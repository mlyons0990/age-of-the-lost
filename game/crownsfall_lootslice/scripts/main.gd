extends Node2D
## Crownfall plaza: painted background, walkable area, depth-sorted props, the
## knight, and the combat loop (Reality Scar waves, loot, levels, quests, saving).

const Systems := preload("res://scripts/systems.gd")
const GD := preload("res://scripts/game_data.gd")
const PLAZA := preload("res://assets/plaza.png")
const Player := preload("res://scripts/player.gd")
const Enemy := preload("res://scripts/enemy.gd")
const Loot := preload("res://scripts/loot.gd")
const Fx := preload("res://scripts/fx.gd")
const Hud := preload("res://scripts/hud.gd")
const SoundBank := preload("res://scripts/sound_bank.gd")
const Mastery := preload("res://scripts/mastery_data.gd")
const SAVE_SCHEMA := 6
const LootRules := preload("res://scripts/loot_rules.gd")
const SAVE_PATH := "user://crownsfall_encounter_v4.json"

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

var world: Node2D
var sound
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
var pickup_clock := 0.0
var pickup_notice_until := 0.0
var loot_notice := ""
var open_points: Array[Vector2] = []
var hover_enemy: Node2D = null
## The Reality Scar: a placeholder combat arena. Waves of the Unwritten spawn while it is open.
var encounter: Node2D
var encounter_wins := 0

var rift := {"active": false, "wave": 0, "timer": 0.0, "cleared": true}
var shake := 0.0
var hurt_flash := 0.0
var save_timer := 0.0
var had_save := false
var save_blocked := false
var save_notice := ""
var save_error := ""
var save_warning := ""
var save_store = preload("res://scripts/save_store.gd").new()
var merchant_stock: Array = []
var buyback_stock: Array = []
const SERVICES := {
	"stash": {"pos": Vector2(1440, 1100), "label": "Stash", "color": "e8c77a"},
	"merchant": {"pos": Vector2(1540, 900), "label": "Quartermaster", "color": "8de5ba"},
	"lore": {"pos": Vector2(1080, 900), "label": "Stone memory", "color": "bdb0ff"},
	"board": {"pos": Vector2(1280, 750), "label": "Noticeboard", "color": "90c9ff"},
}


func _ready() -> void:
	get_tree().auto_accept_quit=false
	sound = SoundBank.new()
	add_child(sound)
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

	cam = Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = PLAZA.get_width()
	cam.limit_bottom = PLAZA.get_height()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	player.add_child(cam)
	cam.make_current()

	fx_parts = _make_fx(Fx.PARTICLES, 100)
	fx_text = _make_fx(Fx.TEXT, 101)

	had_save = load_game()
	if not had_save and not save_blocked:
		player.gold = 45
		for slot in ["weapon", "offhand", "armor", "ring", "boots"]:
			Systems.insert(player.inventory, Systems.make_item(1, 0.0, slot))
	if not had_save:
		for slot in ["weapon", "offhand", "helm", "gloves", "belt", "boots", "ring", "amulet"]:
			merchant_stock.append(Systems.make_item(1, 0.0, slot))
	if not had_save:
		player.hp = player.stats().max_hp
		player.mp = player.stats().max_mp

	hud = Hud.new()
	hud.main = self
	hud.player = player
	add_child(hud)
	encounter = Node2D.new()
	encounter.set_script(preload("res://scripts/encounter_director.gd"))
	encounter.main = self; encounter.z_index = -3
	add_child(encounter)
	var trial_ui := Control.new()
	trial_ui.set_script(preload("res://scripts/trial_hud.gd")); trial_ui.main = self
	hud.add_child(trial_ui)
	if player.dead: hud.show_death()

	if save_notice != "": hud.toast(save_notice, Color("ffd76a"))
	if OS.get_cmdline_user_args().has("--mage-test"):
		var test := Node.new()
		test.set_script(load("res://tests/mage_integration.gd"))
		test.set("main", self)
		add_child(test)
	elif OS.get_cmdline_user_args().has("--systems-test") or OS.get_cmdline_user_args().has("--autotest"):
		var test := Node.new()
		test.set_script(load("res://tests/integration.gd"))
		test.set("main", self)
		add_child(test)
	else:
		check_choice.call_deferred()


func combat_active() -> bool:
	return rift.active or (is_instance_valid(encounter) and encounter.active)

func create_character(class_id: String, chosen_name: String) -> bool:
	if had_save or save_blocked or not GD.CLASSES.has(class_id): return false
	player.cancel_casts()
	player.class_id = class_id
	player.mastery.clear(); player.crafted_uniques.clear()
	player.level = 1; player.xp = 0; player.gold = 45; player.potions = 3
	player.kills = 0; player.elite_kills = 0; player.quest = 0
	if is_instance_valid(encounter): encounter.finish(false,"Character replaced")
	encounter_wins = 0
	player.spec = ""; player.adv = ""; player.heroic = ""; player.opened_rift = false
	player.dead = false; player.cds.clear(); player.cd_full.clear(); player.discoveries.clear()
	player.rally = 0; player.attack_anim = 0
	player.hero_name = chosen_name.strip_edges().left(16)
	if player.hero_name.is_empty(): player.hero_name = "Wayfarer"
	player.hotbar = GD.CLASSES[class_id].starting.duplicate()
	player.inventory.clear()
	player.stash.clear()
	buyback_stock.clear()
	clear_ground_loot()
	for slot in player.gear: player.gear[slot] = null
	var starters := ["staff", "wand", "focus", "robe", "slippers"] if class_id == "mage" else ["weapon", "offhand", "armor", "ring", "boots"]
	for base in starters: Systems.insert(player.inventory, Systems.make_item(1, 0, base, class_id))
	merchant_stock.clear()
	var pool := Systems.drop_pool(class_id)
	for base in pool: merchant_stock.append(Systems.make_item(1, 0, base, class_id))
	player.hp = player.stats().max_hp; player.mp = player.stats().max_mp
	player.refresh_visuals()
	return true

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(hud): request_exit()

func request_exit() -> bool:
	if not save_game():
		hud.open_page("pause")
		return false
	get_tree().paused=true
	quit_game()
	return true

func quit_game(exit_code := 0) -> void:
	await sound.drain()
	get_tree().quit(exit_code)

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
			KEY_F11:
				var w := get_window()
				w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
			KEY_F3:
				debug_draw = not debug_draw
				queue_redraw()
			KEY_E:
				interact()
			KEY_R:
				toggle_rift()
			KEY_F:
				if not get_tree().paused: collect_nearest()
			KEY_F7:
				_enter_articulation_lab()
			KEY_F6:
				# Tester shortcut: gain a level instantly.
				player.xp = 0
				player.level_up()


func _enter_articulation_lab() -> void:
	if get_tree().paused or player.dead: return
	if combat_active():
		hud.toast("Finish or retreat from combat before entering the rig lab.", Color("b3c4dc"), true)
		return
	if save_blocked:
		hud.toast("Resolve the protected save before changing scenes.", Color("ffd76a"), true)
		return
	if not save_game(): return
	player.cancel_casts()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/rig_lab_3d.tscn")

func _draw() -> void:
	if is_instance_valid(player):
		for key in SERVICES:
			var service: Dictionary = SERVICES[key]
			var at: Vector2 = service.pos
			var col := Color(String(service.color))
			var near := GD.gdist(player.position, at) <= 1.8
			draw_circle(at, 13, Color("111b30"))
			draw_arc(at, 14, 0, TAU, 24, col, 2, true)
			draw_string_outline(ThemeDB.fallback_font, at + Vector2(-55, -26), service.label + (" [E]" if near else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 5, Color("111522"))
			draw_string(ThemeDB.fallback_font, at + Vector2(-55, -26), service.label + (" [E]" if near else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
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
	queue_redraw()
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

	# Failed collection keeps the node and its animation age intact.
	pickup_clock+=maxf(0,delta)
	for l in loot.duplicate():
		if not is_instance_valid(l) or l.age<0.35 or player.dead or pickup_clock<l.retry_at: continue
		if GD.gdist(l.position,player.position)<(1.3 if l.kind=="gold" else 0.9):
			if not _pick_up(l,true): l.retry_at=pickup_clock+1.5

	hover_enemy = pick_enemy(get_global_mouse_position())
	save_timer += delta
	if save_timer > 10.0:
		save_timer = 0.0
		save_game()


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
	if loot.size()+LootRules.WAVE_RESERVE>LootRules.MAX_DROPS:
		close_rift("Collect ground loot before another wave")
		return
	rift["wave"] = int(rift["wave"]) + 1
	rift["cleared"] = false
	var wave: int = rift["wave"]
	hud.toast("Wave %d" % wave, Color("c9a8ff"))
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
	if is_instance_valid(encounter) and encounter.active:
		encounter.finish(false,"Retreated from the Cantor trial")
		return
	if rift["active"]:
		close_rift("The Scar Closes")
		return
	if loot.size()+LootRules.WAVE_RESERVE>LootRules.MAX_DROPS:
		hud.toast("Collect ground loot before opening another Scar.",Color("ffd76a"),true); return
	rift = {"active": true, "wave": 0, "timer": 1.8, "cleared": true}
	player.opened_rift = true
	hud.banner("Reality Scar", "The Unwritten are breaking through")
	shake = 7.0
	update_quests()


func close_rift(msg := "") -> void:
	if not rift["active"]:
		return
	rift["active"] = false
	player.cancel_casts()
	for e in enemies:
		if e.dead_t < 0.0:
			e.dead_t = 0.0
			fx_parts.burst(e.position, 12, [Color("c9a8ff"), Color("7a4dff")], 3.0, 60.0)
	enemies.clear()
	if msg != "":
		hud.banner(msg, "You reached wave %d" % int(rift["wave"]) if int(rift["wave"]) > 0 else "")


func kill_enemy(e: Node2D, context: Dictionary = {}) -> void:
	if e.dead_t >= 0.0:
		return
	player.aura.on_kill(e,context)
	if e.has_meta("cantor_trial"):
		e.dead_t = 0; e.hp = 0; enemies.erase(e)
		encounter.on_defeated(e)
		return
	e.dead_t = 0.0
	e.hp = 0.0
	enemies.erase(e)
	player.kills += 1
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
		_drop(e.position, "item", 0, Systems.make_item(e.level, 0.3 if e.elite else 0.0, "", player.class_id))
	if e.elite and randf() < 0.5:
		_drop(e.position, "item", 0, Systems.make_item(e.level, 0.15, "", player.class_id))
	player.gain_xp(xp)
	update_quests()


func _drop(at: Vector2, kind: String, amount: int, item: Dictionary) -> Node2D:
	if loot.size()>=LootRules.MAX_DROPS: return null
	var map:=get_world_2d().navigation_map
	var point:=at
	if NavigationServer2D.map_get_iteration_id(map)>0:
		var projected:=NavigationServer2D.map_get_closest_point(map,at+GD.to_px(Vector2(randf_range(-0.9,0.9),randf_range(-0.9,0.9))))
		if _valid_floor_point(projected): point=projected
	if not _valid_floor_point(point):
		var nearest:=WALKABLE[0]; var distance:=INF
		for i in WALKABLE.size():
			var candidate:=Geometry2D.get_closest_point_to_segment(point,WALKABLE[i],WALKABLE[(i+1)%WALKABLE.size()])
			if candidate.distance_squared_to(point)<distance: nearest=candidate; distance=candidate.distance_squared_to(point)
		point=nearest
	var record:={"uid":Systems.uid(),"kind":kind,"amount":1 if kind=="potion" and amount==0 else amount,"item":item.duplicate(true),"x":point.x,"y":point.y}
	return spawn_drop_record(record)

func spawn_drop_record(record: Dictionary, settled := false) -> Node2D:
	var drop:=Node2D.new(); drop.set_script(Loot)
	drop.uid=record.uid; drop.kind=record.kind; drop.amount=int(record.amount); drop.item=record.item.duplicate(true)
	drop.position=Vector2(record.x,record.y); drop.age=1.0 if settled else 0.0
	world.add_child(drop); loot.append(drop); return drop

func clear_ground_loot() -> void:
	for drop in loot:
		if is_instance_valid(drop): drop.queue_free()
	loot.clear()

func ground_snapshot() -> Array:
	var records: Array=[]
	for drop in loot:
		if is_instance_valid(drop) and not drop.is_queued_for_deletion(): records.append(drop.record())
	return records

func nearby_loot(sort_distance := true) -> Array:
	var found: Array=[]
	for drop in loot:
		if is_instance_valid(drop) and not drop.is_queued_for_deletion() and GD.gdist(player.position,drop.position)<=2.0: found.append(drop)
	if not sort_distance: return found
	found.sort_custom(func(a: Node2D,b: Node2D) -> bool:
		var da:=GD.gdist(player.position,a.position); var db:=GD.gdist(player.position,b.position)
		return String(a.uid)<String(b.uid) if is_equal_approx(da,db) else da<db)
	return found

func collect_nearest() -> bool:
	var found:=nearby_loot()
	if found.is_empty(): hud.toast("No nearby loot. Move closer to a drop.",Color("b3c4dc"),true); return false
	return _pick_up(found[0])

func collect_drop(uid: String) -> bool:
	for drop in loot:
		if is_instance_valid(drop) and drop.uid==uid: return _pick_up(drop)
	loot_notice="This drop is no longer on the ground."; return false

func _pick_up(drop: Node2D, automatic := false) -> bool:
	if not is_instance_valid(drop) or drop.is_queued_for_deletion() or not loot.has(drop):
		loot_notice="This drop is no longer on the ground."; return false
	if player.dead: loot_notice="Return to life before collecting loot."; return false
	if GD.gdist(player.position,drop.position)>2.0: loot_notice="Move closer to this drop."; return false
	var plan:=LootRules.collect(player.inventory,player.gold,player.potions,drop.record())
	if not plan.ok:
		loot_notice=plan.reason; drop.notice=loot_notice
		if not automatic or pickup_clock>=pickup_notice_until:
			hud.toast(loot_notice,Color("ffd76a"),true); pickup_notice_until=pickup_clock+1.5
		return false
	var remaining:=ground_snapshot()
	for i in range(remaining.size()-1,-1,-1):
		if remaining[i].uid==drop.uid:
			if int(plan.remainder)>0: remaining[i].amount=int(plan.remainder)
			else: remaining.remove_at(i)
	if not persist_changes({"inventory":plan.inventory,"gold":plan.gold,"potions":plan.potions,"ground_loot":remaining}):
		loot_notice=save_error; drop.notice=loot_notice; return false
	player.inventory=plan.inventory; player.gold=int(plan.gold); player.potions=int(plan.potions)
	loot_notice="Collected "+(String(drop.item.name) if drop.kind=="item" else ("%d gold" % int(plan.taken) if drop.kind=="gold" else "%d health potion%s" % [int(plan.taken),"s" if int(plan.taken)!=1 else ""]))
	if int(plan.remainder)>0:
		drop.amount=int(plan.remainder); drop.retry_at=pickup_clock+1.5; drop.notice="Remainder kept on the ground."
	else: loot.erase(drop); drop.queue_free()
	sound.play_cue("pickup"); hud.toast(loot_notice,Color("c7d9b1"),true)
	return true

func interact() -> void:
	if player.dead or get_tree().paused: return
	var closest := ""
	var distance := 1.8
	for key in SERVICES:
		var d := GD.gdist(player.position, SERVICES[key].pos)
		if d <= distance:
			distance = d; closest = key
	if closest == "": hud.toast("Move near a labeled service, then press E.", Color("b3c4dc"), true)
	else: hud.open_page(closest)


# ---------------------------------------------------------------- progression
func on_level_up() -> void:
	var sub := "Your oath grows stronger"
	if player.level == GD.SPEC_LEVEL:
		sub = "Your specialization awaits"
	elif player.level == GD.ADVANCED_LEVEL:
		sub = "An advanced path opens"
	elif player.level == GD.MAX_LEVEL:
		sub = "Your training reaches its current limit"
	hud.banner("Level %d" % player.level, sub)
	fx_ground.ring(player.position, 0.2, 3.0, 0.7, Color("ffe9a8"))
	fx_ground.pillar(player.position, 1.0, Color("ffe9a8"))
	for i in 40:
		fx_parts.spark(player.position + Vector2(randf_range(-35, 35), randf_range(-20, 20)), Vector2.ZERO, randf_range(0, 40), randf_range(160, 440), -40.0, randf_range(0.8, 1.4), Color("ffe9a8") if randf() < 0.5 else Color.WHITE, randf_range(4, 8))
	update_quests()
	save_game()
	get_tree().create_timer(0.9).timeout.connect(check_choice)


## Opens the next pending class choice, if any.
func check_choice() -> void:
	if hud.choice_open() or hud.char_panel != null:
		return
	if player.level >= GD.SPEC_LEVEL and player.spec == "":
		hud.open_choice("spec")
	elif player.level >= GD.ADVANCED_LEVEL and player.spec != "" and player.adv == "":
		hud.open_choice("adv")



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
	if is_instance_valid(encounter): encounter.finish(false,"Defeated")
	close_rift()
	hud.show_death()


func respawn() -> void:
	player.respawn(START)


const QUESTS := [
	"A Scar in the Plaza", "The Unwritten", "A Worthy Foe", "The Path Divides", "Tempered Oath", "A Seasoned Wayfarer",
]


func _quest_done(i: int) -> bool:
	match i:
		0: return player.opened_rift
		1: return player.kills >= 15
		2: return player.elite_kills >= 1
		3: return player.spec != ""
		4: return player.adv != ""
		5: return player.level >= GD.MAX_LEVEL
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
func capture_save(changes: Dictionary = {}) -> Dictionary:
	var p := player
	var data := {"schema": SAVE_SCHEMA, "ground_loot":ground_snapshot(), "buyback_stock":buyback_stock, "encounter_wins":encounter_wins, "mastery":p.mastery,"crafted_uniques":p.crafted_uniques,"class_id": p.class_id, "hp": p.hp, "mp": p.mp, "cooldowns": p.cds, "cooldown_full": p.cd_full, "dead": p.dead, "name": p.hero_name, "level": p.level, "xp": p.xp, "gold": p.gold, "potions": p.potions, "kills": p.kills,
		"elite_kills": p.elite_kills, "spec": p.spec, "adv": p.adv, "gear": p.gear, "inventory": p.inventory,
		"stash": p.stash, "hotbar": p.hotbar, "discoveries": p.discoveries, "merchant_stock": merchant_stock,
		"opened_rift": p.opened_rift, "quest": p.quest}
	data.merge(changes,true)
	if changes.has("gear"):
		var derived:=Systems.derive(player.level,data.gear,player.mods(),player.class_id)
		data.hp=minf(data.hp,derived.max_hp); data.mp=minf(data.mp,derived.max_mp)
	return data.duplicate(true)

func persist_changes(changes: Dictionary = {}) -> bool:
	if save_blocked:
		save_error=save_notice if not save_notice.is_empty() else "Save protected. Reopen to recover your progress."
		return false
	var result: Dictionary=save_store.commit(SAVE_PATH,capture_save(changes),_valid_save,SAVE_SCHEMA)
	if not result.ok:
		save_error=result.reason
		if result.protected: save_blocked=true; save_notice=result.reason
		return false
	save_error=""; save_warning=result.warning
	return true

func save_game() -> bool:
	return persist_changes()

func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return {}
	if not parser.data is Dictionary: return {}
	return parser.data

func _valid_save(data: Dictionary) -> bool:
	if data.is_empty() or not data.get("schema") is float and not data.get("schema") is int: return false
	if not is_finite(float(data.schema)) or float(data.schema) != floor(float(data.schema)): return false
	if not int(data.schema) in [2, 3, 4, 5, 6]: return false
	if data.has("encounter_wins"):
		var wins: Variant = data.encounter_wins
		if not wins is float and not wins is int: return false
		if not is_finite(float(wins)) or float(wins) != floor(float(wins)) or wins < 0 or wins > 999999: return false
	var class_id := String(data.get("class_id", "warrior"))
	if not GD.CLASSES.has(class_id): return false
	if int(data.schema) >= 4:
		if not data.get("discoveries") is Array or not data.get("level") is float and not data.get("level") is int: return false
		if not is_finite(float(data.level)): return false
		if Mastery.problem(data.get("mastery"),class_id,int(data.level),data.discoveries) != "": return false
		if not data.get("crafted_uniques") is Array or data.crafted_uniques.size() > 1: return false
		for id in data.crafted_uniques:
			if not id is String or id != Systems.UNIQUE_ID: return false
	if int(data.schema) >= 3:
		for key in ["hp", "mp"]:
			if not data.get(key) is float and not data.get(key) is int: return false
			if not is_finite(float(data[key])) or float(data[key]) < 0: return false
		for key in ["cooldowns", "cooldown_full"]:
			if not data.get(key) is Dictionary: return false
			for id in data[key]:
				if not GD.spells().has(id) or not data[key][id] is float and not data[key][id] is int: return false
				if not is_finite(float(data[key][id])) or float(data[key][id]) < 0 or float(data[key][id]) > 3600: return false
		if not data.get("dead") is bool: return false
	for key in ["level", "xp", "gold", "potions", "kills", "elite_kills", "quest"]:
		if not data.get(key) is float and not data.get(key) is int: return false
		if not is_finite(float(data[key])) or float(data[key]) != floor(float(data[key])): return false
	for key in ["inventory", "stash", "hotbar", "discoveries", "merchant_stock"]:
		if not data.get(key) is Array: return false
	if not data.get("gear") is Dictionary: return false
	var buyback: Array=[]
	if int(data.schema)>=5:
		if not data.get("buyback_stock") is Array or data.buyback_stock.size()>12: return false
		buyback=data.buyback_stock
	for container in [data.inventory, data.stash, data.merchant_stock, buyback]:
		if container.size() > 60: return false
		for item in container:
			if not _valid_item(item): return false
	for item in data.gear.values():
		if item != null and not _valid_item(item): return false
	if not Systems.gear_valid(data.gear, class_id, int(data.level)): return false
	var seen := {}
	for slot in data.gear:
		var item = data.gear[slot]
		if item == null: continue
		if not Systems.SLOTS.has(slot) or not Systems.legal_slot(item, slot) or int(item.get("level", 1)) > int(data.level): return false
		var id := String(item.get("uid", ""))
		if id.is_empty() or seen.has(id): return false
		seen[id] = true
	for container in [data.inventory, data.stash, data.merchant_stock, buyback]:
		var placed: Array = []
		for item in container:
			var id := String(item.get("uid", ""))
			if id.is_empty() or seen.has(id): return false
			seen[id] = true
			if container == data.merchant_stock or container == buyback: continue
			var clean := Systems.clean_item(item)
			if Systems.fits(placed, clean, Vector2i(clean.x, clean.y)): placed.append(clean)
			elif not Systems.insert(placed, clean): return false
	if int(data.schema)>=6:
		if not data.get("ground_loot") is Array or data.ground_loot.size()>LootRules.MAX_DROPS: return false
		var drop_ids: Dictionary={}
		for record in data.ground_loot:
			if LootRules.problem(record)!="" or drop_ids.has(record.uid): return false
			drop_ids[record.uid]=true
			var point:=Vector2(record.x,record.y)
			if not _valid_floor_point(point): return false
			if record.kind=="item":
				var ground_item: Dictionary=record.item
				if not ground_item.get("slot") is String or not Systems.NAMES.has(ground_item.slot): return false
				if not ground_item.get("name") is String or ground_item.name.is_empty() or ground_item.name.length()>64: return false
				if not ground_item.get("uid") is String or ground_item.uid.is_empty() or ground_item.uid.length()>128: return false
				if not LootRules.integer(ground_item.get("rarity"),0,GD.RARITY.size()-1) or not LootRules.integer(ground_item.get("level"),1,GD.MAX_LEVEL): return false
				if not LootRules.integer(ground_item.get("value"),1,100000): return false
				if not _valid_item(record.item): return false
				var id:=String(record.item.get("uid",""))
				if id.is_empty() or seen.has(id): return false
				seen[id]=true
	return true

func _valid_floor_point(point: Vector2) -> bool:
	if Geometry2D.is_point_in_polygon(point,PackedVector2Array(WALKABLE)): return true
	for i in WALKABLE.size():
		if Geometry2D.get_closest_point_to_segment(point,WALKABLE[i],WALKABLE[(i+1)%WALKABLE.size()]).distance_to(point)<=1.0: return true
	return false

func _valid_item(item: Variant) -> bool:
	if not item is Dictionary or not Systems.NAMES.has(String(item.get("slot", ""))): return false
	if not Systems.unique_valid(item): return false
	for key in Systems.ATTRS + ["dmg", "armor", "hp", "crit", "spell_power", "level", "rarity", "value", "x", "y"]:
		if item.has(key) and (not item[key] is float and not item[key] is int): return false
		if item.has(key) and not is_finite(float(item[key])): return false
	return true

func _restore_bag(raw: Array, used: Dictionary) -> Array:
	var result: Array = []
	for value in raw:
		var item := Systems.clean_item(value)
		if item.is_empty() or used.has(item.uid): continue
		if Systems.fits(result, item, Vector2i(item.x, item.y)):
			result.append(item); used[item.uid] = true
		elif Systems.insert(result, item): used[item.uid] = true
	return result

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return false
	var data := _read_save(SAVE_PATH)
	if data.has("schema") and (data.schema is float or data.schema is int) and data.schema > SAVE_SCHEMA:
		save_blocked = true; save_notice = "Newer save version: writing disabled to preserve it."
		return false
	if not _valid_save(data):
		data = _read_save(SAVE_PATH + ".bak")
		if not _valid_save(data):
			save_blocked = true; save_notice = "Save unreadable. Files preserved; writing disabled."
			return false
		# Keep corrupt bytes for diagnosis. Promote backup before any later save.
		var absolute := ProjectSettings.globalize_path(SAVE_PATH)
		if DirAccess.copy_absolute(absolute, absolute + ".corrupt")!=OK or DirAccess.copy_absolute(absolute + ".bak", absolute)!=OK:
			save_blocked=true; save_notice="The recovery copy could not be restored. Files preserved; writing disabled."
			return false
		save_notice = "Recovered from the previous valid save."
	if is_instance_valid(encounter): encounter.finish(false,"Save loaded",false)
	encounter_wins = int(data.get("encounter_wins",0)) if int(data.schema) >= 4 else 0
	var p := player
	p.class_id = String(data.get("class_id", "warrior"))
	p.hero_name = String(data.get("name", "Wayfarer")).strip_edges().left(16)
	if p.hero_name.is_empty(): p.hero_name = "Wayfarer"
	p.level = clampi(int(data.level), 1, GD.MAX_LEVEL)
	p.xp = clampi(int(data.xp), 0, GD.xp_need(p.level) - 1)
	p.gold = clampi(int(data.gold), 0, 999999999)
	p.potions = clampi(int(data.potions), 0, 5)
	p.kills = maxi(0, int(data.kills)); p.elite_kills = maxi(0, int(data.elite_kills))
	p.spec = String(data.get("spec", "")); p.adv = String(data.get("adv", ""))
	if not GD.SPECS.has(p.spec) or p.level < GD.SPEC_LEVEL or GD.SPECS[p.spec]["class"] != p.class_id: p.spec = ""; p.adv = ""
	if p.spec != "" and (p.level < 40 or p.adv != GD.SPECS[p.spec].advanced[0].id): p.adv = ""
	p.opened_rift = bool(data.get("opened_rift", false))
	p.quest = clampi(int(data.quest), 0, QUESTS.size())
	p.discoveries = ["first_echo"] if data.discoveries.has("first_echo") else []
	p.mastery = {}
	p.crafted_uniques = []
	if int(data.schema) >= 4:
		for id in data.mastery: p.mastery[id] = int(data.mastery[id])
		p.crafted_uniques = data.crafted_uniques.duplicate()
	var used := {}
	for slot in p.gear:
		var item := Systems.clean_item(data.gear.get(slot))
		p.gear[slot] = null
		if not item.is_empty() and Systems.legal_slot(item, slot) and int(item.level) <= p.level and not used.has(item.uid):
			p.gear[slot] = item; used[item.uid] = true
	p.inventory = _restore_bag(data.inventory, used)
	p.stash = _restore_bag(data.stash, used)
	merchant_stock.clear()
	for raw in data.merchant_stock:
		var item := Systems.clean_item(raw)
		if not item.is_empty() and not used.has(item.uid): merchant_stock.append(item); used[item.uid] = true
	buyback_stock.clear()
	if int(data.schema)>=5:
		for raw in data.buyback_stock:
			var item := Systems.clean_item(raw)
			if not item.is_empty() and not used.has(item.uid): buyback_stock.append(item); used[item.uid]=true
	p.hotbar = ["", "", "", "", ""]
	for i in mini(5, data.hotbar.size()):
		var id := String(data.hotbar[i])
		if GD.unlocked(p, id) and not p.hotbar.has(id): p.hotbar[i] = id
	if p.hotbar.all(func(id: String) -> bool: return id.is_empty()): p.hotbar = GD.CLASSES[p.class_id].starting.duplicate()
	p.hp = clampf(float(data.get("hp", p.stats().max_hp)), 0, p.stats().max_hp)
	p.mp = clampf(float(data.get("mp", p.stats().max_mp)), 0, p.stats().max_mp)
	p.dead = bool(data.get("dead", false)) or p.hp <= 0
	p.cds.clear(); p.cd_full.clear()
	for id in data.get("cooldowns", {}):
		if GD.unlocked(p, id): p.cds[id] = float(data.cooldowns[id])
	for id in data.get("cooldown_full", {}):
		if GD.unlocked(p, id): p.cd_full[id] = float(data.cooldown_full[id])
	clear_ground_loot()
	if int(data.schema)>=6:
		for record in data.ground_loot: spawn_drop_record(record,true)
	p.cancel_casts()
	p.refresh_visuals()
	return true

func reset_save() -> void:
	# Explicit reset keeps an archive; the original project's save is in another directory.
	var absolute := ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.rename_absolute(absolute, absolute + ".reset-" + str(Time.get_unix_time_from_system()))
	get_tree().paused = false
	get_tree().reload_current_scene()
