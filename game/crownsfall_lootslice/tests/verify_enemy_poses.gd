extends SceneTree
## Painted enemy poses (owner 11-27): each enemy shows idle / walk / windup / strike / hit / death from its real
## state (not forced textures), keeps one size across poses, stands on its feet, and the death pose plays before it
## fades. With --out=<dir> it also saves an in-game screenshot of every pose.
var checks := 0
var failures := 0
var out := ""
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + why)
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	call_deferred("_run")
func _wait(s: float) -> void:
	await create_timer(s).timeout
var lab
func _shot(m, name: String) -> void:
	if out == "": return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var c: Vector2 = lab.camera.unproject_position(m.global_position + Vector3.UP * m.height_m * 0.5)
	var r := Rect2i(Vector2i(c) - Vector2i(150, 150), Vector2i(300, 300)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	img.get_region(r).save_png("%s/enemy_%s.png" % [out, name])
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	load("res://scripts/game/game_state.gd").new_character("warrior", "T")
	var boot = load("res://scripts/game/game_boot.gd")
	boot.class_id = "warrior"; boot.new_game = true
	lab = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 12: await physics_frame
	lab.travel_to("whisperwood", [0, 0])
	await _wait(1.6)
	var g = lab.game
	var p = lab.player
	for key in ["slime", "revenant", "brute"]:
		p.global_position = lab.zone_px_to_world(5900, 1650) + Vector3.UP * 0.08; lab.zone_last_ok = p.global_position
		for m in g.monsters.duplicate():
			if is_instance_valid(m) and m.global_position.distance_to(p.global_position) < 16.0:
				g.monsters.erase(m); lab.targets.erase(m); m.queue_free()
		await process_frame
		var m = g._spawn_monster(key, 3, false, false, p.global_position + Vector3(0, 0, -4.5))
		m.max_hp = 99999.0; m.hp = 99999.0
		p.global_position = m.global_position + Vector3(0, 0, 25.0); lab.zone_last_ok = p.global_position   # out of aggro range
		m.state = "idle"
		await _wait(0.3)
		check(not m.poses.is_empty() and m.pose == "idle", "%s: has 6 painted poses, idle at rest (%s)" % [key, m.pose])
		var h_idle: float = m.sprite.texture.get_height() * m.sprite.pixel_size
		check(absf(h_idle - m.height_m) < 0.02 and absf(m.sprite.offset.y - m.sprite.texture.get_height() * 0.5) < 0.5, "%s: idle stands %.2f m tall on its feet" % [key, h_idle])
		await _shot(m, key + "_idle")
		# chase: walk cycle while it moves
		p.global_position = m.global_position + Vector3(0, 0, 9.0); lab.zone_last_ok = p.global_position
		m.aggro()
		var seen := {}
		for i in 60:
			await physics_frame
			seen[m.pose] = true
			if i == 20: await _shot(m, key + "_walk")
		check(seen.has("walk") and seen.has("idle"), "%s: walks with a two-step cycle while chasing %s" % [key, seen.keys()])
		# wind-up and strike: let it reach the hero
		p.global_position = m.global_position + Vector3(0, 0, 1.2); lab.zone_last_ok = p.global_position
		p.max_hp = 999999.0; p.hp = 999999.0
		var got_wind := false; var got_strike := false
		for i in 300:
			await physics_frame
			if m.pose == "windup" and not got_wind: got_wind = true; await _shot(m, key + "_windup")
			if m.pose == "strike" and not got_strike: got_strike = true; await _shot(m, key + "_strike")
			if got_wind and got_strike: break
		check(got_wind and got_strike, "%s: winds up, then strikes (%s / %s)" % [key, got_wind, got_strike])
		# hit
		await _wait(0.6)
		m.hit(1.0)
		await process_frame; await process_frame   # process_frame fires before the monsters' own _process
		check(m.pose == "hit", "%s: flinches when hit (%s)" % [key, m.pose])
		await _shot(m, key + "_hit")
		await _wait(0.35)
		check(m.pose != "hit" or m.stun_t > 0.0, "%s: recovers from the flinch (%s)" % [key, m.pose])
		# death: the pose holds before the fade
		m.hp = 1.0; m.hit(5.0)
		await _wait(0.3)
		check(m.pose == "death" and is_instance_valid(m) and m.sprite.modulate.a > 0.95, "%s: shows the death pose before fading" % key)
		await _shot(m, key + "_death")
		await _wait(1.5)
		check(not is_instance_valid(m), "%s: removed after the fade" % key)
	print("RESULT %d/%d" % [checks - failures, checks])
	quit(1 if failures > 0 else 0)
