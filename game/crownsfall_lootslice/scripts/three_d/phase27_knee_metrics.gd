extends RefCounted
## Read-only joint geometry and sanity checks, independent of SkeletonIK3D.
## Angles: 180 degrees means straight knee; decreasing means flexion.
const HYPEREXTENSION_DEG := 178.0
const MAX_FLEXION_DEG := 35.0
const MIN_SEGMENT_LENGTH_M := 0.045
const MAX_FOOT_TARGET_ERROR_M := 0.12

static func knee_angle_deg(hip: Vector3, knee: Vector3, ankle: Vector3) -> float:
    var thigh := hip - knee
    var shin := ankle - knee
    if thigh.length() < MIN_SEGMENT_LENGTH_M or shin.length() < MIN_SEGMENT_LENGTH_M:
        return -1.0
    return rad_to_deg(acos(clampf(thigh.normalized().dot(shin.normalized()), -1.0, 1.0)))

static func signed_knee_offset(hip: Vector3, knee: Vector3, ankle: Vector3,
        forward: Vector3) -> float:
    # Signed distance of the knee from hip-to-ankle axis, projected on the
    # model's forward direction. A zero value means an ambiguous pole target.
    var axis := ankle - hip
    var normal := forward.normalized()
    if axis.length_squared() < 0.0001 or normal.length_squared() < 0.001:
        return 0.0
    var fraction := clampf((knee - hip).dot(axis) / axis.length_squared(), 0.0, 1.0)
    var off_axis := knee - (hip + axis * fraction)
    return off_axis.dot(normal)

static func evaluate(hip: Vector3, knee: Vector3, ankle: Vector3,
        foot: Vector3, anchor: Vector3, planted: bool, forward: Vector3) -> Dictionary:
    var angle := knee_angle_deg(hip, knee, ankle)
    var pole := signed_knee_offset(hip, knee, ankle, forward)
    var error_m := foot.distance_to(anchor) if planted else 0.0
    var valid := angle >= 0.0 and hip.is_finite() and knee.is_finite() and ankle.is_finite()
    return {
        "angle_deg": angle,
        "pole_offset_m": pole,
        "foot_error_m": error_m,
        "valid": valid,
        "near_full_extension": valid and angle >= HYPEREXTENSION_DEG,
        "overflexed": valid and angle <= MAX_FLEXION_DEG,
        "ambiguous_pole": valid and absf(pole) <= 0.008,
        "foot_drift": planted and error_m > MAX_FOOT_TARGET_ERROR_M,
    }
