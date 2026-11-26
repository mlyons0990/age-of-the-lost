extends Control
## Title screen: Continue (saved character), New Game (choose Knight or Mage), Settings, Quit.
const STATE := preload("res://scripts/game/game_state.gd")
const BOOT := preload("res://scripts/game/game_boot.gd")
const SAVE := preload("res://scripts/three_d/aotl_save.gd")
const GOLD := Color("d9b46a")
const GOLD_DIM := Color("8f7444")
const IVORY := Color("efe6cf")
var font: Font
var font_r: Font
var menu: VBoxContainer
var pick: Control

func _ready() -> void:
	get_tree().paused = false
	# the original 2D build's self-tests start from the project's main scene: hand them on to it
	for a in OS.get_cmdline_user_args():
		if a.ends_with("-test") or a == "--legacy-2d":
			get_tree().change_scene_to_file.call_deferred("res://main.tscn")
			return
	font = load("res://assets/fonts/LiberationSerif-Bold.ttf")
	font_r = load("res://assets/fonts/LiberationSerif-Regular.ttf")
	_apply_settings()
	var bg := TextureRect.new()
	bg.texture = load("res://assets/zones/whisperwood_w1.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.025, 0.03, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var logo := _label("AGE of the LOST", 86, IVORY)
	logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.position = Vector2(-600, 110); logo.size = Vector2(1200, 110)
	add_child(logo)
	var sub := _label("C R O W N S F A L L", 24, GOLD)
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(-600, 214); sub.size = Vector2(1200, 40)
	add_child(sub)
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 12)
	menu.set_anchors_preset(Control.PRESET_CENTER)
	menu.position = Vector2(-180, -40)
	menu.custom_minimum_size = Vector2(360, 0)
	add_child(menu)
	var info := STATE.summary()
	if not info.is_empty():
		var cls := "Knight" if info["class_id"] == "warrior" else "Mage"
		menu.add_child(_button("Continue  —  Level %d %s" % [int(info["level"]), cls], _continue))
	menu.add_child(_button("New Game", _show_pick))
	menu.add_child(_button("Quit", func(): get_tree().quit()))
	var ver := _label("Chapter I: The Whisperwood   ·   Click to move and attack · Q W E R T skills · 1-5 potions · I inventory · M map · Esc menu · F1 key bindings", 15, Color("cfc7b8"), false)
	ver.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.position = Vector2(-900, -50); ver.size = Vector2(1800, 30)
	add_child(ver)

func _apply_settings() -> void:
	var cf: ConfigFile = SAVE.open()
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(cf.get_value("settings", "volume", 0.8)), 0.0001)))
	if bool(cf.get_value("settings", "fullscreen", false)) and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _label(t: String, size: int, col: Color, bold := true) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", font if bold else font_r)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	return l

func _box(bg: Color, border: Color, w := 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg; sb.border_color = border
	sb.set_border_width_all(w); sb.set_corner_radius_all(3); sb.set_content_margin_all(12)
	return sb

func _button(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(360, 52)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", IVORY)
	b.add_theme_color_override("font_hover_color", Color("ffe7a8"))
	b.add_theme_stylebox_override("normal", _box(Color(0.08, 0.06, 0.05, 0.88), GOLD_DIM, 1))
	b.add_theme_stylebox_override("hover", _box(Color(0.18, 0.12, 0.06, 0.95), GOLD))
	b.add_theme_stylebox_override("pressed", _box(Color(0.24, 0.16, 0.07, 1.0), GOLD))
	b.pressed.connect(cb)
	return b

func _continue() -> void:
	BOOT.class_id = ""
	BOOT.new_game = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _show_pick() -> void:
	menu.visible = false
	pick = HBoxContainer.new()
	pick.add_theme_constant_override("separation", 40)
	pick.set_anchors_preset(Control.PRESET_CENTER)
	pick.position = Vector2(-520, -150)
	add_child(pick)
	for c in [["warrior", "THE KNIGHT", "res://assets/knight/idle_se.png", "Sword and shield. Close-quarters strikes, a sweeping cleave and a charging dash. Plate armour and a deep well of life."],
			["mage", "THE MAGE", "res://assets/mage/idle_se.png", "Staff and spellbook. Ranged bolts, a piercing lance, a nova and a judgment sweep. Fragile, but devastating from afar."]]:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _box(Color(0.05, 0.04, 0.04, 0.92), GOLD))
		card.custom_minimum_size = Vector2(480, 0)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		card.add_child(v)
		v.add_child(_label(c[1], 30, GOLD))
		var tr := TextureRect.new()
		tr.texture = load(c[2])
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(440, 260)
		v.add_child(tr)
		var d := _label(c[3], 17, IVORY, false)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(440, 0)
		v.add_child(d)
		var cls: String = c[0]
		var b := _button("Begin as the " + ("Knight" if cls == "warrior" else "Mage"), func(): _start(cls))
		b.custom_minimum_size = Vector2(440, 52)
		v.add_child(b)
		pick.add_child(card)
	var back := _button("Back", func(): pick.queue_free(); menu.visible = true)
	back.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	back.position = Vector2(-180, -140)
	add_child(back)
	pick.tree_exited.connect(back.queue_free)

func _start(cls: String) -> void:
	if STATE.exists():
		var dlg := ConfirmationDialog.new()
		dlg.dialog_text = "Starting a new game replaces your saved character. Continue?"
		dlg.confirmed.connect(func(): _begin(cls))
		add_child(dlg)
		dlg.popup_centered()
		return
	_begin(cls)

func _begin(cls: String) -> void:
	STATE.new_character(cls)
	BOOT.class_id = cls
	BOOT.new_game = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")
