extends RefCounted
## Phase 22 — deterministic stance/swing quality gate, with hysteresis.
## Pure math: physics raycasting and skeleton IK are handled by the separate lab script.
## Distinguishes low swinging feet from low feet traveling backwards relative to body.

const MIN_ALLOWED_PENETRATION_M := -0.09
const ENTER_HEIGHT := 0.105
const EXIT_HEIGHT := 0.205
const MIN_REARWARD_SPEED := 0.22
const MAX_FORWARD_SPEED_LOCKED := 0.28
const MAX_CONTACT_NORMAL_ANGLE_DEG := 48.0
const MIN_GROUND_NORMAL_Y := 0.66913
const ENTER_CONFIRM_S := 0.048
const MAX_CONTACT_TIME_S := 0.48
const MAX_TARGET_ERROR_M := 0.44
const MIN_ACTOR_SPEED := 0.18
const MAX_TELEPORT_DELTA_M := 1.8

static func fresh() -> Dictionary:
    return {"planted": false, "confirm_s": 0.0, "plant_s": 0.0,
        "reason": "initial", "confidence": 0.0, "samples": 0, "cooldown_s": 0.0}

static func _xz(vector: Vector3) -> Vector3:
    return Vector3(vector.x, 0.0, vector.z)

static func exceeds_leg_reach(hip_position: Vector3, anchored_foot: Vector3,
        nominal_length_m: float, extra_m: float = 0.08) -> bool:
    # A locked sole must not drag the pelvis past the leg's natural extension.
    return nominal_length_m > 0.1 and hip_position.distance_to(anchored_foot) > nominal_length_m * 1.03 + extra_m

static func decide(old: Dictionary, dt: float, foot_height: float, ground_valid: bool,
        ground_normal: Vector3, relative_velocity: Vector3, actor_heading: Vector3,
        actor_speed: float, can_locomo: bool, target_error: float) -> Dictionary:
    var state: Dictionary = old.duplicate(true)
    var duration: float = clampf(dt, 0.0, 0.075)
    var planted: bool = bool(state.get("planted", false))
    state["cooldown_s"] = maxf(0.0, float(state.get("cooldown_s", 0.0)) - duration)
    var reason := "swing"
    var valid := ground_valid and ground_normal.is_finite() and ground_normal.normalized().y >= MIN_GROUND_NORMAL_Y
    var forward: Vector3 = _xz(actor_heading).normalized()
    var velocity: Vector3 = _xz(relative_velocity)
    var rearward: float = -velocity.dot(forward)
    var locomotion := can_locomo and actor_speed >= MIN_ACTOR_SPEED and forward.length_squared() > 0.25
    var penetrating: bool = foot_height < MIN_ALLOWED_PENETRATION_M
    var height_gate: bool = foot_height <= (EXIT_HEIGHT if planted else ENTER_HEIGHT) and not penetrating
    var breaks: bool = not valid or not locomotion or not height_gate or target_error > MAX_TARGET_ERROR_M
    if breaks:
        planted = false
        state["confirm_s"] = 0.0
        state["plant_s"] = 0.0
        if not valid: reason = "no-ground-or-steep"
        elif not locomotion: reason = "not-locomoting"
        elif penetrating: reason = "penetrating-ground"
        elif not height_gate: reason = "lifted"
        else: reason = "overstretched"
    elif planted:
        state["plant_s"] = float(state.get("plant_s", 0.0)) + duration
        if rearward < -MAX_FORWARD_SPEED_LOCKED:
            planted = false
            reason = "forward-swing"
        elif float(state["plant_s"]) >= MAX_CONTACT_TIME_S:
            planted = false
            reason = "contact-timeout"
            state["cooldown_s"] = 0.16
        else:
            reason = "planted"
        if not planted:
            state["confirm_s"] = 0.0
            state["plant_s"] = 0.0
    elif float(state["cooldown_s"]) > 0.0:
        state["confirm_s"] = 0.0
        reason = "cooldown"
    elif rearward >= MIN_REARWARD_SPEED:
        state["confirm_s"] = float(state.get("confirm_s", 0.0)) + duration
        if float(state["confirm_s"]) >= ENTER_CONFIRM_S:
            planted = true
            reason = "contact-acquired"
            state["plant_s"] = 0.0
        else:
            reason = "confirming"
    else:
        state["confirm_s"] = 0.0
        reason = "forward-or-unclear"
    state["planted"] = planted
    state["reason"] = reason
    state["confidence"] = clampf(float(state.get("confirm_s", 0.0)) / ENTER_CONFIRM_S, 0.0, 1.0) if not planted else 1.0
    state["samples"] = int(state.get("samples", 0)) + 1
    state["rearward_mps"] = rearward
    state["height_m"] = foot_height
    return state