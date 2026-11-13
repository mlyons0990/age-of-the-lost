extends "res://scripts/three_d/phase23_terrain_visual_lab.gd"
## Phase 24 opt-in stair traversal; Phase 23 scene remains unchanged.
const ASSIST := preload("res://scripts/three_d/phase24_safe_stair_assist.gd")
var stair_assist: Node3D
var gate_label: Label

func _ready() -> void:
    super._ready()
    for child in get_children():
        if child is StaticBody3D and String(child.name).begins_with("P23_Step_"):
            child.add_to_group("phase24_steps")
    player.floor_snap_length = 0.24
    player.floor_max_angle = deg_to_rad(48.0)
    stair_assist = ASSIST.new()
    stair_assist.name = "Phase24_OptInStepAssist"
    stair_assist.configure(player)
    add_child(stair_assist)
    gate_label = Label.new()
    gate_label.position = Vector2(22, 390)
    gate_label.add_theme_font_size_override("font_size", 17)
    var canvas := CanvasLayer.new()
    canvas.layer = 3
    add_child(canvas)
    canvas.add_child(gate_label)

func _process(delta: float) -> void:
    super._process(delta)
    if stair_assist != null and gate_label != null:
        gate_label.text = "PHASE 24 SAFE STEP (lab only) | steps: %d | last rise %.3f m | headroom rejects: %d | height rejects: %d | untagged: %d" % [
            stair_assist.steps, stair_assist.last_rise_m,
            stair_assist.blocked_by_clearance, stair_assist.rejected_rise,
            stair_assist.rejected_obstacle]
