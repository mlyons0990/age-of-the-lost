extends "res://tests/encounter_integration.gd"

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	# Review capture only: expose poses behind the modal and transient particles.
	var death_panel = main.hud.death_panel
	if death_panel != null: death_panel.hide()
	main.fx_text.hide(); main.fx_parts.hide(); main.fx_ground.hide()
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/actor_feedback/" + name + ".png")
	if death_panel != null: death_panel.show()
	main.fx_text.show(); main.fx_parts.show(); main.fx_ground.show()

func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main = current_scene; p = main.player; trial = main.encounter
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); p.set_process(false); trial.set_process(false)
	DirAccess.make_dir_recursive_absolute("res://previews/actor_feedback")
	for class_id in ["warrior", "mage"]:
		reset_actor("", class_id, 40); p.respawn(main.START); p.invuln = 0
		var origin: Vector2 = p.position
		var before: float = p.hp
		p.hurt(20, 40); p._advance_visual_feedback(0.01)
		check(p.hp < before and p.visual_state() == "hurt", class_id + " actual damage starts a visible hit reaction")
		check(p.position == origin and p.visual_root.position != Vector2.ZERO, class_id + " recoil affects artwork without moving the actor")
		p._advance_visual_feedback(0.3)
		check(p.visual_root.transform == Transform2D.IDENTITY and p.visual_root.modulate == Color.WHITE, class_id + " reaction returns cleanly to neutral")
		p.invuln = 1; before = p.hp; p.hurt(20, 40)
		check(p.hp == before and p.hurt_visual_left == 0, class_id + " invulnerability prevents both damage and false recoil")
		p.invuln = 0; p.ward_time = 5; p.ward_amount = 1000; p.hurt(20, 40)
		check(p.hp == before and p.hurt_visual_left == 0, class_id + " a fully absorbed ward hit does not pretend health was lost")
		p.ward_time = 0; p.ward_amount = 0
		p.dash = {"left":2.0,"dir":Vector2.RIGHT,"hit":[],"packet":{}}
		p._advance_visual_feedback(0)
		check(p.visual_state() == "charge" and p.visual_root.rotation != 0 and p.position == origin, class_id + " charge pose does not advance the dash")
		p.dash.clear(); p._advance_visual_feedback(0)
		check(p.visual_root.transform == Transform2D.IDENTITY, class_id + " finished charge leaves no residual lean")
		p._swing(func(): p.gold += 1)
		var timer: float = p.pending_t; var epoch: int = p.combat_epoch
		p.hurt(20, 40); p._advance_visual_feedback(0.02)
		check(p.pending_hit.is_valid() and p.pending_t == timer and p.combat_epoch == epoch, class_id + " nonfatal recoil preserves scheduled combat callbacks")
		await shot(class_id + "_hurt")
		p.hp = 1; p.hurt(100000, 40); p._advance_visual_feedback(0.5)
		check(p.dead and p.visual_state() == "dead" and absf(p.visual_root.rotation) > 1 and not p.sprite.is_playing(), class_id + " lethal damage settles into a stopped fallen pose")
		check(not p.pending_hit.is_valid() and p.dash.is_empty() and p.path.is_empty(), class_id + " death cancels attacks and movement")
		var gold_before: int = p.gold
		p._physics_process(1)
		check(p.gold == gold_before and p.position == origin, class_id + " dead actor cannot release a pending hit or move")
		check(main.hud.death_panel != null, class_id + " existing death and respawn interface remains available")
		await shot(class_id + "_fallen")
		p.respawn(origin)
		check(not p.dead and p.visual_root.transform == Transform2D.IDENTITY and p.visual_root.modulate == Color.WHITE and is_equal_approx(p.shadow.modulate.a, 0.38), class_id + " respawn immediately restores the complete visual transform")
		check(p.hp == p.stats().max_hp and p.mp == p.stats().max_mp and p.invuln == 2, class_id + " existing respawn resources and grace period are preserved")
		check(main._valid_save(main.capture_save()), class_id + " transient presentation state leaves schema-six saves valid")
	reset_actor("", "mage", 40); p.respawn(main.START); p.invuln = 0
	check(p.use_skill("basic", point(p.position, 4, 0)), "real mage cast starts")
	var cast_time: float = p.cast_remaining; var cast_epoch: int = p.combat_epoch
	p.hurt(20, 40); p._advance_visual_feedback(0.02)
	check(p.cast_remaining == cast_time and p.combat_epoch == cast_epoch, "hit presentation leaves mage windup and packet validity intact")
	p.cancel_casts(); p._advance_visual_feedback(1)
	p.set_process(true); p.hurt(20, 40); var paused_time: float = p.hurt_visual_left
	paused = true; await frames(4)
	check(p.hurt_visual_left == paused_time, "opening a pause menu freezes hit feedback with the world")
	paused = false; p.set_process(false)
	for type_key in ["slime", "revenant", "brute"]:
		main.spawn_enemy(type_key, false, point(p.position, -3, 0))
		var e: Node2D = main.enemies[-1]; e.set_process(false); e.stun = 0
		var at: Vector2 = e.position
		e.state = "windup"; e.wind_left = 0.1
		check(e.shows_attack_warning(), type_key + " living windup retains its warning")
		var health: float = e.hp; var dealt: float = e.take_hit(1, false, e.position - Vector2(100,0), {"kb":0})
		check(dealt == 1 and e.hp == health - 1 and e.sprite_pose().offset.x > 0 and e.position == at, type_key + " real hit recoils visually away from its source")
		var kills_before: int = p.kills
		main.kill_enemy(e); main.kill_enemy(e)
		check(p.kills == kills_before + 1 and not main.enemies.has(e), type_key + " death rewards once and removes combat targeting immediately")
		check(not e.shows_attack_warning(), type_key + " dying windup cannot display a live attack warning")
		e.dead_t = 0.45; var pose: Dictionary = e.sprite_pose(); e.phase += 10; e.struck = 0.18
		check(e.sprite_pose() == pose, type_key + " fallen pose ignores live bobbing and attack lunge")
		check(pose.scale.y < 0.2 if type_key == "slime" else absf(pose.rotation) > 1, type_key + " has the appropriate collapse silhouette")
		e.queue_redraw(); await shot(type_key + "_fallen")
		var player_health: float = p.hp
		e._process(0.6)
		check(e.is_queued_for_deletion() and p.hp == player_health, type_key + " corpse expires on the existing timer without attacking")
		await frames(2)
	var f := FileAccess.open("res://tests/ACTOR_FEEDBACK_LAST_RUN.txt", FileAccess.WRITE)
	f.store_string("\n".join(report) + "\nACTOR FEEDBACK RESULT %d checks; %d failures\n" % [checks, failures]); f.close()
	print("ACTOR FEEDBACK RESULT %d checks; %d failures" % [checks, failures])
	await main.quit_game(1 if failures else 0)
