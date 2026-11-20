extends SceneTree
## Real in-lab captures of the pilot knight's Slash at game timing (controller playback), close and at
## the ~100 px gameplay camera. --out=<dir>
const LAB := preload("res://scripts/three_d/rig_lab.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var out := "/tmp"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	for setup in [["close", 5.5, Vector2i(720, 720)], ["game", 21.0, Vector2i(1920, 1080)]]:
		root.size = setup[2]
		var lab = LAB.new(); lab.use_pilot_knight_candidate = true; lab.pilot_camera_distance = setup[1]
		root.add_child(lab)
		for i in 40: await process_frame
		var d = lab.targets[0]
		d.global_position = lab.player.global_position + lab.player.last_face * 0.9
		for i in 10: await process_frame
		lab.player._attack("Slash", 0.72)
		for k in 18:
			for j in 3: await physics_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s_%02d.png" % [out, setup[0], k])
		lab.queue_free()
		for i in 5: await process_frame
	quit(0)
