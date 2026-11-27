extends CanvasLayer
## Game screens over the HUD, all built from the painted AOTL UI kit (scripts/game/ui_skin.gd): notifications, area
## banner, boss bar, NPC dialogue, the Quartermaster's shop, the hero window (I: Equipment with a live 3D view of the
## hero in his gear, C: Character sheet), the skill tree (K), death screen, pause menu and Options (Esc), epilogue.
const SKILLS_DB := preload("res://scripts/game/skills.gd")
const SKILLS := preload("res://scripts/game/skills.gd")
const SYS := preload("res://scripts/systems.gd")
const GD := preload("res://scripts/game_data.gd")
const SAVE := preload("res://scripts/three_d/aotl_save.gd")
const SKIN := preload("res://scripts/game/ui_skin.gd")
const ART := preload("res://scripts/art_library.gd")
const GOLD := Color("d9b46a")
const GOLD_DIM := Color("8f7444")
const IVORY := Color("efe6cf")
const MUTED := Color("a8977a")
const CELL := 48.0
const SLOT := 56.0
const POTION_PRICE := {"health": 20, "mana": 20}
const DOLL_LAYER := 1 << 19          # render layer the hero window's camera sees (the hero only)

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
var panel: Control = null          # the one open modal panel (dialogue / shop / pause / options / death / epilogue)
var panel_kind := ""
var inv: Control                   # hero window: Equipment + Character tabs (can be open with the shop)
var inv_tab := "equipment"
var inv_draw: Control              # equipment slots + bag (drawn)
var char_page: Control             # character sheet
var tab_row: HBoxContainer
var hover_item: Dictionary = {}
var tip: PanelContainer
var tip_label: RichTextLabel
var doll_vp: SubViewport
var doll_cam: Camera3D
var doll_box: Control

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
	_build_skills()
	tip = PanelContainer.new()
	tip.add_theme_stylebox_override("panel", SKIN.tooltip_box())
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

func _button(text: String, cb: Callable, w := 300.0) -> Button:
	var b := SKIN.button(text, w, 50.0, 19)
	b.pressed.connect(func(): dir.play("click", -10.0); if cb.is_valid(): cb.call())
	return b

## Detach then free (a rebuilt node can reuse its name at once; safe from inside a child's signal).
func _clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()

func _centered(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc

## A framed modal (crownless bronze frame, 9-slice) with an optional title plaque. Returns its content column.
func _modal(kind: String, width := 560.0, title := "") -> VBoxContainer:
	close_panel()
	panel_kind = kind
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.5 if kind in ["pause", "options", "death", "epilogue"] else 0.0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP if kind in ["pause", "options", "death", "epilogue"] else Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", SKIN.panel_box(8.0))
	pc.custom_minimum_size = Vector2(width, 0)
	shade.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	if title != "":
		var pl := SKIN.plaque(title, 330.0, 23)
		v.add_child(_centered(pl))
	panel = shade
	pc.resized.connect(func(): _place(pc, kind))
	_place.call_deferred(pc, kind)
	return v

func _place(pc: Control, kind: String) -> void:
	var vs := root.get_viewport_rect().size
	if kind in ["dialogue"]: pc.position = Vector2((vs.x - pc.size.x) * 0.5, vs.y - pc.size.y - 210)
	elif kind == "shop": pc.position = Vector2(40, (vs.y - pc.size.y) * 0.5 - 30)
	else: pc.position = (vs - pc.size) * 0.5

func close_panel() -> void:
	if panel != null and is_instance_valid(panel): panel.queue_free()
	panel = null
	if panel_kind in ["pause", "options"]: get_tree().paused = false
	panel_kind = ""

## True while a screen that takes the mouse is open (world clicks ignored).
func blocking() -> bool:
	return panel != null or inv.visible or (sk_panel != null and sk_panel.visible)

func over_ui(m: Vector2) -> bool:
	if inv.visible and Rect2(inv.position, inv.size).has_point(m): return true
	if sk_panel != null and sk_panel.visible and Rect2(sk_panel.position, sk_panel.size).has_point(m): return true
	if panel != null and is_instance_valid(panel):
		for c in panel.get_children():
			if c is Control and Rect2(c.position, c.size).has_point(m): return true
		if panel_kind in ["pause", "options", "death", "epilogue"]: return true
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
	var nx := w * 0.5 - font.get_string_size(boss_ref.ename, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x * 0.5
	boss_bar.draw_string_outline(font, Vector2(nx, 18), boss_ref.ename, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 5, Color(0, 0, 0, 0.9))
	boss_bar.draw_string(font, Vector2(nx, 18), boss_ref.ename, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffb08a"))
	var r := Rect2(0, 26, w, 16)
	boss_bar.draw_texture_rect(SKIN.tex("slider_track"), r.grow_individual(10, 5, 10, 5), false)
	boss_bar.draw_rect(Rect2(r.position + Vector2(2, 3), Vector2((w - 4) * boss_ref.hp / boss_ref.max_hp, r.size.y - 6)), Color("b3261e"))

# ---------------- dialogue ----------------

func dialogue(speaker: String, lines: Array, options: Array) -> void:
	var v := _modal("dialogue", 820.0)
	v.add_child(_label(speaker, 26, GOLD))
	for l in lines:
		var t := _label(String(l), 19, IVORY, false)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(700, 0)
		v.add_child(t)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	for o in options:
		var cb: Callable = o[1]
		row.add_child(_button(String(o[0]), func(): close_panel(); if cb.is_valid(): cb.call(), 270.0))

# ---------------- shop ----------------

func open_vendor() -> void:
	var st = dir.state
	if st.vendor_stock.is_empty() or int(st.vendor_stock[0].get("level", 1)) < st.level - 2:
		st.vendor_stock.clear()
		for i in 4: st.vendor_stock.append(SYS.make_item(st.level, 0.25, "", st.class_id))
	var v := _modal("shop", 560.0, "QUARTERMASTER")
	var hi := _label("\"Coin for steel, steel for coin. Click your own gear to sell it.\"", 16, Color("cfc7b8"), false)
	hi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; hi.custom_minimum_size = Vector2(440, 0)
	v.add_child(hi)
	var gold_l := _label("", 19, Color("f2d27a"))
	v.add_child(gold_l)
	var refresh := func(): gold_l.text = "Gold: %d    Potions: %d health / %d mana" % [st.gold, st.potions["health"], st.potions["mana"]]
	refresh.call()
	for k in ["health", "mana"]:
		v.add_child(_button("Buy %s Potion  (%d gold)" % [k.capitalize(), POTION_PRICE[k]], func():
			if st.gold < POTION_PRICE[k]: toast("Not enough gold", Color("ff7a6a"), 1.4, 18); return
			st.gold -= POTION_PRICE[k]; st.potions[k] = mini(99, int(st.potions[k]) + 1); refresh.call(); dir.play("pickup", -8.0), 440.0))
	v.add_child(_centered(SKIN.divider(400)))
	v.add_child(_label("Wares", 20, GOLD))
	for it in st.vendor_stock.duplicate():
		var price: int = int(it.get("value", 10)) * 2
		var b := _button("%s  (lv %d)  —  %d gold" % [it["name"], int(it["level"]), price], Callable(), 440.0)
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", Color(String(GD.RARITY[int(it["rarity"])]["color"])))
		b.pressed.connect(func():
			if st.gold < price: toast("Not enough gold", Color("ff7a6a"), 1.4, 18); return
			if not st.add_item(it): toast("Your bag is full", Color("ff7a6a"), 1.4, 18); return
			st.gold -= price; st.vendor_stock.erase(it); b.queue_free(); refresh.call(); inv_draw.queue_redraw(); dir.autosave())
		b.mouse_entered.connect(func(): _show_tip(it, "Buy for %d gold" % price))
		b.mouse_exited.connect(func(): tip.visible = false)
		v.add_child(b)
	v.add_child(_centered(SKIN.divider(400)))
	var respec_cost: int = 25 * st.level
	v.add_child(_button("Unlearn skills, refund points  (%d gold)" % respec_cost, func():
		if st.gold < respec_cost: toast("Not enough gold", Color("ff7a6a"), 1.4, 18); return
		st.gold -= respec_cost; st.respec(); refresh.call(); toast("Skill points refunded — press K", Color("c9a8ff"), 2.0, 18); dir.autosave(), 440.0))
	v.add_child(_button("Sell all Common items", func():
		var n := 0; var g := 0
		for it in st.bag.duplicate():
			if int(it.get("rarity", 0)) == 0:
				g += st.sell_value(it); st.remove_from_bag(String(it["uid"])); n += 1
		st.gold += g; refresh.call(); inv_draw.queue_redraw(); toast("Sold %d items for %d gold" % [n, g], Color("f2d27a"), 1.8, 18); dir.autosave(), 440.0))
	v.add_child(_button("Leave", func(): close_panel(); inv.visible = false; tip.visible = false, 440.0))
	_show_inv("equipment")

func shop_open() -> bool: return panel_kind == "shop"

# ---------------- hero window: equipment + bag (I), character sheet (C) ----------------

var slot_rects := {}
var bag_origin := Vector2.ZERO
var doll_rect := Rect2()
const SLOT_ART := {"helm": "slot_helm", "amulet": "slot_amulet", "armor": "slot_armor", "gloves": "slot_gloves", "ring1": "slot_ring",
	"weapon": "slot_weapon", "offhand": "slot_offhand", "belt": "slot_belt", "boots": "slot_boots", "ring2": "slot_ring"}

func _build_inventory() -> void:
	var w := SKIN.window("tall", "HERO")
	inv = w["root"]
	inv.visible = false
	root.add_child(inv)
	(w["close"] as TextureButton).pressed.connect(func(): inv.visible = false; tip.visible = false; if shop_open(): close_panel())
	var content: Control = w["content"]
	tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.size = Vector2(content.size.x, 46)
	content.add_child(tab_row)
	# equipment page
	inv_draw = Control.new()
	inv_draw.position = Vector2(0, 50)
	inv_draw.size = Vector2(content.size.x, content.size.y - 50)
	inv_draw.mouse_filter = Control.MOUSE_FILTER_STOP
	inv_draw.draw.connect(_draw_inv)
	inv_draw.gui_input.connect(_inv_input)
	inv_draw.mouse_exited.connect(func(): tip.visible = false; hover_item = {})
	content.add_child(inv_draw)
	var cx := content.size.x * 0.5
	doll_rect = Rect2(cx - 130, 6, 260, 300)
	_layout_slots(cx)
	bag_origin = Vector2(cx - SYS.WIDTH * CELL * 0.5, inv_draw.size.y - SYS.HEIGHT * CELL - 2)
	_build_doll()
	# character page
	char_page = Control.new()
	char_page.position = Vector2(0, 50)
	char_page.size = Vector2(content.size.x, content.size.y - 50)
	char_page.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(char_page)
	_refresh_tabs()

func _layout_slots(cx: float) -> void:
	var lx := doll_rect.position.x - 14 - SLOT
	var rx := doll_rect.end.x + 14
	var y0 := doll_rect.position.y
	var step := (doll_rect.size.y - SLOT) / 4.0
	slot_rects = {}
	var left := ["helm", "amulet", "armor", "gloves", "ring1"]
	var right := ["weapon", "offhand", "belt", "boots", "ring2"]
	for i in 5:
		slot_rects[left[i]] = Rect2(lx, y0 + step * i, SLOT, SLOT)
		slot_rects[right[i]] = Rect2(rx, y0 + step * i, SLOT, SLOT)

## The live 3D hero in the equipment page: a camera in the game world that sees only the hero's render layer,
## in front of him, over the painted shrine backdrop. Shows exactly what he wears, animated.
func _build_doll() -> void:
	doll_box = Control.new()
	doll_box.position = doll_rect.position
	doll_box.size = doll_rect.size
	doll_box.clip_contents = true
	doll_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inv_draw.add_child(doll_box)
	var bg := TextureRect.new()
	bg.texture = SKIN.tex("char_bg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	doll_box.add_child(bg)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	doll_box.add_child(svc)
	doll_vp = SubViewport.new()
	doll_vp.transparent_bg = true
	doll_vp.msaa_3d = Viewport.MSAA_4X
	doll_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	svc.add_child(doll_vp)
	doll_cam = Camera3D.new()
	doll_cam.cull_mask = DOLL_LAYER
	doll_cam.fov = 26
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.72, 0.64)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	doll_cam.environment = env
	doll_vp.add_child(doll_cam)
	var frame := Control.new()       # thin bronze edge over the 3D view
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.draw.connect(func(): frame.draw_rect(Rect2(Vector2.ZERO, frame.size), GOLD_DIM, false, 2.0))
	doll_box.add_child(frame)

func _doll_update() -> void:
	var p = dir.lab.player
	if p == null or not is_instance_valid(p): return
	for n in p.find_children("*", "VisualInstance3D", true, false):
		(n as VisualInstance3D).layers |= DOLL_LAYER
	var base: Vector3 = p.global_position
	var fwd := Vector3(0, 0, 1)
	var sks: Array = p.find_children("*", "Skeleton3D", true, false)
	if not sks.is_empty():
		var sk := sks[0] as Skeleton3D
		var h := sk.find_bone("Head"); var hf := sk.find_bone("headfront")
		if h >= 0 and hf >= 0:
			var d: Vector3 = sk.global_transform.basis * (sk.get_bone_global_pose(hf).origin - sk.get_bone_global_pose(h).origin)
			d.y = 0.0
			if d.length() > 0.001: fwd = d.normalized()
	fwd = fwd.rotated(Vector3.UP, deg_to_rad(22.0))        # a three-quarter view reads armour and weapons best
	doll_cam.global_position = base + fwd * 5.0 + Vector3.UP * 1.3
	doll_cam.look_at(base + Vector3.UP * 0.98, Vector3.UP)

func _process(_dt: float) -> void:
	if inv != null and inv.visible and inv_tab == "equipment": _doll_update()

func _refresh_tabs() -> void:
	_clear(tab_row)
	for t in [["equipment", "Equipment"], ["character", "Character"]]:
		var b := SKIN.tab(t[1], inv_tab == t[0], 190.0)
		var id: String = t[0]
		b.pressed.connect(func(): dir.play("click", -10.0); _show_inv(id))
		tab_row.add_child(b)
	inv_draw.visible = inv_tab == "equipment"
	char_page.visible = inv_tab == "character"
	if inv_tab == "character": _build_character()

func _show_inv(tab: String) -> void:
	inv_tab = tab
	inv.visible = true
	tip.visible = false
	if sk_panel != null: sk_panel.visible = false
	var vs := root.get_viewport_rect().size
	inv.position = Vector2(vs.x - inv.size.x - 16, maxf(0.0, (vs.y - inv.size.y) * 0.5 - 20))
	_refresh_tabs()
	inv_draw.queue_redraw()

func toggle_inventory() -> void:
	if panel_kind == "shop": return
	if inv.visible and inv_tab == "equipment": inv.visible = false; tip.visible = false; return
	_show_inv("equipment")

func toggle_character() -> void:
	if panel_kind == "shop": return
	if inv.visible and inv_tab == "character": inv.visible = false; tip.visible = false; return
	_show_inv("character")

func _slot_layout() -> Dictionary:
	return slot_rects

func _rarity_col(it: Dictionary) -> Color:
	return Color(String(GD.RARITY[clampi(int(it.get("rarity", 0)), 0, 3)]["color"]))

func _portrait(it: Dictionary) -> Texture2D:
	return ART.inventory_portrait(String(it.get("unique_id", it.get("slot", "weapon"))))

func _draw_inv() -> void:
	var st = dir.state
	var c := inv_draw
	var w := c.size.x
	for slot in slot_rects:
		var r: Rect2 = slot_rects[slot]
		var it = st.gear.get(slot)
		c.draw_texture_rect(SKIN.tex(SLOT_ART[slot]), r, false, Color(1, 1, 1) if it == null else Color(0.55, 0.52, 0.48))
		if it != null:
			var tex := _portrait(it)
			if tex != null: c.draw_texture_rect(tex, _fit(tex, r.grow(-9)), false)
			c.draw_rect(r.grow(-5), Color(_rarity_col(it), 0.9), false, 2.0)
	# quick stats under the hero
	var s: Dictionary = st.stats()
	var y := doll_rect.end.y + 30
	var quick := [["Life", "%d" % int(s["max_hp"])], ["Mana", "%d" % int(s["max_mp"])],
		["Spell" if st.class_id == "mage" else "Damage", "%d" % int(s["spell_power"] if st.class_id == "mage" else s["dmg"])], ["Armour", "%d" % int(s["armor"])]]
	for i in quick.size():
		var x := 20.0 + i * (w - 40.0) / 4.0
		c.draw_string(font_r, Vector2(x, y), quick[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, MUTED)
		c.draw_string(font, Vector2(x + font_r.get_string_size(quick[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 8, y), quick[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, IVORY)
	# bag
	c.draw_string(font, bag_origin + Vector2(0, -10), "BAG", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GOLD)
	c.draw_string(font_r, bag_origin + Vector2(50, -10), "Gold %d   ·   Click: equip%s   ·   Right-click: salvage" % [st.gold, " / sell" if shop_open() else ""], HORIZONTAL_ALIGNMENT_RIGHT, SYS.WIDTH * CELL - 50, 14, MUTED)
	var cell := SKIN.tex("cell")
	for y2 in SYS.HEIGHT:
		for x2 in SYS.WIDTH:
			c.draw_texture_rect(cell, Rect2(bag_origin + Vector2(x2, y2) * CELL, Vector2(CELL, CELL)), false)
	for it in st.bag:
		var r := _bag_rect(it)
		c.draw_rect(r.grow(-4), Color(0.04, 0.035, 0.03, 0.85))
		c.draw_rect(r.grow(-4), Color(_rarity_col(it), 0.16))
		var tex := _portrait(it)
		if tex != null: c.draw_texture_rect(tex, _fit(tex, r.grow(-7)), false)
		c.draw_rect(r.grow(-4), _rarity_col(it), false, 1.5)
		if st.can_equip(it) != "": c.draw_rect(r.grow(-4), Color(0.5, 0.05, 0.05, 0.35))

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

## Character sheet: portrait medallion, name, class, level and experience, attributes, combat and journey.
func _build_character() -> void:
	_clear(char_page)
	var st = dir.state
	var cd: Resource = SKILLS.class_data(st.class_id)
	var w := char_page.size.x
	# portrait medallion: the class render, framed
	var med := Control.new()
	med.position = Vector2(14, 4); med.size = Vector2(170, 170)
	med.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_page.add_child(med)
	var face := TextureRect.new()
	face.texture = cd.portrait
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.position = Vector2(22, 22); face.size = Vector2(126, 126)
	var sm := ShaderMaterial.new()
	sm.shader = _portrait_shader()
	face.material = sm
	med.add_child(face)
	var ring := TextureRect.new()
	ring.texture = SKIN.tex("medallion")
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode = TextureRect.STRETCH_SCALE
	ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	med.add_child(ring)
	var nm := _label(String(st.hero_name), 30, GOLD)
	nm.position = Vector2(200, 18)
	char_page.add_child(nm)
	var sub := _label("Level %d %s" % [st.level, SKILLS.display_name(st.class_id)], 20, IVORY, false)
	sub.position = Vector2(200, 60)
	char_page.add_child(sub)
	var xp := Control.new()
	xp.position = Vector2(200, 100); xp.size = Vector2(w - 220, 26)
	xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frac: float = clampf(float(st.xp) / maxf(1.0, float(st.xp_need())), 0.0, 1.0)
	xp.draw.connect(func():
		xp.draw_texture_rect(SKIN.tex("slider_track"), Rect2(Vector2.ZERO, xp.size), false)
		xp.draw_rect(Rect2(Vector2(10, 7), Vector2((xp.size.x - 20) * frac, xp.size.y - 14)), Color(0.55, 0.35, 0.9, 0.9)))
	char_page.add_child(xp)
	var xpl := _label("Experience %d / %d" % [st.xp, st.xp_need()], 15, MUTED, false)
	xpl.position = Vector2(200, 130)
	char_page.add_child(xpl)
	var y := 184.0
	var dv := SKIN.divider(w - 40); dv.position = Vector2(20, y); char_page.add_child(dv)
	y += 26
	var s: Dictionary = st.stats()
	var a: Dictionary = s["attributes"]
	var col_w := (w - 40) / 2.0
	var sections := [
		["Attributes", [["Strength", "%d" % int(a["strength"])], ["Dexterity", "%d" % int(a["dexterity"])], ["Vitality", "%d" % int(a["vitality"])],
			["Intelligence", "%d" % int(a["intelligence"])], ["Wisdom", "%d" % int(a["wisdom"])], ["Charisma", "%d" % int(a["charisma"])]]],
		["Combat", [["Life", "%d" % int(s["max_hp"])], ["Mana", "%d" % int(s["max_mp"])], ["Damage", "%d" % int(s["dmg"])],
			["Spell power", "%d" % int(s["spell_power"])], ["Armour", "%d" % int(s["armor"])], ["Critical chance", "%.1f%%" % (float(s["crit"]) * 100.0)],
			["Mana regeneration", "%.1f / s" % float(s["mana_regen"])]]]]
	var top := y
	for k in sections.size():
		var x := 20.0 + k * col_w
		var yy := top
		var h := _label(String(sections[k][0]).to_upper(), 17, GOLD); h.position = Vector2(x, yy); char_page.add_child(h)
		yy += 30
		for row in sections[k][1]:
			var l := _label(String(row[0]), 16, MUTED, false); l.position = Vector2(x, yy); char_page.add_child(l)
			var v := _label(String(row[1]), 16, IVORY); v.position = Vector2(x + col_w - 40 - 80, yy)
			v.custom_minimum_size = Vector2(80, 0); v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; char_page.add_child(v)
			yy += 25
		y = maxf(y, yy)
	y += 6
	dv = SKIN.divider(w - 40); dv.position = Vector2(20, y); char_page.add_child(dv)
	y += 26
	var done := 0
	for q in st.quests.values():
		if String(q.get("state", "")) == "done": done += 1
	var hj := _label("JOURNEY", 17, GOLD); hj.position = Vector2(20, y); char_page.add_child(hj)
	y += 30
	var journey := [["Time played", _hms(st.play_time)], ["Foes slain", "%d" % st.kills], ["Deaths", "%d" % st.deaths],
		["Quests completed", "%d" % done], ["Gold", "%d" % st.gold], ["Potions", "%d health · %d mana" % [st.potions["health"], st.potions["mana"]]]]
	for i in journey.size():
		var x := 20.0 + (i % 2) * col_w
		var yy := y + (i / 2) * 25
		var l := _label(String(journey[i][0]), 16, MUTED, false); l.position = Vector2(x, yy); char_page.add_child(l)
		var v := _label(String(journey[i][1]), 16, IVORY); v.position = Vector2(x + col_w - 40 - 160, yy)
		v.custom_minimum_size = Vector2(160, 0); v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; char_page.add_child(v)
	y += 3 * 25 + 10
	var desc := _label(String(cd.description), 15, Color("cfc7b8"), false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(20, y); desc.custom_minimum_size = Vector2(w - 40, 0); desc.size = Vector2(w - 40, 0)
	char_page.add_child(desc)

var _portrait_sh: Shader
## Circle-masked portrait, upper body (the render is full length): sample the top third, centred on the head.
func _portrait_shader() -> Shader:
	if _portrait_sh == null:
		_portrait_sh = Shader.new()
		_portrait_sh.code = """shader_type canvas_item;
void fragment() {
	vec2 uv = vec2(0.5 + (UV.x - 0.5) * 0.62, 0.02 + UV.y * 0.36);
	vec4 c = texture(TEXTURE, uv);
	float d = distance(UV, vec2(0.5));
	vec3 bg = mix(vec3(0.16, 0.13, 0.11), vec3(0.05, 0.045, 0.04), d * 2.0);
	COLOR = vec4(mix(bg, c.rgb, c.a), smoothstep(0.5, 0.48, d));
}"""
	return _portrait_sh

# ---------------- skill tree (K) ----------------

var sk_panel: Control
var sk_box: Control                 # the tree (one node per skill)
var sk_detail: VBoxContainer
var sk_selected := ""

func _build_skills() -> void:
	var w := SKIN.window("wide", "SKILLS")
	sk_panel = w["root"]
	sk_panel.visible = false
	root.add_child(sk_panel)
	(w["close"] as TextureButton).pressed.connect(func(): sk_panel.visible = false; tip.visible = false)
	var content: Control = w["content"]
	var bg := TextureRect.new()
	bg.texture = SKIN.tex("skill_bg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(1, 1, 1, 0.92)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(bg)
	content.clip_contents = true
	sk_box = Control.new()
	sk_box.position = Vector2(10, 0)
	sk_box.size = Vector2(800, content.size.y)
	sk_box.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(sk_box)
	var detail_bg := PanelContainer.new()
	detail_bg.add_theme_stylebox_override("panel", SKIN.tooltip_box())
	detail_bg.position = Vector2(820, 6)
	detail_bg.size = Vector2(content.size.x - 830, content.size.y - 12)
	detail_bg.custom_minimum_size = detail_bg.size
	content.add_child(detail_bg)
	sk_detail = VBoxContainer.new()
	sk_detail.add_theme_constant_override("separation", 6)
	detail_bg.add_child(sk_detail)

func toggle_skills() -> void:
	sk_panel.visible = not sk_panel.visible
	if sk_panel.visible:
		inv.visible = false
		var vs := root.get_viewport_rect().size
		sk_panel.position = ((vs - sk_panel.size) * 0.5).floor() - Vector2(0, 40)
		refresh_skills()
	else: tip.visible = false

func refresh_skills() -> void:
	_clear(sk_box)
	var st = dir.state
	var defs: Array = SKILLS.defs(st.class_id)
	if sk_selected == "" or SKILLS.def(st.class_id, sk_selected).is_empty(): sk_selected = String(defs[0]["id"])
	# tiers by unlock level, left to right
	var tiers := {}
	for d in defs:
		var u := int(d["unlock"])
		if not tiers.has(u): tiers[u] = []
		tiers[u].append(d)
	var levels := tiers.keys(); levels.sort()
	var col_w := sk_box.size.x / float(levels.size())
	var node_sz := 86.0
	var centers := {}
	for ci in levels.size():
		var list: Array = tiers[levels[ci]]
		var x := col_w * (ci + 0.5)
		var lv := _label("Level %d" % levels[ci], 15, GOLD if st.level >= int(levels[ci]) else MUTED)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lv.position = Vector2(x - 60, 8); lv.size = Vector2(120, 22)
		sk_box.add_child(lv)
		for ri in list.size():
			var y := sk_box.size.y * (0.5 if list.size() == 1 else (0.3 + 0.42 * ri)) - 8
			centers[list[ri]["id"]] = Vector2(x, y)
	# connectors: each tier links to the next (drawn first, under the nodes)
	var links := Control.new()
	links.set_anchors_preset(Control.PRESET_FULL_RECT)
	links.mouse_filter = Control.MOUSE_FILTER_IGNORE
	links.draw.connect(func():
		for ci in levels.size() - 1:
			for a in tiers[levels[ci]]:
				for b in tiers[levels[ci + 1]]:
					var p0: Vector2 = centers[a["id"]] + Vector2(node_sz * 0.5, 0)
					var p1: Vector2 = centers[b["id"]] - Vector2(node_sz * 0.5, 0)
					var lit: bool = st.rank(String(b["id"])) > 0
					links.draw_line(p0, p1, Color(0.06, 0.05, 0.04, 0.9), 8.0)
					links.draw_line(p0, p1, Color("d9b46a") if lit else Color(0.42, 0.36, 0.27), 3.0)
					for k in [0.0, 1.0]: links.draw_circle(p0.lerp(p1, k), 5.0, Color("b88a45") if lit else Color(0.35, 0.3, 0.24)))
	sk_box.add_child(links)
	for d in defs:
		var id: String = d["id"]
		var r: int = st.rank(id)
		var c: Vector2 = centers[id]
		var node := TextureButton.new()
		node.texture_normal = SKIN.tex("node_locked" if r == 0 else ("node_master" if r >= SKILLS.MAX_RANK else "node_open"))
		node.ignore_texture_size = true
		node.stretch_mode = TextureButton.STRETCH_SCALE
		node.position = c - Vector2(node_sz, node_sz) * 0.5
		node.size = Vector2(node_sz, node_sz)
		node.focus_mode = Control.FOCUS_NONE
		node.name = "node_" + id
		var ic := TextureRect.new()
		ic.texture = d.get("icon_texture")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_SCALE
		ic.position = Vector2(14, 14); ic.size = Vector2(node_sz - 28, node_sz - 28)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if r == 0: ic.modulate = Color(0.38, 0.38, 0.38)
		node.add_child(ic)
		if id == sk_selected:
			var sel := Control.new()
			sel.set_anchors_preset(Control.PRESET_FULL_RECT)
			sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sel.draw.connect(func(): sel.draw_rect(Rect2(Vector2(-4, -4), sel.size + Vector2(8, 8)), Color(1.0, 0.85, 0.45, 0.95), false, 3.0))
			node.add_child(sel)
		node.pressed.connect(func(): dir.play("click", -10.0); sk_selected = id; refresh_skills())
		node.mouse_entered.connect(func(): node.modulate = Color(1.18, 1.12, 1.0))
		node.mouse_exited.connect(func(): node.modulate = Color.WHITE)
		sk_box.add_child(node)
		var nm := _label(String(d["name"]), 15, IVORY if r > 0 else MUTED)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.position = c + Vector2(-80, node_sz * 0.5 + 2); nm.size = Vector2(160, 20)
		sk_box.add_child(nm)
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 1)
		pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for k in SKILLS.MAX_RANK:
			var pip := TextureRect.new()
			pip.texture = SKIN.tex("pip_on" if k < r else "pip_off")
			pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pip.custom_minimum_size = Vector2(16, 16)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pips.add_child(pip)
		pips.position = c + Vector2(-42.5, node_sz * 0.5 + 24)
		sk_box.add_child(pips)
	var hint := _label("Click a skill to inspect it  ·  click a bar slot on the HUD to place a skill  ·  ranks add 14% damage each", 14, MUTED, false)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, sk_box.size.y - 28); hint.size = Vector2(sk_box.size.x, 22)
	sk_box.add_child(hint)
	_refresh_skill_detail()

func _refresh_skill_detail() -> void:
	_clear(sk_detail)
	var st = dir.state
	var id := sk_selected
	var d: Dictionary = SKILLS.def(st.class_id, id)
	var r: int = st.rank(id)
	var rd: Dictionary = dir.skill_def(id)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var ic := TextureRect.new()
	ic.texture = d.get("icon_texture")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.custom_minimum_size = Vector2(64, 64)
	if r == 0: ic.modulate = Color(0.4, 0.4, 0.4)
	head.add_child(ic)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	hv.add_child(_label(String(d["name"]), 22, GOLD))
	hv.add_child(_label(("Rank %d / %d" % [r, SKILLS.MAX_RANK]) if r > 0 else ("Unlocks at level %d" % int(d["unlock"])), 16, IVORY if r > 0 else MUTED, false))
	head.add_child(hv)
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(sp)
	var pts := _label("Points: %d" % st.skill_points, 17, Color("c9a8ff") if st.skill_points > 0 else MUTED)
	head.add_child(pts)
	sk_detail.add_child(head)
	var costs := []
	if float(rd.get("cost", 0)) > 0: costs.append("%d mana" % int(rd["cost"]))
	if float(rd.get("cd", 0)) > 0: costs.append("%.1f s cooldown" % float(rd["cd"]))
	if rd.has("dmg"): costs.append("%d%% damage" % int(round(float(rd["dmg"]) * SKILLS.damage_mult(maxi(r, 1)) * 100.0)))
	if d.get("basic", false): costs.append("primary attack")
	var dl := _label(String(d["desc"]) + ("\n" + "  ·  ".join(costs) if not costs.is_empty() else ""), 15, Color("cfc7b8"), false)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.custom_minimum_size = Vector2(380, 0)
	sk_detail.add_child(dl)
	var up := _button("Rank up  (+14% damage)" if r > 0 else "Not learned yet", func():
		var why: String = st.rank_up(id)
		if why != "": toast(why, Color("ff7a6a"), 1.4, 18)
		refresh_skills(); dir.autosave(), 380.0)
	up.custom_minimum_size = Vector2(380, 46)
	up.disabled = r == 0 or r >= SKILLS.MAX_RANK or st.skill_points <= 0
	up.name = "rank_up"
	sk_detail.add_child(up)
	sk_detail.add_child(_label("Upgrade at rank %d — choose one:" % SKILLS.MOD_RANK, 15, MUTED, false))
	for m in d.get("mods", []):
		var chosen: bool = st.skill_mod(id) == m["id"]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(380, 60)
		b.text = ("✓ " if chosen else "") + String(m["name"]) + "\n" + String(m["desc"])
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_override("font", font_r)
		b.add_theme_font_size_override("font_size", 14)
		b.add_theme_color_override("font_color", Color("ffe7a8") if chosen else IVORY)
		b.add_theme_color_override("font_hover_color", Color("ffe7a8"))
		b.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.46))
		var sb := SKIN.box("choice_on" if chosen else "choice", Vector4(26, 18, 26, 18), Vector4(26, 8, 26, 8), false)
		for s in ["normal", "hover", "pressed", "hover_pressed", "disabled"]: b.add_theme_stylebox_override(s, sb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.disabled = r < SKILLS.MOD_RANK
		b.pressed.connect(func():
			var why: String = st.choose_mod(id, m["id"])
			if why != "": toast(why, Color("ff7a6a"), 1.4, 18)
			dir.play("click", -10.0); refresh_skills(); dir.autosave())
		sk_detail.add_child(b)

func _tip_text(bb: String) -> void:
	tip_label.text = bb
	tip.visible = true
	tip.reset_size()
	var m := root.get_viewport().get_mouse_position()
	tip.position = Vector2(m.x + 18, clampf(m.y + 10, 8, root.get_viewport_rect().size.y - tip.size.y - 8))

# ---------------- death / pause / options / epilogue ----------------

func show_death() -> void:
	inv.visible = false
	sk_panel.visible = false
	var v := _modal("death", 600.0)
	var t := _label("YOU HAVE FALLEN", 40, Color("d8463a"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := _label("The wood claims another name. Crownsfall will remember yours.", 17, IVORY, false)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; s.custom_minimum_size = Vector2(480, 0)
	v.add_child(s)
	v.add_child(_centered(SKIN.divider(420)))
	v.add_child(_centered(_button("Rise again in Crownsfall", func(): close_panel(); dir.respawn(), 440.0)))

func toggle_pause() -> void:
	if panel_kind in ["pause", "options"]: close_panel(); return
	if panel_kind == "death": return
	if panel != null or inv.visible or sk_panel.visible: close_panel(); inv.visible = false; sk_panel.visible = false; tip.visible = false; return
	_open_pause()

func _open_pause() -> void:
	var v := _modal("pause", 480.0, "PAUSED")
	var st = dir.state
	var info := _label("%s · Level %d %s · %s played" % [st.hero_name, st.level, SKILLS.display_name(st.class_id), _hms(st.play_time)], 15, MUTED, false)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(info)
	for b in [["Resume", func(): close_panel()], ["Options", func(): open_options("game")],
			["Key Bindings", func(): close_panel(); dir.lab.hud.toggle_bind_menu()],
			["Save and Exit to Title", func(): dir.autosave(); get_tree().paused = false; get_tree().change_scene_to_file("res://scenes/title.tscn")],
			["Save and Quit", func(): dir.autosave(); get_tree().quit()]]:
		v.add_child(_centered(_button(b[0], b[1], 400.0)))
	_pause_tree()

func _pause_tree() -> void:
	get_tree().paused = true
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	process_mode = Node.PROCESS_MODE_ALWAYS

## Options (from the pause menu): Game, Display, Controls and Profile (player settings), on painted tabs.
func open_options(tab := "game") -> void:
	var v := _modal("options", 760.0, "OPTIONS")
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 6)
	for t in [["game", "Game"], ["display", "Display"], ["controls", "Controls"], ["profile", "Profile"]]:
		var b := SKIN.tab(t[1], tab == t[0], 160.0)
		var id: String = t[0]
		b.pressed.connect(func(): dir.play("click", -10.0); open_options(id))
		tabs.add_child(b)
	v.add_child(tabs)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.custom_minimum_size = Vector2(660, 330)
	v.add_child(body)
	var cf: ConfigFile = SAVE.open()
	match tab:
		"game":
			body.add_child(_setting_slider("Master volume", db_to_linear(AudioServer.get_bus_volume_db(0)), 0.0, 1.0, func(x):
				AudioServer.set_bus_volume_db(0, linear_to_db(maxf(x, 0.0001))); _save_settings(), func(x): return "%d%%" % int(round(x * 100))))
			var combine := SKIN.checkbox("Combine move, interact and primary attack on the left mouse button")
			combine.button_pressed = dir.lab.hud.kb.combine_move_attack
			combine.toggled.connect(func(on): dir.lab.hud.kb.combine_move_attack = on; dir.lab.hud.kb.save_to_disk())
			body.add_child(combine)
			var auto := SKIN.checkbox("Pick up gold automatically")
			auto.button_pressed = bool(cf.get_value("settings", "auto_gold", true))
			auto.toggled.connect(func(on): dir.auto_gold = on; _set_setting("auto_gold", on))
			body.add_child(auto)
		"display":
			var fs := SKIN.checkbox("Fullscreen")
			fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			fs.toggled.connect(func(on):
				if DisplayServer.get_name() != "headless": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
				_set_setting("fullscreen", on))
			body.add_child(fs)
			var vs := SKIN.checkbox("Vertical sync")
			vs.button_pressed = bool(cf.get_value("settings", "vsync", true))
			vs.toggled.connect(func(on):
				if DisplayServer.get_name() != "headless": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if on else DisplayServer.VSYNC_DISABLED)
				_set_setting("vsync", on))
			body.add_child(vs)
			body.add_child(_setting_slider("Frame rate limit", float(cf.get_value("settings", "max_fps", 0)), 0.0, 240.0, func(x):
				Engine.max_fps = int(x); _set_setting("max_fps", int(x)), func(x): return "Unlimited" if int(x) == 0 else "%d fps" % int(x), 30.0))
		"controls":
			var l := _label("Every action can be bound to two keys or mouse buttons.", 16, IVORY, false)
			body.add_child(l)
			body.add_child(_button("Open Key Bindings", func(): close_panel(); dir.lab.hud.toggle_bind_menu(), 360.0))
			var keys := _label("I  Equipment   ·   C  Character   ·   K  Skills   ·   M  Map   ·   Esc  Menu   ·   F1  Key bindings", 15, MUTED, false)
			body.add_child(keys)
		"profile":
			var st = dir.state
			body.add_child(_label("Hero name", 17, GOLD))
			var name_edit := _line_edit(String(st.hero_name))
			name_edit.text_submitted.connect(func(t): _rename(name_edit))
			body.add_child(name_edit)
			body.add_child(_button("Rename", func(): _rename(name_edit), 260.0))
			body.add_child(_label("%s · Level %d · %s played" % [SKILLS.display_name(st.class_id), st.level, _hms(st.play_time)], 16, MUTED, false))
	v.add_child(_centered(SKIN.divider(560)))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.add_child(_button("Back", func(): _open_pause(), 260.0))
	row.add_child(_button("Resume", func(): close_panel(), 260.0))
	v.add_child(row)
	_pause_tree()

func _line_edit(text: String) -> LineEdit:
	var e := LineEdit.new()
	e.text = text
	e.max_length = 24
	e.custom_minimum_size = Vector2(420, 46)
	e.add_theme_font_override("font", font)
	e.add_theme_font_size_override("font_size", 20)
	e.add_theme_color_override("font_color", IVORY)
	var sb := SKIN.box("button_pressed", Vector4(30, 12, 30, 12), Vector4(30, 8, 30, 8))
	e.add_theme_stylebox_override("normal", sb)
	e.add_theme_stylebox_override("focus", SKIN.box("button_hover", Vector4(30, 12, 30, 12), Vector4(30, 8, 30, 8)))
	return e

func _rename(e: LineEdit) -> void:
	var t := e.text.strip_edges().left(24)
	if t == "": toast("Your hero needs a name", Color("ff7a6a"), 1.4, 18); return
	dir.state.hero_name = t
	dir.autosave()
	toast("You are now known as %s" % t, GOLD, 1.6, 20)

func _setting_slider(title: String, value: float, lo: float, hi: float, on_change: Callable, fmt: Callable, step := 0.05) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := _label(title, 17, IVORY, false)
	l.custom_minimum_size = Vector2(190, 0)
	row.add_child(l)
	var s := SKIN.slider(320.0)
	s.min_value = lo; s.max_value = hi; s.step = step
	s.value = value
	row.add_child(s)
	var val := _label(fmt.call(value), 16, GOLD)
	row.add_child(val)
	s.value_changed.connect(func(x): val.text = fmt.call(x); on_change.call(x))
	return row

func _set_setting(key: String, value) -> void:
	var cf: ConfigFile = SAVE.open()
	cf.set_value("settings", key, value)
	SAVE.commit(cf)

func _save_settings() -> void:
	var cf: ConfigFile = SAVE.open()
	cf.set_value("settings", "volume", db_to_linear(AudioServer.get_bus_volume_db(0)))
	SAVE.commit(cf)

func _hms(t: float) -> String:
	return "%dh %02dm" % [int(t) / 3600, (int(t) / 60) % 60]

func show_epilogue() -> void:
	var v := _modal("epilogue", 700.0, "CHAPTER COMPLETE")
	var t := _label("THE WHISPERWOOD IS FREE", 34, GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var st = dir.state
	for line in ["You have completed this chapter of Age of the Lost.", "Level %d · %d foes slain · %d deaths · %s" % [st.level, st.kills, st.deaths, _hms(st.play_time)], "Hollowmere awaits in the next chapter. You may keep exploring, hunting and gathering gear."]:
		var l := _label(line, 18, IVORY, false)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size = Vector2(600, 0)
		v.add_child(l)
	v.add_child(_centered(_button("Continue playing", func(): close_panel(), 440.0)))
