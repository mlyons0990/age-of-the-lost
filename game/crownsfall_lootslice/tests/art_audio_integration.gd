extends SceneTree
const ART := preload("res://scripts/art_library.gd")
const SOUND := preload("res://scripts/sound_bank.gd")
var checks := 0
var failures := 0
var report: Array[String] = []
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1; report.append(("PASS " if ok else "FAIL ") + message); print(report[-1])
	if not ok: failures += 1
func frames(n := 3) -> void:
	for i in n: await process_frame
func button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix): return node
	for child in node.get_children():
		var result := button(child, prefix)
		if result != null: return result
	return null
func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	var main: Node2D = current_scene
	var ui: CanvasLayer = main.hud
	if ui.start_panel != null:
		ui.start_panel.queue_free(); ui.start_panel = null; ui._refresh_pause()
	main.had_save = false; main.save_blocked = false
	check(main.create_character("mage", "Art QA"), "Mage fixture can be created with painted assets installed")
	var p: Node2D = main.player
	p.refresh_visuals()
	check(p.mage_art_active, "Mage selects its complete dedicated sprite bank")
	var complete := true
	for d in ["up", "ne", "right", "se", "down"]:
		complete = complete and p.sprite.sprite_frames.get_frame_count("walk_" + d) == 4
		complete = complete and p.sprite.sprite_frames.get_frame_count("idle_" + d) == 1
		complete = complete and p.sprite.sprite_frames.get_frame_count("cast_" + d) == 2
	check(complete, "all five facings have four walking poses, idle and two casting poses")
	p.class_id = "warrior"; p.refresh_visuals()
	var warrior_frame: AtlasTexture = p.sprite.sprite_frames.get_frame_texture("walk_se", 0)
	check(not p.mage_art_active and warrior_frame.atlas.resource_path.contains("assets/knight/"), "Warrior retains its original character bank")
	p.class_id = "mage"; p.refresh_visuals()
	check(p.mage_art_active and p.sprite.sprite_frames.get_frame_texture("idle_se", 0).resource_path.contains("assets/mage/"), "switching back restores Mage art without changing ownership")
	check(ART.icon("cinder_thread").resource_path.contains("art_expansion02") and ART.icon("staff").resource_path.contains("painted_icons"), "spell and inventory widgets select the actual painted files")
	check(ART.icon("unknown_art_id").resource_path.ends_with("amulet.svg"), "unknown artwork retains the editable vector fallback")
	check(ART.panel() != null, "generated nine-slice panel is available as a runtime style")
	var all_cues := true
	for id in ["cinder_thread", "glacial_stitch", "arcane_fold", "ashen_ward", "starfall_script", "solar_writ", "winter_crown", "epoch_lance", "ui_click", "equip", "pickup", "potion", "slash"]:
		var stream: AudioStream = load("res://assets/audio/%s.wav" % id)
		all_cues = all_cues and stream != null and stream.get_length() > 0 and stream.get_length() < 1
	check(all_cues, "all thirteen PCM sound cues import with bounded durations")
	main.sound.set_muted(false)
	p.cancel_casts(); p.attack_anim = 0; p.cds.clear()
	var voice_before: int = main.sound.next_voice
	var success: bool = p.use_skill("basic", p.position + Vector2(150, 0))
	check(success and main.sound.next_voice == (voice_before + 1) % 8, "a committed Mage cast starts exactly one cue")
	check(p.sprite.animation.begins_with("cast_") and p.sprite.frame == 0 and p.cast_remaining > 0, "cast windup selects the matching initial pose")
	voice_before = main.sound.next_voice
	check(not p.use_skill("basic", p.position + Vector2(150, 0)) and main.sound.next_voice == voice_before, "rejected repeat cast does not produce another cue")
	# Observe the authoritative physics release, not a process-timer race with
	# the .16s windup on a busy import/test machine.
	for i in 30:
		if p.cast_remaining <= 0: break
		await physics_frame
	check(p.sprite.animation.begins_with("cast_") and p.sprite.frame == 1 and p.cast_remaining <= 0, "gameplay release advances to cast release pose")
	main.sound.set_muted(true); await frames()
	check(main.sound.voices.all(func(v: AudioStreamPlayer) -> bool: return not v.playing), "muting stops all existing sound voices")
	var restored := SOUND.new(); root.add_child(restored)
	check(restored.muted, "mute preference survives sound-bank recreation")
	restored.queue_free(); await frames()
	p.cancel_casts(); p.attack_anim = 0; p.cds.clear(); p.mp = p.stats().max_mp
	voice_before = main.sound.next_voice
	check(p.use_skill("s3", p.position) and main.sound.next_voice == voice_before and p.ward_amount > 0, "muted ward still commits gameplay without starting audio")
	main.sound.set_muted(false)
	p.cancel_casts(); p.attack_anim = 0; p.cds.clear(); p.mp = 0
	voice_before = main.sound.next_voice
	check(not p.use_skill("s1", p.position + Vector2(150, 0)) and main.sound.next_voice == voice_before, "insufficient mana fails silently before audio commitment")
	main.save_game()
	var saved_hash := FileAccess.get_sha256(main.SAVE_PATH)
	ui.open_page("pause"); await frames()
	var mute_button := button(ui.char_panel, "Sound effects: On")
	var had_control := mute_button != null
	if mute_button != null: mute_button.pressed.emit()
	await frames()
	check(had_control and main.sound.muted and button(ui.char_panel, "Sound effects: Off") != null, "pause-screen control toggles and redraws persistent mute state")
	check(main.sound.process_mode == Node.PROCESS_MODE_ALWAYS and FileAccess.get_sha256(main.SAVE_PATH) == saved_hash, "audio settings work while paused without rewriting progression")
	main.sound.set_muted(false); ui.close_page()
	var f := FileAccess.open("res://tests/ART_AUDIO_LAST_RUN.txt", FileAccess.WRITE)
	f.store_string("Godot " + Engine.get_version_info().string + " / " + DisplayServer.get_name() + "\n" + "\n".join(report) + "\n%d checks; %d failures\n" % [checks, failures]); f.close()
	print("ART AUDIO RESULT %d checks; %d failures" % [checks, failures])
	await main.quit_game(1 if failures else 0)
