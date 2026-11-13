extends "res://tests/camera_hud_integration.gd"
## Real viewport input at the new utility location, beyond signal-only checks.

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(4); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/dodge_corner/"+name+".png")

func press_space() -> void:
	for down in [true,false]:
		var event := InputEventKey.new(); event.keycode = KEY_SPACE; event.pressed = down
		root.push_input(event,true); await frames(2)

func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main = current_scene; p = main.player; trial = main.encounter; ui = main.hud
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); trial.set_process(false)
	reset_actor("","warrior",19); p.respawn(main.START); p.invuln = 0; ui.banner_t = 99; ui.toasts.clear()
	DirAccess.make_dir_recursive_absolute("res://previews/dodge_corner")
	for view in [Vector2(1920,1080),Vector2(2560,1080),Vector2(1440,1080),Vector2(1280,720)]:
		var geometry := Layout.for_viewport(view)
		var rect: Rect2 = geometry.dodge
		var clear: bool = Rect2(Vector2.ZERO,view).encloses(rect) and rect.position.x>geometry.potion.end.x
		for skill in geometry.skills: clear = clear and not rect.intersects(skill)
		check(clear,"dodge clears the flasks and skill buttons at %s" % view)
	var layout := Layout.for_viewport(root.get_visible_rect().size)
	check(ui.dodge_button.get_rect()==layout.dodge,"actual new dodge target shares the layout rectangle")
	var cam: Camera2D = main.cam; var zoom_before := cam.zoom.x
	await pointer(layout.dodge.get_center(),MOUSE_BUTTON_WHEEL_UP)
	check(cam.zoom.x==zoom_before,"wheel over the new dodge control does not zoom the world")
	p.last_world_aim = p.position+Vector2(300,0)
	await pointer(layout.dodge.get_center(),MOUSE_BUTTON_LEFT)
	check(not p.dodge.is_empty() and is_equal_approx(p.dodge_cd,p.DODGE_COOLDOWN),"real pointer click starts one roll through the new control")
	check(p.path.is_empty() and not p.mouse_held,"dodge pointer input never leaks into world movement")
	var original: Dictionary = p.dodge.duplicate(true)
	await pointer(layout.dodge.get_center(),MOUSE_BUTTON_LEFT)
	check(p.dodge==original,"repeated UI click cannot restart an active roll")
	p._physics_process(0.14); p._advance_visual_feedback(0); await shot("warrior_roll_corner_hud")
	p.cancel_casts(); p.dodge_cd = 0; p.attack_anim = 0; p.swinging = 0
	ui.open_page("inventory")
	await pointer(layout.dodge.get_center(),MOUSE_BUTTON_LEFT)
	check(p.dodge.is_empty() and p.dodge_cd==0,"inventory pause blocks the exposed left-side dodge button")
	await press_space()
	check(p.dodge.is_empty() and p.dodge_cd==0,"Space cannot roll behind the inventory screen")
	ui.close_page(); await frames(3); await press_space()
	check(not p.dodge.is_empty(),"real Space input resumes rolling after the inventory closes")
	p.cancel_casts(); p.dodge_cd = 0; p._advance_visual_feedback(0)
	reset_actor("cinder_bloom","mage",40); p.dodge_cd = 0
	check(p.use_skill("s3",p.position) and p.aura.running,"actual Ember Aura is active before the movement check")
	p.last_world_aim = p.position+Vector2(-300,0)
	await pointer(layout.dodge.get_center(),MOUSE_BUTTON_LEFT)
	check(not p.dodge.is_empty() and p.aura.running,"Mage rolls through the same control without cancelling Ember Aura")
	p._physics_process(0.14); p._advance_visual_feedback(0); await shot("mage_roll_with_aura")
	p._physics_process(0.14); p._advance_visual_feedback(0)
	check(p.dodge.is_empty() and p.dodge_cd>0 and p.aura.running,"roll ends and cooldown remains while the aura continues")
	await pointer(Vector2(800,600),MOUSE_BUTTON_WHEEL_DOWN)
	cam.set_distance(cam.DEFAULT_ZOOM); await shot("dodge_corner_cooldown")
	p.cancel_casts(); p.dodge_cd = 0; p._advance_visual_feedback(0); await shot("dodge_corner_ready")
	if DisplayServer.get_name() != "headless":
		var original_size := root.size
		for window_size in [Vector2i(1280,960),Vector2i(1440,600)]:
			root.size = window_size; await frames(8)
			layout = Layout.for_viewport(root.get_visible_rect().size)
			check(ui.dodge_button.get_rect()==layout.dodge,"window resize keeps dodge art and click target aligned at %s" % window_size)
			p.dodge_cd = 0; p.last_world_aim = p.position+Vector2(100,0)
			await pointer(layout.dodge.get_center(),MOUSE_BUTTON_LEFT)
			check(not p.dodge.is_empty(),"resized dodge control receives its real click at %s" % window_size)
			p.cancel_casts(); p._advance_visual_feedback(0)
		root.size = original_size; await frames(5)
	check(main._valid_save(main.capture_save()),"combined corner HUD and dodge retain valid progression saves")
	var f := FileAccess.open("res://tests/DODGE_CORNER_LAST_RUN.txt",FileAccess.WRITE)
	f.store_string("\n".join(report)+"\nDODGE CORNER RESULT %d checks; %d failures\n" % [checks,failures]); f.close()
	print("DODGE CORNER RESULT %d checks; %d failures" % [checks,failures])
	await main.quit_game(1 if failures else 0)
