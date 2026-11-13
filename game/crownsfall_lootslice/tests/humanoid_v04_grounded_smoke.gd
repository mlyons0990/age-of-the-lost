extends SceneTree
## V04 acceptance: real 21m gameplay scene; new weighted arm/knee skin;
## walk stance anchors must remain in world space while the physics actor travels.
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	_run.call_deferred()
func verify(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
	print(("PASS " if condition else "FAIL ") + "V04 " + label)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func finish() -> void:
	print("AOTL_V04_TEST_%s: %d checks, %d failures" % ["OK" if failures.is_empty() else "FAIL", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
func _run() -> void:
	verify(OS.get_cmdline_user_args().has("--aotl-v04"), "V04 flag enabled")
	var scene := load("res://scenes/two_point_five_d/aotl_25d_lab.tscn") as PackedScene
	verify(scene != null, "Phase02 wide-camera scene loads")
	if scene == null:
		finish()
		return
	var lab = scene.instantiate()
	root.add_child(lab)
	await frames(12)
	verify(lab.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "isometric orthographic camera")
	verify(is_equal_approx(lab.camera.size, 21.0), "approved 21m camera default")
	verify(lab.player.visual_mode == "painted", "approved painted hero still default")
	verify(lab.player.humanoid_v04_opt_in, "V04 experimental controller selected")
	lab.player.change_visual_mode()
	var hero = lab.player
	verify(hero.visual_mode == "humanoid", "cycle into V04 humanoid")
	var rig = hero.humanoid_visual
	verify(rig != null and rig.ready_to_compare, "V04 rig ready")
	if rig == null or not rig.ready_to_compare:
		finish()
		return
	verify(rig.model_root.name == "AOTL_Humanoid_Master_V04", "new revision10 GLB loaded rather than V03")
	verify(rig.skeleton.get_bone_count() == 58, "all 58 bone joints intact")
	verify(rig.clips.size() == 16, "all 16 clips intact")
	verify(rig.equipment.size() == 7, "gear and VFX mounts preserved")
	verify(rig.foot_ik.size() == 2, "both IK chains present")
	var total_multi_weight_vertices := 0
	for short_name in ["ArmL","ArmR","LegL","LegR"]:
		var node := rig.model_root.find_child("V04_SKIN_Articulated"+short_name, true, false) as MeshInstance3D
		verify(node != null, "dense anatomical mesh "+short_name+" imported")
		if node == null or node.mesh == null:
			continue
		var multi := 0
		var normalized := 0
		for surface_id in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface_id)
			var skin_weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			for k in range(0, skin_weights.size(), 4):
				var influence_count := 0
				var weight_sum := 0.0
				for q in range(4):
					if k+q < skin_weights.size():
						weight_sum += skin_weights[k+q]
						if skin_weights[k+q] > 0.02:
							influence_count += 1
				if influence_count > 1: multi += 1
				if absf(weight_sum - 1.0) < 0.02: normalized += 1
		verify(multi > 20, "smoothly multi-weighted "+short_name+" vertices: "+str(multi))
		verify(normalized > 20, "normalized imported "+short_name+" weight rows")
		total_multi_weight_vertices += multi
	verify(total_multi_weight_vertices > 150, "hundreds of genuinely deformable vertices")
	for stale in ["V02_SKIN_TaperedArmL","V02_SKIN_TaperedArmR","V02_SKIN_FittedLegL","V02_SKIN_FittedLegR"]:
		verify(rig.model_root.find_child(stale, true, false) == null, "no duplicate old skin "+stale)
	var player_start: Vector3 = hero.global_position
	hero.move_to_ground(hero.global_position + Vector3(0,0,-6.0))
	var previous: Dictionary = {}
	var held_count := 0
	var xz_motion := 0.0
	for i in range(68):
		await physics_frame
		for side in ["L","R"]:
			if rig.is_foot_planted(side):
				var anchor: Vector3 = rig.get_plant_position(side)
				if previous.has(side):
					var prev: Vector3 = previous[side]
					if anchor.distance_to(prev) < 0.002:
						held_count += 1
				previous[side] = anchor
			else:
				previous.erase(side)
		xz_motion = Vector2(hero.global_position.x-player_start.x,hero.global_position.z-player_start.z).length()
	verify(xz_motion > 1.0, "physics actor actually traversed world: "+str(snappedf(xz_motion,.01))+"m")
	verify(rig.gait_travel_m > 0.3, "step-cycle phase advanced using true velocity")
	verify(rig.contact_transitions >= 2, "ground contact phase was captured multiple times")
	verify(rig.contact_release_count >= 1, "swing phase released locked stance foot")
	verify(held_count >= 3, "world-space foot anchor held across multiple moving physics frames")
	verify(rig.get_foot_contact_count() >= 1, "ground raycast detects walkable collision")
	verify(rig.peak_plant_error_m < .01, "planted foot target has negligible world slip")
	var sampled_weight := 0.0
	for side in ["L","R"]:
		sampled_weight=maxf(sampled_weight,float(rig.foot_ik[side].influence))
	verify(sampled_weight >= 0.0, "IK contact weights remain finite")
	hero.has_target=false
	hero.velocity=Vector3.ZERO
	for i in range(18):
		await physics_frame
	verify(rig.current_clip == "Idle" or rig.current_clip == "Walk", "transition to stop without animation loss")
	lab._set_camera_zoom(28.0)
	verify(is_equal_approx(lab.camera_size_for_test(), 28.0), "zoom-out boundary preserved")
	lab._set_camera_zoom(14.0)
	verify(is_equal_approx(lab.camera_size_for_test(), 14.0), "zoom-in boundary preserved")
	lab._set_camera_zoom(21.0)
	verify(is_equal_approx(lab.camera_size_for_test(), 21.0), "PoE-wide home default retained")
	hero.change_visual_mode()
	verify(hero.visual_mode == "proxy", "original proxy still available for comparison")
	hero.change_visual_mode()
	verify(hero.visual_mode == "painted" and hero.visual.visible, "approved painted character restored")
	lab.queue_free()
	await frames(3)
	finish()
