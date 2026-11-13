extends SceneTree
## Ensure multiple F11 toggles cannot leak IK targets or rebind solvers.
const IK := preload("res://scripts/three_d/phase18_foot_ik.gd")
const MODEL := preload("res://models/AOTL_Wayfarer_Articulated_Proxy.glb")
var checks := 0
var fails := 0
func check(ok: bool, label: String) -> void:
    if ok: checks += 1
    else:
        fails += 1
        push_error("PHASE22_LIFETIME: " + label)
func _initialize() -> void:
    call_deferred("run_checks")
func run_checks() -> void:
    var before_root := root.get_child_count()
    var host := Node3D.new()
    root.add_child(host)
    var model := MODEL.instantiate() as Node3D
    host.add_child(model)
    var skeleton: Skeleton3D = model.find_child("Skeleton3D",true,false)
    var ik := IK.new()
    host.add_child(ik)
    check(ik.bind_rig(model),"first bind succeeds")
    check(not ik.bind_rig(model),"second bind is rejected")
    check(ik.ik_nodes.size()==2,"exactly two solvers")
    check(root.get_child_count()==before_root+3,"two root-level foot targets")
    for i in range(100):
        ik.set_active(true)
        ik.update_foot_placement(0.016,true,4.3,Vector3.FORWARD)
        ik.set_active(false)
    check(ik.ik_nodes.size()==2 and ik.targets.size()==2,"100 toggles do not duplicate solvers")
    check(not ik.locked[0] and not ik.locked[1],"toggle off releases feet")
    ik.queue_free()
    await process_frame
    await process_frame
    check(root.get_child_count()==before_root+1,"foot target nodes removed")
    var found := 0
    for child in skeleton.get_children():
        if child.name.begins_with("AOTL_") and child.name.ends_with("FootIK"):
            found+=1
    check(found==0,"IK solvers cleaned after component removal")
    host.queue_free()
    await process_frame
    check(root.get_child_count()==before_root,"entire testbed cleans up")
    print("PHASE22_SOLVER_LIFETIME ",checks," passed; ",fails," failed")
    quit(0 if fails == 0 else 1)