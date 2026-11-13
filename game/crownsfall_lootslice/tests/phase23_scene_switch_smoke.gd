extends SceneTree
## Validate navigation from the verified 3D rig lab to isolated terrain course.
const LAB := preload("res://scenes/rig_lab_3d.tscn")
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var scene := LAB.instantiate()
    root.add_child(scene)
    current_scene = scene
    await process_frame
    assert(scene.player != null)
    var ev := InputEventKey.new()
    ev.keycode = KEY_F6
    ev.pressed = true
    scene._unhandled_input(ev)
    for i in range(4): await process_frame
    assert(current_scene != null)
    assert(current_scene.name == "AOTL_Phase23_Terrain_FootContact_Lab")
    assert(current_scene.player != null)
    assert(current_scene.step_assist != null)
    print("PHASE23_SCENE_SWITCH 4/4 PASS")
    quit(0)