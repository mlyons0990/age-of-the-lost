extends RefCounted
## Reusable geometry for frame-sampled weapon sweeps.
## No persistent state, so it can be tested outside the Warrior animation rig.
##
## Each segment is the blade (hilt->tip) at one sample. The continuous sweep
## between two blade samples is conservatively approximated with:
##  - previous blade segment
##  - current blade segment
##  - the hilt motion segment
##  - the tip motion segment
##  - the two cross diagonals
## Capsule radius applies to these swept segments. This is a conservative
## collision volume, not a full mesh-on-mesh test.

const EPSILON := 0.0000001

static func nearest_fraction(a: Vector3, b: Vector3, point: Vector3) -> float:
	var ab := b - a
	var length_squared := ab.length_squared()
	if length_squared <= EPSILON:
		return 0.0
	return clampf((point - a).dot(ab) / length_squared, 0.0, 1.0)

static func point_segment_distance_squared(point: Vector3, a: Vector3, b: Vector3) -> float:
	if not point.is_finite() or not a.is_finite() or not b.is_finite():
		return INF
	var foot := a.lerp(b, nearest_fraction(a, b, point))
	return point.distance_squared_to(foot)

static func touches_swept_blade(target: Vector3, target_radius: float,
		prev_hilt: Vector3, prev_tip: Vector3, curr_hilt: Vector3, curr_tip: Vector3,
		blade_radius: float = 0.12) -> bool:
	if target_radius < 0.0 or blade_radius < 0.0:
		return false
	for point in [target, prev_hilt, prev_tip, curr_hilt, curr_tip]:
		if not point.is_finite():
			return false
	var radius := target_radius + blade_radius
	var d2 := radius * radius
	for endpoints in [
		[prev_hilt, prev_tip],
		[curr_hilt, curr_tip],
		[prev_hilt, curr_hilt],
		[prev_tip, curr_tip],
		[prev_hilt, curr_tip],
		[prev_tip, curr_hilt]
	]:
		if point_segment_distance_squared(target, endpoints[0], endpoints[1]) <= d2:
			return true
	return false

static func attack_contact_phase(kind: String) -> float:
	# Tuned against actual Blender R47 Slash weapon-bone trajectory:
	# blade moving rapidly through frames 12-17 of 23.
	match kind:
		"Cast":
			return 0.40
		"Slash", "Cleave", "Dash":
			return 0.57
		_:
			return 0.57

static func contact_window(kind: String) -> Vector2:
	# Normalized window, intentionally wider than a single frame.
	# This supports frame-rate-independent sampling and animation blend.
	if kind == "Cast":
		return Vector2(0.35, 0.55)
	return Vector2(0.42, 0.76)

static func in_contact_window(kind: String, phase: float) -> bool:
	var w := contact_window(kind)
	return phase >= w.x and phase <= w.y

static func crossed_contact_event(previous_phase: float, current_phase: float,
		kind: String) -> bool:
	var marker := attack_contact_phase(kind)
	if previous_phase < 0.0 or not is_finite(previous_phase) or not is_finite(current_phase):
		return false
	# Reject backwards scrubs, attack restarts and animation loop wraps:
	# a new attack must reset its per-swing event state explicitly.
	if current_phase < previous_phase:
		return false
	return previous_phase < marker and current_phase >= marker

static func blade_from_socket(socket: Node3D, length_m: float = 0.85) -> Dictionary:
	# Actual R39 Godot probe (run 43404167311): local -Y reaches a
	# target 0.65m in front, while original -Z pointed away from the hit.
	if socket == null or length_m <= 0.0:
		return {}
	var hilt := socket.global_position
	var tip := socket.to_global(Vector3(0.0, -length_m, 0.0))
	if not hilt.is_finite() or not tip.is_finite():
		return {}
	return {"hilt": hilt, "tip": tip}

static func swept_samples_touch_target(samples: Array, target: Vector3,
		target_radius: float = 0.45, blade_radius: float = 0.12) -> bool:
	if samples.size() < 2:
		return false
	for i in range(1, samples.size()):
		var previous: Dictionary = samples[i - 1]
		var current: Dictionary = samples[i]
		if not (previous.has("hilt") and previous.has("tip") and current.has("hilt") and current.has("tip")):
			continue
		if touches_swept_blade(target, target_radius,
				previous["hilt"], previous["tip"],
				current["hilt"], current["tip"], blade_radius):
			return true
	return false
