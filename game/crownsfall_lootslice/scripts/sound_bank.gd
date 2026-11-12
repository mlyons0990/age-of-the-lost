extends Node
## Thirteen quiet procedural prototype cues; eight voices maximum.
## Audio preferences are independent of progression and persist across F7.
const PREFS := "user://audio_preferences.cfg"
var muted := false
var voices: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var next_voice := 0

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	streams.clear()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var prefs := ConfigFile.new()
	if prefs.load(PREFS) == OK: muted = bool(prefs.get_value("audio", "muted", false))
	for i in 8:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -15
		add_child(voice)
		voices.append(voice)

func set_muted(value: bool) -> void:
	muted = value
	if muted:
		for voice in voices: voice.stop()
	var prefs := ConfigFile.new()
	prefs.set_value("audio", "muted", muted)
	prefs.save(PREFS)

func drain() -> void:
	# Allow the audio mixer to release stopped playback objects before exit.
	for voice in voices:
		voice.stop()
		voice.stream = null
	streams.clear()
	await get_tree().create_timer(0.12, true).timeout

func play_cue(id: String) -> void:
	if muted or voices.is_empty(): return
	var path := "res://assets/audio/%s.wav" % id
	if not ResourceLoader.exists(path): return
	if not streams.has(id): streams[id] = load(path)
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stop()
	voice.stream = streams[id]
	voice.play()
