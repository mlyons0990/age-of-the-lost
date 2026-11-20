extends SceneTree
## Renders the Phase 4 radiant FX on the pilot Mage: a close 3/4 view and the
## gameplay camera, at several moments of the "judgment" cast. Prints lit-pixel
## stats so the run doubles as a smoke check (shaders compiled and drew).
const RFX := preload("res://scripts/three_d/radiant_vfx.gd")
var out := "/tmp"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	call_deferred("_run")

func _gold_pixels(img: Image) -> int:
	var n := 0
	for y in range(0, img.get_height(), 3):
		for x in range(0, img.get_width(), 3):
			var c := img.get_pixel(x, y)
			if c.r > 0.8 and c.g > 0.6 and c.b < c.r * 0.92: n += 1
	return n

func _run() -> void:
	root.size = Vector2i(1280, 900)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.10, 0.09, 0.14)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.45, 0.42, 0.55)
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_bloom = 0.15
	var we := WorldEnvironment.new(); we.environment = e; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); sun.light_energy = 0.8; root.add_child(sun)
	var floor := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(30, 30); floor.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.33, 0.31, 0.34); floor.material_override = fm; root.add_child(floor)
	var m: Node3D = (load("res://models/higgsfield_mage/mage_pilot_armed.glb") as PackedScene).instantiate()
	root.add_child(m)
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	if ap:
		for n in ap.get_animation_list():
			if String(n).ends_with("Cast"):
				ap.play(n); ap.seek(ap.current_animation_length * 0.45, true); ap.pause(); break
	var fx: Node3D = RFX.new(); root.add_child(fx)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true
	# warm-up cast so shader compilation does not eat the timed frames
	fx.judgment(Vector3.ZERO, Vector3(0, 0, 1))
	var warm: float = Time.get_ticks_msec() + 1600.0
	while Time.get_ticks_msec() < warm:
		await process_frame
	seed(7)
	fx.judgment(Vector3.ZERO, Vector3(0, 0, 1))
	var shots := [[0.12, "early"], [0.30, "sweep"], [0.50, "peak"], [0.85, "fade"]]
	var t_prev := 0.0
	for s in shots:
		var dt: float = s[0] - t_prev
		t_prev = s[0]
		var end_t: float = Time.get_ticks_msec() + dt * 1000.0
		while Time.get_ticks_msec() < end_t:
			await process_frame
		# close 3/4
		cam.fov = 40
		cam.look_at_from_position(Vector3(3.6, 2.6, 5.4), Vector3(0, 0.8, 1.2))
		await process_frame; await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png("%s/radiant_%s_close.png" % [out, s[1]])
		print("RADIANT %s close gold_px=%d" % [s[1], _gold_pixels(img)])
	# gameplay camera (fresh cast, peak moment)
	seed(7)
	fx.judgment(Vector3.ZERO, Vector3(0, 0, 1))
	var end2: float = Time.get_ticks_msec() + 300.0
	while Time.get_ticks_msec() < end2:
		await process_frame
	root.size = Vector2i(1920, 1080)
	cam.fov = 32
	var pitch := deg_to_rad(52.0)
	var dist := 21.0
	cam.look_at_from_position(Vector3(0, sin(pitch) * dist, cos(pitch) * dist), Vector3(0, 0.9, 0))
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	var g := root.get_texture().get_image()
	g.save_png("%s/radiant_game_camera.png" % out)
	print("RADIANT game gold_px=%d" % _gold_pixels(g))
	quit(0)
