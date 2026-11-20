extends SceneTree
## Renders the delivered Meshy knight (no animation) from the front, 3/4 and the PoE gameplay camera.
var out := "/tmp"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(900, 900)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.78, 0.78, 0.78)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.78)
	var we := WorldEnvironment.new(); we.environment = e; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 25, 0); root.add_child(sun)
	var m: Node3D = (load("res://models/higgsfield_pilot/knight_rig.glb") as PackedScene).instantiate()
	root.add_child(m)
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	if ap: ap.stop()
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 30
	for v in [["front", Vector3(0, 0.9, 3.8)], ["three_quarter", Vector3(2.4, 1.2, 3.0)], ["back", Vector3(0, 1.0, -3.8)]]:
		cam.look_at_from_position(v[1], Vector3(0, 0.88, 0))
		await process_frame; await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/pilot_model_%s.png" % [out, v[0]])
	# gameplay camera at 1080p
	root.size = Vector2i(1920, 1080)
	cam.fov = 32
	var pitch := deg_to_rad(52.0)
	var dist := 27.0 * 0.5 / tan(deg_to_rad(16.0)) * sin(pitch)
	cam.look_at_from_position(Vector3(0, sin(pitch) * dist, cos(pitch) * dist), Vector3(0, 0.9, 0))
	await process_frame; await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/pilot_model_game_camera.png" % out)
	var top: float = cam.unproject_position(Vector3(0, 1.75, 0)).y
	var bot: float = cam.unproject_position(Vector3(0, 0, 0)).y
	print("PILOT on-screen height %.0f px at 1080p" % (bot - top))
	quit(0)
