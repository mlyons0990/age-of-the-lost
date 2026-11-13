extends SceneTree
## Pixel-level Godot 4.6.3 renderer QA, NOT the headless game regression.
## Run under a real GL rendering context (e.g. Xvfb + --rendering-driver opengl3).
## Use isolated XDG env to avoid reading or changing the player's normal saves.
## The tests render the ACTUAL saved-game scene, source sprites and 3D courtyard.
var checks := 0
var failed := 0
var game: Node2D
var bridge: Node
var actor: Node2D

func verify(ok: bool, description: String) -> void:
    checks += 1
    if ok:
        print("PASS PIXEL: ", description)
    else:
        failed += 1
        push_error("FAIL PIXEL: " + description)

func _initialize() -> void:
    call_deferred("_run")

func _image() -> Image:
    for i in 6:
        await process_frame
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _world_image() -> Image:
    for i in 6:
        await process_frame
    await RenderingServer.frame_post_draw
    return bridge.viewport_3d.get_texture().get_image()

func _bounds(image_a: Image, image_b: Image, rect: Rect2i) -> Dictionary:
    var found := 0
    var min_x := 999999
    var min_y := 999999
    var max_x := -1
    var max_y := -1
    var x0 := maxi(0, rect.position.x)
    var y0 := maxi(0, rect.position.y)
    var x1 := mini(image_a.get_width(), rect.end.x)
    var y1 := mini(image_a.get_height(), rect.end.y)
    for yy in range(y0, y1):
        for xx in range(x0, x1):
            var a: Color = image_a.get_pixel(xx, yy)
            var b: Color = image_b.get_pixel(xx, yy)
            var dist: float = absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
            if dist > 0.175:
                found += 1
                min_x = mini(min_x, xx)
                max_x = maxi(max_x, xx)
                min_y = mini(min_y, yy)
                max_y = maxi(max_y, yy)
    return {"pixels": found, "l": min_x, "t": min_y, "r": max_x, "b": max_y}

func _run() -> void:
    change_scene_to_file("res://main.tscn")
    for i in 12:
        await process_frame
    game = current_scene
    if game == null:
        verify(false, "Real saved game loaded")
        quit(1)
        return
    if game.hud.start_panel != null:
        game.hud.start_panel.queue_free()
        game.hud.start_panel = null
        game.hud._refresh_pause()
    verify(game.toggle_live_25d(), "Real Crownsfall 3D scenery is active")
    bridge = game.live_25d
    actor = game.player
    actor.set_process(false)
    actor.set_physics_process(false)
    bridge.toggle_knight_depth()
    bridge.knight_depth_enabled = false
    bridge.knight_depth_avatar.visible = false
    var cases := [
        ["warrior", "idle_se", 0],
        ["warrior", "walk_se", 2],
        ["warrior", "attack_se", 9],
        ["mage", "cast_se", 1],
    ]
    for row in cases:
        var class_key: String = row[0]
        var clip: String = row[1]
        var frame_number: int = row[2]
        var desc := class_key + " " + clip + ":" + str(frame_number)
        actor.class_id = class_key
        actor.refresh_visuals()
        actor.sprite.play(clip)
        actor.sprite.pause()
        actor.sprite.frame = frame_number
        actor._apply_visual_footlock()
        actor.sprite.visible = true
        actor.shadow.visible = true
        var native_image: Image = await _image()
        actor.sprite.visible = false
        actor.shadow.visible = false
        var native_without: Image = await _image()
        verify(bridge.set_knight_depth_enabled(true), desc + " original art mirrored into 3D scene")
        var depth_image: Image = await _image()
        bridge.knight_depth_enabled = false
        bridge.knight_depth_avatar.visible = false
        var depth_without: Image = await _image()
        var frame_rect := Rect2i(
            int(native_image.get_width() / 2) - 250,
            int(native_image.get_height() * 0.23),
            500, int(native_image.get_height() * 0.51))
        var native: Dictionary = _bounds(native_image, native_without, frame_rect)
        var depth: Dictionary = _bounds(depth_image, depth_without, frame_rect)
        print("AOTL_SILHOUETTE ", desc, " native=", native, " depth=", depth)
        verify(native.pixels > 600 and depth.pixels > 600, desc + " source + depth pixels actually visible")
        verify(absi(native.l - depth.l) <= 4 and absi(native.r - depth.r) <= 4, desc + " horizontal silhouette aligned <=4px")
        verify(absi(native.b - depth.b) <= 4, desc + " original boot contact aligned <=4px")
        verify(absi(native.t - depth.t) <= 12, desc + " upper silhouette aligned <=12px")
    # Confirm the depth buffer is actually used: a temporary opaque *test-only*
    # wall moves in front of the painterly knight. The wall is never shipped.
    actor.class_id = "warrior"
    actor.refresh_visuals()
    actor.sprite.play("idle_se")
    actor.sprite.pause()
    actor.sprite.frame = 0
    actor._apply_visual_footlock()
    verify(bridge.set_knight_depth_enabled(true), "Original knight restored for occlusion proof")
    var avatar = bridge.knight_depth_avatar
    var center: Vector2 = bridge.camera_3d.unproject_position(avatar.global_position)
    var rect := Rect2i(int(center.x) - 225, int(center.y) - 225, 450, 450)
    var clear_knight: Image = await _world_image()
    bridge.knight_depth_enabled = false
    avatar.visible = false
    var clear_without: Image = await _world_image()
    var clear_diff: Dictionary = _bounds(clear_knight, clear_without, rect)
    var blocker := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(6.0, 6.0, 6.0)
    blocker.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color("b93e61")
    blocker.material_override = mat
    blocker.position = avatar.global_position + (
        bridge.camera_3d.global_position - avatar.global_position).normalized() * 2.5
    bridge.scenery.add_child(blocker)
    bridge.knight_depth_enabled = true
    avatar.visible = true
    bridge.sync_knight_depth()
    var blocked_knight: Image = await _world_image()
    bridge.knight_depth_enabled = false
    avatar.visible = false
    var blocked_without: Image = await _world_image()
    var blocked_diff: Dictionary = _bounds(blocked_knight, blocked_without, rect)
    print("AOTL_OCCLUSION_PROOF visible_pixels=",clear_diff.pixels,
        " blocked_pixels=",blocked_diff.pixels)
    verify(clear_diff.pixels > 700, "Knight is genuinely visible in real 3D framebuffer")
    verify(blocked_diff.pixels < int(clear_diff.pixels * 0.12),
        "Opaque 3D geometry correctly occludes actual painterly knight pixels")
    blocker.queue_free()
    bridge.set_knight_depth_enabled(false)
    verify(actor.sprite.visible and not bridge.knight_depth_enabled,
        "Switching back recovers the original 2D rendering")
    print("AOTL PHASE06 PIXEL VALIDATION: ", checks - failed, "/", checks, " passed")
    quit(0 if failed == 0 else 1)
