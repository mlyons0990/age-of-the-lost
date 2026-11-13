extends SceneTree
## Opt-in R50 in actual Crownsfall 3D lab: damage and bone-socket regression.
const LAB := preload("res://scripts/three_d/rig_lab.gd")
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
	var lab = LAB.new()
	lab.use_r50_fullbody_slash_candidate = true
	root.add_child(lab)
	await physics_frame
	await physics_frame
	var hero = lab.player
	verify(hero.active_model_source == "warrior_r50_opt_in", "Rig lab selects opt-in R50 character")
	verify(hero.clip_names.has("Slash_FullBody_R50"), "Rig lab retains independent R50 animation")
	verify(hero.clip_names["Slash"] == hero.clip_names["Slash_FullBody_R50"], "Rig lab maps Slash input to new full-body clip")
	verify(hero.terrain_ik_available, "R50 rig lab retains terrain IK")
	verify(hero.equipment_sockets_available, "R50 rig lab retains physical sword bone socket")
	verify(lab.targets.size() == 4, "All existing training dummies remain intact")
	var dummy = lab.targets[0]
	verify(dummy.hurtbox != null and dummy.hurtbox.collision_layer == 4, "Damageable layer-4 hurtbox survives R50 character swap")
	dummy.global_position = hero.global_position + Vector3(0,0,-1.3)
	dummy.hp = 100
	await physics_frame
	hero._attack("Slash", 0.72)
	await root.get_tree().create_timer(0.77).timeout
	verify(is_equal_approx(dummy.hp, 68.0), "R50 baseline combat hits in-front dummy for 32 damage")
	await root.get_tree().create_timer(0.25).timeout
	verify(is_equal_approx(dummy.hp, 68.0), "R50 hit never repeats after animation recovery")
	lab.strict_weapon_sweep = true
	lab._draw_sword_sweep()
	verify(lab.sword_sweep_debug.visible, "R50 strict swept-blade debug geometry visible")
	dummy.global_position = hero.global_position + Vector3(0,0,-0.65)
	dummy.hp = 100.0
	await physics_frame
	hero._attack("Slash", 0.72)
	await root.get_tree().create_timer(0.82).timeout
	verify(is_equal_approx(dummy.hp, 68.0), "R50 animated physical blade contacts reachable dummy")
	verify(lab.sweep_hit_instances.has(dummy.get_instance_id()), "R50 swept blade records target once per swing")
	lab.strict_weapon_sweep = false
	lab._draw_sword_sweep()
	verify(not lab.sword_sweep_debug.visible, "R50 returns to stable directional combat mode")
	print("AOTL R50 RIG LAB RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
