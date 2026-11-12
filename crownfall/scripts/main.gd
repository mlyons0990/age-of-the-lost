extends Node2D
## Crownfall plaza: painted background, walkable area, depth-sorted props, the
## knight, and the combat loop (Reality Scar waves, loot, levels, quests, saving).

const GD := preload("res://scripts/game_data.gd")
const PLAZA := preload("res://assets/plaza.png")
const Player := preload("res://scripts/player.gd")
const Enemy := preload("res://scripts/enemy.gd")
const Loot := preload("res://scripts/loot.gd")
const Bolt := preload("res://scripts/bolt.gd")
const Hazard := preload("res://scripts/hazard.gd")
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
const Zones := preload("res://scripts/zones.gd")
const Waystone := preload("res://scripts/waystone.gd")

var world: Node2D
var player: Node2D
var cam: Camera2D
var hud: CanvasLayer
var fx_ground: Node2D
var fx_parts: Node2D
var fx_text: Node2D
var nav_region: NavigationRegion2D
var bg: Sprite2D
var zone := "plaza"          # id in zones.gd
var zone_tex: Texture2D = PLAZA
var zone_walk: Array = WALKABLE
var occluder_nodes: Array = []
var waystone: Node2D
var going_to_portal := false
var pack_timer := 2.0         # wild zones: seconds until the next roaming pack
var debug_draw := false

var enemies: Array = []
var bolts_fired := 0   # counters for the self-test
var bolt_hits := 0
var hazard_hits := 0
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
	bg = Sprite2D.new()
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
		var on := _make_occluder(o)
		world.add_child(on)
		occluder_nodes.append(on)
	waystone = Node2D.new()
	waystone.set_script(Waystone)
	waystone.position = Zones.ZONES["plaza"]["portal"]
	waystone.dest_name = Zones.ZONES["whisperwood"]["name"]
	world.add_child(waystone)

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
	# idle loop from the Higgsfield clip (layout from assets/npc/maren_idle.json)
	merchant.anim = {"tex": load("res://assets/npc/maren_idle.png"), "frames": 16, "cols": 6, "cw": 173, "ch": 310, "ax": 86.0, "ay": 305.0, "fps": 5.0}
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
	var verts := PackedVector2Array(zone_walk)
	poly.vertices = verts
	var tris := Geometry2D.triangulate_polygon(verts)
	for i in range(0, tris.size(), 3):
		poly.add_polygon(PackedInt32Array([tris[i], tris[i + 1], tris[i + 2]]))
	if nav_region == null:
		nav_region = NavigationRegion2D.new()
		add_child(nav_region)
	nav_region.navigation_polygon = poly
	# Spawn points: floor positions with some room around them.
	open_points.clear()
	var box := Rect2(verts[0], Vector2.ZERO)
	for v in verts:
		box = box.expand(v)
	for y in range(int(box.position.y), int(box.end.y), 40):
		for x in range(int(box.position.x), int(box.end.x), 40):
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
	p.texture = zone_tex
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
	var pts := PackedVector2Array(zone_walk)
	pts.append(zone_walk[0])
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
	_layout_loot_labels()
	_wild_spawning(delta)
	waystone.hot = pick_portal(get_global_mouse_position())
	if going_to_portal and not player.dead:
		if portal_in_reach():
			going_to_portal = false
			use_portal()
		elif player.path.is_empty():
			going_to_portal = false

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
	# fixed memories belong to their zone; an elite's echo lingers where it fell
	m.set_meta("zone", String(GD.LORE[id].get("zone", "plaza")) if GD.LORE[id].has("pos") else zone)
	m.visible = String(m.get_meta("zone")) == zone
	world.add_child(m)
	memories.append(m)
	return m


## Places the name plates of ground loot so they never overlap (Path of Exile style):
## each plate sits above its drop and moves up past any plate already placed.
## Commons, gold and potions only show while Alt is held or the mouse is near them.
func _layout_loot_labels() -> void:
	var mouse := get_global_mouse_position()
	var alt := Input.is_key_pressed(KEY_ALT)
	var shown: Array = []
	for l in loot:
		var near: bool = l.position.distance_to(mouse) < 70.0
		l.show_label = l.always_labelled() or alt or near
		l.hot = false
		if l.show_label:
			shown.append(l)
	# best items first so they keep the spot closest to their drop
	shown.sort_custom(func(a, b) -> bool: return a.rarity() > b.rarity() if a.rarity() != b.rarity() else a.position.y > b.position.y)
	var placed: Array = []
	for l in shown:
		var sz: Vector2 = l.label_size()
		var r := Rect2(l.position + Vector2(-sz.x / 2.0, -64.0), sz)
		var guard := 0
		var moved := true
		while moved and guard < 30:
			moved = false
			for o in placed:
				if (o as Rect2).grow(2.0).intersects(r):
					r.position.y = (o as Rect2).position.y - sz.y - 3.0
					moved = true
			guard += 1
		placed.append(r)
		l.label_rect = r
	var hot := pick_loot(mouse)
	if hot != null:
		hot.hot = true


## The ground drop whose name plate (or drop) is under a world position, or null.
func pick_loot(at: Vector2) -> Node2D:
	for l in loot:
		if l.show_label and (l.label_rect as Rect2).has_point(at):
			return l
	for l in loot:
		if l.position.distance_to(at + Vector2(0, 12)) < 18.0:
			return l
	return null


func pick_memory(at: Vector2) -> Node2D:
	for m in memories:
		if m.visible and m.pick_rect().has_point(at):
			return m
	return null


func memory_in_reach() -> Node2D:
	var best: Node2D = null
	for m in memories:
		if not m.visible:
			continue
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


# ---------------------------------------------------------------- zones and Waystones
## The Waystone the player can use right now, if they're standing at it.
func portal_in_reach() -> bool:
	return GD.gdist(player.position, waystone.position) <= Waystone.RANGE


func pick_portal(at: Vector2) -> bool:
	return waystone.pick_rect().has_point(at)


func use_portal() -> void:
	change_zone(String(Zones.ZONES[zone]["to"]))


## Sets the background, walkable floor, props, Waystone and town features for a zone.
func _apply_zone(id: String) -> void:
	zone = id
	var z: Dictionary = Zones.ZONES[id]
	zone_tex = PLAZA if id == "plaza" else load(String(z["tex"]))
	bg.texture = zone_tex
	var own: bool = not (z["walk"] is String)
	zone_walk = z["walk"] if own else WALKABLE
	for n in occluder_nodes:
		n.queue_free()
	occluder_nodes.clear()
	for o in (z.get("occluders", []) if own else OCCLUDERS):
		var on := _make_occluder(o)
		world.add_child(on)
		occluder_nodes.append(on)
	_build_navigation()
	waystone.position = z["portal"]
	waystone.dest_name = String(Zones.ZONES[z["to"]]["name"])
	merchant.visible = id == "plaza"
	for m in memories:
		m.visible = String(m.get_meta("zone", "plaza")) == id
	cam.limit_right = zone_tex.get_width()
	cam.limit_bottom = zone_tex.get_height()


## Travels to another zone. Enemies, loot and spells of the old zone are left behind.
func change_zone(id: String) -> void:
	if not Zones.ZONES.has(id) or id == zone:
		return
	if rift["active"]:
		close_rift()
	for e in enemies:
		e.queue_free()
	enemies.clear()
	for l in loot:
		l.queue_free()
	loot.clear()
	for c in world.get_children():
		if c.get_script() == Bolt or c.get_script() == Hazard:
			c.queue_free()
	_apply_zone(id)
	var z: Dictionary = Zones.ZONES[id]
	player.position = z["arrive"]
	player.path = PackedVector2Array()
	player.target = null
	going_to_portal = false
	cam.reset_smoothing()
	audio.play("rift_open", 0.0)
	audio.play_music(String(z["music"]))
	fx_ground.pillar(player.position, 0.9, Color("a070ff"))
	hud.banner(String(z["name"]), "Roaming Unwritten haunt these ruins" if z.get("wild", false) else "")
	pack_timer = 2.5
	save_game()


func is_wild() -> bool:
	return bool(Zones.ZONES[zone].get("wild", false))


## Wild zones: keep roaming packs coming while there's room.
func _wild_spawning(delta: float) -> void:
	if not is_wild() or player.dead:
		return
	var z: Dictionary = Zones.ZONES[zone]
	pack_timer -= delta
	if pack_timer > 0.0:
		return
	pack_timer = float(z["pack_every"])
	var alive := 0
	for e in enemies:
		if e.dead_t < 0.0:
			alive += 1
	if alive >= int(z["pack_cap"]):
		return
	var at := _spawn_point()
	for i in 20:
		if GD.gdist(at, player.position) > 5.0:
			break
		at = open_points[randi() % open_points.size()]
	var tier: int = 2 + player.level / 6
	var n := randi_range(2, 4)
	for i in n:
		var off := GD.to_px(Vector2(randf_range(-1.2, 1.2), randf_range(-1.2, 1.2)))
		var elite: bool = i == 0 and randf() < 0.12
		spawn_enemy(wave_enemy(tier), elite, at + off, int(z.get("level_bonus", 0)))


func pick_merchant(at: Vector2) -> bool:
	return merchant.visible and merchant.pick_rect().has_point(at)


func near_merchant() -> bool:
	return merchant.visible and GD.gdist(player.position, MERCHANT_POS) <= MERCHANT_RANGE


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
func spawn_enemy(key: String, elite: bool, at: Vector2, level_bonus := 0) -> void:
	var e := Node2D.new()
	e.set_script(Enemy)
	e.main = self
	e.player = player
	# keep spawns on the walkable floor, so their first step doesn't snap them somewhere else
	e.position = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, at)
	e.setup(key, elite, player.level + level_bonus)
	world.add_child(e)
	enemies.append(e)
	fx_ground.pillar(at, 0.8, Color("a070ff"))
	fx_parts.burst(at, 14, [Color("c9a8ff"), Color("7a4dff")], 3.0, 40.0)


## A delayed blast on the ground at `at` (warning ring, then damage if the knight is inside).
func ground_blast(at: Vector2, radius: float, delay: float, dmg: float, level: int, col: Color, src := "") -> Node2D:
	var h := Node2D.new()
	h.set_script(Hazard)
	h.main = self
	h.player = player
	h.position = at
	h.radius = radius
	h.delay = delay
	h.dmg = dmg
	h.level = level
	h.col = col
	h.src = src
	world.add_child(h)
	return h


## Fires an enemy bolt from `from` toward `at` (both screen positions on the ground).
func fire_bolt(from: Vector2, at: Vector2, dmg: float, level: int, speed: float, reach: float, src := "") -> Node2D:
	var b := Node2D.new()
	b.set_script(Bolt)
	b.main = self
	b.player = player
	var g := GD.ground(from, at)
	b.dir = g.normalized() if g.length() > 0.01 else Vector2.RIGHT
	b.position = from + GD.to_px(b.dir * 0.5)
	b.speed = speed
	b.life = (reach + 1.5) / speed
	b.dmg = dmg
	b.level = level
	b.src = src
	world.add_child(b)
	audio.play("bolt_cast", 0.1)
	bolts_fired += 1
	return b


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
	if wave % GD.BOSS_EVERY == 0:
		# boss wave: the Warden and a few Hollowlings
		hud.banner("The Unwritten Warden", "A guardian of the Scar awakens")
		spawn_enemy("warden", false, _spawn_point())
		for i in 2:
			spawn_enemy("slime", false, _spawn_point())
		return
	for i in mini(3 + wave, 9):
		spawn_enemy(wave_enemy(wave), false, _spawn_point())
	if wave % 3 == 0:
		spawn_enemy(["brute", "revenant", "caster"][randi() % 3] if wave >= 6 else ("brute" if randf() < 0.5 else "revenant"), true, _spawn_point())


## Picks an enemy type for a wave: tougher and stranger kinds join as waves climb.
func wave_enemy(wave: int) -> String:
	var weights := {"slime": 3.0, "revenant": 2.5, "brute": minf(2.0, 0.6 + wave * 0.15)}
	if wave >= 2:
		weights["caster"] = minf(1.6, 0.6 + wave * 0.1)   # ranged Gravecallers
	if wave >= 3:
		weights["skeleton"] = minf(2.0, 0.8 + wave * 0.12)
	if wave >= 4:
		weights["stag"] = minf(1.5, 0.5 + wave * 0.1)
	var total := 0.0
	for k in weights:
		total += float(weights[k])
	var r := randf() * total
	for k in weights:
		r -= float(weights[k])
		if r <= 0.0:
			return k
	return "slime"


func toggle_rift() -> void:
	if player.dead or get_tree().paused:
		return
	if zone != "plaza":
		hud.toast("The Reality Scar can only be opened in Crownsfall", Color("d9c2ff"), true)
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
	# pending slams, blasts and bolts vanish with the Scar
	for c in world.get_children():
		if c.get_script() == Hazard or c.get_script() == Bolt:
			c.queue_free()
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
	if e.affixes.has("molten"):
		var mo: Dictionary = GD.ELITE_AFFIXES["molten"]
		ground_blast(e.position, float(mo["radius"]), float(mo["delay"]), e.dmg * float(mo["dmg"]), e.level, Color("ff7a2e"), "the blast of " + e.ename)
	var cols: Array = [Color("a77bff"), Color("5a2f9a"), Color("ffe86a")]
	if e.type_key == "brute":
		cols = [Color("7a8a3a"), Color("c9b06a"), Color("3a2a18")]
	elif e.type_key == "revenant":
		cols = [Color("8a90b8"), Color("2b2f45"), Color("c79bff")]
	elif e.type_key == "caster":
		cols = [Color("7dffc8"), Color("1f4a3c"), Color("c8ffe8")]
	elif e.type_key == "skeleton":
		cols = [Color("d8cfc0"), Color("7a1f1f"), Color("2a2a30")]
	elif e.type_key == "stag":
		cols = [Color("c9d48a"), Color("6a4a8a"), Color("e8e0c8")]
	fx_parts.burst(e.position, 40 if e.elite else 18, cols, 5.0, 60.0, 8.0)
	var xp: int = roundi(GD.xp_need(e.level) / (5.0 + e.level * 0.35) * float(e.t["xp"]) * (3.0 if e.elite else 1.0))
	if e.boss:
		shake = 12.0
	fx_text.text(e.position + Vector2(0, -30), "+%d XP" % xp, Color("c9a8ff"))
	var gold: int = roundi(randf_range(2, 6) * (1.0 + e.level * 0.4) * (4.0 if e.elite else 1.0))
	_drop(e.position, "gold", gold, {})
	if randf() < 0.13:
		_drop(e.position, "potion", 0, {})
	if e.boss:
		# the Warden always leaves a legendary and a second good item
		_drop(e.position, "item", 0, GD.make_item(e.level, 1.0))
		_drop(e.position, "item", 0, GD.make_item(e.level, 0.5))
		_drop(e.position, "gold", gold * 3, {})
		hud.banner("Warden Defeated", "The Scar falters")
		player.bosses_killed += 1
	elif e.elite or randf() < 0.3:
		_drop(e.position, "item", 0, GD.make_item(e.level, 0.3 if e.elite else 0.0))
	if e.elite and randf() < 0.5:
		_drop(e.position, "item", 0, GD.make_item(e.level, 0.15))
	player.gain_xp(xp)
	update_quests()


func _drop(at: Vector2, kind: String, amount: int, item: Dictionary) -> void:
	if kind == "item" and int(item.get("rarity", 0)) == 3:
		audio.play("drop_legendary", 0.0)
		hud.toast("Legendary: %s" % item["name"], Color(String(GD.RARITY[3]["color"])))
	elif kind == "item" and int(item.get("rarity", 0)) >= 2:
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


## Share of carried gold lost on death (the price of being carried back to the plaza).
const DEATH_GOLD_LOSS := 0.1
var death_info := {}


func on_player_died() -> void:
	var lost: int = int(floor(player.gold * DEATH_GOLD_LOSS))
	player.gold -= lost
	player.deaths += 1
	death_info = {
		"killer": player.last_attacker if player.last_attacker != "" else "the Unwritten",
		"wave": int(rift["wave"]) if rift["active"] else 0,
		"lost": lost,
	}
	audio.play("death", 0.0)
	shake = maxf(shake, 6.0)
	close_rift()
	save_game()
	# let the fall play out for a moment before the death screen
	get_tree().create_timer(1.3).timeout.connect(func() -> void:
		if player.dead:
			hud.show_death())


func respawn() -> void:
	if zone != "plaza":
		change_zone("plaza")
	player.respawn(START)
	player.last_attacker = ""
	audio.play("respawn", 0.0)
	fx_ground.pillar(START, 1.0, Color("ffe9a8"))
	fx_parts.burst(START, 30, [Color("ffe9a8"), Color.WHITE], 3.0, 40.0)
	hud.toast("You rise again in Crownsfall", Color("ffe9a8"), true)


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
		"elite_kills": p.elite_kills, "bosses_killed": p.bosses_killed, "deaths": p.deaths, "bindings": p.bindings, "spec": p.spec, "adv": p.adv, "heroic": p.heroic, "gear": p.gear,
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
	p.bosses_killed = int(data.get("bosses_killed", 0))
	p.deaths = int(data.get("deaths", 0))
	var binds = data.get("bindings")
	p.bindings = p.DEFAULT_BINDINGS.duplicate()
	if binds is Array and binds.size() == p.BIND_KEYS.size():
		var ok := true
		for b in binds:
			if not (String(b) in ["", "basic", "s1", "s2", "s3", "s4"]):
				ok = false
		if ok:
			p.bindings = []
			for b in binds:
				p.bindings.append(String(b))
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
