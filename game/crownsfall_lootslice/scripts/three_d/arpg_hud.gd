extends CanvasLayer
## ARPG HUD for the 3D lab, laid out after the owner's "AOTL 2.5D LAB v0.2" mockup (2026-11-20):
## logo + lab panel (top-left), minimap + quest tracker (top-right), HP globe + potion belt (bottom-left),
## skill bar + MP globe (bottom-right), purple XP bar with level (bottom-centre), overhead nameplate with
## level badge and HP/MP bars, thin red bars over enemies. Art reused from the 2D Crownfall HUD.

const UI := "res://assets/ui/arpg_hud/"
const TILES := "res://assets/skill_tiles/"
const GOLD := Color("d9b46a")
const GOLD_DIM := Color("8f7444")
const IVORY := Color("efe6cf")
const PANEL_BG := Color(0.05, 0.05, 0.07, 0.78)
const LEVEL := 25

## Bar layouts per hero: [key label, icon tile, MAGE_SPELLS key or warrior attack kind].
## W belongs to WASD movement, so skills sit on Q E R (T and RMB reserved, shown locked).
const MAGE_BAR := [["LMB", "starfall_script", "Bolt"], ["RMB", "", ""], ["Q", "epoch_lance", "Lance"],
	["E", "solar_writ", "Nova"], ["R", "dawnfall", "Judgment"], ["T", "", ""]]
const WARRIOR_BAR := [["LMB", "slash", "Slash"], ["RMB", "", ""], ["Q", "cleave", "Cleave"],
	["E", "charge", "Dash"], ["R", "rally", "Cast"], ["T", "", ""]]
## Potion belt: [key, kind, hp, mana]
const POTIONS := [[KEY_1, "hp", 45.0, 0.0], [KEY_2, "hp", 45.0, 0.0], [KEY_3, "hp", 45.0, 0.0],
	[KEY_4, "mana", 0.0, 60.0], [KEY_5, "mana", 0.0, 60.0]]
const POTION_CD := 6.0

var lab: Node3D
var player: CharacterBody3D
var font: FontFile
var font_regular: FontFile
var hp_globe: TextureProgressBar
var mp_globe: TextureProgressBar
var hp_label: Label
var mp_label: Label
var overlay: Control          # slot cooldowns, XP, minimap markers (above the panels)
var world_overlay: Control    # nameplate + enemy bars (beneath the panels, like world-space UI)
var bar_slots: Array = []     # [{rect, key, spell}]
var potion_slots: Array = []  # [{rect, idx}]
var potion_cds := [0.0, 0.0, 0.0, 0.0, 0.0]
var minimap_vp: SubViewport
var minimap_cam: Camera3D
var minimap_rect: Rect2
var xp_rect: Rect2
var bar_layout: Array = WARRIOR_BAR
var quest_progress := 0

func setup(owner_lab: Node3D) -> void:
	lab = owner_lab
	player = lab.player
	layer = 5
	font = load("res://assets/fonts/LiberationSerif-Bold.ttf")
	font_regular = load("res://assets/fonts/LiberationSerif-Regular.ttf")
	bar_layout = MAGE_BAR if player.is_pilot_mage() else WARRIOR_BAR
	player.number_keys_for_skills = false
	_build()

func _tex(name: String) -> Texture2D:
	return load(UI + name + ".png")

func _label(text: String, size: int, color: Color = IVORY, bold := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if bold else font_regular)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _panel(rect: Rect2, alpha := 0.78) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(PANEL_BG, alpha)
	sb.border_color = GOLD_DIM
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	p.add_theme_stylebox_override("panel", sb)
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _globe(full: String, empty: String, rect: Rect2) -> TextureProgressBar:
	var g := TextureProgressBar.new()
	g.texture_under = _tex(empty)
	g.texture_progress = _tex(full)
	g.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
	g.nine_patch_stretch = true
	g.position = rect.position
	g.size = rect.size
	g.max_value = 1000
	g.value = 1000
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	world_overlay = Control.new()
	world_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	world_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_overlay.draw.connect(_draw_world)
	root.add_child(world_overlay)
	var W := 1920.0
	var H := 1080.0
	# --- top-left: logo + lab panel
	var logo := _label("AGE of the LOST", 42, Color("e9dcc0"))
	logo.position = Vector2(24, 10)
	root.add_child(logo)
	var sub := _label("C R O W N S F A L L", 17, GOLD)
	sub.position = Vector2(74, 60)
	root.add_child(sub)
	var hero_name: String = "Mage (Meshy pilot)" if player.is_pilot_mage() else "Warrior (Meshy pilot)"
	var rows := [["AOTL 3D LAB (v0.3)", true], ["3D Scene: Active", false], ["Camera: Isometric (PoE Scale)", false],
		["Character: " + hero_name, false], ["Animation Set: %d clips" % player.animation.get_animation_list().size(), false],
		["Environment: Combat lab (alpha)", false]]
	var controls := [["W A S D", "Move"], ["LMB", "Primary Attack"], ["Q  E  R", "Skills / Spells"], ["Space", "Dodge Roll"],
		["1 – 5", "Potions"], ["Shift / Ctrl", "Run / Stroll"], ["F7", "Return to 2D plaza"]]
	var ph := 34.0 + rows.size() * 24.0 + 30.0 + controls.size() * 24.0
	root.add_child(_panel(Rect2(14, 92, 360, ph)))
	var y := 100.0
	for i in rows.size():
		var r: Array = rows[i]
		var l := _label(("" if r[1] else "☑  ") + r[0], 17 if r[1] else 15, GOLD if r[1] else IVORY, r[1])
		l.position = Vector2(26, y)
		root.add_child(l)
		y += 24.0 + (6.0 if r[1] else 0.0)
	var c := _label("▾  Controls", 15, GOLD)
	c.position = Vector2(26, y + 4)
	root.add_child(c)
	y += 30.0
	for k in controls:
		var kl := _label(k[0], 13, IVORY)
		kl.position = Vector2(34, y + 2)
		root.add_child(kl)
		var vl := _label(k[1], 15, IVORY, false)
		vl.position = Vector2(150, y)
		root.add_child(vl)
		y += 24.0
	# --- top-right: minimap + quests
	minimap_rect = Rect2(W - 334, 14, 320, 236)
	minimap_vp = SubViewport.new()
	minimap_vp.size = Vector2i(320, 236)
	minimap_vp.world_3d = lab.get_world_3d()
	minimap_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(minimap_vp)
	minimap_cam = Camera3D.new()
	minimap_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	minimap_cam.size = 30.0
	minimap_cam.cull_mask = 1
	minimap_vp.add_child(minimap_cam)
	var mm := TextureRect.new()
	mm.texture = minimap_vp.get_texture()
	mm.position = minimap_rect.position
	mm.size = minimap_rect.size
	mm.modulate = Color(0.82, 0.8, 0.86)
	mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mm)
	var t1 := _label("Crownsfall", 19, IVORY)
	t1.position = minimap_rect.position + Vector2(10, 6)
	root.add_child(t1)
	var t2 := _label("Central Plaza", 14, IVORY, false)
	t2.position = minimap_rect.position + Vector2(10, 28)
	root.add_child(t2)
	var qy := minimap_rect.end.y + 12
	root.add_child(_panel(Rect2(W - 334, qy, 320, 118), 0.62))
	for q in [["A City Reborn", "Speak with Captain Ralden"], ["The Lost Tomes", "Recover the Archive Pages (%d/3)"]]:
		var ql := _label("◆  " + q[0], 17, Color("e8b85c"))
		ql.position = Vector2(W - 322, qy + 8)
		ql.name = "Quest_" + q[0].replace(" ", "")
		root.add_child(ql)
		var ol := _label("☐  " + (q[1] % quest_progress if "%d" in q[1] else q[1]), 14, Color("cfc7b8"), false)
		ol.position = Vector2(W - 312, qy + 32)
		ol.name = "Objective_" + q[0].replace(" ", "")
		root.add_child(ol)
		qy += 56
	# --- bottom: globes, belts, xp
	var g := 196.0
	hp_globe = _globe("orb_life_full", "orb_life_empty", Rect2(10, H - g * 1.106 - 8, g, g * 1.106))
	root.add_child(hp_globe)
	mp_globe = _globe("orb_mana_full", "orb_mana_empty", Rect2(W - g - 10, H - g * 1.106 - 8, g, g * 1.106))
	root.add_child(mp_globe)
	hp_label = _label("HP", 18, IVORY)
	hp_label.position = Vector2(206, H - 156)
	root.add_child(hp_label)
	mp_label = _label("MP", 18, IVORY)
	mp_label.position = Vector2(W - 206 - 170, H - 156)
	mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mp_label.size = Vector2(170, 24)
	root.add_child(mp_label)
	var slot := 64.0
	var gap := 8.0
	# potion belt (5 potions + tome)
	var belt_w := 6 * slot + 5 * gap + 34
	var belt := NinePatchRect.new()
	belt.texture = _tex("belt_plate")
	belt.patch_margin_left = 40; belt.patch_margin_right = 40; belt.patch_margin_top = 40; belt.patch_margin_bottom = 40
	belt.position = Vector2(200, H - 124)
	belt.size = Vector2(belt_w, 104)
	belt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(belt)
	for i in 6:
		var r := Rect2(belt.position + Vector2(17 + i * (slot + gap), 14), Vector2(slot, slot))
		_socket(root, r)
		if i < 5:
			var p := TextureRect.new()
			p.texture = _tex("potion_mana" if POTIONS[i][1] == "mana" else "potion")
			p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			p.position = r.position + Vector2(6, 4)
			p.size = r.size - Vector2(12, 8)
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.add_child(p)
			var kl := _label(str(i + 1), 14, IVORY)
			kl.position = Vector2(r.position.x + slot * 0.5 - 4, r.end.y + 2)
			root.add_child(kl)
			potion_slots.append({"rect": r, "idx": i})
		else:
			var tome := _label("📖", 30, GOLD)
			tome.position = r.position + Vector2(14, 10)
			root.add_child(tome)
	# skill bar (LMB + Q W E R T)
	var bar_w := 6 * slot + 5 * gap + 34
	var bar := NinePatchRect.new()
	bar.texture = _tex("belt_plate")
	bar.patch_margin_left = 40; bar.patch_margin_right = 40; bar.patch_margin_top = 40; bar.patch_margin_bottom = 40
	bar.position = Vector2(W - 200 - bar_w, H - 124)
	bar.size = Vector2(bar_w, 104)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	for i in bar_layout.size():
		var spec: Array = bar_layout[i]
		var r := Rect2(bar.position + Vector2(17 + i * (slot + gap), 14), Vector2(slot, slot))
		_socket(root, r)
		var icon := TextureRect.new()
		icon.texture = load(TILES + spec[1] + ".png") if spec[1] != "" else _tex("lock")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var inset := 4.0 if spec[1] != "" else 16.0
		icon.position = r.position + Vector2(inset, inset)
		icon.size = r.size - Vector2(inset * 2, inset * 2)
		icon.modulate = Color.WHITE if spec[1] != "" else Color(1, 1, 1, 0.45)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(icon)
		var kl := _label(spec[0], 14, IVORY)
		kl.position = Vector2(r.position.x + slot * 0.5 - (12 if spec[0].length() > 1 else 5), r.end.y + 2)
		root.add_child(kl)
		bar_slots.append({"rect": r, "key": spec[0], "spell": spec[2]})
	# XP bar between the belts
	xp_rect = Rect2(belt.position.x + belt_w + 26, H - 34, bar.position.x - (belt.position.x + belt_w) - 52, 12)
	var lv := _label("Lv. %d" % LEVEL, 15, IVORY)
	lv.position = Vector2(xp_rect.get_center().x - 22, xp_rect.position.y - 24)
	root.add_child(lv)
	# world-anchored layer + dynamic overlays
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_overlay)
	root.add_child(overlay)
	for t in lab.targets:
		if t.title != null:
			t.title.visible = false

func _socket(root: Control, r: Rect2) -> void:
	var s := TextureRect.new()
	s.texture = _tex("slot_socket")
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.position = r.position
	s.size = r.size
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(s)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	for i in POTIONS.size():
		if event.keycode == POTIONS[i][0]:
			drink(i)

## Drink potion slot `i` (0-4). Returns true if it restored anything.
func drink(i: int) -> bool:
	if potion_cds[i] > 0.0:
		return false
	var ok: bool = player.restore(POTIONS[i][2], POTIONS[i][3])
	if ok:
		potion_cds[i] = POTION_CD
	return ok

func _process(delta: float) -> void:
	if player == null:
		return
	for i in potion_cds.size():
		potion_cds[i] = maxf(0.0, potion_cds[i] - delta)
	hp_globe.value = 1000.0 * player.hp / player.max_hp
	mp_globe.value = 1000.0 * player.mana / player.max_mana
	hp_label.text = "HP %d / %d" % [roundi(player.hp), roundi(player.max_hp)]
	mp_label.text = "MP %d / %d" % [roundi(player.mana), roundi(player.max_mana)]
	var p: Vector3 = player.global_position
	minimap_cam.look_at_from_position(p + Vector3.UP * 40.0, p, Vector3.FORWARD)
	var q := mini(3, lab.kills)
	if q != quest_progress:
		quest_progress = q
		var ol: Label = find_child("Objective_TheLostTomes", true, false)
		if ol: ol.text = "☐  Recover the Archive Pages (%d/3)" % q
	overlay.queue_redraw()
	world_overlay.queue_redraw()

func _cooldown_fraction(spell: String) -> float:
	if spell == "":
		return 0.0
	if player.is_pilot_mage() and player.MAGE_SPELLS.has(spell):
		var cd: float = player.MAGE_SPELLS[spell]["cd"]
		return clampf(float(player.spell_cds.get(spell, 0.0)) / cd, 0.0, 1.0) if cd > 0.0 else 0.0
	if spell == "Cast":
		return clampf(player.spell_cd / 3.5, 0.0, 1.0)
	return 0.0

func _unaffordable(spell: String) -> bool:
	if player.is_pilot_mage() and player.MAGE_SPELLS.has(spell):
		return player.mana < float(player.MAGE_SPELLS[spell].get("cost", 0.0))
	return spell == "Cast" and player.mana < player.WARRIOR_CAST_COST

func _bar(at: Vector2, w: float, h: float, frac: float, col: Color) -> void:
	world_overlay.draw_rect(Rect2(at - Vector2(1, 1), Vector2(w + 2, h + 2)), Color(0, 0, 0, 0.85))
	world_overlay.draw_rect(Rect2(at, Vector2(w * clampf(frac, 0.0, 1.0), h)), col)

func _draw_overlay() -> void:
	var cam: Camera3D = lab.camera
	# slot overlays: cooldown shade from the top, red tint when mana is short
	for s in bar_slots:
		var r: Rect2 = s["rect"]
		var f := _cooldown_fraction(s["spell"])
		if f > 0.0:
			overlay.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * f)), Color(0, 0, 0, 0.62))
		if _unaffordable(s["spell"]):
			overlay.draw_rect(r, Color(0.25, 0.05, 0.25, 0.45))
	for s in potion_slots:
		var r: Rect2 = s["rect"]
		var f: float = potion_cds[s["idx"]] / POTION_CD
		if f > 0.0:
			overlay.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * f)), Color(0, 0, 0, 0.62))
	# XP bar
	overlay.draw_rect(xp_rect.grow(2), Color(0.08, 0.06, 0.05, 0.95))
	overlay.draw_rect(xp_rect.grow(2), GOLD_DIM, false, 1.0)
	var xp_frac := fposmod(0.42 + lab.kills * 0.07, 1.0)
	overlay.draw_rect(Rect2(xp_rect.position, Vector2(xp_rect.size.x * xp_frac, xp_rect.size.y)), Color("8a4fd8"))
	overlay.draw_rect(Rect2(xp_rect.position, Vector2(xp_rect.size.x * xp_frac, 3)), Color("c7a3ff"))
	# minimap frame + markers
	overlay.draw_rect(minimap_rect, GOLD, false, 2.0)
	var mm_scale := minimap_rect.size.y / minimap_cam.size
	var centre := minimap_rect.get_center()
	for t in lab.targets:
		var d: Vector3 = t.global_position - player.global_position
		var at := centre + Vector2(d.x, d.z) * mm_scale
		if minimap_rect.has_point(at):
			overlay.draw_circle(at, 4.0, Color("d8463a") if t.inactive_t <= 0.0 else Color(0.4, 0.4, 0.4))
	overlay.draw_circle(centre, 6.0, Color(0, 0, 0, 0.8))
	overlay.draw_circle(centre, 4.5, Color("f2d27a"))

func _draw_world() -> void:
	var cam: Camera3D = lab.camera
	if cam == null:
		return
	# enemy bars
	for t in lab.targets:
		if t.inactive_t > 0.0:
			continue
		var top: Vector3 = t.global_position + Vector3.UP * 2.35
		if cam.is_position_behind(top):
			continue
		var sp := cam.unproject_position(top)
		_bar(sp - Vector2(26, 0), 52, 5, t.hp / t.max_hp, Color("c8372d"))
	# player nameplate: level badge, name, HP (green) and MP (blue)
	var head: Vector3 = player.global_position + Vector3.UP * 2.25
	if not cam.is_position_behind(head):
		var hp := cam.unproject_position(head)
		world_overlay.draw_string_outline(font, hp + Vector2(-8, -20), "Wayfarer", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.9))
		world_overlay.draw_string(font, hp + Vector2(-8, -20), "Wayfarer", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, IVORY)
		_bar(hp + Vector2(-8, -12), 72, 5, player.hp / player.max_hp, Color("3fbf4a"))
		_bar(hp + Vector2(-8, -5), 72, 3, player.mana / player.max_mana, Color("3f7fe0"))
		world_overlay.draw_circle(hp + Vector2(-24, -11), 13.0, Color(0.06, 0.05, 0.05, 0.95))
		world_overlay.draw_arc(hp + Vector2(-24, -11), 13.0, 0, TAU, 32, GOLD, 1.5)
		world_overlay.draw_string(font, hp + Vector2(-33, -5), str(LEVEL), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, IVORY)
