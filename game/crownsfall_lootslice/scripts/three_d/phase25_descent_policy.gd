extends RefCounted
## Phase 25 pure downward-step policy. Collision verification stays with the runtime.
const MIN_DROP_M := 0.025
const MAX_DROP_M := 0.185
const MIN_NORMAL_Y := 0.80
const MAX_SPEED_MPS := 7.1
const GRACE_S := 0.12

static func accepted(drop_m: float, floor_normal: Vector3, speed_mps: float,
        recently_grounded: bool, tagged_step: bool, safe_vertical_path: bool,
        attacking: bool, dodging: bool) -> bool:
    return is_finite(drop_m) and is_finite(speed_mps) and floor_normal.is_finite() \
        and drop_m >= MIN_DROP_M and drop_m <= MAX_DROP_M \
        and floor_normal.normalized().y >= MIN_NORMAL_Y \
        and speed_mps > 0.3 and speed_mps <= MAX_SPEED_MPS \
        and recently_grounded and tagged_step and safe_vertical_path \
        and not attacking and not dodging
