extends SceneTree
## R50 7-clip GLB acceptance using real imported skeleton and animation tracks.
## This is isolated QA; it never changes the player's selected R39 production model.
const ASSET := "res://models/AOTL_Warrior_R50_SevenClip_Candidate.glb"
const REQUIRED := ["Idle", "Walk", "Run", "Dodge", "Slash", "Cast", "Slash_FullBody_R50"]
var checks := 0
var failures := 0

func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + message)

func _initialize() -> void:
	call_deferred("_verify")

func sample_animation(skeleton: Skeleton3D, player: AnimationPlayer, name: String) -> Dictionary:
	var index: Dictionary = {}
	for bone in ["Hips", "KneeL", "KneeR", "FootL", "FootR", "WeaponRoot"]:
		index[bone] = skeleton.find_bone(bone)
	var readings: Dictionary = {}
	var duration: float = player.get_animation(name).length
	player.play(name, 0.0)
	for frame in range(23):
		var t: float = float(frame) / 30.0
		player.seek(minf(t, duration), true)
		var p: Dictionary = {}
		for bone in index:
			var pose: Transform3D = skeleton.get_bone_global_pose(int(index[bone]))
			p[bone] = pose
		readings[frame] = p
	return readings

func max_position_travel(readings: Dictionary, bone: String) -> float:
	var start: Vector3 = readings[0][bone].origin
	var farthest: float = 0.0
	for frame in readings:
		farthest = maxf(farthest, start.distance_to(readings[frame][bone].origin))
	return farthest

func max_hip_turn(readings: Dictionary) -> float:
	var first: Quaternion = readings[0]["Hips"].basis.get_rotation_quaternion()
	var angle: float = 0.0
	for frame in readings:
		angle = maxf(angle, first.angle_to(readings[frame]["Hips"].basis.get_rotation_quaternion()))
	return angle

func _verify() -> void:
	verify(ResourceLoader.exists(ASSET), "R50 separate seven-clip asset exists")
	if not ResourceLoader.exists(ASSET):
		quit(1)
		return
	var packed: PackedScene = ResourceLoader.load(ASSET) as PackedScene
	verify(packed != null, "R50 glTF imports as a PackedScene")
	if packed == null:
		quit(1)
		return
	var model: Node3D = packed.instantiate() as Node3D
	root.add_child(model)
	var skeletons: Array[Node] = model.find_children("*", "Skeleton3D", true, false)
	verify(not skeletons.is_empty(), "R50 model has a Skeleton3D")
	if skeletons.is_empty():
		quit(1)
		return
	var skeleton: Skeleton3D = skeletons[0] as Skeleton3D
	verify(skeleton.get_bone_count() >= 62, "Source 62-joint skin imports without bone loss")
	var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	verify(player != null, "Imported R50 model has an AnimationPlayer")
	if player == null:
		quit(1)
		return
	var clips: PackedStringArray = player.get_animation_list()
	for label in REQUIRED:
		verify(clips.has(label), "Imported action: " + label)
	if failures > 0:
		quit(1)
		return
	var skinned: int = 0
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.skin != null:
			skinned += 1
	verify(skinned >= 90, "Retains original 92 skinned mesh objects")
	var old: Dictionary = sample_animation(skeleton, player, "Slash")
	var revised: Dictionary = sample_animation(skeleton, player, "Slash_FullBody_R50")
	var old_hips: float = max_hip_turn(old)
	var new_hips: float = max_hip_turn(revised)
	var knee_l: float = max_position_travel(revised, "KneeL")
	var knee_r: float = max_position_travel(revised, "KneeR")
	var foot_l: float = max_position_travel(revised, "FootL")
	var foot_r: float = max_position_travel(revised, "FootR")
	verify(old_hips < 0.015, "Original Slash has unchanged source hip pose")
	verify(new_hips > 0.05, "R50 adds visible pelvis counter-rotation")
	verify(knee_l > 0.035 and knee_r > 0.035, "Both knees articulate in R50")
	verify(foot_l <= 0.06 and foot_r <= 0.06, "Both feet stay within 6cm in imported animation")
	verify(max_position_travel(revised, "WeaponRoot") > 0.75, "R50 retains authentic sword arm swing")
	print("AOTL R50 IMPORT METRICS: hip_degrees=%.2f left_knee_cm=%.2f right_knee_cm=%.2f left_foot_cm=%.2f right_foot_cm=%.2f" % [
		rad_to_deg(new_hips), knee_l*100.0, knee_r*100.0, foot_l*100.0, foot_r*100.0
	])
	print("AOTL R50 GODOT ANIMATION RESULT %d checks; %d failures" % [checks, failures])
	model.queue_free()
	quit(0 if failures == 0 else 1)
