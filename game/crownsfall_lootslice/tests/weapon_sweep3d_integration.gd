extends SceneTree
## Deterministic geometry and animation-event timing checks for weapon sweeps.
const SWEEP := preload("res://scripts/three_d/weapon_sweep3d.gd")
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + description)

func _initialize() -> void:
	var a := Vector3(0, 0, -0.2)
	var b := Vector3(0, 0, -1.2)
	check(is_equal_approx(SWEEP.nearest_fraction(a, b, Vector3(0, 0, -0.7)), 0.5), "Closest segment fraction")
	check(is_equal_approx(SWEEP.nearest_fraction(a, a, Vector3(1, 0, 0)), 0.0), "Degenerate segment fraction")
	check(SWEEP.point_segment_distance_squared(Vector3(1, 0, -0.7), a, b) > 0.99, "Point distance is squared")
	check(SWEEP.point_segment_distance_squared(Vector3.ZERO, Vector3.INF, b) == INF, "Non-finite geometry fails closed")
	check(SWEEP.touches_swept_blade(Vector3(0, 0, -0.7), 0.2, a, b, a, b), "Static blade hits capsule center")
	check(not SWEEP.touches_swept_blade(Vector3(3, 0, 0), 0.2, a, b, a, b), "Distant enemy rejected")
	check(SWEEP.touches_swept_blade(Vector3(0, 0, -0.7), 0.15,
		Vector3(-0.7, 0, 0.0), Vector3(-0.7, 0, -1.1),
		Vector3(0.7, 0, 0.0), Vector3(0.7, 0, -1.1)), "Fast blade crosses target between frames")
	check(not SWEEP.touches_swept_blade(Vector3(0, 2.0, -0.7), 0.15,
		Vector3(-0.7, 0, 0), Vector3(-0.7, 0, -1.1),
		Vector3(0.7, 0, 0), Vector3(0.7, 0, -1.1)), "Swept strike rejects target above blade")
	check(not SWEEP.touches_swept_blade(Vector3(0,0,-0.5), -0.1, a,b,a,b), "Negative target radius rejected")
	check(not SWEEP.touches_swept_blade(Vector3.INF, 0.1, a,b,a,b), "Non-finite target rejected")
	check(SWEEP.crossed_contact_event(0.45,0.60,"Slash"), "Slash contact event triggers at marker")
	check(not SWEEP.crossed_contact_event(0.58,0.63,"Slash"), "No repeat after contact marker")
	check(not SWEEP.crossed_contact_event(0.75,0.03,"Slash"), "No loop-wrap duplicate strike")
	check(not SWEEP.crossed_contact_event(-1,0.6,"Slash"), "Uninitialized previous phase does not strike")
	check(SWEEP.in_contact_window("Slash",0.55), "Slash contact window includes middle")
	check(not SWEEP.in_contact_window("Slash",0.80), "Slash contact window excludes follow-through")
	check(SWEEP.crossed_contact_event(0.35,0.42,"Cast"), "Cast timing stays independent from sword")
	check(SWEEP.attack_contact_phase("Slash") > SWEEP.attack_contact_phase("Cast"), "Sword timing follows cast timing")
	print("AOTL WEAPON SWEEP RESULT %d checks; %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
