extends SceneTree
## Offscreen standalone quality-gate render of the *imported* GLB.
## This is NOT a screenshot of the user's active Phase11 Crownsfall map.
## Run with an Xvfb display and `--rendering-method gl_compatibility`.
const ART := "res://assets/25d/citadel/AOTL_Citadel_ArtFallback_v15.glb"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(1280, 720)
    var art_scene: PackedScene = load(ART) as PackedScene
    if art_scene == null:
        printerr("CITADEL_V16_RENDER FAIL missing GLB imported PackedScene")
        quit(1)
        return
    var model: Node3D = art_scene.instantiate() as Node3D
    if model == null:
        printerr("CITADEL_V16_RENDER FAIL invalid model root")
        quit(1)
        return
    root.add_child(model)
    model.name = "ArtOnly_220Meshes"
    var world := WorldEnvironment.new()
    world.name = "WarmSunlit_Citadel_Environment"
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("c6d7e4")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("f3e9d8")
    env.ambient_light_energy = 0.95
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    root.add_child(world)
    var sun := DirectionalLight3D.new()
    sun.name = "Warm_Citadel_Sun"
    sun.light_color = Color("ffe9bb")
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    sun.rotation_degrees = Vector3(-52.0, 28.0, -16.0)
    root.add_child(sun)
    var camera := Camera3D.new()
    camera.name = "Citadel_Production_Isometric_GLB_Check"
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 40.0
    camera.position = Vector3(23.0, 29.0, -25.0)
    root.add_child(camera)
    camera.look_at(Vector3(0.0, 1.7, 7.5), Vector3.UP)
    camera.current = true
    # Allow imported meshes, shadows and render thread to settle.
    for i in range(12):
        await process_frame
    await RenderingServer.frame_post_draw
    var frame: Image = root.get_texture().get_image()
    if frame.is_empty():
        printerr("CITADEL_V16_RENDER FAIL no drawable output")
        quit(1)
        return
    if frame.get_width() < 900 or frame.get_height() < 500:
        printerr("CITADEL_V16_RENDER FAIL undersized frame")
        quit(1)
        return
    var pixels: Dictionary = {}
    var min_luma := 999.0
    var max_luma := -999.0
    for y in range(0, frame.get_height(), 26):
        for x in range(0, frame.get_width(), 26):
            var rgb: Color = frame.get_pixel(x, y)
            var key: int = int(rgb.r * 31.0) * 1024 + int(
                rgb.g * 31.0) * 32 + int(rgb.b * 31.0)
            pixels[key] = true
            var luma := rgb.get_luminance()
            min_luma = minf(min_luma, luma)
            max_luma = maxf(max_luma, luma)
    var file_error: Error = frame.save_png("res://citadel_v16_render.png")
    if file_error != OK:
        printerr("CITADEL_V16_RENDER FAIL PNG save: %d" % file_error)
        quit(1)
        return
    if pixels.size() < 20 or max_luma - min_luma < 0.07:
        printerr("CITADEL_V16_RENDER FAIL flat frame sampled_unique=%d range=%.3f" % [
            pixels.size(), max_luma - min_luma])
        quit(1)
        return
    print("CITADEL_V16_RENDER PASS %dx%d unique=%d luma_range=%.3f" % [
        frame.get_width(), frame.get_height(), pixels.size(),
        max_luma - min_luma])
    quit(0)
