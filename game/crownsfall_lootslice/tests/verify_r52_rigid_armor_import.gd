extends SceneTree
## Real Godot 4.6.3 acceptance for the optional seven-clip R52 Warrior.
## Verifies actual imported skinning rather than only glTF JSON metadata.
const ASSET := "res://models/AOTL_Warrior_R52_RigidArmor_SevenClip.glb"
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
	check(ResourceLoader.exists(ASSET), "R52 separate model exists")
	if not ResourceLoader.exists(ASSET):
		quit(1)
		return
	var packed: PackedScene = ResourceLoader.load(ASSET) as PackedScene
	check(packed != null, "R52 glTF imports as editable scene")
	if packed == null:
		quit(1)
		return
	var model: Node3D = packed.instantiate() as Node3D
	root.add_child(model)
	var skeleton_nodes := model.find_children("*", "Skeleton3D", true, false)
	check(not skeleton_nodes.is_empty(), "R52 model has actual skeleton")
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
		print("R52 ARMOR WEIGHTS ", part, " = ", JSON.stringify(report))
	var previous: Dictionary = get_poses(rig, animation, "Slash")
	var updated: Dictionary = get_poses(rig, animation, "Slash_FullBody_R50")
	var initial: Quaternion = updated[0]["Hips"].basis.get_rotation_quaternion()
	var hip_degrees := 0.0
	for f in updated:
		hip_degrees = maxf(hip_degrees, rad_to_deg(initial.angle_to(updated[f]["Hips"].basis.get_rotation_quaternion())))
	check(travel(previous, "FootL") < 0.001, "Original Slash remains unchanged")
	check(hip_degrees > 6.0 and hip_degrees < 12.0, "R50 full-body hip turn preserved in R52")
	check(travel(updated, "KneeL") > 0.035, "Left knee articulation retained")
	check(travel(updated, "KneeR") > 0.035, "Right knee articulation retained")
	check(travel(updated, "FootL") < 0.06, "Left foot stays planted")
	check(travel(updated, "FootR") < 0.06, "Right foot stays planted")
	check(travel(updated, "WeaponRoot") > 0.75, "WeaponRoot still animates during Slash")
	print("AOTL R52 GODOT RIGID ARMOR IMPORT RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
