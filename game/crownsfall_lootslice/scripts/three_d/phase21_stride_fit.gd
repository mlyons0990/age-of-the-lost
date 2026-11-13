extends RefCounted
## Phase 21 | comparative stride-speed fit from in-place foot animation.
## Contact candidates are approximated from foot-bone minima, not shoe/ground contact.
## This is diagnostic only; calibration does not change movement without an explicit opt-in.

const MIN_CONTACT_SEGMENTS := 3
const CONTACT_HEIGHT_M := 0.075
const EPS := 0.00001
const NOMINAL_WALK_SPEED_MPS := 4.3
const NOMINAL_RUN_SPEED_MPS := 6.7

static func _horizontal(delta: Vector3) -> Vector3:
    return Vector3(delta.x, 0.0, delta.z)

static func _gather_segments(path: Dictionary, duration_s: float, band_m: float) -> Array[Vector3]:
    var pts: Array = path.get("points", [])
    var results: Array[Vector3] = []
    if pts.size() < 3 or duration_s <= EPS:
        return results
    var low: float = float(path.get("min_y", 0.0))
    for n in range(1, pts.size()):
        # Require both ends near the same foot's low point: a simple stance proxy.
        if float(pts[n - 1].y) > low + band_m or float(pts[n].y) > low + band_m:
            continue
        var dt: float = duration_s / float(pts.size() - 1)
        results.append(_horizontal(pts[n] - pts[n - 1]) / dt)
    return results

static func estimate_stride(left: Dictionary, right: Dictionary, duration_s: float, preferred_forward: Vector3 = Vector3.FORWARD, band_m: float = CONTACT_HEIGHT_M) -> Dictionary:
    var segments: Array[Vector3] = []
    segments.append_array(_gather_segments(left, duration_s, band_m))
    segments.append_array(_gather_segments(right, duration_s, band_m))
    if segments.size() < MIN_CONTACT_SEGMENTS:
        return {"ok": false, "reason": "insufficient low-foot samples", "segments": segments.size()}
    var forward: Vector3 = _horizontal(preferred_forward)
    if forward.length_squared() <= EPS:
        forward = Vector3.FORWARD
    forward = forward.normalized()
    var candidates: Array[Vector3] = []
    var reverse_samples := 0
    var transverse_samples := 0
    # A planted foot should move backwards against the body's desired heading.
    # Samples showing the opposite motion are likely swing, even when the bone
    # sits near the floor. Keep their count as an uncertainty metric.
    for v in segments:
        var projected: float = v.dot(forward)
        if projected < -0.05:
            candidates.append(v)
        elif projected > 0.05:
            reverse_samples += 1
        else:
            transverse_samples += 1
    if candidates.size() < MIN_CONTACT_SEGMENTS:
        return {"ok": false, "reason": "no consistent backwards stance segments", "segments": segments.size(), "rejected": reverse_samples}
    var mean_velocity := Vector3.ZERO
    for v in candidates:
        mean_velocity += v
    mean_velocity /= float(candidates.size())
    var corrective_velocity: Vector3 = -mean_velocity
    var speed: float = corrective_velocity.length()
    if speed <= EPS:
        return {"ok": false, "reason": "unresolved stance speed", "segments": segments.size()}
    var heading_alignment: float = corrective_velocity.normalized().dot(forward)
    var squared_residual := 0.0
    var squared_baseline := 0.0
    for v in candidates:
        squared_residual += (v + corrective_velocity).length_squared()
        squared_baseline += v.length_squared()
    var residual: float = sqrt(squared_residual / float(candidates.size()))
    var baseline: float = sqrt(squared_baseline / float(candidates.size()))
    var ambiguous: bool = float(reverse_samples) / float(segments.size()) > 0.25
    return {
        "ok": true,
        "segments": segments.size(),
        "stance_candidates": candidates.size(),
        "opposing_low_foot_segments": reverse_samples,
        "ambiguous_contact": ambiguous,
        "corrective_velocity": corrective_velocity,
        "estimated_speed_mps": speed,
        "estimated_distance_per_cycle_m": speed * duration_s,
        "forward_alignment": heading_alignment,
        "baseline_residual_mps": baseline,
        "fit_residual_mps": residual,
        "slip_reduction_pct": (1.0 - residual / maxf(baseline, EPS)) * 100.0,
        "consistent": not ambiguous and residual <= maxf(speed * 0.65, 0.08) and heading_alignment >= 0.65,
        "warning": "Low-height bone velocity is only a stance proxy; opposing low-foot segments indicate ambiguous contact. No automatic production tuning."
    }

static func analyze_report(report: Dictionary, preferred_forward: Vector3 = Vector3.FORWARD) -> Dictionary:
    if not report.get("ok", false):
        return {"ok": false, "reason": "clip report unavailable"}
    var fit: Dictionary = estimate_stride(report["left"], report["right"], float(report["duration_s"]), preferred_forward)
    fit["clip"] = report.get("clip", "")
    fit["duration_s"] = report.get("duration_s", 0.0)
    fit["sample_count"] = report.get("samples", 0)
    var clip: String = String(report.get("clip", "")).get_file()
    var nominal := NOMINAL_RUN_SPEED_MPS if clip == "Run" else NOMINAL_WALK_SPEED_MPS
    fit["nominal_world_speed_mps"] = nominal
    fit["suggested_playback_multiplier"] = (nominal / float(fit["estimated_speed_mps"])) if fit.get("ok", false) else 1.0
    return fit

static func diagnostic_line(result: Dictionary) -> String:
    if not result.get("ok", false):
        return "Stride calibration unavailable (%s, %d segments)" % [result.get("reason", "unknown"), result.get("segments", 0)]
    return "Stride fit: %.2f m/s, %.2f m/cycle, orientation %+.2f, residual %.2f m/s (%d stance / %d opposing; ambiguous=%s)" % [float(result["estimated_speed_mps"]), float(result["estimated_distance_per_cycle_m"]), float(result["forward_alignment"]), float(result["fit_residual_mps"]), int(result["stance_candidates"]), int(result["opposing_low_foot_segments"]), str(result["ambiguous_contact"])]