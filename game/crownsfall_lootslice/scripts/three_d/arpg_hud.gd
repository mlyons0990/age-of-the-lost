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

const KEYBINDS := preload("res://scripts/three_d/keybinds.gd")
const LOADOUT_PATH := "user://aotl_loadout.cfg"
## Skills a hero can put on the bar (click a skill well to choose, like Diablo 4 / PoE). name -> icon tile.
const HERO_SKILLS := {
	"mage": {"Bolt": "starfall_script", "Lance": "epoch_lance", "Nova": "solar_writ", "Judgment": "dawnfall"},
	"warrior": {"Slash": "slash", "Cleave": "cleave", "Dash": "charge", "Cast": "rally"},
}
const DEFAULT_SKILLS := {"mage": ["Lance", "Nova", "Judgment", "Bolt", ""], "warrior": ["Cleave", "Dash", "Cast", "Slash", ""]}
## Potion types for the belt (click a potion well to choose).
const POTION_TYPES := {"health": {"tex": "potion", "hp": 45.0, "mp": 0.0}, "mana": {"tex": "potion_mana", "hp": 0.0, "mp": 60.0}}
const DEFAULT_POTIONS := ["health", "health", "health", "mana", "mana"]
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
var bar_slots: Array = []     # [{rect, idx}] skill wells (contents in skill_loadout)
var potion_slots: Array = []  # [{rect, idx}] potion wells (contents in potion_loadout)
var kb                        # keybinds.gd instance
var hero := "warrior"
var skill_loadout: Array = []
var potion_loadout: Array = []
var skill_icons: Array = []   # TextureRect per skill well
var potion_icons: Array = []
var key_labels := {}          # action -> Label on its plate
var picker: PopupMenu
var picker_target := []       # ["skill"|"potion", idx]
var bind_menu: PanelContainer
var bind_buttons := {}        # action -> [Button, Button]
var capturing := []           # [action, slot] while waiting for a key
var potion_cds := [0.0, 0.0, 0.0, 0.0, 0.0]
var minimap_vp: SubViewport
var minimap_cam: Camera3D
var minimap_rect: Rect2
var xp_rect: Rect2
var quest_progress := 0

func setup(owner_lab: Node3D) -> void:
	lab = owner_lab
	player = lab.player
	layer = 5
	font = load("res://assets/fonts/LiberationSerif-Bold.ttf")
	font_regular = load("res://assets/fonts/LiberationSerif-Regular.ttf")
	hero = "mage" if player.is_pilot_mage() else "warrior"
	player.number_keys_for_skills = false
	player.click_to_move = true
	kb = KEYBINDS.new()
	kb.changed_listeners.append(_refresh_keys)
	_load_loadout()
	_build()
	_refresh_slots()
	_refresh_keys()

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
	var controls := [["LMB", "Move / Attack (hold)"], ["Shift + LMB", "Attack in place"], ["Skill bar", "Skills (click a slot to swap)"],
		["Belt", "Potions (click a slot to swap)"], ["Space", "Dodge Roll"], ["F1", "Key Bindings (rebind anything)"], ["F7", "Return to 2D plaza"]]
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
	# --- bottom: Higgsfield redraw of the owner's mockup (A1-A3): statue + HP globe + potion belt flush bottom-left,
	# skill panel + MP globe + statue flush bottom-right, XP strip joining them. Wells and key plates are blank in
	# the art: contents (any skill / potion) and key labels (any binding) are drawn live.
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(UI + "hud_redraw.json"))
	var vs: Vector2 = lab.get_viewport().get_visible_rect().size
	W = vs.x
	H = vs.y
	var ui_k: float = H / 1080.0
	var hi := ui_k > 1.05
	var L: Dictionary = meta["left"]
	var R: Dictionary = meta["right"]
	var lsz := Vector2(L["size"][0], L["size"][1]) * ui_k
	var rsz := Vector2(R["size"][0], R["size"][1]) * ui_k
	left_piece = _piece("hud_left_hd@2x" if hi else "hud_left_hd", Rect2(0, H - lsz.y, lsz.x, lsz.y))
	right_piece = _piece("hud_right_hd@2x" if hi else "hud_right_hd", Rect2(W - rsz.x, H - rsz.y, rsz.x, rsz.y))
	var lo := left_piece.position
	var ro := right_piece.position
	var lmap := func(v: Array) -> Rect2: return Rect2(lo + Vector2(v[0], v[1]) * ui_k, Vector2(v[2], v[3]) * ui_k)
	var rmap := func(v: Array) -> Rect2: return Rect2(ro + Vector2(v[0], v[1]) * ui_k, Vector2(v[2], v[3]) * ui_k)
	# XP strip behind the pieces' inner ends, aligned with the skill panel's low ledge
	var X: Dictionary = meta["xp_strip"]
	var ledge: Rect2 = rmap.call(R["xp_ledge"])
	var sh: float = float(X["size"][1]) * ui_k
	var strip := NinePatchRect.new()
	strip.texture = _tex("hud_xp_strip@2x" if hi else "hud_xp_strip")
	var cap: int = int(float(X["size"][0]) * float(X["cap_frac"]) * (2.0 if hi else 1.0)) + 2
	strip.patch_margin_left = cap; strip.patch_margin_right = cap
	strip.position = Vector2(lo.x + lsz.x - 20 * ui_k, ledge.get_center().y - sh * 0.5)
	strip.size = Vector2(ledge.position.x + ledge.size.x * 0.7 - strip.position.x, sh)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(strip)
	strip_rect = Rect2(strip.position, strip.size)
	var inner: Array = X["inner_frac"]
	# the fill draws above the pieces, so keep it to the groove visible between them
	var gx0: float = lo.x + lsz.x + 3 * ui_k
	var gx1: float = ro.x - 3 * ui_k
	xp_rect = Rect2(gx0, strip.position.y + sh * float(inner[1]), gx1 - gx0, sh * float(inner[3]))
	root.add_child(left_piece)
	root.add_child(right_piece)
	var dl: Array = L["disc"]
	var dr: Array = R["disc"]
	orb_l = Vector3(lo.x + dl[0] * ui_k, lo.y + dl[1] * ui_k, dl[2] * ui_k)
	orb_r = Vector3(ro.x + dr[0] * ui_k, ro.y + dr[1] * ui_k, dr[2] * ui_k)
	hp_shade = _disc_shade(root, lo, ui_k, dl)
	mp_shade = _disc_shade(root, ro, ui_k, dr)
	# live HP / MP values on dark plates above the belts
	var plate_sb := StyleBoxFlat.new()
	plate_sb.bg_color = Color(0.03, 0.03, 0.04, 0.8)
	plate_sb.set_corner_radius_all(3)
	var w0: Rect2 = lmap.call(L["wells"][0])
	var hp_plate := Panel.new()
	hp_plate.add_theme_stylebox_override("panel", plate_sb)
	hp_plate.size = Vector2(150, 30) * ui_k
	hp_plate.position = Vector2(w0.position.x - 6 * ui_k, lo.y + 40 * ui_k)
	hp_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp_plate)
	hp_label = _label("HP", int(19 * ui_k), IVORY)
	hp_label.position = hp_plate.position + Vector2(8, 2) * ui_k
	root.add_child(hp_label)
	var wl: Rect2 = rmap.call(R["wells"][4])
	var mp_plate := Panel.new()
	mp_plate.add_theme_stylebox_override("panel", plate_sb)
	mp_plate.size = Vector2(150, 30) * ui_k
	mp_plate.position = Vector2(wl.end.x - mp_plate.size.x + 6 * ui_k, lo.y + 40 * ui_k + (ro.y - lo.y))
	mp_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mp_plate)
	mp_label = _label("MP", int(19 * ui_k), IVORY)
	mp_label.size = mp_plate.size - Vector2(16, 4) * ui_k
	mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mp_label.position = mp_plate.position + Vector2(8, 2) * ui_k
	root.add_child(mp_label)
	# wells: clickable (swap contents), live icon, live key label on the plate below
	for i in 5:
		var r: Rect2 = lmap.call(L["wells"][i])
		potion_slots.append({"rect": r, "idx": i})
		potion_icons.append(_well(root, r, "potion", i, 0.12))
		key_labels["potion_%d" % (i + 1)] = _plate_label(root, lmap.call(L["plates"][i]), ui_k)
	for i in 5:
		var r: Rect2 = rmap.call(R["wells"][i])
		bar_slots.append({"rect": r, "idx": i})
		skill_icons.append(_well(root, r, "skill", i, 0.04))
		key_labels["skill_%d" % (i + 1)] = _plate_label(root, rmap.call(R["plates"][i]), ui_k)
	var lv := _label("Lv. %d" % LEVEL, int(13 * ui_k), IVORY)
	lv.size = Vector2(120 * ui_k, xp_rect.size.y + 6 * ui_k)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lv.position = Vector2(xp_rect.get_center().x - 60 * ui_k, xp_rect.position.y - 3 * ui_k)
	lv.z_index = 2
	root.add_child(lv)
	picker = PopupMenu.new()
	picker.id_pressed.connect(_on_pick)
	add_child(picker)
	_build_bind_menu(root, ui_k)
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

# ---------------- wells, loadout, picker ----------------

func _well(root: Control, r: Rect2, kind: String, idx: int, inset_frac: float) -> TextureRect:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.position = r.position
	b.size = r.size
	b.tooltip_text = "Click to change this %s slot" % kind
	b.pressed.connect(_open_picker.bind(kind, idx))
	b.name = "%sWell%d" % [kind.capitalize(), idx + 1]
	root.add_child(b)
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var inset := r.size * inset_frac
	t.position = inset
	t.size = r.size - inset * 2.0
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(t)
	return t

func _plate_label(root: Control, r: Rect2, ui_k: float) -> Label:
	var l := _label("", int(15 * ui_k), IVORY)
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	root.add_child(l)
	return l

func _refresh_slots() -> void:
	for i in 5:
		var sk: String = skill_loadout[i]
		skill_icons[i].texture = load(TILES + HERO_SKILLS[hero][sk] + ".png") if sk != "" else null
		var pt: String = potion_loadout[i]
		potion_icons[i].texture = _tex(POTION_TYPES[pt]["tex"]) if pt != "" else null

func _refresh_keys() -> void:
	for a in key_labels.keys():
		key_labels[a].text = kb.key_label(a)
	if bind_menu != null:
		for a in bind_buttons.keys():
			for i in 2:
				bind_buttons[a][i].text = _bind_text(kb.binds[a][i])

func _open_picker(kind: String, idx: int) -> void:
	picker.clear()
	picker_target = [kind, idx]
	var names: Array = HERO_SKILLS[hero].keys() if kind == "skill" else POTION_TYPES.keys()
	for n in names.size():
		picker.add_item(String(names[n]).capitalize(), n)
	picker.add_separator()
	picker.add_item("(Empty)", 99)
	picker.position = Vector2i(get_viewport().get_mouse_position()) - Vector2i(0, 40 + 24 * names.size())
	picker.popup()

func _on_pick(id: int) -> void:
	var kind: String = picker_target[0]
	var names: Array = HERO_SKILLS[hero].keys() if kind == "skill" else POTION_TYPES.keys()
	assign(kind, picker_target[1], "" if id == 99 else String(names[id]))

## Put `what` ("" = empty) in skill or potion slot `idx`. A skill already on the bar moves (no duplicates, as in D4).
func assign(kind: String, idx: int, what: String) -> void:
	if kind == "skill":
		if what != "" and what in skill_loadout:
			skill_loadout[skill_loadout.find(what)] = skill_loadout[idx]
		skill_loadout[idx] = what
	else:
		potion_loadout[idx] = what
	_save_loadout()
	_refresh_slots()

func _load_loadout() -> void:
	skill_loadout = DEFAULT_SKILLS[hero].duplicate()
	potion_loadout = DEFAULT_POTIONS.duplicate()
	var cf := ConfigFile.new()
	if cf.load(LOADOUT_PATH) == OK:
		var s: Array = cf.get_value(hero, "skills", skill_loadout)
		var p: Array = cf.get_value(hero, "potions", potion_loadout)
		if s.size() == 5 and s.all(func(x): return x == "" or HERO_SKILLS[hero].has(x)): skill_loadout = s
		if p.size() == 5 and p.all(func(x): return x == "" or POTION_TYPES.has(x)): potion_loadout = p

func _save_loadout() -> void:
	var cf := ConfigFile.new()
	cf.load(LOADOUT_PATH)
	cf.set_value(hero, "skills", skill_loadout)
	cf.set_value(hero, "potions", potion_loadout)
	cf.save(LOADOUT_PATH)

## True while the mouse is over a HUD well or the bindings menu (clicks there must not walk the hero).
func pointer_over_ui() -> bool:
	var m := get_viewport().get_mouse_position()
	if bind_menu.visible and Rect2(bind_menu.position, bind_menu.size).has_point(m):
		return true
	for s in bar_slots + potion_slots:
		if (s["rect"] as Rect2).has_point(m):
			return true
	return false

# ---------------- actions ----------------

func use_skill_slot(i: int) -> void:
	var sk: String = skill_loadout[i]
	if sk != "":
		player.use_skill(sk)

## Drink potion slot `i` (0-4). Returns true if it restored anything.
func drink(i: int) -> bool:
	var pt: String = potion_loadout[i]
	if pt == "" or potion_cds[i] > 0.0:
		return false
	var ok: bool = player.restore(POTION_TYPES[pt]["hp"], POTION_TYPES[pt]["mp"])
	if ok:
		potion_cds[i] = POTION_CD
	return ok

func _unhandled_input(event: InputEvent) -> void:
	if bind_menu.visible or not (event.is_pressed()) or event.is_echo():
		if bind_menu.visible and kb.action_for_event(event) == "keybinds":
			toggle_bind_menu()
			get_viewport().set_input_as_handled()
		return
	var a: String = kb.action_for_event(event)
	if a == "":
		return
	if a.begins_with("skill_"):
		use_skill_slot(int(a.substr(6)) - 1)
	elif a.begins_with("potion_"):
		drink(int(a.substr(7)) - 1)
	elif a == "dodge":
		player.dodge_toward_aim()
	elif a == "keybinds":
		toggle_bind_menu()
	elif a == "move":
		var at: Vector2 = event.position if event is InputEventMouse else get_viewport().get_mouse_position()
		lab.handle_click(at, kb.held("force_stand"), kb.combine_move_attack)
	else:
		return
	get_viewport().set_input_as_handled()

# ---------------- key bindings menu (Diablo 4 / PoE style) ----------------

func _bind_text(spec: String) -> String:
	if spec == "":
		return "—"
	var t: String = KEYBINDS.short_label(spec)
	return t.replace("C+", "Ctrl+").replace("A+", "Alt+").replace("S+", "Shift+").replace("Spc", "Space")

func _build_bind_menu(root: Control, ui_k: float) -> void:
	bind_menu = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.035, 0.035, 0.96)
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(18)
	bind_menu.add_theme_stylebox_override("panel", sb)
	bind_menu.visible = false
	root.add_child(bind_menu)
	var v := VBoxContainer.new()
	bind_menu.add_child(v)
	v.add_child(_label("KEY BINDINGS", 24, GOLD))
	v.add_child(_label("Click a binding, then press any key or mouse button.  Esc cancels · Backspace clears.", 14, Color("cfc7b8"), false))
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 14)
	v.add_child(g)
	for h in ["Action", "Primary", "Secondary"]:
		g.add_child(_label(h, 15, GOLD))
	for a in KEYBINDS.ACTIONS:
		g.add_child(_label(a[1], 15, IVORY, false))
		var pair := []
		for slot in 2:
			var b := Button.new()
			b.custom_minimum_size = Vector2(130, 26)
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(_start_capture.bind(a[0], slot, b))
			g.add_child(b)
			pair.append(b)
		bind_buttons[a[0]] = pair
	var combine := CheckBox.new()
	combine.text = "Combine Move / Interact / Primary Attack on one button"
	combine.button_pressed = kb.combine_move_attack
	combine.toggled.connect(func(on): kb.combine_move_attack = on; kb.save_to_disk())
	v.add_child(combine)
	var row := HBoxContainer.new()
	v.add_child(row)
	var reset := Button.new()
	reset.text = "Reset to Defaults"
	reset.pressed.connect(func(): kb.reset_defaults(); combine.button_pressed = true)
	row.add_child(reset)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(toggle_bind_menu)
	row.add_child(close)
	bind_status = _label("", 14, Color("e8b85c"), false)
	v.add_child(bind_status)

var bind_status: Label

func toggle_bind_menu() -> void:
	bind_menu.visible = not bind_menu.visible
	capturing = []
	if bind_menu.visible:
		_refresh_keys()
		bind_menu.reset_size()
		var vs := get_viewport().get_visible_rect().size
		bind_menu.position = (vs - bind_menu.size) * 0.5

func _start_capture(action: String, slot: int, b: Button) -> void:
	capturing = [action, slot]
	b.text = "Press a key…"
	bind_status.text = ""

func _input(event: InputEvent) -> void:
	if capturing.is_empty() or not event.is_pressed() or event.is_echo():
		return
	if not (event is InputEventKey or event is InputEventMouseButton):
		return
	get_viewport().set_input_as_handled()
	var action: String = capturing[0]
	var slot: int = capturing[1]
	capturing = []
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		_refresh_keys()
		return
	if event is InputEventKey and event.keycode in [KEY_BACKSPACE, KEY_DELETE]:
		kb.clear(action, slot)
		return
	var spec: String = KEYBINDS.spec_from_event(event)
	var stolen: String = kb.bind(action, slot, spec)
	bind_status.text = ("%s was unbound from %s" % [_bind_text(spec), kb.label_of(stolen)]) if stolen != "" and stolen != action else ""

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

	# slot overlays: cooldown shade from the top, purple tint when mana is short
	for s in bar_slots:
		var r: Rect2 = s["rect"]
		var sk: String = skill_loadout[s["idx"]]
		var f := _cooldown_fraction(sk)
		if f > 0.0:
			overlay.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * f)), Color(0, 0, 0, 0.62))
		if _unaffordable(sk):
			overlay.draw_rect(r, Color(0.25, 0.05, 0.25, 0.45))
	for s in potion_slots:
		var r: Rect2 = s["rect"]
		var f: float = potion_cds[s["idx"]] / POTION_CD
		if f > 0.0:
			overlay.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * f)), Color(0, 0, 0, 0.62))
	# XP fill in the redrawn strip's groove
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
