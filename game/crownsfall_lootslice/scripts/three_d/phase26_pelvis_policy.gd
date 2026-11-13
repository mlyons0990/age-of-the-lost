extends RefCounted
## Pure, deterministic animation offset gates. Does not manipulate collision capsules.
const MAX_OFFSET_M := 0.065
const MAX_FOOT_ERROR_M := 0.18
const RESPONSE_HZ := 7.0
const RELEASE_RESPONSE_HZ := 11.0
const MAX_CHANGE_MPS := 0.32

static func target_offset(errors_m: Array, ik_on: bool, grounded: bool,
        combat: bool, dodging: bool) -> float:
    if not ik_on or not grounded or combat or dodging or errors_m.is_empty():
        return 0.0
    var total := 0.0
    var count := 0
    for error in errors_m:
        var gap := float(error)
        if not is_finite(gap) or absf(gap) > MAX_FOOT_ERROR_M:
            continue
        total += gap
        count += 1
    if count == 0:
        return 0.0
    # Moving the rendered pelvis down when an IK-planted ankle appears lower.
    # Clamp to preserve knee reach and avoid falsifying the physical capsule.
    return clampf(total / float(count) * 0.45, -MAX_OFFSET_M, MAX_OFFSET_M)

static func update_offset(current: float, target: float, dt: float) -> float:
    if not is_finite(current) or not is_finite(target) or dt <= 0.0:
        return 0.0 if not is_finite(current) else current
    var rate := RESPONSE_HZ if absf(target) > 0.001 else RELEASE_RESPONSE_HZ
    var alpha := 1.0 - exp(-rate * minf(dt, 0.1))
    var desired := lerpf(current, clampf(target, -MAX_OFFSET_M, MAX_OFFSET_M), alpha)
    return clampf(move_toward(current, desired, MAX_CHANGE_MPS * dt), -MAX_OFFSET_M, MAX_OFFSET_M)
