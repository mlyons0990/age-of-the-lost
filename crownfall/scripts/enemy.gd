extends Node2D
## An Unwritten enemy: one painted sprite, animated in code (bob, lean, lunge).
## Chases the knight, winds up (red warning wedge), then strikes.

const GD := preload("res://scripts/game_data.gd")
const TEX := {
	"slime": preload("res://assets/enemies/slime.png"),
	"revenant": preload("res://assets/enemies/revenant.png"),
	"brute": preload("res://assets/enemies/brute.png"),
	"caster": preload("res://assets/enemies/hexcaller.png"),
	"skeleton": preload("res://assets/enemies/skeleton.png"),
	"stag": preload("res://assets/enemies/stag.png"),
}
const EA := preload("res://scripts/enemy_anims.gd")
const DEATH_TIME := 1.5     # seconds a death animation plays
const STRIKE_TIME := 0.42   # seconds the strike animation plays
## On-screen scale of each sprite, tuned against the knight's height.
const DRAW_SCALE := {"slime": 0.8, "revenant": 0.84, "brute": 0.88, "caster": 0.82, "warden": 1.45, "skeleton": 0.84, "stag": 0.86}

var main: Node2D
var player: Node2D
var type_key := "slime"
var t: Dictionary = {}
var level := 1
var elite := false
var ename := ""
var max_hp := 1.0
var hp := 1.0
var dmg := 1.0
var rad := 0.4

var state := "chase"
var wind_left := 0.0
var atk_cd := 0.6
var flash := 0.0
var dead_t := -1.0   # >= 0 while fading out after death
var face := 1.0
var burn := 0.0
var burn_dps := 0.0
var burn_tick := 0.0
var kb := Vector2.ZERO  # knockback, ground units per second
var phase := 0.0
var stun := 0.8
var moving := false
var struck := 0.0
var strike_t := 0.0   # counts down while the strike animation plays
static var _sheets := {}
var affixes: Array = []   # elite affix ids, see GD.ELITE_AFFIXES
var ward := 0.0           # Shielded: seconds the ward stays up
var ward_cd := 3.0        # Shielded: seconds until the next ward
var summons_done := 0     # Summoner: how many hp thresholds have called help
var boss := false
var slam_cd := 3.0        # boss: seconds until the next ground slam
var enraged := false


func setup(key: String, is_elite: bool, player_level: int) -> void:
	type_key = key
	t = GD.ETYPES[key]
	elite = is_elite
	rad = t["rad"]
	level = maxi(1, player_level + (1 if elite else 0) + int(floor(randf_range(-1.0, 1.2))))
	var sc: float = 1.0 + 0.3 * (level - 1)
	max_hp = round(float(t["hp"]) * sc * (2.8 if elite else 1.0))
	hp = max_hp
	dmg = float(t["dmg"]) * (1.0 + 0.24 * (level - 1)) * (1.6 if elite else 1.0)
	ename = t["name"]
	if elite:
		ename = "%s %s" % [GD.ELITE_PREFIX[randi() % GD.ELITE_PREFIX.size()], t["name"]]
	phase = randf() * 6.0
	boss = t.get("boss", false)
	if boss:
		elite = false
		level = player_level + 1
		max_hp = round(float(t["hp"]) * (1.0 + 0.3 * (level - 1)))
		hp = max_hp
		dmg = float(t["dmg"]) * (1.0 + 0.24 * (level - 1))
		set_affixes(["summoner"])
		return
	if elite:
		var pool: Array = GD.ELITE_AFFIXES.keys()
		pool.shuffle()
		set_affixes(pool.slice(0, 2 if player_level >= GD.ELITE_TWO_AFFIX_LEVEL else 1))


## Gives this elite specific affixes (also used by the self-test).
func set_affixes(list: Array) -> void:
	affixes = list.duplicate()
	ward = 0.0
	ward_cd = 3.0
	summons_done = 0


func affix_names() -> String:
	var n: Array = []
	for a in affixes:
		n.append(GD.ELITE_AFFIXES[a]["name"])
	return "  ·  ".join(n)


## Speed and attack-rate multipliers from affixes.
func speed_mult() -> float:
	return (float(GD.ELITE_AFFIXES["swift"]["speed"]) if affixes.has("swift") else 1.0) * (1.35 if enraged else 1.0)


func attack_mult() -> float:
	return (float(GD.ELITE_AFFIXES["swift"]["attack"]) if affixes.has("swift") else 1.0) * (0.7 if enraged else 1.0)


## Height of the sprite on screen, in pixels.
func tex() -> Texture2D:
	return TEX[String(t.get("tex", type_key))]


func height() -> float:
	var tex: Texture2D = tex()
	return tex.get_height() * float(DRAW_SCALE[type_key]) * (1.25 if elite else 1.0)


## Applies a hit. Returns the damage actually taken (0 while a ward is up).
func take_hit(amount: int, crit: bool, from: Vector2, opt: Dictionary) -> int:
	if ward > 0.0:
		main.fx_text.text(position, "Warded", Color("e6e0ff"))
		main.fx_parts.burst(position + Vector2(0, -height() * 0.5), 6, [Color("e6e0ff"), Color("a9a0ff")], 2.0, 40.0)
		return 0
	hp -= amount
	flash = 0.12
	var dir := GD.ground(from, position).normalized()
	var k: float = float(opt.get("kb", 0.15)) * (0.4 if type_key == "brute" else 1.0) * (0.5 if elite else 1.0) * (0.1 if boss else 1.0)
	kb += dir * k * 10.0
	if opt.has("stun"):
		stun = maxf(stun, float(opt["stun"]) * (0.3 if boss else 1.0))
	main.fx_text.text(position, str(amount), Color("ffd84a") if crit else Color.WHITE, crit)
	var cols: Array = opt.get("colors", [Color.WHITE, Color("ffd2a0")])
	main.fx_parts.burst(position, 10 if crit else 5, cols, 3.0, 70.0)
	if crit:
		main.shake = maxf(main.shake, 5.0)
	_check_summon()
	return amount


## Summoner: calls Hollowlings each time its life drops past a threshold.
func _check_summon() -> void:
	if not affixes.has("summoner") or hp <= 0.0:
		return
	var su: Dictionary = GD.ELITE_AFFIXES["summoner"]
	var at: Array = su["at"]
	while summons_done < at.size() and hp / max_hp <= float(at[summons_done]):
		summons_done += 1
		main.fx_text.text(position + Vector2(0, -40), "Rise!", Color("c9a8ff"), true)
		for i in int(su["count"]):
			var off := GD.to_px(Vector2(1.0, 0.0).rotated(TAU * i / float(su["count"]) + randf()))
			main.spawn_enemy("slime", false, position + off)


func _move(g: Vector2) -> void:
	# g is a ground-unit step. The navigation mesh keeps enemies on the floor and lets them slide along edges.
	var np := position + GD.to_px(g)
	var map := get_world_2d().navigation_map
	position = NavigationServer2D.map_get_closest_point(map, np)


func _process(delta: float) -> void:
	queue_redraw()
	if dead_t >= 0.0:
		dead_t += delta
		if dead_t > death_length():
			queue_free()
		return
	strike_t = maxf(0.0, strike_t - delta)
	flash = maxf(0.0, flash - delta)
	struck = maxf(0.0, struck - delta)
	if affixes.has("shielded"):
		var sh: Dictionary = GD.ELITE_AFFIXES["shielded"]
		if ward > 0.0:
			ward -= delta
		else:
			ward_cd -= delta
			if ward_cd <= 0.0:
				ward = float(sh["lasts"])
				ward_cd = float(sh["every"])
				main.audio.play("rally", 0.1)
	phase += delta
	moving = false
	if burn > 0.0:
		burn -= delta
		burn_tick += delta
		if burn_tick > 0.5 and ward <= 0.0:
			burn_tick = 0.0
			var d: int = maxi(1, roundi(burn_dps * 0.5))
			hp -= d
			main.fx_text.text(position, str(d), Color("ff9a4a"))
			if hp <= 0.0:
				main.kill_enemy(self)
				return
		if randf() < 0.4:
			main.fx_parts.spark(position + Vector2(randf_range(-18, 18), 0), Vector2.ZERO, randf_range(20, 90), 80.0, 0.0, 0.4, Color("ff9a4a"), 5.0)
	if kb.length() > 0.01:
		_move(kb * delta)
		kb *= pow(0.001, delta)
	if stun > 0.0:
		stun -= delta
		if state == "windup":
			state = "chase"
		return
	atk_cd = maxf(0.0, atk_cd - delta)
	if player.dead:
		return
	var to_p := GD.ground(position, player.position)
	var d_p := to_p.length()
	if t.get("ranged", false):
		_ranged_ai(delta, to_p, d_p)
		return
	if boss:
		_boss_specials(delta)
	if state == "windup":
		wind_left -= delta
		if wind_left <= 0.0:
			state = "chase"
			atk_cd = float(t["atk_cd"]) * attack_mult()
			struck = 0.18
			strike_t = STRIKE_TIME
			main.audio.play("enemy_swing", 0.12)
			if d_p <= float(t["range"]) + 0.45:
				player.hurt(dmg, level, ename)
	elif d_p <= float(t["range"]) + 0.2:
		if atk_cd <= 0.0:
			state = "windup"
			wind_left = float(t["wind"]) * attack_mult()
			face = 1.0 if player.position.x >= position.x else -1.0
	else:
		_move(to_p / d_p * minf(float(t["speed"]) * speed_mult() * delta * (0.85 if burn > 0.0 else 1.0), d_p))
		face = 1.0 if to_p.x >= 0.0 else -1.0
		moving = true


## Casters keep their distance: approach until in range, back away when the knight
## gets close, and otherwise charge and fire a bolt that can be sidestepped.
func _ranged_ai(delta: float, to_p: Vector2, d_p: float) -> void:
	face = 1.0 if to_p.x >= 0.0 else -1.0
	var spd: float = float(t["speed"]) * speed_mult() * delta * (0.85 if burn > 0.0 else 1.0)
	if state == "windup":
		wind_left -= delta
		if wind_left <= 0.0:
			state = "chase"
			atk_cd = float(t["atk_cd"]) * attack_mult() * randf_range(0.85, 1.15)
			struck = 0.18
			strike_t = STRIKE_TIME
			main.fire_bolt(position, player.position, dmg, level, float(t["bolt_speed"]), float(t["range"]), ename)
		return
	if d_p > float(t["range"]):
		_move(to_p / d_p * minf(spd, d_p - float(t["range"]) + 0.1))
		moving = true
	elif d_p < float(t["keep"]):
		moving = _retreat(to_p / maxf(d_p, 0.01), spd, d_p)
		# cornered against a wall: stand and fight
		if not moving and atk_cd <= 0.0:
			_start_cast()
	elif atk_cd <= 0.0:
		_start_cast()


## Steps away from the knight, trying angled routes when a wall is directly behind.
## Returns true if it found a step that gains distance.
func _retreat(dir_to_player: Vector2, step: float, d_now: float) -> bool:
	var map := get_world_2d().navigation_map
	for ang in [0.0, 0.6, -0.6, 1.2, -1.2, 1.7, -1.7]:
		var g: Vector2 = (-dir_to_player).rotated(ang) * step
		var np := NavigationServer2D.map_get_closest_point(map, position + GD.to_px(g))
		if np.distance_to(position) > step * GD.U * 0.4 and GD.gdist(np, player.position) > d_now + step * 0.3:
			position = np
			return true
	return false


## Boss: slams the ground where the knight stands (twice when enraged) and enrages at low life.
func _boss_specials(delta: float) -> void:
	if not enraged and hp / max_hp <= float(t["enrage"]):
		enraged = true
		main.hud.banner("The Warden Rages", "")
		main.audio.play("wave", 0.0)
		main.shake = maxf(main.shake, 8.0)
	slam_cd -= delta
	if slam_cd <= 0.0 and state != "windup":
		slam_cd = float(t["slam_cd"]) * (0.65 if enraged else 1.0)
		var col := Color("b07aff") if not enraged else Color("ff5a5a")
		main.ground_blast(player.position, float(t["slam_radius"]), float(t["slam_delay"]), dmg * float(t["slam_dmg"]), level, col, ename)
		if enraged:
			# a second ring where the knight is heading
			var lead: Vector2 = player.position + GD.to_px(GD.ground(position, player.position).normalized() * 2.0)
			main.ground_blast(lead, float(t["slam_radius"]), float(t["slam_delay"]) + 0.4, dmg * float(t["slam_dmg"]), level, col, ename)
		struck = 0.18
		strike_t = STRIKE_TIME
		main.audio.play("enemy_swing", 0.0)


func _start_cast() -> void:
	state = "windup"
	wind_left = float(t["wind"]) * attack_mult()


# ---------------------------------------------------------------- drawing
func _ellipse(c: Vector2, rx: float, ry: float, from := 0.0, to := TAU, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := from + (to - from) * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _col(hex: String) -> Color:
	return Color.WHITE if flash > 0.0 else Color(hex)


# ---------------------------------------------------------------- animation (Higgsfield clips)
## The art key this enemy's pictures use (the Warden borrows the Brute's).
func art_key() -> String:
	return String(t.get("tex", type_key)) if type_key != "caster" else "caster"


func has_anim(anim: String) -> bool:
	return EA.ANIMS.has(art_key()) and EA.ANIMS[art_key()].has(anim)


func death_length() -> float:
	return DEATH_TIME if has_anim("death") else 1.0


static func sheet(key: String, anim: String) -> Texture2D:
	var k := key + "_" + anim
	if not _sheets.has(k):
		var path := "res://assets/enemies/anim/%s.png" % k
		_sheets[k] = load(path) if ResourceLoader.exists(path) else null
	return _sheets[k]


## [anim name, frame index] for the current state, or [] to draw the still.
func current_frame() -> Array:
	var key := art_key()
	if not EA.ANIMS.has(key):
		return []
	var A: Dictionary = EA.ANIMS[key]
	if dead_t >= 0.0:
		if A.has("death"):
			var n: int = A["death"]["frames"]
			return ["death", mini(n - 1, int(dead_t / DEATH_TIME * n))]
		return []
	if strike_t > 0.0 and A.has("strike"):
		var n2: int = A["strike"]["frames"]
		return ["strike", mini(n2 - 1, int((1.0 - strike_t / STRIKE_TIME) * n2))]
	if state == "windup" and A.has("wind"):
		var n3: int = A["wind"]["frames"]
		var w := 1.0 - wind_left / maxf(0.01, float(t["wind"]) * attack_mult())
		return ["wind", clampi(int(w * n3), 0, n3 - 1)]
	if A.has("walk"):
		if moving:
			var n4: int = A["walk"]["frames"]
			return ["walk", int(phase * 10.0 * speed_mult()) % n4]
		return ["walk", 0]
	return []


func _draw() -> void:
	var alpha := 1.0
	if dead_t >= 0.0:
		var dl := death_length()
		alpha = clampf((dl - dead_t) / (0.35 if has_anim("death") else dl), 0.0, 1.0)
	modulate.a = alpha
	var sc: float = (1.25 if elite else 1.0) * 2.0
	var tall: float = height()
	var wind: float = 0.0
	if state == "windup" and t.get("ranged", false):
		wind = 1.0 - wind_left / (float(t["wind"]) * attack_mult())
		# aim line along the ground toward the knight, filling in as the bolt charges
		var g := GD.ground(position, player.position).normalized()
		var reach: float = float(t["range"]) + 1.5
		var end := GD.to_px(g * reach)
		draw_line(Vector2.ZERO, end, Color(0.5, 1.0, 0.8, 0.12 + 0.2 * wind), 10.0, true)
		draw_line(Vector2.ZERO, end * wind, Color(0.6, 1.0, 0.85, 0.55), 3.0, true)
	elif state == "windup":
		wind = 1.0 - wind_left / (float(t["wind"]) * attack_mult())
		# red warning wedge on the ground
		var ang := GD.ground(position, player.position).angle()
		var r: float = (float(t["range"]) + 0.3) * GD.U
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, GD.SQ))
		var wedge := PackedVector2Array([Vector2.ZERO])
		for i in 13:
			var a := ang - 0.9 + 1.8 * i / 12.0
			wedge.append(Vector2(cos(a), sin(a)) * r * wind)
		if wind > 0.05:
			draw_colored_polygon(wedge, Color(1.0, 0.16, 0.12, 0.14 + wind * 0.2))
		draw_arc(Vector2.ZERO, r, ang - 0.9, ang + 0.9, 16, Color(1.0, 0.3, 0.24, 0.7), 3.0, true)
	if struck > 0.0 and player != null and not t.get("ranged", false):
		var ang2 := GD.ground(position, player.position).angle()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, GD.SQ))
		draw_arc(Vector2.ZERO, (float(t["range"]) + 0.2) * GD.U, ang2 - 0.8, ang2 + 0.8, 16, Color(1.0, 0.24, 0.16, struck / 0.18 * 0.7), 14.0, true)

	# shadow
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_colored_polygon(_ellipse(Vector2.ZERO, 22.0 * sc * (1.5 if type_key == "brute" else (2.4 if boss else 1.0)), 9.0 * sc * (1.6 if boss else 1.0)), Color(0.1, 0.08, 0.2, 0.3))
	if elite:
		draw_circle(Vector2(0, -tall * 0.5), tall * 0.55, Color(1.0, 0.78, 0.3, 0.12))
	if affixes.has("molten"):
		# smouldering ground and embers
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, GD.SQ))
		draw_circle(Vector2.ZERO, 70.0 + sin(phase * 5.0) * 6.0, Color(1.0, 0.4, 0.1, 0.16))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if randf() < 0.25 and dead_t < 0.0:
			main.fx_parts.spark(position + Vector2(randf_range(-30, 30), -randf_range(0, tall * 0.6)), Vector2.ZERO, randf_range(30, 80), 60.0, 0.0, 0.5, Color("ff8a3a"), 4.0)

	# painted sprite (faces lower-right in the source art; mirrored when facing left)
	var tex: Texture2D = tex()
	var k: float = float(DRAW_SCALE[type_key]) * (1.25 if elite else 1.0)
	var hop := 0.0
	var squash := 1.0
	var tilt := 0.0
	match type_key:
		"slime":
			hop = absf(sin(phase * 7.0)) * (16.0 if moving else 4.0)
			squash = 1.0 + sin(phase * 14.0) * 0.04
		"revenant":
			hop = 5.0 + sin(phase * 3.0) * 5.0
			tilt = sin(phase * 6.0) * 0.03 if moving else 0.0
		"caster":
			hop = 10.0 + sin(phase * 2.4) * 7.0   # floats above the ground
			tilt = sin(phase * 4.0) * 0.03 if moving else 0.0
		"brute", "warden":
			hop = absf(sin(phase * 5.0)) * 6.0 if moving else sin(phase * 2.0) * 2.0
			tilt = sin(phase * 5.0) * 0.04 if moving else 0.0
	# lean back while winding up, lunge forward on the strike
	tilt += (-0.22 * wind + (0.3 * struck / 0.18)) * face
	var tint := Color(2.2, 2.2, 2.2) if flash > 0.0 else (Color(1.0, 0.75, 0.6) if burn > 0.0 else Color.WHITE)
	if t.has("tint") and flash <= 0.0:
		tint *= Color(String(t["tint"])) * (Color(1.4, 0.7, 0.7) if enraged else Color.WHITE)
	var fr := current_frame()
	if not fr.is_empty():
		# animated: the clip already carries the motion, so only keep a float for the caster
		var meta: Dictionary = EA.ANIMS[art_key()][fr[0]]
		var cols: int = meta["cols"]
		var cw: float = meta["cw"]
		var chh: float = meta["ch"]
		var src := Rect2((fr[1] % cols) * cw, (fr[1] / cols) * chh, cw, chh)
		var float_up: float = (10.0 + sin(phase * 2.4) * 7.0) if type_key == "caster" else 0.0
		draw_set_transform(Vector2(0, -float_up), 0.0, Vector2(k * face, k))
		draw_texture_rect_region(sheet(art_key(), fr[0]), Rect2(Vector2(-float(meta["ax"]), -float(meta["ay"]) + 8.0), Vector2(cw, chh)), src, tint)
	else:
		draw_set_transform(Vector2(struck / 0.18 * 14.0 * face, -hop), tilt, Vector2(k * face * squash, k / squash))
		draw_texture(tex, Vector2(-tex.get_width() / 2.0, -tex.get_height() + 8.0), tint)

	# Shielded: a pale ward bubble while it blocks damage
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if ward > 0.0:
		var wa := clampf(ward / 0.3, 0.0, 1.0)
		var wc := Vector2(0, -tall * 0.5)
		draw_circle(wc, tall * 0.62, Color(0.85, 0.82, 1.0, 0.16 * wa))
		draw_arc(wc, tall * 0.62, 0.0, TAU, 48, Color(0.92, 0.9, 1.0, 0.8 * wa), 3.0, true)
		draw_arc(wc, tall * 0.62 - 6.0, phase * 2.0, phase * 2.0 + 2.0, 16, Color(1, 1, 1, 0.6 * wa), 2.0, true)

	# a caster's bolt gathering in its hand
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "windup" and t.get("ranged", false):
		var hc := Vector2(30.0 * face, -tall * 0.55 - hop)
		var rr := 4.0 + 12.0 * wind
		draw_circle(hc, rr * 1.8, Color(0.5, 1.0, 0.8, 0.2))
		draw_circle(hc, rr, Color("7dffc8"))
		draw_circle(hc, rr * 0.45, Color("f2fff9"))

	# health bar and elite name
	if dead_t < 0.0 and not boss and (hp < max_hp or elite or main.hover_enemy == self):
		var w: float = 110.0 if elite else 76.0
		var y: float = -tall - 24.0
		draw_rect(Rect2(-w / 2 - 1, y - 1, w + 2, 8), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-w / 2, y, w * clampf(hp / max_hp, 0.0, 1.0), 6), Color("ff9a2e") if elite else Color("d6343c"))
		if burn > 0.0:
			draw_rect(Rect2(-w / 2, y + 6, w * minf(1.0, burn / 3.0), 2), Color("ffb347"))
		if elite:
			var font := ThemeDB.fallback_font
			var tw := font.get_string_size(ename, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_string_outline(font, Vector2(-tw / 2, y - 8), ename, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 5, Color(0, 0, 0, 0.9))
			draw_string(font, Vector2(-tw / 2, y - 8), ename, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffcf7a"))
			# affixes on a line above the name, each in its own colour
			if not affixes.is_empty():
				var ax := 0.0
				var parts: Array = []
				for af in affixes:
					parts.append(String(GD.ELITE_AFFIXES[af]["name"]))
				var full := "  ·  ".join(parts)
				ax = -font.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x / 2.0
				for i in affixes.size():
					var nm: String = parts[i] + ("  ·  " if i < affixes.size() - 1 else "")
					var cc := Color(String(GD.ELITE_AFFIXES[affixes[i]]["color"]))
					draw_string_outline(font, Vector2(ax, y - 28), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0, 0, 0, 0.9))
					draw_string(font, Vector2(ax, y - 28), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, cc)
					ax += font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
