extends Node3D
## Optional 2.5D R&D scene. Run this scene with F6 in the Godot editor.
## Does not load gameplay save, overwrite progress, or replace res://main.tscn.

const ACTOR := preload("res://scripts/two_point_five_d/painted_actor_25d.gd")
const FX := preload("res://scripts/three_d/rig_effects.gd")
const DUMMY := preload("res://scripts/three_d/training_dummy.gd")
const INK := Color("142238")
const GOLD := Color("d0aa65")
const IVORY := Color("f4e9d5")

var camera: Camera3D
var player
var fx
var dummies: Array = []
var summary: Label
var status: Label
var casts := 0
var slain := 0

func _ready() -> void:
    _build_crownsfall_blockout()
    player = ACTOR.new()
    player.position = Vector3(0.0, 0.07, 1.2)
    add_child(player)
    camera = Camera3D.new()
    camera.name = "Camera_Orthographic_AOTL"
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 14.5
    camera.current = true
    add_child(camera)
    player.camera = camera
    fx = FX.new()
    add_child(fx)
    for i in 3:
        var t: Node3D = DUMMY.new()
        t.position = Vector3(-3.3 + float(i) * 3.3, 0.0, -3.9)
        add_child(t)
        dummies.append(t)
    player.action_impact.connect(_on_player_impact)
    _build_hud()
    _update_status("Ready — existing AOTL painted Warrior art")

func _block(position: Vector3, dimensions: Vector3, color: Color, metallic := 0.0) -> MeshInstance3D:
    var box := BoxMesh.new()
    box.size = dimensions
    var mesh := MeshInstance3D.new()
    mesh.mesh = box
    mesh.position = position
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.84
    material.metallic = metallic
    mesh.material_override = material
    add_child(mesh)
    return mesh

func _build_crownsfall_blockout() -> void:
    # The geometry is intentionally NOT called finished Crownsfall art.
    # Preserve existing assets/plaza.png instead of trying to UV-project an isometric painting onto this floor.
    var env := WorldEnvironment.new()
    env.name = "ArtDirection_LightingBlockout"
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color("d4dae1")
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color("e4d9cc")
    settings.ambient_light_energy = 0.75
    env.environment = settings
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.name = "WarmCrownfallSun"
    sun.rotation_degrees = Vector3(-55, -30, 0)
    sun.light_color = Color("fff0d4")
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)

    var floor := StaticBody3D.new()
    floor.name = "WalkableStone_Collision"
    floor.position = Vector3(0, -0.22, 0)
    add_child(floor)
    var shape := BoxShape3D.new()
    shape.size = Vector3(25, 0.4, 25)
    var collision := CollisionShape3D.new()
    collision.shape = shape
    floor.add_child(collision)
    _block(Vector3(0, -0.22, 0), Vector3(25, 0.4, 25), Color("d0c9bb"))
    # Slight material variation for visual scale cues; not a replacement for our approved plaza painting.
    for ix in range(-6, 7):
        for iz in range(-6, 7):
            var cream := Color("e5dfd1") if posmod(ix + iz, 4) == 0 else Color("dcd4c5")
            _block(Vector3(float(ix) * 1.92, 0.015, float(iz) * 1.92), Vector3(1.90, 0.033, 1.90), cream)
    # Deliberately modest environmental markers; the current goal is sprite-vs-mesh comparison.
    for x in [-8.9, 8.9]:
        for z in [-8.6, 8.6]:
            _block(Vector3(x, 1.9, z), Vector3(0.75, 3.8, 0.75), IVORY)
            _block(Vector3(x, 3.94, z), Vector3(1.0, 0.22, 1.0), GOLD, 0.30)
            _block(Vector3(x, 3.05, z - 0.43), Vector3(0.40, 0.88, 0.05), Color("183f88"))
    _block(Vector3(0.0, 0.17, -8.3), Vector3(9.1, 0.35, 1.10), Color("cfc7ba"))
    _block(Vector3(0.0, 0.42, -9.3), Vector3(9.1, 0.5, 0.85), Color("e3d9c7"))

func _small_label(value: String, font_size := 16, color: Color = IVORY) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label

func _build_hud() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "ReferenceHUD_IndependentOfGameSave"
    add_child(canvas)
    var info_panel := PanelContainer.new()
    info_panel.position = Vector2(22, 24)
    info_panel.custom_minimum_size = Vector2(550, 0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.06, 0.10, 0.91)
    style.border_color = GOLD
    style.set_border_width_all(2)
    style.set_content_margin_all(14)
    info_panel.add_theme_stylebox_override("panel", style)
    canvas.add_child(info_panel)
    var v := VBoxContainer.new()
    info_panel.add_child(v)
    v.add_child(_small_label("AGE OF THE LOST  |  2.5D ART LAB", 24, GOLD))
    v.add_child(_small_label("Real 3D collision + existing painted character sprites", 16))
    status = _small_label("", 17, Color("a5cdf5"))
    v.add_child(status)
    summary = _small_label("", 16)
    v.add_child(summary)
    v.add_child(_small_label("WASD / click: move   Shift: sprint   Space: dodge", 15, GOLD))
    v.add_child(_small_label("1: slash   2: heavy   3: cast   V: painter / rig   Tab: Mage / Warrior", 15, GOLD))
    v.add_child(_small_label("Research scene. Painted dodge-roll frames not authored yet.", 14, Color("edc8a0")))
    v.add_child(_small_label("Press F6 on this scene in Godot. Existing main game is unchanged.", 14, IVORY))
    var ref := TextureRect.new()
    ref.texture = load("res://assets/plaza.png")
    ref.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    ref.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    ref.custom_minimum_size = Vector2(460, 220)
    ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
    v.add_child(ref)
    v.add_child(_small_label("Approved painted Crownsfall plaza — visual reference only", 13, Color("b7b0a4")))

func _update_status(value: String) -> void:
    if status != null:
        status.text = value

func _process(delta: float) -> void:
    if player == null or camera == null:
        return
    var target := player.global_position + Vector3(10.0, 12.8, 10.0)
    camera.global_position = camera.global_position.lerp(target, minf(1.0, delta * 8.0))
    camera.look_at(player.global_position + Vector3.UP * 1.10, Vector3.UP)
    if summary != null:
        summary.text = "Action impacts: %d   Targets defeated: %d" % [casts, slain]

func _on_player_impact(kind: String, where: Vector3, forward: Vector3) -> void:
    casts += 1
    var magic := kind == "cast"
    var hue := Color("9a9dff") if magic else (Color("ffd588") if kind == "heavy" else Color("9ecfff"))
    if magic:
        fx.cast(where, hue)
    else:
        fx.slash(player.global_position, forward, hue, kind == "heavy")
    for item in dummies:
        if item.inactive_t > 0.0:
            continue
        var delta_to: Vector3 = item.global_position - player.global_position
        delta_to.y = 0.0
        var radius := 2.9 if magic or kind == "heavy" else 1.85
        if delta_to.length() <= radius and (magic or delta_to.normalized().dot(forward) > -0.05):
            var defeated: bool = item.hit(45 if magic else (50 if kind == "heavy" else 30))
            fx.sparks(item.global_position + Vector3.UP, hue, 7)
            if defeated:
                slain += 1

func _unhandled_input(event: InputEvent) -> void:
    if player == null:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if event.shift_pressed:
            player.start_action("slash")
            return
        var origin := camera.project_ray_origin(event.position)
        var ray := camera.project_ray_normal(event.position)
        var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, ray)
        if hit is Vector3:
            player.move_to_ground(hit)
    elif event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1: player.start_action("slash")
            KEY_2: player.start_action("heavy")
            KEY_3: player.start_action("cast")
            KEY_SPACE: player.start_dodge()
            KEY_V:
                player.change_visual_mode()
                _update_status("Visual: %s · %s" % [player.visual_mode, player.player_class])
            KEY_TAB:
                player.toggle_class()
                _update_status("Visual: %s · %s" % [player.visual_mode, player.player_class])
            KEY_ESCAPE:
                get_tree().quit()