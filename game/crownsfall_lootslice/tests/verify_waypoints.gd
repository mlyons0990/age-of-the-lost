extends SceneTree
## Waypoints + portals: town waypoint open from the start; Whisperwood's shrine waypoint unlocks on arrival; the
## waypoint window teleports to town and back; unlocks persist; zone exits carry a blue/gold portal aura.
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
func _wait(cond: Callable, secs: float) -> float:
	var t := 0.0
	while not cond.call() and t < secs:
		await physics_frame; t += 1.0 / 60.0
	return t
func _click_waypoint(lab) -> void:
	var w: Dictionary = lab.zone_waypoints[0]
	lab.handle_click(lab.camera.unproject_position(w["pos"]))
func _run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://aotl_waypoints.cfg"))
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 10: await physics_frame
	var a = lab.player
	var net = lab.waypoint_net
	check(net.is_unlocked("crownsfall_town") and not net.is_unlocked("whisperwood_shrine"), "Town waypoint open from the start; Whisperwood locked")
	var portals := get_nodes_in_group("zone_portal")
	check(portals.size() == 1 and portals[0].find_children("*", "CPUParticles3D", true, false).size() == 1 and portals[0].find_children("*", "OmniLight3D", true, false).size() == 1, "Plaza exit has a glowing portal aura (curtain, sparks, light)")
	await create_timer(0.4).timeout
	_click_waypoint(lab)
	await _wait(func(): return lab.waypoint_panel != null and is_instance_valid(lab.waypoint_panel), 6.0)
	check(lab.waypoint_panel != null and is_instance_valid(lab.waypoint_panel), "Clicking the town waypoint walks there and opens the waypoint window")
	if lab.waypoint_panel != null and is_instance_valid(lab.waypoint_panel):
		var b: Button = lab.waypoint_panel.buttons["whisperwood_shrine"]
		check(b.disabled and "???" in b.text, "Locked waypoints show as ??? and cannot be chosen")
		await _shot("waypoint_town_panel")
		lab.waypoint_panel.close()
	# walk out through the portal to Whisperwood
	a.command_move(lab.zone_px_to_world(2220, 1180))
	await create_timer(2.5).timeout
	await _shot("portal_plaza")
	a.command_move(lab.zone_px_to_world(2200, 1640))
	await _wait(func(): return lab.painted_zone == "whisperwood", 12.0)
	while lab.zone_traveling: await process_frame
	check(lab.painted_zone == "whisperwood", "Portal on the south road leads to Whisperwood")
	var wnode: Node3D = lab.zone_waypoints[0]["node"]
	check((wnode.get_node("Plinth") as MeshInstance3D).material_override.albedo_texture.resource_path.ends_with("waypoint_plinth.png") and not (wnode.get_node("Beam") as MeshInstance3D).visible and not (wnode.get_node("Label") as Label3D).visible, "Undiscovered waypoint is dormant: no light, no label, no \"locked\" text")
	check(lab.zone_walkable(lab.zone_waypoints[0]["pos"]), "Shrine ruins are walkable (waypoint area open)")
	a.command_move(lab.zone_px_to_world(1480, 820))
	await create_timer(3.0).timeout
	await _shot("waypoint_dormant")
	var unlocked := [false]
	lab.waypoint_unlocked.connect(func(_id): unlocked[0] = true)
	_click_waypoint(lab)
	await _wait(func(): return lab.waypoint_panel != null and is_instance_valid(lab.waypoint_panel), 10.0)
	check(unlocked[0] and net.is_unlocked("whisperwood_shrine"), "Reaching the shrine waypoint unlocks it")
	check((wnode.get_node("Beam") as MeshInstance3D).visible, "Unlocked waypoint lights up")
	var ptex: Texture2D = (wnode.get_node("Plinth") as MeshInstance3D).material_override.albedo_texture
	check(ptex != null and ptex.resource_path.ends_with("waypoint_plinth_lit.png"), "Discovered waypoint switches to the glowing platform art (WP2)")
	await create_timer(0.5).timeout
	await _shot("waypoint_shrine_panel")
	# the waypoint's visual centre (its basin) must land on the centre of the ruins it sits in
	var wdef: Dictionary = lab.zone["waypoints"][0]
	var rc: Vector2 = lab.camera.unproject_position(lab.zone_px_to_world(float(wdef["centre_of"][0]), float(wdef["centre_of"][1])))
	var bc: Vector2 = lab.camera.unproject_position((wnode.get_node("Rune") as Node3D).global_position)
	print("ruins centre on screen %s, waypoint centre %s" % [rc, bc])
	check(rc.distance_to(bc) < 10.0, "Waypoint centre sits on the centre of the ruins (%.1f px off)" % rc.distance_to(bc))
	check(lab.waypoint_panel != null and is_instance_valid(lab.waypoint_panel), "Waypoint window opens at the shrine")
	# teleport to town
	lab.waypoint_panel.buttons["crownsfall_town"].pressed.emit()
	await _wait(func(): return lab.painted_zone == "crownsfall" and not lab.zone_traveling, 6.0)
	await create_timer(0.8).timeout
	var tdef: Dictionary = lab.zone["waypoints"][0]
	var trc: Vector2 = lab.camera.unproject_position(lab.zone_px_to_world(float(tdef["centre_of"][0]), float(tdef["centre_of"][1])))
	var tbc: Vector2 = lab.camera.unproject_position((lab.zone_waypoints[0]["node"].get_node("Rune") as Node3D).global_position)
	check(trc.distance_to(tbc) < 10.0, "Town waypoint centre sits on the compass rose centre (%.1f px off)" % trc.distance_to(tbc))
	check(lab.painted_zone == "crownsfall" and lab.zone_world_to_px(a.global_position).distance_to(Vector2(1905, 1027)) < 120.0, "Teleported to town, standing at the town waypoint")
	# and back to the newly unlocked waypoint
	_click_waypoint(lab)
	await _wait(func(): return lab.waypoint_panel != null and is_instance_valid(lab.waypoint_panel), 6.0)
	var back: Button = lab.waypoint_panel.buttons["whisperwood_shrine"] if lab.waypoint_panel != null and is_instance_valid(lab.waypoint_panel) else null
	check(back != null and not back.disabled, "From town the unlocked shrine waypoint can be chosen")
	if back != null: back.pressed.emit()
	await _wait(func(): return lab.painted_zone == "whisperwood" and not lab.zone_traveling, 6.0)
	await create_timer(0.8).timeout
	check(lab.painted_zone == "whisperwood" and lab.zone_world_to_px(a.global_position).distance_to(Vector2(1995, 1012)) < 120.0, "Teleported back to the shrine waypoint")
	var fresh = load("res://scripts/three_d/waypoints.gd").new()
	check(fresh.is_unlocked("whisperwood_shrine"), "Unlocked waypoints persist (saved)")
	await _shot("waypoint_back_at_shrine")
	print("AOTL WAYPOINT RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
