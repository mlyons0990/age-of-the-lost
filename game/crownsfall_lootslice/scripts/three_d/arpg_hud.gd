extends CanvasLayer
## ARPG HUD for the 3D lab, laid out after the owner's "AOTL 2.5D LAB v0.2" mockup (2026-11-20):
## logo + lab panel (top-left), minimap + quest tracker (top-right), HP globe + potion belt (bottom-left),
## skill bar + MP globe (bottom-right), purple XP bar with level (bottom-centre), overhead nameplate with
## level badge and HP/MP bars, thin red bars over enemies. Art reused from the 2D Crownfall HUD.

const UI_SKIN := preload("res://scripts/game/ui_skin.gd")
const UI := "res://assets/ui/arpg_hud/"
const TILES := "res://assets/skill_tiles/"
const GOLD := Color("d9b46a")
const GOLD_DIM := Color("8f7444")
const IVORY := Color("efe6cf")
const PANEL_BG := Color(0.05, 0.05, 0.07, 0.78)
const LEVEL := 25

const KEYBINDS := preload("res://scripts/three_d/keybinds.gd")
const SAVE := preload("res://scripts/three_d/aotl_save.gd")   # loadouts: [loadout_<hero>] in user://aotl_save.cfg
## Skills a hero can put on the bar (click a skill well to choose, like Diablo 4 / PoE). name -> icon tile.
const HERO_SKILLS := {
	"mage": {"Bolt": "starfall_script", "Lance": "epoch_lance", "Nova": "solar_writ", "Judgment": "dawnfall"},
	"warrior": {"Slash": "slash", "Cleave": "cleave", "Dash": "charge", "Cast": "rally"},
}
## Seven skill wells, left to right: Q W E R T, LMB, RMB (owner layout; PoE-style: the LMB well holds the primary attack).
## Each well is bound to an action, so any key / mouse button can be rebound without moving the wells.
const SKILL_SLOTS := 8
## PoE layout: bottom row Q W E R T, top row LMB MMB RMB (wells 5, 6, 7). Each well is bound to an action.
const SLOT_ACTIONS := ["skill_1", "skill_2", "skill_3", "skill_4", "skill_5", "move", "skill_7", "skill_6"]
const PRIMARY_SLOT := 5
const POTION_SLOTS := 5
const DEFAULT_SKILLS := {"mage": ["Lance", "Nova", "Judgment", "", "", "Bolt", "", ""], "warrior": ["Cleave", "Dash", "Cast", "", "", "Slash", "", ""]}
## 1080p layout (scaled by screen height): slot, gap, frame border, XP bar height
const SLOT := 60.0
const GAP := 4.0
const BORDER := 7.0
const XP_H := 18.0
const FLASK := Vector2(44, 76)
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
uniform sampler2D glass_mask : filter_linear;   // exact glass pixels: the drain never darkens the statue or ring
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float inside = texture(glass_mask, UV).r;
	float y = 1.0 - UV.y;                                   // 0 at the bottom of the disc, 1 at the top
	float empty = smoothstep(fill - 0.012, fill + 0.02, y); // spent part, above the liquid surface
	float meniscus = exp(-pow((y - fill) * 45.0, 2.0)) * step(0.01, fill) * step(fill, 0.99);
	vec3 col = mix(vec3(0.015, 0.015, 0.03), vec3(1.0, 0.96, 0.9), meniscus);
	COLOR = vec4(col, max(0.82 * empty, 0.16 * meniscus) * inside);
}
"""
var hp_shade: ColorRect
var meta_cache: Dictionary
var frame_poly: PackedVector2Array
var boss_points: Array = []
var frame_body: Control
var mouse_glyphs := {}
var xp_tex: Texture2D
var xp_tile_w := 120.0
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
var lab_panel: Control
var minimap_tex_rect: TextureRect
var minimap_overview: Texture2D      # painted zones: minimap drawn from the zone painting (blueprint UI-09)
const MINIMAP_SPAN_PX := 900.0       # painting px shown top-to-bottom in the minimap
var minimap_cam: Camera3D
var minimap_rect: Rect2
var area_title: Label
var area_sub: Label
var branding: Array = []             # top-left logo (lab only; the playable game hides it)

## The playable game has no logo over the play field.
func set_branding(on: bool) -> void:
	for n in branding: n.visible = on

## Minimap header follows the painted zone ("Region — Place" from the zone JSON name).
func _on_zone_changed(_to: String) -> void:
	minimap_overview = load("res://assets/zones/" + String(lab.zone["overview"])) if lab.zone.has("overview") else null
	if minimap_tex_rect != null:
		minimap_tex_rect.visible = minimap_overview == null
		minimap_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED if minimap_overview != null else SubViewport.UPDATE_ALWAYS
	var nm: String = String(lab.zone.get("name", "Crownsfall — Central Plaza"))
	var parts := nm.split(" — ")
	area_title.text = parts[0]
	area_sub.text = parts[1] if parts.size() > 1 else ""
	if lab.get("game") != null:       # playable game: just the zone's name (levels live on the world map)
		area_sub.text = ""
var xp_rect: Rect2
var quest_progress := 0

const WORLD_MAP := preload("res://scripts/three_d/world_map.gd")
var world_map                       # full-screen zone / world map (M)

func setup(owner_lab: Node3D) -> void:
	lab = owner_lab
	player = lab.player
	layer = 5
	font = load("res://assets/fonts/LiberationSerif-Bold.ttf")
	font_regular = load("res://assets/fonts/LiberationSerif-Regular.ttf")
	hero = "mage" if player.is_pilot_mage() else "warrior"
	player.number_keys_for_skills = false
	player.click_to_move = true
	lab.get_viewport().msaa_2d = Viewport.MSAA_4X      # smooth (anti-aliased) curved frame edges
	player.primary_skill_provider = primary_skill
	kb = KEYBINDS.new()
	kb.changed_listeners.append(_refresh_keys)
	_load_loadout()
	_build()
	var map_layer := CanvasLayer.new()          # above every HUD layer (slot keys, minimap, panels)
	map_layer.layer = 40
	map_layer.name = "MapLayer"
	add_child(map_layer)
	world_map = WORLD_MAP.new()
	world_map.name = "WorldMap"
	map_layer.add_child(world_map)
	world_map.setup(lab, self)
	refresh_quests()
	_refresh_slots()
	_refresh_keys()

var quest_panel: Panel
var quest_box: VBoxContainer

## Quest tracker under the minimap: the character's active quests (game) or the lab's sample quests.
func refresh_quests() -> void:
	if quest_box == null: return
	for c in quest_box.get_children(): c.queue_free()
	var qs: Array = world_map.active_quests() if world_map != null else []
	for q in qs:
		var ql := _label("◆  " + String(q["name"]), 17, Color("e8b85c"))
		ql.name = "Quest_" + String(q["name"]).replace(" ", "")
		quest_box.add_child(ql)
		var obj := String(q["objective"]) + ((" (%d/%d)" % [int(q["progress"]), int(q["count"])]) if int(q.get("count", 0)) > 0 else "")
		var ol := _label("     ☐  " + obj, 14, Color("cfc7b8"), false)
		ol.name = "Objective_" + String(q["name"]).replace(" ", "")
		ol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ol.custom_minimum_size = Vector2(300, 0)
		quest_box.add_child(ol)
	if quest_panel != null:
		quest_panel.visible = not qs.is_empty()
		quest_panel.size.y = 14 + 44 * qs.size()

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
	branding = [logo, sub]
	# lab/debug panel (blueprint CAM-06): one container, hidden by default, toggled by the rebindable "lab_panel"
	# action (F3), and never shown in release builds
	lab_panel = Control.new()
	lab_panel.name = "LabPanel"
	lab_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lab_panel)
	lab_panel.visible = OS.is_debug_build() and bool(SAVE.open().get_value("settings", "lab_panel", false))
	var hero_name: String = "Mage (Meshy pilot)" if player.is_pilot_mage() else "Warrior (Meshy pilot)"
	var rows := [["AOTL 3D LAB (v0.3)", true], ["3D Scene: Active", false], ["Camera: Isometric (PoE Scale)", false],
		["Character: " + hero_name, false], ["Animation Set: %d clips" % player.animation.get_animation_list().size(), false],
		["Environment: Combat lab (alpha)", false]]
	var controls := [["LMB", "Move / Attack (hold)"], ["Shift + LMB", "Attack in place"], ["Skill bar", "Skills (click a slot to swap)"],
		["Belt", "Potions (click a slot to swap)"], ["Space", "Dodge Roll"], ["F1", "Key Bindings (rebind anything)"], ["F3", "Show / hide this panel"], ["F7", "Return to 2D plaza"]]
	var ph := 34.0 + rows.size() * 24.0 + 30.0 + controls.size() * 24.0
	lab_panel.add_child(_panel(Rect2(14, 92, 360, ph)))
	var y := 100.0
	for i in rows.size():
		var r: Array = rows[i]
		var l := _label(("" if r[1] else "☑  ") + r[0], 17 if r[1] else 15, GOLD if r[1] else IVORY, r[1])
		l.position = Vector2(26, y)
		lab_panel.add_child(l)
		y += 24.0 + (6.0 if r[1] else 0.0)
	var c := _label("▾  Controls", 15, GOLD)
	c.position = Vector2(26, y + 4)
	lab_panel.add_child(c)
	y += 30.0
	for k in controls:
		var kl := _label(k[0], 13, IVORY)
		kl.position = Vector2(34, y + 2)
		lab_panel.add_child(kl)
		var vl := _label(k[1], 15, IVORY, false)
		vl.position = Vector2(150, y)
		lab_panel.add_child(vl)
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
	minimap_tex_rect = mm
	area_title = _label("Crownsfall", 19, IVORY)
	area_title.position = minimap_rect.position + Vector2(10, 6)
	root.add_child(area_title)
	area_sub = _label("Central Plaza", 14, IVORY, false)
	area_sub.position = minimap_rect.position + Vector2(10, 28)
	root.add_child(area_sub)
	if "zone" in lab:
		_on_zone_changed("")
		lab.zone_changed.connect(_on_zone_changed)
	var qy := minimap_rect.end.y + 12
	quest_panel = _panel(Rect2(W - 334, qy, 320, 118), 0.62)
	root.add_child(quest_panel)
	quest_box = VBoxContainer.new()
	quest_box.position = Vector2(W - 322, qy + 6)
	quest_box.size = Vector2(300, 100)
	quest_box.add_theme_constant_override("separation", 1)
	quest_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(quest_box)
	refresh_quests()
	# --- bottom, PoE layout: painted statue + globe in each corner; between them, procedurally drawn bronze frames
	# (exact straight bevels): a flask belt beside the life globe, a two-row skill block beside the mana globe
	# (LMB MMB RMB over Q W E R T), and a thin XP bar along the bottom edge. Nothing overlaps; icons fill their wells.
	var CM: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(UI + "hud2.json"))
	meta_cache = CM
	var vs: Vector2 = lab.get_viewport().get_visible_rect().size
	W = vs.x
	H = vs.y
	var f: float = H / 1080.0
	var hi := f > 1.05
	var cl: Dictionary = CM["left"]
	var cr: Dictionary = CM["right"]
	var lsz := Vector2(cl["size"][0], cl["size"][1]) * f
	var rsz := Vector2(cr["size"][0], cr["size"][1]) * f
	left_piece = _piece("hud2_corner_left@2x" if hi else "hud2_corner_left", Rect2(0, H - lsz.y, lsz.x, lsz.y))
	right_piece = _piece("hud2_corner_right@2x" if hi else "hud2_corner_right", Rect2(W - rsz.x, H - rsz.y, rsz.x, rsz.y))
	var lo := left_piece.position
	var ro := right_piece.position
	var dl: Array = cl["disc"]
	var dr: Array = cr["disc"]
	# HUD v2 (owner-approved Higgsfield art). Every element is placed against the corner art's measured silhouette
	# (hud2.json "edge" per row), so nothing overlaps the globes and nothing leaves a gap:
	#   rail (with XP groove) spans the full screen width along the bottom, under everything
	#   flask belt butts against the HP globe art; stepped skill block (LMB MMB RMB over Q W E R T) against the mana art
	#   frames stand on the rail (their bottoms tuck under its top trim); corners drawn over the rail; slots last.
	var RL: Dictionary = CM["rail"]
	var FR: Dictionary = CM["frame"]
	var s_slot := SLOT * f
	var s_gap := GAP * f
	var fb: float = float(FR["border"]) * f + 2.0 * f
	var fl := FLASK * f
	var rail_h: float = float(RL["height"]) * f
	var by0: float = H - rail_h
	var stand: float = by0 + 10.0 * f
	var pad: float = 4.0 * f
	var edge_l := func(y0: float, y1: float) -> float:       # rightmost x of the HP art over screen rows y0..y1
		var e: Array = cl["edge"]; var best := 0.0
		for yy in range(int(y0), int(y1) + 1):
			var k: int = int((yy - lo.y) / f)
			if k >= 0 and k < e.size(): best = maxf(best, lo.x + float(e[k]) * f)
		return best
	var edge_r := func(y0: float, y1: float) -> float:       # leftmost x of the mana art over screen rows y0..y1
		var e: Array = cr["edge"]; var best := W
		for yy in range(int(y0), int(y1) + 1):
			var k: int = int((yy - ro.y) / f)
			if k >= 0 and k < e.size(): best = minf(best, ro.x + float(e[k]) * f)
		return best
	# flask belt
	var belt_h: float = fl.y + 2 * fb
	var belt_x0: float = edge_l.call(stand - belt_h, stand) + pad
	var belt := Rect2(belt_x0, stand - belt_h, 5 * fl.x + 4 * s_gap + 2 * fb, belt_h)
	# skill block
	var low_h: float = s_slot + 2 * fb
	var top_h: float = s_slot + 2 * fb
	var low_w: float = 5 * s_slot + 4 * s_gap + 2 * fb
	var blk_top: float = stand - low_h - (s_slot + s_gap)
	var blk_x1: float = edge_r.call(blk_top, stand) - pad
	var low := Rect2(blk_x1 - low_w, stand - low_h, low_w, low_h)
	var top_x: float = low.position.x + 2 * (s_slot + s_gap)
	var top := Rect2(top_x, blk_top, blk_x1 - top_x, top_h)
	# frames reach behind the globe rings (drawn before the corners, so the ring covers their ends): the wedge where
	# a ring curves away above the rail is filled with frame art instead of empty space. Slots stay outside the rings.
	var disc_lx: float = lo.x + float(dl[0]) * f
	var disc_rx: float = ro.x + float(dr[0]) * f
	root.add_child(_frame9(Rect2(low.position, Vector2(disc_rx - low.position.x, low.size.y)), hi, f))
	root.add_child(_frame9(Rect2(top.position, Vector2(disc_rx - top.position.x, top.size.y)), hi, f))
	root.add_child(_frame9(Rect2(Vector2(disc_lx, belt.position.y), Vector2(belt.end.x - disc_lx, belt.size.y)), hi, f))
	# the frame interior between each globe ring and its panel: bronze filigree panelling (the frame's own border art,
	# tiled) instead of plain stone. Drawn before the corners, so the ring overlaps its outer end.
	var pil_tex: Texture2D = _tex("hud2_pilaster@2x" if hi else "hud2_pilaster")
	for zone in [Rect2(Vector2(disc_lx, belt.position.y + fb), Vector2(belt.position.x + fb - 2 * f - disc_lx, belt.size.y - 2 * fb)),
			Rect2(Vector2(low.end.x - fb + 2 * f, low.position.y + fb), Vector2(disc_rx - (low.end.x - fb + 2 * f), low.size.y - 2 * fb)),
			Rect2(Vector2(top.end.x - fb + 2 * f, top.position.y + fb), Vector2(disc_rx - (top.end.x - fb + 2 * f), top.size.y - fb))]:
		var pz := TextureRect.new()
		pz.texture = pil_tex
		pz.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pz.stretch_mode = TextureRect.STRETCH_TILE
		pz.position = zone.position
		pz.size = zone.size * (2.0 if hi else 1.0)
		if hi: pz.scale = Vector2(0.5, 0.5)
		pz.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(pz)
	var cb: Array = CM["cap_belt"]["size"]
	var cs2: Array = CM["cap_skill"]["size"]
	root.add_child(_piece("hud2_cap_belt@2x" if hi else "hud2_cap_belt", Rect2(belt.end.x - 8 * f, stand - float(cb[1]) * f, float(cb[0]) * f, float(cb[1]) * f)))
	root.add_child(_piece("hud2_cap_skill@2x" if hi else "hud2_cap_skill", Rect2(low.position.x - float(cs2[0]) * f + 8 * f, stand - float(cs2[1]) * f, float(cs2[0]) * f, float(cs2[1]) * f)))
	# rail across the whole bottom (covers the frames' bottom edges and fills under both globes)
	var rail := TextureRect.new()
	rail.texture = _tex("hud2_rail@2x" if hi else "hud2_rail")
	rail.stretch_mode = TextureRect.STRETCH_TILE
	rail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rail.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	rail.position = Vector2(0, by0)
	rail.size = Vector2(W, rail_h)
	if hi:
		rail.scale = Vector2(0.5, 0.5); rail.size *= 2.0
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rail)
	strip_rect = Rect2(0, by0, W, rail_h)
	frame_poly = PackedVector2Array([belt.position, belt.end, low.position, low.end, top.position, top.end,
		Vector2(0, by0), Vector2(W, by0), Vector2(0, H), Vector2(W, H), Vector2(0, by0), Vector2(W, by0)])
	root.add_child(left_piece)
	root.add_child(right_piece)
	# XP fill: in the groove, only where the groove is visible between the two corner pieces
	var gr: Array = RL["groove"]
	var gy0: float = by0 + float(gr[0]) * f
	var gy1: float = gy0 + float(gr[1]) * f
	var xl: float = edge_l.call(gy0, gy1) + 3 * f
	var xr: float = edge_r.call(gy0, gy1) - 3 * f
	xp_rect = Rect2(xl, gy0 + 1 * f, xr - xl, gy1 - gy0 - 2 * f)
	orb_l = Vector3(lo.x + dl[0] * f, lo.y + dl[1] * f, dl[2] * f)
	orb_r = Vector3(ro.x + dr[0] * f, ro.y + dr[1] * f, dr[2] * f)
	hp_shade = _disc_shade(root, lo, f, dl)
	mp_shade = _disc_shade(root, ro, f, dr)
	(hp_shade.material as ShaderMaterial).set_shader_parameter("glass_mask", _tex("hud2_glass_left"))
	(mp_shade.material as ShaderMaterial).set_shader_parameter("glass_mask", _tex("hud2_glass_right"))
	var sk_m: float = float(CM["socket_skill"]["margin"])
	var po_m: float = float(CM["socket_potion"]["margin"])
	for i in POTION_SLOTS:
		var r := Rect2(Vector2(belt.position.x + fb + i * (fl.x + s_gap), belt.position.y + fb), fl)
		root.add_child(_socket9("hud2_socket_potion", r, po_m, hi))
		potion_slots.append({"rect": r, "idx": i})
		potion_icons.append(_well(root, r, "potion", i, (po_m * 0.55) * f / r.size.x))
		key_labels["potion_%d" % (i + 1)] = _corner_key(root, r.grow(-po_m * 0.5 * f), f)
	for i in SKILL_SLOTS:
		var r: Rect2
		if i < 5:
			r = Rect2(Vector2(low.position.x + fb + i * (s_slot + s_gap), low.position.y + fb), Vector2(s_slot, s_slot))
		else:
			r = Rect2(Vector2(low.position.x + fb + (i - 3) * (s_slot + s_gap), top.position.y + fb), Vector2(s_slot, s_slot))
		root.add_child(_socket9("hud2_socket_skill", r, sk_m, hi))
		bar_slots.append({"rect": r, "idx": i})
		skill_icons.append(_well(root, r, "skill", i, (sk_m * 0.7) * f / r.size.x))
		key_labels[SLOT_ACTIONS[i]] = _corner_key(root, r.grow(-sk_m * 0.4 * f), f)
		if i >= 5:
			mouse_glyphs[SLOT_ACTIONS[i]] = _mouse_glyph(root, r.grow(-sk_m * 0.4 * f), f)
	# HP / MP values above their globe art (never over it)
	hp_label = _label("HP", int(18 * f), IVORY)
	hp_label.size = Vector2(220, 24) * f
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var label_y: float = minf(lo.y, ro.y) - 28 * f          # one shared line for HP and MP
	hp_label.position = Vector2(orb_l.x - 110 * f, label_y)
	root.add_child(hp_label)
	mp_label = _label("MP", int(18 * f), IVORY)
	mp_label.size = Vector2(220, 24) * f
	mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mp_label.position = Vector2(orb_r.x - 110 * f, label_y)
	root.add_child(mp_label)
	var lv := _label("Lv. %d" % hero_level(), int(12 * f), IVORY)
	level_label = lv
	lv.size = Vector2(120 * f, xp_rect.size.y + 4 * f)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lv.position = Vector2(xp_rect.get_center().x - 60 * f, xp_rect.position.y - 2 * f)
	lv.z_index = 2
	root.add_child(lv)
	picker = PopupMenu.new()
	picker.id_pressed.connect(_on_pick)
	add_child(picker)
	_build_bind_menu(root, f)
	# world-anchored layer + dynamic overlays
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_overlay)
	root.add_child(overlay)
	# zone name centred on the top of the minimap, black-outlined: children of the overlay draw after the painted
	# minimap it draws
	for l in [area_title, area_sub]:
		l.reparent(overlay, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size.x = minimap_rect.size.x
		l.position.x = minimap_rect.position.x
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 7)
	area_title.add_theme_font_size_override("font_size", 21)
	area_title.add_theme_color_override("font_color", Color("f3e7c4"))
	area_title.position.y = minimap_rect.position.y + 4
	area_sub.position.y = minimap_rect.position.y + 30
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

## Fillet every corner of the frame outline (convex and concave) with a smooth arc, PoE-style; screen-edge
## vertices below the bottom of the screen stay square.
static func _rounded(poly: PackedVector2Array, rad: float, h: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var p: Vector2 = poly[i]
		if p.y >= h:
			out.append(p)
			continue
		var a: Vector2 = poly[(i - 1 + n) % n]
		var b: Vector2 = poly[(i + 1) % n]
		var ra: float = minf(rad, a.distance_to(p) * 0.5)
		var rb: float = minf(rad, b.distance_to(p) * 0.5)
		var p0: Vector2 = p + (a - p).normalized() * ra
		var p1: Vector2 = p + (b - p).normalized() * rb
		for k in 17:
			var t: float = k / 16.0
			out.append(p0.lerp(p, t).lerp(p.lerp(p1, t), t))     # smooth fillet through the corner
	return out

## Small bronze boss with a gold stud at each raised corner (artwork accents on the frame).
func _boss(ctrl: Control, at: Vector2, f: float) -> void:
	ctrl.draw_circle(at, 7.5 * f, Color("0b0909"))
	ctrl.draw_circle(at, 6.5 * f, Color("8a6a46"))
	ctrl.draw_circle(at, 4.2 * f, Color("5a4330"))
	ctrl.draw_circle(at + Vector2(-0.8, -0.8) * f, 2.6 * f, Color("e8c27c"))

func _frame9(r: Rect2, hi: bool, f: float) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = _tex("hud2_frame@2x" if hi else "hud2_frame")
	n.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT     # ornaments repeat, never stretch
	n.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	var m: int = roundi(float(meta_cache["frame"]["margin"]) * (2.0 if hi else 1.0))
	n.patch_margin_left = m; n.patch_margin_right = m; n.patch_margin_top = m; n.patch_margin_bottom = m
	n.position = r.position
	n.size = r.size / (2.0 if hi else 1.0) * (1.0 if not hi else 1.0)
	if hi:
		n.size = r.size * 2.0
		n.scale = Vector2(0.5, 0.5)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n

func _socket9(tex: String, r: Rect2, margin: float, hi: bool) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = _tex(tex + ("@2x" if hi else ""))
	var m: int = roundi(margin * (2.0 if hi else 1.0))
	n.patch_margin_left = m; n.patch_margin_right = m; n.patch_margin_top = m; n.patch_margin_bottom = m
	n.position = r.position
	n.size = r.size * (2.0 if hi else 1.0)
	if hi: n.scale = Vector2(0.5, 0.5)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n

func _nine(name: String, r: Rect2, margin: int, hi: bool) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = _tex(name + ("@2x" if hi else ""))
	var m: int = margin * (2 if hi else 1)
	n.patch_margin_left = m; n.patch_margin_right = m; n.patch_margin_top = m; n.patch_margin_bottom = m
	n.position = r.position
	n.size = r.size
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n

## PoE-style mouse symbol for LMB / MMB / RMB slots: a small mouse with the bound button lit.
func _mouse_glyph(root: Control, r: Rect2, f: float) -> Control:
	var g := Control.new()
	g.size = Vector2(20, 28) * f
	g.position = Vector2(r.position.x + 2 * f, r.end.y - g.size.y - 2 * f)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.z_index = 3
	g.set_meta("button", 0)
	g.draw.connect(func():
		# mouse silhouette: rounded capsule; the bound button (whole left / right half of the top, or the wheel) lit gold
		var w: float = g.size.x; var h: float = g.size.y
		var rad: float = w * 0.5
		var c := Vector2(w * 0.5, rad)
		var body := PackedVector2Array()
		for k in 21: body.append(c + Vector2(cos(PI + PI * k / 20.0), sin(PI + PI * k / 20.0)) * (rad - 1))
		body.append(Vector2(w - 1, h - rad * 0.6)); body.append(Vector2(w * 0.5, h - 1)); body.append(Vector2(1, h - rad * 0.6))
		var split_y: float = h * 0.46
		g.draw_colored_polygon(body, Color(0.07, 0.06, 0.06, 0.92))
		var btn: int = int(g.get_meta("button"))
		var gold := Color("f2c45a")
		if btn == 1 or btn == 3:
			var half := PackedVector2Array()
			var a0: float = PI if btn == 1 else PI * 1.5
			for k in 11: half.append(c + Vector2(cos(a0 + PI * 0.5 * k / 10.0), sin(a0 + PI * 0.5 * k / 10.0)) * (rad - 2.2 * f))
			if btn == 1:
				half.append(Vector2(w * 0.5 - 0.8 * f, split_y - 1.2 * f)); half.append(Vector2(2.2 * f, split_y - 1.2 * f))
			else:
				half.append(Vector2(w - 2.2 * f, split_y - 1.2 * f)); half.append(Vector2(w * 0.5 + 0.8 * f, split_y - 1.2 * f))
			g.draw_colored_polygon(half, gold)
		elif btn == 2:
			g.draw_rect(Rect2(Vector2(w * 0.5 - 2.4 * f, 4 * f), Vector2(4.8 * f, split_y - 6 * f)), gold)
		var closed := body.duplicate(); closed.append(body[0])
		g.draw_polyline(closed, Color("efe6cf"), 1.5 * f, true)
		g.draw_line(Vector2(1.5 * f, split_y), Vector2(w - 1.5 * f, split_y), Color("efe6cf"), 1.3 * f, true)
		if btn != 2:
			g.draw_line(Vector2(w * 0.5, 1.5 * f), Vector2(w * 0.5, split_y), Color("efe6cf"), 1.3 * f, true)
		)
	root.add_child(g)
	return g

## Key letter in the icon's bottom-left corner (PoE style), outlined so it reads over any icon.
func _corner_key(root: Control, r: Rect2, f: float) -> Label:
	var l := _label("", int(14 * f), IVORY)
	l.add_theme_constant_override("outline_size", maxi(3, roundi(5 * f)))
	l.position = r.position + Vector2(4, r.size.y - 20 * f)
	l.size = Vector2(r.size.x - 6 * f, 18 * f)
	l.clip_text = true
	l.z_index = 3
	root.add_child(l)
	return l

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
	var rim: float = 0.0
	var inset := r.size * inset_frac + Vector2(rim, rim)
	t.position = inset
	t.size = r.size - inset * 2.0
	t.stretch_mode = TextureRect.STRETCH_SCALE if kind == "skill" else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(t)
	return t

func _draw_plate(root: Control, r: Rect2, f: float) -> void:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.085, 0.095, 1.0)
	sb.border_color = Color(0.55, 0.41, 0.29, 1.0)
	sb.set_border_width_all(maxi(1, roundi(1.5 * f)))
	sb.set_corner_radius_all(roundi(3 * f))
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = roundi(2 * f)
	p.add_theme_stylebox_override("panel", sb)
	p.position = r.position + Vector2(2, 2) * f
	p.size = r.size - Vector2(4, 4) * f
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(p)

func _plate_label(root: Control, r: Rect2, ui_k: float) -> Label:
	var l := _label("", int(15 * ui_k), IVORY)
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	root.add_child(l)
	return l

const GAME_SKILLS := preload("res://scripts/game/skills.gd")
func _in_game() -> bool:
	return lab.get("game") != null

## The game: the bar holds the character's learned skills (saved with the character).
func reload_bar() -> void:
	if not _in_game(): return
	skill_loadout = lab.game_state.bar.duplicate()
	_refresh_slots()

func _skill_icon(sk: String) -> Texture2D:
	if sk == "": return null
	if _in_game():
		var d: Dictionary = GAME_SKILLS.def(lab.game_state.class_id, sk)
		return d.get("icon_texture") if not d.is_empty() else null
	return load(TILES + HERO_SKILLS[hero][sk] + ".png")

func _refresh_slots() -> void:
	for i in SKILL_SLOTS:
		var sk: String = skill_loadout[i]
		skill_icons[i].texture = _skill_icon(sk)
	for i in POTION_SLOTS:
		var pt: String = potion_loadout[i]
		potion_icons[i].texture = _tex(POTION_TYPES[pt]["tex"]) if pt != "" else null

func _refresh_keys() -> void:
	for a in key_labels.keys():
		var t: String = kb.key_label(a)
		var btn: int = {"LMB": 1, "MMB": 2, "RMB": 3}.get(t, 0)
		if mouse_glyphs.has(a):
			mouse_glyphs[a].visible = btn != 0
			mouse_glyphs[a].set_meta("button", btn)
			mouse_glyphs[a].queue_redraw()
		key_labels[a].text = "" if (btn != 0 and mouse_glyphs.has(a)) else t
	if bind_menu != null:
		for a in bind_buttons.keys():
			for i in 2:
				bind_buttons[a][i].text = _bind_text(kb.binds[a][i])

func _open_picker(kind: String, idx: int) -> void:
	picker.clear()
	picker_target = [kind, idx]
	var names: Array = _skill_names() if kind == "skill" else POTION_TYPES.keys()
	for n in names.size():
		var label := String(names[n]).capitalize()
		if kind == "skill" and _in_game(): label = String(GAME_SKILLS.def(lab.game_state.class_id, names[n])["name"])
		picker.add_item(label, n)
	picker.add_separator()
	picker.add_item("(Empty)", 99)
	picker.position = Vector2i(get_viewport().get_mouse_position()) - Vector2i(0, 40 + 24 * names.size())
	picker.popup()

func _on_pick(id: int) -> void:
	var kind: String = picker_target[0]
	var names: Array = _skill_names() if kind == "skill" else POTION_TYPES.keys()
	assign(kind, picker_target[1], "" if id == 99 else String(names[id]))

func _skill_names() -> Array:
	if _in_game():
		var out := []
		for d in GAME_SKILLS.defs(lab.game_state.class_id):
			if lab.game_state.rank(d["id"]) > 0: out.append(d["id"])
		for id in lab.game_state.skills:          # lorecasts learned at lorecast sites, usable by every class
			if not id in out and not GAME_SKILLS.lore_def(String(id)).is_empty(): out.append(String(id))
		return out
	return HERO_SKILLS[hero].keys()

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
	var cf: ConfigFile = SAVE.open()
	if cf.has_section("loadout_" + hero):
		var s: Array = cf.get_value("loadout_" + hero, "skills", skill_loadout)
		var p: Array = cf.get_value("loadout_" + hero, "potions", potion_loadout)
		if s.size() != SKILL_SLOTS:
			s = DEFAULT_SKILLS[hero].duplicate()     # older bar layouts reset to the new default
		if s.size() == SKILL_SLOTS and s.all(func(x): return x == "" or HERO_SKILLS[hero].has(x)): skill_loadout = s
		if p.size() == 5 and p.all(func(x): return x == "" or POTION_TYPES.has(x)): potion_loadout = p

func _save_loadout() -> void:
	if _in_game():
		lab.game_state.bar = skill_loadout.duplicate()
		var cfp: ConfigFile = SAVE.open()
		cfp.set_value("loadout_game", "potions", potion_loadout)
		SAVE.commit(cfp)
		return
	var cf: ConfigFile = SAVE.open()
	cf.set_value("loadout_" + hero, "skills", skill_loadout)
	cf.set_value("loadout_" + hero, "potions", potion_loadout)
	SAVE.commit(cf)

func toggle_lab_panel() -> void:
	if not OS.is_debug_build():
		lab_panel.visible = false
		return
	lab_panel.visible = not lab_panel.visible
	var cf: ConfigFile = SAVE.open()
	cf.set_value("settings", "lab_panel", lab_panel.visible)
	SAVE.commit(cf)

## True while the mouse is over a HUD well or the bindings menu (clicks there must not walk the hero).
func pointer_over_ui() -> bool:
	var m := get_viewport().get_mouse_position()
	if bind_menu.visible and Rect2(bind_menu.position, bind_menu.size).has_point(m):
		return true
	for s in bar_slots + potion_slots:
		if (s["rect"] as Rect2).has_point(m):
			return true
	if lab.get("game") != null and (lab.game.ui.over_ui(m) or lab.game.dead): return true
	if world_map != null and world_map.visible: return true
	return false

# ---------------- actions ----------------

func use_skill_slot(i: int) -> void:
	var sk: String = skill_loadout[i]
	if sk != "" and _in_game():
		lab.game.use_skill(sk)
	elif sk != "":
		player.use_skill(sk)

var level_label: Label
func hero_level() -> int:
	return lab.game_state.level if lab.get("game_state") != null else LEVEL

func hero_name() -> String:
	return lab.game_state.hero_name if lab.get("game_state") != null else "Wayfarer"

## The skill in the LMB well drives the click-an-enemy primary attack.
func primary_skill() -> String:
	return skill_loadout[PRIMARY_SLOT]

## Drink potion slot `i` (0-4). Returns true if it restored anything.
func drink(i: int) -> bool:
	var pt: String = potion_loadout[i]
	if pt == "" or potion_cds[i] > 0.0:
		return false
	if lab.get("game") != null:
		if lab.game.dead: return false
		if (pt == "health" and player.hp >= player.max_hp) or (pt == "mana" and player.mana >= player.max_mana): return false
		if not lab.game.use_potion(pt): return false
	var ok: bool = player.restore(POTION_TYPES[pt]["hp"] * (1.0 + 0.12 * (hero_level() - 1)), POTION_TYPES[pt]["mp"] * (1.0 + 0.08 * (hero_level() - 1)))
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
	if lab.get("game") != null and (lab.game.dead or lab.game.ui.panel_kind in ["pause", "death", "epilogue"]) and a != "keybinds":
		return
	if a == "inventory" and lab.get("game") != null:
		lab.game.ui.toggle_inventory()
		get_viewport().set_input_as_handled()
		return
	if a == "character" and lab.get("game") != null:
		lab.game.ui.toggle_character()
		get_viewport().set_input_as_handled()
		return
	if a == "skills" and lab.get("game") != null:
		lab.game.ui.toggle_skills()
		get_viewport().set_input_as_handled()
		return
	if a.begins_with("skill_"):
		use_skill_slot(SLOT_ACTIONS.find(a))
	elif a.begins_with("potion_"):
		drink(int(a.substr(7)) - 1)
	elif a == "dodge":
		player.dodge_toward_aim()
	elif a == "lab_panel":
		toggle_lab_panel()
	elif a == "map":
		world_map.toggle()
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
	# painted AOTL kit frame (scripts/game/ui_skin.gd), like every other game screen
	bind_menu = PanelContainer.new()
	bind_menu.add_theme_stylebox_override("panel", UI_SKIN.panel_box(10.0))
	bind_menu.visible = false
	root.add_child(bind_menu)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	bind_menu.add_child(v)
	var head := UI_SKIN.plaque("KEY BINDINGS", 330.0, 23)
	var hc := CenterContainer.new(); hc.custom_minimum_size = head.custom_minimum_size; hc.add_child(head)
	v.add_child(hc)
	v.add_child(_label("Click a binding, then press any key or mouse button.  Esc cancels · Backspace clears.", 15, Color("cfc7b8"), false))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI_SKIN.style_scroll(scroll)
	v.add_child(scroll)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 4)
	scroll.add_child(g)
	for h in ["Action", "Primary", "Secondary"]:
		g.add_child(_label(h, 16, GOLD))
	for a in KEYBINDS.ACTIONS:
		var l := _label(a[1], 16, IVORY, false)
		l.custom_minimum_size = Vector2(300, 0)
		g.add_child(l)
		var pair := []
		for slot in 2:
			var b: Button = UI_SKIN.button("", 170.0, 38.0, 15)
			b.pressed.connect(_start_capture.bind(a[0], slot, b))
			g.add_child(b)
			pair.append(b)
		bind_buttons[a[0]] = pair
	var combine: CheckBox = UI_SKIN.checkbox("Combine Move / Interact / Primary Attack on one button")
	combine.button_pressed = kb.combine_move_attack
	combine.toggled.connect(func(on): kb.combine_move_attack = on; kb.save_to_disk())
	v.add_child(combine)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var reset: Button = UI_SKIN.button("Reset to Defaults", 260.0, 48.0, 18)
	reset.pressed.connect(func(): kb.reset_defaults(); combine.button_pressed = true)
	row.add_child(reset)
	var close: Button = UI_SKIN.button("Close", 260.0, 48.0, 18)
	close.pressed.connect(toggle_bind_menu)
	row.add_child(close)
	bind_status = _label("", 15, Color("e8b85c"), false)
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
	if world_map != null: world_map.tick(delta)
	if lab.get("game") == null:
		var q := mini(3, lab.kills)
		if q != quest_progress:
			quest_progress = q
			refresh_quests()
	if level_label != null: level_label.text = "Lv. %d" % hero_level()
	overlay.queue_redraw()
	world_overlay.queue_redraw()

func _cooldown_fraction(spell: String) -> float:
	if spell == "":
		return 0.0
	if _in_game(): return lab.game.skill_cd_frac(spell)
	if player.is_pilot_mage() and player.MAGE_SPELLS.has(spell):
		var cd: float = player.MAGE_SPELLS[spell]["cd"]
		return clampf(float(player.spell_cds.get(spell, 0.0)) / cd, 0.0, 1.0) if cd > 0.0 else 0.0
	if spell == "Cast":
		return clampf(player.spell_cd / 3.5, 0.0, 1.0)
	return 0.0

func _unaffordable(spell: String) -> bool:
	if _in_game(): return spell != "" and not lab.game.skill_affordable(spell)
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
		var pt: String = potion_loadout[s["idx"]]
		if lab.get("game_state") != null and pt != "":
			var n: int = int(lab.game_state.potions.get(pt, 0))
			if n <= 0: overlay.draw_rect(r, Color(0, 0, 0, 0.55))
			var at := r.position + Vector2(r.size.x - 6, 18)
			overlay.draw_string_outline(font, at, str(n), HORIZONTAL_ALIGNMENT_RIGHT, -1, 16, 4, Color(0, 0, 0, 0.95))
			overlay.draw_string(font, at, str(n), HORIZONTAL_ALIGNMENT_RIGHT, -1, 16, IVORY if n > 0 else Color("ff7a6a"))
	# XP fill inside the thin channel
	var xp_frac := fposmod(0.42 + lab.kills * 0.07, 1.0)
	if lab.get("game_state") != null: xp_frac = clampf(float(lab.game_state.xp) / float(lab.game_state.xp_need()), 0.0, 1.0)
	var fw: float = xp_rect.size.x * xp_frac
	overlay.draw_rect(Rect2(xp_rect.position, Vector2(fw, xp_rect.size.y)), Color("6d35b8"))
	overlay.draw_rect(Rect2(xp_rect.position, Vector2(fw, xp_rect.size.y * 0.5)), Color("8c55dc"))
	overlay.draw_rect(Rect2(xp_rect.position, Vector2(fw, maxf(1.0, xp_rect.size.y * 0.18))), Color("c9a8ff"))
	if fw > 2.0:
		overlay.draw_rect(Rect2(xp_rect.position + Vector2(fw - 2.0, 0), Vector2(2.0, xp_rect.size.y)), Color("e8dcff"))
	# minimap frame + markers
	if minimap_overview != null:
		_draw_zone_minimap()
		return
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

## Painted-zone minimap: the zone painting around the hero (kept inside the zone, no black margins), a faint walkable
## outline, discovered waypoints, exit portals, enemies and the hero. Everything is placed from the same zone data the
## game uses, so the map always matches where you can walk.
func _draw_zone_minimap() -> void:
	var sz: Array = lab.zone["size"]
	var zw := float(sz[0]); var zh := float(sz[1])
	var span := Vector2(MINIMAP_SPAN_PX * minimap_rect.size.x / minimap_rect.size.y, MINIMAP_SPAN_PX)
	span = span.min(Vector2(zw, zh))
	var me: Vector2 = lab.zone_world_to_px(player.global_position)
	var win := Rect2(me - span * 0.5, span)
	win.position = win.position.clamp(Vector2.ZERO, Vector2(zw, zh) - span)
	var k := minimap_rect.size / span
	var to_map := func(px: Vector2) -> Vector2: return minimap_rect.position + (px - win.position) * k
	var ov_scale := Vector2(minimap_overview.get_width(), minimap_overview.get_height()) / Vector2(zw, zh)
	overlay.draw_rect(minimap_rect, Color(0.05, 0.04, 0.05, 0.9))
	overlay.draw_texture_rect_region(minimap_overview, minimap_rect, Rect2(win.position * ov_scale, win.size * ov_scale), Color(0.86, 0.84, 0.9))
	for poly in lab.zone.get("walkable", []):
		var n: int = poly.size()
		for i in n:
			var a2: Vector2 = to_map.call(Vector2(float(poly[i][0]), float(poly[i][1])))
			var b2: Vector2 = to_map.call(Vector2(float(poly[(i + 1) % n][0]), float(poly[(i + 1) % n][1])))
			var seg := _clip_segment(a2, b2, minimap_rect)   # keep the outline inside the minimap box
			if seg.size() == 2:
				overlay.draw_line(seg[0], seg[1], Color(1, 0.95, 0.8, 0.35), 1.5, true)
	for ex in lab.zone.get("exits", []):
		var c := Vector2.ZERO
		for p in ex["poly"]: c += Vector2(float(p[0]), float(p[1]))
		c = to_map.call(c / float(ex["poly"].size()))
		if minimap_rect.has_point(c):
			overlay.draw_circle(c, 6.0, Color(0.35, 0.65, 1.0, 0.9))
			overlay.draw_arc(c, 7.5, 0, TAU, 20, Color("f2d27a"), 2.0)
	for w in lab.zone_waypoints:
		if lab.waypoint_net == null or not lab.waypoint_net.is_unlocked(w["id"]): continue   # undiscovered: not on the map
		var c: Vector2 = to_map.call(lab.zone_world_to_px(w["pos"]))
		if minimap_rect.has_point(c):
			overlay.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7), c + Vector2(6, 0), c + Vector2(0, 7), c + Vector2(-6, 0)]), Color(0.45, 0.75, 1.0))
	# points of interest and quest objectives (same data as the full map); quests outside the window get an edge arrow
	if world_map != null:
		var zid: String = world_map.current_zone_id()
		for m in world_map.zone_markers(zid):
			if m["kind"] in ["hero", "exit", "waypoint"]: continue
			var c: Vector2 = to_map.call(m["at"])
			if minimap_rect.grow(-6).has_point(c):
				world_map._draw_marker(m, c, false, 0.75, overlay)
			elif m["kind"] == "quest":
				var dir: Vector2 = (c - minimap_rect.get_center()).normalized()
				var edge: Vector2 = minimap_rect.get_center() + dir * minf(minimap_rect.size.x * 0.5 / maxf(absf(dir.x), 1e-4), minimap_rect.size.y * 0.5 / maxf(absf(dir.y), 1e-4)) * 0.9
				var tri := PackedVector2Array([edge + dir * 9.0, edge + dir.rotated(2.4) * 7.0, edge + dir.rotated(-2.4) * 7.0])
				overlay.draw_colored_polygon(tri, Color("f2c14e"))
				overlay.draw_polyline(tri + PackedVector2Array([tri[0]]), Color(0, 0, 0, 0.8), 1.0, true)
	for t in lab.targets:
		if not t.visible: continue
		var c: Vector2 = to_map.call(lab.zone_world_to_px(t.global_position))
		if minimap_rect.has_point(c):
			overlay.draw_circle(c, 4.0, Color("d8463a") if t.inactive_t <= 0.0 else Color(0.4, 0.4, 0.4))
	var mc: Vector2 = to_map.call(me)
	overlay.draw_circle(mc, 6.0, Color(0, 0, 0, 0.8))
	overlay.draw_circle(mc, 4.5, Color("f2d27a"))
	overlay.draw_rect(minimap_rect, GOLD, false, 2.0)

## Liang-Barsky: the part of segment a-b inside rect r ([] if none).
func _clip_segment(a: Vector2, b: Vector2, r: Rect2) -> PackedVector2Array:
	var d := b - a
	var t0 := 0.0; var t1 := 1.0
	for e in [[-d.x, a.x - r.position.x], [d.x, r.end.x - a.x], [-d.y, a.y - r.position.y], [d.y, r.end.y - a.y]]:
		var pp: float = e[0]; var qq: float = e[1]
		if absf(pp) < 1e-9:
			if qq < 0.0: return PackedVector2Array()
		else:
			var t := qq / pp
			if pp < 0.0: t0 = maxf(t0, t)
			else: t1 = minf(t1, t)
	if t0 > t1: return PackedVector2Array()
	return PackedVector2Array([a + d * t0, a + d * t1])

func _draw_world() -> void:
	var cam: Camera3D = lab.camera
	if cam == null:
		return
	# enemy bars
	for t in lab.targets:
		if t.inactive_t > 0.0:
			continue
		var top: Vector3 = t.global_position + Vector3.UP * float(t.get("bar_h") if t.get("bar_h") != null else 2.35)
		if cam.is_position_behind(top):
			continue
		var sp := cam.unproject_position(top)
		var elite: bool = t.get("elite") == true
		if t.get("boss") == true: continue          # the boss has its own bar at the top of the screen
		if elite or (t.get("hp") != null and t.hp < t.max_hp):
			_bar(sp - Vector2(32 if elite else 26, 0), 64 if elite else 52, 5, t.hp / t.max_hp, Color("c8372d"))
		if elite:
			var nm := "%s  (%d)" % [String(t.ename), int(t.level)]
			var w := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			world_overlay.draw_string_outline(font, sp + Vector2(-w * 0.5, -6), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0, 0, 0, 0.9))
			world_overlay.draw_string(font, sp + Vector2(-w * 0.5, -6), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffc46a"))
	# player nameplate: level badge, name, HP (green) and MP (blue)
	var head: Vector3 = player.global_position + Vector3.UP * 2.25
	if not cam.is_position_behind(head):
		var hp := cam.unproject_position(head)
		world_overlay.draw_string_outline(font, hp + Vector2(-8, -20), hero_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.9))
		world_overlay.draw_string(font, hp + Vector2(-8, -20), hero_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, IVORY)
		_bar(hp + Vector2(-8, -12), 72, 5, player.hp / player.max_hp, Color("3fbf4a"))
		_bar(hp + Vector2(-8, -5), 72, 3, player.mana / player.max_mana, Color("3f7fe0"))
		world_overlay.draw_circle(hp + Vector2(-24, -11), 13.0, Color(0.06, 0.05, 0.05, 0.95))
		world_overlay.draw_arc(hp + Vector2(-24, -11), 13.0, 0, TAU, 32, GOLD, 1.5)
		world_overlay.draw_string(font, hp + Vector2(-33, -5), str(hero_level()), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, IVORY)
