extends SceneTree
## Real renders of the armed knight's Left_Slash (front 3/4 and side) for visual review.
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var out := "/tmp"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	root.size = Vector2i(640, 640)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.78, 0.78, 0.78)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.78)
	var we := WorldEnvironment.new(); we.environment = e; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 30, 0); root.add_child(sun)
	var fl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(6, 6); fl.mesh = pm; root.add_child(fl)
	var m: Node3D = (load("res://models/higgsfield_pilot/knight_pilot_armed.glb") as PackedScene).instantiate()
	root.add_child(m)
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 38
	var clip := "Left_Slash"
	var L := ap.get_animation(clip).length
	for view in [["front", Vector3(1.6, 1.6, 3.4)], ["side", Vector3(3.6, 1.5, 0.4)]]:
		cam.look_at_from_position(view[1], Vector3(0, 1.0, 0.2))
		for k in 16:
			ap.play(clip, 0); ap.seek(0.3 + (1.5 - 0.3) * k / 15.0, true); ap.pause()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s_%02d.png" % [out, view[0], k])
	quit(0)
