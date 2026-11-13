extends SceneTree
## Full Crownsfall controller acceptance: default R39 vs optional R50 candidate.
const CONTROLLER := preload("res://scripts/three_d/rig_controller.gd")
var checks := 0
var failures := 0

func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stable = CONTROLLER.new()
	stable.name = "BaselineWarrior"
	root.add_child(stable)
	verify(stable.active_model_source != "warrior_r50_opt_in", "Default controller never opts into unapproved R50")
	verify(stable.clip_names.has("Slash"), "Default controller retains original Slash")
	var candidate = CONTROLLER.new()
	candidate.name = "R50OptInWarrior"
	candidate.enable_r50_fullbody_slash_candidate = true
	root.add_child(candidate)
	verify(candidate.active_model_source == "warrior_r50_opt_in", "Explicit opt-in selects R50 model")
	verify(candidate.clip_names.has("Slash_FullBody_R50"), "R50 candidate retains separate authored action")
	verify(candidate.clip_names.has("Slash"), "R50 candidate has normal Slash gameplay key")
	verify(candidate.clip_names["Slash"] == candidate.clip_names["Slash_FullBody_R50"], "Opt-in remaps Slash to new full-body animation")
	verify(candidate.terrain_ik_available, "R50 keeps Godot terrain-foot IK")
	verify(candidate.equipment_sockets_available, "R50 keeps weapon and offhand equipment sockets")
	verify(candidate.animation.get_animation_list().has("Slash"), "Original Slash remains available for rollback")
	verify(candidate.animation.get_animation_list().has("Slash_FullBody_R50"), "R50 animation is an independent imported clip")
	candidate.set_physics_process(false)
	candidate._play("Slash")
	candidate.animation.seek(0.50, true)
	verify(candidate.animation.current_animation == candidate.clip_names["Slash_FullBody_R50"], "Actual R50 clip plays through controller")
	var bone_node = candidate.body.find_child("Skeleton3D", true, false)
	var skeleton: Skeleton3D = bone_node as Skeleton3D
	verify(skeleton != null and skeleton.get_bone_count() >= 62, "R50 skeleton retains full articulation")
	candidate.animation.seek(0.0, true)
	var hip_index: int = skeleton.find_bone("Hips")
	var start_rotation: Quaternion = skeleton.get_bone_global_pose(hip_index).basis.get_rotation_quaternion()
	candidate.animation.seek(0.48, true)
	var later_rotation: Quaternion = skeleton.get_bone_global_pose(hip_index).basis.get_rotation_quaternion()
	verify(start_rotation.angle_to(later_rotation) > 0.05, "Live controller R50 Slash rotates the hips")
	candidate.set_physics_process(true)
	candidate._play("Idle")
	var strikes: Array = []
	candidate.impact.connect(func(_at: Vector3, kind: String, _direction: Vector3): strikes.append(kind))
	candidate._attack("Slash", 0.72)
	await root.get_tree().create_timer(0.12).timeout
	verify(strikes.is_empty(), "R50 Slash does not hit early during anticipation")
	await root.get_tree().create_timer(0.65).timeout
	verify(strikes.size() == 1 and strikes[0] == "Slash", "R50 emits exactly one animation-timed Slash impact")
	await root.get_tree().create_timer(0.25).timeout
	verify(strikes.size() == 1, "R50 never repeats the same swing impact")
	print("AOTL R50 LIVE CONTROLLER RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
