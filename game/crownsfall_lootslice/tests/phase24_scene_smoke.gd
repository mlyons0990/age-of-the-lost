extends SceneTree
## Structural smoke only; not physics or visual certification.
## godot --headless --path game/crownsfall_lootslice --script res://tests/phase24_scene_smoke.gd
const COURSE := preload("res://scenes/phase24_stair_lab.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var lab: Node3D = COURSE.instantiate()
    root.add_child(lab)
    await process_frame
    var steps := get_nodes_in_group("phase24_steps")
    if steps.size() != 6:
        push_error("Expected 6 Phase24 tagged physical risers, got %d" % steps.size())
        quit(1)
        return
    for step in steps:
        if not (step is StaticBody3D):
            push_error("Stair step is not a static physics body")
            quit(1)
            return
        if step.find_child("CollisionShape3D", false, false) == null:
            push_error("Stair step has no collision shape")
            quit(1)
            return
    var wall := lab.get_node_or_null("Phase24_UnmarkedWall_NoAssist")
    if wall == null or wall.is_in_group("phase24_steps"):
        push_error("Untagged wall gate failed")
        quit(1)
        return
    if lab.get_node_or_null("Phase24_OptInStepAssist") == null:
        push_error("Missing Phase24 stair assist")
        quit(1)
        return
    print("Phase24 structural scene smoke: 9/9 checks passed")
    quit(0)
