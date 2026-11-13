extends Node3D
## Phase 24 diagnostic-only bounded stair stepping; not installed in Crownsfall.
const POLICY := preload("res://scripts/three_d/phase24_step_safety.gd")
const FORWARD_PROBE_M := 0.35
const FORWARD_SHIFT_M := 0.19
const RISE_MARGIN_M := 0.02
const RAY_START_M := 0.42
const RAY_DEPTH_M := 0.65
const STEP_COOLDOWN_S := 0.07

var actor: CharacterBody3D
var active := true
var cooldown_s := 0.0
var steps := 0
var blocked_by_clearance := 0
var rejected_rise := 0
var rejected_obstacle := 0
var last_rise_m := 0.0

func configure(character: CharacterBody3D) -> void:
    actor = character
    process_physics_priority = 10

func _physics_process(delta: float) -> void:
    cooldown_s = maxf(0.0, cooldown_s - delta)
    if not active or actor == null or cooldown_s > 0.0 or not actor.is_on_floor():
        return
    if actor.get("attack_t") > 0.0 or actor.get("dodge_t") > 0.0:
        return
    var speed := Vector2(actor.velocity.x, actor.velocity.z).length()
    if speed < 0.3 or speed > POLICY.MAX_HORIZONTAL_SPEED_MPS:
        return
    var heading := Vector3(actor.velocity.x, 0.0, actor.velocity.z).normalized()
    var ray_origin := actor.global_position + heading * FORWARD_PROBE_M
    var query := PhysicsRayQueryParameters3D.create(
        ray_origin + Vector3.UP * RAY_START_M,
        ray_origin - Vector3.UP * RAY_DEPTH_M)
    query.exclude = [actor.get_rid()]
    query.collide_with_areas = false
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return
    var obstacle: Object = hit.get("collider")
    var course_step := obstacle is StaticBody3D and obstacle.is_in_group("phase24_steps")
    if not course_step:
        rejected_obstacle += 1
        return
    var rise := float(hit["position"].y) - actor.global_position.y
    if rise < POLICY.MIN_RISE_M or rise > POLICY.MAX_RISE_M:
        rejected_rise += 1
        return
    var forward := heading * FORWARD_SHIFT_M
    var blocked_low := actor.test_move(actor.global_transform, forward)
    if not blocked_low:
        return
    var ascent := Vector3.UP * (rise + RISE_MARGIN_M)
    var headroom := not actor.test_move(actor.global_transform, ascent)
    var raised_transform := actor.global_transform.translated(ascent)
    var upper_path_clear := headroom and not actor.test_move(raised_transform, forward)
    if not upper_path_clear:
        blocked_by_clearance += 1
        return
    if not POLICY.accepted(rise, hit["normal"], speed, actor.is_on_floor(),
            upper_path_clear, blocked_low, course_step):
        return
    actor.global_position += ascent + forward
    last_rise_m = rise
    steps += 1
    cooldown_s = STEP_COOLDOWN_S
    var ik: Node3D = actor.get("foot_ik") as Node3D
    if ik != null and actor.get("ik_available"):
        ik.set_active(ik.active)
