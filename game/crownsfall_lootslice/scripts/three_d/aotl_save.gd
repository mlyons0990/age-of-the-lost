extends RefCounted
## One versioned save for the ARPG labs (blueprint SAVE-01/02/03): key bindings, hero loadouts and waypoint unlocks
## live in user://aotl_save.cfg instead of three separate files. Writes are atomic (temp file, keep the previous save
## as .bak, then rename). On first use the old per-feature files are migrated and renamed *.migrated.
## Sections: [meta] version · [keybinds] · [keybind_options] · [loadout_<hero>] · [waypoints]

const PATH := "user://aotl_save.cfg"
const VERSION := 1
const LEGACY := {"keybinds": "user://aotl_keybinds.cfg", "loadout": "user://aotl_loadout.cfg", "waypoints": "user://aotl_waypoints.cfg"}

static func open() -> ConfigFile:
	var cf := ConfigFile.new()
	if cf.load(PATH) == OK:
		var v := int(cf.get_value("meta", "version", 0))
		if v > VERSION:
			push_warning("AOTL save is from a newer build (v%d); loading what this build understands" % v)
		return cf
	if cf.load(PATH + ".bak") == OK:            # last good save survives a failed write
		return cf
	cf = ConfigFile.new()
	_migrate_legacy(cf)
	return cf

static func commit(cf: ConfigFile) -> bool:
	cf.set_value("meta", "version", VERSION)
	cf.set_value("meta", "saved_unix", Time.get_unix_time_from_system())
	var tmp := PATH + ".tmp"
	if cf.save(tmp) != OK:
		push_error("AOTL save: could not write %s" % tmp)
		return false
	var dir := DirAccess.open("user://")
	if dir.file_exists(PATH.get_file()):
		if dir.file_exists((PATH + ".bak").get_file()): dir.remove((PATH + ".bak").get_file())
		dir.rename(PATH.get_file(), (PATH + ".bak").get_file())
	return dir.rename(tmp.get_file(), PATH.get_file()) == OK

static func _migrate_legacy(cf: ConfigFile) -> void:
	var any := false
	var old := ConfigFile.new()
	if old.load(LEGACY["keybinds"]) == OK:
		for k in old.get_section_keys("binds") if old.has_section("binds") else []:
			cf.set_value("keybinds", k, old.get_value("binds", k))
		if old.has_section_key("options", "combine_move_attack"):
			cf.set_value("keybind_options", "combine_move_attack", old.get_value("options", "combine_move_attack"))
		any = true
	old = ConfigFile.new()
	if old.load(LEGACY["loadout"]) == OK:
		for hero in old.get_sections():
			for k in old.get_section_keys(hero):
				cf.set_value("loadout_" + hero, k, old.get_value(hero, k))
		any = true
	old = ConfigFile.new()
	if old.load(LEGACY["waypoints"]) == OK:
		cf.set_value("waypoints", "unlocked", old.get_value("waypoints", "unlocked", []))
		any = true
	if any and commit(cf):
		var dir := DirAccess.open("user://")
		for k in LEGACY:
			var f: String = LEGACY[k].get_file()
			if dir.file_exists(f): dir.rename(f, f + ".migrated")
