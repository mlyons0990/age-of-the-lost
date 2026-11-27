extends Node
## The playable game (owner 11-26 "connect all the ideas into one cohesive system"). Sits inside the 3D world
## (scripts/three_d/rig_lab.gd, game_mode) and ties every system together:
##   character record (game_state.gd: level, XP, gold, potions, bag, gear, quests, position) -> hero stats
##   zone encounters (data/encounters.json) -> monsters (monster.gd) -> kills -> XP / loot / quest progress
##   quests (data/quests.json) -> NPC dialogue in Crownsfall, objectives on the HUD tracker, minimap and map
##   hero damage scaled by gear and level, monster damage reduced by armour, potions from the character record
##   death -> respawn in town; travel / waypoints / pickups / quest steps -> autosave
const STATE := preload("res://scripts/game/game_state.gd")
const MONSTER := preload("res://scripts/game/monster.gd")
const LOOT := preload("res://scripts/game/loot_drop.gd")
const UI := preload("res://scripts/game/game_ui.gd")
const SYS := preload("res://scripts/systems.gd")
const SKILLS := preload("res://scripts/game/skills.gd")
const GEAR_VISUALS := preload("res://scripts/game/gear_visuals.gd")
var gear_visuals
const GD := preload("res://scripts/game_data.gd")
const TARGETING := preload("res://scripts/three_d/combat_targeting3d.gd")
const NPC_MODELS := {"knight": "res://models/higgsfield_pilot/knight_pilot_armed.glb", "mage": "res://models/higgsfield_mage/mage_pilot_armed.glb"}
const NPCS := {"crownsfall": [
	{"id": "ralden", "name": "Captain Ralden", "model": "knight", "at": [2330, 1060], "tint": Color(0.82, 0.86, 1.0)},
	{"id": "quartermaster", "name": "Quartermaster Ysolde", "model": "mage", "at": [1500, 1060], "tint": Color(1.0, 0.92, 0.85)}]}
const SAFE_ZONES := ["crownsfall"]
const SOUNDS := {"hit": "slash", "pickup": "pickup", "potion": "potion", "equip": "equip", "click": "ui_click", "level": "winter_crown", "quest": "ashen_ward", "boss": "starfall_script"}

var lab
var state
var ui
var quests_def: Array = []
var encounters: Dictionary = {}
var monsters: Array = []
var loot: Array = []
var npcs: Array = []             # {id, name, node, pos}
var pending: Dictionary = {}     # {"kind": "loot"|"npc", "ref": ...} target the hero is walking to
var dead := false
var stats: Dictionary = {}
var save_t := 0.0
var boss: Node3D = null
var sfx: Array = []
var quest_dirty := true
var skill_cds := {}              # skill id -> seconds left
var casting: Dictionary = {}     # the skill whose animation is playing: resolved def + aim + start
var buff_t := 0.0
var buff_dmg := 0.0
var buff_def := 0.0
var ward := 0.0
var ward_t := 0.0
var ward_def: Dictionary = {}
var pending_ground: Array = []   # delayed strikes: {at, t, def}

func setup(owner_lab, st) -> void:
	lab = owner_lab
	state = st
	quests_def = JSON.parse_string(FileAccess.get_file_as_string("res://data/quests.json"))["quests"]
	encounters = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	for i in 6:
		var p := AudioStreamPlayer.new(); p.bus = "Master"; add_child(p); sfx.append(p)
	ui = UI.new()
	ui.name = "GameUI"
	lab.add_child(ui)
	ui.setup(self)
	if state.quest_state("city_reborn") == "":
		state.set_quest("city_reborn", "active", 0)
	gear_visuals = GEAR_VISUALS.new()
	gear_visuals.name = "GearVisuals"
	lab.player.add_child(gear_visuals)
	gear_visuals.setup(lab.player.body, lab.player.class_data)
	apply_stats(true)
	lab.player.external_costs = true
	lab.player.primary_action = func(): use_skill(String(state.bar[5]) if state.bar.size() == 8 else "")
	lab.player.death_handler = _on_hero_died
	lab.zone_changed.connect(_on_zone_changed)
	lab.hud.reload_bar()
	_enter_zone(true)

# ---------------- helpers used by monsters ----------------

func hero() -> Node3D: return lab.player
func hero_alive() -> bool: return not dead and not lab.zone_traveling
func walkable(p: Vector3) -> bool: return lab.zone_walkable(p)
func line_clear(a: Vector2, b: Vector2) -> bool:
	return lab._kit_line_free(a, b) if lab.kit_grid != null else lab.zone_line_clear(a, b)
func find_path(a: Vector2, b: Vector2) -> PackedVector2Array: return lab.zone_find_path(a, b)
func can_see(a: Vector3, b: Vector3) -> bool: return line_clear(Vector2(a.x, a.z), Vector2(b.x, b.z))

func zone_id() -> String:
	var z := String(lab.painted_zone)
	return z.get_file().get_basename() if z.begins_with("res://") else z

func in_town() -> bool: return zone_id() in SAFE_ZONES

func play(name: String, vol_db := -6.0) -> void:
	var path := "res://assets/audio/%s.wav" % String(SOUNDS.get(name, name))
	if not ResourceLoader.exists(path): return
	for p in sfx:
		if not p.playing:
			p.stream = load(path); p.volume_db = vol_db; p.play(); return

# ---------------- stats ----------------

func apply_stats(full := false) -> void:
	stats = state.stats()
	if gear_visuals != null: gear_visuals.apply(state.gear)
	var p = lab.player
	var frac_hp: float = p.hp / maxf(1.0, p.max_hp)
	var frac_mp: float = p.mana / maxf(1.0, p.max_mana)
	p.max_hp = float(stats["max_hp"])
	p.max_mana = float(stats["max_mp"])
	p.hp = p.max_hp if full else clampf(p.max_hp * frac_hp, 1.0, p.max_hp)
	p.mana = p.max_mana if full else p.max_mana * frac_mp
	p.mana_regen = float(stats["mana_regen"]) * (1.0 if state.class_id == "mage" else 0.6)
	p.health_changed.emit(p.hp, p.max_hp)

## Damage of one hero attack against monsters: the attack's base (combat_targeting3d) scaled by the character's
## weapon/spell power from gear and level, with crits.
func damage_hero(raw: float, from: Node3D) -> void:
	if dead: return
	var armor: float = float(stats["armor"])
	var lvl: int = from.level if from != null and "level" in from else 1
	var taken: float = raw * (1.0 - armor / (armor + 10.0 * lvl + 40.0)) * (1.0 - (buff_def if buff_t > 0.0 else 0.0))
	if ward > 0.0:
		var soak := minf(ward, taken)
		ward -= soak; taken -= soak
		lab.effects.ring(lab.player.global_position, 1.1, Color("ffb070"), 0.25)
		if ward <= 0.0: _end_ward()
		if taken <= 0.0: return
	lab.player.receive_damage(round(maxf(1.0, taken)))
	show_damage(lab.player.global_position + Vector3.UP * 2.3, round(taken), false, true)

# ---------------- zones, monsters, NPCs ----------------

func remap_travel(to: String, arrive: Array) -> Array:
	# the playable game uses the kit-built Whisperwood (3x3 zone) in place of the single painted screen
	if to == "whisperwood":
		var z: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/zones/whisperwood_forest.json"))
		return ["whisperwood_forest", z["spawn"]]
	return [to, arrive]

func _on_zone_changed(_to: String) -> void:
	_enter_zone(false)

func _enter_zone(first: bool) -> void:
	_clear_zone()
	var zid := zone_id()
	state.zone = zid
	if first and state.pos.x >= 0.0:
		var at: Vector3 = lab.zone_px_to_world(state.pos.x, state.pos.y)
		if lab.zone_walkable(at):
			lab.player.global_position = at + Vector3.UP * 0.08
			lab.zone_last_ok = lab.player.global_position
	_spawn_npcs(zid)
	_spawn_encounters(zid)
	if in_town():
		state.potions["health"] = maxi(state.potions["health"], 3)    # the town healer tops you up
		lab.player.restore(99999, 99999)
	quest_dirty = true
	ui.area_banner(String(lab.zone.get("name", zid)).split(" — ")[0], "Sanctuary" if in_town() else _level_text(zid))
	autosave()

func _level_text(zid: String) -> String:
	var lv: Array = encounters.get(zid, {}).get("levels", [1, 1])
	return "Monster level %d–%d" % [int(lv[0]), int(lv[1])]

func _clear_zone() -> void:
	for m in monsters:
		if is_instance_valid(m): m.queue_free()
	monsters.clear()
	lab.targets.clear()
	for l in loot:
		if is_instance_valid(l): l.queue_free()
	loot.clear()
	for n in npcs:
		if is_instance_valid(n["node"]): n["node"].queue_free()
	npcs.clear()
	boss = null
	pending = {}

func _zone_level(zid: String, u: float) -> int:
	var lv: Array = encounters.get(zid, {}).get("levels", [1, 1])
	var W: float = float(lab.zone["size"][0])
	return clampi(int(lv[0]) + int(floor((int(lv[1]) - int(lv[0]) + 0.99) * u / W)), int(lv[0]), int(lv[1]))

func _spawn_encounters(zid: String) -> void:
	for p in encounters.get(zid, {}).get("packs", []):
		if p.has("guardian") and state.dead_uniques.has(p["guardian"]): continue
		if p.has("boss"):
			if state.dead_uniques.has(p["boss"]): continue
			if p.has("needs_quest") and state.quest_state(String(p["needs_quest"])) != "active": continue
		var lvl := _zone_level(zid, float(p["at"][0]))
		var centre: Vector3 = lab.zone_px_to_world(float(p["at"][0]), float(p["at"][1]))
		var pack := []
		var specs: Array = []
		for ty in p.get("types", []): specs.append({"type": ty})
		if p.get("elite", false) and not specs.is_empty(): specs[0]["elite"] = true
		if p.has("guardian"): specs.push_front({"type": p["elite_type"], "elite": true, "unique": p["guardian"], "name": p["elite_name"], "page": p["page"]})
		if p.has("boss"): specs.push_front({"type": p["boss_type"], "boss": true, "unique": p["boss"], "name": p["boss_name"]})
		for i in specs.size():
			var s: Dictionary = specs[i]
			var a := TAU * i / maxf(1.0, specs.size()) + randf() * 0.6
			var at := centre + (Vector3(cos(a), 0, sin(a)) * randf_range(0.8, 2.2) if i > 0 or specs.size() > 1 else Vector3.ZERO)
			if not lab.zone_walkable(at): at = centre
			if not lab.zone_walkable(at): continue
			var m := _spawn_monster(String(s["type"]), lvl + (1 if s.get("elite", false) else 0), bool(s.get("elite", false)), bool(s.get("boss", false)), at)
			if s.has("unique"): m.unique_id = s["unique"]
			if s.has("name"): m.ename = s["name"]
			if s.has("page"): m.drops_page = s["page"]
			if m.boss: boss = m
			pack.append(m)
		for m in pack: m.pack = pack

func _spawn_monster(key: String, lvl: int, elite: bool, is_boss: bool, at: Vector3) -> Node3D:
	var m := Node3D.new()
	m.set_script(MONSTER)
	m.setup(key, lvl, elite, is_boss)
	m.director = self
	lab.add_child(m)
	m.global_position = at
	m.home = at
	m.died.connect(_on_monster_died)
	monsters.append(m)
	lab.targets.append(m)
	return m

func summon_adds(src: Node3D, n: int) -> void:
	var pack: Array = src.pack
	for i in n:
		var a := TAU * i / n
		var at: Vector3 = src.global_position + Vector3(cos(a), 0, sin(a)) * 2.2
		if not lab.zone_walkable(at): continue
		var m := _spawn_monster("slime", src.level, false, false, at)
		m.pack = pack; pack.append(m); m.state = "chase"
	lab.effects.ring(src.global_position, 3.5, Color("9c6bff"), 0.7)
	ui.toast("The Thornwarden calls the wood to its aid!", Color("c9a8ff"))

func _spawn_npcs(zid: String) -> void:
	for d in NPCS.get(zid, []):
		var node := Node3D.new()
		node.name = "NPC_" + String(d["id"])
		lab.add_child(node)
		var at: Vector3 = lab.zone_px_to_world(float(d["at"][0]), float(d["at"][1]))
		node.global_position = at
		var packed: PackedScene = load(NPC_MODELS[d["model"]])
		var body: Node3D = packed.instantiate()
		body.rotation.y = PI + 0.5
		node.add_child(body)
		var ap: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
		if ap != null:
			for a in ap.get_animation_list():
				if String(a).ends_with("Idle"):
					ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR; ap.play(a); break
		var lbl := Label3D.new()
		lbl.text = String(d["name"])
		lbl.font = load("res://assets/fonts/LiberationSerif-Bold.ttf")
		lbl.font_size = 40; lbl.pixel_size = 0.005
		lbl.modulate = Color("e8d9a8"); lbl.outline_size = 10; lbl.outline_modulate = Color(0, 0, 0, 0.9)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lbl.no_depth_test = true; lbl.render_priority = 8
		lbl.position = Vector3(0, 2.45, 0)
		node.add_child(lbl)
		var mark := Label3D.new()
		mark.font = lbl.font; mark.font_size = 96; mark.pixel_size = 0.006
		mark.outline_size = 14; mark.outline_modulate = Color(0, 0, 0, 0.9)
		mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED; mark.no_depth_test = true; mark.render_priority = 8
		mark.position = Vector3(0, 2.95, 0)
		node.add_child(mark)
		npcs.append({"id": d["id"], "name": d["name"], "node": node, "pos": at, "mark": mark})

func _update_npc_marks() -> void:
	for n in npcs:
		var m: Label3D = n["mark"]
		var q := npc_quest(String(n["id"]))
		if q.is_empty(): m.text = ""
		else:
			var st: String = state.quest_state(String(q["id"]))
			m.text = "?" if st == "ready" else "!"
			m.modulate = Color("f2c14e")

## The quest this NPC has something to say about right now ({} = none).
func npc_quest(npc_id: String) -> Dictionary:
	for q in quests_def:
		if String(q.get("giver", "")) != npc_id: continue
		var st: String = state.quest_state(String(q["id"]))
		if st in ["active", "ready"]: return q
	return {}

# ---------------- kills, XP, loot ----------------

func _on_monster_died(m: Node3D) -> void:
	lab.targets.erase(m)
	monsters.erase(m)
	state.kills += 1
	var gained: int = state.add_xp(m.xp_value)
	ui.float_xp(m.xp_value)
	if gained > 0: _level_up(gained)
	if m.unique_id != "": state.dead_uniques[m.unique_id] = true
	_drop_loot(m)
	if m.boss:
		boss = null
		if state.quest_state("thornwarden") == "active":
			state.set_quest("thornwarden", "ready", 1)
			ui.toast("The Thornwarden is slain! Report to Captain Ralden.", Color("f2c14e"), 4.0)
			play("quest")
		autosave()
	elif m.unique_id != "":
		autosave()
	quest_dirty = true

func _level_up(n: int) -> void:
	apply_stats(true)
	learn_unlocks()
	ui.toast("+%d skill point%s  —  press K" % [n, "" if n == 1 else "s"], Color("c9a8ff"), 3.0, 20)
	lab.effects.ring(lab.player.global_position, 2.4, Color("f2d27a"), 0.9)
	lab.effects.sparks(lab.player.global_position + Vector3.UP, Color("f2d27a"), 30)
	ui.toast("LEVEL %d" % state.level, Color("f2d27a"), 3.0, 40)
	play("level", -4.0)
	autosave()

func _drop_loot(m: Node3D) -> void:
	var at: Vector3 = m.global_position
	var drops: Array = []
	if m.drops_page != "" and state.quest_state("lost_tomes") == "active":
		drops.append({"kind": "quest", "item": {"name": "Archive Page", "page": m.drops_page}})
	var gold_chance := 1.0 if m.elite else 0.45
	if randf() < gold_chance:
		drops.append({"kind": "gold", "amount": int(round(randf_range(3, 9) * (1.0 + 0.4 * (m.level - 1)) * (6.0 if m.boss else (2.5 if m.elite else 1.0))))})
	if randf() < (0.5 if m.elite else 0.09):
		drops.append({"kind": "potion", "potion": "health" if randf() < 0.65 else "mana"})
	var n_items := 3 if m.boss else (1 + int(randf() < 0.35) if m.elite else int(randf() < 0.16))
	for i in n_items:
		var boost: float = 0.35 if m.boss else (0.12 if m.elite else 0.0)
		drops.append({"kind": "item", "item": SYS.make_item(m.level, boost, "", state.class_id if randf() < 0.85 else SKILLS.ORDER.filter(func(c): return c != state.class_id).pick_random())})
	for i in drops.size():
		var a := TAU * i / maxf(1.0, drops.size()) + randf() * 0.5
		var p := at + Vector3(cos(a), 0, sin(a)) * (0.0 if drops.size() == 1 else randf_range(0.6, 1.3))
		if not lab.zone_walkable(p): p = at
		spawn_loot(drops[i], p)

func spawn_loot(d: Dictionary, at: Vector3) -> Node3D:
	var l := Node3D.new()
	l.set_script(LOOT)
	l.kind = d["kind"]
	l.amount = int(d.get("amount", 0))
	l.potion = String(d.get("potion", "health"))
	l.item = d.get("item", {})
	lab.add_child(l)
	l.global_position = at + Vector3.UP * 0.02
	loot.append(l)
	return l

func _pickup(l: Node3D) -> bool:
	match l.kind:
		"gold":
			state.gold += l.amount
			ui.toast("+%d gold" % l.amount, Color("f2d27a"), 1.2, 18)
		"potion":
			state.potions[l.potion] = mini(99, int(state.potions[l.potion]) + 1)
			ui.toast("+1 %s" % l.text(), l.colour(), 1.2, 18)
		"quest":
			var q: Dictionary = state.quest("lost_tomes")
			var n: int = int(q.get("progress", 0)) + 1
			state.set_quest("lost_tomes", "ready" if n >= 3 else "active", n)
			ui.toast("Archive Page recovered (%d/3)" % n + ("  —  return to Captain Ralden" if n >= 3 else ""), Color("ff9a2e"), 3.5)
			play("quest")
			quest_dirty = true
		"item":
			if not state.add_item(l.item):
				ui.toast("Your bag is full", Color("ff7a6a"), 1.6)
				return false
			ui.toast(String(l.item["name"]), l.colour(), 1.4, 18)
	play("pickup", -10.0)
	loot.erase(l)
	l.queue_free()
	if l.kind in ["quest", "item"]: autosave()
	return true

# ---------------- clicks: loot and NPCs ----------------

## Called by the world before its own click handling; returns true when the click was used.
func handle_click(screen: Vector2) -> bool:
	if dead or ui.blocking(): return true
	var cam: Camera3D = lab.camera
	var best = null; var best_d: float = 40.0 * lab.get_viewport().get_visible_rect().size.y / 1080.0
	for l in loot:
		if not is_instance_valid(l): continue
		var d := cam.unproject_position(l.global_position + Vector3.UP * 0.6).distance_to(screen)
		if d < best_d: best_d = d; best = {"kind": "loot", "ref": l, "pos": l.global_position}
	for n in npcs:
		var sp := cam.unproject_position(n["pos"] + Vector3.UP * 1.1)
		var d := sp.distance_to(screen)
		if d < 70.0 * lab.get_viewport().get_visible_rect().size.y / 1080.0 and d < best_d + 30.0:
			best_d = d; best = {"kind": "npc", "ref": n, "pos": n["pos"]}
	if best == null: return false
	pending = best
	var p: Vector3 = best["pos"]
	if lab.player.global_position.distance_to(p) < (2.2 if best["kind"] == "npc" else 1.2):
		_arrive_pending()
	else:
		lab.zone_move_to(p + (lab.player.global_position - p).normalized() * (1.4 if best["kind"] == "npc" else 0.2))
	return true

func _arrive_pending() -> void:
	var p := pending; pending = {}
	if p["kind"] == "loot":
		if is_instance_valid(p["ref"]): _pickup(p["ref"])
	else:
		lab.player.stop_moving()
		talk(String(p["ref"]["id"]))

# ---------------- quests + dialogue ----------------

func quest_def(id: String) -> Dictionary:
	for q in quests_def:
		if q["id"] == id: return q
	return {}

func talk(npc_id: String) -> void:
	play("click", -8.0)
	if npc_id == "quartermaster":
		ui.open_vendor()
		return
	var q := npc_quest(npc_id)
	if q.is_empty():
		ui.dialogue("Captain Ralden", ["Crownsfall owes you a debt, Wayfarer. Hollowmere will call for you soon."], [["Farewell", Callable()]])
		return
	var st: String = state.quest_state(String(q["id"]))
	var lines: Array = q.get("talk", {}).get(st, ["Captain Ralden", "..."])
	if q["id"] == "city_reborn":
		ui.dialogue(lines[0], lines.slice(1), [["I will bring them back.", func(): complete_quest("city_reborn")]])
	elif st == "ready":
		ui.dialogue(lines[0], lines.slice(1), [["Claim your reward", func(): complete_quest(String(q["id"]))]])
	else:
		ui.dialogue(lines[0], lines.slice(1), [["On my way.", Callable()]])

func complete_quest(id: String) -> void:
	var q := quest_def(id)
	state.set_quest(id, "done")
	var r: Dictionary = q.get("reward", {})
	state.gold += int(r.get("gold", 0))
	var gained: int = state.add_xp(int(r.get("xp", 0)))
	var msg := "Quest complete: %s   +%d XP  +%d gold" % [q["name"], int(r.get("xp", 0)), int(r.get("gold", 0))]
	if r.has("item_rarity"):
		var it: Dictionary = SYS.make_item(state.level, 0.0, "", state.class_id)
		it["rarity"] = int(r["item_rarity"])
		var mult: float = SYS.MULT[it["rarity"]] / SYS.MULT[0]
		for k in ["dmg", "armor", "hp", "spell_power"]: it[k] = round(float(it.get(k, 0)) * mult)
		it["name"] = ["", "Etched ", "Dawnforged ", "Epochbound "][it["rarity"]] + String(SYS.NAMES[it["slot"]])
		if state.add_item(it): msg += "   +" + String(it["name"])
		else: spawn_loot({"kind": "item", "item": it}, lab.player.global_position + Vector3(1, 0, 0))
	ui.toast(msg, Color("f2c14e"), 4.0, 22)
	play("quest")
	if gained > 0: _level_up(gained)
	if q.has("next"):
		state.set_quest(String(q["next"]), "active", 0)
		ui.toast("New quest: " + String(quest_def(String(q["next"]))["name"]), Color("e8b85c"), 4.0, 22)
	if id == "thornwarden":
		ui.show_epilogue()
	quest_dirty = true
	autosave()

## Quests as the HUD tracker and the map show them: [{id, name, objective, progress, count, done, markers}]
func quest_view() -> Array:
	var out := []
	for q in quests_def:
		var st: String = state.quest_state(String(q["id"]))
		if st == "" or st == "done": continue
		var step: Dictionary = q.get("steps", {}).get(st, {})
		var markers := []
		for m in step.get("markers", []):
			var mm: Dictionary = m.duplicate()
			if m.has("npc"):
				for d in NPCS.get(String(m["zone"]), []):
					if d["id"] == m["npc"]: mm["at"] = d["at"]; mm["label"] = d["name"]
			if m.has("page") and state.dead_uniques.has({"page_1": "page_dell", "page_2": "page_fae", "page_3": "page_stones"}[m["page"]]): continue
			markers.append(mm)
		var prog: int = int(state.quest(String(q["id"])).get("progress", 0))
		out.append({"id": q["id"], "name": q["name"], "objective": step.get("objective", ""), "progress": prog,
			"count": int(q.get("count", 0)) if st == "active" else 0, "done": false, "markers": markers})
	return out

# ---------------- potions ----------------

func use_potion(kind: String) -> bool:
	if int(state.potions.get(kind, 0)) <= 0:
		ui.toast("No %s potions" % kind, Color("ff7a6a"), 1.2, 18)
		return false
	state.potions[kind] = int(state.potions[kind]) - 1
	play("potion", -6.0)
	return true

# ---------------- skills ----------------

func skill_def(id: String) -> Dictionary:
	return SKILLS.resolved(state.class_id, id, state.skill_mod(id))

func skill_cd_frac(id: String) -> float:
	var d := skill_def(id)
	var cd: float = float(d.get("cd", 0.0))
	return clampf(float(skill_cds.get(id, 0.0)) / cd, 0.0, 1.0) if cd > 0.0 else 0.0

func skill_affordable(id: String) -> bool:
	return lab.player.mana >= float(skill_def(id).get("cost", 0.0))

## Use a learned skill toward the cursor (or the clicked enemy). Charges mana and cooldown only if it starts.
func use_skill(id: String) -> bool:
	if id == "" or dead or lab.zone_traveling or state.rank(id) <= 0: return false
	var p = lab.player
	if p.attack_t > 0.0 or p.dodge_t > 0.0: return false
	if float(skill_cds.get(id, 0.0)) > 0.0: return false
	var d := skill_def(id)
	if p.mana < float(d.get("cost", 0.0)):
		ui.toast("Not enough mana", Color("8ab4ff"), 0.8, 18)
		return false
	var aim: Vector3 = p.aim_point
	if p.attack_target != null and is_instance_valid(p.attack_target): aim = p.attack_target.global_position
	if d["shape"] == "blink":
		if not _blink(d, aim): return false
	else:
		var before: int = p.attack_serial
		var anim: String = d["anim"]
		if state.class_id == "mage" and p.MAGE_SPELLS.has(anim): p.use_skill(anim)
		else:
			if p.click_to_move: p._face_aim(); p.move_target = Vector3.INF
			p._attack(anim, float(p.WARRIOR_SKILLS.get(anim, 0.72)))
		if p.attack_serial == before: return false
		casting = {"def": d, "id": id, "aim": aim, "from": p.global_position}
	p.mana -= float(d.get("cost", 0.0))
	if float(d.get("cd", 0.0)) > 0.0: skill_cds[id] = float(d["cd"])
	if SOUNDS.has(id) or ResourceLoader.exists("res://assets/audio/%s.wav" % id): play(id, -10.0)
	return true

## Base hit of a skill: weapon (Knight) or spell (Mage) power from gear and level, the skill's multiplier, its rank,
## Rallying Cry, crits.
func skill_hit(d: Dictionary, id: String) -> Dictionary:
	var power: float = float(stats["spell_power"]) * 1.9 if state.class_id == "mage" else float(stats["dmg"]) * 1.8
	var crit: bool = randf() < float(stats["crit"])
	var amt: float = power * float(d.get("dmg", 1.0)) * SKILLS.damage_mult(state.rank(id)) * (1.0 + (buff_dmg if buff_t > 0.0 else 0.0))
	return {"amount": round(amt * randf_range(0.92, 1.08) * (1.6 if crit else 1.0)), "crit": crit}

func roll_damage(kind: String) -> Dictionary:
	var id := String(state.bar[5]) if state.bar.size() == 8 and String(state.bar[5]) != "" else String(SKILLS.defs(state.class_id)[0]["id"])
	return skill_hit(skill_def(id), id)

## The hero's animation reached its release point: resolve the skill that is playing.
func skill_impact(kind: String, direction: Vector3) -> void:
	if casting.is_empty():
		var id := String(state.bar[5]) if state.bar.size() == 8 else ""
		if id == "": return
		casting = {"def": skill_def(id), "id": id, "aim": lab.player.aim_point, "from": lab.player.global_position}
	var c := casting; casting = {}
	var d: Dictionary = c["def"]
	var p = lab.player
	var origin: Vector3 = p.global_position
	var dir := Vector3(direction.x, 0, direction.z).normalized()
	match String(d["shape"]):
		"arc":
			var hits := []
			for m in lab.targets.duplicate():
				if not _alive(m): continue
				var off := Vector3(m.global_position.x - origin.x, 0, m.global_position.z - origin.z)
				var r: float = float(d["range"]) + m.damage_radius()
				if off.length() <= r and (off.length() < 0.6 or dir.dot(off.normalized()) >= float(d.get("arc", 0.2))): hits.append(m)
			_apply_hits(hits, d, c["id"], dir)
		"line":
			var cands := []
			for m in lab.targets.duplicate():
				if not _alive(m): continue
				var off := Vector3(m.global_position.x - origin.x, 0, m.global_position.z - origin.z)
				var along := off.dot(dir)
				var side := (off - dir * along).length()
				if along > -0.3 and along <= float(d["range"]) and side <= float(d.get("width", 1.0)) * 0.5 + m.damage_radius():
					cands.append([along, m])
			cands.sort_custom(func(a, b): return a[0] < b[0])
			var hits := []
			for k in mini(int(d.get("pierce", 1)), cands.size()): hits.append(cands[k][1])
			_apply_hits(hits, d, c["id"], dir)
		"nova":
			_circle_hit(origin, float(d["radius"]), d, c["id"])
			lab.effects.ring(origin, float(d["radius"]), Color("bfe8ff") if state.class_id == "mage" else Color("ffe5a4"), 0.45)
		"dash":
			var start: Vector3 = c["from"]
			var hits := []
			for m in lab.targets.duplicate():
				if not _alive(m): continue
				var off := Vector3(m.global_position.x - start.x, 0, m.global_position.z - start.z)
				var along := off.dot(dir)
				if along > -0.5 and along <= float(d["range"]) and (off - dir * along).length() <= float(d.get("width", 1.2)) * 0.5 + m.damage_radius():
					hits.append(m)
			_apply_hits(hits, d, c["id"], dir)
			if d.has("end_radius"):
				_ground_strike(p.global_position + dir * 2.5, float(d["end_radius"]), d, c["id"], 0.25)
		"ground":
			var at: Vector3 = c["aim"] if c["aim"].is_finite() else origin + dir * 3.0
			var off := Vector3(at.x - origin.x, 0, at.z - origin.z)
			if off.length() > float(d.get("reach", 7.0)): at = origin + off.normalized() * float(d.get("reach", 7.0))
			_ground_strike(at, float(d["radius"]), d, c["id"], float(d.get("delay", 0.5)))
		"buff":
			buff_t = float(d["duration"]); buff_dmg = float(d.get("buff_dmg", 0.0)); buff_def = float(d.get("buff_def", 0.0))
			p.restore(p.max_hp * float(d.get("heal", 0.0)), 0.0)
			lab.effects.ring(origin, 1.8, Color("ffd36a"), 0.7)
			lab.effects.sparks(origin + Vector3.UP, Color("ffd36a"), 24)
			ui.toast(String(d.get("name", "Rallying Cry")), Color("ffd36a"), 1.0, 20)
		"ward":
			ward = p.max_hp * float(d.get("ward", 0.3)); ward_t = float(d["duration"]); ward_def = d
			lab.effects.ring(origin, 1.3, Color("ffb070"), 0.6)

func _alive(m) -> bool:
	return is_instance_valid(m) and m.has_method("is_alive") and m.is_alive()

func _circle_hit(at: Vector3, r: float, d: Dictionary, id: String) -> void:
	var hits := []
	for m in lab.targets.duplicate():
		if _alive(m) and Vector2(m.global_position.x - at.x, m.global_position.z - at.z).length() <= r + m.damage_radius(): hits.append(m)
	_apply_hits(hits, d, id, Vector3.ZERO, at)

func _ground_strike(at: Vector3, r: float, d: Dictionary, id: String, delay: float) -> void:
	var col := Color("c3a9ff") if state.class_id == "mage" else Color("ffe5a4")
	lab.effects.ring(at, r, Color(col, 0.6), delay)
	pending_ground.append({"at": at, "r": r, "def": d, "id": id, "t": delay})

## Damage + statuses + mana/heal per hit.
func _apply_hits(hits: Array, d: Dictionary, id: String, dir: Vector3, centre := Vector3.INF) -> void:
	var gained := false
	for m in hits:
		if not _alive(m): continue
		var h := skill_hit(d, id)
		var away: Vector3 = dir if centre == Vector3.INF else Vector3(m.global_position.x - centre.x, 0, m.global_position.z - centre.z).normalized()
		var dead_now: bool = m.hit(float(h["amount"]))
		lab.effects.sparks(m.damage_center(), Color("c3a9ff") if state.class_id == "mage" else Color("ffca70"), 10)
		if dead_now: lab.kills += 1
		else:
			m.apply_status(float(d.get("slow", 0.0)), float(d.get("slow_t", 0.0)), float(d.get("stun", 0.0)), float(h["amount"]) * float(d.get("burn", 0.0)), away * float(d.get("knock", 0.0)))
		if d.has("gain") and not gained: lab.player.mana = minf(lab.player.max_mana, lab.player.mana + float(d["gain"])); gained = true
		if d.has("heal_hit"): lab.player.restore(lab.player.max_hp * float(d["heal_hit"]), 0.0)
	if not hits.is_empty(): play("hit", -14.0)

func _blink(d: Dictionary, aim: Vector3) -> bool:
	var p = lab.player
	if not aim.is_finite(): return false
	var from: Vector3 = p.global_position
	var off := Vector3(aim.x - from.x, 0, aim.z - from.z)
	if off.length() > float(d["range"]): off = off.normalized() * float(d["range"])
	var to := from + off
	var k := 1.0
	while k > 0.1 and not lab.zone_walkable(to):
		k -= 0.1; to = from + off * k
	if not lab.zone_walkable(to) or off.length() * k < 1.0:
		ui.toast("Cannot reach there", Color("c3a9ff"), 0.8, 18)
		return false
	lab.effects.ring(from, 1.0, Color("c3a9ff"), 0.35)
	p.global_position = Vector3(to.x, from.y, to.z)
	p.stop_moving()
	lab.zone_last_ok = p.global_position
	lab.zone_route = PackedVector2Array()
	lab.effects.ring(to, 1.0, Color("c3a9ff"), 0.35)
	if d.has("radius"):
		var at: Vector3 = p.global_position if bool(d.get("land", false)) else from
		_circle_hit(at, float(d["radius"]), d, String(d.get("id", "arcane_fold")))
		lab.effects.ring(at, float(d["radius"]), Color("bfe8ff"), 0.5)
	return true

func _end_ward() -> void:
	if ward_def.has("burst"):
		var d := ward_def.duplicate(); d["dmg"] = d["burst"]
		_circle_hit(lab.player.global_position, float(d["radius"]), d, "ashen_ward")
		lab.effects.ring(lab.player.global_position, float(d["radius"]), Color("ff8a4a"), 0.5)
	ward = 0.0; ward_t = 0.0; ward_def = {}

func _tick_skills(delta: float) -> void:
	for k in skill_cds.keys(): skill_cds[k] = maxf(0.0, skill_cds[k] - delta)
	if buff_t > 0.0: buff_t = maxf(0.0, buff_t - delta)
	if ward_t > 0.0:
		ward_t -= delta
		if ward_t <= 0.0: _end_ward()
	for g in pending_ground.duplicate():
		g["t"] -= delta
		if g["t"] <= 0.0:
			pending_ground.erase(g)
			_circle_hit(g["at"], g["r"], g["def"], g["id"])
			lab.effects.cast(g["at"], Color("c3a9ff") if state.class_id == "mage" else Color("ffe5a4"))
			lab.effects.ring(g["at"], g["r"], Color("ffffff"), 0.3)

func learn_unlocks() -> void:
	for id in state.unlock_skills():
		ui.toast("New skill: %s" % SKILLS.def(state.class_id, id)["name"], Color("c9a8ff"), 3.5, 22)
	lab.hud.reload_bar()

# ---------------- death ----------------

func _on_hero_died() -> void:
	if dead: return
	dead = true
	state.deaths += 1
	lab.player.stop_moving()
	lab.player.set_physics_process(false)
	lab.player.play_death()
	for m in monsters:
		if is_instance_valid(m) and m.state != "dead": m.state = "leash"
	ui.show_death()

func respawn() -> void:
	dead = false
	lab.player.set_physics_process(true)
	lab.player.hp = lab.player.max_hp
	lab.player.mana = lab.player.max_mana
	lab.player.health_changed.emit(lab.player.hp, lab.player.max_hp)
	lab.player.play_idle()
	if in_town():
		var sp: Array = lab.zone["spawn"]
		lab.player.global_position = lab.zone_px_to_world(float(sp[0]), float(sp[1])) + Vector3.UP * 0.08
		lab.zone_last_ok = lab.player.global_position
	else:
		var wp: Dictionary = lab.waypoint_net.get_entry("crownsfall_town")
		lab.travel_to("crownsfall", [float(wp["at"][0]), float(wp["at"][1]) + 150.0])

# ---------------- feedback ----------------

func show_damage(at: Vector3, amount: float, big: bool, to_hero := false, col := Color(0, 0, 0, 0)) -> void:
	var l := Label3D.new()
	l.text = str(int(amount))
	l.font = load("res://assets/fonts/LiberationSerif-Bold.ttf")
	l.font_size = 56 if big else 44
	l.pixel_size = 0.005
	l.modulate = col if col.a > 0.0 else (Color("ff5a4a") if to_hero else (Color("ffd36a") if big else Color("fff4dc")))
	l.outline_size = 12; l.outline_modulate = Color(0, 0, 0, 0.95)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true; l.render_priority = 9
	lab.add_child(l)
	l.global_position = at + Vector3(randf_range(-0.3, 0.3), 0, 0)
	var tw := l.create_tween()
	tw.tween_property(l, "global_position", l.global_position + Vector3.UP * 0.9, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.tween_callback(l.queue_free)

func strike_fx(at: Vector3, r: float, big: bool) -> void:
	lab.effects.ring(at, r, Color("ff6a4a") if big else Color("ffb08a"), 0.4 if big else 0.25)
	if big: play("boss", -8.0)

# ---------------- frame ----------------

func autosave() -> void:
	if lab.zone.is_empty() or dead: return
	state.pos = lab.zone_world_to_px(lab.player.global_position)
	state.save()
	save_t = 0.0

func _process(delta: float) -> void:
	state.play_time += delta
	save_t += delta
	_tick_skills(delta)
	if save_t > 30.0: autosave()
	if dead or lab.zone_traveling: return
	var hp: Vector3 = lab.player.global_position
	# walk-over pickups (gold, potions, quest items) and the clicked target
	for l in loot.duplicate():
		if not is_instance_valid(l): loot.erase(l); continue
		var reach := 1.7 if l.kind == "quest" else 1.0      # quest items can lie against rocks: generous pickup
		if l.auto_pickup() and Vector2(l.global_position.x - hp.x, l.global_position.z - hp.z).length() < reach:
			_pickup(l)
	if not pending.is_empty():
		var p: Vector3 = pending["pos"]
		var reach := 2.2 if pending["kind"] == "npc" else 1.2
		if Vector2(p.x - hp.x, p.z - hp.z).length() < reach: _arrive_pending()
		elif lab.player.move_target == Vector3.INF and lab.zone_route.is_empty(): pending = {}
	if quest_dirty:
		quest_dirty = false
		_update_npc_marks()
		lab.hud.refresh_quests()
	ui.update_boss(boss)
