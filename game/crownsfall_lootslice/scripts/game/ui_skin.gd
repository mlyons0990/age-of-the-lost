extends RefCounted
## The painted AOTL UI kit (assets/ui/kit, cut by tools/cut_ui_kit.py from the 2026-11-27 Higgsfield set that
## matches the HUD's bronze filigree): frames, buttons, slots, cells, tabs, sliders, checkboxes, skill-tree pieces.
## Every game screen (title, inventory / character, skills, options, shop, dialogue, death, epilogue, tooltips) is
## built from these helpers so the whole UI reads as one set.
const DIR := "res://assets/ui/kit/"
const GOLD := Color("d9b46a")
const GOLD_DIM := Color("8f7444")
const IVORY := Color("efe6cf")
const MUTED := Color("a8977a")
## Inner (slate) rectangles of the whole window frames, in frame pixels (measured from the cut art).
const TALL_INNER := Rect2(59, 126, 601, 789)
const TALL_SMALL_INNER := Rect2(41, 87, 417, 548)
const WIDE_INNER := Rect2(80, 219, 1281, 497)

static var _tex := {}

static func tex(name: String) -> Texture2D:
	if not _tex.has(name): _tex[name] = load(DIR + name + ".png")
	return _tex[name]

static func fonts() -> Array:
	return [load("res://assets/fonts/LiberationSerif-Bold.ttf"), load("res://assets/fonts/LiberationSerif-Regular.ttf")]

## A 9-slice StyleBoxTexture from one kit image.
static func box(name: String, margin: Vector4, content := Vector4(-1, -1, -1, -1), tile := true) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex(name)
	sb.texture_margin_left = margin.x; sb.texture_margin_top = margin.y
	sb.texture_margin_right = margin.z; sb.texture_margin_bottom = margin.w
	if tile:
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	var c := margin if content.x < 0 else content
	sb.content_margin_left = c.x; sb.content_margin_top = c.y
	sb.content_margin_right = c.z; sb.content_margin_bottom = c.w
	return sb

## The crownless bronze frame for panels of any size (dialogue, shop, death, epilogue, options pages).
static func panel_box(pad := 22.0) -> StyleBoxTexture:
	return box("frame9", Vector4(47, 47, 47, 47), Vector4(47 + pad, 44 + pad, 47 + pad, 44 + pad), false)

static func tooltip_box() -> StyleBoxTexture:
	return box("tooltip", Vector4(34, 34, 34, 34), Vector4(26, 24, 26, 22), false)

static func button_boxes() -> Dictionary:
	var out := {}
	for st in ["normal", "hover", "pressed"]:
		out[st] = box("button_" + st, Vector4(30, 12, 30, 12), Vector4(34, 6, 34, 6), false)
	var dis := box("button_pressed", Vector4(30, 12, 30, 12), Vector4(34, 6, 34, 6), false)
	dis.modulate_color = Color(0.6, 0.6, 0.6)
	out["disabled"] = dis
	return out

## A painted kit button: bronze plate, gold rim on hover, inset when pressed.
static func button(text: String, w := 300.0, h := 52.0, size := 19) -> Button:
	var f := fonts()
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", f[0])
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", IVORY)
	b.add_theme_color_override("font_hover_color", Color("ffe7a8"))
	b.add_theme_color_override("font_pressed_color", Color("ffe7a8"))
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.46))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	b.add_theme_constant_override("outline_size", 4)
	var bx := button_boxes()
	for st in bx: b.add_theme_stylebox_override(st, bx[st])
	b.add_theme_stylebox_override("hover_pressed", bx["pressed"])
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

## A round icon button from the kit (close / plus).
static func icon_button(name: String, sz := 40.0) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = tex(name)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(sz, sz)
	b.size = Vector2(sz, sz)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_entered.connect(func(): b.modulate = Color(1.25, 1.15, 0.95))
	b.mouse_exited.connect(func(): b.modulate = Color.WHITE)
	return b

## A tab: rounded bronze tab, gold when selected.
static func tab(text: String, on: bool, w := 170.0) -> Button:
	var f := fonts()
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, 46)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", f[0])
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", Color("2a1c0c") if on else IVORY)
	b.add_theme_color_override("font_hover_color", Color("2a1c0c") if on else Color("ffe7a8"))
	var sb := box("tab_on" if on else "tab", Vector4(28, 22, 28, 8), Vector4(20, 12, 20, 4), false)
	for st in ["normal", "hover", "pressed", "hover_pressed"]: b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

## Slider styled with the kit track and gem knob.
static func slider(w := 300.0) -> HSlider:
	var s := HSlider.new()
	s.custom_minimum_size = Vector2(w, 32)
	s.focus_mode = Control.FOCUS_NONE
	var track := box("slider_track", Vector4(14, 8, 14, 8), Vector4(0, 6, 0, 6), false)
	s.add_theme_stylebox_override("slider", track)
	var fill := StyleBoxFlat.new(); fill.bg_color = Color(0.85, 0.66, 0.3, 0.75)
	fill.content_margin_top = 4; fill.content_margin_bottom = 4
	fill.set_corner_radius_all(3)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var knob := _scaled(tex("slider_knob"), 30)
	s.add_theme_icon_override("grabber", knob)
	s.add_theme_icon_override("grabber_highlight", knob)
	return s

static func checkbox(text: String) -> CheckBox:
	var f := fonts()
	var c := CheckBox.new()
	c.text = text
	c.focus_mode = Control.FOCUS_NONE
	c.add_theme_font_override("font", f[1])
	c.add_theme_font_size_override("font_size", 18)
	c.add_theme_color_override("font_color", IVORY)
	c.add_theme_color_override("font_hover_color", Color("ffe7a8"))
	c.add_theme_color_override("font_pressed_color", IVORY)
	c.add_theme_icon_override("unchecked", _scaled(tex("check_off"), 30))
	c.add_theme_icon_override("checked", _scaled(tex("check_on"), 30))
	c.add_theme_constant_override("h_separation", 12)
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]: c.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	return c

static func _scaled(t: Texture2D, px: int) -> Texture2D:
	var key := "%s@%d" % [t.resource_path, px]
	if _tex.has(key): return _tex[key]
	var im := t.get_image()
	im.resize(px, int(round(px * float(im.get_height()) / im.get_width())), Image.INTERPOLATE_LANCZOS)
	var out := ImageTexture.create_from_image(im)
	_tex[key] = out
	return out

## The title plaque with a label on it (window headers).
static func plaque(text: String, w := 345.0, size := 24) -> TextureRect:
	var f := fonts()
	var p := TextureRect.new()
	p.texture = tex("title_plaque")
	p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode = TextureRect.STRETCH_SCALE
	p.custom_minimum_size = Vector2(w, w * 96.0 / 345.0)
	p.size = p.custom_minimum_size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = text
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.offset_bottom = -w * 0.035
	l.add_theme_font_override("font", f[0])
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", GOLD)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	p.add_child(l)
	return p

## A whole crowned window (fixed size): frame art + a content Control laid over its slate interior.
## Returns {"root": Control, "content": Control, "close": TextureButton}.
static func window(kind: String, title: String) -> Dictionary:
	var name: String = {"tall": "window_tall", "small": "window_tall_small", "wide": "window_wide"}[kind]
	var inner: Rect2 = {"tall": TALL_INNER, "small": TALL_SMALL_INNER, "wide": WIDE_INNER}[kind]
	var t := tex(name)
	var root := Control.new()
	root.size = t.get_size()
	root.custom_minimum_size = t.get_size()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := TextureRect.new()
	bg.texture = t
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var pw := 300.0 if kind != "wide" else 340.0
	var pl := plaque(title, pw, 24 if kind != "small" else 22)
	pl.position = Vector2((root.size.x - pw) * 0.5, inner.position.y - 4)
	root.add_child(pl)
	var content := Control.new()
	var top := pl.size.y - 2
	content.position = inner.position + Vector2(0, top)
	content.size = inner.size - Vector2(0, top)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(content)
	var close := icon_button("close", 40)
	close.position = Vector2(inner.end.x - 44, inner.position.y + 4)
	root.add_child(close)
	return {"root": root, "content": content, "close": close, "inner": inner}

static func divider(w: float) -> TextureRect:
	var d := TextureRect.new()
	d.texture = tex("divider")
	d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	d.custom_minimum_size = Vector2(w, 18)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d

## Bronze scrollbar for scroll areas (key bindings).
static func style_scroll(sc: ScrollContainer) -> void:
	var bar := sc.get_v_scroll_bar()
	var track := StyleBoxFlat.new(); track.bg_color = Color(0.05, 0.045, 0.04, 0.9)
	track.border_color = GOLD_DIM; track.set_border_width_all(1); track.set_corner_radius_all(4)
	track.content_margin_left = 6; track.content_margin_right = 6
	var grab := StyleBoxFlat.new(); grab.bg_color = Color(0.62, 0.46, 0.24)
	grab.border_color = Color(0.92, 0.74, 0.4); grab.set_border_width_all(1); grab.set_corner_radius_all(4)
	var grab_hi := grab.duplicate(); grab_hi.bg_color = Color(0.8, 0.6, 0.3)
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("grabber", grab)
	bar.add_theme_stylebox_override("grabber_highlight", grab_hi)
	bar.add_theme_stylebox_override("grabber_pressed", grab_hi)
	bar.custom_minimum_size.x = 14
