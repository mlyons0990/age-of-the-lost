extends SceneTree
const TERRAIN := preload("res://scenes/phase23_terrain_lab.tscn")
func _initialize() -> void: call_deferred("run")
func key(code: Key, down: bool) -> void:
    var e := InputEventKey.new()
    e.keycode = code
    e.physical_keycode = code
    e.pressed = down
    Input.parse_input_event(e)
func run():
    var arena := TERRAIN.instantiate()
    root.add_child(arena)
    await physics_frame
    await physics_frame
    arena.player.camera = null
    arena.player.toggle_foot_ik()
    for lane in [1,2,3]:
        arena.teleport_lane(lane)
        await physics_frame
        key(KEY_W,true)
        var low := INF
        var high := -INF
        var grounded := 0
        for i in range(265):
            await physics_frame
            low = minf(low,arena.player.global_position.y)
            high = maxf(high,arena.player.global_position.y)
            if arena.player.is_on_floor(): grounded += 1
            if i%45 == 0:
                print("LANE ",lane," frame ",i," pos ",arena.player.global_position," grounded ",arena.player.is_on_floor())
        key(KEY_W,false)
        await physics_frame
        print("TRAVERSAL_SUMMARY lane=",lane," pos=",arena.player.global_position," minY=",low," maxY=",high," grounded_frames=",grounded," assist_checks=",arena.step_assist.candidate_checks," steps=",arena.step_assist.step_events," high=",arena.step_assist.rejected_high," blocked=",arena.step_assist.rejected_blocked," plants=",arena.player.foot_ik.plant_events," releases=",arena.player.foot_ik.release_events)
    arena.queue_free()
    await process_frame
    quit(0)