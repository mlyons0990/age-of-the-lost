extends SceneTree
## The Higgsfield pilot knight driven by the real rig-lab controller: loads, idles, walks, slashes the
## training dummy, rolls (in place, controller-driven travel, i-frames) and still fights by default rules.
const LAB := preload("res://scripts/three_d/rig_lab.gd")
var checks := 0
var failures := 0

func verify(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + why)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var lab = LAB.new()
	lab.use_pilot_knight_candidate = true
	root.add_child(lab)
	await physics_frame
	await physics_frame
	var actor = lab.player
	verify(actor.active_model_source == "pilot_knight_opt_in", "Rig lab selected the pilot knight (%s)" % actor.active_model_source)
	verify(actor.clip_names.get("Dodge", "") == actor.clip_names.get("Roll_Dodge", "x"), "Dodge plays the library roll")
	verify(actor.anim_state == "Idle", "Knight starts idle")
	var sk: Skeleton3D = actor.body.find_children("*", "Skeleton3D", true, false)[0]
	var hips := sk.find_bone("Hips")
	# slash the front dummy
	var dummy = lab.targets[0]
	dummy.global_position = actor.global_position + Vector3(0, 0, -1.3)
	dummy.hp = 100.0
	await physics_frame
	actor._attack("Slash", 0.72)
	verify(actor.anim_state == "Slash", "Slash animation plays on attack")
	await root.get_tree().create_timer(0.8).timeout
	verify(dummy.hp < 100.0, "Slash damages the training dummy (hp %.0f)" % dummy.hp)
	await root.get_tree().create_timer(0.3).timeout
	# roll: in place animation, controller travel, invulnerability
	var start: Vector3 = actor.global_position
	var low := 9.0
	var drift := 0.0
	actor._dodge()
	verify(actor.anim_state == "Dodge" and actor.invulnerable > 0.0, "Space-roll starts with i-frames")
	for i in 40:
		await physics_frame
		var hp: Vector3 = sk.global_transform * sk.get_bone_global_pose(hips).origin
		low = minf(low, hp.y - actor.global_position.y)
		drift = maxf(drift, Vector2(hp.x - actor.global_position.x, hp.z - actor.global_position.z).length())
	var moved: float = actor.global_position.distance_to(start)
	print("PILOT LAB roll: controller travel %.2f m, lowest hips %.2f m above feet, hips off the body %.2f m" % [moved, low, drift])
	verify(low < 0.6, "Knight tucks into the roll (hips %.2f m)" % low)
	verify(absf(moved - 10.5 * 0.65) < 0.5, "Roll travel is the controller's standard dodge (%.2f m)" % moved)
	verify(drift < 0.45, "Roll animation adds no root-motion drift (hips stay over the body, %.2f m)" % drift)
	await root.get_tree().create_timer(0.4).timeout
	verify(actor.dodge_t <= 0.0, "Roll finishes and control returns")
	print("AOTL PILOT KNIGHT LAB RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
