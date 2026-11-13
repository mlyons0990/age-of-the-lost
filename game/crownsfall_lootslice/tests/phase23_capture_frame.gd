extends SceneTree
## Developer-only visual capture: actual Godot rendered screenshot, no generated concept art.
const COURSE := preload("res://scenes/phase23_terrain_lab.tscn")
func _initialize() -> void: call_deferred("run")
func key(k: Key, down: bool) -> void:
    var ev := InputEventKey.new()
    ev.keycode = k
    ev.physical_keycode = k
    ev.pressed = down
    Input.parse_input_event(ev)
func run():
    var arena := COURSE.instantiate()
    root.add_child(arena)
    await physics_frame
    arena.player.camera = null
    arena.teleport_lane(2)
    arena.player.toggle_foot_ik()
    key(KEY_W,true)
    for i in range(165): await physics_frame
    key(KEY_W,false)
    arena.follow_camera = false
    arena.camera.global_position = Vector3(8.0,9.0,10.5)
    arena.camera.look_at(Vector3(0,0.7,-2.3),Vector3.UP)
    arena.camera.size = 12.0
    for i in range(8): await process_frame
    var img: Image = root.get_texture().get_image()
    var target := "user://phase23_foot_contact_live.png"
    var rc := img.save_png(target)
    print("PHASE23_REAL_RENDER: ",target," size=",img.get_size()," rc=",rc," player_pos=",arena.player.global_position," planted=",arena.player.foot_ik.plant_events)
    arena.queue_free()
    quit(0 if rc==OK else 1)