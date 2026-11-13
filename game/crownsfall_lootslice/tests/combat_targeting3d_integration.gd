extends SceneTree
## R39 3D Warrior directional and world-obstruction combat QA (Godot 4.6.3).
## Run in isolated QA project: --headless --script res://tests/combat_targeting3d_integration.gd

const TARGETING := preload("res://scripts/three_d/combat_targeting3d.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var hero := CharacterBody3D.new()
	hero.name = "WarriorCombatQA"
	hero.collision_layer = 2
	root.add_child(hero)
	var far := Vector3(0, 0, -3.0)
	var near := Vector3(0, 0, -1.0)
	check(TARGETING.within_attack_arc(Vector3.ZERO, Vector3.FORWARD, near, 2.15, 0.2), "Slash accepts a forward target")
	check(not TARGETING.within_attack_arc(Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, 1), 2.15, 0.2), "Slash rejects a target behind")
	check(not TARGETING.within_attack_arc(Vector3.ZERO, Vector3.FORWARD, far, 2.15, 0.2), "Slash rejects out-of-range target")
	check(TARGETING.within_attack_arc(Vector3.ZERO, Vector3.FORWARD, far, 3.3, -1.0), "Cast reaches full area radius")
	check(TARGETING.within_attack_arc(Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, 2), 3.3, -1.0), "Cast includes target behind within area")
	check(not TARGETING.within_attack_arc(Vector3.ZERO, Vector3.FORWARD, Vector3(3.4, 0, 0), 3.3, -1.0), "Cast radius has a strict boundary")
	check(not TARGETING.within_attack_arc(Vector3.ZERO, Vector3.ZERO, near, 2.15, 0.2), "Zero-facing input does not produce free melee hits")
	check(TARGETING.within_attack_arc(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, 2.15, 0.2), "Zero-distance target is well-defined")
	check(is_equal_approx(TARGETING.damage_for("Cleave"), 43.0) and is_equal_approx(TARGETING.damage_for("Cast"), 53.0), "Existing ability damages remain stable")
	check(not TARGETING.within_attack_arc(Vector3.ZERO, Vector3.FORWARD, Vector3.INF, 3.0, 0.2), "Rejects non-finite target")
	var profile := TARGETING.profile_for("Dash")
	check(is_equal_approx(float(profile["range"]), 2.15) and float(profile["min_dot"]) > 0, "Dash has directional range")

	var obstacle := StaticBody3D.new()
	obstacle.name = "LineOfSightBlocker"
	obstacle.collision_layer = 1
	obstacle.position = Vector3(0, 1.1, -1.25)
	var hitbox := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 2.2, 0.3)
	hitbox.shape = box
	obstacle.add_child(hitbox)
	root.add_child(obstacle)
	await physics_frame
	await physics_frame

	check(not TARGETING.world_line_of_sight(hero.get_world_3d(), Vector3.ZERO, Vector3(0, 0, -2.6), hero.get_rid()), "Solid wall intercepts world-space attack ray")
	check(not TARGETING.can_hit(hero.get_world_3d(), hero, Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, -2.6), "Cleave"), "Cleave cannot strike through opaque collision wall")
	check(TARGETING.can_hit(hero.get_world_3d(), hero, Vector3.ZERO, Vector3.RIGHT, Vector3(2.3, 0, -0.5), "Cast"), "Clear target beside wall can be hit")
	obstacle.position = Vector3(4.0, 1.1, -1.25)
	await physics_frame
	await physics_frame
	check(TARGETING.can_hit(hero.get_world_3d(), hero, Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, -2.6), "Cleave"), "Moving cover out of the ray restores hit")
	check(not TARGETING.can_hit(hero.get_world_3d(), hero, Vector3.ZERO, Vector3.BACK, Vector3(0, 0, -2.6), "Slash"), "Turning away prevents hits even without obstruction")
	obstacle.queue_free()
	hero.queue_free()
	print("AOTL 3D COMBAT TARGETING RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
