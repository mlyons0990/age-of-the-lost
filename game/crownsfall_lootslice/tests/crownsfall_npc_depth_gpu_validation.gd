extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _grab() -> Image:
    for i in 8: await process_frame
    await RenderingServer.frame_post_draw
    return current_scene.live_25d.viewport_3d.get_texture().get_image()
func _run() -> void:
    change_scene_to_file("res://main.tscn")
    for i in 12: await process_frame
    var g=current_scene
    if g.hud.start_panel != null:
        g.hud.start_panel.queue_free()
        g.hud.start_panel=null
        g.hud._refresh_pause()
    g.player.position=Vector2(3290,2280)
    g.cam.reset_smoothing()
    for i in 25: await process_frame
    g.toggle_live_25d()
    for i in 20: await process_frame
    var b=g.live_25d
    b.set_knight_depth_enabled(true)
    var mirror:Sprite3D=b.npc_depth_mirrors["market_tailor"]
    var center:Vector2=b.camera_3d.unproject_position(mirror.global_position)
    print("CAMERA_DEBUG=", b.camera_3d.global_position, " mirror=",mirror.global_position," screen=",center," viewport=",b.viewport_3d.size)
    var a:Image=await _grab()
    mirror.visible=false
    var off:Image=await _grab()
    var n:=0
    var bounds:=Rect2i(int(center.x)-120,int(center.y)-160,240,320)
    for y in range(maxi(0,bounds.position.y),mini(a.get_height(),bounds.end.y),2):
        for x in range(maxi(0,bounds.position.x),mini(a.get_width(),bounds.end.x),2):
            var c1=a.get_pixel(x,y)
            var c2=off.get_pixel(x,y)
            if absf(c1.r-c2.r)+absf(c1.g-c2.g)+absf(c1.b-c2.b) > 0.15: n+=1
    print("AOTL08.1_NPC_GPU_VISIBLE_PIXELS=",n," center=",center)
    quit(0 if n>150 else 1)
