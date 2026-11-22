extends Node3D
const WAYPOINTS := preload("res://scripts/three_d/waypoints.gd")
const WAYPOINT_PANEL := preload("res://scripts/three_d/waypoint_panel.gd")
const WAYPOINT_MESH := preload("res://scripts/three_d/waypoint_mesh.gd")
const WAYPOINT_TOP := "res://assets/props/waypoint_top.png"
const WAYPOINT_TOP_LIT := "res://assets/props/waypoint_top_lit.png"
const WAYPOINT_ART := "res://assets/props/waypoint_plinth.png"
const WAYPOINT_ART_LIT := "res://assets/props/waypoint_plinth_lit.png"   # WP2: same platform, runes glowing
const WAYPOINT_ART_RATIO := 0.51   # ground ratio the plinth art was flattened to (tools/build_waypoint_art.py)
const WAYPOINT_ART_PX := 374.0     # image width in painting pixels (footprint 89% of it, fits the shrine floor rings)
const WAYPOINT_ART_BASIN_U := 0.009 # basin centre this fraction of the image width right of its centre (tools/build_waypoint_art.py)
const WAYPOINT_ART_BASIN_V := 0.054 # basin centre sits this fraction of the image height above its centre (tools/build_waypoint_art.py)
const WAYPOINT_RUNE_M := 1.8       # glowing rune circle fitted to the painted basin
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
var ZONE_PITCH := 52.0              # camera pitch over painted zones (zone JSON "pitch" or pitch_override)
@export var pitch_override := 0.0   # >0: comparison renders (camera-angle study)
@export var ppm_override := 0.0
var zone: Dictionary = {}
var zone_refs: Array = []             # [Environment, sun, floor shape] for rebuilding on travel
var zone_exits: Array = []            # {name, to, arrive, poly (world xz)}
var zone_exit_armed := false          # set once the hero has stepped off every exit (no bounce on arrival)
var zone_traveling := false
var zone_waypoints: Array = []        # {id, name, pos, node} in this zone
var waypoint_net                      # scripts/three_d/waypoints.gd (shared across zones)
var waypoint_pending := ""            # waypoint the player clicked; its window opens on arrival
var waypoint_panel: CanvasLayer
signal waypoint_unlocked(id: String)
var zone_block: Array = []            # blocked polygons (world xz) cut out of the walkable area
var zone_nav_nodes := PackedVector2Array()  # pathfinding: corner points (world xz) just off every obstacle corner
var zone_nav_links: Array = []        # per node: Array of [neighbour index, distance] with a clear straight line
var zone_route := PackedVector2Array() # remaining corners of the current click-to-move route
const NAV_CLEARANCE := 0.45           # metres kept between the hero's path and walls / pillars / water
var xray_enabled := true             # occluded-actor silhouette (hero stays visible behind pillars, trees, railings)
var xray_mat: ShaderMaterial
var zone_tiles: Array = []            # {node, mat, rect (zone px), image, depth, state 0=unloaded 1=loading 2=shown}
signal zone_changed(name: String)
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
		zone_stream(true)
		apply_xray(player)
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
		zone_refs = [settings, sun, shape]
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
	for n in ["ZonePainting", "ZoneShadowCatcher", "ZoneDecor"]:
		var old := get_node_or_null(n)
		if old != null:
			remove_child(old); old.queue_free()
	var zpath := painted_zone if painted_zone.begins_with("res://") else "res://assets/zones/%s.json" % painted_zone
	zone = JSON.parse_string(FileAccess.get_file_as_string(zpath))
	ZONE_PPM = float(zone.get("ppm", ZONE_PPM))     # world scale measured from the painting's own props
	ZONE_PITCH = pitch_override if pitch_override > 0.0 else float(zone.get("pitch", 52.0))   # painted zones use 31 (owner-approved); legacy paintings 52
	if ppm_override > 0.0: ZONE_PPM = ppm_override
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
	# painting: one or more tiles of a large zone canvas, streamed in/out around the camera (tools/build_zone_tiles.py)
	var holder := Node3D.new()
	holder.name = "ZonePainting"
	add_child(holder)
	var tiles: Array = zone.get("tiles", [])
	if tiles.is_empty():
		tiles = [{"image": zone["image"], "depth": zone.get("depth", ""), "rect": [0, 0, size[0], size[1]], "img_rect": [0, 0, size[0], size[1]]}]
	zone_tiles.clear()
	var sp_: float = sin(deg_to_rad(ZONE_PITCH))
	for t in tiles:
		var r: Array = t["rect"]; var ir: Array = t["img_rect"]
		var tile := MeshInstance3D.new()
		tile.name = "ZoneTile_%d_%d" % [int(r[0]), int(r[1])]
		var tm := PlaneMesh.new()
		tm.size = Vector2(float(r[2]) / ZONE_PPM, float(r[3]) / ZONE_PPM / sp_)
		tile.mesh = tm
		tile.position = zone_px_to_world(float(r[0]) + float(r[2]) * 0.5, float(r[1]) + float(r[3]) * 0.5)
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/zone_painting.gdshader")
		mat.set_shader_parameter("use_depth", String(t.get("depth", "")) != "")
		mat.set_shader_parameter("z_per_row", 1.0 / ZONE_PPM / sp_)
		mat.set_shader_parameter("uv_offset", Vector2((float(r[0]) - float(ir[0])) / float(ir[2]), (float(r[1]) - float(ir[1])) / float(ir[3])))
		mat.set_shader_parameter("uv_scale", Vector2(float(r[2]) / float(ir[2]), float(r[3]) / float(ir[3])))
		tile.material_override = mat
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tile.visible = false
		holder.add_child(tile)
		zone_tiles.append({"node": tile, "mat": mat, "rect": Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])),
			"image": "res://assets/zones/" + String(t["image"]),
			"depth": ("res://assets/zones/" + String(t["depth"])) if String(t.get("depth", "")) != "" else "", "state": 0})
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
	zone_block.clear()
	for poly in zone.get("blocked", []):                # ruins, water, columns inside the walkable outline
		var bp := PackedVector2Array()
		for p in poly:
			var wp := zone_px_to_world(float(p[0]), float(p[1]))
			bp.append(Vector2(wp.x, wp.z))
		zone_block.append(bp)
	if waypoint_net == null:
		waypoint_net = WAYPOINTS.new()
	var decor := Node3D.new()
	decor.name = "ZoneDecor"
	add_child(decor)
	zone_exits.clear()
	for ex in zone.get("exits", []):
		var ep := PackedVector2Array()
		var c := Vector3.ZERO
		for p in ex["poly"]:
			var wp := zone_px_to_world(float(p[0]), float(p[1]))
			ep.append(Vector2(wp.x, wp.z)); c += wp
		c /= float(ex["poly"].size())
		zone_exits.append({"name": ex["name"], "to": ex["to"], "arrive": ex["arrive"], "poly": ep})
		_build_portal(decor, ep, c, String(ex["name"]))
	zone_waypoints.clear()
	for wdef in zone.get("waypoints", []):
		var wp_pos := zone_px_to_world(float(wdef["at"][0]), float(wdef["at"][1]))
		var rot := float(wdef.get("rot_deg", 0.0))
		if wdef.has("face"):   # aim the bottom star point at a painted feature (e.g. the stream)
			var fdir := zone_px_to_world(float(wdef["face"][0]), float(wdef["face"][1])) - wp_pos
			rot = rad_to_deg(atan2(fdir.x, fdir.z))
		zone_waypoints.append({"id": wdef["id"], "name": wdef["name"], "pos": wp_pos, "node": _build_waypoint(decor, wp_pos, String(wdef["id"]), float(wdef.get("radius_px", 167.0)), rot)})
	_build_zone_nav()
	zone_exit_armed = false

## Zone-exit portal: blue/gold light curtain standing on the exit, a glow on the ground, rising sparks and the
## destination's name, so the player can always tell an exit to another area apart from the scenery.
func _build_portal(parent: Node3D, poly: PackedVector2Array, centre: Vector3, label: String) -> void:
	var mn := Vector2(INF, INF); var mx := -mn
	for p in poly:
		mn = mn.min(p); mx = mx.max(p)
	var width := clampf(mx.x - mn.x, 1.6, 7.0)
	var root := Node3D.new(); root.name = "Portal_" + label.replace(" ", "")
	# stand the aura on the exit's threshold: the edge facing the walkable area (the side nearest the zone centre)
	var to_mid := -Vector2(centre.x, centre.z).normalized()
	var edge := Vector2(centre.x, centre.z)
	if absf(to_mid.y) >= absf(to_mid.x):
		edge.y = mn.y + 0.4 if to_mid.y < 0.0 else mx.y - 0.4
	else:
		edge.x = mn.x + 0.4 if to_mid.x < 0.0 else mx.x - 0.4
	root.position = Vector3(edge.x, 0.0, edge.y)
	root.add_to_group("zone_portal")
	parent.add_child(root)
	var curtain := MeshInstance3D.new()
	var q := QuadMesh.new(); q.size = Vector2(width, 3.2); curtain.mesh = q
	var cm := ShaderMaterial.new(); cm.shader = load("res://shaders/portal_aura.gdshader"); cm.set_shader_parameter("strength", 1.35)
	curtain.material_override = cm
	curtain.position.y = 1.6
	curtain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(curtain)
	var disc := MeshInstance3D.new()
	var dq := PlaneMesh.new(); dq.size = Vector2(width * 1.25, 1.6); disc.mesh = dq
	var dm := ShaderMaterial.new(); dm.shader = load("res://shaders/waypoint_rune.gdshader"); dm.set_shader_parameter("lit", 0.55)
	disc.material_override = dm
	disc.position.y = 0.03
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(disc)
	var sparks := CPUParticles3D.new()
	sparks.amount = 40; sparks.lifetime = 1.8; sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sparks.emission_box_extents = Vector3(width * 0.45, 0.05, 0.3)
	sparks.direction = Vector3.UP; sparks.spread = 12.0; sparks.gravity = Vector3(0, 0.35, 0)
	sparks.initial_velocity_min = 0.4; sparks.initial_velocity_max = 1.1
	sparks.scale_amount_min = 0.04; sparks.scale_amount_max = 0.09
	var sm := SphereMesh.new(); sm.radius = 0.5; sm.height = 1.0; sm.radial_segments = 6; sm.rings = 3
	var smat := StandardMaterial3D.new(); smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(1.0, 0.85, 0.45); smat.vertex_color_use_as_albedo = true
	smat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.material = smat; sparks.mesh = sm
	var grad := Gradient.new(); grad.set_color(0, Color(1.0, 0.85, 0.45, 1)); grad.set_color(1, Color(0.35, 0.65, 1.0, 0))
	sparks.color_ramp = grad
	root.add_child(sparks)
	var light := OmniLight3D.new(); light.light_color = Color(0.45, 0.7, 1.0); light.light_energy = 1.4; light.omni_range = 4.0
	light.position.y = 1.0; light.shadow_enabled = false
	root.add_child(light)
	var lbl := Label3D.new()
	lbl.text = "▼ " + label
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true; lbl.fixed_size = true; lbl.pixel_size = 0.0011
	lbl.font_size = 26; lbl.outline_size = 8
	lbl.modulate = Color("f2d38a"); lbl.outline_modulate = Color(0.08, 0.06, 0.04, 0.9)
	lbl.position.y = 2.9
	lbl.add_to_group("zone_exit_label")
	root.add_child(lbl)

## Waypoint: rune circle on the ground (grey until unlocked, then blue/gold with a pillar of light) and a label.
func _build_waypoint(parent: Node3D, at: Vector3, id: String, radius_px := 167.0, rot_deg := 0.0) -> Node3D:
	var root := Node3D.new(); root.name = "Waypoint_" + id; root.position = at
	root.add_to_group("zone_waypoint")
	parent.add_child(root)
	var basin_h := 0.03
	# real 3D platform (scripts/three_d/waypoint_mesh.gd): exact eight-fold symmetric, centred on the point
	var radius_m := radius_px / ZONE_PPM
	var plat := WAYPOINT_MESH.build(radius_m, load(WAYPOINT_TOP))
	plat.rotation.y = deg_to_rad(rot_deg)   # +z (bottom) star point turns to (sin, cos) of this angle
	root.add_child(plat)
	basin_h = WAYPOINT_MESH.H_BASIN * radius_m + 0.01
	var disc := MeshInstance3D.new(); disc.name = "Rune"
	var pm := PlaneMesh.new(); pm.size = Vector2(WAYPOINT_RUNE_M, WAYPOINT_RUNE_M); disc.mesh = pm
	var dm := ShaderMaterial.new(); dm.shader = load("res://shaders/waypoint_rune.gdshader")
	disc.material_override = dm; disc.position = Vector3(0, basin_h, 0)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(disc)
	var beam := MeshInstance3D.new(); beam.name = "Beam"
	var q := QuadMesh.new(); q.size = Vector2(1.1, 3.4); beam.mesh = q
	var bm := ShaderMaterial.new(); bm.shader = load("res://shaders/portal_aura.gdshader"); bm.set_shader_parameter("strength", 0.55)
	beam.material_override = bm; beam.position = Vector3(0, 1.7, 0)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(beam)
	var lbl := Label3D.new(); lbl.name = "Label"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true; lbl.fixed_size = true; lbl.pixel_size = 0.001
	lbl.font_size = 24; lbl.outline_size = 8
	lbl.outline_modulate = Color(0.08, 0.06, 0.04, 0.9)
	lbl.position.y = 3.6
	root.add_child(lbl)
	_waypoint_visual(root, waypoint_net != null and waypoint_net.is_unlocked(id))
	return root

func _waypoint_visual(node: Node3D, open: bool) -> void:
	var plat := node.get_node_or_null("Platform") as Node3D
	if plat != null:
		# the top texture carries the runes: dormant = carved stone, discovered = the WP2 glowing version
		WAYPOINT_MESH.set_top(plat, load(WAYPOINT_TOP_LIT if open else WAYPOINT_TOP))
		(node.get_node("Rune") as MeshInstance3D).visible = false
	(node.get_node("Rune") as MeshInstance3D).material_override.set_shader_parameter("lit", 1.0 if open else 0.0)
	(node.get_node("Beam") as MeshInstance3D).visible = open
	# undiscovered waypoints are simply part of the world (dormant stone, no label) until the hero finds them
	var lbl := node.get_node("Label") as Label3D
	lbl.text = "Waypoint"
	lbl.modulate = Color("9fd0ff")
	lbl.visible = open

func waypoint_at(at: Vector3, radius := 1.6) -> Dictionary:
	for w in zone_waypoints:
		if Vector2(at.x - w["pos"].x, at.z - w["pos"].z).length() <= radius:
			return w
	return {}

func _waypoint_tick() -> void:
	if player == null or zone_waypoints.is_empty(): return
	var here := waypoint_at(player.global_position, 1.4)
	if here.is_empty():
		if waypoint_panel != null and is_instance_valid(waypoint_panel) and waypoint_at(player.global_position, 3.0).is_empty():
			waypoint_panel.close()
		return
	if waypoint_net.unlock(here["id"]):
		_waypoint_visual(here["node"], true)
		effects.ring(here["pos"], 1.3, Color("9fd0ff"), 0.8)
		waypoint_unlocked.emit(here["id"])
	if waypoint_pending == here["id"]:
		waypoint_pending = ""
		open_waypoint_panel(here["id"])

func open_waypoint_panel(here_id: String) -> void:
	if waypoint_panel != null and is_instance_valid(waypoint_panel):
		waypoint_panel.queue_free()
	player.stop_moving()
	waypoint_panel = WAYPOINT_PANEL.new(waypoint_net, here_id)
	waypoint_panel.travel_requested.connect(teleport_to_waypoint)
	add_child(waypoint_panel)

## Teleport to an unlocked waypoint in any zone (town included): fade, load that zone if needed, arrive just in front.
func teleport_to_waypoint(id: String) -> void:
	if not waypoint_net.is_unlocked(id) or zone_traveling: return
	var e: Dictionary = waypoint_net.get_entry(id)
	if waypoint_panel != null and is_instance_valid(waypoint_panel): waypoint_panel.close()
	await travel_to(String(e["zone"]), [float(e["at"][0]), float(e["at"][1]) + 150.0])

func zone_world_to_px(at: Vector3) -> Vector2:
	var size: Array = zone["size"]
	return Vector2(at.x * ZONE_PPM + float(size[0]) * 0.5, at.z * ZONE_PPM * sin(deg_to_rad(ZONE_PITCH)) + float(size[1]) * 0.5)

## Tile streaming (D4-style seamless region): tiles near the camera are loaded on a worker thread and shown; tiles far
## away drop their textures. `sync` loads the near ones immediately (zone entry, so the first frame is never blank).
func zone_stream(sync := false) -> void:
	if zone_tiles.is_empty():
		return
	var vs := get_viewport().get_visible_rect().size
	var focus: Vector3 = zone_cam_focus if zone_cam_focus.is_finite() else (player.global_position if player != null else Vector3.ZERO)
	var c := zone_world_to_px(focus)
	var half := Vector2(vs.x / vs.y, 1.0) * (1080.0 / ZONE_SCREEN_PPM) * 0.5 * ZONE_PPM
	half.x = maxf(half.x, 15.0 * ZONE_PPM)                 # minimap sees ~30 m around the hero
	var near := Rect2(c - half * 1.6, half * 3.2)
	var far := Rect2(c - half * 2.6, half * 5.2)
	for t in zone_tiles:
		var r: Rect2 = t["rect"]
		if near.intersects(r):
			if t["state"] == 0:
				if sync:
					_zone_tile_apply(t, load(t["image"]), load(t["depth"]) if t["depth"] != "" else null)
				else:
					ResourceLoader.load_threaded_request(t["image"])
					if t["depth"] != "": ResourceLoader.load_threaded_request(t["depth"])
					t["state"] = 1
			if t["state"] == 1:
				var ok: bool = ResourceLoader.load_threaded_get_status(t["image"]) == ResourceLoader.THREAD_LOAD_LOADED
				if t["depth"] != "": ok = ok and ResourceLoader.load_threaded_get_status(t["depth"]) == ResourceLoader.THREAD_LOAD_LOADED
				if ok or sync:
					_zone_tile_apply(t, ResourceLoader.load_threaded_get(t["image"]),
						ResourceLoader.load_threaded_get(t["depth"]) if t["depth"] != "" else null)
		elif not far.intersects(r) and t["state"] == 2:
			t["mat"].set_shader_parameter("painting", null)
			t["mat"].set_shader_parameter("depthmap", null)
			t["node"].visible = false
			t["state"] = 0

func _zone_tile_apply(t: Dictionary, tex: Texture2D, dep: Texture2D) -> void:
	t["mat"].set_shader_parameter("painting", tex)
	if dep != null: t["mat"].set_shader_parameter("depthmap", dep)
	t["node"].visible = true
	t["state"] = 2

func zone_tiles_shown() -> int:
	var n := 0
	for t in zone_tiles:
		if t["state"] == 2: n += 1
	return n

# ---------- pathfinding (visibility graph over the walk map) ----------
## Clear straight line on walkable ground, keeping NAV_CLEARANCE from edges (sampled every 0.2 m).
func zone_line_clear(a: Vector2, b: Vector2) -> bool:
	var n := int(ceil(a.distance_to(b) / 0.2)) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		if not _walk_xz(p, NAV_CLEARANCE * 0.8): return false
	return true

func _walk_xz(p: Vector2, clearance := 0.0) -> bool:
	if not zone_walkable(Vector3(p.x, 0, p.y)): return false
	if clearance <= 0.0: return true
	for k in 8:
		var o := Vector2.RIGHT.rotated(TAU * float(k) / 8.0) * clearance
		if not zone_walkable(Vector3(p.x + o.x, 0, p.y + o.y)): return false
	return true

func _build_zone_nav() -> void:
	zone_nav_nodes = PackedVector2Array(); zone_nav_links.clear(); zone_route = PackedVector2Array()
	var polys: Array = []
	polys.append_array(zone_walk); polys.append_array(zone_block)
	for poly in polys:
		var m: int = (poly as PackedVector2Array).size()
		for i in m:
			var v: Vector2 = poly[i]
			var e1: Vector2 = (v - poly[(i - 1 + m) % m]).normalized()
			var e2: Vector2 = (poly[(i + 1) % m] - v).normalized()
			var bis := (e1 - e2)
			if bis.length() < 0.01: bis = Vector2(-e1.y, e1.x)
			bis = bis.normalized()
			for sgn in [1.0, -1.0]:        # step off the corner to whichever side is walkable
				var c: Vector2 = v + bis * sgn * (NAV_CLEARANCE * 1.6)
				if _walk_xz(c, NAV_CLEARANCE * 0.8):
					zone_nav_nodes.append(c)
					break
	for i in zone_nav_nodes.size():
		var links: Array = []
		for j in zone_nav_nodes.size():
			if i != j and zone_line_clear(zone_nav_nodes[i], zone_nav_nodes[j]):
				links.append([j, zone_nav_nodes[i].distance_to(zone_nav_nodes[j])])
		zone_nav_links.append(links)

## Shortest walkable route from `from` to `to` (world xz). Returns the corners to walk through, ending at the goal
## (or the nearest walkable point on the way to it when the goal itself is blocked).
func zone_find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if not _walk_xz(to):
		var t := 1.0
		var found := false
		while t > 0.0:
			t -= 0.02
			var q := from.lerp(to, t)
			if _walk_xz(q): to = q; found = true; break
		if not found: return PackedVector2Array()
	if zone_line_clear(from, to) or zone_nav_nodes.is_empty():
		return PackedVector2Array([to])
	var n := zone_nav_nodes.size()
	var S := n; var G := n + 1              # start / goal as extra nodes
	var start_links: Array = []; var goal_links := {}
	for i in n:
		if zone_line_clear(from, zone_nav_nodes[i]): start_links.append([i, from.distance_to(zone_nav_nodes[i])])
		if zone_line_clear(zone_nav_nodes[i], to): goal_links[i] = zone_nav_nodes[i].distance_to(to)
	var dist := {S: 0.0}; var prev := {}; var open := [S]; var done := {}
	while not open.is_empty():
		var best := 0
		var best_f := INF
		for k in open.size():
			var u0: int = open[k]
			var pu: Vector2 = from if u0 == S else (to if u0 == G else zone_nav_nodes[u0])
			var f: float = dist[u0] + pu.distance_to(to)
			if f < best_f: best_f = f; best = k
		var u: int = open[best]; open.remove_at(best)
		if u == G: break
		if done.has(u): continue
		done[u] = true
		var nbrs: Array = start_links if u == S else zone_nav_links[u]
		var extra: Array = []
		if u != S and goal_links.has(u): extra = [[G, goal_links[u]]]
		for e in nbrs + extra:
			var v: int = e[0]; var nd: float = dist[u] + float(e[1])
			if not dist.has(v) or nd < dist[v]:
				dist[v] = nd; prev[v] = u
				if not open.has(v): open.append(v)
	if not prev.has(G):
		return PackedVector2Array()
	var out := PackedVector2Array([to])
	var c: int = prev[G]
	while c != S:
		out.insert(0, zone_nav_nodes[c]); c = prev[c]
	return out

## Click-to-move inside a painted zone: route around obstacles and walk the corners one by one.
func zone_move_to(dest: Vector3) -> void:
	var path := zone_find_path(Vector2(player.global_position.x, player.global_position.z), Vector2(dest.x, dest.z))
	zone_route = path
	if path.is_empty():
		player.stop_moving(); return
	var first := zone_route[0]; zone_route.remove_at(0)
	player.command_move(Vector3(first.x, 0, first.y))

func _zone_route_tick() -> void:
	if zone_route.is_empty() or player == null: return
	if not player.move_target.is_finite():    # reached the current corner: head for the next one
		var nxt := zone_route[0]; zone_route.remove_at(0)
		player.command_move(Vector3(nxt.x, 0, nxt.y))

## Gold silhouette over the hero wherever painted scenery hides him (material_overlay on every mesh of the actor).
func apply_xray(actor: Node3D) -> void:
	if xray_mat == null:
		xray_mat = ShaderMaterial.new()
		xray_mat.shader = load("res://shaders/occluded_actor.gdshader")
	for m in actor.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_overlay = xray_mat if xray_enabled else null

func zone_exit_at(at: Vector3) -> Dictionary:
	for ex in zone_exits:
		if Geometry2D.is_point_in_polygon(Vector2(at.x, at.z), ex["poly"]):
			return ex
	return {}

## Leave through an exit: fade out, swap the painting/walk map/targets, place the hero at `arrive`, fade in.
func travel_to(to: String, arrive: Array) -> void:
	zone_traveling = true
	player.stop_moving()
	var fade_layer := CanvasLayer.new(); fade_layer.layer = 50
	var fade := ColorRect.new(); fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT); fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade); add_child(fade_layer)
	var tw := create_tween(); tw.tween_property(fade, "color:a", 1.0, 0.3)
	await tw.finished
	painted_zone = to
	_build_zone(zone_refs[0], zone_refs[1], zone_refs[2])
	player.global_position = zone_px_to_world(float(arrive[0]), float(arrive[1])) + Vector3.UP * 0.08
	player.velocity = Vector3.ZERO
	zone_last_ok = player.global_position
	zone_cam_focus = Vector3.INF
	zone_stream(true)
	var tps: Array = zone.get("targets", [])
	for i in targets.size():
		if i < tps.size():
			targets[i].global_position = zone_px_to_world(float(tps[i][0]), float(tps[i][1]))
			targets[i].visible = true
		else:
			targets[i].global_position = Vector3(0, -50, 0); targets[i].visible = false
	zone_changed.emit(to)
	var tw2 := create_tween(); tw2.tween_property(fade, "color:a", 0.0, 0.35)
	await tw2.finished
	fade_layer.queue_free()
	zone_traveling = false

func zone_walkable(at: Vector3) -> bool:
	for poly in zone_block:
		if Geometry2D.is_point_in_polygon(Vector2(at.x, at.z), poly):
			return false
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
		zone_stream()
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
		var on_exit := zone_exit_at(player.global_position)
		if on_exit.is_empty():
			zone_exit_armed = true
		elif zone_exit_armed and not zone_traveling:
			travel_to(String(on_exit["to"]), on_exit["arrive"])
		_zone_route_tick()
		_waypoint_tick()
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
		zone_route = PackedVector2Array()
		player.command_attack(enemy)
	elif ground.is_finite():
		var wp := waypoint_at(ground) if not zone.is_empty() else {}
		waypoint_pending = String(wp["id"]) if not wp.is_empty() else ""
		var dest: Vector3 = wp["pos"] if not wp.is_empty() else ground
		if zone.is_empty(): player.command_move(dest)
		else: zone_move_to(dest)
		effects.ring(dest, 0.25, Color("f2d17f"), 0.35)
		if not wp.is_empty() and waypoint_at(player.global_position, 1.4).get("id", "") == waypoint_pending:
			waypoint_pending = ""
			open_waypoint_panel(String(wp["id"]))

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
