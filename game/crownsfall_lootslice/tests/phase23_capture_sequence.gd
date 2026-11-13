extends SceneTree
## Source frames for a genuine engine-captured Phase23 walking/stair test GIF.
## Run in a graphical Godot session, not headless/dummy renderer.
const COURSE := preload("res://scenes/phase23_terrain_lab.tscn")
const SAMPLE_FRAMES := [45, 53, 61, 69, 77, 85, 93, 101]
func _initialize() -> void: call_deferred("run")
func press_key(keycode: Key, down: bool) -> void:
    var e := InputEventKey.new()
    e.keycode = keycode
    e.physical_keycode = keycode
    e.pressed = down
    Input.parse_input_event(e)
func run() -> void:
    var scene := COURSE.instantiate()
    root.add_child(scene)
    await physics_frame
    scene.player.camera = null
    scene.teleport_lane(2)
    scene.player.toggle_foot_ik()
    scene.follow_camera = false
    scene.camera.global_position = Vector3(8.0, 9.0, 10.5)
    scene.camera.look_at(Vector3(0, 0.70, -2.3), Vector3.UP)
    scene.camera.size = 11.4
    press_key(KEY_W, true)
    var shots := 0
    for frame_idx in range(105):
        await physics_frame
        await process_frame
        if frame_idx in SAMPLE_FRAMES:
            var snap: Image = root.get_texture().get_image()
            var out := "user://phase23_stair_%02d.png" % shots
            var rc := snap.save_png(out)
            print("PHASE23_SEQUENCE_CAPTURE: frame=", frame_idx," outfile=",ProjectSettings.globalize_path(out)," result=",rc," pose=",scene.player.global_position)
            shots += 1
    press_key(KEY_W, false)
    print("PHASE23_SEQUENCE_COMPLETE: ",shots," frames")
    quit(0 if shots==SAMPLE_FRAMES.size() else 1)