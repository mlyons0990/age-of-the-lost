extends SceneTree
## Real R39 animated Warrior strict sword collision, not just fixed arc damage.
const LAB := preload("res://scripts/three_d/rig_lab.gd")
var checks := 0
var failures := 0

func verify(condition: bool, why: String) -> void:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + why)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var lab := LAB.new()
	root.add_child(lab)
	await physics_frame
	await physics_frame
	var warrior = lab.player
	verify(warrior.active_model_source == "warrior_r39", "Uses real R39 skinned skeleton")
	verify(warrior.equipment_sockets_available, "Warrior weapon attachment resolves")
	lab.strict_weapon_sweep = true
	lab._draw_sword_sweep()
	verify(lab.sword_sweep_debug.visible, "Strict F8 mode exposes actual contact path")
	var dummy = lab.targets[0]
	verify(dummy.hurtbox != null and dummy.hurtbox.collision_layer == 4, "Target owns independent damageable physics layer")
	dummy.global_position = warrior.global_position + Vector3(0,0,-0.65)
	await physics_frame
	var query := PhysicsPointQueryParameters3D.new()
	query.position = dummy.damage_center()
	query.collision_mask = 4
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var overlaps := lab.get_world_3d().direct_space_state.intersect_point(query)
	verify(not overlaps.is_empty(), "Physics query resolves actual target hurtbox")
	dummy.hp = 100.0
	warrior._attack("Slash",0.72)
	await root.get_tree().create_timer(0.75).timeout
	verify(is_equal_approx(dummy.hp,68.0), "Animation-swept blade hits dummy at reachable 0.65 meter range")
	verify(lab.sweep_hit_instances.has(dummy.get_instance_id()), "Damaged target recorded once for current swing")
	await root.get_tree().create_timer(0.25).timeout
	verify(is_equal_approx(dummy.hp,68.0), "Follow-through does not hit dummy twice")
	dummy.global_position = warrior.global_position + Vector3(0,0,-1.35)
	dummy.hp = 100.0
	warrior._attack("Slash",0.72)
	await root.get_tree().create_timer(0.85).timeout
	verify(is_equal_approx(dummy.hp,100.0), "Strict physical blade correctly rejects out-of-reach 1.35m dummy")
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.position = warrior.global_position + Vector3(0,1.0,-0.32)
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = Vector3(1.4,1.8,0.18)
	shape.shape = block
	wall.add_child(shape)
	lab.add_child(wall)
	dummy.global_position = warrior.global_position + Vector3(0,0,-0.65)
	dummy.hp = 100.0
	await physics_frame
	await physics_frame
	warrior._attack("Slash",0.72)
	await root.get_tree().create_timer(0.85).timeout
	verify(is_equal_approx(dummy.hp,100.0), "Strict collision never strikes through solid world cover")
	lab.strict_weapon_sweep = false
	lab._draw_sword_sweep()
	verify(not lab.sword_sweep_debug.visible, "Baseline mode restores without sword trail")
	verify(lab.sweep_hit_instances.size() <= 1, "Strict mode deduplicates per target")
	print("AOTL R39 STRICT BLADE RESULT %d checks; %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
