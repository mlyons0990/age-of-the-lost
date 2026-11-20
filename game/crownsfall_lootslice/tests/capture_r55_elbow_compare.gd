extends SceneTree
## Real Godot 4.6.3 renders of R54 and R55 at the same animation times, for the frames where
## the R52 arm strain peaked. Each model is rendered alone from the same 3/4 front-right camera
## (r54_/r55_ prefixes) so tools/r53_compose_compare.py can place them side by side.
const MODELS := ["res://models/AOTL_Warrior_R54_ElbowHelper_SevenClip.glb", "res://models/AOTL_Warrior_R55_ClipSafeElbow_SevenClip.glb"]
const SHOTS := [["Slash_FullBody_R50", 5], ["Slash_FullBody_R50", 9], ["Cast", 23], ["Cast", 15], ["Idle", 1]]
var out := "user://r53_compare"
var gif_dir := ""
var elbow_cam := ""   # --elbow=R: close-up camera that follows that side's forearm head

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		if a.begins_with("--elbow="):
			elbow_cam = a.substr(8)
		if a.begins_with("--gif="):
			gif_dir = a.substr(6)
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1400, 900)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.17, 0.2)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.55, 0.6)
	env.environment = e
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	root.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 200, 0)
	fill.light_energy = 0.45
	root.add_child(fill)
	var players: Array = []
	var models: Array = []
	for i in MODELS.size():
		var m: Node3D = (load(MODELS[i]) as PackedScene).instantiate()
		m.visible = false
		root.add_child(m)
		players.append(m.find_child("AnimationPlayer", true, false))
		models.append(m)
	var cam := Camera3D.new()
	cam.fov = 42
	root.add_child(cam)
	cam.look_at_from_position(Vector3(2.6, 1.55, 3.4), Vector3(0, 1.0, 0))
	cam.current = true
	for shot in SHOTS:
		for ap in players:
			(ap as AnimationPlayer).play(shot[0], 0)
			(ap as AnimationPlayer).seek(float(shot[1]) / 30.0, true)
			(ap as AnimationPlayer).pause()
		if elbow_cam != "":
			await process_frame
			var sk: Skeleton3D = models[0].find_children("*", "Skeleton3D", true, false)[0]
			var bi := sk.find_bone("Forearm" + elbow_cam)
			var at: Vector3 = sk.global_transform * sk.get_bone_global_pose(bi).origin
			cam.fov = 30
			cam.look_at_from_position(at + Vector3(0.55, 0.12, 0.6), at)
		for i in models.size():
			for k in models.size():
				models[k].visible = k == i
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s_%s%s_f%02d.png" % [out, ["r54", "r55"][i], "elbow_" if elbow_cam != "" else "", String(shot[0]), int(shot[1])])
		print("captured ", shot)
	if gif_dir != "":
		DirAccess.make_dir_recursive_absolute(gif_dir)
		for f in range(0, 24):
			for k in models.size():
				models[k].visible = k == 1
			var ap: AnimationPlayer = players[1]
			ap.play("Slash_FullBody_R50", 0)
			ap.seek(float(f) / 30.0, true)
			ap.pause()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/slash_%02d.png" % [gif_dir, f])
	quit(0)
