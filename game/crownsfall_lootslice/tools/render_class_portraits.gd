extends SceneTree
## Renders the four class portraits (title cards, character screen) from the real 3D heroes: same pose, camera and
## lighting for every class, transparent background. Writes assets/portraits/<class>.png.
##   xvfb-run godot --path . --rendering-driver opengl3 -s tools/render_class_portraits.gd
const HEROES := {"warrior": "res://models/higgsfield_pilot/knight_pilot_armed.glb", "rogue": "res://models/higgsfield_rogue/rogue_armed.glb",
	"mage": "res://models/higgsfield_mage/mage_pilot_armed.glb", "cleric": "res://models/higgsfield_cleric/cleric_armed.glb"}
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/portraits"))
	root.size = Vector2i(800, 1000)
	root.transparent_bg = true
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.6, 0.66)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new(); we.environment = e; root.add_child(we)
	var key := DirectionalLight3D.new(); key.rotation_degrees = Vector3(-30, 35, 0); key.light_color = Color(1.0, 0.92, 0.8); key.light_energy = 1.25; root.add_child(key)
	var rim := DirectionalLight3D.new(); rim.rotation_degrees = Vector3(-15, 200, 0); rim.light_color = Color(0.6, 0.7, 1.0); rim.light_energy = 0.9; root.add_child(rim)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 27
	cam.look_at_from_position(Vector3(1.55, 1.45, 4.3), Vector3(0, 0.92, 0))
	for cls in HEROES:
		var m: Node3D = (load(HEROES[cls]) as PackedScene).instantiate()
		root.add_child(m)
		m.rotation_degrees.y = 0.0
		var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
		ap.play("Idle"); ap.seek(0.3, true); ap.pause()
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var used := img.get_used_rect()
		img = img.get_region(used.grow(12).intersection(Rect2i(Vector2i.ZERO, img.get_size())))
		img.save_png("res://assets/portraits/%s.png" % cls)
		print("portrait ", cls, " ", img.get_size())
		m.queue_free()
		await process_frame
	quit(0)
