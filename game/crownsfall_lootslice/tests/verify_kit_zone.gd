extends SceneTree
## Kit zones (owner 11-22): ground layers + reusable props. Loads the Whisperwood kit mock-up and checks ground, props,
## per-prop collision, free movement between trees, pathfinding through the forest, hiding behind a tree, captures.
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
func _shot(lab, at: Vector2, name: String) -> void:
	lab.player.global_position = lab.zone_px_to_world(at.x, at.y) + Vector3.UP * 0.05
	lab.zone_last_ok = lab.player.global_position
	lab.zone_cam_focus = Vector3.INF
	await create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	print("%s hero screen %s walkable %s visible %s" % [name, lab.camera.unproject_position(lab.player.global_position + Vector3.UP), lab.zone_walkable(lab.player.global_position), lab.player.visible])
	if out != "": root.get_texture().get_image().save_png("%s/kit_%s.png" % [out, name])
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	lab.painted_zone = "whisperwood_kit"
	var t0 := Time.get_ticks_msec()
	root.add_child(lab)
	for i in 10: await physics_frame
	print("zone build %d ms" % (Time.get_ticks_msec() - t0))
	var a = lab.player
	check(lab.find_child("KitGround", true, false) != null, "Kit ground built (tileable layers + splat)")
	var props: Node = lab.find_child("KitProps", true, false)
	check(props != null and props.get_child_count() == lab.zone["props"].size(), "All %d props placed" % lab.zone["props"].size())
	check(lab.kit_grid != null, "Grid navigation built")
	# a tree trunk is solid, the ground beside it is free
	var tree: Dictionary = {}
	for p in lab.zone["props"]:
		if p["prop"] == "tree_oak": tree = p; break
	var tw: Vector3 = lab.zone_px_to_world(float(tree["at"][0]), float(tree["at"][1]))
	check(not lab.zone_walkable(tw), "Tree trunk is solid")
	check(lab.zone_walkable(lab.zone_px_to_world(float(tree["at"][0]) + 230.0, float(tree["at"][1]))), "Ground 230 px beside the trunk is walkable (free movement between trees)")
	var free := 0; var n := 0
	for x in range(400, 11000, 200):
		for y in range(400, 4800, 200):
			n += 1
			if lab.zone_walkable(lab.zone_px_to_world(x, y)): free += 1
	check(float(free) / n > 0.75, "Most of the zone is walkable (%.0f%%), not walled-off forest" % (100.0 * free / n))
	# path through the middle of the forest, off the paths
	var from := Vector2(2000, 3600); var to := Vector2(8000, 3000)
	var fw: Vector3 = lab.zone_px_to_world(from.x, from.y); var tw2: Vector3 = lab.zone_px_to_world(to.x, to.y)
	var t1 := Time.get_ticks_msec()
	var path: PackedVector2Array = lab.zone_find_path(Vector2(fw.x, fw.z), Vector2(tw2.x, tw2.z))
	print("path %d corners, %d ms" % [path.size(), Time.get_ticks_msec() - t1])
	check(path.size() >= 1 and Time.get_ticks_msec() - t1 < 300, "Path across the forest found quickly")
	var ok := true
	var prev := Vector2(fw.x, fw.z)
	for q in path:
		if not lab._kit_line_free(prev, q): ok = false
		prev = q
	check(ok, "Every leg of the route is clear of trunks, rocks and water")
	a.global_position = fw + Vector3.UP * 0.05; lab.zone_last_ok = a.global_position
	lab.zone_move_to(tw2)
	var t := 0.0
	while t < 40.0 and (not lab.zone_route.is_empty() or a.move_target.is_finite()):
		await physics_frame; t += 1.0 / 60.0
	var miss := Vector2(a.global_position.x - tw2.x, a.global_position.z - tw2.z).length()
	check(miss < 0.8, "Hero walks through the forest to the click (%.2f m off, %.1f s)" % [miss, t])
	# hide behind a tree: stand just behind (north of) a trunk
	lab.hud.visible = false
	await _shot(lab, Vector2(float(tree["at"][0]), float(tree["at"][1]) - 120.0), "behind_tree")
	await _shot(lab, Vector2(5900, 1650), "shrine")
	await _shot(lab, Vector2(4600, 1150), "stairs")
	await _shot(lab, Vector2(3800, 3000), "forest")
	await _shot(lab, Vector2(9300, 1300), "stele")
	await _shot(lab, Vector2(9300, 4000), "pools")
	print("AOTL KIT ZONE RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
