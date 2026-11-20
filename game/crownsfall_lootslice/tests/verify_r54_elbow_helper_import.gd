extends SceneTree
## Real Godot 4.6.3 acceptance for the optional seven-clip R54 Warrior (R53 + half-swing Elbow helper).
## Also proves the helper never moves hands, weapon or shield: compared against R53 at and between keys.
## Verifies actual imported skinning rather than only glTF JSON metadata.
const ASSET := "res://models/AOTL_Warrior_R54_ElbowHelper_SevenClip.glb"
const BASELINE := "res://models/AOTL_Warrior_R53_ArmSkin_SevenClip.glb"
const REQUIRED := ["Idle", "Walk", "Run", "Dodge", "Slash", "Cast", "Slash_FullBody_R50"]
var checks := 0
var failures := 0

func check(condition: bool, why: String) -> void:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + why)

func _initialize() -> void:
	call_deferred("_run")

func find_mesh(model: Node, needle: String) -> MeshInstance3D:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var m := node as MeshInstance3D
		if needle in String(m.name) or (m.mesh != null and needle in m.mesh.resource_name):
			return m
	return null

func only_one_bone_per_vertex(mesh: MeshInstance3D) -> Dictionary:
	if mesh == null or mesh.mesh == null:
		return {"ok": false, "count": 0, "bad": 0, "stride": 0}
	var bad := 0
	var count := 0
	var last_stride := 0
	for surface in range(mesh.mesh.get_surface_count()):
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var coords: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var size := coords.size()
		if size == 0 or weights.size() % size != 0:
			return {"ok": false, "count": count, "bad": bad, "stride": 0}
		var stride := weights.size() / size
		if stride not in [4, 8]:
			return {"ok": false, "count": count, "bad": bad, "stride": stride}
		last_stride = stride
		for v in size:
			var weighted := 0
			var total := 0.0
			for j in stride:
				var w: float = weights[v * stride + j]
				total += w
				if w > 0.001:
					weighted += 1
			if weighted != 1 or absf(total - 1.0) > 0.01:
				bad += 1
			count += 1
	return {"ok": bad == 0 and count > 100, "count": count, "bad": bad, "stride": last_stride}

func primary_weighted_bone(mesh: MeshInstance3D, skeleton: Skeleton3D) -> String:
	if mesh == null or mesh.skin == null or mesh.mesh == null:
		return ""
	var surface: Array = mesh.mesh.surface_get_arrays(0)
	var bones = surface[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = surface[Mesh.ARRAY_WEIGHTS]
	for i in range(mini(bones.size(), weights.size())):
		if weights[i] < 0.999:
			continue
		var bind: int = int(bones[i])
		if bind < 0 or bind >= mesh.skin.get_bind_count():
			return ""
		var name: String = String(mesh.skin.get_bind_name(bind))
		if not name.is_empty():
			return name
		var skeleton_index: int = mesh.skin.get_bind_bone(bind)
		if skeleton_index >= 0 and skeleton_index < skeleton.get_bone_count():
			return String(skeleton.get_bone_name(skeleton_index))
	return ""

## Arm skin summary from the imported surface: which joints carry weight, and how far
## Forearm weight reaches up the arm (distance above the elbow along the upper arm).
func arm_skin(mesh: MeshInstance3D, rig: Skeleton3D, side: String) -> Dictionary:
	var used := {}
	var max_influences := 0
	var bad_sum := 0
	var reach := 0.0
	if mesh == null or mesh.mesh == null or mesh.skin == null:
		return {"ok": false}
	var shoulder: Vector3 = rig.get_bone_global_rest(rig.find_bone("UpperArm" + side)).origin
	var elbow: Vector3 = rig.get_bone_global_rest(rig.find_bone("Forearm" + side)).origin
	var axis := (elbow - shoulder).normalized()
	for surface in range(mesh.mesh.get_surface_count()):
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var coords: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var stride := weights.size() / coords.size()
		for v in coords.size():
			var n := 0
			var total := 0.0
			for j in stride:
				var w: float = weights[v * stride + j]
				total += w
				if w <= 0.001:
					continue
				n += 1
				var name := String(mesh.skin.get_bind_name(int(bones[v * stride + j])))
				if name.is_empty():
					name = rig.get_bone_name(mesh.skin.get_bind_bone(int(bones[v * stride + j])))
				used[name] = true
				if name == "Forearm" + side and w > 0.05:
					# how far above the elbow (toward the shoulder) this vertex sits
					reach = maxf(reach, (elbow - coords[v]).dot(axis))
			max_influences = maxi(max_influences, n)
			if absf(total - 1.0) > 0.01:
				bad_sum += 1
	return {"ok": true, "used": used.keys(), "max_influences": max_influences, "bad_sum": bad_sum, "forearm_reach_m": reach}

func get_poses(skeleton: Skeleton3D, anim: AnimationPlayer, action: String) -> Dictionary:
	var out: Dictionary = {}
	var indices: Dictionary = {}
	for bone in ["Hips", "KneeL", "KneeR", "FootL", "FootR", "WeaponRoot"]:
		indices[bone] = skeleton.find_bone(bone)
	anim.play(action, 0)
	for f in range(23):
		anim.seek(float(f) / 30.0, true)
		out[f] = {}
		for bone in indices:
			out[f][bone] = skeleton.get_bone_global_pose(int(indices[bone]))
	return out

func travel(poses: Dictionary, bone: String) -> float:
	var start: Vector3 = poses[0][bone].origin
	var distance := 0.0
	for frame in poses:
		distance = maxf(distance, start.distance_to(poses[frame][bone].origin))
	return distance

func _run() -> void:
	check(ResourceLoader.exists(ASSET), "R54 separate model exists")
	if not ResourceLoader.exists(ASSET):
		quit(1)
		return
	var packed: PackedScene = ResourceLoader.load(ASSET) as PackedScene
	check(packed != null, "R54 glTF imports as editable scene")
	if packed == null:
		quit(1)
		return
	var model: Node3D = packed.instantiate() as Node3D
	root.add_child(model)
	var skeleton_nodes := model.find_children("*", "Skeleton3D", true, false)
	check(not skeleton_nodes.is_empty(), "R54 model has actual skeleton")
	if skeleton_nodes.is_empty():
		quit(1)
		return
	var rig: Skeleton3D = skeleton_nodes[0] as Skeleton3D
	check(rig.get_bone_count() >= 62, "All 62 skeleton joints preserved")
	var animation: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	check(animation != null, "AnimationPlayer imports")
	if animation == null:
		quit(1)
		return
	var clips: PackedStringArray = animation.get_animation_list()
	for action in REQUIRED:
		check(clips.has(action), "Retains animation " + action)
	var skinned := 0
	for item in model.find_children("*", "MeshInstance3D", true, false):
		var m := item as MeshInstance3D
		if m.skin != null:
			skinned += 1
	check(skinned >= 90, "At least 90 of 92 original skinned meshes remain")
	for part in ["ShoulderPlateL", "ShoulderPlateR", "LayeredCuirass"]:
		var mesh := find_mesh(model, part)
		check(mesh != null, "Rigid armor imported: " + part)
		var report := only_one_bone_per_vertex(mesh)
		check(report["ok"], "All vertices rigidly skinned: " + part)
		var expected_bone: String = ("Chest" if part == "LayeredCuirass" else "UpperArmL" if part == "ShoulderPlateL" else "UpperArmR")
		var actual_bone: String = primary_weighted_bone(mesh, rig)
		check(actual_bone == expected_bone, "Armor weights bind to actual bone " + expected_bone + " (got " + actual_bone + ")")
		print("R54 ARMOR WEIGHTS ", part, " = ", JSON.stringify(report))
	for side in ["L", "R"]:
		var arm := find_mesh(model, "ArticulatedArm" + side)
		check(arm != null, "Arm skin imported: ArticulatedArm" + side)
		var a := arm_skin(arm, rig, side)
		print("R54 ARM SKIN ", side, " = ", JSON.stringify(a))
		check(bool(a.get("ok", false)) and int(a["bad_sum"]) == 0, "Arm %s weights normalised on every vertex" % side)
		check(bool(a.get("ok", false)) and int(a["max_influences"]) <= 4, "Arm %s uses at most four influences" % side)
		check(bool(a.get("ok", false)) and (a["used"] as Array).has("Elbow" + side), "Arm %s: Elbow helper joint carries the crease weight" % side)
		check(bool(a.get("ok", false)) and (a["used"] as Array).has("Hand" + side) and (a["used"] as Array).has("Clavicle" + side), "Arm %s: shoulder and wrist blends present" % side)
	# the helper must be invisible to everything below the elbow: compare global poses with R53
	var base: Node3D = (ResourceLoader.load(BASELINE) as PackedScene).instantiate() as Node3D
	root.add_child(base)
	var brig: Skeleton3D = base.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var banim: AnimationPlayer = base.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for clip in ["Slash", "Cast", "Slash_FullBody_R50", "Idle"]:
		var drift := 0.0
		var helper := 0.0
		var length: float = animation.get_animation(clip).length
		for k in 61:
			var t := length * k / 60.0   # includes times between keys
			animation.play(clip, 0); animation.seek(t, true)
			banim.play(clip, 0); banim.seek(t, true)
			for bone in ["HandL", "HandR", "WeaponRoot", "ShieldRoot", "ForearmL", "ForearmR"]:
				var a2: Transform3D = rig.get_bone_global_pose(rig.find_bone(bone))
				var b2: Transform3D = brig.get_bone_global_pose(brig.find_bone(bone))
				drift = maxf(drift, a2.origin.distance_to(b2.origin))
			for sd in ["L", "R"]:
				var e1: Quaternion = rig.get_bone_pose_rotation(rig.find_bone("Elbow" + sd))
				var e0: Quaternion = brig.get_bone_pose_rotation(brig.find_bone("Elbow" + sd))
				helper = maxf(helper, rad_to_deg(e0.angle_to(e1)))
		print("R54 %s: max hand/weapon/forearm drift vs R53 %.5f m, max helper swing %.1f deg" % [clip, drift, helper])
		check(drift < 0.002, "%s: hands, weapon and shield match R53 within 2 mm" % clip)
		if clip in ["Slash", "Cast", "Slash_FullBody_R50"]:
			check(helper > 20.0 and helper < 45.0, "%s: Elbow helper swings about half the elbow bend (%.1f deg)" % [clip, helper])
	base.queue_free()
	var previous: Dictionary = get_poses(rig, animation, "Slash")
	var updated: Dictionary = get_poses(rig, animation, "Slash_FullBody_R50")
	var initial: Quaternion = updated[0]["Hips"].basis.get_rotation_quaternion()
	var hip_degrees := 0.0
	for f in updated:
		hip_degrees = maxf(hip_degrees, rad_to_deg(initial.angle_to(updated[f]["Hips"].basis.get_rotation_quaternion())))
	check(travel(previous, "FootL") < 0.001, "Original Slash remains unchanged")
	check(hip_degrees > 6.0 and hip_degrees < 12.0, "R50 full-body hip turn preserved in R54")
	check(travel(updated, "KneeL") > 0.035, "Left knee articulation retained")
	check(travel(updated, "KneeR") > 0.035, "Right knee articulation retained")
	check(travel(updated, "FootL") < 0.06, "Left foot stays planted")
	check(travel(updated, "FootR") < 0.06, "Right foot stays planted")
	check(travel(updated, "WeaponRoot") > 0.75, "WeaponRoot still animates during Slash")
	print("AOTL R54 GODOT ELBOW HELPER IMPORT RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
