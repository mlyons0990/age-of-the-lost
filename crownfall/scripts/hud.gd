extends CanvasLayer
## HUD: health and mana orbs, skill bar with cooldowns, XP bar, quest tracker,
## minimap, toasts, plus the start, class-choice, character and death panels.
## Drawn in code for now; painted HUD art can replace HudDraw later.

const GD := preload("res://scripts/game_data.gd")
const Inv := preload("res://scripts/inventory_logic.gd")
const Icons := preload("res://scripts/icons.gd")
const InventoryWindow := preload("res://scripts/inventory_window.gd")
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
var start_panel: Control = null
var death_panel: Control = null
var rift_btn: Button
var top_row: HBoxContainer
var inv_window: Control = null
var lore_panel: Control = null
var journal_panel: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	draw_ctl = HudDraw.new()
	draw_ctl.hud = self
	draw_ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(draw_ctl)

	top_row = HBoxContainer.new()
	top_row.position = Vector2(24, 118)
	top_row.add_theme_constant_override("separation", 8)
	add_child(top_row)
	top_row.add_child(_button("Character (C)", toggle_character))
	top_row.add_child(_button("Inventory (I)", func() -> void: open_inventory("inventory")))
	top_row.add_child(_button("Stash (K)", func() -> void: open_inventory("stash")))
	top_row.add_child(_button("Skills (P)", func() -> void: toggle_left("spellbook")))
	rift_btn = _button("Reality Scar (R)", func() -> void: main.toggle_rift())
	rift_btn.add_theme_color_override("font_color", Color("d9c2ff"))
	top_row.add_child(rift_btn)

	if not main.had_save and not OS.get_cmdline_user_args().has("--autotest"):
		_open_start()


func _process(delta: float) -> void:
	banner_t += delta
	for t in toasts:
		t["t"] += delta
	while toasts.size() > 0 and float(toasts[0]["t"]) > 2.8:
		toasts.pop_front()
	rift_btn.text = "Close Scar (R)" if main.rift["active"] else "Reality Scar (R)"
	top_row.visible = inv_window == null or not inv_window.left_open()
	draw_ctl.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if death_panel != null and ((event as InputEventKey).keycode == KEY_ENTER or (event as InputEventKey).keycode == KEY_KP_ENTER):
		rise_again()
		get_viewport().set_input_as_handled()
		return
	if start_panel != null or choice_panel != null or death_panel != null:
		return
	match (event as InputEventKey).keycode:
		KEY_C:
			toggle_left("character")
			get_viewport().set_input_as_handled()
		KEY_P:
			toggle_left("spellbook")
			get_viewport().set_input_as_handled()
		KEY_I:
			if inv_window != null and inv_window.inv_open:
				close_right()
			else:
				open_inventory("inventory")
			get_viewport().set_input_as_handled()
		KEY_J:
			if lore_panel == null:
				toggle_journal()
			get_viewport().set_input_as_handled()
		KEY_K:
			if inv_window != null and inv_window.mode == "stash":
				close_inventory()
			else:
				open_inventory("stash")
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if lore_panel != null:
				close_lore()
				get_viewport().set_input_as_handled()
				return
			if journal_panel != null:
				toggle_journal()
				get_viewport().set_input_as_handled()
				return
			if inv_window != null:
				close_inventory()
				get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- docked panels
## The panels sit at the screen edges like Path of Exile's and don't pause the game.
## The left side shows one of: character, stash, merchant, spellbook. The right side is the inventory.
func _ensure_window() -> void:
	if inv_window == null:
		inv_window = InventoryWindow.new()
		inv_window.main = main
		inv_window.player = player
		inv_window.hud = self
		add_child(inv_window)


func _panels_blocked() -> bool:
	return start_panel != null or choice_panel != null or death_panel != null or player.dead


## Opens a panel. "inventory" opens only the right side; "stash" and "merchant" open both sides.
func open_inventory(mode: String) -> void:
	if _panels_blocked():
		return
	if mode == "stash" and main.rift["active"]:
		toast("The stash can only be opened while the Scar is closed", Color("d9c2ff"), true)
		return
	if mode == "merchant" and not main.near_merchant():
		toast("Visit Maren at the market stalls to trade", Color("ffe9a8"), true)
		return
	if mode == "merchant" and main.rift["active"]:
		toast("Maren won't trade while the Scar is open", Color("d9c2ff"), true)
		return
	if mode == "merchant" and (main.shop.is_empty() or main.shop_level != player.level):
		main.restock_shop()
	_ensure_window()
	inv_window.inv_open = true
	if mode != "inventory":
		inv_window.set_mode(mode)
	_refresh_pause()


## Opens or closes a left-side page (character, spellbook) without touching the inventory.
func toggle_left(mode: String) -> void:
	if _panels_blocked():
		return
	if inv_window != null and inv_window.mode == mode:
		close_left()
		return
	_ensure_window()
	inv_window.set_mode(mode)


func toggle_character() -> void:
	toggle_left("character")


func close_left() -> void:
	if inv_window == null:
		return
	inv_window.set_mode("inventory")
	if not inv_window.inv_open:
		close_inventory()


func close_right() -> void:
	if inv_window == null:
		return
	inv_window.release_held()
	inv_window.inv_open = false
	if inv_window.mode == "stash" or inv_window.mode == "merchant":
		inv_window.set_mode("inventory")
	if not inv_window.left_open():
		close_inventory()
	main.save_game()


## Closes every docked panel.
func close_inventory() -> void:
	if inv_window == null:
		return
	inv_window.release_held()
	inv_window.queue_free()
	inv_window = null
	_refresh_pause()
	main.save_game()


## Short message near the top of the screen. A repeat of a message still showing
## refreshes it with a count ("x2") instead of stacking another copy.
const TOAST_MAX := 3

func toast(msg: String, color := GOLD, small := false) -> void:
	for t in toasts:
		if t["text"] == msg:
			t["count"] = int(t.get("count", 1)) + 1
			t["t"] = minf(float(t["t"]), 0.2)
			return
	toasts.append({"text": msg, "color": color, "small": small, "t": 0.0, "count": 1})
	while toasts.size() > TOAST_MAX:
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
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	return [root, box]


func _refresh_pause() -> void:
	get_tree().paused = start_panel != null or choice_panel != null or lore_panel != null or journal_panel != null


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
	var help := _label("Left click / hold: move or attack      Shift + click: attack in place\nRight click or 1: Cleave      2: Shield Charge      3: Rallying Cry      4: Spec skill\nQ: potion      R: Reality Scar      C: character      I: inventory      K: stash      E: trade or Lorecast      J: journal      M: mute\nDrag items or click to pick up and put down. Sell to Maren at the market stalls.\nF11: fullscreen      F3: show walk area      Esc: save and quit\n\nThe plaza is safe until you open the Reality Scar. Waves of the Unwritten then break through.\nTester shortcut: L gains a level instantly.", 17, Color("cfc6b2"))
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
	close_inventory()
	var title := "Choose Your Specialization"
	var sub := "Level %d — this choice shapes the rest of your journey." % GD.SPEC_LEVEL
	var opts: Array = []
	if kind == "spec":
		for id in GD.SPECS:
			var s: Dictionary = GD.SPECS[id]
			opts.append({"id": id, "name": s["name"], "color": Color(String(s["color"])),
				"body": "%s\n\nSkill: %s — %s\n\nPassive: %s — %s" % [s["tagline"], s["skill"]["name"], s["skill"]["desc"], s["passive"]["name"], s["passive"]["desc"]]})
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
		card.add_child(_button("Choose", func() -> void: _choose(kind, id, label, col), Vector2(0, 46)))
	_refresh_pause()


func _choose(kind: String, id: String, label: String, color: Color) -> void:
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
# ---------------------------------------------------------------- Lorecasting and the journal
func show_lore(id: String, first: bool) -> void:
	if lore_panel != null:
		close_lore()
	if journal_panel != null:
		toggle_journal()
	var data: Dictionary = GD.LORE[id]
	var m := _modal(Color(0.06, 0.02, 0.14, 0.72))
	lore_panel = m[0]
	var box: VBoxContainer = m[1]
	box.add_child(_label("Lorecasting" if first else "A remembered memory", 16, Color("b48cff")))
	box.add_child(_label(data["title"], 32, Color("e6d8ff")))
	var body := _label(data["text"], 19, Color("efe6d2"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(620, 0)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(body)
	box.add_child(_label("Added to your journal (J)  ·  %d of %d memories found" % [player.lore.size(), GD.LORE.size()] if first else "%d of %d memories found" % [player.lore.size(), GD.LORE.size()], 15, Color("a99f8a")))
	box.add_child(_button("Close", close_lore, Vector2(0, 46)))
	_refresh_pause()


func close_lore() -> void:
	if lore_panel != null:
		lore_panel.queue_free()
		lore_panel = null
	_refresh_pause()


func toggle_journal() -> void:
	if journal_panel != null:
		journal_panel.queue_free()
		journal_panel = null
		_refresh_pause()
		return
	if start_panel != null or choice_panel != null:
		return
	if inv_window != null:
		close_inventory()
	var m := _modal()
	journal_panel = m[0]
	var box: VBoxContainer = m[1]
	box.add_child(_label("Journal", 32, GOLD))
	box.add_child(_label("Memories uncovered by Lorecasting: %d of %d" % [player.lore.size(), GD.LORE.size()], 17, Color("a99f8a")))
	for id in GD.LORE:
		var known: bool = player.lore.has(id)
		var title: String = GD.LORE[id]["title"] if known else "? ? ?"
		var b := _button(title, func() -> void: show_lore(id, false), Vector2(460, 44))
		b.disabled = not known
		b.name = "journal_" + String(id)
		box.add_child(b)
	box.add_child(_label("Look for faint violet sigils in Crownsfall. Some memories only surface after a hard fight.", 15, Color("8f8878")))
	box.add_child(_button("Close (J)", toggle_journal, Vector2(0, 44)))
	_refresh_pause()


func show_death() -> void:
	if death_panel != null:
		return
	close_inventory()
	var m := _modal(Color(0.2, 0.0, 0.0, 0.55))
	death_panel = m[0]
	var box: VBoxContainer = m[1]
	box.add_child(_label("You Have Fallen", 48, Color("dd3333")))
	var info: Dictionary = main.death_info
	box.add_child(_label("Slain by %s" % info.get("killer", "the Unwritten"), 22, Color("efe6d2")))
	if int(info.get("wave", 0)) > 0:
		box.add_child(_label("The Reality Scar closed at wave %d" % int(info["wave"]), 17, Color("c9a8ff")))
	if int(info.get("lost", 0)) > 0:
		box.add_child(_label("Lost %d gold on the way back" % int(info["lost"]), 17, Color("ffd84a")))
	box.add_child(_label("Your gear and items are safe.", 15, Color("a99f8a")))
	var rise := _button("Rise again in Crownsfall  (Enter)", rise_again, Vector2(0, 52))
	rise.name = "rise_again"
	box.add_child(rise)
	rise.grab_focus()


func rise_again() -> void:
	if death_panel == null:
		return
	death_panel.queue_free()
	death_panel = null
	main.respawn()


# ================================================================ drawn HUD
class HudDraw extends Control:
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
		Icons.draw_icon(self, id, r, col)

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

		var left_cov: bool = hud.inv_window != null and hud.inv_window.left_open()
		var right_cov: bool = hud.inv_window != null and hud.inv_window.inv_open
		# top-left: name, level, class
		if not left_cov:
			draw_circle(Vector2(62, 62), 42, BRONZE.darkened(0.3))
			draw_circle(Vector2(62, 62), 37, Color(0.08, 0.08, 0.14))
			_text_c(str(p.level), Vector2(62, 73), 30, GOLD)
			draw_string_outline(font, Vector2(118, 54), p.hero_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Color(0, 0, 0, 0.9))
			draw_string(font, Vector2(118, 54), p.hero_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("efe6d2"))
			var sub: String = p.title()
			if p.rally > 0.0:
				sub += "   ·   Rallied %ds" % int(ceil(p.rally))
			draw_string_outline(font, Vector2(118, 82), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, 5, Color(0, 0, 0, 0.9))
			draw_string(font, Vector2(118, 82), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("cfc6b2"))
			if p.points_free() > 0:
				var pts := "+%d stat points  (C)" % p.points_free()
				var glow := Color(1.0, 0.91, 0.66, 0.65 + 0.35 * sin(now * 4.0))
				draw_string_outline(font, Vector2(24, 196), pts, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 5, Color(0, 0, 0, 0.85))
				draw_string(font, Vector2(24, 196), pts, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, glow)

		# top-right: minimap, zone, quest
		if not right_cov:
			var mm := Rect2(w - 284, 22, 260, 176)
			var src_size := Vector2(1300, 880)
			var tex: Texture2D = main.PLAZA
			var src_pos: Vector2 = (p.position - src_size / 2.0).clamp(Vector2.ZERO, Vector2(tex.get_width(), tex.get_height()) - src_size)
			draw_rect(mm.grow(4), BRONZE.darkened(0.3))
			draw_texture_rect_region(tex, mm, Rect2(src_pos, src_size), Color(0.75, 0.75, 0.85))
			var k: float = mm.size.x / src_size.x
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
			_text_c(zone, Vector2(mm.get_center().x, mm.end.y + 28), 20, GOLD)
			var qr := Rect2(mm.position.x, mm.end.y + 42, mm.size.x, 78)
			draw_rect(qr, DARK)
			draw_rect(qr, BRONZE, false, 2.0)
			draw_string(font, qr.position + Vector2(12, 26), main.quest_title(), HORIZONTAL_ALIGNMENT_LEFT, qr.size.x - 20, 18, GOLD)
			draw_multiline_string(font, qr.position + Vector2(12, 48), main.quest_text(), HORIZONTAL_ALIGNMENT_LEFT, qr.size.x - 20, 15, 2, Color("efe6d2"))

		# bottom: orbs, skill bar, xp
		var cy := h - 84.0
		var sz := 68.0
		var gap := 8.0
		var n := SLOTS.size() + 1
		var bar_w := n * sz + (n - 1) * gap + 12.0
		var x0 := (w - bar_w) / 2.0
		draw_rect(Rect2(x0 - 16, cy - sz / 2 - 12, bar_w + 32, sz + 24), DARK)
		draw_rect(Rect2(x0 - 16, cy - sz / 2 - 12, bar_w + 32, sz + 24), BRONZE, false, 3.0)
		var cols: Array = p.fx_colors()
		var mouse := get_local_mouse_position()
		var tip: Dictionary = {}
		var tip_rect := Rect2()
		for i in n:
			var r := Rect2(x0 + i * (sz + gap) + (12.0 if i == n - 1 else 0.0), cy - sz / 2, sz, sz)
			draw_rect(r, Color(0.11, 0.11, 0.16))
			if i == n - 1:
				_icon("potion", r, Color.WHITE)
				draw_string(font, r.position + Vector2(5, 17), "Q", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
				draw_string(font, r.position + Vector2(sz - 16, sz - 6), str(p.potions), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
				draw_rect(r, BRONZE.darkened(0.25), false, 2.0)
				if r.has_point(mouse):
					tip = {"name": "Health Potion", "desc": "Restore 45% of your life.", "meta": ""}
					tip_rect = r
				continue
			var slot: String = SLOTS[i][0]
			var sk: Dictionary = p.skill_def(slot)
			if sk.is_empty():
				_icon("lock", r, Color.GRAY)
				draw_rect(r, BRONZE.darkened(0.5), false, 2.0)
				if r.has_point(mouse):
					tip = {"name": "Locked", "desc": "Choose a specialization at level %d to unlock this skill." % GD.SPEC_LEVEL, "meta": ""}
					tip_rect = r
			else:
				var col: Color = Color.WHITE if slot == "basic" else (cols[1] if slot == "s4" else cols[0])
				_icon(sk["id"], r, col)
				var cd: float = p.cds.get(slot, 0.0)
				var full: float = p.cd_full.get(slot, 1.0)
				if cd > 0.0:
					draw_rect(Rect2(r.position, Vector2(sz, sz * clampf(cd / full, 0.0, 1.0))), Color(0, 0, 0, 0.72))
					if cd > 0.6 and slot != "basic":
						_text_c(str(int(ceil(cd))), r.get_center() + Vector2(0, 8), 24, Color.WHITE)
				var no_mana: bool = float(sk["mana"]) > 0.0 and p.mp < float(sk["mana"])
				draw_rect(r, Color("2a5bd8") if no_mana else BRONZE.darkened(0.25), false, 3.0 if no_mana else 2.0)
				if r.has_point(mouse):
					var meta := "%ss cooldown" % str(sk["cd"])
					if float(sk["mana"]) > 0.0:
						meta = "%d mana · %s" % [int(sk["mana"]), meta]
					tip = {"name": sk["name"], "desc": sk["desc"], "meta": meta}
					tip_rect = r
			draw_string(font, r.position + Vector2(5, 17), SLOTS[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
		var max_mp: float = s["max_mp"]
		_orb(Vector2(x0 - 100, cy - 8), 60, Color(0.78, 0.1, 0.13), p.hp / max_hp, "%d/%d" % [int(ceil(p.hp)), int(max_hp)])
		_orb(Vector2(x0 + bar_w + 100, cy - 8), 60, Color(0.14, 0.34, 0.86), p.mp / max_mp, "%d/%d" % [int(p.mp), int(max_mp)])
		var xr := Rect2(x0 - 16, cy + sz / 2 + 18, bar_w + 32, 12)
		draw_rect(xr, Color(0.06, 0.06, 0.06))
		var need: int = GD.xp_need(p.level)
		var xf: float = 1.0 if p.level >= GD.MAX_LEVEL else float(p.xp) / need
		draw_rect(Rect2(xr.position, Vector2(xr.size.x * xf, xr.size.y)), GOLD.darkened(0.15))
		draw_rect(xr, BRONZE.darkened(0.25), false, 1.5)
		_text_c("Max level" if p.level >= GD.MAX_LEVEL else "XP %d/%d" % [p.xp, need], xr.get_center() + Vector2(0, 5), 13, Color.WHITE, 4)

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
		var boss_up := false
		for e in main.enemies:
			if e.boss and e.dead_t < 0.0:
				boss_up = true
		if he != null and is_instance_valid(he) and not he.boss:
			var fw := 460.0
			var fr := Rect2(w / 2 - fw / 2, 92.0 if boss_up else 20.0, fw, 24)
			draw_rect(fr.grow(3), Color(0.04, 0.04, 0.06, 0.85))
			draw_rect(fr, Color("3a0a0e"))
			draw_rect(Rect2(fr.position, Vector2(fw * clampf(he.hp / he.max_hp, 0.0, 1.0), fr.size.y)), Color("d07a1e") if he.elite else Color("b3242e"))
			_text_c("%s  ·  Lv %d%s" % [he.ename, he.level, "  ·  Elite" if he.elite else ""], fr.get_center() + Vector2(0, 6), 17, Color("ffd27a") if he.elite else Color("f2e6d0"), 4)
			# what its elite affixes do
			var ay := fr.end.y + 20.0
			for af in he.affixes:
				var ad: Dictionary = GD.ELITE_AFFIXES[af]
				_text_c("%s: %s" % [ad["name"], ad["desc"]], Vector2(w / 2, ay), 15, Color(String(ad["color"])), 4)
				ay += 19.0

		# toasts and banner
		# boss health bar, top centre
		for e in main.enemies:
			if e.boss and e.dead_t < 0.0:
				var bw := 640.0
				var bx := w / 2 - bw / 2
				var by := 46.0
				draw_rect(Rect2(bx - 4, by - 4, bw + 8, 30), Color(0.03, 0.02, 0.05, 0.85))
				draw_rect(Rect2(bx, by, bw * clampf(e.hp / e.max_hp, 0.0, 1.0), 22), Color("c0392b") if e.enraged else Color("8e44ad"))
				draw_rect(Rect2(bx - 4, by - 4, bw + 8, 30), GOLD.darkened(0.2), false, 2.0)
				# enrage threshold tick
				var ex: float = bx + bw * float(e.t["enrage"])
				draw_line(Vector2(ex, by - 2), Vector2(ex, by + 24), Color(1, 0.6, 0.5, 0.8), 2.0)
				_text_c(e.ename + ("  ·  Enraged" if e.enraged else ""), Vector2(w / 2, by - 12), 22, GOLD, 6)
				_text_c("%d / %d" % [int(e.hp), int(e.max_hp)], Vector2(w / 2, by + 17), 15, Color("efe6d2"), 4)
				break
		# toasts sit in a band near the top, each on a dark plate so they read over bright stone
		var ty := 150.0
		for t in hud.toasts:
			var a: float = clampf(minf(float(t["t"]) * 5.0, (2.8 - float(t["t"])) * 2.0), 0.0, 1.0)
			var c: Color = t["color"]
			c.a = a
			var msg: String = t["text"]
			if int(t.get("count", 1)) > 1:
				msg += "  x%d" % int(t["count"])
			var fs: int = 19 if t["small"] else 24
			var tw: float = font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_rect(Rect2(w / 2 - tw / 2 - 16, ty - fs * 0.95, tw + 32, fs + 14), Color(0.03, 0.03, 0.05, 0.55 * a))
			_text_c(msg, Vector2(w / 2, ty), fs, c, 5)
			ty += fs + 20.0
		if hud.banner_t < 3.2:
			var a2: float = clampf(minf(hud.banner_t * 2.5, (3.2 - hud.banner_t) * 1.3), 0.0, 1.0)
			_text_c(hud.banner_a, Vector2(w / 2, h * 0.36), 64, Color(GOLD.r, GOLD.g, GOLD.b, a2), 10)
			if hud.banner_b != "":
				_text_c(hud.banner_b, Vector2(w / 2, h * 0.36 + 40), 24, Color(0.94, 0.9, 0.82, a2), 6)
