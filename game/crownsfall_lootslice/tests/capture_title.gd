extends SceneTree
## Title screen and class select captures.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var out := OS.get_cmdline_user_args()[0].substr(6)
	root.size = Vector2i(1920, 1080)
	var t: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(t)
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/title.png")
	t._show_pick()
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/title_pick.png")
	quit(0)
