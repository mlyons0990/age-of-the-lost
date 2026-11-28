extends RefCounted
## The one character record for the playable game (owner 11-26 "one cohesive system"): class, level, XP, gold,
## potions, bag + gear (the same item model as the original Crownsfall inventory, scripts/systems.gd), quest state,
## which unique monsters are dead, where the hero stands. Saved in the [game] section of the one save file
## (user://aotl_save.cfg, scripts/three_d/aotl_save.gd) next to waypoints, map exploration, key binds and loadouts.
const SAVE := preload("res://scripts/three_d/aotl_save.gd")
const SYS := preload("res://scripts/systems.gd")
const GD := preload("res://scripts/game_data.gd")
const VERSION := 1
const MAX_LEVEL := 70
const SKILLS := preload("res://scripts/game/skills.gd")

var class_id := "warrior"        # "warrior" (Knight) | "rogue" | "mage" | "cleric" (skills.gd CLASS_PATHS)
var hero_name := "Wayfarer"
var level := 1
var xp := 0
var gold := 0
var potions := {"health": 3, "mana": 2}
var bag: Array = []              # items with x/y cells (SYS.WIDTH x SYS.HEIGHT)
var gear := {}                   # slot -> item
var quests := {}                 # id -> {"state": "active"|"ready"|"done", "progress": int}
var dead_uniques := {}           # id -> true (quest guardians, bosses stay dead)
var zone := "crownsfall"
var pos := Vector2(-1, -1)       # zone px; (-1,-1) = zone spawn
var play_time := 0.0
var deaths := 0
var kills := 0
var vendor_stock: Array = []
var skills := {}                 # skill id -> {"rank": int, "mod": String}
var skill_points := 0
var bar: Array = []              # 8 skill wells (HUD order), skill ids or ""

static func exists() -> bool:
	var cf: ConfigFile = SAVE.open()
	return cf.has_section_key("game", "version")

static func summary() -> Dictionary:
	var cf: ConfigFile = SAVE.open()
	if not cf.has_section_key("game", "version"): return {}
	return {"class_id": cf.get_value("game", "class_id", "warrior"), "level": cf.get_value("game", "level", 1),
		"zone": cf.get_value("game", "zone", "crownsfall"), "play_time": cf.get_value("game", "play_time", 0.0)}

## A brand-new character: wipes the old character, its waypoints and map exploration (key binds stay).
static func new_character(cls: String, name := "") -> RefCounted:
	var s = load("res://scripts/game/game_state.gd").new()
	s.class_id = cls
	s.hero_name = name.strip_edges().left(24) if name.strip_edges() != "" else String(SKILLS.class_data(cls).hero_name)
	var starter := SYS.make_item(1, 0.0, "staff" if cls == "mage" else "weapon", cls)
	starter["rarity"] = 0; starter["name"] = "Worn " + String(SYS.NAMES[starter["slot"]])
	s.gear[SYS.default_slot(starter)] = starter
	if cls in ["warrior", "cleric"]:  # Knight and Cleric start with their shield (it shows on the hero)
		var sh := SYS.make_item(1, 0.0, "offhand", cls)
		sh["rarity"] = 0; sh["name"] = "Worn Kite Shield" if cls == "warrior" else "Worn Sun Shield"
		s.gear["offhand"] = sh
	s.unlock_skills()
	var first: Array = []
	for d in SKILLS.defs(cls):
		if int(d["unlock"]) <= 1: first.append(d["id"])
	s.bar = [first[1] if first.size() > 1 else "", "", "", "", "", first[0], "", ""]
	var cf: ConfigFile = SAVE.open()
	for sec in ["game", "waypoints", "map"]:
		if cf.has_section(sec): cf.erase_section(sec)
	SAVE.commit(cf)
	s.save()
	return s

static func load_saved() -> RefCounted:
	var cf: ConfigFile = SAVE.open()
	if not cf.has_section_key("game", "version"): return null
	var s = load("res://scripts/game/game_state.gd").new()
	s.class_id = String(cf.get_value("game", "class_id", "warrior"))
	if not SKILLS.CLASS_PATHS.has(s.class_id): s.class_id = "warrior"
	s.hero_name = String(cf.get_value("game", "hero_name", "Wayfarer")).left(24)
	s.level = clampi(int(cf.get_value("game", "level", 1)), 1, MAX_LEVEL)
	s.xp = maxi(0, int(cf.get_value("game", "xp", 0)))
	s.gold = clampi(int(cf.get_value("game", "gold", 0)), 0, 99999999)
	var p = cf.get_value("game", "potions", {})
	if p is Dictionary:
		for k in s.potions: s.potions[k] = clampi(int(p.get(k, s.potions[k])), 0, 99)
	for raw in cf.get_value("game", "bag", []):
		var it: Dictionary = SYS.clean_item(raw)
		if not it.is_empty(): s.bag.append(it)
	var g = cf.get_value("game", "gear", {})
	if g is Dictionary:
		for slot in g:
			var it: Dictionary = SYS.clean_item(g[slot])
			if not it.is_empty() and SYS.legal_slot(it, String(slot)): s.gear[String(slot)] = it
	var q = cf.get_value("game", "quests", {})
	if q is Dictionary: s.quests = q
	var du = cf.get_value("game", "dead_uniques", {})
	if du is Dictionary: s.dead_uniques = du
	s.zone = String(cf.get_value("game", "zone", "crownsfall"))
	s.pos = cf.get_value("game", "pos", Vector2(-1, -1))
	s.play_time = float(cf.get_value("game", "play_time", 0.0))
	s.deaths = int(cf.get_value("game", "deaths", 0))
	s.kills = int(cf.get_value("game", "kills", 0))
	var sk = cf.get_value("game", "skills", {})
	if sk is Dictionary:
		for id in sk:
			if not SKILLS.def(s.class_id, String(id)).is_empty() and sk[id] is Dictionary:
				s.skills[String(id)] = {"rank": clampi(int(sk[id].get("rank", 1)), 1, SKILLS.MAX_RANK), "mod": String(sk[id].get("mod", ""))}
	s.skill_points = clampi(int(cf.get_value("game", "skill_points", 0)), 0, 99)
	var b = cf.get_value("game", "bar", [])
	if b is Array and b.size() == 8: s.bar = b
	s.unlock_skills()
	for raw in cf.get_value("game", "vendor_stock", []):
		var it: Dictionary = SYS.clean_item(raw)
		if not it.is_empty(): s.vendor_stock.append(it)
	return s

func save() -> bool:
	var cf: ConfigFile = SAVE.open()
	for k in ["class_id", "hero_name", "level", "xp", "gold", "potions", "bag", "gear", "quests", "dead_uniques", "zone", "pos", "play_time", "deaths", "kills", "vendor_stock", "skills", "skill_points", "bar"]:
		cf.set_value("game", k, get(k))
	cf.set_value("game", "version", VERSION)
	return SAVE.commit(cf)

# ---------------- progression ----------------

func xp_need() -> int:
	return GD.xp_need(level)

## Adds XP; returns the number of levels gained.
func add_xp(amount: int) -> int:
	if level >= MAX_LEVEL: return 0
	xp += amount
	var gained := 0
	while level < MAX_LEVEL and xp >= xp_need():
		xp -= xp_need()
		level += 1
		gained += 1
		skill_points += 1
	return gained

# ---------------- skills ----------------

## Learn every skill the current level allows (rank 1, free). Returns the newly learned skill ids.
func unlock_skills() -> Array:
	var out := []
	for d in SKILLS.defs(class_id):
		if int(d["unlock"]) <= level and not skills.has(d["id"]):
			skills[d["id"]] = {"rank": 1, "mod": ""}
			out.append(d["id"])
			if bar.size() == 8 and not d["id"] in bar:
				for i in [0, 1, 2, 3, 4, 7, 6]:
					if String(bar[i]) == "": bar[i] = d["id"]; break
	return out

func rank(id: String) -> int:
	return int(skills.get(id, {}).get("rank", 0))

func skill_mod(id: String) -> String:
	return String(skills.get(id, {}).get("mod", ""))

## Spend a point on a skill. Returns "" or why not.
func rank_up(id: String) -> String:
	if not skills.has(id): return "Not learned yet."
	if skill_points <= 0: return "No skill points."
	if rank(id) >= SKILLS.MAX_RANK: return "Already at the highest rank."
	skills[id]["rank"] = rank(id) + 1
	skill_points -= 1
	return ""

func choose_mod(id: String, mod_id: String) -> String:
	if rank(id) < SKILLS.MOD_RANK: return "Reach rank %d first." % SKILLS.MOD_RANK
	skills[id]["mod"] = mod_id
	return ""

## Refund every skill point (ranks back to 1, upgrades cleared), for a gold price paid in town.
func respec() -> void:
	for id in skills:
		skill_points += rank(id) - 1
		skills[id] = {"rank": 1, "mod": ""}

func stats() -> Dictionary:
	return SYS.derive(level, gear, {}, class_id)

# ---------------- items ----------------

func add_item(item: Dictionary) -> bool:
	return SYS.insert(bag, item)

func remove_from_bag(uid: String) -> Dictionary:
	for i in bag.size():
		if String(bag[i]["uid"]) == uid:
			var it: Dictionary = bag[i]
			bag.remove_at(i)
			return it
	return {}

func can_equip(item: Dictionary) -> String:
	if not SYS.class_allows(item, class_id): return "Your class cannot use this."
	if int(item.get("level", 1)) > level: return "Requires level %d." % int(item.get("level", 1))
	return ""

## Equip a bag item (swaps with what is worn). Returns "" or the reason it failed.
func equip(uid: String) -> String:
	var it := {}
	for b in bag:
		if String(b["uid"]) == uid: it = b
	if it.is_empty(): return "Item not found."
	var why := can_equip(it)
	if why != "": return why
	var slot: String = SYS.default_slot(it)
	if String(it["slot"]) == "ring" and gear.get("ring1") != null and gear.get("ring2") == null: slot = "ring2"
	var trial := gear.duplicate(); trial[slot] = it
	if String(it["slot"]) == "staff" and gear.get("offhand") != null: trial.erase("offhand")
	remove_from_bag(uid)
	var back: Array = []
	if gear.get(slot) != null: back.append(gear[slot])
	if String(it["slot"]) == "staff" and gear.get("offhand") != null: back.append(gear["offhand"])
	gear = trial
	for b in back:
		if not add_item(b):
			# no room: undo
			gear.erase(slot)
			for bb in back: gear[SYS.default_slot(bb) if String(bb["slot"]) != "ring" else slot] = bb
			add_item(it)
			return "No room in your bag."
	return ""

func unequip(slot: String) -> String:
	if gear.get(slot) == null: return ""
	if not add_item(gear[slot]): return "No room in your bag."
	gear.erase(slot)
	return ""

## Item value in gold when sold / salvaged.
func sell_value(item: Dictionary) -> int:
	return maxi(1, int(item.get("value", 5)) / 3)

# ---------------- quests ----------------

func quest(id: String) -> Dictionary:
	return quests.get(id, {})

func quest_state(id: String) -> String:
	return String(quests.get(id, {}).get("state", ""))

func set_quest(id: String, state: String, progress := -1) -> void:
	var q: Dictionary = quests.get(id, {"state": state, "progress": 0})
	q["state"] = state
	if progress >= 0: q["progress"] = progress
	quests[id] = q
