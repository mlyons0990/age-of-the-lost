extends SceneTree
## Blueprint free items: CAM-06 lab panel toggle, SAVE-01/02/03 one versioned atomic save with legacy migration,
## UI-09 painted-zone minimap drawn from zone data.
var checks := 0
var failures := 0
var out := ""
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + why)
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	call_deferred("_run")
func _rm(f: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
func _run() -> void:
	for f in ["user://aotl_save.cfg", "user://aotl_save.cfg.bak", "user://aotl_save.cfg.tmp", "user://aotl_keybinds.cfg", "user://aotl_loadout.cfg", "user://aotl_waypoints.cfg", "user://aotl_keybinds.cfg.migrated", "user://aotl_loadout.cfg.migrated", "user://aotl_waypoints.cfg.migrated"]:
		_rm(f)
	# legacy files from an older build
	var kb := ConfigFile.new(); kb.set_value("binds", "skill_1", ["key:A", ""]); kb.save("user://aotl_keybinds.cfg")
	var lo := ConfigFile.new(); lo.set_value("knight", "potions", ["hp", "hp", "mp", "mp", "hp"]); lo.save("user://aotl_loadout.cfg")
	var wp := ConfigFile.new(); wp.set_value("waypoints", "unlocked", ["whisperwood_shrine"]); wp.save("user://aotl_waypoints.cfg")
	var SAVE = load("res://scripts/three_d/aotl_save.gd")
	var cf: ConfigFile = SAVE.open()
	check(cf.get_value("keybinds", "skill_1", [])[0] == "key:A" and cf.get_value("waypoints", "unlocked", []).has("whisperwood_shrine") and cf.has_section("loadout_knight"), "Old key bindings, loadout and waypoint files migrate into the one save")
	check(FileAccess.file_exists("user://aotl_save.cfg") and FileAccess.file_exists("user://aotl_keybinds.cfg.migrated") and not FileAccess.file_exists("user://aotl_keybinds.cfg"), "Legacy files renamed *.migrated after migration")
	check(int(cf.get_value("meta", "version", 0)) == SAVE.VERSION, "Save carries a schema version")
	cf.set_value("waypoints", "unlocked", ["whisperwood_shrine", "crownsfall_town"]); SAVE.commit(cf)
	check(FileAccess.file_exists("user://aotl_save.cfg.bak") and not FileAccess.file_exists("user://aotl_save.cfg.tmp"), "Writes are atomic: previous save kept as .bak, no temp file left")
	var f := FileAccess.open("user://aotl_save.cfg", FileAccess.WRITE); f.store_string("[[corrupt"); f.close()
	check((SAVE.open() as ConfigFile).get_value("waypoints", "unlocked", []).has("whisperwood_shrine"), "A corrupted save falls back to the last good .bak")
	_rm("user://aotl_save.cfg"); _rm("user://aotl_save.cfg.bak")
	# game: lab panel hidden by default, F3 toggles, minimap from the zone painting
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 10: await physics_frame
	var hud = lab.hud
	check(not hud.lab_panel.visible, "Lab/debug panel hidden by default (play field clear)")
	var ev := InputEventKey.new(); ev.keycode = KEY_F3; ev.physical_keycode = KEY_F3; ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame; await process_frame
	check(hud.lab_panel.visible, "F3 shows the lab panel (debug build)")
	check(bool(SAVE.open().get_value("settings", "lab_panel", false)), "Panel choice saved")
	hud.toggle_lab_panel()
	check(not hud.lab_panel.visible, "F3 again hides it")
	check(hud.minimap_overview != null and not hud.minimap_tex_rect.visible and hud.minimap_vp.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Painted-zone minimap drawn from the zone painting (3D minimap camera off)")
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if out != "": img.save_png(out + "/free_items_hud.png")
	var r: Rect2 = hud.minimap_rect
	var dark := 0; var n := 0
	for y in range(int(r.position.y) + 4, int(r.end.y) - 4, 4):
		for x in range(int(r.position.x) + 4, int(r.end.x) - 4, 4):
			var c := img.get_pixel(x, y); n += 1
			if c.r + c.g + c.b < 0.15: dark += 1
	check(float(dark) / float(n) < 0.02, "No black margins in the minimap (%.1f%% dark)" % (100.0 * dark / n))
	print("AOTL FREE ITEMS RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
