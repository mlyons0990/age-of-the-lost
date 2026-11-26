extends CanvasLayer
## Game screens over the HUD (same gold/ink style): notifications, area banner, boss bar, NPC dialogue, the
## Quartermaster's shop, inventory + character sheet (I / C), death screen, pause menu (Esc) and the epilogue.
const SYS := preload("res://scripts/systems.gd")
const GD := preload("res://scripts/game_data.gd")
const SAVE := preload("res://scripts/three_d/aotl_save.gd")
const GOLD := Color("d9b46a")
const GOLD_DIM := Color("8f7444")
const IVORY := Color("efe6cf")
const INK := Color(0.045, 0.04, 0.04, 0.96)
const CELL := 46.0
const POTION_PRICE := {"health": 20, "mana": 20}

var dir
var font: Font
var font_r: Font
var root: Control
var toasts: VBoxContainer
var banner: Label
var banner_sub: Label
var banner_t := 0.0
var boss_bar: Control
var boss_ref = null
var panel: Control = null          # the one open modal panel (dialogue / shop / pause / death / epilogue)
var panel_kind := ""
var inv: Control                   # inventory + character (can be open with the shop)
var inv_draw: Control
var hover_item: Dictionary = {}
var hover_slot := ""
var tip: PanelContainer
var tip_label: RichTextLabel

func setup(director) -> void:
	dir = director
	layer = 30
	font = load("res://assets/fonts/LiberationSerif-Bold.ttf")
	font_r = load("res://assets/fonts/LiberationSerif-Regular.ttf")
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	toasts = VBoxContainer.new()
	toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toasts.position = Vector2(-500, 150)
	toasts.size = Vector2(1000, 300)
	toasts.add_theme_constant_override("separation", 4)
	root.add_child(toasts)
	banner = _label("", 44, GOLD)
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.position = Vector2(-500, 70); banner.size = Vector2(1000, 60)
	root.add_child(banner)
	banner_sub = _label("", 20, IVORY, false)
	banner_sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_sub.position = Vector2(-500, 122); banner_sub.size = Vector2(1000, 30)
	root.add_child(banner_sub)
	boss_bar = Control.new()
	boss_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_bar.position = Vector2(-330, 22); boss_bar.size = Vector2(660, 48)
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.visible = false
	boss_bar.draw.connect(_draw_boss)
	root.add_child(boss_bar)
	_build_inventory()
	tip = PanelContainer.new()
	tip.add_theme_stylebox_override("panel", _box(Color(0.04, 0.035, 0.03, 0.97), GOLD))
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.visible = false
	tip_label = RichTextLabel.new()
	tip_label.bbcode_enabled = true
	tip_label.fit_content = true
	tip_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	tip_label.custom_minimum_size = Vector2(300, 0)
	tip_label.add_theme_font_override("normal_font", font_r)
	tip_label.add_theme_font_override("bold_font", font)
	tip_label.add_theme_font_size_override("normal_font_size", 16)
	tip_label.add_theme_font_size_override("bold_font_size", 18)
	tip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_child(tip_label)
	add_child(tip)

# ---------------- small widgets ----------------

func _label(text: String, size: int, col: Color, bold := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if bold else font_r)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _box(bg: Color, border: Color, w := 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg; sb.border_color = border
	sb.set_border_width_all(w); sb.set_corner_radius_all(3); sb.set_content_margin_all(18)
	return sb

func _button(text: String, cb: Callable, w := 300.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, 44)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", IVORY)
	b.add_theme_color_override("font_hover_color", Color("ffe7a8"))
	b.add_theme_stylebox_override("normal", _box(Color(0.12, 0.09, 0.06, 0.95), GOLD_DIM, 1))
	b.add_theme_stylebox_override("hover", _box(Color(0.2, 0.14, 0.07, 0.98), GOLD, 2))
	b.add_theme_stylebox_override("pressed", _box(Color(0.26, 0.18, 0.08, 1.0), GOLD, 2))
	b.pressed.connect(func(): dir.play("click", -10.0); cb.call())
	return b

func _modal(kind: String, width := 560.0) -> VBoxContainer:
	close_panel()
	panel_kind = kind
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45 if kind in ["pause", "death", "epilogue"] else 0.0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP if kind in ["pause", "death", "epilogue"] else Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _box(INK, GOLD))
	pc.custom_minimum_size = Vector2(width, 0)
	shade.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	panel = shade
	pc.resized.connect(func(): _place(pc, kind))
	_place.call_deferred(pc, kind)
	return v

func _place(pc: Control, kind: String) -> void:
	var vs := root.get_viewport_rect().size
	if kind in ["dialogue"]: pc.position = Vector2((vs.x - pc.size.x) * 0.5, vs.y - pc.size.y - 210)
	elif kind == "shop": pc.position = Vector2(60, (vs.y - pc.size.y) * 0.5 - 40)
	else: pc.position = (vs - pc.size) * 0.5

func close_panel() -> void:
	if panel != null and is_instance_valid(panel): panel.queue_free()
	panel = null
	if panel_kind == "pause": get_tree().paused = false
	panel_kind = ""

## True while a screen that takes the mouse is open (world clicks ignored).
func blocking() -> bool:
	return panel != null or inv.visible

func over_ui(m: Vector2) -> bool:
	if inv.visible and Rect2(inv.position, inv.size).has_point(m): return true
	if panel != null and is_instance_valid(panel):
		for c in panel.get_children():
			if c is Control and Rect2(c.position, c.size).has_point(m): return true
		if panel_kind in ["pause", "death", "epilogue"]: return true
	return false

# ---------------- notifications ----------------

func toast(text: String, col := IVORY, secs := 2.5, size := 24) -> void:
	var l := _label(text, size, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(1000, 0)
	toasts.add_child(l)
	while toasts.get_child_count() > 5: toasts.get_child(0).free()
	var tw := l.create_tween()
	tw.tween_interval(secs)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)

func float_xp(n: int) -> void:
	pass   # XP shows on the bar; kept as a hook for a future floating "+XP"

func area_banner(title: String, sub: String) -> void:
	banner.text = title.to_upper()
	banner_sub.text = sub
	banner.modulate.a = 1.0; banner_sub.modulate.a = 1.0
	var tw := banner.create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(banner, "modulate:a", 0.0, 1.0)
	tw.parallel().tween_property(banner_sub, "modulate:a", 0.0, 1.0)

func update_boss(b) -> void:
	boss_ref = b if b != null and is_instance_valid(b) and b.state not in ["idle", "dead"] else null
	boss_bar.visible = boss_ref != null
	if boss_bar.visible: boss_bar.queue_redraw()

func _draw_boss() -> void:
	if boss_ref == null: return
	var w := boss_bar.size.x
	boss_bar.draw_string_outline(font, Vector2(w * 0.5 - font.get_string_size(boss_ref.ename, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x * 0.5, 18), boss_ref.ename, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 5, Color(0, 0, 0, 0.9))
	boss_bar.draw_string(font, Vector2(w * 0.5 - font.get_string_size(boss_ref.ename, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x * 0.5, 18), boss_ref.ename, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffb08a"))
	var r := Rect2(0, 26, w, 16)
	boss_bar.draw_rect(r.grow(2), Color(0, 0, 0, 0.9))
	boss_bar.draw_rect(Rect2(r.position, Vector2(w * boss_ref.hp / boss_ref.max_hp, r.size.y)), Color("b3261e"))
	boss_bar.draw_rect(r.grow(2), GOLD, false, 1.5)

# ---------------- dialogue ----------------

func dialogue(speaker: String, lines: Array, options: Array) -> void:
	var v := _modal("dialogue", 760.0)
	v.add_child(_label(speaker, 26, GOLD))
	for l in lines:
		var t := _label(String(l), 19, IVORY, false)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(720, 0)
		v.add_child(t)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	for o in options:
		var cb: Callable = o[1]
		row.add_child(_button(String(o[0]), func(): close_panel(); if cb.is_valid(): cb.call(), 260.0))

# ---------------- shop ----------------

func open_vendor() -> void:
	var st = dir.state
	if st.vendor_stock.is_empty() or int(st.vendor_stock[0].get("level", 1)) < st.level - 2:
		st.vendor_stock.clear()
		for i in 4: st.vendor_stock.append(SYS.make_item(st.level, 0.25, "", st.class_id))
	var v := _modal("shop", 470.0)
	v.add_child(_label("Quartermaster Ysolde", 26, GOLD))
	var hi := _label("\"Coin for steel, steel for coin. Click your own gear to sell it.\"", 16, Color("cfc7b8"), false)
	hi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; hi.custom_minimum_size = Vector2(430, 0)
	v.add_child(hi)
	var gold_l := _label("", 19, Color("f2d27a"))
	v.add_child(gold_l)
	var refresh := func(): gold_l.text = "Gold: %d    Potions: %d health / %d mana" % [st.gold, st.potions["health"], st.potions["mana"]]
	refresh.call()
	for k in ["health", "mana"]:
		v.add_child(_button("Buy %s Potion  (%d gold)" % [k.capitalize(), POTION_PRICE[k]], func():
			if st.gold < POTION_PRICE[k]: toast("Not enough gold", Color("ff7a6a"), 1.4, 18); return
			st.gold -= POTION_PRICE[k]; st.potions[k] = mini(99, int(st.potions[k]) + 1); refresh.call(); dir.play("pickup", -8.0), 430.0))
	v.add_child(_label("Wares", 20, GOLD))
	for it in st.vendor_stock.duplicate():
		var price: int = int(it.get("value", 10)) * 2
		var b := _button("%s  (lv %d)  —  %d gold" % [it["name"], int(it["level"]), price], Callable(), 430.0)
		b.add_theme_color_override("font_color", Color(String(GD.RARITY[int(it["rarity"])]["color"])))
		b.pressed.connect(func():
			if st.gold < price: toast("Not enough gold", Color("ff7a6a"), 1.4, 18); return
			if not st.add_item(it): toast("Your bag is full", Color("ff7a6a"), 1.4, 18); return
			st.gold -= price; st.vendor_stock.erase(it); b.queue_free(); refresh.call(); inv_draw.queue_redraw(); dir.autosave())
		b.mouse_entered.connect(func(): _show_tip(it, "Buy for %d gold" % price))
		b.mouse_exited.connect(func(): tip.visible = false)
		v.add_child(b)
	v.add_child(_button("Sell all Common items", func():
		var n := 0; var g := 0
		for it in st.bag.duplicate():
			if int(it.get("rarity", 0)) == 0:
				g += st.sell_value(it); st.remove_from_bag(String(it["uid"])); n += 1
		st.gold += g; refresh.call(); inv_draw.queue_redraw(); toast("Sold %d items for %d gold" % [n, g], Color("f2d27a"), 1.8, 18); dir.autosave(), 430.0))
	v.add_child(_button("Leave", func(): close_panel(); inv.visible = false; tip.visible = false, 430.0))
	inv.visible = true
	inv_draw.queue_redraw()

func shop_open() -> bool: return panel_kind == "shop"

# ---------------- inventory + character ----------------

var inv_rect := Rect2()
var slot_rects := {}
var bag_origin := Vector2.ZERO

func _build_inventory() -> void:
	inv = PanelContainer.new()
	inv.add_theme_stylebox_override("panel", _box(INK, GOLD))
	inv.visible = false
	inv.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(inv)
	inv_draw = Control.new()
	inv_draw.custom_minimum_size = Vector2(SYS.WIDTH * CELL + 8, 745)
	inv_draw.mouse_filter = Control.MOUSE_FILTER_STOP
	inv_draw.draw.connect(_draw_inv)
	inv_draw.gui_input.connect(_inv_input)
	inv_draw.mouse_exited.connect(func(): tip.visible = false; hover_item = {})
	inv.add_child(inv_draw)
	inv.resized.connect(func(): inv.position = Vector2(root.get_viewport_rect().size.x - inv.size.x - 40, 60))

func toggle_inventory() -> void:
	if panel_kind == "shop": return
	inv.visible = not inv.visible
	tip.visible = false
	if inv.visible:
		inv.position = Vector2(root.get_viewport_rect().size.x - inv.size.x - 40, 60)
		inv_draw.queue_redraw()

func _slot_layout() -> Dictionary:
	var c := Vector2(SYS.WIDTH * CELL * 0.5 + 4, 0)
	var s := 64.0
	return {"helm": Rect2(c + Vector2(-s * 0.5, 40), Vector2(s, s)), "amulet": Rect2(c + Vector2(s * 0.75, 52), Vector2(44, 44)),
		"weapon": Rect2(c + Vector2(-s * 2.4, 112), Vector2(s, s * 1.5)), "armor": Rect2(c + Vector2(-s * 0.6, 112), Vector2(s * 1.2, s * 1.5)),
		"offhand": Rect2(c + Vector2(s * 1.4, 112), Vector2(s, s * 1.5)), "gloves": Rect2(c + Vector2(-s * 2.4, 222), Vector2(s, s)),
		"belt": Rect2(c + Vector2(-s * 0.6, 222), Vector2(s * 1.2, 40)), "boots": Rect2(c + Vector2(s * 1.4, 222), Vector2(s, s)),
		"ring1": Rect2(c + Vector2(-s * 1.15, 272), Vector2(44, 44)), "ring2": Rect2(c + Vector2(s * 0.45, 272), Vector2(44, 44))}

func _rarity_col(it: Dictionary) -> Color:
	return Color(String(GD.RARITY[clampi(int(it.get("rarity", 0)), 0, 3)]["color"]))

const ART := preload("res://scripts/art_library.gd")
func _portrait(it: Dictionary) -> Texture2D:
	return ART.inventory_portrait(String(it.get("unique_id", it.get("slot", "weapon"))))

func _draw_inv() -> void:
	var st = dir.state
	var c := inv_draw
	var w := c.size.x
	c.draw_string(font, Vector2(4, 22), st.hero_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, GOLD)
	var cls := "Knight" if st.class_id == "warrior" else "Mage"
	c.draw_string(font_r, Vector2(w * 0.5, 22), "Level %d %s" % [st.level, cls], HORIZONTAL_ALIGNMENT_RIGHT, w * 0.5 - 4, 17, IVORY)
	slot_rects = _slot_layout()
	for slot in slot_rects:
		var r: Rect2 = slot_rects[slot]
		var it = st.gear.get(slot)
		c.draw_rect(r, Color(0.09, 0.075, 0.06, 0.95))
		c.draw_rect(r, _rarity_col(it) if it != null else GOLD_DIM, false, 1.5)
		if it != null:
			var tex := _portrait(it)
			if tex != null: c.draw_texture_rect(tex, _fit(tex, r.grow(-4)), false)
		else:
			c.draw_string(font_r, Vector2(r.position.x, r.get_center().y + 4), slot.trim_suffix("1").trim_suffix("2").capitalize(), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, Color(0.55, 0.5, 0.42))
	# stats
	var s: Dictionary = st.stats()
	var y := 336.0
	var col2 := w * 0.52
	var lines := [["Life", "%d" % int(s["max_hp"])], ["Mana", "%d" % int(s["max_mp"])],
		["Spell power" if st.class_id == "mage" else "Damage", "%d" % int(s["spell_power"] if st.class_id == "mage" else s["dmg"])],
		["Armour", "%d" % int(s["armor"])], ["Critical chance", "%.1f%%" % (float(s["crit"]) * 100.0)],
		["Gold", "%d" % st.gold], ["Potions", "%d health · %d mana" % [st.potions["health"], st.potions["mana"]]],
		["Experience", "%d / %d" % [st.xp, st.xp_need()]]]
	for i in lines.size():
		var x := 4.0 if i % 2 == 0 else col2
		if i % 2 == 0 and i > 0: y += 22
		c.draw_string(font_r, Vector2(x, y), lines[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("a8977a"))
		c.draw_string(font, Vector2(x + 118, y), lines[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, IVORY)
	# bag
	bag_origin = Vector2(4, 440)
	c.draw_string(font, bag_origin + Vector2(0, -8), "BAG", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GOLD)
	c.draw_string(font_r, bag_origin + Vector2(60, -8), "Click: equip (sell at the shop)  ·  Right-click: salvage", HORIZONTAL_ALIGNMENT_RIGHT, SYS.WIDTH * CELL - 60, 13, Color("a8977a"))
	for y2 in SYS.HEIGHT:
		for x2 in SYS.WIDTH:
			var r := Rect2(bag_origin + Vector2(x2, y2) * CELL, Vector2(CELL, CELL))
			c.draw_rect(r.grow(-1), Color(0.07, 0.06, 0.05, 0.95))
			c.draw_rect(r.grow(-1), Color(0.3, 0.25, 0.18, 0.6), false, 1.0)
	for it in st.bag:
		var r := _bag_rect(it)
		c.draw_rect(r.grow(-2), Color(_rarity_col(it), 0.14))
		c.draw_rect(r.grow(-2), _rarity_col(it), false, 1.5)
		var tex := _portrait(it)
		if tex != null: c.draw_texture_rect(tex, _fit(tex, r.grow(-5)), false)
		if st.can_equip(it) != "": c.draw_rect(r.grow(-2), Color(0.5, 0.05, 0.05, 0.35))
	c.draw_string(font_r, Vector2(4, 440 + SYS.HEIGHT * CELL + 22), "I / C to close", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a8977a"))

func _fit(tex: Texture2D, r: Rect2) -> Rect2:
	var k := minf(r.size.x / tex.get_width(), r.size.y / tex.get_height())
	var sz := Vector2(tex.get_width(), tex.get_height()) * k
	return Rect2(r.get_center() - sz * 0.5, sz)

func _bag_rect(it: Dictionary) -> Rect2:
	var fp: Vector2i = SYS.footprint(it)
	return Rect2(bag_origin + Vector2(int(it.get("x", 0)), int(it.get("y", 0))) * CELL, Vector2(fp) * CELL)

func _item_at(m: Vector2) -> Array:
	for slot in slot_rects:
		if (slot_rects[slot] as Rect2).has_point(m) and dir.state.gear.get(slot) != null: return ["gear", slot, dir.state.gear[slot]]
	for it in dir.state.bag:
		if _bag_rect(it).has_point(m): return ["bag", "", it]
	return []

func _inv_input(e: InputEvent) -> void:
	var st = dir.state
	if e is InputEventMouseMotion:
		var hit := _item_at(e.position)
		if hit.is_empty(): tip.visible = false; return
		var it: Dictionary = hit[2]
		var extra := ""
		if hit[0] == "bag":
			var why: String = st.can_equip(it)
			extra = ("[color=#ff7a6a]%s[/color]" % why) if why != "" else "Click to equip"
			if shop_open(): extra = "Click to sell for %d gold" % st.sell_value(it)
			extra += "\nRight-click to salvage (%d gold)" % st.sell_value(it)
			var worn = st.gear.get(SYS.default_slot(it))
			if worn != null: extra += "\n\n[color=#a8977a]Equipped:[/color] " + String(worn["name"]) + "\n" + GD.item_line(worn)
		else:
			extra = "Click to unequip"
		_show_tip(it, extra)
	elif e is InputEventMouseButton and e.pressed:
		var hit := _item_at(e.position)
		if hit.is_empty(): return
		var it: Dictionary = hit[2]
		var msg := ""
		if hit[0] == "gear":
			msg = st.unequip(String(hit[1]))
		elif e.button_index == MOUSE_BUTTON_RIGHT or shop_open():
			st.gold += st.sell_value(it); st.remove_from_bag(String(it["uid"]))
			toast("+%d gold" % st.sell_value(it), Color("f2d27a"), 1.0, 18)
		else:
			msg = st.equip(String(it["uid"]))
			if msg == "": dir.play("equip", -8.0)
		if msg != "": toast(msg, Color("ff7a6a"), 1.6, 18)
		dir.apply_stats()
		dir.autosave()
		tip.visible = false
		inv_draw.queue_redraw()

func _show_tip(it: Dictionary, extra := "") -> void:
	var col := _rarity_col(it).to_html(false)
	var rar: String = GD.RARITY[clampi(int(it.get("rarity", 0)), 0, 3)]["name"]
	tip_label.text = "[b][color=#%s]%s[/color][/b]\n[color=#a8977a]%s %s · item level %d[/color]\n%s\n\n%s" % [col, it.get("name", "?"), rar, String(it.get("slot", "")).capitalize(), int(it.get("level", 1)), GD.item_line(it).replace(", ", "\n"), extra]
	tip.visible = true
	tip.reset_size()
	var m := root.get_viewport().get_mouse_position()
	tip.position = Vector2(clampf(m.x - tip.size.x - 18, 8, 99999), clampf(m.y + 10, 8, root.get_viewport_rect().size.y - tip.size.y - 8))

# ---------------- death / pause / epilogue ----------------

func show_death() -> void:
	inv.visible = false
	var v := _modal("death", 520.0)
	var t := _label("YOU HAVE FALLEN", 40, Color("d8463a"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := _label("The wood claims another name. Crownsfall will remember yours.", 17, IVORY, false)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; s.custom_minimum_size = Vector2(480, 0)
	v.add_child(s)
	v.add_child(_button("Rise again in Crownsfall", func(): close_panel(); dir.respawn(), 480.0))

func toggle_pause() -> void:
	if panel_kind == "pause": close_panel(); return
	if panel_kind == "death": return
	if panel != null or inv.visible: close_panel(); inv.visible = false; tip.visible = false; return
	var v := _modal("pause", 420.0)
	var t := _label("PAUSED", 34, GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var st = dir.state
	var info := _label("%s · Level %d · %s played" % [st.hero_name, st.level, _hms(st.play_time)], 15, Color("a8977a"), false)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(info)
	v.add_child(_button("Resume", func(): close_panel(), 380.0))
	v.add_child(_button("Key Bindings", func(): close_panel(); dir.lab.hud.toggle_bind_menu(), 380.0))
	var vol := HSlider.new()
	vol.min_value = 0; vol.max_value = 1; vol.step = 0.05
	vol.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	vol.custom_minimum_size = Vector2(380, 28)
	vol.value_changed.connect(func(x): AudioServer.set_bus_volume_db(0, linear_to_db(maxf(x, 0.0001))); _save_settings())
	var vrow := HBoxContainer.new(); vrow.add_child(_label("Volume", 17, IVORY, false)); vrow.add_child(vol)
	v.add_child(vrow)
	var fs := CheckBox.new()
	fs.text = "Fullscreen"
	fs.add_theme_font_override("font", font_r); fs.add_theme_font_size_override("font_size", 17)
	fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.toggled.connect(func(on): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED); _save_settings())
	v.add_child(fs)
	v.add_child(_button("Save and Exit to Title", func(): dir.autosave(); get_tree().paused = false; get_tree().change_scene_to_file("res://scenes/title.tscn"), 380.0))
	v.add_child(_button("Save and Quit", func(): dir.autosave(); get_tree().quit(), 380.0))
	get_tree().paused = true
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	process_mode = Node.PROCESS_MODE_ALWAYS

func _save_settings() -> void:
	var cf: ConfigFile = SAVE.open()
	cf.set_value("settings", "volume", db_to_linear(AudioServer.get_bus_volume_db(0)))
	cf.set_value("settings", "fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	SAVE.commit(cf)

func _hms(t: float) -> String:
	return "%dh %02dm" % [int(t) / 3600, (int(t) / 60) % 60]

func show_epilogue() -> void:
	var v := _modal("epilogue", 640.0)
	var t := _label("THE WHISPERWOOD IS FREE", 34, GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var st = dir.state
	for line in ["You have completed this chapter of Age of the Lost.", "Level %d · %d foes slain · %d deaths · %s" % [st.level, st.kills, st.deaths, _hms(st.play_time)], "Hollowmere awaits in the next chapter. You may keep exploring, hunting and gathering gear."]:
		var l := _label(line, 18, IVORY, false)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size = Vector2(600, 0)
		v.add_child(l)
	v.add_child(_button("Continue playing", func(): close_panel(), 600.0))
