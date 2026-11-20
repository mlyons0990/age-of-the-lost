extends SkeletonModifier3D
## Upper-body layering for armed characters whose locomotion clips were authored unarmed.
## After the AnimationPlayer has posed the skeleton, the arm bones are blended toward a stored
## "weapon-ready" pose (sword and shield carried steady) while legs, hips and spine keep the clip.
## `influence` (from SkeletonModifier3D) is driven by the controller: ~0.85 while moving, 0 otherwise.

var bones: PackedInt32Array = []
var carry: Array = []          # Quaternion per bone, local pose rotations of the carry pose

func setup(skeleton: Skeleton3D, bone_names: Array, carry_rotations: Array) -> void:
	bones.clear()
	carry.clear()
	for i in bone_names.size():
		var b := skeleton.find_bone(bone_names[i])
		if b >= 0:
			bones.append(b)
			carry.append(carry_rotations[i])

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	for i in bones.size():
		var b: int = bones[i]
		var q: Quaternion = sk.get_bone_pose_rotation(b)
		sk.set_bone_pose_rotation(b, q.slerp(carry[i], influence))
