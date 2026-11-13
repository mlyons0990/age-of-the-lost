extends Node3D
## Phase 23 stair traversal experiment. Runs BEFORE the actor's physics process.
## Only obstacles explicitly tagged as test-course stairs can be stepped.
## No production Crownsfall scene creates this component.
const STEP_PROBE_M := 0.38
const MAX_STEP_M := 0.19
const MIN_STEP_M := 0.025
const CLEARANCE_M := 0.025
const GROUND_TO_SOLE_M := 0.025
const COOLDOWN_S := 0.035

var hero: CharacterBody3D
var enabled := true
var smoothing_enabled := true
var visual_blend_speed := 11.0
var visual_applies := 0
var peak_visual_offset_m := 0.0
var step_events := 0
var rejected_high := 0
var rejected_blocked := 0
var candidate_checks := 0
var since_step := 0.0

func configure(body: CharacterBody3D) -> void:
    hero = body
    process_physics_priority = -10

func _process(dt: float) -> void:
    if hero == null:
        return
    var visual := hero.get("body") as Node3D
    if visual == null:
        return
    if not smoothing_enabled:
        visual.position = Vector3.ZERO
    elif dt > 0.0:
        visual.position = visual.position.lerp(Vector3.ZERO, minf(1.0, dt * visual_blend_speed))

func _physics_process(dt: float) -> void:
    if hero == null or not enabled or dt <= 0.0:
        return
    since_step += dt
    if since_step < COOLDOWN_S or not hero.is_on_floor():
        return
    var horizontal := Vector3(hero.velocity.x,0.0,hero.velocity.z)
    if horizontal.length() < 0.3:
        return
    var forward := horizontal.normalized()
    var space := get_world_3d().direct_space_state
    var sole_y := hero.global_position.y + GROUND_TO_SOLE_M
    var check_center := hero.global_position + forward * STEP_PROBE_M
    var start := Vector3(check_center.x,sole_y+MAX_STEP_M+0.30,check_center.z)
    var end := Vector3(check_center.x,sole_y-0.45,check_center.z)
    var q := PhysicsRayQueryParameters3D.create(start,end)
    q.exclude = [hero.get_rid()]
    var hit: Dictionary = space.intersect_ray(q)
    if hit.is_empty():
        return
    if not (hit.collider is StaticBody3D and hit.collider.is_in_group("phase23_step")):
        return
    candidate_checks += 1
    if hit.normal.y < 0.9:
        return
    var rise := float(hit.position.y) - sole_y
    if rise > MAX_STEP_M:
        rejected_high += 1
        return
    if rise < MIN_STEP_M:
        return
    var forward_motion := forward * 0.22
    # Only use assisted step-up if genuinely blocked at current height.
    if not hero.test_move(hero.global_transform,forward_motion):
        return
    var clearance := rise + CLEARANCE_M
    var proposed_transform := hero.global_transform.translated(Vector3.UP*clearance)
    if hero.test_move(proposed_transform,forward_motion):
        rejected_blocked += 1
        return
    var step_shift := Vector3.UP * clearance + forward_motion
    hero.global_position += step_shift
    # The collision correction is instantaneous; counter-offset the rendered model
    # then blend it forward and up so the player doesn't see a 22 cm visual pop.
    var visual := hero.get("body") as Node3D
    if visual != null and smoothing_enabled:
        visual.position = (visual.position - step_shift).limit_length(0.52)
        peak_visual_offset_m = maxf(peak_visual_offset_m,visual.position.length())
        visual_applies += 1
    # The following move_and_slide() resolves the upper stair surface.
    since_step = 0.0
    step_events += 1