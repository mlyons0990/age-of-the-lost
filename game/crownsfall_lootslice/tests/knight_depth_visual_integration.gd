extends SceneTree
## Rendered-only Phase 06 guard: catches the bug where the 3D knight's Sprite3D
## existed but was fully obscured by the alpha-blended painted floor.
## Use Godot with real OpenGL/Vulkan/Xvfb rendering, NOT --headless.
## Writes only diagnostic PNGs to user:// in an isolated test profile.
var checks := 0
var failed := 0

func check(ok: bool, what: String) -> void:
    checks += 1
    if ok:
        print("PASS ", what)
    else:
        failed += 1
        push_error("FAIL " + what)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    change_scene_to_file("res://main.tscn")
    for i in 9: await process_frame
    var game = current_scene
    if game == null:
        check(false,"Main scene exists")
        quit(1)
        return
    check(game.player.sprite != null,"Authoritative painted player loaded")
    if game.hud.start_panel != null:
        game.hud.start_panel.queue_free()
        game.hud.start_panel = null
        game.hud._refresh_pause()
    game.toggle_live_25d()
    for i in 9: await process_frame
    var bridge = game.live_25d
    check(bridge.is_ready,"Visual-only Crownsfall 3D scenery renders")
    bridge.toggle_knight_depth()
    for i in 9: await process_frame
    var actor = bridge.knight_depth_avatar
    check(actor != null and actor.painted_sprite.texture != null,"Current original knight frame is sent to the 3D pass")
    bridge.set_process(false)
    await RenderingServer.frame_post_draw
    var with_knight: Image = root.get_texture().get_image()
    with_knight.save_png("user://aotl_phase06_rendered_with_knight.png")
    actor.painted_sprite.visible = false
    for i in 3: await process_frame
    await RenderingServer.frame_post_draw
    var without_knight: Image = root.get_texture().get_image()
    without_knight.save_png("user://aotl_phase06_rendered_without_knight.png")
    var viewport_size: Vector2 = game.get_viewport().get_visible_rect().size
    var relative: Vector2 = Vector2(with_knight.get_width(),with_knight.get_height()) / viewport_size
    var player_screen: Vector2 = game.get_viewport().get_canvas_transform() * game.player.global_position
    var center: Vector2 = player_screen * relative
    # Sample a human-sized region above the character's ground contact.
    var left: int = clampi(int(center.x - 130),0,with_knight.get_width() - 1)
    var right: int = clampi(int(center.x + 130),0,with_knight.get_width() - 1)
    var top: int = clampi(int(center.y - 240),0,with_knight.get_height() - 1)
    var bottom: int = clampi(int(center.y + 40),0,with_knight.get_height() - 1)
    var diff_pixels := 0
    for yy in range(top,bottom,2):
        for xx in range(left,right,2):
            var a: Color = with_knight.get_pixel(xx,yy)
            var b: Color = without_knight.get_pixel(xx,yy)
            if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.18:
                diff_pixels += 1
    print("AOTL_VISIBLE_KNIGHT_PIXELS ",diff_pixels," center=",center," inspected=",Vector2(right-left,bottom-top))
    check(diff_pixels > 250,"Rendered 3D-depth knight is actually visible, not hidden by painted floor")
    print("AOTL PHASE06 RENDERED VISIBILITY: ",checks-failed,"/",checks," passed")
    quit(0 if failed == 0 else 1)
