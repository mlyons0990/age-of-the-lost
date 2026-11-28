extends SceneTree
## Map (owner 11-26): M opens a full-screen zone map (fog of war, waypoints, exits, points of interest, quest
## objectives, the hero) and a world map (zones, links, discovery, you-are-here, quest zones); the minimap shows the
## same points of interest and quests. Exploration is saved.
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
func _key(code: Key) -> void:
	var e := InputEventKey.new(); e.keycode = code; e.physical_keycode = code; e.pressed = true
	Input.parse_input_event(e)
	await process_frame
	e = InputEventKey.new(); e.keycode = code; e.physical_keycode = code; e.pressed = false
	Input.parse_input_event(e)
	await process_frame
	await process_frame
func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if out != "": root.get_texture().get_image().save_png("%s/map_%s.png" % [out, name])
func _run() -> void:
	for f in ["user://aotl_save.cfg", "user://aotl_save.cfg.bak"]:
		if FileAccess.file_exists(f): DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	lab.painted_zone = "whisperwood_forest"
	lab.arpg_hud = true
	root.add_child(lab)
	for i in 10: await physics_frame
	var hud = lab.hud
	var wm = hud.world_map
	check(wm != null and not wm.visible, "Map exists and starts closed")
	check(hud.kb.action_for_event(_ev(KEY_M)) == "map", "M is bound to Open Map (rebindable)")
	# walk the hero past a few places so there is explored ground and an unlocked waypoint
	for at in [Vector2(600, 2600), Vector2(2000, 1000), Vector2(2400, 2250), Vector2(4300, 1750), Vector2(5650, 2900), Vector2(5900, 1520)]:
		lab.player.global_position = lab.zone_px_to_world(at.x, at.y) + Vector3.UP * 0.05
		lab.zone_last_ok = lab.player.global_position
		await create_timer(0.35).timeout
	await create_timer(1.0).timeout
	var frac: float = wm.explored_fraction("whisperwood_forest")
	check(frac > 0.05 and frac < 0.6, "Fog of war: explored part of the zone only (%.0f%%)" % (frac * 100.0))
	await _key(KEY_M)
	check(wm.visible and wm.mode == "zone", "M opens the zone map")
	var ms: Array = wm.zone_markers("whisperwood_forest")
	var kinds := {}
	for m in ms: kinds[m["kind"]] = int(kinds.get(m["kind"], 0)) + 1
	print("markers ", kinds)
	check(kinds.get("hero", 0) == 1 and kinds.get("exit", 0) == 2, "Zone map shows the hero and both exits (Crownsfall, Hollowmere)")
	check(kinds.get("quest", 0) == 3, "Zone map shows the 3 Lost Tomes objectives")
	check(kinds.get("landmark", 0) >= 1, "Zone map shows the points of interest already explored")
	check(not kinds.has("secret") and kinds.get("landmark", 0) < 5, "Unexplored places (incl. the secret Fae Ring) stay hidden")
	var unlocked: bool = lab.waypoint_net.is_unlocked("whisperwood_glade")
	check(unlocked and kinds.get("waypoint", 0) == 1, "Waypoint appears on the map once discovered")
	await _shot("zone")
	await _key(KEY_TAB)
	check(wm.mode == "world", "Tab switches to the world map")
	await _shot("world")
	var names := []
	for wn in wm.world_nodes: names.append(wn["node"]["id"])
	check("crownsfall" in names and "whisperwood" in names and "hollowmere" in names, "World map lists the zones")
	check(wm.is_discovered("whisperwood") and wm.is_discovered("crownsfall") and not wm.is_discovered("hollowmere"), "Discovered: Crownsfall + Whisperwood; Hollowmere not yet")
	await _key(KEY_ESCAPE)
	check(not wm.visible, "Esc closes the map")
	await _key(KEY_M)
	await _key(KEY_M)
	check(not wm.visible, "M toggles the map closed again")
	wm.save_explored()
	var wm2 = load("res://scripts/three_d/world_map.gd").new()
	wm2.setup(lab, hud)
	check(absf(wm2.explored_fraction("whisperwood_forest") - frac) < 0.02, "Exploration is saved and restored")
	wm2.free()
	# minimap with a quest arrow / POIs
	await _shot("minimap")
	print("AOTL WORLD MAP RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
func _ev(code: Key) -> InputEventKey:
	var e := InputEventKey.new(); e.keycode = code; e.physical_keycode = code; e.pressed = true
	return e
