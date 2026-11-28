extends SceneTree
## Zone exits: walk off the plaza's south road into Whisperwood and back; hero lands on walkable ground, no bounce.
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
func _shot(name: String) -> void:
	if out == "": return
	await process_frame; await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 10: await physics_frame
	var a = lab.player
	check(lab.zone_exits.size() == 2 and lab.zone_exit_at(a.global_position).is_empty(), "Plaza has two exits (stairs, Kingsroad Gate) and the hero does not spawn on one")
	check(get_nodes_in_group("zone_exit_label").size() == 2, "Both exits are marked in the world")
	lab.zone_move_to(lab.zone_px_to_world(6250, 135))
	var t := 0.0
	while lab.painted_zone != "highward_steps" and t < 25.0:
		await physics_frame; t += 1.0 / 60.0
	check(lab.painted_zone == "highward_steps", "Climbing the grand stairs travels to Highward Steps (%.1fs)" % t)
	while lab.zone_traveling: await process_frame
	await create_timer(1.0).timeout
	check(lab.zone_walkable(a.global_position), "Hero arrives on Highward Steps' walkable ground")
	# the painted-zone checks below use the legacy painted Whisperwood (reached directly; no longer on the Crownsfall stairs)
	lab.travel_to("whisperwood", [720, 636])
	while lab.painted_zone != "whisperwood" or lab.zone_traveling: await process_frame
	await create_timer(1.5).timeout
	check(lab.zone_walkable(a.global_position), "Hero arrives on Whisperwood's walkable ground")
	check(lab.zone_exit_at(a.global_position).is_empty(), "Arrival point is off the return exit (no bounce)")
	check(lab.find_child("ZonePainting", true, false) != null and lab.get_children().filter(func(n): return n.name.begins_with("ZonePainting")).size() == 1, "Old painting freed, one painting in the scene")
	var top: float = lab.camera.unproject_position(a.global_position + Vector3.UP * 1.75).y
	var bot: float = lab.camera.unproject_position(a.global_position).y
	check(absf((bot - top) - 125.0) < 6.0, "Whisperwood hero size %.0f px (owner: 125 here)" % (bot - top))
	check(lab.zone_world_to_px(a.global_position).distance_to(Vector2(720, 636)) < 60.0, "Arrives at the foot of the top-left stairs")
	check(not lab.zone_walkable(lab.zone_px_to_world(2190, 1010)) and lab.zone_walkable(lab.zone_px_to_world(1995, 851)), "Stream is blocked; the shrine ruins (waypoint) are walkable")
	var vis := 0
	for tg in lab.targets:
		if tg.visible and lab.zone_walkable(tg.global_position): vis += 1
	check(vis == 4, "Whisperwood targets placed on its walkable ground (%d)" % vis)
	check(lab.hud.area_title.text == "Whisperwood" and lab.hud.area_sub.text == "Fallen Shrine", "Minimap header shows the new area")
	await _shot("travel_whisperwood")
	lab.zone_move_to(lab.zone_px_to_world(445, 285))
	t = 0.0
	while lab.painted_zone != "crownsfall" and t < 25.0:
		await physics_frame; t += 1.0 / 60.0
	check(lab.painted_zone == "crownsfall", "Return exit travels back to Crownsfall (%.1fs)" % t)
	while lab.zone_traveling: await process_frame
	await create_timer(1.5).timeout
	check(lab.zone_walkable(a.global_position) and lab.zone_exit_at(a.global_position).is_empty(), "Back on the plaza, off the exit")
	await _shot("travel_back_plaza")
	print("AOTL ZONE TRAVEL RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
