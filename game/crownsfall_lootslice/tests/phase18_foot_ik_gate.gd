extends SceneTree
## Phase 18: import and toggle test; doesn't open or modify any game saves.
const HERO = preload("res://scripts/three_d/rig_controller.gd")
var checks := 0
func _initialize() -> void:
    call_deferred("run_test")
func run_test() -> void:
    var ground := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(20,0.4,20)
    shape.shape = box
    ground.add_child(shape)
    ground.position.y = -0.2
    root.add_child(ground)
    var hero := HERO.new()
    hero.position.y = 0.1
    root.add_child(hero)
    await process_frame
    assert(hero.foot_ik != null and hero.ik_available)
    checks += 1
    assert(hero.foot_ik.ik_nodes.size() == 2)
    checks += 1
    assert(hero.foot_ik.targets.size() == 2)
    checks += 1
    assert(not hero.foot_ik.active)
    checks += 1
    assert(hero.foot_ik.foot_bones.size() == 2)
    checks += 1
    assert(hero.toggle_foot_ik())
    checks += 1
    assert(hero.foot_ik_status().contains("Foot IK R&D"))
    checks += 1
    hero.foot_ik.update_foot_placement(0.016,true,4.3)
    checks += 1
    assert(not hero.toggle_foot_ik())
    checks += 1
    for ik in hero.foot_ik.ik_nodes:
        assert(ik.interpolation == 0.0)
        checks += 1
    for marker in hero.foot_ik.targets:
        assert(is_instance_valid(marker))
        checks += 1
    hero.queue_free()
    ground.queue_free()
    await process_frame
    print("PHASE18 IK LAB SMOKE: %d/13 checks OK" % checks)
    quit(0)
