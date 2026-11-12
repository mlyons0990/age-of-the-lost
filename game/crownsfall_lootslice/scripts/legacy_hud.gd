extends CanvasLayer
## HUD: health and mana orbs, skill bar with cooldowns, XP bar, quest tracker,
## minimap, toasts, plus the start, class-choice, character and death panels.
## Drawn in code for now; painted HUD art can replace HudDraw later.

const GD := preload("res://scripts/game_data.gd")
const ART := preload("res://scripts/art_library.gd")
const Layout := preload("res://scripts/poe_hud_layout.gd")
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	draw_ctl = HudDraw.new()
	draw_ctl.hud = self
	draw_ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(draw_ctl)

	var row := HBoxContainer.new()
	row.position = Vector2(24, 118)
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	row.add_child(_button("Inventory [I / C]", toggle_character))
	rift_btn = _button("Reality Scar (R)", func() -> void: main.toggle_rift())
	rift_btn.add_theme_color_override("font_color", Color("d9c2ff"))
	row.add_child(rift_btn)

	if not main.had_save and not OS.get_cmdline_user_args().has("--autotest") and not OS.get_cmdline_user_args().has("--systems-test") and not OS.get_cmdline_user_args().has("--mage-test"):
		_open_start()


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
	var help := _label("Left click / hold: move or attack      Shift + click: attack in place\nRight click or 1 / 2 / 3 / 4: equipped skills      Q: potion\nQ: potion      R: open or close the Reality Scar      I / C: inventory      K: spellbook      E: nearby interaction\nF11: fullscreen      F3: show walk area      Esc: close panel or pause\n\nThe plaza is safe until you open the Reality Scar. Waves of the Unwritten then break through.\nDevelopment shortcut: F6 gains a level instantly.", 17, Color("cfc6b2"))
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
	var icon_cache := {}
	var hud: CanvasLayer

	func _orb(c: Vector2, r: float, col: Color, frac: float, label: String) -> void:
		draw_circle(c, r + 10, BRONZE.darkened(0.35))
		draw_circle(c, r + 4, Color(0.03, 0.03, 0.05))
		frac = clampf(frac, 0.0, 1.0)
		if frac >= 0.995:
			draw_circle(c, r, col)
		elif frac > 0.01:
			var y0: float = r * (1.0 - 2.0 * frac)
			var a0: float = asin(clampf(y0 / r, -1.0, 1.0))
			var pts := PackedVector2Array()
			for i in 33:
				var a: float = a0 + (PI - 2.0 * a0) * i / 32.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, col)
		draw_circle(c + Vector2(-r * 0.3, -r * 0.38), r * 0.26, Color(1, 1, 1, 0.22))
		draw_arc(c, r + 7, 0, TAU, 64, BRONZE, 4.0, true)
		_text_c(label, c + Vector2(0, 7), 20, Color.WHITE)

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

	func _bank_frame(rect: Rect2, metal: Color) -> void:
		draw_rect(rect.grow(4), Color("080c16e8"))
		draw_rect(rect.grow(2), Color("352c26"), false, 2.0)
		draw_rect(rect, metal.darkened(0.22), false, 1.5)
		var line_y: float = rect.position.y - 4.0
		draw_line(Vector2(rect.position.x + 8, line_y), Vector2(rect.end.x - 8, line_y), metal, 1.2, true)
		for side in [rect.position.x + 4, rect.end.x - 4]:
			draw_circle(Vector2(side, line_y), 3, metal.darkened(0.12))

	func _flask_slot(r: Rect2, liquid: Color, enabled: bool) -> void:
		var opacity: float = 1.0 if enabled else 0.38
		draw_rect(r, Color("11111a"))
		var cx: float = r.get_center().x
		var y: float = r.position.y
		var s: float = r.size.x / 53.0
		# Stylised bottle with a metallic lip, glass highlight and colored contents.
		var glass := Color("b3cad7", 0.76 * opacity)
		var content_color := liquid
		content_color.a = opacity
		draw_rect(Rect2(cx - 7*s, y + 9*s, 14*s, 7*s), Color("bd9560", opacity))
		draw_rect(Rect2(cx - 9*s, y + 5*s, 18*s, 5*s), Color("ead4a3", opacity))
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 13*s,y + 17*s), Vector2(cx + 13*s,y + 17*s),
			Vector2(cx + 17*s,y + 25*s), Vector2(cx + 13*s,y + 43*s),
			Vector2(cx - 13*s,y + 43*s), Vector2(cx - 17*s,y + 25*s)]), glass)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 12*s,y + 27*s), Vector2(cx + 12*s,y + 27*s),
			Vector2(cx + 12*s,y + 41*s), Vector2(cx - 12*s,y + 41*s)]), content_color)
		draw_line(Vector2(cx - 8*s,y + 20*s), Vector2(cx - 8*s,y + 37*s), Color(1,1,1,0.55*opacity), 2*s, true)
		draw_rect(r, BRONZE.darkened(0.4), false, maxf(1.0, 2.0*s))

	func _draw_ornamented_orb(c: Vector2, radius: float, liquid: Color, frac: float) -> void:
		_orb(c, radius, liquid, frac, "")
		for i in 12:
			var a: float = TAU * float(i) / 12.0
			var out: Vector2 = c + Vector2(cos(a), sin(a)) * (radius + 12)
			var inner: Vector2 = c + Vector2(cos(a), sin(a)) * (radius + 6)
			draw_line(inner, out, GOLD.darkened(0.24), 2.0, true)
		draw_circle(c + Vector2(0, radius + 10), 4, GOLD)
		draw_arc(c, radius + 15, PI * 0.22, PI * 0.78, 24, Color("c7aa72"), 2.0, true)

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

		# top-left: name, level, class
		draw_circle(Vector2(62, 62), 42, BRONZE.darkened(0.3))
		draw_circle(Vector2(62, 62), 37, Color(0.08, 0.08, 0.14))
		_text_c(str(p.level), Vector2(62, 73), 30, GOLD)
		draw_string_outline(font, Vector2(118, 54), p.hero_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(118, 54), p.hero_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("efe6d2"))
		var sub: String = p.title()
		if p.ward_time > 0.0 and p.ward_amount > 0:
			sub += "   ·   Ward %d / %.1fs" % [p.ward_amount, p.ward_time]
		if p.rally > 0.0:
			sub += "   ·   Rallied %ds" % int(ceil(p.rally))
		draw_string_outline(font, Vector2(118, 82), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, 5, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(118, 82), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("cfc6b2"))

		# top-right: minimap, zone, quest
		var mm := Rect2(w - 284, 22, 260, 176)
		var src_size := Vector2(1300, 880)
		var tex: Texture2D = main.PLAZA
		var src_pos: Vector2 = (p.position - src_size / 2.0).clamp(Vector2.ZERO, Vector2(tex.get_width(), tex.get_height()) - src_size)
		draw_rect(mm.grow(4), BRONZE.darkened(0.3))
		draw_texture_rect_region(tex, mm, Rect2(src_pos, src_size), Color(0.75, 0.75, 0.85))
		var k: Vector2 = mm.size / src_size
		if main.rift["active"]:
			draw_circle(mm.position + (main.RIFT_POS - src_pos) * k, 6, Color("a070ff"))
		for e in main.enemies:
			var ep: Vector2 = mm.position + (e.position - src_pos) * k
			if mm.has_point(ep):
				draw_circle(ep, 4.5 if e.elite else 3.0, Color("ff9a2e") if e.elite else Color("e23b3b"))
		draw_circle(mm.position + (p.position - src_pos) * k, 4.5, Color.BLACK)
		draw_circle(mm.position + (p.position - src_pos) * k, 3.5, Color("ffe9a8"))
		draw_rect(mm, GOLD.darkened(0.2), false, 2.0)
		var zone := "Crownsfall"
		if main.rift["active"]:
			zone = "Reality Scar · Wave %d" % maxi(1, int(main.rift["wave"]))
		var in_trial: bool = is_instance_valid(main.encounter) and main.encounter.active
		if in_trial: zone = "Cantor Trial · Verse %d" % (2 if main.encounter.second_phase else 1)
		_text_c(zone, Vector2(mm.get_center().x, mm.end.y + 28), 20, GOLD)
		var qr := Rect2(mm.position.x, mm.end.y + 42, mm.size.x, 78)
		draw_rect(qr, DARK)
		draw_rect(qr, BRONZE, false, 2.0)
		draw_string(font, qr.position + Vector2(12, 26), ("Silence the Cantor" if in_trial else main.quest_title()), HORIZONTAL_ALIGNMENT_LEFT, qr.size.x - 20, 18, GOLD)
		draw_multiline_string(font, qr.position + Vector2(12, 48), ("Read the seals. R to retreat." if in_trial else main.quest_text()), HORIZONTAL_ALIGNMENT_LEFT, qr.size.x - 20, 15, 2, Color("efe6d2"))

		# Phase 03: painterly Path-of-Exile-inspired screen edges.
		# The *actual* main game, not the independent 2.5D rig lab, uses this.
		# Geometry comes from one pure model shared with the input hitboxes;
		# hotbar IDs, mana rules, cooldowns and potion ownership are unchanged.
		var geometry: Dictionary = Layout.compute(size)
		var unit: float = geometry["scale"]
		var radius: float = geometry["radius"]
		var skill_rects: Array = geometry["skills"]
		var flask_rects: Array = geometry["flasks"]
		var left_panel: Rect2 = geometry["left_panel"]
		var right_panel: Rect2 = geometry["right_panel"]
		var xp_rect: Rect2 = geometry["xp_rect"]
		_bank_frame(left_panel, GOLD)
		_bank_frame(right_panel, Color("9ba8c6"))
		var mouse := get_local_mouse_position()
		var tip: Dictionary = {}
		var tip_rect := Rect2()

		# Q is the ONE implemented health potion. Four future flask slots are
		# intentionally dark / unassigned; they cannot spend or duplicate items.
		for i in flask_rects.size():
			var r: Rect2 = flask_rects[i]
			var assigned: bool = i == 0
			var fluid := Color("cf2735") if i < 3 else Color("3164cb")
			_flask_slot(r, fluid, assigned)
			if assigned:
				_text_c("Q", r.position + Vector2(9.0 * unit, 15.0 * unit), maxi(11, int(13 * unit)), Color("ffe5ae"), 3)
				_text_c(str(p.potions), r.end - Vector2(10.0 * unit, 7.0 * unit), maxi(12, int(16 * unit)), Color.WHITE, 3)
			else:
				_text_c("—", r.get_center() + Vector2(0, 16.0 * unit), maxi(12, int(17 * unit)), Color("aaa39a"), 2)
			if hud.char_panel == null and r.has_point(mouse):
				tip = {"name":"Health Potion", "desc":"Restore 45% life from your inventory.", "meta":"Q · %d remaining" % p.potions} if assigned else {"name":"Flask slot %d" % (i + 1), "desc":"Unassigned. Future flask types will go here.", "meta":"No item assigned or consumed."}
				tip_rect = r
		var cols: Array = p.fx_colors()
		for i in skill_rects.size():
			var r: Rect2 = skill_rects[i]
			draw_rect(r, Color("151a28"))
			draw_rect(r.grow(2.0 * unit), BRONZE.darkened(0.38), false, 1.0 * unit)
			var slot: String = SLOTS[i][0]
			var sk: Dictionary = p.skill_def(slot)
			if sk.is_empty():
				_icon("lock", r, Color.GRAY)
				draw_rect(r, BRONZE.darkened(0.55), false, 2.0 * unit)
				if hud.char_panel == null and r.has_point(mouse):
					tip = {"name":"Locked", "desc":"Open the Grimoire (K) and equip a known ability.", "meta":""}
					tip_rect = r
			else:
				var col: Color = Color.WHITE if slot == "basic" else (cols[1] if slot == "s4" else cols[0])
				_icon(String(sk.get("variant", sk.id)), r, col)
				var active_aura: bool = sk.get("type", "") == "aura" and p.aura.running
				var cd: float = p.cds.get(sk["id"], 0.0)
				var full: float = maxf(0.001, p.cd_full.get(sk["id"], 1.0))
				if cd > 0.0:
					draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * clampf(cd / full, 0.0, 1.0))), Color(0, 0, 0, 0.72))
					if cd > 0.6 and slot != "basic" and not active_aura:
						_text_c(str(int(ceil(cd))), r.get_center() + Vector2(0, 8 * unit), maxi(14, int(22 * unit)), Color.WHITE)
				if active_aura: _text_c("ON", r.get_center() + Vector2(0, 8 * unit), maxi(13, int(20 * unit)), Color("ffc67d"))
				var no_mana: bool = not active_aura and float(sk["mana"]) > 0.0 and p.mp < float(sk["mana"])
				draw_rect(r, Color("2a5bd8") if no_mana else BRONZE.darkened(0.25), false, (3.0 if no_mana else 2.0) * unit)
				if hud.char_panel == null and r.has_point(mouse):
					var meta := "%ss cooldown" % str(sk["cd"])
					if sk.get("type", "") == "aura": meta = "%.2f mana / %.1fs pulse · toggle off freely" % [sk.pulse_cost,sk.pulse_interval]
					if float(sk["mana"]) > 0.0:
						meta = "%d mana · %s" % [int(sk["mana"]), meta]
					tip = {"name":sk["name"], "desc":sk["desc"], "meta":meta}
					tip_rect = r
			# Existing bindings remain LMB / 1–4; art reference keys do NOT
			# silently remap combat to QWERT or steal Q from the health flask.
			_text_c("LMB" if i == 0 else SLOTS[i][1], r.position + Vector2(13.0 * unit, 14.0 * unit), maxi(9, int(12 * unit)), Color("fff8e4"), 3)

		# Jewelled globe framing is procedural so it scales crisply at 810p/1080p.
		var left_globe: Vector2 = geometry["left_orb"]
		var right_globe: Vector2 = geometry["right_orb"]
		_draw_ornamented_orb(left_globe, radius, Color("b51f2f"), p.hp / max_hp)
		var max_mp: float = s["max_mp"]
		_draw_ornamented_orb(right_globe, radius, Color("225fc7"), p.mp / max_mp)
		_text_c("HP  %d / %d" % [int(ceil(p.hp)), int(max_hp)], left_panel.position + Vector2(left_panel.size.x * 0.55, -13.0 * unit), maxi(11, int(15 * unit)), Color("f5dccb"), 4)
		_text_c("MP  %d / %d" % [int(p.mp), int(max_mp)], right_panel.position + Vector2(right_panel.size.x * 0.48, -13.0 * unit), maxi(11, int(15 * unit)), Color("d4e1ff"), 4)

		# Thin centre XP ledger: resource banks never straddle the playfield.
		draw_rect(xp_rect.grow(2 * unit), Color("110d13"))
		draw_rect(xp_rect, Color("242137"))
		var need: int = GD.xp_need(p.level)
		var xf: float = 1.0 if p.level >= GD.MAX_LEVEL else float(p.xp) / need
		draw_rect(Rect2(xp_rect.position, Vector2(xp_rect.size.x * xf, xp_rect.size.y)), Color("9878c6"))
		draw_rect(xp_rect, GOLD.darkened(0.3), false, maxf(1.0, unit))
		_text_c("LEVEL %d  ·  %s" % [p.level, "MAX" if p.level >= GD.MAX_LEVEL else "%d / %d XP" % [p.xp, need]], xp_rect.get_center() - Vector2(0, 7.0 * unit), maxi(10, int(12 * unit)), Color("f1d9a6"), 3)

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