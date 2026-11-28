extends SceneTree
## Pathfinding: clicks route around the stream and the shrine's pillars instead of stopping at the first obstacle.
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + why)
func _initialize() -> void:
	call_deferred("_run")
func _walk(lab, a, to_px: Vector2, secs: float) -> float:
	var goal: Vector3 = lab.zone_px_to_world(to_px.x, to_px.y)
	lab.zone_move_to(goal)
	var t := 0.0
	var max_off := 0.0
	while t < secs:
		await physics_frame; t += 1.0 / 60.0
		if not lab.zone_walkable(a.global_position): max_off += 1.0
		if lab.zone_route.is_empty() and not a.move_target.is_finite(): break
	return Vector2(a.global_position.x - goal.x, a.global_position.z - goal.z).length()
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	lab.painted_zone = "whisperwood"
	root.add_child(lab)
	for i in 10: await physics_frame
	var a = lab.player
	check(lab.zone_nav_nodes.size() > 20, "Nav graph built around obstacles (%d corners)" % lab.zone_nav_nodes.size())
	check(not lab.zone_walkable(lab.zone_px_to_world(1497, 880)), "Shrine pillar is solid")
	# straight line from west of the shrine to beyond the stream crosses the water: must route around
	a.global_position = lab.zone_px_to_world(1500, 1150) + Vector3.UP * 0.05
	lab.zone_last_ok = a.global_position
	await physics_frame
	var direct: bool = lab.zone_line_clear(Vector2(a.global_position.x, a.global_position.z), Vector2(lab.zone_px_to_world(2600, 1000).x, lab.zone_px_to_world(2600, 1000).z))
	var path: PackedVector2Array = lab.zone_find_path(Vector2(a.global_position.x, a.global_position.z), Vector2(lab.zone_px_to_world(2600, 1000).x, lab.zone_px_to_world(2600, 1000).z))
	check(not direct and path.size() >= 2, "Route across the stream goes round it (%d legs)" % path.size())
	var miss: float = await _walk(lab, a, Vector2(2600, 1000), 20.0)
	check(miss < 0.6, "Hero arrives on the far side of the stream (%.2f m from the click)" % miss)
	# through the ruins: from the left arch to the waypoint without clipping a pillar
	a.global_position = lab.zone_px_to_world(1380, 760) + Vector3.UP * 0.05
	lab.zone_last_ok = a.global_position
	await physics_frame
	miss = await _walk(lab, a, Vector2(1995, 862), 20.0)
	check(miss < 0.6, "Hero walks around the shrine pillars to the waypoint (%.2f m)" % miss)
	print("AOTL ZONE PATHING RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
