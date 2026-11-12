extends Node2D
## Crownfall plaza: painted background, walkable area, depth-sorted props, the
## knight, and the combat loop (Reality Scar waves, loot, levels, quests, saving).

const GD := preload("res://scripts/game_data.gd")
const PLAZA := preload("res://assets/plaza.png")
const Player := preload("res://scripts/player.gd")
const Enemy := preload("res://scripts/enemy.gd")
const Loot := preload("res://scripts/loot.gd")
const Fx := preload("res://scripts/fx.gd")
const Inv := preload("res://scripts/inventory_logic.gd")
const Hud := preload("res://scripts/hud.gd")
const SAVE_PATH := "user://aotl_save.json"

## Outline of the floor the knight may walk on, in plaza image pixels.
const WALKABLE := [
	Vector2(990, 725), Vector2(990, 520), Vector2(860, 400), Vector2(860, 350),
	Vector2(1040, 340), Vector2(1100, 390), Vector2(1190, 540), Vector2(1200, 640),
	Vector2(1320, 712), Vector2(1400, 695), Vector2(1540, 795), Vector2(1625, 815),
	Vector2(1700, 885), Vector2(1670, 960), Vector2(1670, 1155), Vector2(1780, 1165),
	Vector2(1780, 1340), Vector2(1990, 1345), Vector2(2010, 1300), Vector2(2300, 1500),
	Vector2(2340, 1536), Vector2(1820, 1536), Vector2(1820, 1500), Vector2(1665, 1480),
	Vector2(1640, 1420), Vector2(1520, 1420), Vector2(1440, 1440), Vector2(1420, 1380),
	Vector2(1372, 1380), Vector2(1368, 1258), Vector2(1300, 1215), Vector2(1140, 1215),
	Vector2(1010, 1200), Vector2(800, 1100), Vector2(820, 1010), Vector2(930, 1005),
	Vector2(930, 880), Vector2(870, 850), Vector2(880, 740),
]

## Props cut from the painting that must draw in front of the knight when he
## stands behind them. "base" is the ground line of the prop (image y).
const OCCLUDERS := [
	{"base": 1700.0, "points": [Vector2(840, 1040), Vector2(1010, 1090), Vector2(1010, 1105), Vector2(1135, 1095), Vector2(1140, 1210), Vector2(1210, 1185), Vector2(1300, 1195), Vector2(1368, 1255), Vector2(1372, 1375), Vector2(1420, 1375), Vector2(1425, 1440), Vector2(1520, 1445), Vector2(1525, 1536), Vector2(840, 1536)]},
	{"base": 1700.0, "points": [Vector2(1690, 1300), Vector2(1740, 1270), Vector2(1795, 1300), Vector2(1800, 1440), Vector2(1770, 1470), Vector2(1770, 1536), Vector2(1715, 1536), Vector2(1715, 1470), Vector2(1685, 1440)]},
	{"base": 1700.0, "points": [Vector2(1510, 1445), Vector2(1580, 1415), Vector2(1660, 1440), Vector2(1670, 1536), Vector2(1505, 1536)]},
	{"base": 1335.0, "points": [Vector2(1790, 1160), Vector2(1850, 1060), Vector2(1960, 1040), Vector2(2010, 1100), Vector2(2010, 1330), Vector2(1900, 1345), Vector2(1785, 1335)]},
	{"base": 1150.0, "points": [Vector2(1705, 600), Vector2(1795, 600), Vector2(1795, 960), Vector2(1800, 1150), Vector2(1680, 1150), Vector2(1680, 975), Vector2(1715, 960)]},
	{"base": 715.0, "points": [Vector2(815, 560), Vector2(850, 500), Vector2(950, 500), Vector2(975, 560), Vector2(975, 710), Vector2(900, 720), Vector2(815, 690)]},
	{"base": 705.0, "points": [Vector2(1210, 560), Vector2(1260, 510), Vector2(1330, 520), Vector2(1390, 570), Vector2(1390, 705), Vector2(1320, 705), Vector2(1320, 630), Vector2(1215, 625)]},
]

const START := Vector2(1350, 1020)
## Where the Reality Scar opens: the centre of the engraved circle.
const RIFT_POS := Vector2(1290, 1010)
## Where the merchant stands: top of the market steps on the left of the plaza.
const MERCHANT_POS := Vector2(918, 792)
const MERCHANT_RANGE := 1.6   # ground units
const MEMORY_RANGE := 1.4
const MemoryPoint := preload("res://scripts/memory_point.gd")

var world: Node2D
var player: Node2D
var cam: Camera2D
var hud: CanvasLayer
var fx_ground: Node2D
var fx_parts: Node2D
var fx_text: Node2D
var nav_region: NavigationRegion2D
var debug_draw := false

var enemies: Array = []
var loot: Array = []
var open_points: Array[Vector2] = []
var hover_enemy: Node2D = null
var merchant: Node2D
var memories: Array = []   # memory points in the plaza
var audio: Node
## Maren's gear for sale. Restocked on level-up and when the Scar closes after a cleared wave.
var shop: Array = []
var shop_level := 0
const SHOP_SIZE := 6
## The Reality Scar: a placeholder combat arena. Waves of the Unwritten spawn while it is open.
var rift := {"active": false, "wave": 0, "timer": 0.0, "cleared": true}
var shake := 0.0
var hurt_flash := 0.0
var save_timer := 0.0
var had_save := false
var full_warn := 0.0


func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = PLAZA
	bg.centered = false
	bg.z_index = -10
	add_child(bg)

	_build_navigation()

	fx_ground = _make_fx(Fx.GROUND, -4)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	for o in OCCLUDERS:
		world.add_child(_make_occluder(o))

	player = Player.new()
	player.main = self
	player.position = START
	world.add_child(player)

	merchant = Node2D.new()
	merchant.set_script(load("res://scripts/npc.gd"))
	merchant.tex = load("res://assets/npc/merchant.png")
	merchant.title = "Maren"
	merchant.role = "Merchant  ·  click to trade"
	merchant.position = MERCHANT_POS
	world.add_child(merchant)

	for id in GD.LORE:
		if GD.LORE[id].has("pos"):
			_add_memory(id, GD.LORE[id]["pos"])

	cam = Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = PLAZA.get_width()
	cam.limit_bottom = PLAZA.get_height()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	player.add_child(cam)
	cam.make_current()

	audio = Node.new()
	audio.set_script(load("res://scripts/audio.gd"))
	add_child(audio)
	fx_parts = _make_fx(Fx.PARTICLES, 100)
	fx_text = _make_fx(Fx.TEXT, 101)

	had_save = load_game()
	if not had_save:
		# Starting kit so the inventory has something to try straight away.
		for it in [GD.starter_item("weapon", "Recruit's Sword", {"dmg": 3.0}), GD.starter_item("armor", "Worn Chainmail", {"armor": 8.0, "hp": 5.0}),
				GD.starter_item("helm", "Dented Barbute", {"armor": 4.0}), GD.starter_item("ring", "Copper Band", {"dmg": 1.0})]:
			Inv.add(player.bag, Inv.BAG_COLS, Inv.BAG_ROWS, it)
	var s: Dictionary = player.stats()
	player.hp = s["max_hp"]
	player.mp = s["max_mp"]

	audio.play_music("plaza")
	hud = Hud.new()
	hud.main = self
	hud.player = player
	add_child(hud)

	if OS.get_cmdline_user_args().has("--autotest"):
		var t := Node.new()
		t.set_script(load("res://scripts/dev_test.gd"))
		t.set("main", self)
		add_child(t)
	else:
		check_choice.call_deferred()


func _make_fx(mode: int, z: int) -> Node2D:
	var f := Node2D.new()
	f.set_script(Fx)
	f.mode = mode
	f.main = self
	f.z_index = z
	add_child(f)
	return f


func _build_navigation() -> void:
	var poly := NavigationPolygon.new()
	var verts := PackedVector2Array(WALKABLE)
	poly.vertices = verts
	var tris := Geometry2D.triangulate_polygon(verts)
	for i in range(0, tris.size(), 3):
		poly.add_polygon(PackedInt32Array([tris[i], tris[i + 1], tris[i + 2]]))
	nav_region = NavigationRegion2D.new()
	nav_region.navigation_polygon = poly
	add_child(nav_region)
	# Spawn points: floor positions with some room around them.
	for y in range(360, 1520, 40):
		for x in range(820, 2320, 40):
			var p := Vector2(x, y)
			var ok := true
			for off in [Vector2.ZERO, Vector2(55, 0), Vector2(-55, 0), Vector2(0, 40), Vector2(0, -40)]:
				if not Geometry2D.is_point_in_polygon(p + off, verts):
					ok = false
			if ok:
				open_points.append(p)


func _make_occluder(o: Dictionary) -> Polygon2D:
	var p := Polygon2D.new()
	var base: float = o["base"]
	var pts := PackedVector2Array(o["points"])
	var local := PackedVector2Array()
	for v in pts:
		local.append(v - Vector2(0, base))
	p.position = Vector2(0, base)
	p.polygon = local
	p.uv = pts
	p.texture = PLAZA
	return p


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				save_game()
				quit_game()
			KEY_F11:
				var w := get_window()
				w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
			KEY_F3:
				debug_draw = not debug_draw
				queue_redraw()
			KEY_R:
				toggle_rift()
			KEY_M:
				audio.toggle_mute()
				hud.toast("Sound off" if audio.muted else "Sound on", Color.WHITE, true)
			KEY_L:
				# Tester shortcut: gain a level instantly.
				player.xp = 0
				player.level_up()


func _draw() -> void:
	if not debug_draw:
		return
	var pts := PackedVector2Array(WALKABLE)
	pts.append(WALKABLE[0])
	draw_polyline(pts, Color(0, 1, 0, 0.9), 3.0)
	for o in OCCLUDERS:
		var op := PackedVector2Array(o["points"])
		op.append(o["points"][0])
		draw_polyline(op, Color(1, 0, 0, 0.9), 2.0)


# ---------------------------------------------------------------- frame loop
func _process(delta: float) -> void:
	shake = maxf(0.0, shake - delta * 25.0)
	hurt_flash = maxf(0.0, hurt_flash - delta)
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 2.0

	# Reality Scar waves
	if rift["active"] and not player.dead:
		var alive := false
		for e in enemies:
			if e.dead_t < 0.0:
				alive = true
		if not alive:
			if int(rift["wave"]) > 0 and not rift["cleared"]:
				rift["cleared"] = true
				rift["timer"] = 3.0
				hud.toast("Wave %d cleared" % int(rift["wave"]), Color("8fd18a"), true)
				save_game()
			rift["timer"] = float(rift["timer"]) - delta
			if float(rift["timer"]) <= 0.0:
				spawn_wave()
		if randf() < 0.5:
			fx_parts.spark(RIFT_POS + GD.to_px(Vector2(randf_range(-1.4, 1.4), randf_range(-1.4, 1.4))), Vector2.ZERO, 0.0, randf_range(60, 180), -20.0, randf_range(0.6, 1.2), Color("c9a8ff") if randf() < 0.5 else Color("7a4dff"), randf_range(3, 6))

	# Keep enemies from stacking on each other or on the knight.
	var n := enemies.size()
	for i in n:
		var a: Node2D = enemies[i]
		if a.dead_t >= 0.0:
			continue
		for j in range(i + 1, n):
			var b: Node2D = enemies[j]
			if b.dead_t >= 0.0:
				continue
			var g := GD.ground(a.position, b.position)
			var d := g.length()
			var m: float = a.rad + b.rad
			if d < m and d > 0.001:
				var push := g / d * (m - d) * 0.5
				a._move(-push)
				b._move(push)
		var gp := GD.ground(player.position, a.position)
		var dp := gp.length()
		var mp: float = a.rad + 0.3
		if dp < mp and dp > 0.001:
			a._move(gp / dp * (mp - dp))

	# Loot is picked up by walking over it.
	for i in range(loot.size() - 1, -1, -1):
		var l: Node2D = loot[i]
		if l.age < 0.35 or player.dead:
			continue
		if l.wait_leave:
			if GD.gdist(l.position, player.position) > 1.6:
				l.wait_leave = false
			continue
		if GD.gdist(l.position, player.position) < (1.3 if l.kind == "gold" else 0.9):
			if l.kind == "item" and not Inv.add(player.bag, Inv.BAG_COLS, Inv.BAG_ROWS, l.item):
				# No room: the item stays on the ground until space is made.
				if full_warn <= 0.0:
					full_warn = 4.0
					hud.toast("Backpack is full", Color("ff8a8a"), true)
				continue
			loot.remove_at(i)
			_pick_up(l)
			l.queue_free()
	full_warn = maxf(0.0, full_warn - delta)

	hover_enemy = pick_enemy(get_global_mouse_position())
	var mouse := get_global_mouse_position()
	var hm: Node2D = pick_memory(mouse) if hover_enemy == null else null
	for m in memories:
		m.hovered = m == hm
	merchant.hovered = hover_enemy == null and hm == null and pick_merchant(mouse)
	save_timer += delta
	if save_timer > 10.0:
		save_timer = 0.0
		save_game()


func restock_shop() -> void:
	shop.clear()
	shop_level = player.level
	for i in SHOP_SIZE:
		# Mostly magic and rare; legendaries are rare at the shop, as in Diablo.
		shop.append(GD.make_item(maxi(1, player.level + randi_range(-1, 1)), 0.25))


# ---------------------------------------------------------------- Lorecasting
func _add_memory(id: String, at: Vector2) -> Node2D:
	var m := Node2D.new()
	m.set_script(MemoryPoint)
	m.lore_id = id
	m.main = self
	m.position = at
	m.z_index = -3
	world.add_child(m)
	memories.append(m)
	return m


func pick_memory(at: Vector2) -> Node2D:
	for m in memories:
		if m.pick_rect().has_point(at):
			return m
	return null


func memory_in_reach() -> Node2D:
	var best: Node2D = null
	for m in memories:
		var d := GD.gdist(player.position, m.position)
		if d <= MEMORY_RANGE and (best == null or d < GD.gdist(player.position, best.position)):
			best = m
	return best


## Reads a memory. The first time, it is added to the journal and grants experience.
func lorecast(m: Node2D) -> void:
	var id: String = m.lore_id
	var first: bool = not player.lore.has(id)
	if first:
		player.lore.append(id)
		var xp := roundi(GD.xp_need(player.level) * GD.LORE_XP)
		player.gain_xp(xp)
		fx_text.text(player.position, "+%d XP" % xp, Color("c9a8ff"))
		fx_ground.pillar(m.position, 1.4, Color("b48cff"))
		fx_ground.ring(m.position, 0.2, 2.4, 0.9, Color("d9c2ff"))
		fx_parts.burst(m.position, 30, [Color("e6d8ff"), Color("b48cff"), Color("ffe9a8")], 2.5, 30.0, 7.0, 1.4)
		audio.play("lorecast", 0.0)
		save_game()
	hud.show_lore(id, first)
	# An elite's echo fades once it has been read.
	if not GD.LORE[id].has("pos"):
		memories.erase(m)
		m.queue_free()


func pick_merchant(at: Vector2) -> bool:
	return merchant.pick_rect().has_point(at)


func near_merchant() -> bool:
	return GD.gdist(player.position, MERCHANT_POS) <= MERCHANT_RANGE


func pick_enemy(at: Vector2) -> Node2D:
	var best: Node2D = null
	var bd := 1e9
	for e in enemies:
		if e.dead_t >= 0.0:
			continue
		var h: float = e.height()
		var w: float = h * 0.45
		var p: Vector2 = e.position
		if at.x > p.x - w and at.x < p.x + w and at.y > p.y - h and at.y < p.y + 16.0:
			var d: float = absf(at.y - (p.y - h / 2.0)) + absf(at.x - p.x)
			if d < bd:
				bd = d
				best = e
	return best


# ---------------------------------------------------------------- enemies and the rift
func spawn_enemy(key: String, elite: bool, at: Vector2) -> void:
	var e := Node2D.new()
	e.set_script(Enemy)
	e.main = self
	e.player = player
	e.position = at
	e.setup(key, elite, player.level)
	world.add_child(e)
	enemies.append(e)
	fx_ground.pillar(at, 0.8, Color("a070ff"))
	fx_parts.burst(at, 14, [Color("c9a8ff"), Color("7a4dff")], 3.0, 40.0)


func _spawn_point() -> Vector2:
	for i in 80:
		var c: Vector2 = open_points[randi() % open_points.size()]
		var d := GD.gdist(c, player.position)
		if d > 3.5 and d < 10.0:
			return c
	return open_points[randi() % open_points.size()]


func spawn_wave() -> void:
	rift["wave"] = int(rift["wave"]) + 1
	rift["cleared"] = false
	var wave: int = rift["wave"]
	hud.toast("Wave %d" % wave, Color("c9a8ff"))
	audio.play("wave", 0.0)
	shake = maxf(shake, 4.0)
	for i in mini(3 + wave, 9):
		var r := randf()
		var key := "slime"
		if r < minf(0.4, 0.15 + wave * 0.03):
			key = "brute"
		elif r < 0.65:
			key = "revenant"
		spawn_enemy(key, false, _spawn_point())
	if wave % 3 == 0:
		spawn_enemy("brute" if randf() < 0.5 else "revenant", true, _spawn_point())


func toggle_rift() -> void:
	if player.dead or get_tree().paused:
		return
	if rift["active"]:
		close_rift("The Scar Closes")
		return
	rift = {"active": true, "wave": 0, "timer": 1.8, "cleared": true}
	player.opened_rift = true
	hud.banner("Reality Scar", "The Unwritten are breaking through")
	audio.play("rift_open", 0.0)
	audio.play_music("scar")
	shake = 7.0
	update_quests()


func close_rift(msg := "") -> void:
	if not rift["active"]:
		return
	rift["active"] = false
	audio.play("rift_close", 0.0)
	audio.play_music("plaza")
	if int(rift["wave"]) > 1 or (int(rift["wave"]) == 1 and rift["cleared"]):
		restock_shop()
	for e in enemies:
		if e.dead_t < 0.0:
			e.dead_t = 0.0
			fx_parts.burst(e.position, 12, [Color("c9a8ff"), Color("7a4dff")], 3.0, 60.0)
	enemies.clear()
	if msg != "":
		hud.banner(msg, "You reached wave %d" % int(rift["wave"]) if int(rift["wave"]) > 0 else "")


func kill_enemy(e: Node2D) -> void:
	if e.dead_t >= 0.0:
		return
	e.dead_t = 0.0
	e.hp = 0.0
	enemies.erase(e)
	player.kills += 1
	audio.play("enemy_die", 0.1)
	# The first elite you defeat leaves an echo of who it used to be.
	if e.elite and not player.lore.has("echo_elite") and not memories.any(func(m): return m.lore_id == "echo_elite"):
		_add_memory("echo_elite", e.position)
		hud.toast("Something lingers where it fell...", Color("d9c2ff"))
	if e.elite:
		player.elite_kills += 1
		shake = 9.0
	var cols: Array = [Color("a77bff"), Color("5a2f9a"), Color("ffe86a")]
	if e.type_key == "brute":
		cols = [Color("7a8a3a"), Color("c9b06a"), Color("3a2a18")]
	elif e.type_key == "revenant":
		cols = [Color("8a90b8"), Color("2b2f45"), Color("c79bff")]
	fx_parts.burst(e.position, 40 if e.elite else 18, cols, 5.0, 60.0, 8.0)
	var xp: int = roundi(GD.xp_need(e.level) / (5.0 + e.level * 0.35) * float(e.t["xp"]) * (3.0 if e.elite else 1.0))
	fx_text.text(e.position + Vector2(0, -30), "+%d XP" % xp, Color("c9a8ff"))
	var gold: int = roundi(randf_range(2, 6) * (1.0 + e.level * 0.4) * (4.0 if e.elite else 1.0))
	_drop(e.position, "gold", gold, {})
	if randf() < 0.13:
		_drop(e.position, "potion", 0, {})
	if e.elite or randf() < 0.3:
		_drop(e.position, "item", 0, GD.make_item(e.level, 0.3 if e.elite else 0.0))
	if e.elite and randf() < 0.5:
		_drop(e.position, "item", 0, GD.make_item(e.level, 0.15))
	player.gain_xp(xp)
	update_quests()


func _drop(at: Vector2, kind: String, amount: int, item: Dictionary) -> void:
	if kind == "item" and int(item.get("rarity", 0)) >= 2:
		audio.play("drop_rare", 0.0)
	var map := get_world_2d().navigation_map
	var p := NavigationServer2D.map_get_closest_point(map, at + GD.to_px(Vector2(randf_range(-0.9, 0.9), randf_range(-0.9, 0.9))))
	var l := Node2D.new()
	l.set_script(Loot)
	l.kind = kind
	l.amount = amount
	l.item = item
	l.position = p
	world.add_child(l)
	loot.append(l)


func _pick_up(l: Node2D) -> void:
	match String(l.kind):
		"gold":
			player.gold += l.amount
			audio.play("gold")
			fx_text.text(player.position, "+%d gold" % l.amount, Color("ffd84a"))
		"potion":
			if player.potions < 5:
				player.potions += 1
				hud.toast("Health Potion", Color("ff8a8a"), true)
			else:
				player.gold += 10
		"item":
			var it: Dictionary = l.item
			var col := Color(String(GD.RARITY[int(it["rarity"])]["color"]))
			# The item is already in the backpack (see the pickup loop in _process).
			audio.play("pickup")
			hud.toast("%s  (I: inventory)" % it["name"], col, int(it["rarity"]) < 2)
			save_game()


# ---------------------------------------------------------------- progression
func on_level_up() -> void:
	var sub := "Your oath grows stronger"
	if player.level == GD.SPEC_LEVEL:
		sub = "Your specialization awaits"
	elif player.level == GD.ADVANCED_LEVEL:
		sub = "An advanced path opens"
	elif player.level == GD.MAX_LEVEL:
		sub = "Heroic Talents unlocked"
	hud.banner("Level %d" % player.level, sub)
	hud.toast("+%d stat points  (C to spend)" % GD.POINTS_PER_LEVEL, Color("ffe9a8"), true)
	audio.play("level_up", 0.0)
	fx_ground.ring(player.position, 0.2, 3.0, 0.7, Color("ffe9a8"))
	fx_ground.pillar(player.position, 1.0, Color("ffe9a8"))
	for i in 40:
		fx_parts.spark(player.position + Vector2(randf_range(-35, 35), randf_range(-20, 20)), Vector2.ZERO, randf_range(0, 40), randf_range(160, 440), -40.0, randf_range(0.8, 1.4), Color("ffe9a8") if randf() < 0.5 else Color.WHITE, randf_range(4, 8))
	update_quests()
	save_game()
	get_tree().create_timer(0.9).timeout.connect(check_choice)


## Opens the next pending class choice, if any.
func check_choice() -> void:
	if hud.choice_open():
		return
	if player.level >= GD.SPEC_LEVEL and player.spec == "":
		hud.open_choice("spec")
	elif player.level >= GD.ADVANCED_LEVEL and player.spec != "" and player.adv == "":
		hud.open_choice("adv")
	elif player.level >= GD.MAX_LEVEL and player.heroic == "":
		hud.open_choice("heroic")


func on_choice_made(kind: String, label: String, color: Color) -> void:
	var sub := "Specialization chosen"
	if kind == "adv":
		sub = "Advanced path chosen"
	elif kind == "heroic":
		sub = "Heroic Talent awakened"
	hud.banner(label, sub)
	fx_ground.pillar(player.position, 1.2, color)
	player.hp = player.stats()["max_hp"]
	update_quests()
	save_game()
	get_tree().create_timer(0.6).timeout.connect(check_choice)


func on_player_died() -> void:
	close_rift()
	hud.show_death()


func respawn() -> void:
	player.respawn(START)


const QUESTS := [
	"A Scar in the Plaza", "The Unwritten", "A Worthy Foe", "The Path Divides", "Tempered Oath", "Heroic Ascension",
]


func _quest_done(i: int) -> bool:
	match i:
		0: return player.opened_rift
		1: return player.kills >= 15
		2: return player.elite_kills >= 1
		3: return player.spec != ""
		4: return player.adv != ""
		5: return player.heroic != ""
	return false


func quest_title() -> String:
	return QUESTS[player.quest] if player.quest < QUESTS.size() else "Legend of Crownsfall"


func quest_text() -> String:
	match player.quest:
		0: return "Open the Reality Scar (press R)"
		1: return "Slay Unwritten (%d/15)" % mini(player.kills, 15)
		2: return "Defeat an elite (appears every third wave)"
		3: return "Reach level %d and choose a specialization (%d/%d)" % [GD.SPEC_LEVEL, player.level, GD.SPEC_LEVEL]
		4: return "Reach level %d (%d/%d)" % [GD.ADVANCED_LEVEL, player.level, GD.ADVANCED_LEVEL]
		5: return "Reach level %d (%d/%d)" % [GD.MAX_LEVEL, player.level, GD.MAX_LEVEL]
	return "All current quests complete."


func update_quests() -> void:
	while player.quest < QUESTS.size() and _quest_done(player.quest):
		hud.toast("Quest complete: %s" % QUESTS[player.quest], Color("8fd18a"))
		player.quest += 1
		player.gain_xp(roundi(GD.xp_need(player.level) * 0.25))


# ---------------------------------------------------------------- saving
## Quits cleanly: stops all sound first so nothing is left playing at exit.
func quit_game() -> void:
	audio.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()


func save_game() -> void:
	var p := player
	var data := {"save_version": 2, "bag": p.bag, "stash": p.stash, "name": p.hero_name, "level": p.level, "xp": p.xp, "gold": p.gold, "potions": p.potions, "kills": p.kills,
		"elite_kills": p.elite_kills, "spec": p.spec, "adv": p.adv, "heroic": p.heroic, "gear": p.gear,
		"opened_rift": p.opened_rift, "quest": p.quest, "spent": p.spent,
		"shop": shop, "shop_level": shop_level, "buyback": p.buyback, "lore": p.lore}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var p := player
	p.hero_name = String(data.get("name", "Wayfarer"))
	p.level = clampi(int(data.get("level", 1)), 1, GD.MAX_LEVEL)
	p.xp = int(data.get("xp", 0))
	p.gold = int(data.get("gold", 0))
	p.potions = int(data.get("potions", 3))
	p.kills = int(data.get("kills", 0))
	p.elite_kills = int(data.get("elite_kills", 0))
	p.spec = String(data.get("spec", ""))
	p.adv = String(data.get("adv", ""))
	p.heroic = String(data.get("heroic", ""))
	if not GD.SPECS.has(p.spec):
		p.spec = ""
		p.adv = ""
	p.opened_rift = bool(data.get("opened_rift", false))
	p.quest = int(data.get("quest", 0))
	# Placed stat points. Older saves have none, so all points earned so far are free to spend.
	for a in p.spent:
		p.spent[a] = 0
	var sp = data.get("spent", {})
	if typeof(sp) == TYPE_DICTIONARY:
		for a in p.spent:
			p.spent[a] = maxi(0, int(sp.get(a, 0)))
	if p.points_free() < 0:
		for a in p.spent:
			p.spent[a] = 0
	var g = data.get("gear", {})
	if typeof(g) == TYPE_DICTIONARY:
		for slot in p.gear.keys():
			var it = g.get(slot)
			p.gear[slot] = it if typeof(it) == TYPE_DICTIONARY else null
	p.bag = _load_grid(data.get("bag"), Inv.BAG_COLS, Inv.BAG_ROWS)
	p.stash = _load_grid(data.get("stash"), Inv.STASH_COLS, Inv.STASH_ROWS)
	shop = _load_items(data.get("shop"), SHOP_SIZE)
	shop_level = int(data.get("shop_level", 0))
	p.buyback = _load_items(data.get("buyback"), 8)
	p.lore = []
	var lr = data.get("lore", [])
	if typeof(lr) == TYPE_ARRAY:
		for id in lr:
			if GD.LORE.has(String(id)) and not p.lore.has(String(id)):
				p.lore.append(String(id))
	return true


## Reads a saved grid. Entries that are malformed or would overlap are re-packed, never dropped silently into overlap.
## Reads a saved list of items (shop stock, buyback), skipping anything malformed.
func _load_items(raw, limit: int) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for it in raw:
		if typeof(it) == TYPE_DICTIONARY and it.has("slot") and it.has("name") and out.size() < limit:
			out.append(it)
	return out


func _load_grid(raw, cols: int, rows: int) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for e in raw:
		if typeof(e) != TYPE_DICTIONARY or typeof(e.get("item")) != TYPE_DICTIONARY or not e["item"].has("slot"):
			continue
		var it: Dictionary = e["item"]
		var x := int(e.get("x", -1))
		var y := int(e.get("y", -1))
		if Inv.can_place(out, cols, rows, it, x, y):
			out.append({"item": it, "x": x, "y": y})
		else:
			Inv.add(out, cols, rows, it)
	return out


func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	get_tree().paused = false
	get_tree().reload_current_scene()
