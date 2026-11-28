extends "res://scripts/three_d/phase26_visual_lab.gd"
## Phase27 adds measurement only, and never alters the knee bone pose.
const AUDIT := preload("res://scripts/three_d/phase27_rig_audit.gd")
var audit: Node3D
var audit_hud: Label
func _ready() -> void:
    super._ready()
    audit = AUDIT.new()
    audit.name = "Phase27_ReadOnlyKneeAudit"
    add_child(audit)
    audit.configure(player)
    var canvas := CanvasLayer.new()
    canvas.layer = 6
    add_child(canvas)
    audit_hud = Label.new()
    audit_hud.position = Vector2(22, 418)
    audit_hud.add_theme_font_size_override("font_size", 16)
    canvas.add_child(audit_hud)

func _process(delta: float) -> void:
    super._process(delta)
    if audit_hud != null and audit != null:
        audit_hud.text = audit.summary()
