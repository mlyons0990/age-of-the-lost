extends Node2D
## The knight: movement, combat, skills and progression.
## Left click (or hold) to walk or attack; eight facing directions, the three
## west-facing ones are mirrored from their east-facing sheets.

const GD := preload("res://scripts/game_data.gd")
const Inv := preload("res://scripts/inventory_logic.gd")

const SPEED := 340.0          # pixels per second across the screen
const DEPTH_SQUASH := 0.72    # moving "into" the screen covers less ground
const FRAME := 384            # size of one square frame in the strips
const SPRITE_SCALE := 0.76
const FEET := Vector2(0, 12) # nudges the art so the boots sit on the node origin
const WALK_FPS := 14.0
const ATTACK_FRAME := 512      # attack strips use larger frames so the sword swing fits
const ATTACK_FPS := 28.0
## Frames per second of each action strip (assets/knight/<kind>_<se|ne>.png).
const ACTION_FPS := {"attack": 28.0, "hit": 24.0, "cast": 24.0, "death": 9.0, "roll": 28.0}
const ATTACK_TIME := 0.5       # how long a swing roots the knight
const HIT_DELAY := 0.2         # the blow lands this long after the swing starts

## Which attack strip to use for each of the 8 facings, and whether to mirror it.
## Only the two diagonal strips exist, so the other facings borrow the nearest one.
const ATTACK_FACINGS := [
	["se", false], ["se", false], ["se", false], ["se", true],
	["se", true], ["ne", true], ["ne", false], ["ne", false],
]

## animation suffix and whether to mirror, for 8 screen directions starting
## at "right" and going clockwise (right, down-right, down, down-left, ...).
const FACINGS := [
	["right", false], ["se", false], ["down", false], ["se", true],
	["right", true], ["ne", true], ["up", false], ["ne", false],
]

var main: Node2D
var sprite: AnimatedSprite2D
var shadow: Sprite2D
var path: PackedVector2Array = PackedVector2Array()
var path_index := 0
var facing := 1
var marker: Node2D
var idle_time := 0.0

# ---- progression (saved)
var hero_name := "Wayfarer"
var level := 1
var xp := 0
var gold := 0
var potions := 3
var kills := 0
var elite_kills := 0
var bosses_killed := 0
var last_attacker := ""   # name of whatever hit the knight last, for the death screen
var deaths := 0
var spec := ""
var adv := ""
var heroic := ""
var gear := {"helm": null, "amulet": null, "weapon": null, "armor": null, "offhand": null,
	"gloves": null, "belt": null, "boots": null, "ring1": null, "ring2": null}
var bag: Array = []      # backpack grid entries, see inventory_logic.gd
var stash: Array = []    # stash grid entries
var opened_rift := false
var quest := 0

# ---- combat state
var hp := 100.0
var mp := 50.0
var cds := {}       # slot -> seconds left
var cd_full := {}   # slot -> full cooldown, for the HUD sweep
var rally := 0.0
var invuln := 0.0
var attack_anim := 0.0
var lunge := Vector2.ZERO
var last_hurt := -99.0
var clock := 0.0
var dead := false
var target: Node2D = null
var going_to_merchant := false
var going_to_memory: Node2D = null
var lore: Array = []      # ids of memories uncovered by Lorecasting (saved)
var spent := {"str": 0, "dex": 0, "vit": 0, "int": 0, "wis": 0}   # stat points placed by hand
var buyback: Array = []   # items sold this session, newest first (not saved)
var dash := {}
## Skill bar: which skill (basic, s1..s4) sits in each slot, in bar order 1, 2, 3, 4, LMB, RMB.
## Any skill can go in any slot; a skill appears at most once. "" is an empty slot.
const BIND_KEYS := ["1", "2", "3", "4", "LMB", "RMB"]
const DEFAULT_BINDINGS := ["s2", "s3", "s4", "", "basic", "s1"]
var bindings: Array = DEFAULT_BINDINGS.duplicate()
var rolling := {}            # active dodge roll: {"dir": ground dir, "left": units, "speed": units/s}
var evade_override := ""     # forces an evade type (tests; a future class could set it too)
var evade_msg := 0.0         # throttles the "Evade" text
var evade_t := 0.0           # seconds left of the evade's untouchable window
var mouse_held := false
var repath := 0.0
var mana_warn := 0.0
var pending_hit: Callable = Callable()
var pending_t := 0.0
var swinging := 0.0


func _ready() -> void:
	shadow = Sprite2D.new()
	shadow.texture = _shadow_texture()
	shadow.modulate = Color(0.1, 0.08, 0.2, 0.38)
	shadow.scale = Vector2(1.5, 0.62)
	shadow.z_index = -1
	add_child(shadow)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _build_frames()
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	sprite.offset = Vector2(0, -FRAME / 2.0) + FEET / SPRITE_SCALE
	add_child(sprite)
	_play("idle")


func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for d in ["up", "ne", "right", "se", "down"]:
		var tex: Texture2D = load("res://assets/knight/walk_%s.png" % d)
		var count := int(tex.get_width() / float(FRAME))
		var walk: String = "walk_" + d
		sf.add_animation(walk)
		sf.set_animation_speed(walk, WALK_FPS)
		sf.set_animation_loop(walk, true)
		for i in count:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * FRAME, 0, FRAME, FRAME)
			sf.add_frame(walk, at)
		var idle: String = "idle_" + d
		sf.add_animation(idle)
		sf.set_animation_loop(idle, false)
		var itex: Texture2D = load("res://assets/knight/idle_%s.png" % d)
		sf.add_frame(idle, itex)
	# action strips (512 px frames, the 384 px idle pose centred): sword swing, plus the
	# hit reaction, cast and death from the Higgsfield clips. Only the two diagonals exist.
	for kind in ACTION_FPS:
		for d in ["se", "ne"]:
			var apath := "res://assets/knight/%s_%s.png" % [kind, d]
			if not ResourceLoader.exists(apath):
				continue
			var atex: Texture2D = load(apath)
			var aname: String = kind + "_" + d
			sf.add_animation(aname)
			sf.set_animation_speed(aname, float(ACTION_FPS[kind]))
			sf.set_animation_loop(aname, false)
			for i in int(atex.get_width() / float(ATTACK_FRAME)):
				var at2 := AtlasTexture.new()
				at2.atlas = atex
				at2.region = Rect2(i * ATTACK_FRAME, 0, ATTACK_FRAME, ATTACK_FRAME)
				sf.add_frame(aname, at2)
	return sf


# ---------------------------------------------------------------- evade (Space)
func evade_def() -> Dictionary:
	var id := evade_override
	if id == "" and spec != "" and GD.SPECS[spec].has("evade"):
		id = String(GD.SPECS[spec]["evade"])
	return GD.EVADE.get(id, GD.EVADE["roll"])


## Dodges toward a painting position: a roll (or a blink, for specs that have one).
## Returns true if it happened (not on cooldown, enough mana, not already evading).
func evade(aim: Vector2) -> bool:
	if dead or get_tree().paused or not rolling.is_empty() or not dash.is_empty():
		return false
	if float(cds.get("evade", 0.0)) > 0.0:
		return false
	var ev := evade_def()
	if mp < float(ev["mana"]):
		return false
	var g := GD.ground(position, aim)
	if g.length() < 0.2:
		g = GD.ground(Vector2.ZERO, Vector2(1, 0).rotated(facing * PI / 4.0))
	var dir := g.normalized()
	mp -= float(ev["mana"])
	cds["evade"] = float(ev["cd"])
	cd_full["evade"] = float(ev["cd"])
	invuln = maxf(invuln, float(ev["iframes"]))
	evade_t = float(ev["iframes"])
	evade_msg = 0.0
	# an evade cancels a swing in progress and any walk or target
	pending_hit = Callable()
	pending_t = 0.0
	path = PackedVector2Array()
	target = null
	_face(GD.to_px(dir))
	if String(ev["type"]) == "blink":
		var from := position
		var to := NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, position + GD.to_px(dir * float(ev["dist"])))
		main.fx_ground.pillar(from, 0.5, Color("8fb8ff"))
		main.fx_parts.burst(from, 18, [Color("cfe2ff"), Color("6a8cff")], 3.0, 50.0)
		position = to
		main.fx_ground.pillar(to, 0.5, Color("8fb8ff"))
		main.fx_parts.burst(to, 18, [Color("cfe2ff"), Color("6a8cff")], 3.0, 50.0)
		main.audio.play("dodge", 0.0)
		return true
	rolling = {"dir": dir, "left": float(ev["dist"]), "speed": float(ev["dist"]) / float(ev["time"])}
	# the down-right clip rolls toward screen-left, so mirror it when rolling right
	var up: bool = dir.y < -0.2
	var anim := "roll_ne" if up else "roll_se"
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
		sprite.frame = 0
		sprite.speed_scale = 1.0
		sprite.scale = Vector2.ONE * SPRITE_SCALE
		sprite.flip_h = (dir.x < 0.0) if up else (dir.x > 0.0)
		swinging = float(ev["time"])
	main.audio.play("dodge", 0.0)
	return true


## Plays a one-shot action animation (hit, cast, death) facing the current direction.
## The animation holds the sprite for `lock` seconds; movement isn't stopped.
func _play_action(kind: String, lock: float) -> bool:
	var f: Array = ATTACK_FACINGS[facing]
	var anim: String = kind + "_" + String(f[0])
	if not sprite.sprite_frames.has_animation(anim):
		anim = kind + "_se"
		if not sprite.sprite_frames.has_animation(anim):
			return false
	sprite.flip_h = f[1]
	sprite.play(anim)
	sprite.frame = 0
	sprite.speed_scale = 1.0
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	swinging = lock
	return true


func _shadow_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


func _play(kind: String) -> void:
	if swinging > 0.0:
		return  # let the attack animation finish
	# Movement speed from gear also speeds up the walk cycle so the feet keep up.
	sprite.speed_scale = 1.0 + float(stats()["move"]) if kind == "walk" else 1.0
	var f: Array = FACINGS[facing]
	var anim: String = kind + "_" + f[0]
	sprite.flip_h = f[1]
	if sprite.animation != anim:
		sprite.play(anim)


## Starts the sword swing animation and schedules the blow to land mid-swing.
func _swing(on_hit: Callable) -> void:
	var f: Array = ATTACK_FACINGS[facing]
	var anim: String = "attack_" + String(f[0])
	if not sprite.sprite_frames.has_animation(anim):
		anim = "attack_se"
	if sprite.sprite_frames.has_animation(anim):
		swinging = 0.0
		sprite.flip_h = f[1]
		sprite.play(anim)
		sprite.frame = 0
		swinging = ATTACK_TIME / _aspd()
		sprite.speed_scale = _aspd()
		sprite.scale = Vector2.ONE * SPRITE_SCALE
	pending_hit = on_hit
	pending_t = HIT_DELAY / _aspd()
	main.audio.play("swing")


## Attack speed multiplier for the swing animation and its timing.
func _aspd() -> float:
	return 1.0 + float(stats()["atk_speed"])


# ---------------------------------------------------------------- stats
func mods() -> Dictionary:
	var m := {"hp": 0.0, "armor": 0.0, "dmg": 0.0, "crit": 0.0, "cdr": 0.0, "spec_dmg": 0.0, "spec_radius": 0.0,
		"lifesteal_mult": 1.0, "burn_mult": 1.0, "rally_heal": 0.0}
	var sources: Array = []
	if spec != "" and adv != "":
		for a in GD.SPECS[spec]["advanced"]:
			if a["id"] == adv:
				sources.append(a["mods"])
	if heroic != "":
		for h in GD.HEROIC:
			if h["id"] == heroic:
				sources.append(h["mods"])
	for src in sources:
		for k in src:
			if String(k).ends_with("_mult"):
				m[k] = float(m[k]) * float(src[k])
			else:
				m[k] = float(m[k]) + float(src[k])
	return m


## Strength, Dexterity, Vitality, Intelligence and Wisdom: class base + growth per level + gear.
func attributes(g: Dictionary = {}) -> Dictionary:
	if g.is_empty():
		g = Inv.gear_totals(gear)
	var c: Dictionary = GD.CLASS_ATTRS["knight"]
	var out := {}
	for a in GD.ATTRS:
		out[a] = floor(float(c["base"][a]) + float(c["per_level"][a]) * (level - 1)) + float(spent.get(a, 0)) + float(g.get(a, 0.0))
	return out


# ---------------------------------------------------------------- stat points
func points_earned() -> int:
	return (level - 1) * GD.POINTS_PER_LEVEL


func points_free() -> int:
	var used := 0
	for a in spent:
		used += int(spent[a])
	return points_earned() - used


## Places up to n points in a stat. Returns how many were placed.
func allocate(a: String, n: int = 1) -> int:
	if not spent.has(a):
		return 0
	var k := mini(n, points_free())
	if k <= 0:
		return 0
	spent[a] = int(spent[a]) + k
	var s := stats()
	hp = minf(hp, float(s["max_hp"]))
	mp = minf(mp, float(s["max_mp"]))
	return k


func respec_cost() -> int:
	return level * GD.RESPEC_COST_PER_LEVEL


## Takes every placed point back for gold. Returns false if there is nothing to reset or not enough gold.
func respec() -> bool:
	if points_free() == points_earned() or gold < respec_cost():
		return false
	gold -= respec_cost()
	for a in spent:
		spent[a] = 0
	var s := stats()
	hp = minf(hp, float(s["max_hp"]))
	mp = minf(mp, float(s["max_mp"]))
	return true


func stats() -> Dictionary:
	var m := mods()
	var g := Inv.gear_totals(gear)
	var at := attributes(g)
	var k: Dictionary = GD.PER_POINT
	var main_stat: float = at[GD.CLASS_ATTRS["knight"]["main"]]
	return {
		"attr": at,
		"max_hp": round((20.0 + 10.0 * level + float(at["vit"]) * float(k["vit_life"]) + float(g["hp"])) * (1.0 + float(m["hp"]))),
		"max_mp": round(20.0 + 2.0 * level + float(at["int"]) * float(k["int_mana"])),
		"dmg": (10.0 + 3.0 * (level - 1) + float(g["dmg"])) * (1.0 + main_stat * float(k["main_dmg"])) * (1.0 + float(m["dmg"])),
		"armor": (5.0 + 2.0 * level + float(g["armor"]) + float(at["str"]) * float(k["str_armor"])) * (1.0 + float(m["armor"])),
		"crit": 0.05 + float(at["dex"]) * float(k["dex_crit"]) + float(g["crit"]) + float(m["crit"]),
		"dodge": minf(GD.DODGE_CAP, float(at["dex"]) * float(k["dex_dodge"])),
		"spell": float(at["int"]) * float(k["int_spell"]),
		"mana_regen": 2.0 + float(at["wis"]) * float(k["wis_regen"]),
		"healing": 1.0 + float(at["wis"]) * float(k["wis_healing"]),
		"crit_mult": 1.75 + float(g["crit_dmg"]),
		"atk_speed": minf(float(GD.CAP["atk_speed"]), float(g["atk_speed"])),
		"life_hit": float(g["life_hit"]),
		"cdr": minf(float(GD.CAP["cdr"]), float(m["cdr"]) + float(g["cdr"])),
		"move": minf(float(GD.CAP["move"]), float(g["move"])),
		"m": m,
	}


func skill_def(slot: String) -> Dictionary:
	if slot == "s4":
		if spec == "":
			return {}
		return GD.SPECS[spec]["skill"]
	return GD.BASE.get(slot, {})


func fx_colors() -> Array:
	if spec == "":
		return [Color("e6eeff"), Color("8fb0ff")]
	var f: Array = GD.SPECS[spec]["fx"]
	return [Color(String(f[0])), Color(String(f[1]))]


func title() -> String:
	if spec == "":
		return "Knight"
	var s: Dictionary = GD.SPECS[spec]
	var n: String = s["name"]
	if adv != "":
		for a in s["advanced"]:
			if a["id"] == adv:
				n = "%s %s" % [a["name"], n]
	return n


# ---------------------------------------------------------------- combat
func heal(v: float, quiet := false) -> void:
	var before := hp
	var s := stats()
	hp = minf(float(s["max_hp"]), hp + v * float(s["healing"]))
	if not quiet and hp - before >= 1.0:
		main.fx_text.text(position, "+%d" % int(round(hp - before)), Color("7dff8a"))


func hurt(amount: float, src_level: int, src := "") -> void:
	if dead:
		return
	if invuln > 0.0:
		# rolled or blinked through it
		if evade_t > 0.0 and evade_msg <= 0.0:
			main.fx_text.text(position, "Evade", Color("bfe3ff"))
			evade_msg = 1.0
		return
	if src != "":
		last_attacker = src
	var s := stats()
	if randf() < float(s["dodge"]):
		main.fx_text.text(position, "Dodge", Color("cfe0ff"))
		main.audio.play("dodge")
		return
	var armor: float = s["armor"]
	var red: float = armor / (armor + 40.0 + 12.0 * src_level)
	var d: int = maxi(1, roundi(amount * (1.0 - red) * randf_range(0.9, 1.1)))
	hp -= d
	last_hurt = clock
	main.audio.play("hurt")
	main.hurt_flash = 0.35
	main.shake = maxf(main.shake, 4.0)
	main.fx_text.text(position, "-%d" % d, Color("ff5a5a"))
	if hp > 0.0 and swinging <= 0.0 and dash.is_empty():
		_play_action("hit", 0.32)   # flinch, unless mid-swing or charging
	if hp <= 0.0:
		hp = 0.0
		dead = true
		path = PackedVector2Array()
		target = null
		main.on_player_died()


func damage_enemy(e: Node2D, base: float, opt: Dictionary = {}) -> void:
	if e.dead_t >= 0.0:
		return
	var s := stats()
	var crit: bool = randf() < float(s["crit"])
	var d: float = base * randf_range(0.9, 1.1)
	if rally > 0.0:
		d *= 1.0 + float(GD.BASE["s3"]["dmg_buff"])
	if crit:
		d *= float(s["crit_mult"])
	var amount: int = maxi(1, roundi(d))
	amount = e.take_hit(amount, crit, position, opt)   # 0 when a ward blocks it
	if amount <= 0:
		main.audio.play("dodge", 0.08)
		return
	main.audio.play("crit" if crit else "hit", 0.08)
	if float(s["life_hit"]) > 0.0:
		heal(float(s["life_hit"]), true)
	if spec != "":
		var p: Dictionary = GD.SPECS[spec]["passive"]
		if p.has("heal_on_hit"):
			heal(float(s["max_hp"]) * float(p["heal_on_hit"]), true)
		if p.has("lifesteal"):
			heal(amount * float(p["lifesteal"]) * float(s["m"]["lifesteal_mult"]), true)
	var burn: float = opt.get("burn", 0.0)
	if burn > 0.0:
		e.burn = 3.0
		e.burn_dps = maxf(e.burn_dps, burn * float(s["dmg"]) * float(s["m"]["burn_mult"]) / 3.0)
	if e.hp <= 0.0:
		main.kill_enemy(e)


func _hit_arc(range_u: float, arc: float, mult: float, ang: float, opt: Dictionary) -> int:
	var n := 0
	var base: float = float(stats()["dmg"]) * mult
	for e in main.enemies.duplicate():
		if e.dead_t >= 0.0:
			continue
		var gv := GD.ground(position, e.position)
		var d := gv.length()
		if d > range_u + e.rad:
			continue
		if d > 0.5 and absf(angle_difference(gv.angle(), ang)) > arc / 2.0:
			continue
		damage_enemy(e, base, opt)
		n += 1
	return n


## Uses the skill in a slot ("basic", "s1".."s4"), aimed at a painting position.
func use_skill(slot: String, aim: Vector2) -> bool:
	if dead or get_tree().paused:
		return false
	var sk := skill_def(slot)
	if sk.is_empty():
		return false
	if float(cds.get(slot, 0.0)) > 0.0:
		return false
	var s := stats()
	var mana: float = sk["mana"]
	if mana > 0.0 and mp < mana:
		if mana_warn <= 0.0:
			mana_warn = 1.0
			main.hud.toast("Not enough mana", Color("8fb0ff"), true)
		return false
	mp = clampf(mp - mana, 0.0, float(s["max_mp"]))
	# Attack speed shortens the basic attack; cooldown reduction shortens skills.
	var full: float = float(sk["cd"]) / (1.0 + float(s["atk_speed"])) if slot == "basic" else float(sk["cd"]) * (1.0 - float(s["cdr"]))
	cds[slot] = full
	cd_full[slot] = full

	var gv := GD.ground(position, aim)
	var ang := gv.angle()
	_face(aim - position)
	var cols := fx_colors()
	var c1: Color = cols[0]
	var c2: Color = cols[1]
	# Specialization skills are magical, so Intelligence adds to them.
	var spec_mult: float = (1.0 + float(s["m"]["spec_dmg"])) * (1.0 + float(s["spell"])) if slot == "s4" else 1.0
	attack_anim = 0.22
	lunge = Vector2.ZERO

	match String(sk["type"]):
		"melee":
			attack_anim = ATTACK_TIME / _aspd()
			_swing(func() -> void:
				main.fx_ground.slash(position, ang, sk["range"], sk["arc"], 0.2, c2, 0.35)
				if _hit_arc(sk["range"], sk["arc"], sk["dmg"], ang, {"colors": [c1, Color.WHITE]}) > 0:
					main.shake = maxf(main.shake, 2.0))
		"arc":
			attack_anim = ATTACK_TIME / _aspd()
			var burn := 0.0
			if spec != "" and GD.SPECS[spec]["passive"].has("cleave_burn"):
				burn = 0.35
			_swing(func() -> void:
				main.fx_ground.slash(position, ang, sk["range"], sk["arc"], 0.28, c2, 0.7)
				_hit_arc(sk["range"], sk["arc"], sk["dmg"], ang, {"kb": 0.3, "burn": burn, "colors": [c1, c2]})
				main.shake = maxf(main.shake, 4.0))
		"dash":
			var d: float = clampf(gv.length(), 1.5, float(sk["range"]))
			swinging = 0.0
			main.audio.play("charge", 0.03)
			dash = {"dir": gv.normalized(), "left": d, "hit": [], "mult": float(sk["dmg"])}
			invuln = 0.35
			path = PackedVector2Array()
			target = null
		"buff":
			_play_action("cast", 0.55)
			heal(float(s["max_hp"]) * (float(sk["heal"]) + float(s["m"]["rally_heal"])))
			rally = sk["duration"]
			main.audio.play("rally", 0.0)
			main.fx_ground.ring(position, 0.3, 3.2, 0.6, c1)
			main.fx_ground.pillar(position, 0.8, c1)
		"nova":
			_play_action("cast", 0.5)
			var radius: float = float(sk["radius"]) * (1.0 + float(s["m"]["spec_radius"]))
			main.fx_ground.ring(position, 0.3, radius, 0.45, c2, true)
			main.audio.play("harvest", 0.03)
			main.fx_ground.ring(position, radius, 0.2, 0.5, c1)
			var n := _hit_arc(radius, 7.0, float(sk["dmg"]) * spec_mult, ang, {"kb": 0.5, "colors": [c1, c2]})
			if n > 0 and sk.has("heal_per_hit"):
				heal(float(s["max_hp"]) * float(sk["heal_per_hit"]) * n)
			main.shake = maxf(main.shake, 6.0)
		"cone":
			_play_action("cast", 0.5)
			main.audio.play("fire", 0.04)
			var fire := [Color("fff2b0"), Color("ffb347"), Color("ff6a1f"), Color("ff3b1f")]
			for i in 70:
				var a: float = ang + randf_range(-0.5, 0.5) * float(sk["arc"])
				var sp: float = randf_range(4.0, 11.0)
				main.fx_parts.spark(position + GD.to_px(Vector2(cos(ang), sin(ang)) * 0.4), Vector2(cos(a), sin(a)) * sp,
					90.0, randf_range(-20.0, 80.0), 0.0, randf_range(0.3, 0.55), fire[randi() % 4], randf_range(6.0, 13.0), 1.6)
			_hit_arc(sk["range"], sk["arc"], float(sk["dmg"]) * spec_mult, ang, {"burn": float(sk["burn"]), "kb": 0.2, "colors": [fire[1], fire[2]]})
			main.shake = maxf(main.shake, 4.0)
		"ground":
			_play_action("cast", 0.5)
			var reach: float = minf(gv.length(), 7.0)
			var at: Vector2 = position + GD.to_px(gv.normalized() * reach)
			var radius2: float = sk["radius"]
			var mult: float = float(sk["dmg"]) * spec_mult
			main.fx_ground.hammer(at, radius2, sk["delay"], c1, c2, func() -> void:
				main.shake = 10.0
				main.audio.play("boom", 0.04)
				var base: float = float(stats()["dmg"]) * mult
				for e in main.enemies.duplicate():
					if e.dead_t < 0.0 and GD.gdist(e.position, at) < radius2 + e.rad:
						damage_enemy(e, base, {"kb": 0.7, "colors": [c1, c2]})
				main.fx_parts.burst(at, 50, [c1, c2, Color.WHITE], 6.0, 20.0, 9.0, 1.0))
	return true


func drink_potion() -> void:
	if dead:
		return
	if potions <= 0:
		main.hud.toast("No potions", Color.WHITE, true)
		return
	var max_hp: float = stats()["max_hp"]
	if hp >= max_hp:
		return
	potions -= 1
	main.audio.play("potion")
	heal(max_hp * 0.45)
	main.fx_parts.burst(position, 14, [Color("ff8a8a"), Color.WHITE], 2.0, 80.0)


func gain_xp(v: int) -> void:
	if level >= GD.MAX_LEVEL:
		return
	xp += v
	while level < GD.MAX_LEVEL and xp >= GD.xp_need(level):
		xp -= GD.xp_need(level)
		level_up()
	if level >= GD.MAX_LEVEL:
		xp = 0


func level_up() -> void:
	if level >= GD.MAX_LEVEL:
		return
	level += 1
	var s := stats()
	hp = s["max_hp"]
	mp = s["max_mp"]
	main.on_level_up()


func respawn(at: Vector2) -> void:
	dead = false
	var s := stats()
	hp = s["max_hp"]
	mp = s["max_mp"]
	position = at
	path = PackedVector2Array()
	target = null
	invuln = 2.0


# ---------------------------------------------------------------- input and movement
func _unhandled_input(event: InputEvent) -> void:
	if dead or get_tree().paused:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			mouse_held = mb.pressed
			if mb.pressed:
				var at := get_global_mouse_position()
				var e: Node2D = main.pick_enemy(at)
				going_to_merchant = false
				going_to_memory = null
				main.going_to_portal = false
				if e != null:
					target = e
					path = PackedVector2Array()
				elif main.pick_portal(at):
					# walk to the Waystone; main.gd sends us through on arrival
					target = null
					if main.portal_in_reach():
						main.use_portal()
					else:
						main.going_to_portal = true
						_walk_to(main.waystone.position, true)
				elif main.pick_loot(at) != null:
					# click a loot label: walk over it to pick it up
					target = null
					_walk_to(main.pick_loot(at).position, true)
				elif main.pick_memory(at) != null:
					go_to_memory(main.pick_memory(at))
				elif main.pick_merchant(at):
					talk_to_merchant()
				elif mb.shift_pressed:
					use_bound(4, at)
				else:
					target = null
					_walk_to(at, true)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			use_bound(5, get_global_mouse_position())
	elif event is InputEventKey and event.pressed and not event.echo:
		var at2 := get_global_mouse_position()
		match (event as InputEventKey).keycode:
			KEY_1:
				use_bound(0, at2)
			KEY_2:
				use_bound(1, at2)
			KEY_3:
				use_bound(2, at2)
			KEY_4:
				use_bound(3, at2)
			KEY_E:
				var m: Node2D = main.memory_in_reach()
				if m != null:
					main.lorecast(m)
				elif main.near_merchant():
					main.hud.open_inventory("merchant")
				elif main.portal_in_reach():
					main.use_portal()
			KEY_SPACE:
				evade(at2)
			KEY_Q:
				drink_potion()


# ---------------------------------------------------------------- skill bar bindings
## Uses whatever skill sits in bar slot i (0-3 = keys 1-4, 4 = LMB, 5 = RMB).
func use_bound(i: int, aim: Vector2) -> bool:
	var slot: String = bindings[i] if i < bindings.size() else ""
	if slot == "":
		return false
	if skill_def(slot).is_empty():
		main.hud.toast("Specialization unlocks at level %d" % GD.SPEC_LEVEL, Color.WHITE, true)
		return false
	return use_skill(slot, aim)


## The skill on LMB, used when attacking a clicked enemy (Slash if LMB is empty or locked).
func lmb_skill() -> String:
	var slot: String = bindings[4]
	return slot if slot != "" and not skill_def(slot).is_empty() else "basic"


func can_use(slot: String) -> bool:
	var sk := skill_def(slot)
	if sk.is_empty() or float(cds.get(slot, 0.0)) > 0.0:
		return false
	return float(sk["mana"]) <= 0.0 or mp >= float(sk["mana"])


## How close the knight must be to a target to use a skill on it, in ground units.
func skill_reach(slot: String) -> float:
	var sk := skill_def(slot)
	if sk.is_empty():
		return float(GD.BASE["basic"]["range"])
	match String(sk["type"]):
		"ground":
			return 6.0
		"nova":
			return float(sk["radius"]) * 0.8
		"dash":
			return float(sk["range"]) * 0.8
		"buff":
			return float(GD.BASE["basic"]["range"])
	return float(sk.get("range", GD.BASE["basic"]["range"]))


## Puts a skill in bar slot i. If it's already elsewhere on the bar, the two slots swap.
func bind_skill(i: int, slot: String) -> void:
	var j := bindings.find(slot)
	if j >= 0 and j != i:
		bindings[j] = bindings[i]
	bindings[i] = slot


func swap_bindings(i: int, j: int) -> void:
	var t: String = bindings[i]
	bindings[i] = bindings[j]
	bindings[j] = t


func clear_binding(i: int) -> void:
	bindings[i] = ""


func go_to_memory(m: Node2D) -> void:
	target = null
	going_to_merchant = false
	if GD.gdist(position, m.position) <= main.MEMORY_RANGE:
		main.lorecast(m)
		return
	going_to_memory = m
	_walk_to(m.position, true)


func talk_to_merchant() -> void:
	target = null
	if main.near_merchant():
		main.hud.open_inventory("merchant")
		return
	going_to_merchant = true
	_walk_to(main.MERCHANT_POS + Vector2(40, 30), true)


func _walk_to(goal_px: Vector2, show_marker: bool) -> void:
	var map := get_world_2d().navigation_map
	var goal := NavigationServer2D.map_get_closest_point(map, goal_px)
	var start := NavigationServer2D.map_get_closest_point(map, global_position)
	var p := NavigationServer2D.map_get_path(map, start, goal, true)
	if p.size() < 2:
		return
	path = p
	path_index = 1
	if show_marker:
		_show_marker(goal)


func _physics_process(delta: float) -> void:
	clock += delta
	for k in cds.keys():
		cds[k] = maxf(0.0, float(cds[k]) - delta)
	rally = maxf(0.0, rally - delta)
	invuln = maxf(0.0, invuln - delta)
	attack_anim = maxf(0.0, attack_anim - delta)
	mana_warn = maxf(0.0, mana_warn - delta)
	swinging = maxf(0.0, swinging - delta)
	if pending_t > 0.0:
		pending_t -= delta
		if pending_t <= 0.0 and pending_hit.is_valid() and not dead:
			pending_hit.call()
			pending_hit = Callable()
	evade_msg = maxf(0.0, evade_msg - delta)
	evade_t = maxf(0.0, evade_t - delta)
	sprite.modulate.a = 0.6 if (invuln > 0.0 and dash.is_empty() and rolling.is_empty() and int(clock * 20.0) % 2 == 1) else 1.0
	if dead:
		swinging = 0.0
		pending_t = 0.0
		if not String(sprite.animation).begins_with("death"):
			if not _play_action("death", 0.0):
				_play("idle")
				sprite.stop()
		if not String(sprite.animation).begins_with("death"):
			# no death animation: topple over
			var side := -1.0 if sprite.flip_h else 1.0
			sprite.rotation = move_toward(sprite.rotation, 1.35 * side, 3.0 * delta)
		sprite.modulate = sprite.modulate.lerp(Color(0.6, 0.5, 0.55, 1.0), 1.5 * delta)
		return
	sprite.rotation = 0.0
	if sprite.modulate.r < 0.99:
		sprite.modulate = Color(1, 1, 1, sprite.modulate.a)
	var s := stats()
	mp = minf(float(s["max_mp"]), mp + float(s["mana_regen"]) * delta)
	hp = minf(float(s["max_hp"]), hp + float(s["max_hp"]) * (0.012 if clock - last_hurt > 4.0 else 0.002) * delta)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		mouse_held = false

	# Dodge roll: travel along the ground, stopping at walls
	if not rolling.is_empty():
		var rstep: float = minf(float(rolling["left"]), float(rolling["speed"]) * delta)
		var rdir: Vector2 = rolling["dir"]
		var rnp := position + GD.to_px(rdir * rstep)
		var rcp := NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, rnp)
		if rcp.distance_to(rnp) < 6.0:
			position = rnp
			rolling["left"] = float(rolling["left"]) - rstep
		else:
			position = rcp
			rolling["left"] = 0.0
		if randf() < 0.5:
			main.fx_parts.spark(position + Vector2(randf_range(-16, 16), -4), Vector2.ZERO, randf_range(10, 50), 20.0, 0.0, 0.35, Color(0.85, 0.8, 0.7, 0.7), 7.0)
		if float(rolling["left"]) <= 0.0:
			rolling = {}
		return

	# Shield Charge
	if not dash.is_empty():
		var step: float = minf(float(dash["left"]), 16.0 * delta)
		var dir: Vector2 = dash["dir"]
		var np := position + GD.to_px(dir * step)
		var cp := NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, np)
		if cp.distance_to(np) < 6.0:
			position = np
			dash["left"] = float(dash["left"]) - step
		else:
			dash["left"] = 0.0
		main.fx_parts.spark(position, Vector2.ZERO, randf_range(20, 120), 0.0, 0.0, 0.3, fx_colors()[1], 9.0)
		var hit: Array = dash["hit"]
		for e in main.enemies.duplicate():
			if e.dead_t < 0.0 and not hit.has(e) and GD.gdist(position, e.position) < 1.1 + e.rad:
				hit.append(e)
				damage_enemy(e, float(s["dmg"]) * float(dash["mult"]), {"kb": 0.8, "stun": 1.0, "colors": fx_colors()})
		if float(dash["left"]) <= 0.0:
			dash = {}
			main.shake = maxf(main.shake, 5.0)
			main.fx_ground.ring(position, 0.2, 1.8, 0.3, fx_colors()[0])
		_play("walk")
		return

	# Walking over to a memory after clicking it
	if going_to_memory != null:
		if not is_instance_valid(going_to_memory):
			going_to_memory = null
		elif GD.gdist(position, going_to_memory.position) <= main.MEMORY_RANGE:
			var m := going_to_memory
			going_to_memory = null
			path = PackedVector2Array()
			main.lorecast(m)
		elif path_index >= path.size():
			going_to_memory = null

	# Walking over to the merchant after clicking her
	if going_to_merchant:
		if main.near_merchant():
			going_to_merchant = false
			path = PackedVector2Array()
			_face(main.MERCHANT_POS - position)
			main.hud.open_inventory("merchant")
		elif path_index >= path.size():
			going_to_merchant = false

	# Chasing and attacking a clicked enemy
	if target != null:
		if not is_instance_valid(target) or target.dead_t >= 0.0:
			target = null
			if mouse_held:
				target = main.pick_enemy(get_global_mouse_position())
		else:
			# attack with the skill on LMB; Slash fills in while it is on cooldown or short of mana
			var lmb: String = lmb_skill()
			var reach: float = skill_reach(lmb) + target.rad - 0.15
			var basic_reach: float = float(GD.BASE["basic"]["range"]) + target.rad - 0.15
			var dist := GD.gdist(position, target.position)
			if dist <= reach and can_use(lmb):
				path = PackedVector2Array()
				use_skill(lmb, target.position)
			elif dist <= basic_reach:
				path = PackedVector2Array()
				if lmb != "basic" and can_use("basic"):
					use_skill("basic", target.position)
				else:
					_face(target.position - position)
				if not mouse_held and attack_anim <= 0.0 and float(cds.get("basic", 0.0)) > 0.0:
					pass  # keep the target until it dies or the player clicks elsewhere
			else:
				repath -= delta
				if repath <= 0.0 or path_index >= path.size():
					repath = 0.25
					_walk_to(target.position, false)
	elif mouse_held:
		# Holding the button keeps steering toward the cursor, as in other ARPGs.
		if Input.is_key_pressed(KEY_SHIFT):
			use_skill("basic", get_global_mouse_position())
			path = PackedVector2Array()
		elif Engine.get_physics_frames() % 6 == 0:
			_walk_to(get_global_mouse_position(), false)

	if path_index >= path.size() or attack_anim > 0.05:
		_play("idle")
		idle_time += delta
		if swinging <= 0.0:
			sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE * (1.0 + 0.008 * sin(idle_time * 2.2)))
		return

	idle_time = 0.0
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	var remaining := SPEED * (1.0 + float(stats()["move"])) * delta
	while remaining > 0.0 and path_index < path.size():
		var to: Vector2 = path[path_index] - global_position
		# Convert the on-screen offset into "ground" distance.
		var ground := Vector2(to.x, to.y / DEPTH_SQUASH)
		var dist := ground.length()
		if dist < 0.5:
			path_index += 1
			continue
		_face(to)
		if dist <= remaining:
			global_position = path[path_index]
			path_index += 1
			remaining -= dist
		else:
			var step2 := ground / dist * remaining
			global_position += Vector2(step2.x, step2.y * DEPTH_SQUASH)
			remaining = 0.0
	_play("walk" if path_index < path.size() else "idle")


func _face(dir: Vector2) -> void:
	if dir.length() < 1.0:
		return
	var a := Vector2(dir.x, dir.y / DEPTH_SQUASH).angle()
	facing = posmod(int(round(a / (PI / 4.0))), 8)


func _show_marker(at: Vector2) -> void:
	if marker and is_instance_valid(marker):
		marker.queue_free()
	marker = ClickMarker.new()
	marker.global_position = at
	get_parent().get_parent().add_child(marker)


class ClickMarker extends Node2D:
	var t := 0.0
	func _ready() -> void:
		z_index = -5
	func _process(delta: float) -> void:
		t += delta
		if t > 0.6:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var k := t / 0.6
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		draw_arc(Vector2.ZERO, 14.0 + 26.0 * k, 0.0, TAU, 40, Color(1.0, 0.86, 0.4, 1.0 - k), 4.0, true)
		draw_arc(Vector2.ZERO, 6.0 + 10.0 * k, 0.0, TAU, 24, Color(1, 1, 1, 0.8 * (1.0 - k)), 2.0, true)
