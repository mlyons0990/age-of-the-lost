extends Node3D
## Phase 22: revised opt-in 2-foot IK training mode.
## Never enabled in production Crownsfall; independent testbed only.
const CLASSIFIER := preload("res://scripts/three_d/phase22_contact_classifier.gd")
const PAIRS := [
    {"root": "HipL", "tip": "FootL", "name": "Left"},
    {"root": "HipR", "tip": "FootR", "name": "Right"},
]
const GROUND_CLEARANCE := 0.075
const RAY_START := 0.9
const RAY_REACH := 2.2
const TARGET_WEIGHT := 0.84
const WEIGHT_RESPONSE := 7.5

var skeleton: Skeleton3D
var ik_nodes: Array[SkeletonIK3D] = []
var targets: Array[Marker3D] = []
var foot_bones: Array[int] = []
var hip_bones: Array[int] = []
var leg_reach_m: Array[float] = []
var reach_releases := 0
var stance_positions: Array[Vector3] = []
var last_local_foot: Array[Vector3] = []
var last_actor_position := Vector3.ZERO
var states: Array[Dictionary] = []
var locked := [false, false]
var active := false
var foot_state := ["swing", "swing"]
var ray_hits := 0
var release_events := 0
var plant_events := 0
var rejected_steep := 0

func bind_rig(model: Node3D) -> bool:
    if not ik_nodes.is_empty():
        return false # Duplicate solvers must never be installed on the same skeleton.
    skeleton = model.find_child("Skeleton3D", true, false) as Skeleton3D
    if skeleton == null:
        return false
    for descriptor in PAIRS:
        if skeleton.find_bone(String(descriptor["root"])) < 0 or skeleton.find_bone(String(descriptor["tip"])) < 0:
            return false # Prevalidate both chains to prevent partial solver installation.
    for descriptor in PAIRS:
        var hip: int = skeleton.find_bone(String(descriptor["root"]))
        var foot: int = skeleton.find_bone(String(descriptor["tip"]))
        if hip < 0 or foot < 0:
            return false
        var ik := SkeletonIK3D.new()
        ik.name = "AOTL_%s_FootIK" % String(descriptor["name"])
        ik.root_bone = String(descriptor["root"])
        ik.tip_bone = String(descriptor["tip"])
        ik.override_tip_basis = false
        ik.interpolation = 0.0
        skeleton.add_child(ik)
        var marker := Marker3D.new()
        marker.name = "AOTL_%s_PlantTarget" % String(descriptor["name"])
        get_tree().root.add_child(marker)
        var p := skeleton.global_transform * skeleton.get_bone_global_pose(foot).origin
        marker.global_position = p
        ik.target_node = ik.get_path_to(marker)
        ik.start()
        ik_nodes.append(ik)
        targets.append(marker)
        foot_bones.append(foot)
        hip_bones.append(hip)
        leg_reach_m.append(skeleton.get_bone_global_rest(hip).origin.distance_to(skeleton.get_bone_global_rest(foot).origin))
        stance_positions.append(p)
        last_local_foot.append(skeleton.get_bone_global_pose(foot).origin)
        states.append(CLASSIFIER.fresh())
    last_actor_position = skeleton.global_position
    return ik_nodes.size() == 2

func set_active(value: bool) -> void:
    active = value
    locked = [false, false]
    foot_state = ["swing", "swing"]
    for i in ik_nodes.size():
        ik_nodes[i].interpolation = 0.0
        states[i] = CLASSIFIER.fresh()
        if skeleton != null:
            last_local_foot[i] = skeleton.get_bone_global_pose(foot_bones[i]).origin
    if skeleton != null:
        last_actor_position = skeleton.global_position

func update_foot_placement(delta: float, locomotion: bool, planar_speed: float, movement_direction: Vector3 = Vector3.FORWARD, exclude: Array = []) -> void:
    if skeleton == null or ik_nodes.size() != 2 or delta <= 0.0:
        return
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var distance_travelled: float = skeleton.global_position.distance_to(last_actor_position)
    if distance_travelled > CLASSIFIER.MAX_TELEPORT_DELTA_M:
        set_active(active)
    last_actor_position = skeleton.global_position
    var movement := Vector3(movement_direction.x, 0.0, movement_direction.z).normalized()
    var collision_exclusions: Array[RID] = []
    for object_rid in exclude:
        if object_rid is RID:
            collision_exclusions.append(object_rid)
    for index in range(2):
        var local_foot: Vector3 = skeleton.get_bone_global_pose(foot_bones[index]).origin
        var foot: Vector3 = skeleton.global_transform * local_foot
        var local_delta: Vector3 = local_foot - last_local_foot[index]
        var local_velocity: Vector3 = skeleton.global_basis * local_delta / maxf(delta, 0.001)
        last_local_foot[index] = local_foot
        var query := PhysicsRayQueryParameters3D.create(foot + Vector3.UP * RAY_START, foot - Vector3.UP * RAY_REACH)
        query.collide_with_areas = false
        query.exclude = collision_exclusions
        var hit: Dictionary = space.intersect_ray(query)
        var candidate := foot
        var normal := Vector3.UP
        var height := 999.0
        var valid := not hit.is_empty()
        if valid:
            ray_hits += 1
            normal = hit["normal"]
            candidate = hit["position"] + Vector3.UP * GROUND_CLEARANCE
            candidate.x = foot.x
            candidate.z = foot.z
            height = foot.y - candidate.y
            if normal.normalized().y < CLASSIFIER.MIN_GROUND_NORMAL_Y:
                rejected_steep += 1
                valid = false
        var prev: bool = bool(states[index].get("planted", false))
        var hip_world: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(hip_bones[index]).origin
        var exceeds_reach: bool = prev and CLASSIFIER.exceeds_leg_reach(hip_world, stance_positions[index], leg_reach_m[index])
        if exceeds_reach:
            reach_releases += 1
        states[index] = CLASSIFIER.decide(states[index], delta, height, valid, normal,
            local_velocity, movement, planar_speed, active and locomotion,
            ((CLASSIFIER.MAX_TARGET_ERROR_M + 1.0 if exceeds_reach else foot.distance_to(stance_positions[index])) if prev else 0.0))
        var plant: bool = bool(states[index]["planted"])
        if plant and not prev:
            stance_positions[index] = candidate
            plant_events += 1
        elif not plant and prev:
            release_events += 1
        locked[index] = plant
        var weight := TARGET_WEIGHT if plant else 0.0
        ik_nodes[index].interpolation = move_toward(ik_nodes[index].interpolation, weight, WEIGHT_RESPONSE * delta)
        targets[index].global_position = stance_positions[index] if plant else candidate
        foot_state[index] = "plant" if plant else String(states[index]["reason"])

func get_status() -> String:
    if not active:
        return "Foot IK off — original animation"
    return "Foot IK Phase22  ·  L %s  /  R %s  ·  planted %d / released %d" % [
        foot_state[0], foot_state[1], plant_events, release_events]

func _exit_tree() -> void:
    for solver in ik_nodes:
        if is_instance_valid(solver):
            solver.queue_free()
    for marker in targets:
        if is_instance_valid(marker):
            marker.queue_free()