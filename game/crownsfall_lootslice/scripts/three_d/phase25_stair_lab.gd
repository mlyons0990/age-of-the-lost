extends "res://scripts/three_d/phase24_stair_lab.gd"
## Opt-in separate scene; the Phase24 live and production scenes are unchanged.
const DESCENT := preload("res://scripts/three_d/phase25_stair_descent.gd")
var downhill: Node3D
var descent_note: Label

func _ready() -> void:
    super._ready()
    downhill = DESCENT.new()
    downhill.name = "Phase25_Descending_StairAssist"
    downhill.configure(player)
    add_child(downhill)
    descent_note = Label.new()
    descent_note.position = Vector2(22, 300)
    descent_note.add_theme_font_size_override("font_size", 17)
    var layer := CanvasLayer.new()
    layer.layer = 4
    add_child(layer)
    layer.add_child(descent_note)

func _process(dt: float) -> void:
    super._process(dt)
    if downhill != null and descent_note != null:
        descent_note.text = "PHASE 25: downhill contacts %d | blocked %d | untagged %d | last drop %.3fm" % [
            downhill.accepted_steps, downhill.blocked_steps, downhill.ignored_untagged,
            downhill.last_drop_m]
