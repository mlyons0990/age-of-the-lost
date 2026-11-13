extends SceneTree
## Phase23: render authentic v10 baseline and painted v13 derived GLB in
## the SAME isolated Godot world. No writes to user's approved Phase11 scene.
const ART_OLD := "res://assets/25d/citadel/AOTL_Citadel_Higgsfield_Optimized_v10.glb"
const ART_NEW := "res://assets/25d/citadel/AOTL_Citadel_Painterly_v13.glb"
const SIZES := [Vector2i(1920,1080), Vector2i(2560,1440)]
var failures: Array[String] = []
var samples: Array[Dictionary] = []

func _initialize() -> void:
    call_deferred("_run")

func _stats(frame: Image) -> Dictionary:
    var tones: Dictionary = {}
    var minimum := 1000.0
    var maximum := -1000.0
    var average := 0.0
    var samples_count := 0
    for y in range(0,frame.get_height(),32):
        for x in range(0,frame.get_width(),32):
            var c := frame.get_pixel(x,y)
            var key := int(c.r*31)*1024+int(c.g*31)*32+int(c.b*31)
            tones[key] = true
            var luma := c.get_luminance()
            minimum = minf(minimum,luma)
            maximum = maxf(maximum,luma)
            average += luma
            samples_count += 1
    return {"tones":tones.size(),"range":maximum-minimum,
            "mean_luminance":average/float(maxi(samples_count,1))}

func _sample_diff(before: Image, after: Image) -> Dictionary:
    var total := 0
    var changed := 0
    var max_channel := 0.0
    for y in range(0,before.get_height(),32):
        for x in range(0,before.get_width(),32):
            var b := before.get_pixel(x,y)
            var a := after.get_pixel(x,y)
            var diff := maxf(absf(b.r-a.r),maxf(absf(b.g-a.g),absf(b.b-a.b)))
            total += 1
            if diff > 0.02:
                changed += 1
            max_channel = maxf(max_channel,diff)
    return {"sampled_pixels":total,"changed_2pct":changed,
            "fraction_changed":float(changed)/float(maxi(total,1)),
            "max_rgb_difference":max_channel}

func _run() -> void:
    root.size = Vector2i(1280,720)
    var packed_old := load(ART_OLD) as PackedScene
    var packed_new := load(ART_NEW) as PackedScene
    if packed_old == null or packed_new == null:
        printerr("CITADEL_V23_RENDER FAIL: baseline or new GLB absent")
        quit(1)
        return
    var old: Node3D = packed_old.instantiate() as Node3D
    var candidate: Node3D = packed_new.instantiate() as Node3D
    if old == null or candidate == null:
        printerr("CITADEL_V23_RENDER FAIL: imported root not a Node3D")
        quit(1)
        return
    root.add_child(old)
    root.add_child(candidate)
    old.name = "AOTL_Ph22_Baseline"
    candidate.name = "AOTL_Ph23_Painted"
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("a5c0d5")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("e9dcc9")
    env.ambient_light_energy = 0.36
    env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    environment.environment = env
    root.add_child(environment)
    var key := DirectionalLight3D.new()
    key.light_color = Color("ffe9bb")
    key.light_energy = 0.62
    key.shadow_enabled = true
    key.rotation_degrees = Vector3(-52,28,-16)
    root.add_child(key)
    var cam := Camera3D.new()
    cam.projection = Camera3D.PROJECTION_ORTHOGONAL
    cam.size = 40
    cam.position = Vector3(23,29,-25)
    root.add_child(cam)
    cam.look_at(Vector3(0,1.7,7.5),Vector3.UP)
    cam.current = true

    for resolution in SIZES:
        root.size = resolution
        var baseline_image: Image
        var painted_image: Image
        for variant in ["baseline","painted"]:
            old.visible = variant == "baseline"
            candidate.visible = variant == "painted"
            for tick in range(10):
                await process_frame
            await RenderingServer.frame_post_draw
            var shot := root.get_texture().get_image()
            if shot.is_empty() or shot.get_width()!=resolution.x or shot.get_height()!=resolution.y:
                failures.append("Missing viewport frame %s %s" % [variant,resolution])
                continue
            var stats := _stats(shot)
            if int(stats["tones"])<12 or float(stats["range"])<0.10:
                failures.append("Flat rendered frame %s %s" % [variant,resolution])
            var filename := "citadel_phase23_%s_%dx%d.png" % [variant,resolution.x,resolution.y]
            if shot.save_png("res://"+filename)!=OK:
                failures.append("Unable to save "+filename)
            samples.append({"variant":variant,"resolution":"%dx%d" % [resolution.x,resolution.y],
                            "unique_tones":stats["tones"],"luminance_range":stats["range"],
                            "mean_luminance":stats["mean_luminance"],"png":filename})
            if variant=="baseline":baseline_image=shot
            else:painted_image=shot
        if baseline_image != null and painted_image != null:
            var difference := _sample_diff(baseline_image,painted_image)
            print("CITADEL_V23_RENDER_COMPARE %dx%d baseline vs painted: %s" %
                [resolution.x,resolution.y,JSON.stringify(difference)])
            if int(difference["changed_2pct"])==0:
                failures.append("Painted GLB visually identical to old flat albedo")
    if failures.is_empty() and samples.size()==4:
        for s in samples:
            print("CITADEL_V23_REAL_RENDER PASS %s %s tones=%d range=%.4f PNG=%s" % [
                s["variant"],s["resolution"],int(s["unique_tones"]),
                float(s["luminance_range"]),String(s["png"])])
        quit(0)
    else:
        for m in failures:printerr("CITADEL_V23_RENDER FAIL "+m)
        quit(1)
