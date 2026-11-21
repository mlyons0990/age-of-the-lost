extends Node
## Sound effects and music. Effects load from res://assets/sfx and play through a
## small pool of players, with slight pitch variation so repeats don't sound robotic.
## Music loops from res://assets/music and crossfades between tracks.
## M toggles mute. Made by tools/make_sfx.py and tools/make_music.py.

const POOL := 14
const VOLUME := {   # per-sound level in dB, so loud and quiet sounds sit together
	"swing": -6.0, "hit": -4.0, "crit": -3.0, "hurt": -4.0, "dodge": -8.0, "enemy_swing": -10.0, "enemy_die": -6.0,
	"boom": -2.0, "fire": -4.0, "harvest": -5.0, "charge": -5.0, "rally": -6.0,
	"gold": -8.0, "pickup": -8.0, "drop_rare": -6.0, "potion": -6.0, "level_up": -4.0,
	"rift_open": -4.0, "rift_close": -6.0, "wave": -6.0, "lorecast": -5.0,
	"ui_pick": -10.0, "ui_drop": -10.0, "equip": -8.0, "sell": -7.0, "error": -10.0, "click": -12.0,
	"bolt_cast": -8.0, "bolt_hit": -7.0, "drop_legendary": -5.0, "death": -4.0, "respawn": -6.0,
}
const MIN_GAP := 0.045   # the same sound won't restart faster than this (many hits in one swing)

var streams := {}
var players: Array[AudioStreamPlayer] = []
var last_played := {}
var muted := false
var played_count := 0   # used by the self-test

const MUSIC_DB := -13.0
const FADE := 1.6          # seconds for a music crossfade
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var music_now := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name in VOLUME.keys():
		var path := "res://assets/sfx/%s.wav" % name
		if ResourceLoader.exists(path):
			streams[name] = load(path)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music_a = AudioStreamPlayer.new()
	music_b = AudioStreamPlayer.new()
	add_child(music_a)
	add_child(music_b)


## Crossfades to a music track ("plaza" or "scar"). Does nothing if it is already playing.
func play_music(name: String) -> void:
	if name == music_now:
		return
	var path := "res://assets/music/%s.ogg" % name
	if not ResourceLoader.exists(path):
		return
	music_now = name
	var stream: AudioStreamOggVorbis = load(path)
	stream.loop = true
	var old := music_a if music_a.playing else null
	var nxt := music_b if old == music_a else music_a
	nxt.stream = stream
	nxt.volume_db = -60.0
	nxt.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(nxt, "volume_db", MUSIC_DB if not muted else -80.0, FADE)
	if old != null:
		tw.tween_property(old, "volume_db", -60.0, FADE)
		tw.chain().tween_callback(old.stop)


func play(name: String, pitch_jitter := 0.06, volume_offset := 0.0) -> void:
	if muted or not streams.has(name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(last_played.get(name, -1.0)) < MIN_GAP:
		return
	last_played[name] = now
	var best: AudioStreamPlayer = players[0]
	for p in players:
		if not p.playing:
			best = p
			break
	best.stream = streams[name]
	best.volume_db = float(VOLUME.get(name, -6.0)) + volume_offset
	best.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	best.play()
	played_count += 1


func toggle_mute() -> void:
	muted = not muted
	if muted:
		for p in players:
			p.stop()
	for m in [music_a, music_b]:
		if m.playing:
			m.volume_db = -80.0 if muted else MUSIC_DB



## Stops everything and releases the streams. Call before quitting, then wait a
## couple of frames so the audio engine lets go of sounds that were playing.
func stop_all() -> void:
	for p in players + [music_a, music_b]:
		p.stop()
		p.stream = null
	music_now = ""
