extends Node3D
## Standalone playable 3D art/rig/VFX testbed for the next developer.
## This deliberately does NOT replace the established 2D plaza; keep both.
const HERO := preload("res://scripts/three_d/rig_controller.gd")
const FX := preload("res://scripts/three_d/rig_effects.gd")
const DUMMY := preload("res://scripts/three_d/training_dummy.gd")
const TARGETING := preload("res://scripts/three_d/combat_targeting3d.gd")
const WEAPON_SWEEP := preload("res://scripts/three_d/weapon_sweep3d.gd")
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
@export var use_r50_fullbody_slash_candidate := false
@export var use_r52_rigid_armor_candidate := false
@export var use_r53_arm_skin_candidate := false
var strict_weapon_sweep := false
var contact_samples: Array = []
var contact_sample_limit := 24
var last_sampled_attack_serial := -1
var sweep_hit_instances: Dictionary = {}
var sword_sweep_debug: MeshInstance3D
var sword_sweep_lines: ImmediateMesh
var sword_sweep_material: StandardMaterial3D

func _ready() -> void:
	get_tree().auto_accept_quit=true # This independent lab never changes the saved plaza actor.
	_build_world()
	_create_sword_sweep_visualizer()
	player = CharacterBody3D.new()
	player.set_script(HERO)
	# Godot inspector opt-in: never change the stable R39 lab by default.
	player.enable_r50_fullbody_slash_candidate = use_r50_fullbody_slash_candidate
	player.enable_r52_rigid_armor_candidate = use_r52_rigid_armor_candidate
	player.enable_r53_arm_skin_candidate = use_r53_arm_skin_candidate
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

func _create_sword_sweep_visualizer() -> void:
	sword_sweep_debug = MeshInstance3D.new()
	sword_sweep_debug.name = "SwordSweepDebug"
	sword_sweep_lines = ImmediateMesh.new()
	sword_sweep_debug.mesh = sword_sweep_lines
	sword_sweep_debug.visible = false
	sword_sweep_debug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sword_sweep_material = StandardMaterial3D.new()
	sword_sweep_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sword_sweep_material.albedo_color = Color("ffca70")
	add_child(sword_sweep_debug)

func _draw_sword_sweep() -> void:
	if sword_sweep_lines == null:
		return
	sword_sweep_lines.clear_surfaces()
	sword_sweep_debug.visible = strict_weapon_sweep
	if not strict_weapon_sweep or contact_samples.size() < 1:
		return
	sword_sweep_lines.surface_begin(Mesh.PRIMITIVE_LINES, sword_sweep_material)
	for i in range(contact_samples.size()):
		var sample: Dictionary = contact_samples[i]
		var hilt: Vector3 = to_local(sample["hilt"])
		var tip: Vector3 = to_local(sample["tip"])
		sword_sweep_lines.surface_add_vertex(hilt)
		sword_sweep_lines.surface_add_vertex(tip)
		if i > 0:
			var previous: Dictionary = contact_samples[i - 1]
			sword_sweep_lines.surface_add_vertex(to_local(previous["hilt"]))
			sword_sweep_lines.surface_add_vertex(hilt)
			sword_sweep_lines.surface_add_vertex(to_local(previous["tip"]))
			sword_sweep_lines.surface_add_vertex(tip)
	sword_sweep_lines.surface_end()

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
	# Collision-backed terrain IK QA fixtures, placed away from combat dummies.
	# Decorative plaza steps below are intentionally *not* used for physics tests.
	_add_terrain_fixture(Vector3(5.4, 0.10, 2.6), Vector3(2.4, 0.20, 2.4), 0.0, Color("cbbd9d"))
	_add_terrain_fixture(Vector3(8.2, 0.22, 2.6), Vector3(2.6, 0.44, 2.4), 0.0, Color("bba88a"))
	_add_terrain_fixture(Vector3(6.4, 0.17, -0.7), Vector3(4.4, 0.24, 2.6), deg_to_rad(-8.0), Color("d3c6ac"))
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

func _add_terrain_fixture(center: Vector3, dims: Vector3, slope_radians: float, tint: Color) -> void:
	var platform := StaticBody3D.new()
	platform.name = "IK_TerrainTest"
	platform.position = center
	platform.rotation.x = slope_radians
	platform.collision_layer = 1
	add_child(platform)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dims
	collision.shape = shape
	platform.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = dims
	mesh.mesh = box_mesh
	mesh.material_override = _material(tint)
	platform.add_child(mesh)

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
	v.add_child(_hud_label("Articulated GLB · optional ground-contact IK · real-time FX", 16, Color("9dbff1")))
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
	words.add_child(_hud_label("WASD move    Shift run    Space dodge    F8 sword sweep    F9 IK    F10 IK targets    F11 equipment sockets    Click slash    1/2/3 skills", 18, GOLD))
	words.add_child(_hud_label("Foot IK automatically enables only on compatible leg bones. Current proxy may use the original animation. Terrain IK and cloth require further QA.", 15))

func _process(delta: float) -> void:
	if player == null: return
	var goal: Vector3 = player.global_position + Vector3(8.5, 11.0, 11.0)
	camera.global_position = camera.global_position.lerp(goal, minf(1.0, delta * 6.0))
	camera.look_at(player.global_position + Vector3.UP * 1.25, Vector3.UP)
	info.text = "Targets: %d  ·  Model: %s  ·  IK: %s  ·  Equipment sockets: %s  ·  Sweep: %s  ·  Reach releases: %d" % [kills, player.active_model_source, ("ON" if player.terrain_ik_available and player.terrain_ik_enabled else ("OFF" if player.terrain_ik_available else "unsupported")), ("preview" if player.equipment_debug_equipped else ("ready" if player.equipment_sockets_available else "unsupported")), ("STRICT" if strict_weapon_sweep else "baseline"), player.terrain_foot_ik.contact_releases if player.terrain_ik_available else 0]

func _physics_process(_delta: float) -> void:
	if player == null or not player.equipment_sockets_available or player.equipment_sockets == null:
		contact_samples.clear()
		_draw_sword_sweep()
		return
	if player.anim_state != "Slash" or player.attack_t <= 0.0:
		contact_samples.clear()
		_draw_sword_sweep()
		return
	if player.attack_serial != last_sampled_attack_serial:
		last_sampled_attack_serial = player.attack_serial
		contact_samples.clear()
		sweep_hit_instances.clear()
	var socket: BoneAttachment3D = player.equipment_sockets.get_socket("weapon")
	var sample: Dictionary = WEAPON_SWEEP.blade_from_socket(socket)
	if sample.is_empty():
		return
	contact_samples.append(sample)
	if contact_samples.size() > contact_sample_limit:
		contact_samples.pop_front()
	_draw_sword_sweep()
	if not strict_weapon_sweep or contact_samples.size() < 2:
		return
	var phase := -1.0
	if player.animation != null and player.animation.current_animation_length > 0:
		phase = player.animation.current_animation_position / player.animation.current_animation_length
	if not WEAPON_SWEEP.in_contact_window(player.attack_type, phase):
		return
	# Physics-frame swept damage is independent from the single animation
	# impact event, so targets only connect when the blade actually crosses.
	# Track instance IDs to prevent repeated damage through the active swing.
	var recent: Array = contact_samples.slice(-2)
	var direction: Vector3 = player.last_face
	for target in targets:
		if target.inactive_t > 0 or sweep_hit_instances.has(target.get_instance_id()):
			continue
		if not TARGETING.can_hit(get_world_3d(), player,
				player.global_position, direction, target.global_position, player.attack_type):
			continue
		var center: Vector3 = target.damage_center()
		if not WEAPON_SWEEP.swept_samples_touch_target(recent, center, target.damage_radius()):
			continue
		sweep_hit_instances[target.get_instance_id()] = true
		var dead: bool = target.hit(TARGETING.damage_for(player.attack_type))
		effects.sparks(target.global_position + Vector3.UP, Color("ffca70"), 12)
		if dead:
			kills += 1

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
	# One physics-backed damage decision per candidate; the VFX remains
	# responsive even when a nearby target is safely screened by cover.
	for target in targets:
		if target.inactive_t > 0: continue
		var allowed := TARGETING.can_hit(get_world_3d(), player, player.global_position, direction, target.global_position, kind)
		if strict_weapon_sweep and kind != "Cast":
			# Blade contacts are resolved continuously in _physics_process,
			# not at a separate one-shot event (prevents early/duplicate hits).
			continue
		var actively_swinging: bool = kind != "Cast" and player.attack_t > 0.0 and player.anim_state == "Slash"
		if actively_swinging and sweep_hit_instances.has(target.get_instance_id()):
			continue
		if allowed:
			if actively_swinging:
				sweep_hit_instances[target.get_instance_id()] = true
			var dead: bool = target.hit(TARGETING.damage_for(kind))
			effects.sparks(target.global_position + Vector3.UP * 1.0, color, 12)
			if dead: kills += 1

func _back_to_plaza() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		strict_weapon_sweep = not strict_weapon_sweep
		contact_samples.clear()
		# Do not reset the per-swing hit ledger on mode change: that could
		# apply damage twice to a target during one uninterrupted swing.
		_draw_sword_sweep()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE,KEY_F7]:
		_back_to_plaza()
