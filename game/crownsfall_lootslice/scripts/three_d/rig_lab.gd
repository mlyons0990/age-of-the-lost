extends Node3D
## Standalone playable 3D art/rig/VFX testbed for the next developer.
## This deliberately does NOT replace the established 2D plaza; keep both.
const HERO := preload("res://scripts/three_d/rig_controller.gd")
const FX := preload("res://scripts/three_d/rig_effects.gd")
const DUMMY := preload("res://scripts/three_d/training_dummy.gd")
const IVORY := Color("f3e8d3")
const GOLD := Color("e5bf72")
const BLUE := Color("274f99")

var player
var camera: Camera3D
var effects: Node3D
var targets: Array = []
var info: Label
var hpbar: ProgressBar
var kills := 0
var mode := "3D articulated rig lab"

func _ready() -> void:
	get_tree().auto_accept_quit=true # This independent lab never changes the saved plaza actor.
	_build_world()
	player = CharacterBody3D.new()
	player.set_script(HERO)
	player.position = Vector3(0, 0.08, 1.8)
	add_child(player)
	player.impact.connect(_on_impact)
	player.health_changed.connect(_on_hp)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.0
	camera.current = true
	add_child(camera)
	player.camera = camera
	effects = FX.new()
	add_child(effects)
	for i in 4:
		var e := Node3D.new()
		e.set_script(DUMMY)
		e.position = Vector3(-4.2 + i * 2.8, 0.0, -3.6 - (i % 2) * 1.4)
		add_child(e)
		targets.append(e)
	_build_hud()

func _material(color: Color, metallic := 0.0, rough := 0.7) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = rough
	return mat

func _box(pos: Vector3, size: Vector3, col: Color, metal := 0.0) -> MeshInstance3D:
	var o := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	o.mesh = b
	o.position = pos
	o.material_override = _material(col, metal)
	add_child(o)
	return o

func _sphere(pos: Vector3, size: float, col: Color, emissive := false) -> MeshInstance3D:
	var o := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = size
	m.height = size * 2.0
	o.mesh = m
	var mat := _material(col, 0.05)
	if emissive:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 3.0
	o.material_override = mat
	o.position = pos
	add_child(o)
	return o

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("d0dcea")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("bdcce4")
	settings.ambient_light_energy = 0.45
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	settings.tonemap_exposure = 0.9
	env.environment = settings
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 0.9
	sun.light_color = Color("ffe8c3")
	sun.shadow_enabled = true
	add_child(sun)
	var floor := StaticBody3D.new()
	floor.position = Vector3(0, -0.2, 0)
	add_child(floor)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(28, 0.4, 28)
	collision.shape = shape
	floor.add_child(collision)
	_box(Vector3(0,-0.22,0), Vector3(28,0.4,28), Color("e0d9c5"))
	for x in range(-13, 14, 2):
		for z in range(-13, 14, 2):
			_box(Vector3(float(x),0.0,float(z)), Vector3(1.95,0.035,1.95), Color("eee7d4") if (x+z)%4==0 else Color("d9d4c9"))
	# Four ivory columns and hanging royal-blue pennants: art-direction cues only.
	for x in [-9.0,9.0]:
		for z in [-8.0,8.0]:
			_box(Vector3(x,2.0,z),Vector3(.8,4.0,.8),Color("eee5d2"))
			_box(Vector3(x,4.05,z),Vector3(1.18,.35,1.18),Color("d8be88"))
			_box(Vector3(x,4.5,z),Vector3(.12,.68,.25),BLUE)
			_box(Vector3(x,4.35,z-.20),Vector3(.15,.08,.15),GOLD,.6)
			_sphere(Vector3(x,4.7,z),.18,Color("ffcc83"),true)
	# Decorative blue/gold steps and framing (not level geometry).
	_box(Vector3(0,.15,-9.6),Vector3(9,.35,1.8),Color("e8dfc9"))
	_box(Vector3(0,.40,-11),Vector3(9,.8,1.2),Color("cfc6b3"))
	for x in [-12.0,12.0]:
		for z in range(-12,13,4):
			_sphere(Vector3(x,1.1,float(z)),.55,Color("78966c"))
			_sphere(Vector3(x+0.2,1.45,float(z)),.30,Color("d9d4a4"))

func _hud_label(text: String, size := 18, color: Color = IVORY) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.06, 0.1, 0.93)
	style.border_color = Color("b59b65")
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	style.set_corner_radius_all(5)
	return style

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", _panel_style())
	top.position = Vector2(20, 18)
	top.custom_minimum_size = Vector2(480, 0)
	layer.add_child(top)
	var v := VBoxContainer.new()
	top.add_child(v)
	v.add_child(_hud_label("AOTL · 3D MOTION / COMBAT TESTBED", 25, GOLD))
	v.add_child(_hud_label("58-bone GLB · six animation clips · real-time FX", 16, Color("9dbff1")))
	v.add_child(_hud_label("F11: foot IK  |  F12: master rig animation review", 15, GOLD))
	info = _hud_label("Targets defeated: 0", 17)
	v.add_child(info)
	hpbar = ProgressBar.new()
	hpbar.custom_minimum_size = Vector2(470,24)
	hpbar.max_value = 130
	hpbar.value = 130
	v.add_child(hpbar)
	var back := Button.new()
	back.text = "Return to playable 2D plaza (F7)"
	back.pressed.connect(_back_to_plaza)
	v.add_child(back)
	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", _panel_style())
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -120
	bottom.offset_bottom = -12
	bottom.offset_left = 100
	bottom.offset_right = -100
	layer.add_child(bottom)
	var words := VBoxContainer.new()
	bottom.add_child(words)
	words.add_child(_hud_label("WASD move    Shift sprint    Space dodge    Left click slash    1 cleave    2 dash strike    3 lorecast burst", 19, GOLD))
	words.add_child(_hud_label("Proxy geometry only. Final SAO-proportion character sculpt, skin weights, texture work, IK and cloth simulation still required.", 15))

func _process(delta: float) -> void:
	if player == null: return
	var goal: Vector3 = player.global_position + Vector3(8.5, 11.0, 11.0)
	camera.global_position = camera.global_position.lerp(goal, minf(1.0, delta * 6.0))
	camera.look_at(player.global_position + Vector3.UP * 1.25, Vector3.UP)
	info.text = "Targets defeated: %d  ·  Dodge invuln: %.1f s   ·  Cast cooldown: %.1f s\n%s" % [kills, player.invulnerable, player.spell_cd, player.foot_ik_status()]

func _on_hp(current: float, maximum: float) -> void:
	hpbar.max_value = maximum
	hpbar.value = current

func _on_impact(at: Vector3, kind: String, direction: Vector3) -> void:
	var spell := kind == "Cast"
	var color := Color("b0a0ff") if spell else (Color("ffe5a4") if kind == "Cleave" else Color("8acaff"))
	var wide := kind == "Cleave"
	if spell:
		effects.cast(at, color)
	else:
		effects.slash(player.global_position, direction, color, wide)
		if kind == "Dash": effects.ring(at, 0.8, Color("f2d17f"), 0.45)
	var range_limit := 2.8 if wide or spell else 1.65
	for target in targets:
		if target.inactive_t > 0: continue
		var relative: Vector3 = target.global_position - player.global_position
		var forward := relative.normalized().dot(direction)
		if relative.length() <= range_limit + 0.5 and (forward > -0.3 or wide or spell):
			var dead: bool = target.hit(53 if spell else (43 if wide else 32))
			effects.sparks(target.global_position + Vector3.UP * 1.0, color, 12)
			if dead: kills += 1

func _back_to_plaza() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F12:
		get_tree().change_scene_to_file("res://scenes/phase19_animation_review.tscn")
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		player.toggle_foot_ik()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE,KEY_F7]:
		_back_to_plaza()
