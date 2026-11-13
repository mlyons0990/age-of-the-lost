extends SceneTree
## Run with Godot 4.3+: godot --headless --path . --script res://tests/terrain_foot_ik_integration.gd
const IK_SCRIPT := preload("res://scripts/three_d/terrain_foot_ik.gd")

func _initialize() -> void:
	var checks := 0
	assert(is_equal_approx(IK_SCRIPT.circular_distance(0.99, 0.01), 0.02))
	checks += 1
	assert(IK_SCRIPT.stance_weight(4.0 / 24.0, "R", false) > 0.99)
	checks += 1
	assert(IK_SCRIPT.stance_weight(16.0 / 24.0, "L", false) > 0.99)
	checks += 1
	assert(IK_SCRIPT.stance_weight(4.0 / 18.0, "R", true) > 0.99)
	checks += 1
	assert(IK_SCRIPT.stance_weight(14.0 / 18.0, "L", true) > 0.99)
	checks += 1
	assert(IK_SCRIPT.stance_weight(0.54, "R", false) < 0.01)
	checks += 1
	assert(IK_SCRIPT.stance_weight(0.50, "R", false) < 0.01)
	checks += 1
	assert(is_equal_approx(IK_SCRIPT.contact_phase("R", false), 4.0 / 24.0))
	checks += 1
	assert(is_equal_approx(IK_SCRIPT.contact_phase("L", true), 14.0 / 18.0))
	checks += 1
	# Regression guard: proxy GLB or empty root must NOT force IK on.
	var root := Node3D.new()
	var actor := CharacterBody3D.new()
	var solver := IK_SCRIPT.new()
	assert(not solver.configure(root, actor, null))
	checks += 1
	root.free()
	actor.free()
	solver.free()
	print("AOTL terrain-foot-IK logic checks passed: ", checks)
	quit(0)
