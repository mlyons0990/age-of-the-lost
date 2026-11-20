extends SceneTree
## Real screenshot of the pilot knight in the rig lab at the owner's ~100 px gameplay camera (1080p).
const LAB := preload("res://scripts/three_d/rig_lab.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var out := "/tmp"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	root.size = Vector2i(1920, 1080)
	var lab = LAB.new(); lab.use_pilot_knight_candidate = true; root.add_child(lab)
	for i in 60: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/pilot_lab_idle_1080p.png")
	lab.player._attack("Slash", 0.72)
	for i in 22: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/pilot_lab_slash_1080p.png")
	quit(0)
