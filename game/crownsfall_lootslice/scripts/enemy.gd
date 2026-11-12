extends Node2D
## An Unwritten enemy: one painted sprite, animated in code (bob, lean, lunge).
## Chases the knight, winds up (red warning wedge), then strikes.

const GD := preload("res://scripts/game_data.gd")
const TEX := {
	"slime": preload("res://assets/enemies/slime.png"),
	"revenant": preload("res://assets/enemies/revenant.png"),
	"brute": preload("res://assets/enemies/brute.png"),
}
## On-screen scale of each sprite, tuned against the knight's height.
const DRAW_SCALE := {"slime": 0.8, "revenant": 0.84, "brute": 0.88}

var main: Node2D
var player: Node2D
var type_key := "slime"
var t: Dictionary = {}
var level := 1
var elite := false
var ename := ""
var max_hp := 1.0
var hp := 1.0
var invulnerable := false
var dmg := 1.0
var rad := 0.4

var state := "chase"
var wind_left := 0.0
var atk_cd := 0.6
var flash := 0.0
var dead_t := -1.0   # >= 0 while fading out after death
var face := 1.0
var slow_time := 0.0
var slow_factor := 1.0
var frost_until := -1.0
var burn := 0.0
var burn_dps := 0.0
var burn_tick := 0.0
var kb := Vector2.ZERO  # knockback, ground units per second
var phase := 0.0
var stun := 0.8
var moving := false
var struck := 0.0
var recoil_side := 1.0


func setup(key: String, is_elite: bool, player_level: int) -> void:
	type_key = key
	t = GD.ETYPES[key]
	elite = is_elite
	rad = t["rad"]
	level = maxi(1, player_level + (1 if elite else 0) + int(floor(randf_range(-1.0, 1.2))))
	var sc: float = pow(1.0 + 0.3 * (level - 1), 1.35)
	max_hp = round(float(t["hp"]) * sc * (2.8 if elite else 1.0))
	hp = max_hp
	dmg = float(t["dmg"]) * (1.0 + 0.24 * (level - 1)) * (1.6 if elite else 1.0)
	ename = t["name"]
	if elite:
		ename = "%s %s" % [GD.ELITE_PREFIX[randi() % GD.ELITE_PREFIX.size()], t["name"]]
	phase = randf() * 6.0


## Height of the sprite on screen, in pixels.
func height() -> float:
	var tex: Texture2D = TEX[type_key]
	return tex.get_height() * float(DRAW_SCALE[type_key]) * (1.25 if elite else 1.0)


func take_hit(amount: int, crit: bool, from: Vector2, opt: Dictionary) -> float:
	if invulnerable or dead_t >= 0 or hp <= 0 or amount <= 0: return 0.0
	var actual := minf(hp,float(amount))
	hp = maxf(0,hp-actual)
	flash = 0.12
	var dir := GD.ground(from, position).normalized()
	recoil_side = signf(dir.x) if absf(dir.x) > 0.01 else -face
	var k: float = float(opt.get("kb", 0.15)) * (0.4 if type_key == "brute" else 1.0) * (0.5 if elite else 1.0)
	kb += dir * k * 10.0
	if opt.has("stun"):
		stun = maxf(stun, float(opt["stun"]) * (0.5 if elite else 1.0))
	main.fx_text.text(position, str(amount), Color("ffd84a") if crit else Color.WHITE, crit)
	var cols: Array = opt.get("colors", [Color.WHITE, Color("ffd2a0")])
	main.fx_parts.burst(position, 10 if crit else 5, cols, 3.0, 70.0)
	if crit:
		main.shake = maxf(main.shake, 5.0)
	return actual


func _move(g: Vector2) -> void:
	# g is a ground-unit step. The navigation mesh keeps enemies on the floor and lets them slide along edges.
	var np := position + GD.to_px(g)
	var map := get_world_2d().navigation_map
	position = NavigationServer2D.map_get_closest_point(map, np)


func _advance_burn(delta: float) -> bool:
	if dead_t >= 0: return true
	if burn <= 0: return false
	var active_delta := minf(delta, burn)
	burn = maxf(0, burn - active_delta)
	burn_tick += active_delta
	while burn_tick >= 0.5 - 0.00001:
		burn_tick = maxf(0, burn_tick - 0.5)
		if not invulnerable: hp -= burn_dps * 0.5
		main.fx_text.text(position, "%.1f" % (burn_dps * 0.5), Color("ff9a4a"))
		if hp <= 0:
			main.kill_enemy(self,{"origin":"burn","proc_depth":0,"was_burning":true}); return true
	if burn <= 0.00001:
		if burn_tick > 0.00001:
			if not invulnerable: hp -= burn_dps * burn_tick
			if hp <= 0: main.kill_enemy(self,{"origin":"burn","proc_depth":0,"was_burning":true}); return true
		burn = 0; burn_tick = 0; burn_dps = 0
	return false

func _process(delta: float) -> void:
	queue_redraw()
	if dead_t >= 0.0:
		dead_t += delta
		if dead_t > 1.0:
			queue_free()
		return
	flash = maxf(0.0, flash - delta)
	struck = maxf(0.0, struck - delta)
	slow_time = maxf(0, slow_time - delta)
	if slow_time <= 0: slow_factor = 1.0
	phase += delta
	moving = false
	if _advance_burn(delta): return
	if burn > 0 and randf() < 0.4:
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
	if state == "windup":
		wind_left -= delta
		if wind_left <= 0.0:
			state = "chase"
			atk_cd = t["atk_cd"]
			struck = 0.18
			if d_p <= float(t["range"]) + 0.45:
				player.hurt(dmg, level)
	elif d_p <= float(t["range"]) + 0.2:
		if atk_cd <= 0.0:
			state = "windup"
			wind_left = t["wind"]
			face = 1.0 if player.position.x >= position.x else -1.0
	else:
		_move(to_p / d_p * minf(float(t["speed"]) * delta * slow_factor, d_p))
		face = 1.0 if to_p.x >= 0.0 else -1.0
		moving = true


# ---------------------------------------------------------------- drawing
func _ellipse(c: Vector2, rx: float, ry: float, from := 0.0, to := TAU, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := from + (to - from) * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _col(hex: String) -> Color:
	return Color.WHITE if flash > 0.0 else Color(hex)

## Pose only; AI, hit boxes, damage and reward ownership stay on the actor.
func sprite_pose() -> Dictionary:
	var k: float = float(DRAW_SCALE[type_key]) * (1.25 if elite else 1.0)
	if dead_t >= 0:
		var fall := smoothstep(0.0, 0.42, dead_t)
		if type_key == "slime":
			return {"offset":Vector2.ZERO,"rotation":0.0,"scale":Vector2(k * face * (1 + 0.35 * fall), k * (1 - 0.8 * fall)),"tint":Color.WHITE.lerp(Color(0.5,0.5,0.55),fall)}
		return {"offset":Vector2(0,8 * fall),"rotation":face * 1.25 * fall,"scale":Vector2(k * face,k * (1 - 0.2 * fall)),"tint":Color.WHITE.lerp(Color(0.5,0.5,0.55),fall)}
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
		"brute":
			hop = absf(sin(phase * 5.0)) * 6.0 if moving else sin(phase * 2.0) * 2.0
			tilt = sin(phase * 5.0) * 0.04 if moving else 0.0
	var wind: float = 1.0 - wind_left / float(t["wind"]) if state == "windup" else 0.0
	tilt += (-0.22 * wind + (0.3 * struck / 0.18)) * face
	var recoil := clampf(flash / 0.12, 0, 1)
	tilt += recoil_side * recoil * 0.12
	var tint := Color(2.2, 2.2, 2.2) if flash > 0.0 else (Color(1.0, 0.75, 0.6) if burn > 0.0 else Color.WHITE)
	return {"offset":Vector2(struck / 0.18 * 14.0 * face + recoil_side * recoil * 7, -hop),"rotation":tilt,"scale":Vector2(k * face * squash, k / squash),"tint":tint}

func shows_attack_warning() -> bool:
	return dead_t < 0 and state == "windup"


func _draw() -> void:
	var alpha := 1.0
	if dead_t >= 0.0:
		alpha = maxf(0.0, 1.0 - dead_t)
	modulate.a = alpha
	var sc: float = (1.25 if elite else 1.0) * 2.0
	var tall: float = height()
	var wind: float = 0.0
	if shows_attack_warning():
		wind = 1.0 - wind_left / float(t["wind"])
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
	if dead_t < 0 and struck > 0.0 and player != null:
		var ang2 := GD.ground(position, player.position).angle()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, GD.SQ))
		draw_arc(Vector2.ZERO, (float(t["range"]) + 0.2) * GD.U, ang2 - 0.8, ang2 + 0.8, 16, Color(1.0, 0.24, 0.16, struck / 0.18 * 0.7), 14.0, true)

	# shadow
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_colored_polygon(_ellipse(Vector2.ZERO, 22.0 * sc * (1.5 if type_key == "brute" else 1.0), 9.0 * sc), Color(0.1, 0.08, 0.2, 0.3))
	if elite and dead_t < 0:
		draw_circle(Vector2(0, -tall * 0.5), tall * 0.55, Color(1.0, 0.78, 0.3, 0.12))

	# painted sprite (faces lower-right in the source art; mirrored when facing left)
	var tex: Texture2D = TEX[type_key]
	var pose := sprite_pose()
	draw_set_transform(pose.offset, pose.rotation, pose.scale)
	draw_texture(tex, Vector2(-tex.get_width() / 2.0, -tex.get_height() + 8.0), pose.tint)

	# health bar and elite name
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if dead_t < 0.0 and (hp < max_hp or elite or main.hover_enemy == self):
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
