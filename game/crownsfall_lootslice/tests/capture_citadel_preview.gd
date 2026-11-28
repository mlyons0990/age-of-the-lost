extends SceneTree
var out := "/tmp"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1600, 900)
	var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.6, 0.7, 0.8)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.7, 0.72, 0.78)
	var we := WorldEnvironment.new(); we.environment = e; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, -35, 0); sun.shadow_enabled = true; root.add_child(sun)
	var c: Node3D = (load("res://assets/25d/citadel/AOTL_Citadel_MasonryArt_v17.glb") as PackedScene).instantiate(); root.add_child(c)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 40
	for v in [["front", Vector3(0, 9, -22), Vector3(0, 3, 6)], ["game", Vector3(10, 22, -18), Vector3(0, 0, 4)]]:
		cam.look_at_from_position(v[1], v[2])
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/citadel_%s.png" % [out, v[0]])
	quit(0)
