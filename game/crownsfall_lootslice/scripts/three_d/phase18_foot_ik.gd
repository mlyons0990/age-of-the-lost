extends Node3D
## Phase 18: experimental two-foot IK quality gate for the independent 3D RIG LAB.
## The production 2D Crownsfall character remains unchanged.

const PAIRS := [
    {"root":"HipL","tip":"FootL","name":"Left"},
    {"root":"HipR","tip":"FootR","name":"Right"},
]
const GROUND_CLEARANCE := 0.075
const PLANT_HEIGHT := 0.21
const RELEASE_DISTANCE := 0.56
const RAY_START := 0.9
const RAY_REACH := 2.2
const TARGET_WEIGHT := 0.84
const WEIGHT_RESPONSE := 8.0

var skeleton: Skeleton3D
var ik_nodes: Array[SkeletonIK3D] = []
var targets: Array[Marker3D] = []
var foot_bones: Array[int] = []
var stance_positions: Array[Vector3] = []
var locked := [false, false]
var active := false
var foot_state := ["swing","swing"]
var ray_hits := 0

func bind_rig(model: Node3D) -> bool:
    skeleton = model.find_child("Skeleton3D",true,false) as Skeleton3D
    if skeleton == null: return false
    for descriptor in PAIRS:
        var hip: int = skeleton.find_bone(String(descriptor["root"]))
        var foot: int = skeleton.find_bone(String(descriptor["tip"]))
        if hip < 0 or foot < 0: return false
        var ik := SkeletonIK3D.new()
        ik.name = "AOTL_%s_FootIK" % String(descriptor["name"])
        ik.root_bone = String(descriptor["root"])
        ik.tip_bone = String(descriptor["tip"])
        ik.override_tip_basis = false
        ik.interpolation = 0.0
        skeleton.add_child(ik)
        var marker := Marker3D.new()
        marker.name = "AOTL_%s_PlantTarget" % String(descriptor["name"])
        if get_tree().current_scene != null:
            get_tree().current_scene.add_child(marker)
        else:
            get_tree().root.add_child(marker)
        marker.global_position = skeleton.global_transform * skeleton.get_bone_global_pose(foot).origin
        ik.target_node = ik.get_path_to(marker)
        ik.start()
        ik_nodes.append(ik)
        targets.append(marker)
        foot_bones.append(foot)
        stance_positions.append(marker.global_position)
    return ik_nodes.size() == 2

func set_active(value: bool) -> void:
    active = value
    if not active:
        locked = [false,false]
        foot_state = ["swing","swing"]
        for ik in ik_nodes: ik.interpolation = 0.0

func update_foot_placement(delta: float, locomotion: bool, planar_speed: float) -> void:
    if skeleton == null or ik_nodes.size() != 2: return
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    for index in 2:
        var foot: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(foot_bones[index]).origin
        var query := PhysicsRayQueryParameters3D.create(foot + Vector3.UP * RAY_START, foot - Vector3.UP * RAY_REACH)
        query.collide_with_areas = false
        var hit: Dictionary = space.intersect_ray(query)
        var candidate := foot
        var near_floor := false
        if not hit.is_empty():
            ray_hits += 1
            candidate = Vector3(foot.x,float(hit["position"].y) + GROUND_CLEARANCE,foot.z)
            near_floor = absf(foot.y - candidate.y) <= PLANT_HEIGHT
        var should_plant := active and locomotion and planar_speed > 0.12 and near_floor
        if should_plant and not locked[index]:
            stance_positions[index] = candidate
            locked[index] = true
        if locked[index] and (not should_plant or foot.distance_to(stance_positions[index]) > RELEASE_DISTANCE):
            locked[index] = false
        var goal: float = TARGET_WEIGHT if locked[index] else 0.0
        if not active: goal = 0.0
        ik_nodes[index].interpolation = move_toward(ik_nodes[index].interpolation,goal,WEIGHT_RESPONSE*delta)
        targets[index].global_position = stance_positions[index] if locked[index] else candidate
        foot_state[index] = "plant" if locked[index] else "swing"

func get_status() -> String:
    if not active: return "Foot IK off — original animation"
    return "Foot IK R&D  ·  L %s  /  R %s" % [foot_state[0],foot_state[1]]

func _exit_tree() -> void:
    for marker in targets:
        if is_instance_valid(marker): marker.queue_free()
