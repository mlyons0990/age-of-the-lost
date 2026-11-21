extends SceneTree
## Renders the Mage lab with the ARPG HUD at several resolutions to prove the bar meets the screen edges.
var out := "/tmp"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	call_deferred("_run")
func _run() -> void:
	for res in [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1280, 720), Vector2i(2560, 1080)]:
		root.size = res
		await process_frame
		var lab: Node3D = (load("res://scenes/pilot_mage_combat_lab.tscn") as PackedScene).instantiate()
		root.add_child(lab)
		for i in 20: await physics_frame
		await process_frame; await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png("%s/edges_%dx%d.png" % [out, res.x, res.y])
		var r: Rect2 = lab.hud.left_piece.get_global_rect()
		print("RES %s bar %s" % [res, r])
		var a = lab.player
		var top: float = lab.camera.unproject_position(a.global_position + Vector3.UP * 1.75).y
		var bot: float = lab.camera.unproject_position(a.global_position).y
		print("HERO_PX %.0f at %s" % [bot - top, res])
		lab.queue_free()
		await process_frame
	quit(0)
