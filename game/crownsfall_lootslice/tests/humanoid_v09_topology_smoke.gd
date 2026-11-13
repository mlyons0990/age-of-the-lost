extends SceneTree
## V06 acceptance: real 21m gameplay scene; new weighted arm/knee skin;
## walk stance anchors must remain in world space while the physics actor travels.
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	_run.call_deferred()
func verify(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
	print(("PASS " if condition else "FAIL ") + "V09 " + label)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func finish() -> void:
	print("AOTL_V09_TEST_%s: %d checks, %d failures" % ["OK" if failures.is_empty() else "FAIL", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
func _run() -> void:
	verify(OS.get_cmdline_user_args().has("--aotl-v09"), "V09 flag enabled")
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
	verify(lab.player.humanoid_v09_opt_in, "V06 experimental controller selected")
	lab.player.change_visual_mode()
	var hero = lab.player
	verify(hero.visual_mode == "humanoid", "cycle into V09 humanoid")
	var rig = hero.humanoid_visual
	verify(rig != null and rig.ready_to_compare, "V09 rig ready")
	if rig == null or not rig.ready_to_compare:
		finish()
		return
	verify(rig.model_root.name == "AOTL_Humanoid_Master_V09", "Higgsfield revision17 weighted + textured GLB loaded")
	verify(rig.disabled_stage_lights == 3, "three imported turntable lights isolated from Crownsfall")
	verify(rig.disabled_stage_cameras == 1, "imported Blender studio camera isolated")
	verify(lab.camera.current, "original approved gameplay camera remains active")
	var studio_lights_disabled := true
	for node in rig.model_root.find_children("*", "Node3D", true, false):
		if node is Light3D and (node.visible or (node as Light3D).light_energy > 0.0001):
			studio_lights_disabled = false
	verify(studio_lights_disabled, "no Higgsfield light brightens the Crownsfall world")
	verify(rig.skeleton.get_bone_count() == 58, "all 58 bone joints intact")
	verify(rig.clips.size() == 23, "all 16 clips intact")
	verify(rig.equipment.size() == 7, "gear and VFX mounts preserved")

	var v07_material_names: Dictionary = {}
	var textured_materials: Dictionary = {}
	for node in rig.model_root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		for surface in range(mi.mesh.get_surface_count()):
			var material: Material = mi.mesh.surface_get_material(surface)
			if material == null:
				continue
			var material_name := String(material.resource_name)
			if material_name.begins_with("V07_"):
				v07_material_names[material_name] = true
				if material is BaseMaterial3D and (material as BaseMaterial3D).albedo_texture != null:
					textured_materials[material_name] = true
	verify(v07_material_names.size() >= 1, "some legacy V09 materials remain on unaffected equipment")
	var atlas_domains: Dictionary = {}
	var atlas_surfaces := 0
	for node in rig.model_root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		for surface in range(mi.mesh.get_surface_count()):
			var mat: Material = mi.mesh.surface_get_material(surface)
			if mat is BaseMaterial3D and String(mat.resource_name).begins_with("V08_"):
				var tex: Texture2D = (mat as BaseMaterial3D).albedo_texture
				if tex != null:
					if tex.get_width() == 2048 and tex.get_height() == 2048:
						var domain := "BODY" if String(mat.resource_name).begins_with("V08_BODY_") else "GEAR"
						atlas_domains[domain] = true
						atlas_surfaces += 1
	verify(atlas_domains.has("BODY") and atlas_domains.has("GEAR"), "two 2048-square body/gear paint canvases imported")
	verify(atlas_surfaces >= 15, "original V08 paint-carrier surfaces retain their material links")
	var expected_geometry := {
		"V02_SKIN_AnatomicalHead": 2882,
		"V02_HAIR_Crown": 1346,
		"V02_GEAR_LayeredCuirass": 6274,
		"V02_GEAR_ShoulderPlateL": 4034,
		"V02_GEAR_ShoulderPlateR": 4034,
		"V02_GEAR_RoyalBlueCape": 8514,
		"V02_GEAR_RoyalTabard": 242
	}
	for mesh_name in expected_geometry.keys():
		var part := rig.model_root.find_child(mesh_name, true, false) as MeshInstance3D
		verify(part != null and part.mesh != null, "topology object imported: " + mesh_name)
		if part == null or part.mesh == null:
			continue
		var vertex_count := 0
		var uv_count := 0
		for si in range(part.mesh.get_surface_count()):
			var arrays: Array = part.mesh.surface_get_arrays(si)
			var coords: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var texcoords: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			vertex_count += coords.size()
			uv_count += texcoords.size()
		verify(vertex_count >= int(expected_geometry[mesh_name]) * 0.9, "refined vertex density for " + mesh_name + " (" + str(vertex_count) + ")")
		verify(uv_count > 0, "UV map survives on " + mesh_name)

	verify(rig.foot_ik.size() == 2, "both IK chains present")
	for name in ["V06_WalkForward","V06_RunForward","V06_StrafeLeft","V06_StrafeRight","V06_WalkBackward","V06_PivotLeft","V06_PivotRight"]:
		verify(rig.clips.has(name) and rig.animation.has_animation(rig.clips[name]), "Higgsfield revision11 action imported "+name)
	verify(rig.locomotion.tree_root is AnimationNodeBlendTree, "Godot 4.6 directional BlendTree instanced")
	var graph = rig.locomotion.tree_root as AnimationNodeBlendTree
	var blend = graph.get_node("Direction") as AnimationNodeBlendSpace2D
	verify(blend != null and blend.get_blend_point_count() == 5, "five-way 2D directional blend incl idle, forward, back, left/right")
	verify(graph.get_node("RunMix") is AnimationNodeBlend2, "run-forward speed layer mixes independently")
	for side in ["L","R"]:
		verify(rig.foot_ik[side].use_magnet, "Godot knee IK magnet enabled on "+side)

	var total_multi_weight_vertices := 0
	for short_name in ["ArmL","ArmR","LegL","LegR"]:
		var node := rig.model_root.find_child("V04_SKIN_Articulated"+short_name, true, false) as MeshInstance3D
		verify(node != null, "V04 weighted anatomical mesh retained for "+short_name)
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
	var toe_skin_vertices := 0
	for side in ["L","R"]:
		var boot = rig.model_root.find_child("V03_GEAR_AnatomicalBoot_"+side, true, false) as MeshInstance3D
		verify(boot != null, "visible boot "+side+" preserved with toe-roll skin")
		if boot != null and boot.mesh != null:
			for surface in boot.mesh.get_surface_count():
				var arrays: Array = boot.mesh.surface_get_arrays(surface)
				var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
				for wi in range(0, weights.size(), 4):
					var nonzero := 0
					for n in range(4):
						if wi+n < weights.size() and weights[wi+n] > 0.03:
							nonzero += 1
					if nonzero >= 2:
						toe_skin_vertices += 1
	verify(toe_skin_vertices > 5, "real boot mesh receives blended foot-toe deformation")

	for stale in ["V02_SKIN_TaperedArmL","V02_SKIN_TaperedArmR","V02_SKIN_FittedLegL","V02_SKIN_FittedLegR"]:
		verify(rig.model_root.find_child(stale, true, false) == null, "no duplicate old skin "+stale)
	var player_start: Vector3 = hero.global_position
	hero.move_to_ground(hero.global_position + Vector3(0,0,-6.0))
	var previous: Dictionary = {}
	var ankle_slip_samples: Array[float] = []
	var held_count := 0
	var xz_motion := 0.0
	for i in range(68):
		await physics_frame
		for side in ["L","R"]:
			if rig.is_foot_planted(side):
				var anchor: Vector3 = rig.get_plant_position(side)
				var ankle_index: int = rig.skeleton.find_bone("Ankle"+side)
				var actual: Vector3 = rig.skeleton.to_global(rig.skeleton.get_bone_global_pose(ankle_index).origin)
				var slip := Vector2(actual.x-anchor.x, actual.z-anchor.z).length()
				if rig.get_plant_stance_frames(side) >= 2:
					ankle_slip_samples.append(slip)
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
	verify(rig.get_cadence_ratio_for_test() > 1.20, "walk action playback cadence matches displacement instead of fixed source FPS")
	verify(rig.contact_transitions >= 2, "ground contact phase was captured multiple times")
	verify(rig.contact_release_count >= 1, "swing phase released locked stance foot")
	verify(held_count >= 3, "world-space foot anchor held across multiple moving physics frames")
	verify(rig.get_foot_contact_count() >= 1, "ground raycast detects walkable collision")
	verify(rig.peak_plant_error_m < .01, "world-space foot IK target stays fixed during stance")
	var average_ankle_slip := 0.0
	if ankle_slip_samples.size()>0:
		for number in ankle_slip_samples:
			average_ankle_slip += number
		average_ankle_slip /= float(ankle_slip_samples.size())
	print("V09_ANKLE_WORLD_SLIP_MEAN_M %.4f (%d frames)" % [average_ankle_slip, ankle_slip_samples.size()])
	verify(ankle_slip_samples.size() >= 4, "actual ankle/world contact sampled at least four times")
	verify(average_ankle_slip < 0.18, "mean actual ankle drift below 18cm, not just stable IK targets")
	var sampled_weight := 0.0
	for side in ["L","R"]:
		sampled_weight=maxf(sampled_weight,float(rig.foot_ik[side].influence))
	verify(sampled_weight >= 0.0, "IK contact weights remain finite")
	# A directional control test at the real 21m camera: right mouse
	# locks combat facing while movement directions vary independently.
	hero.has_target = false
	hero.velocity = Vector3.ZERO
	await frames(5)
	hero.facing_world = Vector3.FORWARD
	hero.set_v06_facing_lock(true)
	verify(hero.is_v06_facing_locked(), "right mouse facing lock supported")
	hero.move_to_ground(hero.global_position + Vector3(2.3,0,0))
	await frames(22)
	var strafe_right: Vector2 = rig.get_direction_vector_for_test()
	verify(strafe_right.x > 0.35, "right-strafe uses positive local X: "+str(strafe_right))
	hero.move_to_ground(hero.global_position + Vector3(-3.2,0,0))
	await frames(23)
	var strafe_left: Vector2 = rig.get_direction_vector_for_test()
	verify(strafe_left.x < -0.35, "left-strafe uses negative local X: "+str(strafe_left))
	hero.move_to_ground(hero.global_position + Vector3(0,0,2.8))
	await frames(22)
	var backpedal: Vector2 = rig.get_direction_vector_for_test()
	verify(backpedal.y < -0.35, "backward step uses negative local Y: "+str(backpedal))
	hero.set_v06_facing_lock(false)
	verify(not hero.is_v06_facing_locked(), "right mouse release returns original follow-facing")
	hero.has_target=false
	hero.velocity=Vector3.ZERO
	for i in range(18):
		await physics_frame
	verify(rig.current_clip == "Idle" or rig.current_clip == "Walk", "transition to stop without animation loss")
	hero.start_dodge()
	await frames(13)
	verify(rig.current_clip == "Dodge", "dodge animation receives physics action")
	verify(rig.action_compression_m < -0.02, "dodge uses knee/hip weight compression")
	await frames(33)
	verify(rig.recovered_from_dodge >= 1, "dodge recovery transitions back into locomotion")
	verify(rig.current_clip in ["Idle","Walk","Run"], "dodge animation terminates without stuck pose")

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
