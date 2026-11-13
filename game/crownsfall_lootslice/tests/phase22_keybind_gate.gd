extends SceneTree
## Actual separate 3D rig-lab F11 and Phase21 stride-control dispatch regression.
const LAB := preload("res://scripts/three_d/rig_lab.gd")
var checks := 0
func _initialize() -> void:
    call_deferred("run_checks")
func press(lab: Node3D, keycode: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = keycode
    event.pressed = true
    lab._unhandled_input(event)
func run_checks() -> void:
    var lab := LAB.new()
    root.add_child(lab)
    await process_frame
    assert(lab.player != null and lab.player.ik_available)
    checks += 1
    assert(not lab.player.foot_ik.active)
    checks += 1
    press(lab, KEY_F11)
    assert(lab.player.foot_ik.active)
    checks += 1
    press(lab, KEY_F11)
    assert(not lab.player.foot_ik.active)
    checks += 1
    press(lab, KEY_F10)
    assert(lab.player.stride_rate_mode and lab.player.stride_rate > 1.0)
    checks += 1
    press(lab, KEY_F8)
    assert(not lab.player.stride_rate_mode and lab.player.stride_rate == 1.0)
    checks += 1
    lab.queue_free()
    await process_frame
    print("PHASE22_REAL_LAB_KEYS %d/6 PASS" % checks)
    quit(0)