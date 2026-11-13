extends "res://tests/encounter_integration.gd"
## Dodge Roll: movement, invulnerability window, gating, cooldown and HUD button.

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	main.fx_text.hide()
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/dodge_roll/" + name + ".png")
	main.fx_text.show()

## Steps the real physics callback until the roll ends; returns seconds used.
func finish_roll() -> float:
	var used := 0.0
	while not p.dodge.is_empty() and used < 2.0:
		p._physics_process(0.02); used += 0.02
	return used

func on_floor(at: Vector2) -> bool:
	return NavigationServer2D.map_get_closest_point(p.get_world_2d().navigation_map, at).distance_to(at) < 6.0

func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main = current_scene; p = main.player; trial = main.encounter
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); p.set_process(false); trial.set_process(false)
	await physics_frame
	DirAccess.make_dir_recursive_absolute("res://previews/dodge_roll")
	for class_id in ["warrior", "mage"]:
		reset_actor("", class_id, 40); p.respawn(main.START); p.invuln = 0; p.dodge_cd = 0
		# Start-menu pause disables navigation regions; await their real server sync.
		await physics_frame; await process_frame
		check(on_floor(p.position), class_id + " navigation is active before stepping the dodge fixture")
		var origin: Vector2 = p.position
		var mana: float = p.mp; var epoch: int = p.combat_epoch
		p.target = null; p._walk_to(point(origin, 2, 2), false)
		check(p.dodge_ready() and p.dodge_roll(point(origin, 4, 0)), class_id + " roll starts toward the aim point")
		check(p.visual_state() == "dodge" and p.path.is_empty() and p.target == null, class_id + " roll replaces walking and targeting")
		check(p.mp == mana and p.combat_epoch == epoch, class_id + " roll costs no mana and leaves combat packets valid")
		check(is_equal_approx(p.invuln, p.DODGE_INVULN) and is_equal_approx(p.dodge_cd, p.DODGE_COOLDOWN), class_id + " roll grants its invulnerability window and starts its cooldown")
		var health: float = p.hp
		p.hurt(50, 40)
		check(p.hp == health and p.hurt_visual_left == 0, class_id + " damage during the window is ignored without a false recoil")
		check(not p.dodge_roll(point(origin, 0, 4)), class_id + " a second roll cannot start mid-roll")
		var cooldowns: Dictionary = p.cds.duplicate()
		check(not p.use_skill("basic", point(origin, 4, 0)) and p.mp == mana and p.cds == cooldowns, class_id + " abilities cannot be used mid-roll and nothing is spent")
		p._physics_process(0.14); p._advance_visual_feedback(0)
		check(absf(p.visual_root.rotation) > 1.0 and p.visual_root.scale.x < 1.0, class_id + " artwork tumbles and tucks at mid-roll")
		await shot(class_id + "_mid_roll")
		var used := 0.14 + finish_roll()
		var moved: Vector2 = GD.ground(origin, p.position)
		check(p.dodge.is_empty() and absf(moved.x - p.DODGE_DISTANCE) < 0.05 and absf(moved.y) < 0.05, class_id + " full roll travels its exact ground distance along the aim")
		check(used >= p.DODGE_TIME - 0.021 and used <= p.DODGE_TIME + 0.041, class_id + " full roll takes its stated time")
		check(on_floor(p.position), class_id + " roll ends on walkable floor")
		p._advance_visual_feedback(0)
		check(p.visual_state() != "dodge" and p.visual_root.transform == Transform2D.IDENTITY, class_id + " finished roll leaves no residual pose")
		check(not p.dodge_ready() and not p.dodge_roll(point(p.position, 4, 0)), class_id + " cooldown blocks an immediate second roll")
		p._physics_process(0.1)
		check(p.invuln == 0, class_id + " invulnerability ends shortly after the roll")
		p.hurt(20, 40)
		check(p.hp < health, class_id + " damage applies again once the window has passed")
		p._physics_process(p.DODGE_COOLDOWN)
		check(p.dodge_cd == 0 and p.dodge_ready(), class_id + " roll is ready again after the cooldown")

		# recovery may be cut short; committed actions may not
		p.attack_anim = 0.3
		check(p.dodge_roll(point(p.position, -3, 0)) and p.attack_anim == 0, class_id + " roll may cut short attack recovery")
		finish_roll(); p.dodge_cd = 0; p.invuln = 0
		p.position = main.START
		check(p.use_skill("basic", point(p.position, 3, 0)), class_id + " primary ability starts for the commitment check")
		var committed: bool = p.cast_remaining > 0 or p.pending_t > 0
		var cast_left: float = p.cast_remaining; var pending_left: float = p.pending_t
		check(committed and not p.dodge_roll(point(p.position, 0, 3)), class_id + " roll cannot interrupt a committed swing or cast windup")
		check(p.cast_remaining == cast_left and p.pending_t == pending_left and p.dodge.is_empty(), class_id + " refused roll leaves the committed action untouched")
		p.cancel_casts(); p.swinging = 0; p.attack_anim = 0; p.cds.clear()

		# zero-length aim, walls, pause and death
		p.position = main.START; p.facing = 4; p.dodge_cd = 0
		check(p.dodge_roll(p.position), class_id + " aiming at oneself still rolls")
		finish_roll()
		var facing_move: Vector2 = GD.ground(main.START, p.position)
		check(facing_move.x < -p.DODGE_DISTANCE + 0.05 and absf(facing_move.y) < 0.05, class_id + " a self-aimed roll goes the way the actor faces")
		var edge := NavigationServer2D.map_get_closest_point(p.get_world_2d().navigation_map, Vector2(-5000, main.START.y))
		p.position = edge; p.dodge_cd = 0
		check(p.dodge_roll(edge + Vector2(-600, 0)), class_id + " roll toward a wall starts")
		finish_roll()
		check(on_floor(p.position) and GD.gdist(edge, p.position) < 0.3 and p.dodge.is_empty(), class_id + " a wall stops the roll on the floor instead of passing through")
		p.position = main.START; p.dodge_cd = 0
		paused = true
		check(not p.dodge_roll(point(p.position, 3, 0)) and p.dodge_cd == 0, class_id + " roll is unavailable while the game is paused")
		paused = false
		p.ward_time = 5; p.ward_amount = 77
		check(p.dodge_roll(point(p.position, 3, 0)) and p.ward_amount == 77, class_id + " roll keeps an active ward")
		p.ward_time = 0; p.ward_amount = 0
		p.invuln = 0; p.hp = 1; p.hurt(100000, 40)
		check(p.dead and p.dodge.is_empty() and p.visual_state() == "dead", class_id + " death ends an active roll")
		check(not p.dodge_ready() and not p.dodge_roll(point(p.position, 3, 0)), class_id + " a fallen actor cannot roll")
		p.respawn(main.START)
		check(p.dodge.is_empty() and p.dodge_cd == 0 and p.dodge_ready(), class_id + " respawn clears the roll and its cooldown")
		var data: Dictionary = main.capture_save()
		check(main._valid_save(data) and not JSON.stringify(data).contains("dodge"), class_id + " roll state is transient and schema-six saves stay valid")

	# Shield Charge and the roll exclude each other
	reset_actor("", "warrior", 40); p.respawn(main.START); p.invuln = 0; p.dodge_cd = 0
	await physics_frame; await process_frame
	p.dash = {"left": 2.0, "dir": Vector2.RIGHT, "hit": [], "packet": {}}
	check(not p.dodge_roll(point(p.position, 0, 3)), "roll cannot start during Shield Charge")
	p.dash.clear()

	# keyboard and HUD button
	var key := InputEventKey.new(); key.keycode = KEY_SPACE; key.pressed = true
	p._unhandled_input(key)
	check(not p.dodge.is_empty(), "Space starts a roll")
	finish_roll(); p.dodge_cd = 0; p.invuln = 0
	var ui: CanvasLayer = main.hud
	ui._layout_bar()
	var view: Vector2 = root.get_visible_rect().size
	var button: Button = ui.dodge_button
	var rect := Rect2(button.position, button.size)
	check(rect == ui.dodge_button_rect(view) and Rect2(Vector2.ZERO, view).encloses(rect), "HUD roll button matches the drawn circle and sits inside the screen")
	var clear := true
	for other in ui.overlay_buttons: clear = clear and not rect.intersects(Rect2(other.position, other.size))
	check(clear, "HUD roll button does not overlap the ability or potion buttons")
	check(ui.draw_ctl.icon_cache.get("dodge_roll") is Texture2D, "the drawn HUD holds its own reference to the roll icon")
	var icon: Texture2D = load(ui.DODGE_ICON)
	check(icon != null and icon.get_size() == Vector2(128, 128), "HUD roll button uses the 128px Dodge Roll icon")
	check(FileAccess.get_sha256(ui.DODGE_ICON) == "764d12caad6efd99c37bbb13a099b7803740504c7dd6d6de0e565e55a65309e0", "runtime icon matches the published art-library file")
	p.last_world_aim = point(p.position, 3, 0)
	button.pressed.emit()
	check(not p.dodge.is_empty(), "clicking the HUD button rolls toward the last aim point")
	finish_roll()
	await shot("hud_cooldown")
	p.dodge_cd = 0; p.invuln = 0
	paused = true; button.pressed.emit()
	check(p.dodge.is_empty(), "the HUD button does nothing while paused")
	paused = false
	p._advance_visual_feedback(0)
	await shot("hud_ready")

	var f := FileAccess.open("res://tests/DODGE_ROLL_LAST_RUN.txt", FileAccess.WRITE)
	f.store_string("\n".join(report) + "\nDODGE ROLL RESULT %d checks; %d failures\n" % [checks, failures]); f.close()
	print("DODGE ROLL RESULT %d checks; %d failures" % [checks, failures])
	await main.quit_game(1 if failures else 0)
