extends RefCounted
## Hero skills for the playable game (owner 11-27 "make the character you play the most complete"). The data lives in
## SkillData resources (data/skills/*.tres) listed by each ClassData (data/classes/*.tres). Six skills per
## class, unlocked by level, ranked 1-5 with skill points (one per level), and a choice of one of two upgrades at
## rank 3. Each skill plays one of the hero's existing animations ("anim") and its effect is resolved by the game
## director in the shape given here (arc, line, circle at self, circle at the cursor, dash, blink, buff, ward).
## Names, icons and numbers come from the original Crownsfall design (scripts/game_data.gd, skill tiles).

const MAX_RANK := 5
const MOD_RANK := 3
const RANK_DMG := 0.14            # +14% damage per rank above 1

const CLASS_PATHS := {"warrior": "res://data/classes/knight.tres", "rogue": "res://data/classes/rogue.tres",
	"mage": "res://data/classes/mage.tres", "cleric": "res://data/classes/cleric.tres"}
const ORDER := ["warrior", "rogue", "mage", "cleric"]

## Classes the player can pick now: those whose rigged outfit is in the project.
static func playable() -> Array:
	var out := []
	for cid in ORDER:
		if class_data(cid).hero_model != null: out.append(cid)
	return out

static func display_name(class_id: String) -> String:
	return String(class_data(class_id).display_name)
static var _cache := {}

## The class's ClassData resource (data/classes/*.tres, edited in the Inspector).
static func class_data(class_id: String) -> Resource:
	var cid: String = class_id if CLASS_PATHS.has(class_id) else "warrior"
	if not _cache.has("cls_" + cid): _cache["cls_" + cid] = load(CLASS_PATHS[cid])
	return _cache["cls_" + cid]

## Skills as flat dictionaries (built from the class's SkillData resources).
static func defs(class_id: String) -> Array:
	var cid: String = class_id if CLASS_PATHS.has(class_id) else "warrior"
	if not _cache.has("defs_" + cid):
		var out := []
		for sd in class_data(cid).skills: out.append(sd.to_dict())
		_cache["defs_" + cid] = out
	return _cache["defs_" + cid]

static func def(class_id: String, id: String) -> Dictionary:
	for d in defs(class_id):
		if d["id"] == id: return d
	return lore_def(id)

## Lorecast skills (data/lorecasts.json): learned at lorecast sites, usable by every class.
static func lorecast_sites() -> Array:
	if not _cache.has("lore_sites"):
		_cache["lore_sites"] = JSON.parse_string(FileAccess.get_file_as_string("res://data/lorecasts.json")).get("sites", [])
	return _cache["lore_sites"]

## The quest that teaches Lorecasting ("" = always available).
static func lorecast_requires() -> String:
	if not _cache.has("lore_req"):
		_cache["lore_req"] = String(JSON.parse_string(FileAccess.get_file_as_string("res://data/lorecasts.json")).get("requires_quest", ""))
	return _cache["lore_req"]

static func lore_def(id: String) -> Dictionary:
	if not _cache.has("lore_" + id):
		var d := {}
		for site in lorecast_sites():
			var sd: Resource = load(String(site["skill"]))
			if sd != null and sd.id == id:
				d = sd.to_dict(); d["lorecast"] = true; d["figure"] = site["figure"]; d["unlock"] = 999
		_cache["lore_" + id] = d
	return _cache["lore_" + id]

## The skill's numbers with its chosen upgrade folded in (upgrade values replace the base ones).
static func resolved(class_id: String, id: String, mod_id: String) -> Dictionary:
	var d: Dictionary = def(class_id, id).duplicate(true)
	for m in d.get("mods", []):
		if m["id"] == mod_id:
			for k in m:
				if not k in ["id", "name", "desc"]: d[k] = m[k]
	return d

static func damage_mult(rank: int) -> float:
	return 1.0 + RANK_DMG * float(maxi(0, rank - 1))
