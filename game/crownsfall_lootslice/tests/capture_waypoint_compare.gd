extends SceneTree
## Close-up of the 3D waypoint next to the approved WP1-A painting, for art comparison.
var out := "/tmp"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 10: await physics_frame
	var w: Dictionary = lab.zone_waypoints[0]
	lab.player.global_position = w["pos"] + Vector3(2.5, 0.05, 4.5)
	lab.zone_last_ok = lab.player.global_position
	await create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/wp_closeup.png")
	var c: Vector2 = lab.camera.unproject_position(w["pos"])
	print("WPCENTRE %d %d" % [int(c.x), int(c.y)])
	quit(0)
