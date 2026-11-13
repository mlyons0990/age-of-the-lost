extends SceneTree
## Rig-lab QA: instantiate real terrain, inspect collision geometry, test safe controls.
const TERRAIN := preload("res://scenes/phase23_terrain_lab.tscn")
var passed := 0
var failed := 0
func check(ok: bool, description: String) -> void:
    if ok:
        passed += 1
    else:
        failed += 1
        push_error("PHASE23: " + description)
func _initialize() -> void:
    call_deferred("run_checks")
func run_checks() -> void:
    var arena := TERRAIN.instantiate()
    root.add_child(arena)
    await physics_frame
    await physics_frame
    check(arena.ready_world, "arena initialized")
    check(arena.player != null and arena.camera != null, "player and orthographic camera")
    check(arena.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "isometric camera")
    check(arena.terrain_nodes.size() >= 15, "collision mesh/physics terrain built")
    check(arena.step_top_heights.size() == 7, "seven stair risers")
    check(is_equal_approx(arena.step_top_heights[0], 0.14), "first stair correct height")
    check(is_equal_approx(arena.step_top_heights[-1], 0.98), "top stair correct height")
    check(arena.player.floor_snap_length > 0.15, "downward floor snap enabled")
    check(arena.player.floor_max_angle < deg_to_rad(49.0), "steep surfaces rejected")
    check(arena.player.ik_available, "imported articulated skeleton supports two-foot IK")
    check(not arena.player.foot_ik.active, "IK initially disabled")
    check(arena.contact_markers.size() == 2, "two visual target markers")
    var hit_count := 0
    for physics in arena.terrain_nodes:
        if physics is StaticBody3D and physics.get_child_count() >= 2:
            hit_count += 1
    check(hit_count == arena.terrain_nodes.size(), "all terrain obstacles have mesh and collision")
    arena.teleport_lane(1)
    check(is_equal_approx(arena.player.global_position.x, -7.0), "ramp reset")
    arena.teleport_lane(2)
    check(is_equal_approx(arena.player.global_position.x, 0.0), "stairs reset")
    arena.teleport_lane(3)
    check(is_equal_approx(arena.player.global_position.x, 7.0), "flat reset")
    var k := InputEventKey.new()
    k.keycode = KEY_F11
    k.pressed = true
    arena._unhandled_input(k)
    check(arena.player.foot_ik.active, "F11 toggle enables experimental IK")
    arena._unhandled_input(k)
    check(not arena.player.foot_ik.active, "F11 toggle releases IK")
    k.keycode = KEY_7
    arena._unhandled_input(k)
    check(not arena.show_contact, "contact marker display toggle")
    k.keycode = KEY_8
    arena._unhandled_input(k)
    check(not arena.follow_camera, "camera tracking toggle")
    arena._process(0.016)
    check(arena.status != null and arena.status.text.contains("World y"), "diagnostic status updates")
    arena.player.global_position = Vector3(0.0,-7.0,-4.0)
    arena._process(0.016)
    check(arena.safety_resets == 1, "out-of-bounds rescue activates once")
    check(arena.player.global_position.y > 0.0, "falling player safely returns to course")
    arena.queue_free()
    await process_frame
    print("PHASE23_TERRAIN_SCENE: ",passed," passed; ",failed," failed")
    quit(0 if failed==0 else 1)