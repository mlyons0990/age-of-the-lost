extends SceneTree
## In-game screenshots of each class's weapon attacks at their contact moment (visual QA for ClassData.weapon_moves).
##   xvfb-run godot --path . --rendering-driver opengl3 -s tests/capture_class_moves.gd -- --out=/tmp/m
var out := "/tmp"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab = null
	for cls in ["warrior", "rogue", "cleric"]:
		if lab != null: lab.queue_free(); await process_frame
		load("res://scripts/game/game_state.gd").new_character(cls, "Aldric")
		var boot = load("res://scripts/game/game_boot.gd")
		boot.class_id = cls; boot.new_game = true
		lab = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		root.add_child(lab)
		for i in 12: await physics_frame
		lab.travel_to("whisperwood", [0, 0])
		await create_timer(1.6).timeout
		var p = lab.player
		p.global_position = lab.zone_px_to_world(5900, 1650) + Vector3.UP * 0.08; lab.zone_last_ok = p.global_position
		for m in lab.game.monsters.duplicate():
			if is_instance_valid(m) and m.global_position.distance_to(p.global_position) < 14.0:
				lab.game.monsters.erase(m); lab.targets.erase(m); m.queue_free()
		await create_timer(0.5).timeout
		var target = lab.game._spawn_monster("brute", 3, false, false, p.global_position + Vector3(0.4, 0, -1.7))
		target.state = "recover"; target.wind_left = 999.0; target.max_hp = 99999.0; target.hp = 99999.0
		p.aim_point = target.global_position
		p.last_face = Vector3(target.global_position.x - p.global_position.x, 0, target.global_position.z - p.global_position.z).normalized()
		for kind in ["Slash", "Cleave"]:
			p.attack_t = 0.0; p.attack_cd = 0.0
			p._attack(kind, 0.72)
			var dur: float = p.attack_duration
			var phase: float = float(p.weapon_moves[kind]["phase"]) if p.weapon_moves.has(kind) else 0.57
			for k in 3:   # wind-up, contact, follow-through
				var at: float = dur * [phase * 0.55, phase, minf(0.98, phase + 0.12)][k]
				while dur - p.attack_t < at: await physics_frame
				await RenderingServer.frame_post_draw
				var img := root.get_texture().get_image()
				var c: Vector2 = lab.camera.unproject_position(p.global_position + Vector3.UP * 0.9)
				img = img.get_region(Rect2i(Vector2i(c) - Vector2i(170, 170), Vector2i(340, 340)))
				img.save_png("%s/move_%s_%s_%d.png" % [out, cls, kind, k])
			while p.attack_t > 0.0: await physics_frame
			await create_timer(0.4).timeout
		print("captured ", cls)
	quit(0)
