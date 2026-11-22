extends RefCounted
## Waypoint network (PoE-style): checkpoints across the world. A waypoint unlocks the first time the hero reaches it;
## from any waypoint the hero can teleport to the town or to any other unlocked waypoint. Unlocks persist in
## the [waypoints] section of user://aotl_save.cfg. The world's zones (in travel order) and the town come from assets/zones/world.json;
## each zone JSON lists its waypoints: {"id", "name", "at": [u, v]} in zone canvas pixels.

const SAVE := preload("res://scripts/three_d/aotl_save.gd")
var world: Dictionary = {}
var entries: Array = []          # {id, name, zone, zone_name, at, town}
var unlocked := {}               # id -> true

func _init() -> void:
	world = JSON.parse_string(FileAccess.get_file_as_string("res://assets/zones/world.json"))
	for zname in world.get("zones", []):
		var z: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/zones/%s.json" % zname))
		for w in z.get("waypoints", []):
			entries.append({"id": w["id"], "name": w["name"], "zone": zname, "zone_name": String(z.get("name", zname)).split(" — ")[0],
				"at": w["at"], "town": zname == world.get("town", "")})
	load_from_disk()
	for e in entries:
		if e["town"]: unlocked[e["id"]] = true

func get_entry(id: String) -> Dictionary:
	for e in entries:
		if e["id"] == id: return e
	return {}

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

## Returns true when this call newly unlocked it.
func unlock(id: String) -> bool:
	if unlocked.has(id) or get_entry(id).is_empty(): return false
	unlocked[id] = true
	save_to_disk()
	return true

func reset() -> void:
	unlocked.clear()
	for e in entries:
		if e["town"]: unlocked[e["id"]] = true
	save_to_disk()

func save_to_disk() -> void:
	var cf: ConfigFile = SAVE.open()
	cf.set_value("waypoints", "unlocked", unlocked.keys())
	SAVE.commit(cf)

func load_from_disk() -> void:
	var cf: ConfigFile = SAVE.open()
	for id in cf.get_value("waypoints", "unlocked", []):
		unlocked[str(id)] = true
