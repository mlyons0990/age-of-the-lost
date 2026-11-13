extends Node3D
## Optional terrain-aware leg IK for the articulated 3D lab.
## Godot 4.3: SkeletonIK3D is deprecated but supported. Never modifies source animations.
## Imported skeletons without ThighL/AnkleL and ThighR/AnkleR run unchanged.

@export var ground_collision_mask: int = 1
@export var foot_clearance_m: float = 0.16
@export var probe_up_m: float = 0.65
@export var probe_down_m: float = 1.25
@export var weight_speed: float = 12.0
@export var target_speed: float = 18.0
@export var max_step_m: float = 0.28
@export var max_horizontal_reach_m: float = 0.52
@export var max_normal_tilt_degrees: float = 49.0
@export var enabled: bool = true

var actor: CharacterBody3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var solvers: Dictionary = {}
var targets: Dictionary = {}
var ankles: Dictionary = {}
var planted: Dictionary = {}
var planted_world: Dictionary = {}
var last_phase: float = 0.0
var contact_releases: int = 0
var invalid_surface_skips: int = 0
var active: bool = false

static func circular_distance(a: float, b: float) -> float:
	return absf(fposmod(a - b + 0.5, 1.0) - 0.5)

static func contact_phase(side: String, running: bool) -> float:
	# Blender V27 contact markers: Walk (frame 5 R, 17 L; frames 1..25)
	# Run (frame 5 R, 15 L; frames 1..19). Phase is zero-based.
	if running:
		return 14.0 / 18.0 if side == "L" else 4.0 / 18.0
	return 16.0 / 24.0 if side == "L" else 4.0 / 24.0

static func stance_weight(phase: float, side: String, running: bool) -> float:
	var d := circular_distance(phase, contact_phase(side, running))
	var inner := 0.055 if running else 0.07
	var outer := 0.11 if running else 0.135
	return 1.0 - smoothstep(inner, outer, d)

func configure(model_root: Node3D, character: CharacterBody3D, player: AnimationPlayer) -> bool:
	actor = character
	animation_player = player
	var candidates := model_root.find_children("*", "Skeleton3D", true, false)
	if candidates.is_empty():
		return false
	skeleton = candidates[0] as Skeleton3D
	if skeleton == null:
		return false
	for side in ["L", "R"]:
		var thigh := skeleton.find_bone("Thigh" + side)
		var ankle := skeleton.find_bone("Ankle" + side)
		if thigh < 0 or ankle < 0:
			return false
		ankles[side] = ankle
	for side in ["L", "R"]:
		var target := Node3D.new()
		target.name = "TerrainFootTarget" + side
		add_child(target)
		target.global_position = _animated_ankle(side)
		var ik := SkeletonIK3D.new()
		ik.name = "TerrainLegIK" + side
		ik.root_bone = "Thigh" + side
		ik.tip_bone = "Ankle" + side
		ik.override_tip_basis = false
		ik.max_iterations = 16
		ik.min_distance = 0.004
		ik.influence = 0.0
		skeleton.add_child(ik)
		ik.target_node = ik.get_path_to(target)
		ik.start()
		targets[side] = target
		solvers[side] = ik
		planted[side] = false
	active = true
	return true

func _animated_ankle(side: String) -> Vector3:
	# Read the animation BEFORE IK overrides to prevent target feedback/drift.
	var pose := skeleton.get_bone_global_pose_no_override(int(ankles[side]))
	return skeleton.to_global(pose.origin)

func _ground_below(world_ankle: Vector3) -> Dictionary:
	var from := world_ankle + Vector3.UP * probe_up_m
	var to := world_ankle - Vector3.UP * probe_down_m
	var query := PhysicsRayQueryParameters3D.create(from, to, ground_collision_mask)
	query.exclude = [actor.get_rid()]
	return actor.get_world_3d().direct_space_state.intersect_ray(query)

func _reset_locks() -> void:
	for side in ["L", "R"]:
		planted[side] = false

func reset_contact_state() -> void:
	_reset_locks()
	if not active:
		return
	for side in ["L", "R"]:
		var solver: SkeletonIK3D = solvers[side]
		solver.influence = 0.0
		var target: Node3D = targets[side]
		target.global_position = _animated_ankle(side)

static func is_reach_safe(animated_ankle: Vector3, locked_foot: Vector3, max_horizontal_m: float) -> bool:
	var horizontal_offset := Vector2(animated_ankle.x - locked_foot.x, animated_ankle.z - locked_foot.z)
	return horizontal_offset.length() <= max_horizontal_m

func update_foot_ik(delta: float, clip: String, phase: float) -> void:
	if not active or not is_instance_valid(actor):
		return
	var locomotion := clip == "Walk" or clip == "Run"
	var allowed := enabled and actor.is_on_floor() and locomotion
	if not allowed:
		_reset_locks()
	var running := clip == "Run"
	for side in ["L", "R"]:
		var animated := _animated_ankle(side)
		var ik: SkeletonIK3D = solvers[side]
		var target: Node3D = targets[side]
		var hit := _ground_below(animated) if allowed else {}
		var desired_weight := 0.0
		var goal := animated
		if allowed and not hit.is_empty():
			var surface: Vector3 = hit["position"]
			var surface_normal: Vector3 = hit["normal"]
			var correction := surface.y + foot_clearance_m - animated.y
			if surface_normal.dot(Vector3.UP) >= cos(deg_to_rad(max_normal_tilt_degrees)) and absf(correction) <= max_step_m:
				desired_weight = stance_weight(phase, side, running)
				if desired_weight >= 0.98 and not bool(planted[side]):
					# Save a true WORLD position so translating the actor cannot drag a planted foot.
					planted_world[side] = Vector3(animated.x, surface.y + foot_clearance_m, animated.z)
					planted[side] = true
				elif desired_weight <= 0.15:
					planted[side] = false
				if bool(planted[side]):
					var lock: Vector3 = planted_world[side]
					# Never ask a leg to reach an unreachable planted target.
					if not is_reach_safe(animated, lock, max_horizontal_reach_m):
						planted[side] = false
						contact_releases += 1
						desired_weight = 0.0
						goal = animated
					else:
						goal = lock
				else:
					goal = Vector3(animated.x, surface.y + foot_clearance_m, animated.z)
			else:
				planted[side] = false
				invalid_surface_skips += 1
		else:
			planted[side] = false
		# World-space targets and influence are eased separately to prevent a hard plant/release pop.
		var t := 1.0 - exp(-target_speed * delta)
		target.global_position = target.global_position.lerp(goal, t)
		ik.influence = move_toward(ik.influence, desired_weight, weight_speed * delta)
	last_phase = phase
