extends "res://scripts/three_d/rig_lab.gd"
## Phase 24 self-contained stair course on the stable articulated rig lab.
## Compatible with both Phase23 full-source ZIP and GitHub QA branch.
const ASSIST := preload("res://scripts/three_d/phase24_safe_stair_assist.gd")
var stair_assist: Node3D
var gate_label: Label

func _ready() -> void:
    super._ready()
    _build_stair_course()
    player.floor_snap_length = 0.24
    player.floor_max_angle = deg_to_rad(48.0)
    player.global_position = Vector3(8.0, 0.12, 5.8)
    stair_assist = ASSIST.new()
    stair_assist.name = "Phase24_OptInStepAssist"
    stair_assist.configure(player)
    add_child(stair_assist)
    gate_label = Label.new()
    gate_label.position = Vector2(22, 248)
    gate_label.add_theme_font_size_override("font_size", 16)
    var canvas := CanvasLayer.new()
    canvas.layer = 3
    add_child(canvas)
    canvas.add_child(gate_label)

func _build_stair_course() -> void:
    # Six solid risers, 14 cm additional height per consecutive top surface.
    # Tagged colliders are the ONLY objects the solver can step over.
    for i in range(6):
        var rise := float(i + 1) * 0.14
        var step := StaticBody3D.new()
        step.name = "Phase24_Riser_%02d" % (i + 1)
        step.position = Vector3(8.0, rise * 0.5, 3.0 - float(i) * 0.72)
        step.add_to_group("phase24_steps")
        add_child(step)
        var shape_node := CollisionShape3D.new()
        var collision_shape := BoxShape3D.new()
        collision_shape.size = Vector3(2.4, rise, 0.72)
        shape_node.shape = collision_shape
        step.add_child(shape_node)
        var mesh_node := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = collision_shape.size
        mesh_node.mesh = mesh
        mesh_node.material_override = _material(Color("7589a0") if i % 2 == 0 else Color("a0aabc"))
        step.add_child(mesh_node)
    # Unmarked wall verifies assist never climbs arbitrary gameplay objects.
    var wall := StaticBody3D.new()
    wall.name = "Phase24_UnmarkedWall_NoAssist"
    wall.position = Vector3(3.5, 0.45, 0.0)
    add_child(wall)
    var wall_shape := CollisionShape3D.new()
    var wall_box := BoxShape3D.new()
    wall_box.size = Vector3(1.0, 0.9, 2.0)
    wall_shape.shape = wall_box
    wall.add_child(wall_shape)
    var wall_visual := MeshInstance3D.new()
    var wall_mesh := BoxMesh.new()
    wall_mesh.size = wall_box.size
    wall_visual.mesh = wall_mesh
    wall_visual.material_override = _material(Color("a06060"))
    wall.add_child(wall_visual)

func _process(delta: float) -> void:
    super._process(delta)
    if stair_assist != null and gate_label != null:
        gate_label.text = ("PHASE 24 · SIX 14cm RISERS · F11 IK · RED WALL NOT STEPPABLE\n"
            + "Assists: %d · Last rise: %.3fm · Clearance rejects: %d · Height rejects: %d · Untagged rejects: %d") % [
            stair_assist.steps, stair_assist.last_rise_m,
            stair_assist.blocked_by_clearance, stair_assist.rejected_rise,
            stair_assist.rejected_obstacle]
