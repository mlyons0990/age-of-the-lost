extends CanvasLayer
## HUD: health and mana orbs, skill bar with cooldowns, XP bar, quest tracker,
## minimap, toasts, plus the start, class-choice, character and death panels.
## Drawn in code for now; painted HUD art can replace HudDraw later.

const GD := preload("res://scripts/game_data.gd")
const ART := preload("res://scripts/art_library.gd")
const Layout := preload("res://scripts/hud_layout.gd")
const GOLD := Color("e8c77a")
const BRONZE := Color(0.62, 0.47, 0.22)
const DARK := Color(0.07, 0.06, 0.08, 0.92)
const SLOTS := [["basic", "LMB"], ["s1", "1"], ["s2", "2"], ["s3", "3"], ["s4", "4"]]

var main: Node2D
var player: Node2D
var draw_ctl: Control
var toasts: Array = []
var banner_a := ""
var banner_b := ""
var banner_t := 99.0
var choice_panel: Control = null
var char_panel: Control = null
var start_panel: Control = null
var death_panel: Control = null
var rift_btn: Button
var menu_box: VBoxContainer
var menu_toggle: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	draw_ctl = HudDraw.new()
	draw_ctl.hud = self
	draw_ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(draw_ctl)

	menu_toggle = _button("Controls & menus [F2]  +", toggle_menu)
	menu_toggle.position = Vector2(24, 112)
	add_child(menu_toggle)
	var row := VBoxContainer.new()
	menu_box = row
	row.position = Vector2(24, 168)
	row.add_theme_constant_override("separation", 3)
	add_child(row)
	row.hide()
	row.add_child(_button("Inventory [I / C]", toggle_character))
	rift_btn = _button("Reality Scar (R)", func() -> void: main.toggle_rift())
	rift_btn.add_theme_color_override("font_color", Color("d9c2ff"))
	row.add_child(rift_btn)

	if not main.had_save and not OS.get_cmdline_user_args().has("--autotest") and not OS.get_cmdline_user_args().has("--systems-test") and not OS.get_cmdline_user_args().has("--mage-test"):
		_open_start()

func toggle_menu() -> void:
	menu_box.visible = not menu_box.visible
	menu_toggle.text = "Controls & menus [F2]  " + ("−" if menu_box.visible else "+")


func _process(delta: float) -> void:
	banner_t += delta
	for t in toasts:
		t["t"] += delta
	while toasts.size() > 0 and float(toasts[0]["t"]) > 2.8:
		toasts.pop_front()
	rift_btn.text = "Retreat (R)" if is_instance_valid(main.encounter) and main.encounter.active else ("Close Scar (R)" if main.rift["active"] else "Reality Scar (R)")
	draw_ctl.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		if start_panel == null and choice_panel == null and death_panel == null:
			toggle_character()


func toast(msg: String, color := GOLD, small := false) -> void:
	toasts.append({"text": msg, "color": color, "small": small, "t": 0.0})
	while toasts.size() > 5:
		toasts.pop_front()


func banner(a: String, b := "") -> void:
	banner_a = a
	banner_b = b
	banner_t = 0.0


func choice_open() -> bool:
	return choice_panel != null


# ---------------------------------------------------------------- widgets
func _style(border := BRONZE, bg := DARK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(14)
	return sb


func _button(text: String, cb: Callable, min_size := Vector2.ZERO) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_stylebox_override("normal", _style(BRONZE.darkened(0.2), Color(0.1, 0.085, 0.06, 0.95)))
	b.add_theme_stylebox_override("hover", _style(GOLD, Color(0.16, 0.13, 0.09, 0.97)))
	b.add_theme_stylebox_override("pressed", _style(GOLD, Color(0.2, 0.16, 0.1, 1.0)))
	b.pressed.connect(func() -> void: main.sound.play_cue("ui_click"))
	b.pressed.connect(cb)
	return b


func _label(text: String, size: int, color := Color("efe6d2")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## A dimmed full-screen layer with a centred panel. Returns [root, vbox].
func _modal(dim := Color(0.02, 0.02, 0.04, 0.72)) -> Array:
	var root := ColorRect.new()
	root.color = dim
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(GOLD.darkened(0.25), Color(0.07, 0.075, 0.12, 0.97)))
	var painted_panel := ART.panel()
	if painted_panel != null: panel.add_theme_stylebox_override("panel", painted_panel)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	return [root, box]


func _refresh_pause() -> void:
	get_tree().paused = start_panel != null or choice_panel != null or char_panel != null


# ---------------------------------------------------------------- start panel
func _open_start() -> void:
	var m := _modal()
	start_panel = m[0]
	var box: VBoxContainer = m[1]
	box.add_child(_label("AGE OF THE LOST", 44, GOLD))
	box.add_child(_label("Crownsfall plaza — playable prototype", 20, Color("a99f8a")))
	box.add_child(_label("Name your Wayfarer", 18))
	var edit := LineEdit.new()
	edit.placeholder_text = "Wayfarer"
	edit.max_length = 16
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.custom_minimum_size = Vector2(320, 44)
	edit.add_theme_font_size_override("font_size", 22)
	box.add_child(edit)
	var help := _label("Left click / hold: move or attack      Shift + click: attack in place\nRight click or 1 / 2 / 3 / 4: equipped skills      Q: potion\nMouse wheel: camera distance      Home: reset camera      F2: menus\nR: open or close the Reality Scar      I / C: inventory      K: spellbook      E: nearby interaction\nF11: fullscreen      F3: show walk area      Esc: close panel or pause\n\nThe plaza is safe until you open the Reality Scar. Waves of the Unwritten then break through.\nDevelopment shortcut: F6 gains a level instantly.", 17, Color("cfc6b2"))
	box.add_child(help)
	var begin := func() -> void:
		var n := edit.text.strip_edges()
		player.hero_name = n if n != "" else "Wayfarer"
		start_panel.queue_free()
		start_panel = null
		_refresh_pause()
		main.save_game()
	box.add_child(_button("Begin", begin, Vector2(0, 52)))
	edit.text_submitted.connect(func(_t: String) -> void: begin.call())
	_refresh_pause()


# ---------------------------------------------------------------- class choices
func open_choice(kind: String) -> void:
	if choice_panel != null:
		return
	var title := "Choose Your Specialization"
	var sub := "Level %d — this choice shapes the rest of your journey." % GD.SPEC_LEVEL
	var opts: Array = []
	if kind == "spec":
		for id in GD.specs_for(player.class_id):
			var s: Dictionary = GD.SPECS[id]
			opts.append({"id": id, "name": s["name"], "color": Color(String(s["color"])),
				"body": "%s\n\nTechnique: %s — %s\n\nEquip the technique through the Grimoire after choosing this path." % [s["tagline"], s["skill"]["name"], s["skill"]["desc"]]})
	elif kind == "adv":
		var sp: Dictionary = GD.SPECS[player.spec]
		title = "%s: Advanced Path" % sp["name"]
		sub = "Level %d — refine your specialization." % GD.ADVANCED_LEVEL
		for a in sp["advanced"]:
			opts.append({"id": a["id"], "name": a["name"], "color": Color(String(sp["color"])), "body": a["desc"]})
	else:
		title = "Heroic Talents"
		sub = "Level %d — the pinnacle of your oath." % GD.MAX_LEVEL
		for h in GD.HEROIC:
			opts.append({"id": h["id"], "name": h["name"], "color": Color("ffd76a"), "body": h["desc"]})

	var m := _modal()
	choice_panel = m[0]
	var box: VBoxContainer = m[1]
	box.add_child(_label(title, 34, GOLD))
	box.add_child(_label(sub, 18, Color("a99f8a")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	for o in opts:
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(360, 0)
		card.add_theme_constant_override("separation", 10)
		var holder := PanelContainer.new()
		var col: Color = o["color"]
		holder.add_theme_stylebox_override("panel", _style(col.darkened(0.3), Color(0.1, 0.1, 0.15, 0.95)))
		holder.add_child(card)
		row.add_child(holder)
		card.add_child(_label(o["name"], 26, col))
		var body := _label(o["body"], 17)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		body.custom_minimum_size = Vector2(330, 150)
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.add_child(body)
		var id: String = o["id"]
		var label: String = o["name"]
		var choose_button := _button("Choose", func() -> void: _choose(kind, id, label, col), Vector2(0, 46))
		choose_button.disabled = player.level < (GD.SPEC_LEVEL if kind == "spec" else GD.ADVANCED_LEVEL)
		card.add_child(choose_button)
	_refresh_pause()


func _choose(kind: String, id: String, label: String, color: Color) -> void:
	if choice_panel == null: return
	if kind == "spec" and (player.level < GD.SPEC_LEVEL or not GD.specs_for(player.class_id).has(id)): return
	if kind == "adv" and (player.level < GD.ADVANCED_LEVEL or player.spec == "" or id != GD.SPECS[player.spec].advanced[0].id): return
	match kind:
		"spec":
			player.spec = id
		"adv":
			player.adv = id
		_:
			player.heroic = id
	choice_panel.queue_free()
	choice_panel = null
	_refresh_pause()
	main.on_choice_made(kind, label, color)


# ---------------------------------------------------------------- character panel
func toggle_character() -> void:
	if char_panel != null:
		char_panel.queue_free()
		char_panel = null
		_refresh_pause()
		return
	if choice_panel != null or start_panel != null:
		return
	var p := player
	var s: Dictionary = p.stats()
	var m := _modal()
	char_panel = m[0]
	var box: VBoxContainer = m[1]
	box.add_child(_label(p.hero_name, 34, GOLD))
	box.add_child(_label("Level %d %s" % [p.level, p.title()], 20, Color("a99f8a")))
	var lines := "Life %d      Mana %d      Damage %d      Armor %d\nCrit chance %.1f%%      Cooldown speed +%d%%      Gold %d      Slain %d" % [
		int(s["max_hp"]), int(s["max_mp"]), int(round(float(s["dmg"]))), int(round(float(s["armor"]))),
		float(s["crit"]) * 100.0, int(round(float(s["m"]["cdr"]) * 100.0)), p.gold, p.kills]
	box.add_child(_label(lines, 19))
	for slot in ["weapon", "armor", "helm", "amulet"]:
		var it = p.gear[slot]
		if it == null:
			box.add_child(_label("%s: — empty —" % slot.capitalize(), 18, Color("7d766a")))
		else:
			box.add_child(_label("%s: %s  (%s)" % [slot.capitalize(), it["name"], GD.item_line(it)], 18, Color(String(GD.RARITY[int(it["rarity"])]["color"]))))
	var path := "Lv 1 · Warrior"
	if p.spec != "":
		path += "\nLv %d · %s" % [GD.SPEC_LEVEL, GD.SPECS[p.spec]["name"]]
	else:
		path += "\nLv %d · Specialization: Paladin, Death Warrior or Dragon Warrior" % GD.SPEC_LEVEL
	path += "\nLv %d · %s" % [GD.ADVANCED_LEVEL, p.title() if p.adv != "" else "Advanced specialization"]
	var hname := "Heroic Talents"
	for h in GD.HEROIC:
		if h["id"] == p.heroic:
			hname = h["name"]
	path += "\nLv %d · %s" % [GD.MAX_LEVEL, hname]
	box.add_child(_label(path, 17, Color("cfc6b2")))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	row.add_child(_button("Close (C)", toggle_character, Vector2(160, 44)))
	var reset := _button("Reset progress", func() -> void: pass, Vector2(200, 44))
	reset.pressed.connect(func() -> void:
		if reset.text == "Click again to confirm":
			main.reset_save()
		else:
			reset.text = "Click again to confirm")
	row.add_child(reset)
	_refresh_pause()


# ---------------------------------------------------------------- death
func show_death() -> void:
	if death_panel != null:
		return
	var m := _modal(Color(0.2, 0.0, 0.0, 0.55))
	death_panel = m[0]
	var box: VBoxContainer = m[1]
	box.add_child(_label("You Have Fallen", 48, Color("dd3333")))
	box.add_child(_button("Rise again in Crownsfall", func() -> void:
		death_panel.queue_free()
		death_panel = null
		main.respawn(), Vector2(0, 52)))


# ================================================================ drawn HUD
class HudDraw extends Control:
	const TITLE_FONT := preload("res://assets/fonts/Cinzel.ttf")
	const HEALTH_FLASK := preload("res://assets/ui/corner_hud/health_flask.png")
	const LIFE_FRAME := preload("res://assets/ui/corner_hud/life_frame.png")
	const MANA_FRAME := preload("res://assets/ui/corner_hud/mana_frame.png")
	var icon_cache := {}
	var hud: CanvasLayer

	func _orb(c: Vector2, r: float, col: Color, frac: float, label: String) -> void:
		draw_circle(c, r + 10, BRONZE.darkened(0.35))
		draw_circle(c, r + 4, Color(0.03, 0.03, 0.05))
		frac = clampf(frac, 0.0, 1.0)
		# Layered curved liquid retains a fixed surface as its volume drains.
		var surface := r*(1.0-2.0*frac)
		for layer in 24:
			var rr := r*(1.0-float(layer)/31.0)
			if surface >= rr: continue
			var color := col.darkened(0.72).lerp(col.lightened(0.12),float(layer)/24.0)
			if surface <= -rr: draw_circle(c,rr,color)
			else:
				var a0 := asin(clampf(surface/rr,-1,1))
				var pts := PackedVector2Array()
				for i in 49:
					var a := a0+(PI-2*a0)*i/48.0
					pts.append(c+Vector2(cos(a),sin(a))*rr)
				draw_colored_polygon(pts,color)
		if frac > 0.7:
			draw_circle(c+Vector2(-r*0.3,-r*0.38),r*0.14,Color(1,1,1,0.16))
			draw_circle(c+Vector2(-r*0.33,-r*0.42),r*0.065,Color(1,1,1,0.4))
		draw_arc(c,r+3,0,TAU,64,BRONZE.darkened(0.4),2,true)
		if not label.is_empty(): _text_c(label,c+Vector2(0,7),20,Color.WHITE)

	func _text_c(s: String, at: Vector2, size: int, col: Color, outline := 5) -> void:
		var font := ThemeDB.fallback_font
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if outline > 0:
			draw_string_outline(font, at - Vector2(w / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(0, 0, 0, col.a * 0.9))
		draw_string(font, at - Vector2(w / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

	func _icon(id: String, r: Rect2, col: Color) -> void:
		if ART.action_icon(id)!=ART.icon(id):
			draw_texture_rect(ART.action_icon(id), r.grow(-2), false)
			return
		var icon_path := "res://assets/icons/%s.svg" % id
		if ResourceLoader.exists(icon_path) or ResourceLoader.exists("res://assets/painted_icons/%s.png" % id):
			draw_texture_rect(ART.icon(id), r.grow(-3), false)
			return
		var c := r.get_center()
		match id:
			"slash":
				draw_line(c + Vector2(-16, 16), c + Vector2(16, -16), col, 6.0, true)
				draw_line(c + Vector2(-20, 6), c + Vector2(-6, 20), col, 4.0, true)
			"cleave":
				draw_arc(c + Vector2(0, 10), 24, PI * 1.1, PI * 1.9, 24, col, 7.0, true)
				draw_arc(c + Vector2(0, 10), 14, PI * 1.15, PI * 1.85, 24, col, 3.0, true)
			"charge":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -22), c + Vector2(19, -15), c + Vector2(17, 6), c + Vector2(0, 22), c + Vector2(-17, 6), c + Vector2(-19, -15)]), col)
				draw_rect(Rect2(c + Vector2(-2, -17), Vector2(4, 32)), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(c + Vector2(-13, -7), Vector2(26, 4)), Color(0, 0, 0, 0.35))
			"rally":
				for i in 8:
					var a := i / 8.0 * TAU
					draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a), sin(a)) * 24, c + Vector2(cos(a + 0.3), sin(a + 0.3)) * 10]), col)
			"hammer":
				draw_set_transform(c, -0.7, Vector2.ONE)
				draw_rect(Rect2(-3, -6, 6, 28), col)
				draw_rect(Rect2(-14, -20, 28, 15), col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"harvest":
				draw_arc(c, 19, 0, TAU, 32, col, 4.0, true)
				draw_circle(c + Vector2(0, -2), 10, col)
				draw_rect(Rect2(c + Vector2(-6, -5), Vector2(4, 4)), Color.BLACK)
				draw_rect(Rect2(c + Vector2(2, -5), Vector2(4, 4)), Color.BLACK)
			"breath":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-22, 2), c + Vector2(-4, -20), c + Vector2(22, -12), c + Vector2(8, -4), c + Vector2(20, 4), c + Vector2(6, 8), c + Vector2(18, 20), c + Vector2(-8, 18)]), col)
			"lock":
				draw_arc(c + Vector2(0, -5), 9, PI, TAU, 16, Color(0.6, 0.6, 0.6), 4.0, true)
				draw_rect(Rect2(c + Vector2(-13, -5), Vector2(26, 20)), Color(0.6, 0.6, 0.6))
			"potion":
				draw_rect(Rect2(c + Vector2(-5, -24), Vector2(10, 9)), Color("c9b38a"))
				draw_circle(c + Vector2(0, 6), 16, Color("a8121c"))
				draw_circle(c + Vector2(-2, 4), 11, Color("e0434a"))
				draw_circle(c + Vector2(-6, 0), 4, Color(1, 1, 1, 0.5))

	func _draw() -> void:
		var p: Node2D = hud.player
		var main: Node2D = hud.main
		if p == null:
			return
		var s: Dictionary = p.stats()
		var w := size.x
		var h := size.y
		var font := ThemeDB.fallback_font
		var now := Time.get_ticks_msec() / 1000.0

		# screen tints
		if main.rift["active"]:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.24, 0.08, 0.5, 0.12 + 0.03 * sin(now * 2.0)))
		if main.hurt_flash > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.8, 0.0, 0.0, main.hurt_flash * 0.22))
		var max_hp: float = s["max_hp"]
		if p.hp / max_hp < 0.3 and not p.dead:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.6, 0.0, 0.0, 0.1 + 0.08 * sin(now * 6.0)), false, 60.0)

		var layout := Layout.for_viewport(size)
		var scale: float = layout.scale
		# A quiet corner wordmark; actual menus expand below it on demand.
		draw_string_outline(TITLE_FONT, Vector2(26, 53), "AGE OF THE LOST", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, 6, Color("141015"))
		draw_string(TITLE_FONT, Vector2(26, 53), "AGE OF THE LOST", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("e5dfd0"))
		draw_line(Vector2(26, 70), Vector2(324, 70), BRONZE, 1.0)
		draw_string(font, Vector2(65, 93), "C R O W N S F A L L", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GOLD)
		# Identity follows the actual actor/camera, including camera shake and zoom.
		var actor_height: float = 246.0 if p.class_id == "mage" else 286.0
		var at: Vector2 = p.get_global_transform_with_canvas().origin - Vector2(0, actor_height*main.cam.zoom.y+18)
		_text_c(p.hero_name, at-Vector2(0,15), 18, Color("efe6d2"), 4)
		draw_circle(at-Vector2(64,1), 15, DARK)
		draw_arc(at-Vector2(64,1), 15, 0, TAU, 32, BRONZE, 2, true)
		_text_c(str(p.level), at-Vector2(64,-5), 15, GOLD, 2)
		for resource in 2:
			var bar := Rect2(at+Vector2(-44,resource*8),Vector2(100,6))
			var fraction: float = p.hp/max_hp if resource == 0 else p.mp/float(s.max_mp)
			draw_rect(bar.grow(1), Color("17151a"))
			draw_rect(Rect2(bar.position,Vector2(bar.size.x*clampf(fraction,0,1),bar.size.y)),Color("648b48") if resource == 0 else Color("416da5"))
		var status := ""
		if p.ward_time > 0 and p.ward_amount > 0: status = "Ward %d" % p.ward_amount
		if p.rally > 0: status += "  Rallied %ds" % int(ceil(p.rally))
		if not status.is_empty(): _text_c(status,at+Vector2(0,31),15,GOLD)

		# Map geometry is the actual navigable plaza, not invented corridors.
		var mm := Rect2(w-284, 14, 270, 194)
		draw_rect(mm, DARK)
		draw_rect(mm, BRONZE, false, 2)
		draw_string(font,mm.position+Vector2(12,23),"Crownsfall",HORIZONTAL_ALIGNMENT_LEFT,-1,18,GOLD)
		draw_string(font,mm.position+Vector2(12,43),"Central Plaza",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("c4bdaf"))
		var map_area := Rect2(mm.position+Vector2(14,56),mm.size-Vector2(28,70))
		var src_pos := Vector2(700,260)
		var src_size := Vector2(1740,1340)
		var k := map_area.size/src_size
		var polygon := PackedVector2Array()
		for vertex in main.WALKABLE: polygon.append(map_area.position+(vertex-src_pos)*k)
		draw_colored_polygon(polygon,Color("494443"))
		polygon.append(polygon[0]); draw_polyline(polygon,Color("b0a48c"),1.4,true)
		if main.rift["active"]: draw_circle(map_area.position+(main.RIFT_POS-src_pos)*k,5,Color("a070ff"))
		for e in main.enemies:
			var ep: Vector2 = map_area.position+(e.position-src_pos)*k
			if map_area.has_point(ep): draw_circle(ep,3.5 if e.elite else 2.5,Color("ff9a2e") if e.elite else Color("e23b3b"))
		var marker: Vector2 = map_area.position+(p.position-src_pos)*k
		draw_circle(marker,5,Color.BLACK); draw_circle(marker,3.5,Color("ffe9a8"))
		var zone := ""
		if main.rift["active"]: zone = "Reality Scar · Wave %d" % maxi(1,int(main.rift["wave"]))
		var in_trial: bool = is_instance_valid(main.encounter) and main.encounter.active
		if in_trial: zone = "Cantor Trial · Verse %d" % (2 if main.encounter.second_phase else 1)
		var qr := Rect2(mm.position.x,mm.end.y+12,mm.size.x,108 if not zone.is_empty() else 82)
		draw_rect(qr,Color(0.06,0.055,0.07,0.78))
		draw_line(qr.position,qr.position+Vector2(qr.size.x,0),BRONZE,1)
		draw_string(font,qr.position+Vector2(12,26),("Silence the Cantor" if in_trial else main.quest_title()),HORIZONTAL_ALIGNMENT_LEFT,qr.size.x-20,18,GOLD)
		draw_multiline_string(font,qr.position+Vector2(12,49),("Read the seals. R to retreat." if in_trial else main.quest_text()),HORIZONTAL_ALIGNMENT_LEFT,qr.size.x-20,15,2,Color("efe6d2"))
		if not zone.is_empty(): draw_string(font,qr.position+Vector2(12,94),zone,HORIZONTAL_ALIGNMENT_LEFT,qr.size.x-20,15,Color("d3b5e1"))

		# Corner HUD: approved square skill art, shared draw/click geometry.
		var sz: float = 64*scale
		var n := SLOTS.size()
		var bar := Rect2(layout.skills[0].position-Vector2(8,8)*scale,Vector2(368,104)*scale)
		draw_rect(bar,DARK); draw_rect(bar,BRONZE,false,2)
		var cols: Array = p.fx_colors()
		var mouse := get_local_mouse_position()
		var tip: Dictionary = {}
		var tip_rect := Rect2()
		for i in n:
			var r: Rect2 = layout.skills[i]
			draw_rect(r,Color(0.11,0.11,0.16))
			var slot: String = SLOTS[i][0]
			var sk: Dictionary = p.skill_def(slot)
			if sk.is_empty():
				_icon("lock", r, Color.GRAY)
				draw_rect(r, BRONZE.darkened(0.5), false, 2.0)
				if hud.char_panel==null and r.has_point(mouse):
					tip = {"name": "Locked", "desc": "Open Spellbook (K) to equip a known ability.", "meta": ""}
					tip_rect = r
			else:
				var col: Color = Color.WHITE if slot == "basic" else (cols[1] if slot == "s4" else cols[0])
				_icon(String(sk.get("variant",sk.id)), r, col)
				var active_aura: bool = sk.get("type", "") == "aura" and p.aura.running
				var cd: float = p.cds.get(sk["id"], 0.0)
				var full: float = maxf(0.001, p.cd_full.get(sk["id"], 1.0))
				if cd > 0.0:
					draw_rect(Rect2(r.position, Vector2(sz, sz * clampf(cd / full, 0.0, 1.0))), Color(0, 0, 0, 0.72))
					if cd > 0.6 and slot != "basic" and not active_aura:
						_text_c(str(int(ceil(cd))), r.get_center() + Vector2(0, 8), 24, Color.WHITE)
				if active_aura: _text_c("ON",r.get_center()+Vector2(0,8),21,Color("ffc67d"))
				var no_mana: bool = not active_aura and float(sk["mana"]) > 0.0 and p.mp < float(sk["mana"])
				draw_rect(r, Color("2a5bd8") if no_mana else BRONZE.darkened(0.25), false, 3.0 if no_mana else 2.0)
				if hud.char_panel==null and r.has_point(mouse):
					var meta := "%ss cooldown" % str(sk["cd"])
					if sk.get("type", "") == "aura": meta = "%.2f mana / %.1fs pulse · toggle off freely" % [sk.pulse_cost,sk.pulse_interval]
					if float(sk["mana"]) > 0.0:
						meta = "%d mana · %s" % [int(sk["mana"]), meta]
					tip = {"name": sk["name"], "desc": sk["desc"], "meta": meta}
					tip_rect = r
			_text_c(SLOTS[i][1],Vector2(r.get_center().x,r.end.y+23*scale),maxi(12,int(17*scale)),Color("d5c9b3"),3)
		var potion: Rect2 = layout.potion
		draw_rect(potion.grow(8*scale),DARK); draw_rect(potion.grow(8*scale),BRONZE,false,2)
		# Five vessels visualize the existing shared health-potion charges.
		# They are not five independently bound or new mana-potion systems.
		for i in 5:
			var bottle := Rect2(potion.position+Vector2((i*48-10)*scale,0),Vector2(64,64)*scale)
			draw_texture_rect(HEALTH_FLASK,bottle,false,Color.WHITE if i<p.potions else Color(0.26,0.25,0.24,0.65))
		_text_c("Q  ·  Health  %d" % p.potions,Vector2(potion.get_center().x,potion.end.y+23*scale),maxi(12,int(17*scale)),Color("d5c9b3"),3)
		if hud.char_panel == null and potion.has_point(mouse):
			tip = {"name":"Health Potion","desc":"Restore 45% of your life. Five vessels show remaining charges.","meta":"Q or click · %d remaining" % p.potions}
			tip_rect = potion
		var max_mp: float = s["max_mp"]
		_orb(layout.life,layout.radius,Color(0.56,0.025,0.05),p.hp/max_hp,"")
		_orb(layout.mana,layout.radius,Color(0.055,0.19,0.56),p.mp/max_mp,"")
		var frame_scale: float = layout.radius/190.0
		draw_texture_rect(LIFE_FRAME,Rect2(layout.life-Vector2(359,393.5)*frame_scale,Vector2(672,760)*frame_scale),false)
		draw_texture_rect(MANA_FRAME,Rect2(layout.mana-Vector2(298,393.5)*frame_scale,Vector2(672,760)*frame_scale),false)
		_text_c("HP %d / %d" % [int(ceil(p.hp)),int(max_hp)],Vector2(potion.get_center().x,potion.position.y-24*scale),maxi(12,int(17*scale)),Color("eee1cd"),4)
		_text_c("MP %d / %d" % [int(p.mp),int(max_mp)],Vector2(bar.get_center().x,bar.position.y-16*scale),maxi(12,int(17*scale)),Color("eee1cd"),4)
		var xr: Rect2 = layout.xp
		draw_rect(xr,Color(0.025,0.025,0.03))
		var need: int = GD.xp_need(p.level)
		var xf: float = 1.0 if p.level>=GD.MAX_LEVEL else clampf(float(p.xp)/need,0,1)
		draw_rect(Rect2(xr.position,Vector2(xr.size.x*xf,xr.size.y)),Color("784fb1"))
		draw_rect(xr,BRONZE,false,1.5)
		draw_rect(Rect2(w/2-40,xr.position.y-27,80,23),DARK)
		_text_c("Lv. %d" % p.level,Vector2(w/2,xr.position.y-7),15,Color("e1d8c7"),4)
		if xr.has_point(mouse): _text_c("Max level" if p.level>=GD.MAX_LEVEL else "XP %d / %d" % [p.xp,need],Vector2(w/2,xr.position.y-30),16,GOLD)

		# skill tooltip
		if not tip.is_empty():
			var tw := 360.0
			var tr := Rect2(clampf(tip_rect.get_center().x - tw / 2, 8, w - tw - 8), tip_rect.position.y - 126, tw, 110)
			draw_rect(tr, DARK)
			draw_rect(tr, GOLD.darkened(0.2), false, 2.0)
			draw_string(font, tr.position + Vector2(12, 26), tip["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GOLD)
			draw_multiline_string(font, tr.position + Vector2(12, 50), tip["desc"], HORIZONTAL_ALIGNMENT_LEFT, tw - 24, 16, 2, Color("efe6d2"))
			draw_string(font, tr.position + Vector2(12, 98), tip["meta"], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("a99f8a"))

		# hovered or targeted enemy
		var he: Node2D = main.hover_enemy
		if he == null and p.target != null and is_instance_valid(p.target) and p.target.dead_t < 0.0:
			he = p.target
		if he != null and is_instance_valid(he) and not (is_instance_valid(main.encounter) and main.encounter.active):
			var fw := 460.0
			var fr := Rect2(w / 2 - fw / 2, 20, fw, 24)
			draw_rect(fr.grow(3), Color(0.04, 0.04, 0.06, 0.85))
			draw_rect(fr, Color("3a0a0e"))
			draw_rect(Rect2(fr.position, Vector2(fw * clampf(he.hp / he.max_hp, 0.0, 1.0), fr.size.y)), Color("d07a1e") if he.elite else Color("b3242e"))
			_text_c("%s  ·  Lv %d%s" % [he.ename, he.level, "  ·  Elite" if he.elite else ""], fr.get_center() + Vector2(0, 6), 17, Color("ffd27a") if he.elite else Color("f2e6d0"), 4)

		# toasts and banner
		var ty := h * 0.2
		for t in hud.toasts:
			var a: float = clampf(minf(float(t["t"]) * 5.0, (2.8 - float(t["t"])) * 2.0), 0.0, 1.0)
			var c: Color = t["color"]
			c.a = a
			_text_c(t["text"], Vector2(w / 2, ty), 20 if t["small"] else 26, c, 6)
			ty += 30.0 if t["small"] else 38.0
		if hud.banner_t < 3.2:
			var a2: float = clampf(minf(hud.banner_t * 2.5, (3.2 - hud.banner_t) * 1.3), 0.0, 1.0)
			_text_c(hud.banner_a, Vector2(w / 2, h * 0.36), 64, Color(GOLD.r, GOLD.g, GOLD.b, a2), 10)
			if hud.banner_b != "":
				_text_c(hud.banner_b, Vector2(w / 2, h * 0.36 + 40), 24, Color(0.94, 0.9, 0.82, a2), 6)
