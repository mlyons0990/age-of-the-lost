extends SceneTree
## Real PhysicsDirectSpaceState3D raycast against flat and steep inclines.
const IK := preload("res://scripts/three_d/phase18_foot_ik.gd")
const MODEL := preload("res://models/AOTL_Wayfarer_Articulated_Proxy.glb")
var pass_count := 0
var failure_count := 0
func check(ok: bool, reason: String) -> void:
    if ok:
        pass_count += 1
    else:
        failure_count += 1
        push_error("PHASE22_TERRAIN: " + reason)
func _initialize() -> void:
    call_deferred("run_checks")
func run_checks() -> void:
    var host := Node3D.new()
    root.add_child(host)
    var floor := StaticBody3D.new()
    var collider := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(6,0.25,6)
    collider.shape = box
    floor.add_child(collider)
    host.add_child(floor)
    var model := MODEL.instantiate() as Node3D
    host.add_child(model)
    var ik := IK.new()
    host.add_child(ik)
    check(ik.bind_rig(model),"IK should bind")
    ik.set_active(true)
    await physics_frame
    floor.position = Vector3(0,-0.12,0)
    floor.rotation_degrees.z = 0
    await physics_frame
    ik.update_foot_placement(0.016,true,4.3,Vector3.FORWARD)
    check(ik.ray_hits > 0,"flat floor ray hits")
    check(ik.rejected_steep == 0,"flat floor not treated as steep")
    ik.set_active(true)
    floor.rotation_degrees.z = 20.0
    await physics_frame
    var gentle_start := ik.ray_hits
    ik.update_foot_placement(0.016,true,4.3,Vector3.FORWARD)
    check(ik.ray_hits > gentle_start,"moderate slope detected")
    check(ik.rejected_steep == 0,"moderate slope accepted")
    ik.set_active(true)
    floor.rotation_degrees.z = 70.0
    await physics_frame
    ik.update_foot_placement(0.016,true,4.3,Vector3.FORWARD)
    print("SLOPE_DIAGNOSTIC hits=",ik.ray_hits," rejected=",ik.rejected_steep," states=",ik.foot_state)
    check(ik.rejected_steep >= 1,"steep slope reject increments")
    check(not bool(ik.states[0].get("planted",true)) and not bool(ik.states[1].get("planted",true)),"no foot locks to steep slope")
    ik.set_active(true)
    floor.rotation_degrees.z = 0.0
    floor.position.y = 0.14 # A raised floor top is above the unanimated foot bone.
    await physics_frame
    ik.update_foot_placement(0.016,true,4.3,Vector3.FORWARD)
    check(ik.states[0].reason == "penetrating-ground" and ik.states[1].reason == "penetrating-ground", "raised platform does not trap buried feet")
    ik.set_active(false)
    check(not ik.active and not ik.locked[0] and not ik.locked[1],"toggle releases steep rejection")
    host.queue_free()
    await process_frame
    print("PHASE22_TERRAIN_SLOPE ",pass_count," passed; ",failure_count," failed")
    quit(0 if failure_count == 0 else 1)