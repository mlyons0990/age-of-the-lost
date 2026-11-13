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
	print("AOTL R39 TERRAIN PHYSICS PASS: ", checks, " checks")
	quit(0)
