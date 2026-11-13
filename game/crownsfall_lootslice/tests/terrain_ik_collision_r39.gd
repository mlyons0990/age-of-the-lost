extends SceneTree
## R39 real-terrain acceptance: physics-backed ground contact and IK lock release.
## This test uses the imported Warrior and the existing gameplay controller.
const CONTROLLER = preload("res://scripts/three_d/rig_controller.gd")
var checks := 0

func _verify(condition: bool, description: String) -> bool:
	if condition:
		checks += 1
		print("PASS ", description)
		return true
	push_error("R39 TERRAIN IK FAIL: " + description)
	quit(1)
	return false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	world.name = "R39PhysicsTestWorld"
	root.add_child(world)
	var floor := StaticBody3D.new()
	floor.name = "CollisionBackedFloor"
	world.add_child(floor)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(20, 0.5, 20)
	collision.shape = shape
	collision.position = Vector3(0, -0.25, 0)
	floor.add_child(collision)
	var actor = CONTROLLER.new()
	actor.name = "WarriorR39PhysicsTest"
	actor.position = Vector3(0, 0.15, 0)
	world.add_child(actor)
	if not _verify(actor.active_model_source == "warrior_r39", "validated R39 asset selected"):
		return
	if not _verify(actor.terrain_ik_available, "real R39 terrain IK initialized"):
		return
	# The character's normal gravity/controller must establish floor contact.
	for i in 50:
		await physics_frame
		if actor.is_on_floor():
			break
	if not _verify(actor.is_on_floor(), "character grounded on physics-backed floor"):
		return
	var foot_ik = actor.terrain_foot_ik
	var ankle: Vector3 = foot_ik._animated_ankle("R")
	var hit: Dictionary = foot_ik._ground_below(ankle)
	if not _verify(not hit.is_empty(), "right-foot world raycast contacts floor"):
		return
	if not _verify(hit.get("collider") == floor, "floor surface collision returned by raycast"):
		return
	actor._play("Walk")
	# The contact phase is verified against the R39 authored 25-frame loop.
	foot_ik.update_foot_ik(1.0 / 60.0, "Walk", 4.0 / 24.0)
	if not _verify(bool(foot_ik.planted["R"]), "right foot captures world-space contact lock"):
		return
	var contact: Vector3 = foot_ik.planted_world["R"]
	if not _verify(absf(contact.y - foot_ik.foot_clearance_m) < 0.03, "planted foot aligns with floor height"):
		return
	var releases_before: int = foot_ik.contact_releases
	foot_ik.planted_world["R"] = ankle + Vector3(1.25, 0.0, 0.0)
	foot_ik.update_foot_ik(1.0 / 60.0, "Walk", 4.0 / 24.0)
	if not _verify(foot_ik.contact_releases == releases_before + 1, "overextended planted target is safely released"):
		return
	foot_ik.update_foot_ik(1.0 / 60.0, "Dodge", 0.0)
	if not _verify(not foot_ik.planted["R"] and not foot_ik.planted["L"], "dodge cancels all planted-foot locks"):
		return
	actor._toggle_terrain_ik()
	if not _verify(not actor.terrain_ik_enabled, "F9 toggles IK off"):
		return
	actor._toggle_terrain_ik()
	if not _verify(actor.terrain_ik_enabled, "F9 toggles IK back on"):
		return
	# A 15cm collision-backed elevation change must move the world lock upward.
	var raised := StaticBody3D.new()
	raised.name = "RaisedStep"
	raised.position = Vector3(3.5, 0.075, 0.0)
	world.add_child(raised)
	var raised_collision := CollisionShape3D.new()
	var raised_box := BoxShape3D.new()
	raised_box.size = Vector3(2.6, 0.15, 2.6)
	raised_collision.shape = raised_box
	raised.add_child(raised_collision)
	actor.global_position = Vector3(3.5, 0.55, 0)
	actor.velocity = Vector3.ZERO
	for step_frame in 80:
		await physics_frame
		if actor.is_on_floor() and actor.global_position.y <= 0.18:
			break
	if not _verify(actor.is_on_floor(), "Warrior grounds on elevated collision platform"):
		return
	ankle = foot_ik._animated_ankle("R")
	hit = foot_ik._ground_below(ankle)
	if not _verify(hit.get("collider") == raised, "foot ray detects raised platform instead of underlying floor"):
		return
	foot_ik.reset_contact_state()
	actor._play("Walk")
	foot_ik.update_foot_ik(1.0 / 60.0, "Walk", 4.0 / 24.0)
	if not _verify(bool(foot_ik.planted["R"]), "IK plants on the raised surface"):
		return
	contact = foot_ik.planted_world["R"]
	if not _verify(absf(contact.y - (0.15 + foot_ik.foot_clearance_m)) < 0.035, "planted-foot lock rises by exactly the step height"):
		return
	# A 12-degree traversable collision slope should be eligible for contact IK.
	var slope := StaticBody3D.new()
	slope.name = "GentleSlope"
	slope.position = Vector3(-3.5, 0.1, 0)
	slope.rotation.x = deg_to_rad(12.0)
	world.add_child(slope)
	var slope_collision := CollisionShape3D.new()
	var slope_box := BoxShape3D.new()
	slope_box.size = Vector3(3.0, 0.2, 3.0)
	slope_collision.shape = slope_box
	slope.add_child(slope_collision)
	actor.global_position = Vector3(-3.5, 0.60, 0)
	actor.velocity = Vector3.ZERO
	for slope_frame in 80:
		await physics_frame
		if actor.is_on_floor() and actor.global_position.y <= 0.24:
			break
	ankle = foot_ik._animated_ankle("R")
	hit = foot_ik._ground_below(ankle)
	if not _verify(actor.is_on_floor() and hit.get("collider") == slope, "Warrior grounds on tilted collision geometry"):
		return
	var normal: Vector3 = hit["normal"]
	if not _verify(foot_ik.is_surface_usable(normal, 0.15, 49.0, 0.28), "12-degree slope passes surface acceptance gate"):
		return
	print("AOTL R39 TERRAIN PHYSICS PASS: ", checks, " checks")
	quit(0)
