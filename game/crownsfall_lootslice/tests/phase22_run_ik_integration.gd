extends SceneTree
## Phase 22 physical-floor and animated gait integration test.
## Runs with a real imported GLB, a ground collider and the experimental IK node.
const IK := preload("res://scripts/three_d/phase18_foot_ik.gd")
const MODEL := preload("res://models/AOTL_Wayfarer_Articulated_Proxy.glb")
var checks := 0
var failures := 0
func assert_check(ok: bool, description: String) -> void:
    if not ok:
        failures += 1
        push_error("PHASE22_RUN: " + description)
    else:
        checks += 1
func _initialize() -> void:
    call_deferred("run_checks")
func run_checks() -> void:
    var host := Node3D.new()
    root.add_child(host)
    var floor := StaticBody3D.new()
    floor.name = "FlatGround"
    floor.position.y = -0.12
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(30,0.24,30)
    shape.shape = box
    floor.add_child(shape)
    host.add_child(floor)
    var model := MODEL.instantiate() as Node3D
    host.add_child(model)
    var anim := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
    var ik := IK.new()
    host.add_child(ik)
    await physics_frame
    assert_check(anim != null,"animation player imported")
    assert_check(ik.bind_rig(model),"both IK chains import")
    assert_check(ik.ik_nodes.size() == 2,"two IK solvers")
    ik.set_active(true)
    assert_check(ik.active,"enabled")
    var key := ""
    for name in anim.get_animation_list():
        if String(name).get_file() == "Run":
            key = String(name)
    assert_check(key != "","Run clip present")
    if key == "":
        quit(1)
        return
    var length := anim.get_animation(key).length
    var frame_dt := length / 60.0
    for frame in range(61):
        var progress := float(frame)/60.0
        anim.play(key,0.0)
        anim.seek(length*progress,true)
        anim.advance(0.0)
        model.position.z = -progress * length * 6.7
        ik.update_foot_placement(frame_dt,true,6.7,Vector3.FORWARD)
    print("PHASE22_RUN_LOG plants=",ik.plant_events," releases=",ik.release_events," ray_hits=",ik.ray_hits," steep=",ik.rejected_steep)
    assert_check(ik.ray_hits > 10,"ground physics rays hit")
    assert_check(ik.plant_events > 0,"at least one foot acquired stance")
    assert_check(ik.release_events > 0,"at least one foot released stance")
    assert_check(ik.states.size() == 2,"states track both feet")
    ik.set_active(false)
    assert_check(not ik.locked[0] and not ik.locked[1],"both feet release when disabled")
    assert_check(is_zero_approx(ik.ik_nodes[0].interpolation) and is_zero_approx(ik.ik_nodes[1].interpolation),"disabled IK has zero influence")
    host.queue_free()
    await process_frame
    print("PHASE22_RUN_IK_INTEGRATION ",checks," passed; ",failures," failed")
    quit(0 if failures == 0 else 1)