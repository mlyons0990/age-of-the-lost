extends Node3D
## A monster in the 3D world (owner 11-26 playable build): the painted enemy art of the original game (Hollowling,
## Veilbound Revenant, Thornhide Brute) standing upright in the scene, animated in code (bob, lean, lunge, hit flash,
## death fade). Idles at its spawn, aggroes when the hero comes close (or when hit, and its whole pack with it),
## chases along the zone's navigation grid, winds up a telegraphed attack (red ground marker) and strikes if the hero
## is still inside it. Bosses add a delayed slam and summon adds at half life. Leashes back home if dragged too far.
## Same target interface as the training dummies (hit / inactive_t / damage_center / damage_radius), so every
## player attack, targeting rule and HUD bar works unchanged.
const GD := preload("res://scripts/game_data.gd")
const HURTBOX := preload("res://scripts/three_d/hurtbox3d.gd")
const TEX := {"slime": preload("res://assets/enemies/slime.png"), "revenant": preload("res://assets/enemies/revenant.png"), "brute": preload("res://assets/enemies/brute.png")}
## Painted poses (assets/enemies/poses, tools/cut_enemy_poses.py): idle, walk, windup, strike, hit, death, all at one
## scale per enemy (idle = IDLE_POSE_PX tall). An enemy without poses keeps its single painting.
const POSE_DIR := "res://assets/enemies/poses/"
const POSE_NAMES := ["idle", "walk", "windup", "strike", "hit", "death"]
const IDLE_POSE_PX := 512.0
static var _pose_cache := {}
var poses := {}
var pose := ""
var hit_pose_t := 0.0
var velocity_hint := 0.0         # ground speed this physics frame (m/s), for the walk cycle
## Chapter II (Hollowmere, levels 5-9) and later enemy types, kept here so the original 2D game's table stays as it
## was. "art" names the painting (and poses) a type uses until it has its own; "tint" colours that stand-in art.
## "adds" is what a boss summons at half life.
const MORE_TYPES := {
	"bog_ghoul": {"name": "Bog Ghoul", "hp": 58.0, "dmg": 12.0, "speed": 2.3, "range": 1.3, "atk_cd": 1.8, "wind": 0.55, "rad": 0.42, "xp": 1.3,
		"art": "revenant", "tint": Color(0.62, 0.86, 0.66), "height": 1.95, "speed_m": 3.0},
	"mire_lurker": {"name": "Mire Lurker", "hp": 120.0, "dmg": 19.0, "speed": 1.6, "range": 1.7, "atk_cd": 2.4, "wind": 0.75, "rad": 0.65, "xp": 2.3,
		"art": "brute", "tint": Color(0.55, 0.76, 0.82), "height": 2.6, "speed_m": 2.5},
	"mire_wisp": {"name": "Mirelight Wisp", "hp": 24.0, "dmg": 8.0, "speed": 2.6, "range": 1.0, "atk_cd": 1.1, "wind": 0.35, "rad": 0.32, "xp": 0.9,
		"art": "slime", "tint": Color(0.74, 1.0, 0.82), "height": 1.0, "speed_m": 3.8},
	"drowned_matron": {"name": "The Drowned Matron", "hp": 150.0, "dmg": 22.0, "speed": 2.2, "range": 1.6, "atk_cd": 2.0, "wind": 0.6, "rad": 0.5, "xp": 3.0,
		"art": "revenant", "tint": Color(0.6, 0.82, 0.98), "height": 2.15, "speed_m": 3.2, "adds": "mire_wisp"},
	# Greyfen Causeway (levels 9-12): the Tollkeeper's brigands on the salt heath
	"salt_brigand": {"name": "Salt Brigand", "hp": 64.0, "dmg": 13.0, "speed": 2.5, "range": 1.3, "atk_cd": 1.6, "wind": 0.5, "rad": 0.42, "xp": 1.4,
		"art": "revenant", "tint": Color(1.0, 0.86, 0.7), "height": 1.9, "speed_m": 3.4},
	"causeway_brute": {"name": "Causeway Brute", "hp": 130.0, "dmg": 20.0, "speed": 1.6, "range": 1.7, "atk_cd": 2.4, "wind": 0.75, "rad": 0.65, "xp": 2.4,
		"art": "brute", "tint": Color(0.95, 0.82, 0.62), "height": 2.5, "speed_m": 2.6},
	"brine_slime": {"name": "Brine Slime", "hp": 30.0, "dmg": 9.0, "speed": 2.4, "range": 1.0, "atk_cd": 1.2, "wind": 0.4, "rad": 0.36, "xp": 1.0,
		"art": "slime", "tint": Color(1.0, 1.0, 0.92), "height": 1.1, "speed_m": 3.2},
	"tollkeeper": {"name": "The Tollkeeper", "hp": 165.0, "dmg": 24.0, "speed": 1.8, "range": 1.8, "atk_cd": 2.2, "wind": 0.7, "rad": 0.7, "xp": 3.2,
		"art": "brute", "tint": Color(1.0, 0.78, 0.42), "height": 2.8, "speed_m": 2.8, "adds": "salt_brigand"},
	# Wreckers' Strand (levels 12-15): the drowned crews and what lives in the wrecks
	"drowned_sailor": {"name": "Drowned Sailor", "hp": 70.0, "dmg": 14.0, "speed": 2.4, "range": 1.3, "atk_cd": 1.7, "wind": 0.5, "rad": 0.42, "xp": 1.5,
		"art": "revenant", "tint": Color(0.66, 0.8, 0.92), "height": 1.95, "speed_m": 3.3},
	"tide_crawler": {"name": "Tide Crawler", "hp": 34.0, "dmg": 10.0, "speed": 2.6, "range": 1.0, "atk_cd": 1.1, "wind": 0.35, "rad": 0.36, "xp": 1.0,
		"art": "slime", "tint": Color(1.0, 0.7, 0.62), "height": 1.05, "speed_m": 3.6},
	"wreck_hulk": {"name": "Wreck Hulk", "hp": 140.0, "dmg": 21.0, "speed": 1.6, "range": 1.7, "atk_cd": 2.4, "wind": 0.75, "rad": 0.65, "xp": 2.5,
		"art": "brute", "tint": Color(0.62, 0.84, 0.72), "height": 2.6, "speed_m": 2.5},
	"tidewrought_warden": {"name": "The Tidewrought Warden", "hp": 185.0, "dmg": 26.0, "speed": 2.2, "range": 1.7, "atk_cd": 2.0, "wind": 0.6, "rad": 0.55, "xp": 3.6,
		"art": "revenant", "tint": Color(0.5, 0.92, 0.88), "height": 2.4, "speed_m": 3.3, "adds": "tide_crawler"},
	# Lorecast echoes: figures of the Gilded Epoch, woken at their remains
	"exalted_echo": {"name": "Echo of the Exalted", "hp": 120.0, "dmg": 16.0, "speed": 2.2, "range": 1.6, "atk_cd": 1.8, "wind": 0.55, "rad": 0.5, "xp": 3.0,
		"art": "revenant", "tint": Color(1.0, 0.92, 0.6), "height": 2.25, "speed_m": 3.2},
	# Mossbarrow Crypts (levels 3-4)
	"barrow_shade": {"name": "Barrow Shade", "hp": 40.0, "dmg": 9.0, "speed": 2.4, "range": 1.2, "atk_cd": 1.6, "wind": 0.5, "rad": 0.4, "xp": 1.1,
		"art": "revenant", "tint": Color(0.72, 0.74, 0.86), "height": 1.9, "speed_m": 3.3},
	"crypt_ooze": {"name": "Crypt Ooze", "hp": 22.0, "dmg": 6.0, "speed": 2.4, "range": 1.0, "atk_cd": 1.2, "wind": 0.4, "rad": 0.34, "xp": 0.8,
		"art": "slime", "tint": Color(0.78, 0.86, 0.7), "height": 1.0, "speed_m": 3.2},
	"barrow_lord": {"name": "Barrow-Lord Ostric", "hp": 140.0, "dmg": 17.0, "speed": 1.9, "range": 1.7, "atk_cd": 2.1, "wind": 0.65, "rad": 0.6, "xp": 3.0,
		"art": "brute", "tint": Color(0.7, 0.72, 0.9), "height": 2.7, "speed_m": 2.7, "adds": "barrow_shade"},
	"tomb_warden": {"name": "Tomb Warden", "hp": 95.0, "dmg": 15.0, "speed": 1.6, "range": 1.7, "atk_cd": 2.4, "wind": 0.75, "rad": 0.62, "xp": 2.0,
		"art": "brute", "tint": Color(0.78, 0.78, 0.82), "height": 2.4, "speed_m": 2.5},
}

## A monster type's stats: the original table, or MORE_TYPES.
static func type_def(key: String) -> Dictionary:
	return GD.ETYPES[key] if GD.ETYPES.has(key) else MORE_TYPES[key]

## The painting a type is drawn with (its own key once its art exists).
static func art_key(key: String) -> String:
	return key if TEX.has(key) else String(MORE_TYPES[key].get("art", "slime"))

var type_tint := Color.WHITE
const HEIGHT_M := {"slime": 1.15, "revenant": 2.05, "brute": 2.45}
const SPEED_M := {"slime": 3.2, "revenant": 3.6, "brute": 2.7}
const AGGRO_M := 9.0
const LEASH_M := 26.0

signal died(m: Node3D)

var director
var type_key := "slime"
var level := 1
var elite := false
var boss := false
var unique_id := ""              # quest guardians / bosses: stays dead once killed
var drops_page := ""             # quest item this monster carries
var ename := ""
var max_hp := 30.0
var hp := 30.0
var dmg := 7.0
var reach := 1.4
var atk_cd_base := 1.4
var wind_time := 0.45
var speed := 3.0
var xp_value := 10
var pack: Array = []             # siblings (aggro together)
var home := Vector3.ZERO
var inactive_t := 0.0            # >0: dead (targeting / HUD ignore it)
var bar_h := 2.6
var state := "idle"              # idle, chase, wind, recover, leash, dead
var t := 0.0
var atk_cd := 0.0
var wind_left := 0.0
var wind_kind := "strike"
var wind_at := Vector3.ZERO
var path := PackedVector2Array()
var path_t := 0.0
var flash := 0.0
var lunge := 0.0
var dead_t := 0.0
var summoned := false
var slam_cd := 4.0
var phase := 0.0
var sprite: Sprite3D
var shadow: MeshInstance3D
var tele: MeshInstance3D
var tele_mat: StandardMaterial3D
var hurtbox: Area3D
var height_m := 1.2
var slow_t := 0.0
var slow_mult := 0.0
var stun_t := 0.0
var burn_left := 0.0             # total burn damage still to deal
var burn_t := 0.0
var burn_tick := 0.0
var knock := Vector3.ZERO

func setup(key: String, lvl: int, is_elite := false, is_boss := false) -> void:
	type_key = key
	level = maxi(1, lvl)
	elite = is_elite or is_boss
	boss = is_boss
	var e: Dictionary = type_def(key)
	type_tint = e.get("tint", Color.WHITE) if not TEX.has(key) else Color.WHITE
	var sc: float = pow(1.0 + 0.3 * (level - 1), 1.35)
	max_hp = round(float(e["hp"]) * sc * (8.0 if boss else (2.8 if elite else 1.0)))
	hp = max_hp
	dmg = float(e["dmg"]) * (1.0 + 0.24 * (level - 1)) * (1.9 if boss else (1.5 if elite else 0.75))
	atk_cd_base = float(e["atk_cd"])
	wind_time = float(e["wind"]) * (1.25 if boss else 1.0)
	reach = 1.0 + float(e["range"]) * 0.45 + (0.6 if boss else 0.0)
	speed = float(e.get("speed_m", SPEED_M.get(key, 3.0))) * (0.85 if boss else 1.0)
	xp_value = int(round(float(e["xp"]) * 12.0 * (1.0 + 0.25 * (level - 1)) * (25.0 if boss else (3.0 if elite else 1.0))))
	ename = String(e["name"])
	if elite and not boss: ename = "%s %s" % [GD.ELITE_PREFIX[randi() % GD.ELITE_PREFIX.size()], ename]
	height_m = float(e.get("height", HEIGHT_M.get(key, 1.5))) * (1.7 if boss else (1.18 if elite else 1.0))
	bar_h = height_m + 0.45
	phase = randf() * 6.0
	atk_cd = randf_range(0.2, 0.8)

func _ready() -> void:
	home = global_position
	hurtbox = HURTBOX.new()
	hurtbox.local_center_height_m = height_m * 0.5
	hurtbox.collision_radius_m = 0.35 + height_m * 0.12
	add_child(hurtbox)
	# contact shadow
	shadow = MeshInstance3D.new()
	var sm := PlaneMesh.new(); sm.size = Vector2(height_m * 0.75, height_m * 0.42)
	shadow.mesh = sm
	var smat := ShaderMaterial.new(); smat.shader = _blob_shader()
	shadow.material_override = smat
	shadow.position.y = 0.025
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	sprite = Sprite3D.new()
	var ak := art_key(type_key)
	poses = _load_poses(ak)
	sprite.texture = TEX[ak]
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	sprite.pixel_size = height_m / float(TEX[ak].get_height())
	sprite.centered = true
	sprite.offset = Vector2(0, TEX[ak].get_height() * 0.5)
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not poses.is_empty():
		sprite.pixel_size = height_m / IDLE_POSE_PX
		_set_pose("idle")
	if boss: sprite.modulate = Color(1.0, 0.86, 0.92) * type_tint
	elif elite: sprite.modulate = Color(1.0, 0.95, 0.85) * type_tint
	else: sprite.modulate = type_tint
	add_child(sprite)
	# telegraph (red ground marker during wind-ups)
	tele = MeshInstance3D.new()
	var tm := PlaneMesh.new(); tm.size = Vector2(1, 1)
	tele.mesh = tm
	tele_mat = StandardMaterial3D.new()
	tele_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tele_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tele_mat.albedo_texture = _ring_texture()
	tele_mat.albedo_color = Color(1, 0.25, 0.15, 0.0)
	tele_mat.no_depth_test = false
	tele_mat.render_priority = 2
	tele.material_override = tele_mat
	tele.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tele.visible = false
	add_child(tele)
	tele.top_level = true

static var _blob: Shader
static func _blob_shader() -> Shader:
	if _blob == null:
		_blob = Shader.new()
		_blob.code = "shader_type spatial;\nrender_mode unshaded, blend_mix, depth_draw_never, cull_disabled;\nvoid fragment(){ float d = length(UV - 0.5) * 2.0; ALBEDO = vec3(0.0); ALPHA = 0.42 * (1.0 - smoothstep(0.35, 1.0, d)); }"
	return _blob

static var _ring: ImageTexture
static func _ring_texture() -> ImageTexture:
	if _ring == null:
		var n := 128
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var d := Vector2(x - n * 0.5 + 0.5, y - n * 0.5 + 0.5).length() / (n * 0.5)
				var a := 0.0
				if d <= 1.0: a = 0.28 + 0.72 * smoothstep(0.82, 0.97, d) * (1.0 - smoothstep(0.97, 1.0, d))
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_ring = ImageTexture.create_from_image(img)
	return _ring

static func _load_poses(key: String) -> Dictionary:
	if _pose_cache.has(key): return _pose_cache[key]
	var out := {}
	for p in POSE_NAMES:
		var path := POSE_DIR + "%s_%s.png" % [key, p]
		if not ResourceLoader.exists(path): out = {}; break
		out[p] = load(path)
	_pose_cache[key] = out
	return out

## Show one painted pose, bottom-centred on the monster's feet.
func _set_pose(p: String) -> void:
	if poses.is_empty() or p == pose: return
	pose = p
	var tex: Texture2D = poses[p]
	sprite.texture = tex
	sprite.offset = Vector2(0, tex.get_height() * 0.5)

## Which pose the monster's state calls for (the code motion - bob, lean, lunge, flashes - plays on top).
func _pick_pose() -> String:
	if state == "dead": return "death"
	if hit_pose_t > 0.0 or stun_t > 0.0: return "hit"
	if state == "wind": return "windup"
	if state == "recover" and lunge > 0.25: return "strike"
	if state in ["chase", "leash"] and velocity_hint > 0.2:
		return "walk" if int(t * 3.2 + phase) % 2 == 0 else "idle"   # two-step walk cycle
	return "idle"

func damage_center() -> Vector3:
	return global_position + Vector3.UP * height_m * 0.5

func damage_radius() -> float:
	return 0.35 + height_m * 0.12

func is_alive() -> bool:
	return inactive_t <= 0.0 and state != "dead"

## Player damage. Returns true on the killing blow.
func hit(amount: float) -> bool:
	if not is_alive(): return false
	hp = maxf(0.0, hp - amount)
	flash = 0.16
	hit_pose_t = 0.22
	if director != null: director.show_damage(damage_center() + Vector3.UP * height_m * 0.35, amount, elite)
	if state in ["idle", "leash"]: aggro()
	if hp <= 0.0:
		_die()
		return true
	return false

## Status effects from hero skills: slow (fraction, seconds), stun (seconds, cancels a wind-up; bosses resist half),
## burn (total damage over 3 s, refreshes), knockback (metres, bosses immune).
func apply_status(slow: float, slow_s: float, stun: float, burn_total: float, push: Vector3) -> void:
	if not is_alive(): return
	if slow > 0.0 and slow_s > 0.0:
		slow_mult = maxf(slow_mult if slow_t > 0.0 else 0.0, slow); slow_t = maxf(slow_t, slow_s)
	if stun > 0.0:
		stun_t = maxf(stun_t, stun * (0.5 if boss else 1.0))
		if state == "wind": state = "chase"; tele.visible = false; atk_cd = maxf(atk_cd, 0.4)
	if burn_total > 0.0:
		burn_left = maxf(burn_left, burn_total); burn_t = 3.0
	if not boss and push.length() > 0.01: knock = push * (0.5 if elite else 1.0)
	if state == "idle": aggro()

func _statuses(delta: float) -> bool:
	if slow_t > 0.0:
		slow_t -= delta
		if slow_t <= 0.0: slow_mult = 0.0
	if burn_left > 0.0 and burn_t > 0.0:
		burn_tick -= delta
		if burn_tick <= 0.0:
			burn_tick = 0.5
			var tick := burn_left / maxf(1.0, burn_t / 0.5)
			burn_left -= tick; burn_t -= 0.5
			hp = maxf(0.0, hp - tick)
			if director != null: director.show_damage(damage_center() + Vector3.UP * height_m * 0.3, tick, false, false, Color("ff9a4a"))
			if hp <= 0.0:
				_die(); return true
	if knock.length() > 0.01:
		var step := knock * minf(1.0, delta * 8.0)
		var nxt := global_position + step
		if director.walkable(nxt): global_position = nxt
		knock -= step
		if knock.length() < 0.02: knock = Vector3.ZERO
	if stun_t > 0.0:
		stun_t -= delta
		return true
	return false

func aggro() -> void:
	if state in ["idle", "leash"]:
		state = "chase"
	for m in pack:
		if is_instance_valid(m) and m != self and m.state == "idle": m.state = "chase"

func _die() -> void:
	state = "dead"
	inactive_t = 9999.0
	tele.visible = false
	dead_t = 0.0
	hurtbox.monitorable = false
	died.emit(self)

func _process(delta: float) -> void:
	t += delta
	if state == "dead":
		dead_t += delta
		if poses.is_empty():
			sprite.modulate.a = clampf(1.0 - dead_t / 0.9, 0.0, 1.0)
			sprite.position.y = -dead_t * 0.35
			shadow.visible = dead_t < 0.6
			if dead_t > 1.0: queue_free()
		else:
			# the death pose holds, then sinks and fades
			_set_pose("death")
			sprite.modulate = Color(type_tint.r, type_tint.g, type_tint.b, clampf(1.0 - (dead_t - 0.8) / 0.7, 0.0, 1.0))
			sprite.position.y = -maxf(0.0, dead_t - 0.8) * 0.3
			shadow.visible = dead_t < 1.0
			if dead_t > 1.5: queue_free()
		return
	hit_pose_t = maxf(0.0, hit_pose_t - delta)
	_set_pose(_pick_pose())
	flash = maxf(0.0, flash - delta)
	lunge = maxf(0.0, lunge - delta * 3.5)
	var base_col := (Color(1.0, 0.86, 0.92) if boss else (Color(1.0, 0.95, 0.85) if elite else Color.WHITE)) * type_tint
	sprite.modulate = base_col.lerp(Color(2.2, 1.6, 1.4), flash / 0.16) if flash > 0.0 else base_col
	if state == "wind": sprite.modulate = sprite.modulate.lerp(Color(1.5, 0.7, 0.6), 0.35 + 0.25 * sin(t * 30.0))
	if stun_t > 0.0: sprite.modulate = sprite.modulate.lerp(Color(0.75, 0.9, 1.6), 0.5)
	elif slow_t > 0.0: sprite.modulate = sprite.modulate.lerp(Color(0.7, 0.85, 1.25), 0.35)
	elif burn_left > 0.0: sprite.modulate = sprite.modulate.lerp(Color(1.5, 0.85, 0.55), 0.25 + 0.1 * sin(t * 12.0))
	var bob := sin(t * (5.0 if state == "chase" else 2.0) + phase) * (0.05 if state == "chase" else 0.025) * height_m
	sprite.position = Vector3(0, bob, 0)
	sprite.rotation.z = 0.0
	if state == "wind": sprite.position.y -= 0.04 * height_m
	sprite.scale = Vector3.ONE * (1.0 + lunge * 0.08)

func _physics_process(delta: float) -> void:
	if state == "dead" or director == null: return
	velocity_hint = 0.0
	var hero: Node3D = director.hero()
	if hero == null: return
	var to_hero := Vector3(hero.global_position.x - global_position.x, 0, hero.global_position.z - global_position.z)
	var dist := to_hero.length()
	atk_cd = maxf(0.0, atk_cd - delta)
	slam_cd = maxf(0.0, slam_cd - delta)
	var hero_alive: bool = director.hero_alive()
	if _statuses(delta): return
	match state:
		"idle":
			if hero_alive and dist < AGGRO_M * (1.4 if boss else 1.0) and director.can_see(global_position, hero.global_position):
				aggro()
		"leash":
			_move_toward(home, delta, 1.4)
			hp = minf(max_hp, hp + max_hp * 0.25 * delta)
			if Vector2(global_position.x - home.x, global_position.z - home.z).length() < 0.6:
				state = "idle"; hp = max_hp
		"chase":
			if not hero_alive or Vector2(global_position.x - home.x, global_position.z - home.z).length() > LEASH_M:
				state = "leash"; path = PackedVector2Array(); return
			_face(to_hero)
			if boss and slam_cd <= 0.0 and dist < 9.0:
				_begin_wind("slam", hero.global_position); return
			if dist <= reach and atk_cd <= 0.0:
				_begin_wind("strike", hero.global_position); return
			if dist > reach * 0.8:
				_chase(hero.global_position, delta)
			if boss and not summoned and hp < max_hp * 0.5:
				summoned = true
				director.summon_adds(self, 4)
		"wind":
			wind_left -= delta
			_update_tele()
			if wind_left <= 0.0:
				_strike(hero)
		"recover":
			wind_left -= delta
			if wind_left <= 0.0: state = "chase"

func _begin_wind(kind: String, at: Vector3) -> void:
	state = "wind"
	wind_kind = kind
	wind_left = wind_time * (1.8 if kind == "slam" else 1.0)
	wind_at = at if kind == "slam" else global_position
	tele.visible = true
	_update_tele()

func _update_tele() -> void:
	var r := 3.0 if wind_kind == "slam" else reach + 0.25
	var centre := wind_at if wind_kind == "slam" else global_position
	tele.global_position = Vector3(centre.x, centre.y + 0.05, centre.z)
	tele.scale = Vector3(r * 2.0, 1, r * 2.0)
	var total := wind_time * (1.8 if wind_kind == "slam" else 1.0)
	var k := 1.0 - clampf(wind_left / maxf(total, 0.01), 0.0, 1.0)
	tele_mat.albedo_color = Color(1, 0.22, 0.12, 0.25 + 0.55 * k)

func _strike(hero: Node3D) -> void:
	tele.visible = false
	lunge = 1.0
	var centre := wind_at if wind_kind == "slam" else global_position
	var r := 3.0 if wind_kind == "slam" else reach + 0.25
	var d := Vector2(hero.global_position.x - centre.x, hero.global_position.z - centre.z).length()
	if d <= r + 0.3:
		director.damage_hero(dmg * (1.6 if wind_kind == "slam" else 1.0), self)
	director.strike_fx(centre, r, wind_kind == "slam")
	if wind_kind == "slam": slam_cd = 6.0
	atk_cd = atk_cd_base
	state = "recover"
	wind_left = 0.35

func _face(dir: Vector3) -> void:
	if absf(dir.x) > 0.05: sprite.flip_h = dir.x < 0.0

func _chase(target: Vector3, delta: float) -> void:
	path_t -= delta
	var me := Vector2(global_position.x, global_position.z)
	var goal := Vector2(target.x, target.z)
	if director.line_clear(me, goal):
		path = PackedVector2Array([goal])
	elif path_t <= 0.0 or path.is_empty():
		path = director.find_path(me, goal)
		path_t = 0.6
	if path.is_empty(): return
	var next := path[0]
	if me.distance_to(next) < 0.35 and path.size() > 1:
		path.remove_at(0); next = path[0]
	_step(Vector3(next.x, global_position.y, next.y), delta, 1.0)

func _move_toward(target: Vector3, delta: float, mult: float) -> void:
	var me := Vector2(global_position.x, global_position.z)
	var goal := Vector2(target.x, target.z)
	if path.is_empty() or path_t <= 0.0:
		path = director.find_path(me, goal) if not director.line_clear(me, goal) else PackedVector2Array([goal])
		path_t = 1.0
	path_t -= delta
	if path.is_empty(): global_position = target; return
	var next := path[0]
	if me.distance_to(next) < 0.35 and path.size() > 1:
		path.remove_at(0); next = path[0]
	_step(Vector3(next.x, global_position.y, next.y), delta, mult)

func _step(to: Vector3, delta: float, mult: float) -> void:
	var d := Vector3(to.x - global_position.x, 0, to.z - global_position.z)
	var L := d.length()
	if L < 0.01: return
	var stepv := d / L * minf(L, speed * mult * (1.0 - slow_mult) * delta)
	# keep a little space from pack mates
	for m in pack:
		if is_instance_valid(m) and m != self and m.state != "dead":
			var o := Vector3(global_position.x - m.global_position.x, 0, global_position.z - m.global_position.z)
			var ol := o.length()
			if ol < 0.9 and ol > 0.001: stepv += o / ol * (0.9 - ol) * delta * 3.0
	var nxt := global_position + stepv
	if director.walkable(nxt):
		velocity_hint = stepv.length() / maxf(delta, 0.0001)
		global_position = nxt
		_face(d)
