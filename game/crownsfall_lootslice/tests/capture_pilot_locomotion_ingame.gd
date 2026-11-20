extends SceneTree
## Real renders of the pilot knight moving under player input (W, +Shift sprint, +Ctrl stroll), with the
## arm-carry layer active, from a following side camera. --out=<dir>
const LAB := preload("res://scripts/three_d/rig_lab.gd")
func _initialize() -> void:
	call_deferred("_run")
func key(code: Key, down: bool) -> void:
	var e := InputEventKey.new(); e.keycode = code; e.physical_keycode = code; e.pressed = down
	Input.parse_input_event(e)
func _run() -> void:
	var out := "/tmp"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	root.size = Vector2i(640, 640)
	var lab = LAB.new(); lab.use_pilot_knight_candidate = true
	root.add_child(lab)
	for i in 30: await process_frame
	var actor = lab.player
	var cam := Camera3D.new(); cam.fov = 36; lab.add_child(cam); cam.current = true
	for mode in [["Walk", []], ["Run", [KEY_SHIFT]], ["Stroll", [KEY_CTRL]]]:
		for k in mode[1]: key(k, true)
		key(KEY_W, true)
		for i in 40: await physics_frame
		var cycle: float = actor.animation.current_animation_length / maxf(0.01, actor.animation.get_playing_speed())
		for k in 8:
			var t0 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - t0 < cycle / 8.0 * 1000.0:
				var ap: Vector3 = actor.global_position
				cam.look_at_from_position(ap + Vector3(3.0, 1.5, 0.6), ap + Vector3(0, 0.9, 0))
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s_%d.png" % [out, mode[0], k])
		print("CAP %s anim %s speed x%.2f carry %.2f body speed %.2f" % [mode[0], actor.animation.current_animation, actor.animation.get_playing_speed(), actor.arm_carry.influence, Vector2(actor.velocity.x, actor.velocity.z).length()])
		key(KEY_W, false)
		for k in mode[1]: key(k, false)
		for i in 20: await physics_frame
	quit(0)
