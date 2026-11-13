extends SceneTree
const IK := preload("res://scripts/three_d/phase18_foot_ik.gd")
const MODEL := preload("res://models/AOTL_Wayfarer_Articulated_Proxy.glb")
var checks := 0
func _initialize() -> void:
    call_deferred("run_checks")
func run_checks() -> void:
    var root_node := Node3D.new()
    root.add_child(root_node)
    var floor := StaticBody3D.new()
    floor.position = Vector3(0,-0.1,0)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(20,0.2,20)
    collider.shape = shape
    floor.add_child(collider)
    root_node.add_child(floor)
    var model := MODEL.instantiate() as Node3D
    root_node.add_child(model)
    var ik := IK.new()
    root_node.add_child(ik)
    await process_frame
    assert(ik.bind_rig(model))
    checks += 1
    assert(ik.ik_nodes.size() == 2 and ik.targets.size() == 2)
    checks += 1
    assert(not ik.active)
    checks += 1
    ik.set_active(true)
    assert(ik.active)
    checks += 1
    ik.update_foot_placement(0.016,true,4.3,Vector3.FORWARD)
    checks += 1
    assert(ik.states.size() == 2 and ik.foot_bones.size() == 2)
    checks += 1
    assert(ik.ray_hits >= 0)
    checks += 1
    ik.set_active(false)
    assert(not ik.active and not ik.locked[0] and not ik.locked[1])
    checks += 1
    assert(is_zero_approx(ik.ik_nodes[0].interpolation))
    checks += 1
    assert(is_zero_approx(ik.ik_nodes[1].interpolation))
    checks += 1
    root_node.queue_free()
    await process_frame
    print("PHASE22_IK_ENGINE %d/%d PASS" % [checks,checks])
    quit(0)