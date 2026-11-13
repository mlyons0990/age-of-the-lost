extends SceneTree
## Live 3D rig-lab combat smoke test, not just pure vector/raycast helpers.
## Mounts the real R39 Warrior + all existing lab scripts in a physics world.

const LAB := preload("res://scripts/three_d/rig_lab.gd")
var checked := 0
var failed := 0

func require(condition: bool, reason: String) -> void:
	checked += 1
	if not condition:
		failed += 1
	print(("PASS " if condition else "FAIL ") + reason)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var lab := LAB.new()
	root.add_child(lab)
	await physics_frame
	await physics_frame
	var warrior = lab.player
	require(warrior != null and warrior.active_model_source == "warrior_r39", "Full lab loaded real R39 Warrior")
	require(warrior.terrain_ik_available and warrior.equipment_sockets_available, "Full lab constructed IK and equipment sockets")
	require(lab.targets.size() >= 1, "Real training dummies are active")
	if failed > 0:
		print("AOTL LIVE R39 COMBAT RESULT %d checks; %d failures" % [checked, failed])
		quit(1)
		return
	var target = lab.targets[0]
	target.global_position = warrior.global_position + Vector3(0, 0, -1.3)
	await physics_frame
	var original: float = target.hp
	lab._on_impact(target.global_position, "Slash", Vector3.FORWARD)
	require(is_equal_approx(target.hp, original - 32.0), "Live Slash damages in-front visible dummy once")
	var blocking := StaticBody3D.new()
	blocking.collision_layer = 1
	blocking.position = warrior.global_position + Vector3(0, 1.1, -0.65)
	var blocker_shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = Vector3(1.2, 2.0, 0.18)
	blocker_shape.shape = cube
	blocking.add_child(blocker_shape)
	lab.add_child(blocking)
	await physics_frame
	await physics_frame
	original = target.hp
	lab._on_impact(target.global_position, "Slash", Vector3.FORWARD)
	require(is_equal_approx(target.hp, original), "Live sword attack cannot hit dummy through solid cover")
	blocking.position = warrior.global_position + Vector3(5.0, 1.1, -0.65)
	await physics_frame
	await physics_frame
	lab._on_impact(target.global_position, "Slash", Vector3.FORWARD)
	require(is_equal_approx(target.hp, original - 32.0), "Live Slash hits again when cover is removed")
	target.global_position = warrior.global_position + Vector3(0, 0, 1.3)
	await physics_frame
	original = target.hp
	lab._on_impact(target.global_position, "Slash", Vector3.FORWARD)
	require(is_equal_approx(target.hp, original), "Live Slash never damages target behind Warrior")
	lab._on_impact(target.global_position, "Cast", Vector3.FORWARD)
	require(is_equal_approx(target.hp, original - 53.0), "Live AoE Cast keeps full-circle area effect and expected damage")
	print("AOTL LIVE R39 COMBAT RESULT %d checks; %d failures" % [checked, failed])
	quit(0 if failed == 0 else 1)
