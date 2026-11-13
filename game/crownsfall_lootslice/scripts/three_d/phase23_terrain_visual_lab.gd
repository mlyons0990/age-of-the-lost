extends "res://scripts/three_d/rig_lab.gd"
## Phase 23 R&D: collision-backed incline, steps and ground-contact diagnostics.
## Separate scene. Never replaces Crownsfall's active character or saves.
## This scene intentionally exposes missing automatic stair stepping.

const RAMP_ANGLE_DEG := 12.0
const STEP_HEIGHT_M := 0.16
const STEP_COUNT := 5
var terrain_note: Label

func _ready() -> void:
    super._ready()
    _create_terrain()
    _add_diagnostic_hud()
    player.global_position = Vector3(4.5, 0.12, 5.0)

func _solid_box(label_name: String, center: Vector3, size_m: Vector3,
        tint: Color, tilt_x_deg: float = 0.0) -> StaticBody3D:
    var collider := StaticBody3D.new()
    collider.name = label_name
    collider.position = center
    collider.rotation_degrees.x = tilt_x_deg
    add_child(collider)

    var shape := CollisionShape3D.new()
    var box_shape := BoxShape3D.new()
    box_shape.size = size_m
    shape.shape = box_shape
    collider.add_child(shape)

    var mesh := MeshInstance3D.new()
    var box_mesh := BoxMesh.new()
    box_mesh.size = size_m
    mesh.mesh = box_mesh
    mesh.material_override = _material(tint)
    collider.add_child(mesh)
    return collider

func _create_terrain() -> void:
    # Start at +Z and travel toward -Z along the colored right-hand testing lane.
    # The raised slope has genuine rigid-body collision, not decorative geometry.
    _solid_box("P23_Slope_12deg_Collision", Vector3(4.5, 0.42, 1.45),
        Vector3(2.7, 0.22, 4.3), Color("668f78"), -RAMP_ANGLE_DEG)
    # Independently collision-backed steps deliberately reveal the lack of
    # CharacterBody3D automatic step-up; they are NOT claimed as traversable.
    for i in range(STEP_COUNT):
        var h := STEP_HEIGHT_M * float(i + 1)
        _solid_box("P23_Step_%02d" % (i + 1),
            Vector3(8.0, h * 0.5, 3.2 - float(i) * 0.85),
            Vector3(2.25, h, 0.82),
            Color("8390a8") if i % 2 == 0 else Color("a2a9b5"))
    # A raised flat landing provides a measurable platform/contact height.
    _solid_box("P23_Raised_Platform", Vector3(-5.0, 0.30, 2.0),
        Vector3(3.0, 0.60, 3.0), Color("9c826b"))

func _add_diagnostic_hud() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 2
    add_child(layer)
    terrain_note = Label.new()
    terrain_note.position = Vector2(22, 220)
    terrain_note.add_theme_font_size_override("font_size", 17)
    terrain_note.add_theme_color_override("font_color", Color("fff0c9"))
    layer.add_child(terrain_note)

func _process(delta: float) -> void:
    super._process(delta)
    if not is_instance_valid(player) or terrain_note == null:
        return
    var elevation := player.global_position.y
    var left_plant := false
    var right_plant := false
    var plants := 0
    var releases := 0
    var ray_count := 0
    if player.ik_available and is_instance_valid(player.foot_ik):
        var ik = player.foot_ik
        left_plant = bool(ik.locked[0])
        right_plant = bool(ik.locked[1])
        plants = ik.plant_events
        releases = ik.release_events
        ray_count = ik.ray_hits
    terrain_note.text = ("PHASE 23 · COLLISION TERRAIN QA (separate scene)\n"
        + "GREEN: 12° ramp   BLUE: 16 cm stairs   BROWN: raised platform\n"
        + "Actor Y: %.3f m   Grounded: %s   Vertical speed: %.2f m/s\n"
        + "Foot L/R planted: %s / %s   Plants: %d   Releases: %d   Rays: %d\n"
        + "F11 IK toggle · F9/F10 stride rate · F8 reset · F7 plaza\n"
        + "WARNING: step-up logic is NOT implemented; record stair collisions as failures."
        ) % [elevation, str(player.is_on_floor()), player.velocity.y,
            str(left_plant), str(right_plant), plants, releases, ray_count]
