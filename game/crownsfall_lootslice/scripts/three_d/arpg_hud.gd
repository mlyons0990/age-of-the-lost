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
## The mockup panel's five wells, Q W E R T (click-to-move, so W is a skill). LMB is move / primary attack.
const MAGE_BAR := [["Q", "epoch_lance", "Lance"], ["W", "solar_writ", "Nova"], ["E", "dawnfall", "Judgment"],
	["R", "", ""], ["T", "", ""]]
const WARRIOR_BAR := [["Q", "cleave", "Cleave"], ["W", "charge", "Dash"], ["E", "rally", "Cast"],
	["R", "", ""], ["T", "", ""]]
## Potion belt: [key, kind, hp, mana]
const POTIONS := [[KEY_1, "hp", 45.0, 0.0], [KEY_2, "hp", 45.0, 0.0], [KEY_3, "hp", 45.0, 0.0],
	[KEY_4, "mana", 0.0, 60.0], [KEY_5, "mana", 0.0, 60.0]]
const POTION_CD := 6.0

var lab: Node3D
var player: CharacterBody3D
var font: FontFile
var font_regular: FontFile
const DISC_SHADER := """
shader_type canvas_item;
uniform float fill = 1.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float inside = smoothstep(1.0, 0.965, r);
	float y = 1.0 - UV.y;                                   // 0 at the bottom of the disc, 1 at the top
	float empty = smoothstep(fill - 0.012, fill + 0.02, y); // spent part, above the liquid surface
	float meniscus = exp(-pow((y - fill) * 45.0, 2.0)) * step(0.01, fill) * step(fill, 0.99);
	vec3 col = mix(vec3(0.015, 0.015, 0.03), vec3(1.0, 0.96, 0.9), meniscus);
	COLOR = vec4(col, max(0.82 * empty, 0.16 * meniscus) * inside);
}
"""
var hp_shade: ColorRect
var mp_shade: ColorRect
var left_piece: TextureRect
var right_piece: TextureRect
var strip_rect: Rect2
var orb_l: Vector3   # x, y, radius of the frame's painted life orb (screen px)
var orb_r: Vector3
var hp_frac := 1.0
var mp_frac := 1.0
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
	player.click_to_move = true
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
	var controls := [["LMB", "Move / Attack (hold)"], ["Shift + LMB", "Attack in place"], ["Q W E R T", "Skills / Spells"],
		["Space", "Dodge Roll"], ["1 – 5", "Potions"], ["F7", "Return to 2D plaza"]]
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
	# Owner's mockup HUD: statue + life orb + potion belt flush bottom-left, skill panel + mana orb + statue flush
	# bottom-right, a bronze XP strip joining them along the bottom edge. Pieces are cut from the owner's mockup
	# close-ups (hud_left/right.png); slot positions in hud_mockup.json are in those images' pixels.
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(UI + "hud_mockup.json"))
	var vs: Vector2 = lab.get_viewport().get_visible_rect().size
	W = vs.x
	H = vs.y
	var ui_k: float = H / 1080.0
	var L: Dictionary = meta["left"]
	var R: Dictionary = meta["right"]
	var sl: float = float(L["image_scale"]) * ui_k     # source px -> screen px
	var sr: float = float(R["image_scale"]) * ui_k
	var lsz := Vector2(L["size"][0], L["size"][1]) * sl
	var rsz := Vector2(R["size"][0], R["size"][1]) * sr
	left_piece = _piece("hud_left", Rect2(0, H - lsz.y, lsz.x, lsz.y))
	right_piece = _piece("hud_right", Rect2(W - rsz.x, H - rsz.y, rsz.x, rsz.y))
	root.add_child(left_piece)
	root.add_child(right_piece)
	var lo := left_piece.position
	var ro := right_piece.position
	var lmap := func(v: Array) -> Rect2: return Rect2(lo + Vector2(v[0], v[1]) * sl, Vector2(v[2], v[3]) * sl)
	var rmap := func(v: Array) -> Rect2: return Rect2(ro + Vector2(v[0], v[1]) * sr, Vector2(v[2], v[3]) * sr)
	var oo: Array = L["orb_outer"]
	orb_l = Vector3(lo.x + oo[0] * sl, lo.y + oo[1] * sl, oo[2] * sl)
	oo = R["orb_outer"]
	orb_r = Vector3(ro.x + oo[0] * sr, ro.y + oo[1] * sr, oo[2] * sr)
	# drained-orb shading: a shader clipped to each glass disc (slightly elliptical in the art)
	hp_shade = _disc_shade(root, lo, sl, L["disc"])
	mp_shade = _disc_shade(root, ro, sr, R["disc"])
	# XP strip: from the left belt's housing to the right panel's housing, along the bottom edge
	var lh: Rect2 = lmap.call(L["xp_housing"])
	var rh: Rect2 = rmap.call(R["xp_housing"])
	strip_rect = Rect2(lh.position.x + lh.size.x * 0.4, lh.position.y, rh.end.x - lh.size.x * 0.4 - lh.position.x, lh.size.y)
	xp_rect = Rect2(strip_rect.position.x + 8 * ui_k, strip_rect.get_center().y - 5 * ui_k, strip_rect.size.x - 16 * ui_k, 10 * ui_k)
	# live labels on dark plates, where the mockup prints them
	var plate_sb := StyleBoxFlat.new()
	plate_sb.bg_color = Color(0.03, 0.03, 0.04, 0.8)
	plate_sb.set_corner_radius_all(3)
	var hp_pos: Vector2 = lo + Vector2(L["label_anchor"][0], L["label_anchor"][1]) * sl
	var hp_plate := Panel.new()
	hp_plate.add_theme_stylebox_override("panel", plate_sb)
	hp_plate.position = hp_pos - Vector2(8, 2) * ui_k
	hp_plate.size = Vector2(150, 30) * ui_k
	hp_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp_plate)
	hp_label = _label("HP", int(19 * ui_k), IVORY)
	hp_label.position = hp_pos
	root.add_child(hp_label)
	mp_label = _label("MP", int(19 * ui_k), IVORY)
	mp_label.size = Vector2(220 * ui_k, 26 * ui_k)
	mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mp_label.position = ro + Vector2(R["label_anchor"][0], R["label_anchor"][1]) * sr - Vector2(mp_label.size.x, 0)
	var mp_plate := Panel.new()
	mp_plate.add_theme_stylebox_override("panel", plate_sb)
	mp_plate.size = Vector2(150, 30) * ui_k
	mp_plate.position = Vector2(mp_label.position.x + mp_label.size.x - mp_plate.size.x + 8 * ui_k, mp_label.position.y - 2 * ui_k)
	mp_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mp_plate)
	root.move_child(mp_plate, mp_label.get_index() if mp_label.get_parent() else root.get_child_count() - 1)
	root.add_child(mp_label)
	# potions are painted into the belt; keep their rects for cooldown shading
	for i in 5:
		potion_slots.append({"rect": lmap.call(L["potions"][i]), "idx": i})
	# skills: live icons in the panel wells, live key labels on the plates
	for i in bar_layout.size():
		var spec: Array = bar_layout[i]
		var r: Rect2 = rmap.call(R["skills"][i])
		var icon := TextureRect.new()
		icon.texture = load(TILES + spec[1] + ".png") if spec[1] != "" else _tex("lock")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var inset: float = (3.0 if spec[1] != "" else 16.0) * ui_k
		icon.position = r.position + Vector2(inset, inset)
		icon.size = r.size - Vector2(inset * 2, inset * 2)
		icon.modulate = Color.WHITE if spec[1] != "" else Color(1, 1, 1, 0.3)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(icon)
		var kr: Rect2 = rmap.call(R["keys"][i])
		var kl := _label(spec[0], int(17 * ui_k), IVORY)
		kl.size = kr.size
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		kl.position = kr.position
		root.add_child(kl)
		bar_slots.append({"rect": r, "key": spec[0], "spell": spec[2]})
	var lv := _label("Lv. %d" % LEVEL, int(14 * ui_k), IVORY)
	lv.size = Vector2(120 * ui_k, 20 * ui_k)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lv.position = Vector2(xp_rect.get_center().x - 60 * ui_k, xp_rect.get_center().y - 10 * ui_k)
	lv.z_index = 2
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

func _disc_shade(root: Control, origin: Vector2, k: float, d: Array) -> ColorRect:
	var c := ColorRect.new()
	var sh := Shader.new()
	sh.code = DISC_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	c.material = m
	c.color = Color.WHITE
	c.size = Vector2(d[2], d[3]) * 2.0 * k
	c.position = origin + Vector2(d[0], d[1]) * k - c.size * 0.5
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(c)
	return c

func _piece(name: String, r: Rect2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = _tex(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

func _keycap(root: Control, text: String, r: Rect2, k: float) -> void:
	if text == "":
		return
	var kl := _label(text, int(13 * k), IVORY)
	kl.size = Vector2(r.size.x, 18 * k)
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kl.position = Vector2(r.position.x, r.end.y - 15 * k)
	root.add_child(kl)

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
	hp_frac = clampf(player.hp / player.max_hp, 0.0, 1.0)
	mp_frac = clampf(player.mana / player.max_mana, 0.0, 1.0)
	(hp_shade.material as ShaderMaterial).set_shader_parameter("fill", hp_frac)
	(mp_shade.material as ShaderMaterial).set_shader_parameter("fill", mp_frac)
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
	# bronze housing strip joining the two pieces along the bottom edge
	overlay.draw_rect(strip_rect, Color(0.09, 0.08, 0.075, 1.0))
	overlay.draw_rect(Rect2(strip_rect.position, Vector2(strip_rect.size.x, 3)), Color("6b5a43"))
	overlay.draw_rect(Rect2(strip_rect.position + Vector2(0, 3), Vector2(strip_rect.size.x, 1)), Color("2a241d"))
	overlay.draw_rect(Rect2(Vector2(strip_rect.position.x, strip_rect.end.y - 3), Vector2(strip_rect.size.x, 3)), Color("4a3e30"))
	overlay.draw_rect(xp_rect.grow(2), Color(0.04, 0.035, 0.03, 1.0))
	overlay.draw_rect(xp_rect.grow(2), Color("5d4d39"), false, 1.0)
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
