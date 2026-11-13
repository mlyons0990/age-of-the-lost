extends Node
## Selected NPC/enemy dialogue only. Presentation never owns combat timing.
const PREFS := "user://dialogue_preferences.cfg"
var main: Node2D
var lines: Dictionary = {}
var voice: AudioStreamPlayer
var active: Dictionary = {}
var remaining := 0.0
var clock := 0.0
var last_played: Dictionary = {}
var voice_enabled := true
var voice_volume := 0.7
var subtitles_enabled := true
var subtitle_layer: CanvasLayer
var panel: Panel
var caption: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue_lines.json"))
	if parsed is Dictionary: lines = parsed
	var prefs := ConfigFile.new()
	if prefs.load(PREFS) == OK:
		var volume = prefs.get_value("dialogue", "volume", 0.7)
		if (volume is float or volume is int) and is_finite(float(volume)): voice_volume = clampf(float(volume), 0, 1)
		var enabled = prefs.get_value("dialogue", "enabled", true)
		if enabled is bool: voice_enabled = enabled
		var subtitles = prefs.get_value("dialogue", "subtitles", true)
		if subtitles is bool: subtitles_enabled = subtitles
	voice = AudioStreamPlayer.new(); voice.volume_db = linear_to_db(maxf(voice_volume, 0.0001)); add_child(voice)
	subtitle_layer = CanvasLayer.new(); subtitle_layer.layer = 20; add_child(subtitle_layer)
	panel = Panel.new(); panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; subtitle_layer.add_child(panel)
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.035,0.04,0.06,0.94)
	style.border_color = Color("a38a55"); style.set_border_width_all(1); style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	caption = Label.new(); caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.max_lines_visible = 2
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",20); caption.add_theme_color_override("font_color",Color("f1e3c9")); panel.add_child(caption)
	panel.hide()

func _exit_tree() -> void:
	stop()

func save_preferences() -> void:
	var prefs := ConfigFile.new()
	prefs.set_value("dialogue","volume",voice_volume); prefs.set_value("dialogue","enabled",voice_enabled)
	prefs.set_value("dialogue","subtitles",subtitles_enabled); prefs.save(PREFS)

func set_voice_enabled(value: bool) -> void:
	voice_enabled = value
	if not value: voice.stop()
	save_preferences()

func set_voice_volume(value: float) -> void:
	if not is_finite(value): return
	voice_volume = clampf(value,0,1); voice.volume_db = linear_to_db(maxf(voice_volume,0.0001))
	if voice_volume == 0: voice.stop()
	save_preferences()

func set_subtitles(value: bool) -> void:
	subtitles_enabled = value; save_preferences(); _layout()

func play_line(id: String) -> bool:
	if main != null and main.player.dead: return false
	if not lines.has(id) or not lines[id] is Dictionary: return false
	var line: Dictionary = lines[id]
	if String(line.get("text","")).is_empty(): return false
	if clock - float(last_played.get(id,-9999)) < float(line.get("cooldown",20)): return false
	if not active.is_empty() and int(line.get("priority",0)) <= int(active.get("priority",0)): return false
	stop(); active = line.duplicate(true); active.id = id; last_played[id] = clock
	remaining = clampf(String(line.text).length()/14.0,3,9)
	var path := String(line.get("audio",""))
	if path.begins_with("res://assets/audio/dialogue/") and ResourceLoader.exists(path):
		var stream = load(path)
		if stream is AudioStream:
			remaining = maxf(remaining,stream.get_length()+0.25)
			if voice_enabled and voice_volume > 0:
				voice.stream = stream; voice.stream_paused = false; voice.play()
	caption.text = "%s: %s" % [line.get("speaker",""),line.text]
	_layout()
	return true

func stop(scope := "") -> void:
	if scope != "" and active.get("scope","") != scope: return
	active.clear(); remaining = 0
	if voice != null:
		voice.stream_paused = false; voice.stop(); voice.stream = null
	if panel != null: panel.hide()

func _process(delta: float) -> void: advance(delta)

func advance(delta: float) -> void:
	if not is_finite(delta) or delta < 0: return
	if main != null and main.player != null and main.player.dead: stop()
	if not active.is_empty() and active.get("scope","") == "merchant" and main.hud.page != "merchant": stop()
	var suspended: bool = get_tree().paused and active.get("scope","") != "merchant"
	voice.stream_paused = suspended
	if not suspended:
		clock += delta
		if not active.is_empty():
			remaining -= delta
			if remaining <= 0: stop()
	_layout()

func _layout() -> void:
	if panel == null: return
	panel.visible = subtitles_enabled and not active.is_empty() and not voice.stream_paused
	if not panel.visible: return
	var size := get_viewport().get_visible_rect().size
	var width := minf(620,size.x-32)
	if active.get("scope","") == "merchant" and main.hud.inventory_shell != null:
		var shell = main.hud.inventory_shell
		var gap: float = size.x - 2*(12 + shell.BASE.x*shell.scale_factor) - 24
		if gap >= 260: width = minf(width,gap)
	panel.size = Vector2(width,80)
	caption.position = Vector2(12,8); caption.size = Vector2(width-24,64)
	panel.position = Vector2((size.x-width)/2,maxf(145,size.y-235))
