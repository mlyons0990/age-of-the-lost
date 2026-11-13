extends "res://scripts/three_d/phase25_stair_lab.gd"
## Separate phase 26 visual-stabilization lab, no production changes.
const STABILIZER := preload("res://scripts/three_d/phase26_foot_visual_stabilizer.gd")
var stabilizer: Node3D
var visual_note: Label

func _ready() -> void:
    super._ready()
    stabilizer = STABILIZER.new()
    stabilizer.name = "Phase26_OptionalVisualStabilizer"
    add_child(stabilizer)
    stabilizer.configure(player)
    var canvas := CanvasLayer.new()
    canvas.layer = 5
    add_child(canvas)
    visual_note = Label.new()
    visual_note.position = Vector2(22, 360)
    visual_note.add_theme_font_size_override("font_size", 16)
    canvas.add_child(visual_note)

func _process(dt: float) -> void:
    super._process(dt)
    if stabilizer != null and visual_note != null:
        visual_note.text = "PHASE26 VISUAL PELVIS: %.3fm | target %.3fm | samples %d | %s" % [
            stabilizer.current_offset_m, stabilizer.target_offset_m,
            stabilizer.valid_foot_samples, stabilizer.suspended_reason]
