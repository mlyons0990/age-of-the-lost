extends Node3D
## Standalone playable 3D art/rig/VFX testbed for the next developer.
## This deliberately does NOT replace the established 2D plaza; keep both.
const HERO := preload("res://scripts/three_d/rig_controller.gd")
const FX := preload("res://scripts/three_d/rig_effects.gd")
const RADIANT_FX := preload("res://scripts/three_d/radiant_vfx.gd")
const ARPG_HUD := preload("res://scripts/three_d/arpg_hud.gd")
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
@export var use_r54_elbow_helper_candidate := false
@export var use_r55_clip_safe_elbow_candidate := false
@export var use_pilot_knight_candidate := false
@export var use_pilot_mage_candidate := false
## Phase 4 groundwork: Hollow Sun radiant FX for the Cast attack (opt-in).
@export var radiant_spell_fx := false
## ARPG HUD after the owner's 2.5D lab mockup (globes, belts, minimap, quests, nameplates). Opt-in.
@export var arpg_hud := false
## Crownsfall plaza dressing (owner plaza reference): limestone flagstones with the compass-rose mosaic, the existing
## Citadel v17 as a backdrop, warm sunlight. Opt-in; replaces the white test floor visuals only (same collision).
@export var crownsfall_plaza := false
## 2D painted zone (owner direction 2026-11-21: "a 2D game with a few 3D elements; each zone is a 2D environment").
## Name of assets/zones/<zone>.json. The painting is laid on the ground and viewed by an orthographic camera at the
## painting's own pitch, so it appears exactly as painted while the 3D heroes walk over it and cast real shadows.
@export var painted_zone := ""
var ZONE_PPM := 93.0                 # painting pixels per ground metre (per zone: zone JSON "ppm")
var ZONE_SCREEN_PPM := 93.0          # screen px per metre at 1080p (derived from HERO_PX_1080)
const HERO_PX_1080 := 110.0          # owner reference: hero ~110 px at 1080p (zones opt in with "hero_px_1080")
const ZONE_PITCH := 52.0
var zone: Dictionary = {}
var zone_walk: Array = []            # walkable polygons in world XZ (PackedVector2Array each)
var zone_last_ok := Vector3.INF
const CITADEL := "res://assets/25d/citadel/AOTL_Citadel_MasonryArt_v17.glb"
var hud: CanvasLayer
var radiant: Node3D
const PILOT_CAMERA_FOV := 32.0
const PILOT_CAMERA_PITCH := 52.0
@export var pilot_camera_distance := 21.0

## Same compass direction as the lab's original camera, pitched 52° down, at a distance that makes
## the 1.75 m knight ~100 px tall on a 1080p screen.
var zone_cam_focus := Vector3.INF

## Orthographic camera at the painting's pitch, following the hero but never showing past the painting's edges.
func _zone_camera(delta: float) -> void:
	var vs := get_viewport().get_visible_rect().size
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1080.0 / ZONE_SCREEN_PPM          # world metres per screen height: hero ~100 px at 1080p
	var size: Array = zone["size"]
	var sp: float = sin(deg_to_rad(ZONE_PITCH))
	var half_w: float = float(size[0]) / ZONE_PPM * 0.5
	var half_d: float = float(size[1]) / ZONE_PPM / sp * 0.5
	var view_w: float = camera.size * vs.x / vs.y * 0.5
	var view_d: float = camera.size / sp * 0.5
	var t: Vector3 = player.global_position
	t.x = clampf(t.x, -half_w + view_w, half_w - view_w)
	t.z = clampf(t.z, -half_d + view_d, half_d - view_d)
	t.y = 0.0
	zone_cam_focus = t if not zone_cam_focus.is_finite() else zone_cam_focus.lerp(t, minf(1.0, delta * 6.0))
	var p := deg_to_rad(ZONE_PITCH)
	camera.global_position = zone_cam_focus + Vector3(0, sin(p), cos(p)) * 60.0
	camera.look_at(zone_cam_focus, Vector3.UP)

func pilot_camera_offset() -> Vector3:
	var flat := Vector2(8.5, 11.0).normalized()
	var p := deg_to_rad(PILOT_CAMERA_PITCH)
	return Vector3(flat.x * cos(p), sin(p), flat.y * cos(p)) * pilot_camera_distance
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
	player.enable_r54_elbow_helper_candidate = use_r54_elbow_helper_candidate
	player.enable_r55_clip_safe_elbow_candidate = use_r55_clip_safe_elbow_candidate
	player.enable_pilot_knight_candidate = use_pilot_knight_candidate
	player.enable_pilot_mage_candidate = use_pilot_mage_candidate
	player.position = Vector3(0, 0.08, 1.8)
	add_child(player)
	player.impact.connect(_on_impact)
	player.health_changed.connect(_on_hp)
	camera = Camera3D.new()
	if use_pilot_knight_candidate or use_pilot_mage_candidate:
		# Owner target (2026-11-20): PoE-style perspective, ~100 px tall knight at 1080p.
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = PILOT_CAMERA_FOV
	else:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 14.0
	camera.current = true
	add_child(camera)
	player.camera = camera
	effects = FX.new()
	add_child(effects)
	if radiant_spell_fx:
		radiant = RADIANT_FX.new()
		radiant.name = "RadiantFX"
		add_child(radiant)
	for i in 4:
		var e := Node3D.new()
		e.set_script(DUMMY)
		e.position = Vector3(-4.2 + i * 2.8, 0.0, -3.6 - (i % 2) * 1.4)
		add_child(e)
		targets.append(e)
	if not zone.is_empty():
		var sp: Array = zone["spawn"]
		player.global_position = zone_px_to_world(float(sp[0]), float(sp[1])) + Vector3.UP * 0.08
		for i in mini(targets.size(), zone["targets"].size()):
			var tp: Array = zone["targets"][i]
			targets[i].global_position = zone_px_to_world(float(tp[0]), float(tp[1]))
	if arpg_hud:
		hud = ARPG_HUD.new()
		hud.name = "ArpgHud"
		add_child(hud)
		hud.setup(self)
	else:
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
	if painted_zone != "":
		_build_zone(settings, sun, shape)
		return
	if crownsfall_plaza:
		_build_plaza(settings, sun)
		return
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

func zone_px_to_world(u: float, v: float) -> Vector3:
	var size: Array = zone["size"]
	return Vector3((u - float(size[0]) * 0.5) / ZONE_PPM, 0.0, (v - float(size[1]) * 0.5) / ZONE_PPM / sin(deg_to_rad(ZONE_PITCH)))

func _build_zone(settings: Environment, sun: DirectionalLight3D, shape: BoxShape3D) -> void:
	zone = JSON.parse_string(FileAccess.get_file_as_string("res://assets/zones/%s.json" % painted_zone))
	ZONE_PPM = float(zone.get("ppm", ZONE_PPM))     # world scale measured from the painting's own props
	# hero size on screen is fixed (owner reference: ~110 px at 1080p); the painting is scaled to match it
	ZONE_SCREEN_PPM = float(zone.get("hero_px_1080", 0.0)) / (1.75 * cos(deg_to_rad(ZONE_PITCH))) if zone.has("hero_px_1080") else ZONE_PPM
	var size: Array = zone["size"]
	var w: float = float(size[0]) / ZONE_PPM
	var d: float = float(size[1]) / ZONE_PPM / sin(deg_to_rad(ZONE_PITCH))
	shape.size = Vector3(w, 0.4, d)
	settings.background_color = Color("1a1714")
	settings.ambient_light_color = Color("e8e0d2")
	settings.ambient_light_energy = 0.6
	sun.light_energy = 1.0
	sun.light_color = Color("fff3e0")
	sun.shadow_opacity = 0.55
	sun.look_at_from_position(Vector3.ZERO, Vector3(0.45, -0.78, 0.45))   # painted light: upper-left/back
	var plane := MeshInstance3D.new()
	plane.name = "ZonePainting"
	var pm := PlaneMesh.new(); pm.size = Vector2(w, d); plane.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = load("res://assets/zones/" + String(zone["image"]))
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	plane.material_override = mat
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(plane)
	var catcher := MeshInstance3D.new()             # receives the heroes' real shadows on the painting
	catcher.name = "ZoneShadowCatcher"
	var cm := PlaneMesh.new(); cm.size = Vector2(w, d); catcher.mesh = cm
	var sm := StandardMaterial3D.new()
	sm.shadow_to_opacity = true
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(0.05, 0.04, 0.06, 1.0)
	catcher.material_override = sm
	catcher.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	catcher.position.y = 0.01
	add_child(catcher)
	zone_walk.clear()
	for poly in zone["walkable"]:
		var pts := PackedVector2Array()
		for p in poly:
			var wp := zone_px_to_world(float(p[0]), float(p[1]))
			pts.append(Vector2(wp.x, wp.z))
		zone_walk.append(pts)

func zone_walkable(at: Vector3) -> bool:
	for poly in zone_walk:
		if Geometry2D.is_point_in_polygon(Vector2(at.x, at.z), poly):
			return true
	return zone_walk.is_empty()

func _build_plaza(settings: Environment, sun: DirectionalLight3D) -> void:
	settings.background_color = Color("8fa9c6")
	settings.ambient_light_color = Color("c9d0dc")
	settings.ambient_light_energy = 0.38
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	settings.tonemap_exposure = 0.78
	sun.light_energy = 0.85
	sun.light_color = Color("fff7ec")
	sun.rotation_degrees = Vector3(-52, -38, 0)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "PlazaFloor"
	var pm := PlaneMesh.new()
	pm.size = Vector2(28, 28)
	floor_mesh.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/env/plaza_floor.png")
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/env/plaza_floor_normal.png")
	mat.normal_scale = 0.6
	mat.roughness = 0.85
	floor_mesh.material_override = mat
	floor_mesh.position = Vector3(0, -0.0, 0)
	add_child(floor_mesh)
	# outer apron so the plaza does not end in the void at the camera's edge
	var apron := MeshInstance3D.new()
	var ap := PlaneMesh.new(); ap.size = Vector2(120, 120); apron.mesh = ap
	var am := StandardMaterial3D.new(); am.albedo_color = Color("b9ad93"); am.roughness = 0.95
	apron.material_override = am; apron.position = Vector3(0, -0.03, 0)
	add_child(apron)
	if ResourceLoader.exists(CITADEL):
		var cit: Node3D = (load(CITADEL) as PackedScene).instantiate()
		cit.name = "CitadelBackdrop"
		cit.rotation.y = PI                       # stairs face the plaza (south)
		cit.position = Vector3(0, -0.02, -7.5)
		add_child(cit)

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
	if player.click_to_move:
		var mouse := get_viewport().get_mouse_position()
		player.aim_point = cursor_ground(mouse)
		# hold LMB on the ground to keep walking toward the cursor
		var holding_move: bool = hud.kb.held("move") if hud != null else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		var standing: bool = hud.kb.held("force_stand") if hud != null else Input.is_key_pressed(KEY_SHIFT)
		var over_ui: bool = hud != null and hud.pointer_over_ui()
		if holding_move and not standing and not over_ui and player.attack_target == null and player.aim_point.is_finite():
			player.command_move(player.aim_point)
	if not zone.is_empty():
		_zone_camera(delta)
	else:
		var goal: Vector3 = player.global_position + (pilot_camera_offset() if (use_pilot_knight_candidate or use_pilot_mage_candidate) else Vector3(8.5, 11.0, 11.0))
		camera.global_position = camera.global_position.lerp(goal, minf(1.0, delta * 6.0))
		camera.look_at(player.global_position + Vector3.UP * 1.25, Vector3.UP)
	if info == null: return
	info.text = "Targets: %d  ·  Model: %s  ·  IK: %s  ·  Equipment sockets: %s  ·  Sweep: %s  ·  Reach releases: %d" % [kills, player.active_model_source, ("ON" if player.terrain_ik_available and player.terrain_ik_enabled else ("OFF" if player.terrain_ik_available else "unsupported")), ("preview" if player.equipment_debug_equipped else ("ready" if player.equipment_sockets_available else "unsupported")), ("STRICT" if strict_weapon_sweep else "baseline"), player.terrain_foot_ik.contact_releases if player.terrain_ik_available else 0]

func _physics_process(_delta: float) -> void:
	if not zone.is_empty() and player != null:
		if zone_walkable(player.global_position):
			zone_last_ok = player.global_position
		elif zone_last_ok.is_finite():
			player.global_position = Vector3(zone_last_ok.x, player.global_position.y, zone_last_ok.z)
			player.velocity.x = 0.0; player.velocity.z = 0.0
			player.stop_moving()
	_physics_body()

func _physics_body() -> void:
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
	var sample: Dictionary = player.blade_segment()
	if sample.is_empty():
		var socket: BoneAttachment3D = player.equipment_sockets.get_socket("weapon")
		sample = WEAPON_SWEEP.blade_from_socket(socket)
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
	if hpbar == null: return
	hpbar.max_value = maximum
	hpbar.value = current

func _on_impact(at: Vector3, kind: String, direction: Vector3) -> void:
	var spell := kind == "Cast"
	var color := Color("b0a0ff") if spell else (Color("ffe5a4") if kind == "Cleave" else Color("8acaff"))
	var wide := kind == "Cleave"
	if spell and radiant:
		radiant.spell(player.spell_variant, player.global_position, direction, player.global_position.distance_to(at))
	elif spell:
		effects.cast(at, color)
	else:
		effects.slash(player.global_position, direction, color, wide)
		if kind == "Dash": effects.ring(at, 0.8, Color("f2d17f"), 0.45)
	# One physics-backed damage decision per candidate; the VFX remains
	# responsive even when a nearby target is safely screened by cover.
	for target in targets:
		if target.inactive_t > 0: continue
		var allowed := TARGETING.can_hit(get_world_3d(), player, player.global_position, direction, target.global_position, kind)
		# ranged Mage spells (Bolt, Lance) reach as far as their projectile, in a narrow cone
		if spell and player.spell_variant in ["Bolt", "Lance"]:
			var reach: float = float(player.MAGE_SPELLS[player.spell_variant]["reach"]) + 0.6
			allowed = TARGETING.within_attack_arc(player.global_position, direction, target.global_position, reach, 0.7) \
				and TARGETING.world_line_of_sight(get_world_3d(), player.global_position, target.global_position, player.get_rid())
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

## --- click-to-move (ARPG HUD labs) ---
func cursor_ground(screen: Vector2) -> Vector3:
	if camera == null or player == null:
		return Vector3.INF
	var o := camera.project_ray_origin(screen)
	var d := camera.project_ray_normal(screen)
	if absf(d.y) < 1e-4:
		return Vector3.INF
	var t: float = (player.global_position.y - o.y) / d.y
	return o + d * t if t > 0.0 else Vector3.INF

## The live enemy under the cursor: its body on screen, or its footprint on the ground.
func enemy_under(screen: Vector2) -> Node3D:
	var ground := cursor_ground(screen)
	var best: Node3D = null
	var best_d := INF
	var px := 46.0 * get_viewport().get_visible_rect().size.y / 1080.0
	for t in targets:
		if t.inactive_t > 0.0:
			continue
		var sp := camera.unproject_position(t.global_position + Vector3.UP * 1.0)
		var d := sp.distance_to(screen)
		if ground.is_finite():
			var g := Vector2(ground.x - t.global_position.x, ground.z - t.global_position.z).length()
			if g < 0.8: d = minf(d, g * px)
		if d < px and d < best_d:
			best_d = d
			best = t
	return best

func handle_click(screen: Vector2, force_stand := false, combine_move_attack := true) -> void:
	var ground := cursor_ground(screen)
	player.aim_point = ground
	var enemy := enemy_under(screen) if (combine_move_attack or force_stand) else null
	if force_stand:
		player.stop_moving()
		if enemy != null: player.attack_target = enemy
		player.primary_attack()
		player.attack_target = null
	elif enemy != null:
		player.command_attack(enemy)
	elif ground.is_finite():
		player.command_move(ground)
		effects.ring(ground, 0.25, Color("f2d17f"), 0.35)

func _unhandled_input(event: InputEvent) -> void:
	if hud == null and player != null and player.click_to_move and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_click(event.position, Input.is_key_pressed(KEY_SHIFT))
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		strict_weapon_sweep = not strict_weapon_sweep
		contact_samples.clear()
		# Do not reset the per-swing hit ledger on mode change: that could
		# apply damage twice to a target during one uninterrupted swing.
		_draw_sword_sweep()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE,KEY_F7]:
		_back_to_plaza()
