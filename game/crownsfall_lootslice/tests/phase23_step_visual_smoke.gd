extends SceneTree
const TERRAIN := preload("res://scenes/phase23_terrain_lab.tscn")
var passed := 0
var failed := 0
func check(ok: bool, why: String) -> void:
    if ok: passed += 1
    else:
        failed += 1
        push_error("PHASE23_STEP_VISUAL: " + why)
func _initialize() -> void: call_deferred("run")
func input_key(keycode: Key, pressed: bool) -> void:
    var e := InputEventKey.new()
    e.keycode = keycode
    e.physical_keycode = keycode
    e.pressed = pressed
    Input.parse_input_event(e)
func run() -> void:
    var lab := TERRAIN.instantiate()
    root.add_child(lab)
    await physics_frame
    lab.player.camera = null
    lab.teleport_lane(2)
    check(lab.step_assist != null and lab.step_assist.enabled,"step assist exists in isolated course")
    check(lab.step_assist.smoothing_enabled,"visual blending initially enabled")
    input_key(KEY_W,true)
    for i in range(175): await physics_frame
    input_key(KEY_W,false)
    await process_frame
    check(lab.step_assist.step_events >= 1,"actual stair collisions trigger step correction")
    check(lab.step_assist.visual_applies >= 1,"step collision applies visual counter-offset")
    check(lab.step_assist.peak_visual_offset_m > 0.08,"measured nonzero motion smoothing offset")
    check(lab.step_assist.peak_visual_offset_m <= 0.525,"visual offset safely bounded")
    var k := InputEventKey.new()
    k.keycode = KEY_9
    k.pressed = true
    lab._unhandled_input(k)
    check(not lab.step_assist.smoothing_enabled,"F9 disables visual smoothing")
    await process_frame
    check(lab.player.body.position.is_zero_approx(),"disabled smoothing resets model local offset")
    lab.teleport_lane(1)
    check(lab.player.body.position.is_zero_approx(),"teleport resets visual offset")
    lab.queue_free()
    await process_frame
    print("PHASE23_VISUAL_BLEND: ",passed," passed; ",failed," failed")
    quit(0 if failed == 0 else 1)