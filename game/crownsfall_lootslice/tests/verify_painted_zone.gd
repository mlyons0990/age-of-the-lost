extends SceneTree
## 2D painted zone mode: painting laid out, hero ~100 px, walkable clamp, camera stays inside the painting.
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + why)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_mage_combat_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 10: await physics_frame
	check(not lab.zone.is_empty() and lab.find_child("ZonePainting", true, false) != null, "Painted zone loaded")
	check(lab.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Orthographic camera matches the painting")
	var a = lab.player
	var top: float = lab.camera.unproject_position(a.global_position + Vector3.UP * 1.75).y
	var bot: float = lab.camera.unproject_position(a.global_position).y
	check(absf((bot - top) - 100.0) < 6.0, "Hero ~100 px tall at 1080p (%.0f)" % (bot - top))
	check(lab.zone_walkable(a.global_position), "Hero spawns on walkable ground")
	var far: Vector3 = lab.zone_px_to_world(100, 1450)
	check(not lab.zone_walkable(far), "Painted wall/garden area is not walkable")
	a.command_move(far)
	await create_timer(2.0).timeout
	check(lab.zone_walkable(a.global_position), "Walking toward a blocked area stops at the walkable edge")
	# camera never shows past the painting
	var vs := Vector2(1920, 1080)
	var ok := true
	for c in [Vector2(0, 0), Vector2(vs.x - 1, 0), Vector2(0, vs.y - 1), vs - Vector2.ONE]:
		var g: Vector3 = lab.cursor_ground(c)
		var sz: Array = lab.zone["size"]
		var half_w: float = float(sz[0]) / lab.ZONE_PPM * 0.5
		var half_d: float = float(sz[1]) / lab.ZONE_PPM / sin(deg_to_rad(lab.ZONE_PITCH)) * 0.5
		ok = ok and absf(g.x) <= half_w + 0.05 and absf(g.z) <= half_d + 0.05
	check(ok, "Screen corners stay inside the painting (no void)")
	print("AOTL PAINTED ZONE RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
