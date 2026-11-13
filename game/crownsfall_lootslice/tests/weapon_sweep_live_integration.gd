extends SceneTree
## Real R39 rig-lab test: imported Slash animation drives one impact event.
const LAB := preload("res://scripts/three_d/rig_lab.gd")
var checks := 0
var failures := 0

func verify(ok: bool, desc: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + desc)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var lab := LAB.new()
	root.add_child(lab)
	await physics_frame
	await physics_frame
	var actor = lab.player
	verify(actor != null and actor.active_model_source == "warrior_r39", "Real R39 model selected")
	verify(actor.equipment_sockets_available, "Imported weapon attachment available")
	var socket = actor.equipment_sockets.get_socket("weapon")
	verify(socket != null and socket is BoneAttachment3D, "Real WeaponRoot BoneAttachment3D active")
	var target = lab.targets[0]
	target.global_position = actor.global_position + Vector3(0,0,-1.30)
	await physics_frame
	actor._attack("Slash", 0.72)
	await root.get_tree().create_timer(0.12).timeout
	verify(actor.attack_t > 0.0 and not actor.has_impacted, "Slash windup has not registered early impact")
	verify(lab.contact_samples.size() >= 2, "Real moving weapon socket generated consecutive sweep samples")
	verify(actor.anim_state == "Slash", "Imported Slash animation actively plays")
	await root.get_tree().create_timer(0.56).timeout
	verify(actor.has_impacted, "Slash event fired after animation contact point")
	verify(is_equal_approx(target.hp,68.0), "One valid Slash hit deals exactly 32 damage")
	await root.get_tree().create_timer(0.35).timeout
	verify(is_equal_approx(target.hp,68.0), "No duplicate Slash hit during follow-through")
	lab.strict_weapon_sweep = true
	lab._draw_sword_sweep()
	verify(lab.strict_weapon_sweep, "F8 strict sweep comparison can be enabled independently")
	verify(lab.sword_sweep_debug != null and lab.sword_sweep_debug.visible, "F8 renders actual sampled sword path")
	lab.strict_weapon_sweep = false
	lab._draw_sword_sweep()
	verify(not lab.strict_weapon_sweep, "Baseline combat remains recoverable")
	verify(not lab.sword_sweep_debug.visible, "F8 hides debug geometry when disabled")
	print("AOTL R39 LIVE WEAPON CONTACT RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
