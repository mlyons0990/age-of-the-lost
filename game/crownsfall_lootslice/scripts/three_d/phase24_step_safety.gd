extends RefCounted
## Phase 24 deterministic lab-only policy; geometry tests remain authoritative.
const MIN_RISE_M := 0.025
const MAX_RISE_M := 0.185
const MIN_WALKABLE_NORMAL_Y := 0.80
const MAX_HORIZONTAL_SPEED_MPS := 7.1

static func accepted(rise_m: float, normal: Vector3, horizontal_speed: float,
        grounded: bool, has_clearance: bool, blocked_at_base: bool,
        is_course_step: bool) -> bool:
    if not is_finite(rise_m) or not normal.is_finite() or not is_finite(horizontal_speed):
        return false
    return grounded and is_course_step and blocked_at_base and has_clearance \
        and rise_m >= MIN_RISE_M and rise_m <= MAX_RISE_M \
        and normal.normalized().y >= MIN_WALKABLE_NORMAL_Y \
        and horizontal_speed > 0.3 and horizontal_speed <= MAX_HORIZONTAL_SPEED_MPS
