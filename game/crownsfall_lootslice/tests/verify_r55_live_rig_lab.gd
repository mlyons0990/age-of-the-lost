extends SceneTree
## Actual Crownsfall playable R55 Warrior, not a geometry-only import.
const LAB := preload("res://scripts/three_d/rig_lab.gd")
var checks := 0
var failures := 0

func verify(condition: bool, reason: String) -> void:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + reason)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var lab = LAB.new()
	lab.use_r55_clip_safe_elbow_candidate = true
	root.add_child(lab)
	await physics_frame
	await physics_frame
	var actor = lab.player
	verify(actor.active_model_source == "warrior_r55_opt_in", "Rig lab selected actual optional R55 GLB")
	verify(actor.clip_names.has("Slash_FullBody_R50"), "R55 keeps independent full-body Slash")
	verify(actor.clip_names["Slash"] == actor.clip_names["Slash_FullBody_R50"], "New armor uses same verified R50 full-body attack")
	verify(actor.animation.has_animation("Slash"), "Original Slash still exists for rollback")
	verify(actor.animation.has_animation("Slash_FullBody_R50"), "R50 full-body animation remains independently playable")
	var skeleton: Skeleton3D = actor.body.find_child("Skeleton3D", true, false) as Skeleton3D
	verify(skeleton != null and skeleton.get_bone_count() >= 62, "Full 62-joint humanoid skeleton active")
	verify(actor.terrain_ik_available, "Terrain-foot IK remains available")
	verify(actor.equipment_sockets_available, "Weapon and shield attachment bones remain available")
	verify(lab.targets.size() == 4, "All four rig-lab training dummies remain")
	var dummy = lab.targets[0]
	verify(dummy.hurtbox != null and dummy.hurtbox.collision_layer == 4, "Damageable physics hurtbox remains")
	dummy.global_position = actor.global_position + Vector3(0,0,-1.3)
	dummy.hp = 100.0
	await physics_frame
	actor._attack("Slash", 0.72)
	await root.get_tree().create_timer(0.77).timeout
	verify(is_equal_approx(dummy.hp,68.0), "R55 baseline Slash hits front dummy for unchanged 32 damage")
	await root.get_tree().create_timer(0.25).timeout
	verify(is_equal_approx(dummy.hp,68.0), "R55 baseline swing has no second hit")
	lab.strict_weapon_sweep = true
	lab._draw_sword_sweep()
	verify(lab.sword_sweep_debug.visible, "F8 experimental blade geometry remains visible")
	dummy.global_position = actor.global_position + Vector3(0,0,-0.65)
	dummy.hp = 100.0
	await physics_frame
	actor._attack("Slash", 0.72)
	await root.get_tree().create_timer(0.82).timeout
	verify(is_equal_approx(dummy.hp,68.0), "Real R55 sword contacts nearby dummy during active swing")
	verify(lab.sweep_hit_instances.has(dummy.get_instance_id()), "Swept blade only damages once per target")
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.position = actor.global_position + Vector3(0,1.0,-0.32)
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = Vector3(1.4,1.8,0.18)
	shape.shape = block
	wall.add_child(shape)
	lab.add_child(wall)
	dummy.hp = 100.0
	await physics_frame
	await physics_frame
	actor._attack("Slash", 0.72)
	await root.get_tree().create_timer(0.85).timeout
	verify(is_equal_approx(dummy.hp,100.0), "R55 physical blade refuses hits through world cover")
	lab.strict_weapon_sweep = false
	lab._draw_sword_sweep()
	verify(not lab.sword_sweep_debug.visible, "Default collision-aware combat restored")
	print("AOTL R55 LIVE RIG LAB RESULT %d checks; %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
