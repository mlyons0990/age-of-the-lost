extends SceneTree
## Phase 23: real physics locomotion through the independent terrain course.
const COURSE := preload("res://scenes/phase23_terrain_lab.tscn")
var passed := 0
var failed := 0
func check(ok: bool, description: String) -> void:
    if ok: passed += 1
    else:
        failed += 1
        push_error("PHASE23_TRAVERSAL: " + description)
func _initialize() -> void: call_deferred("run_checks")
func key(k: Key, down: bool) -> void:
    var e := InputEventKey.new()
    e.keycode = k
    e.physical_keycode = k
    e.pressed = down
    Input.parse_input_event(e)
func run_checks() -> void:
    var lab := COURSE.instantiate()
    root.add_child(lab)
    await physics_frame
    await physics_frame
    lab.player.camera = null
    check(lab.player.toggle_foot_ik(),"IK optional toggle")
    var summaries := []
    for lane in [1,2,3]:
        lab.teleport_lane(lane)
        await physics_frame
        var start_steps: int = lab.step_assist.step_events
        var highest := -100.0
        var lowest := 100.0
        var grounded := 0
        key(KEY_W,true)
        for i in range(265):
            await physics_frame
            var y: float = lab.player.global_position.y
            highest = maxf(highest,y)
            lowest = minf(lowest,y)
            if lab.player.is_on_floor():grounded += 1
        key(KEY_W,false)
        await physics_frame
        var steps: int = lab.step_assist.step_events - start_steps
        var z: float = lab.player.global_position.z
        print("PHASE23_LANE:",lane," pos=",lab.player.global_position," highY=",highest," steps=",steps," grounded=",grounded)
        summaries.append({"lane":lane,"max_y":highest,"min_y":lowest,"z":z,"steps":steps,"grounded":grounded})
        check(grounded>=240,"lane %d sustained physical floor collision" % lane)
        check(lab.player.foot_ik.plant_events>0 and lab.player.foot_ik.release_events>0,"lane %d real foot-lock lifetime" % lane)
    var ramp: Dictionary = summaries[0]
    var stairs: Dictionary = summaries[1]
    var flat: Dictionary = summaries[2]
    check(ramp.max_y>1.0,"actual ramp ascent exceeds 1 m")
    check(ramp.z < -4.0,"ramp forward travel reaches upper slope")
    check(ramp.steps>=1,"safe ramp seam assist recorded")
    check(stairs.max_y>0.30,"actual character climbs multiple 14cm steps")
    check(stairs.steps>=2,"step-up assistance occurs on stairs")
    check(flat.max_y<0.05,"flat lane maintains correct height")
    check(flat.z < -6.0,"flat lane traverses to steep obstacle")
    check(flat.steps==0,"steep untagged obstacle cannot be auto-climbed")
    check(lab.max_contact_gap_m>=0.0 and lab.contact_gap_samples>0,"foot-to-target error physically sampled")
    lab.queue_free()
    await process_frame
    print("PHASE23_TRAVERSAL_ASSERTIONS: ",passed," passed; ",failed," failed")
    quit(0 if failed==0 else 1)