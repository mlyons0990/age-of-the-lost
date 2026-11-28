extends SceneTree
## Phase 4 groundwork checks for the Hollow Sun radiant FX (headless-safe).
const RFX := preload("res://scripts/three_d/radiant_vfx.gd")
var passed := 0
var failed := 0
func check(ok: bool, msg: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		print("FAIL ", msg)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var fx: Node3D = RFX.new(); root.add_child(fx)
	var s: MeshInstance3D = fx.sigil(Vector3(1, 0, 2), 1.2)
	check(s.mesh is QuadMesh and is_equal_approx((s.mesh as QuadMesh).size.x, 2.4), "sigil quad sized to diameter")
	check(s.global_position.distance_to(Vector3(1, 0.10, 2)) < 1e-3, "sigil sits just above ground")
	var sm := s.material_override as ShaderMaterial
	check(sm != null and sm.shader.code.contains("blend_mix"), "sigil alpha-blended shader (reads on pale stone)")
	for p in ["reveal", "spin", "intensity"]:
		check(sm.get_shader_parameter(p) != null, "sigil param %s initialised (tweenable)" % p)
	var vert: MeshInstance3D = fx.sigil(Vector3.ZERO, 0.7, 1.0, 1.0, Vector3.BACK)
	check(vert.global_basis.y.dot(Vector3.BACK) > 0.99, "halo sigil faces requested normal")
	var c: MeshInstance3D = fx.crescent(Vector3.ZERO, Vector3(1, 0, 0), 1.8, deg_to_rad(200.0))
	var aabb := c.mesh.get_aabb()
	check(aabb.size.x > 1.5 and aabb.size.z > 2.5, "crescent spans the arc (%s)" % aabb.size)
	check(aabb.end.x > 1.7, "crescent centred on facing +X")
	check((c.material_override as ShaderMaterial).get_shader_parameter("progress") == 0.0, "crescent starts unswept")
	var st: MeshInstance3D = fx.starburst(Vector3.UP, 0.8)
	check((st.material_override as ShaderMaterial).shader.code.contains("INV_VIEW_MATRIX"), "starburst billboards")
	for child in fx.get_children(): child.queue_free()
	await process_frame
	var made: Array = fx.judgment(Vector3.ZERO, Vector3(0, 0, 1), 3.0)
	check(made.size() == 11, "judgment builds 11 pieces (%d)" % made.size())
	var names := {}
	for n in made: names[String(n.name).replace("@", "").rstrip("0123456789")] = true
	check(names.has("RadiantSigil") and names.has("RadiantCrescent") and names.has("RadiantStar"), "judgment mixes sigils, crescents and stars")
	var landing := false
	for n in made:
		if String(n.name).contains("RadiantSigil") and n.global_position.distance_to(Vector3(0, 0.10, 3.0)) < 1e-3: landing = true
	if not landing:
		for n in made: print(n.name, " ", n.global_position)
	check(landing, "landing sigil at reach along facing")
	# everything cleans itself up
	var end_t := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < end_t:
		await process_frame
	check(fx.get_child_count() == 0, "all FX freed after lifetime (%d left)" % fx.get_child_count())
	# lab wiring
	var lab_src := FileAccess.get_file_as_string("res://scenes/pilot_mage_combat_lab.tscn")
	check(lab_src.contains("radiant_spell_fx = true"), "mage lab opts in to radiant FX")
	var knight_src := FileAccess.get_file_as_string("res://scenes/pilot_knight_combat_lab.tscn")
	check(not knight_src.contains("radiant_spell_fx"), "knight lab unchanged")
	print("RADIANT_VFX %d/%d passed" % [passed, passed + failed])
	quit(0 if failed == 0 else 1)
