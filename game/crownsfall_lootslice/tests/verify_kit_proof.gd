extends SceneTree
## Kit proof zone (owner 11-22, Higgsfield K1-K7): real kit art at true scale, world-space ground, baked canopy light,
## soft-edged props, flat decals, waypoint, free movement, hiding behind a trunk.
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
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	lab.painted_zone = "whisperwood_proof"
	root.add_child(lab)
	for i in 10: await physics_frame
	var g: MeshInstance3D = lab.find_child("KitGround", true, false)
	var gm: ShaderMaterial = g.material_override
	check(gm.get_shader_parameter("world_space") == true and gm.get_shader_parameter("use_light") == true, "Ground: world-space textures + baked light map")
	var props: Node = lab.find_child("KitProps", true, false)
	var pieces := 0; var fringe := 0; var decals := 0; var batched := 0
	for n in props.get_children():
		var k: int = int(n.get_meta("instances", 1))
		pieces += k
		if n is MultiMeshInstance3D: batched += 1
		var m: ShaderMaterial = n.material_override
		if m.shader.resource_path.ends_with("kit_decal.gdshader"): decals += k
		elif m.next_pass != null: fringe += k
	check(pieces == lab.zone["props"].size(), "All %d kit pieces placed (%d nodes, %d batches)" % [pieces, props.get_child_count(), batched])
	check(decals > 10 and fringe > 20, "Decals blended flat (%d); upright props have a soft-edge pass (%d)" % [decals, fringe])
	check(lab.find_child("KitShafts", true, false) != null, "Light shafts built")
	check(not get_root().find_children("Waypoint_*", "", true, false).is_empty(), "Waypoint placed in the glade")
	var tree: Dictionary = {}
	for p in lab.zone["props"]:
		if String(p["prop"]).begins_with("oak"): tree = p; break
	var tw: Vector3 = lab.zone_px_to_world(float(tree["at"][0]), float(tree["at"][1]))
	check(not lab.zone_walkable(tw), "Oak trunk is solid")
	var dec: Dictionary = {}           # a moss decal well clear of trunks and rocks (their own footprints are solid)
	for p in lab.zone["props"]:
		if String(p["prop"]) != "a_moss": continue
		var clear := true
		for s_ in lab.zone["solids"]:
			if Vector2(float(s_[0]) - float(p["at"][0]), (float(s_[1]) - float(p["at"][1])) * 2.0).length() < float(s_[2]) + 120.0: clear = false; break
		if clear and float(p["at"][0]) > 200 and float(p["at"][1]) > 300: dec = p; break
	check(lab.zone_walkable(lab.zone_px_to_world(float(dec["at"][0]), float(dec["at"][1]))), "Decals never block movement")
	# true scale: oak foot-to-top on screen ~ 13 m * cos31 * screen ppm
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/kit/forest_hf/catalog.json"))["props"][tree["prop"]]
	var tall_m: float = float(c["foot"][1]) * float(tree["scale"]) / lab.ZONE_PPM / cos(deg_to_rad(31.0))
	check(absf(tall_m - 13.0) < 1.5, "Oak stands at true size (%.1f m)" % tall_m)
	var a = lab.player
	var from: Vector3 = lab.zone_px_to_world(1000, 1000); var to: Vector3 = lab.zone_px_to_world(2900, 900)
	a.global_position = from + Vector3.UP * 0.05; lab.zone_last_ok = a.global_position
	lab.zone_move_to(to)
	var t := 0.0
	while t < 30.0 and (not lab.zone_route.is_empty() or a.move_target.is_finite()):
		await physics_frame; t += 1.0 / 60.0
	var miss := Vector2(a.global_position.x - to.x, a.global_position.z - to.z).length()
	check(miss < 0.8, "Hero walks across the glade between trees (%.2f m off)" % miss)
	print("AOTL KIT PROOF RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
