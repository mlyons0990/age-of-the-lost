extends SceneTree
## Phase 22: real v10 Higgsfield GLB independent Godot rendering smoke gate.
## This is the *actual optimized binary* committed to feature branch.
## NOT the user's active Phase11 playable Crownsfall game or an art sign-off.
const ART := "res://assets/25d/citadel/AOTL_Citadel_Higgsfield_Optimized_v10.glb"
const SIZES := [
    Vector2i(1920, 1080),
    Vector2i(2560, 1440),
]
var failures: Array[String] = []
var samples: Array[Dictionary] = []

func _initialize() -> void:
    call_deferred("_run")

func _color_stats(frame: Image) -> Dictionary:
    var tones: Dictionary = {}
    var min_luma: float = 999.0
    var max_luma: float = -999.0
    for y in range(0, frame.get_height(), 32):
        for x in range(0, frame.get_width(), 32):
            var c: Color = frame.get_pixel(x, y)
            var key: int = int(c.r * 31) * 1024 + int(c.g * 31) * 32 + int(c.b * 31)
            tones[key] = true
            min_luma = minf(min_luma, c.get_luminance())
            max_luma = maxf(max_luma, c.get_luminance())
    return {"tones": tones.size(), "range": max_luma - min_luma}

func _run() -> void:
    root.size = Vector2i(1280, 720)
    var packed := load(ART) as PackedScene
    if packed == null:
        printerr("CITADEL_V22_RENDER FAIL: real v10 GLB missing")
        quit(1)
        return
    var model := packed.instantiate() as Node3D
    if model == null:
        printerr("CITADEL_V22_RENDER FAIL: GLB root not Node3D")
        quit(1)
        return
    root.add_child(model)
    model.name = "Actual_Higgsfield_v10_309_Meshes"
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("a5c0d5")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("e9dcc9")
    env.ambient_light_energy = 0.36
    env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    env_node.environment = env
    root.add_child(env_node)
    var light := DirectionalLight3D.new()
    light.light_color = Color("ffe9bb")
    light.light_energy = 0.62
    light.shadow_enabled = true
    light.rotation_degrees = Vector3(-52, 28, -16)
    root.add_child(light)
    var cam := Camera3D.new()
    cam.name = "Citadel_v22_Isometric_Review_Camera"
    cam.projection = Camera3D.PROJECTION_ORTHOGONAL
    cam.size = 40
    cam.position = Vector3(23, 29, -25)
    root.add_child(cam)
    cam.look_at(Vector3(0, 1.7, 7.5), Vector3.UP)
    cam.current = true
    for resolution in SIZES:
        root.size = resolution
        for i in range(10):
            await process_frame
        await RenderingServer.frame_post_draw
        var shot := root.get_texture().get_image()
        if shot.is_empty() or shot.get_width() != resolution.x or shot.get_height() != resolution.y:
            failures.append("frame unavailable at %dx%d" % [resolution.x,resolution.y])
            continue
        var stats := _color_stats(shot)
        var name := "citadel_v22_real_higgsfield_v10_%dx%d.png" % [resolution.x,resolution.y]
        var err := shot.save_png("res://" + name)
        if err != OK:
            failures.append("PNG write failed at " + name)
        if int(stats["tones"]) < 12 or float(stats["range"]) < 0.10:
            failures.append("flat or underspecified frame " + name)
        samples.append({
            "resolution": "%dx%d" % [resolution.x,resolution.y],
            "tones": stats["tones"],
            "luma_range": stats["range"],
            "png": name
        })
    if failures.is_empty() and samples.size() == SIZES.size():
        for item in samples:
            print("CITADEL_V22_REAL_RENDER PASS %s unique=%d luma_range=%.4f saved=%s" % [
                item["resolution"], item["tones"], item["luma_range"], item["png"]])
        quit(0)
    else:
        for message in failures:
            printerr("CITADEL_V22_REAL_RENDER FAIL: " + message)
        quit(1)
