extends "res://tests/inventory_ui_integration.gd"
const Layout := preload("res://scripts/hud_layout.gd")

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(4); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/reference_camera/"+name+".png")

func pointer(at: Vector2, which: int) -> void:
	var motion := InputEventMouseMotion.new(); motion.position = at
	root.push_input(motion,true); await frames(2)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = which; event.pressed = down; event.position = at
		root.push_input(event,true); await frames(2)

func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main = current_scene; p = main.player; trial = main.encounter; ui = main.hud
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); trial.set_process(false)
	reset_actor("","warrior",25); p.spec = "weaponmaster"; ui.banner_t = 99; ui.toasts.clear()
	DirAccess.make_dir_recursive_absolute("res://previews/reference_camera")
	var cam: Camera2D = main.cam
	check(not ui.menu_box.visible,"large development menu starts collapsed")
	ui.menu_toggle.pressed.emit()
	check(ui.menu_box.visible,"visible control toggles the real menu open")
	ui.menu_toggle.pressed.emit()
	check(not ui.menu_box.visible,"menu closes without pausing world simulation")
	for viewport_size in [Vector2(1920,1080),Vector2(2560,1080),Vector2(1440,1080),Vector2(1280,720)]:
		var layout := Layout.for_viewport(viewport_size)
		var bounds := Rect2(Vector2.ZERO,viewport_size)
		check(layout.skills.size()==5 and bounds.encloses(layout.potion),"potion cluster stays on screen at %s" % viewport_size)
		var valid := true
		for rect in layout.skills: valid = valid and bounds.encloses(rect) and is_equal_approx(rect.size.x,rect.size.y)
		check(valid,"all five skill paintings remain square and on screen at %s" % viewport_size)
		check(layout.potion.end.x<layout.skills[0].position.x,"left and right actions remain separated at %s" % viewport_size)
	var layout := Layout.for_viewport(root.get_visible_rect().size)
	for i in 6:
		var rect: Rect2 = layout.potion if i==5 else layout.skills[i]
		check(ui.overlay_buttons[i].get_rect()==rect,"click target %d matches the rendered rectangle" % i)
	var original_position: Vector2 = p.position
	cam.set_distance(-100)
	check(is_equal_approx(cam.zoom.x,cam.minimum_zoom()) and cam.zoom.x==cam.zoom.y,"wide zoom clamps uniformly to painted world bounds")
	cam.set_distance(100)
	check(is_equal_approx(cam.zoom.x,1.10),"close zoom has a stable maximum")
	cam.set_distance(NAN)
	check(is_equal_approx(cam.zoom.x,1.10),"invalid zoom values leave the last valid camera intact")
	cam.set_distance(cam.DEFAULT_ZOOM)
	var z := cam.zoom.x
	await pointer(root.get_visible_rect().size/2,MOUSE_BUTTON_WHEEL_UP)
	check(cam.zoom.x>z,"real viewport wheel event zooms the world")
	z = cam.zoom.x
	await pointer(layout.skills[1].get_center(),MOUSE_BUTTON_WHEEL_UP)
	check(cam.zoom.x==z,"scrolling over a skill cannot zoom the world")
	ui.open_page("inventory"); z = cam.zoom.x
	await pointer(root.get_visible_rect().size/2,MOUSE_BUTTON_WHEEL_DOWN)
	check(cam.zoom.x==z,"camera ignores wheel input while inventory pauses the world")
	ui.close_page(); p.path = PackedVector2Array(); p.mouse_held = false
	p.hp = p.stats().max_hp*0.3; p.potions = 3
	await pointer(layout.potion.get_center(),MOUSE_BUTTON_LEFT)
	check(p.potions==2 and p.hp>p.stats().max_hp*0.3,"new left potion cluster invokes the real heal exactly once")
	check(p.path.is_empty() and not p.mouse_held,"potion click cannot steer the character")
	p.cds.clear(); p.mp = p.stats().max_mp
	await pointer(layout.skills[1].get_center(),MOUSE_BUTTON_LEFT)
	check(float(p.cds.get(p.skill_def("s1").id,0))>0,"new right skill square invokes its actual equipped ability")
	check(p.path.is_empty() and not p.mouse_held,"skill click cannot steer the character")
	for at in [layout.life,layout.mana,Vector2(root.get_visible_rect().size.x-150,100)]:
		await pointer(at,MOUSE_BUTTON_LEFT)
		check(p.path.is_empty() and not p.mouse_held,"orb/minimap decoration absorbs pointer clicks at %s" % at)
		z = cam.zoom.x; await pointer(at,MOUSE_BUTTON_WHEEL_UP)
		check(cam.zoom.x==z,"orb/minimap decoration absorbs wheel input at %s" % at)
	check(p.position==original_position,"camera and HUD input leave world coordinates unchanged")
	cam.set_distance(cam.DEFAULT_ZOOM); cam.reset_smoothing(); await frames(4)
	check(cam.zoom.x>=cam.minimum_zoom(),"default camera never shows beyond available artwork")
	var screen_world := Rect2(cam.get_screen_center_position()-root.get_visible_rect().size/cam.zoom/2,root.get_visible_rect().size/cam.zoom)
	check(cam.bounds().grow(1).encloses(screen_world),"all viewport edges stay inside the camera's painted bounds")
	for world_point in [Vector2(860,350),Vector2(2340,1536),Vector2(800,1100),Vector2(1820,1536)]:
		p.position = world_point; cam.reset_smoothing(); cam.force_update_scroll(); await frames(2)
		screen_world = Rect2(cam.get_screen_center_position()-root.get_visible_rect().size/cam.zoom/2,root.get_visible_rect().size/cam.zoom)
		check(cam.bounds().grow(1).encloses(screen_world),"camera keeps painted edges at walkable boundary %s" % world_point)
	p.position = original_position; cam.reset_smoothing()
	p.hp = p.stats().max_hp; p.mp = p.stats().max_mp; p.cds.clear()
	await pointer(Vector2(800,600),MOUSE_BUTTON_WHEEL_DOWN)
	cam.set_distance(cam.DEFAULT_ZOOM); await shot("warrior_reference_layout")
	reset_actor("","mage",40); p.hp = p.stats().max_hp; p.mp = p.stats().max_mp
	cam.reset_smoothing(); await shot("mage_reference_layout")
	ui.open_page("inventory"); await shot("right_inventory_with_corner_hud"); ui.close_page()
	if DisplayServer.get_name() != "headless":
		var original_size := root.size
		for window_size in [Vector2i(1280,960),Vector2i(1440,600)]:
			root.size = window_size; await frames(8)
			cam.reset_smoothing(); cam.force_update_scroll(); await frames(3)
			screen_world = Rect2(cam.get_screen_center_position()-root.get_visible_rect().size/cam.zoom/2,root.get_visible_rect().size/cam.zoom)
			check(cam.bounds().grow(1).encloses(screen_world),"native resize keeps scenery coverage at %s" % window_size)
			layout = Layout.for_viewport(root.get_visible_rect().size)
			check(ui.overlay_buttons[1].get_rect()==layout.skills[1],"native resize moves actual click target with its skill at %s" % window_size)
			await shot("layout_"+str(window_size.x)+"x"+str(window_size.y))
		root.size = original_size; await frames(8); cam.set_distance(cam.DEFAULT_ZOOM)
	main.dialogue.set_voice_enabled(false)
	trial.start(); freeze_enemies(); trial.advance(0.3)
	main.fx_text.text(p.position-Vector2(0,100),"248",Color("f4c985"),true)
	await shot("combat_readability"); trial.finish(false,"Camera review",false)
	check(main._valid_save(main.capture_save()),"new presentation preserves valid progression saves")
	var f := FileAccess.open("res://tests/CAMERA_HUD_LAST_RUN.txt",FileAccess.WRITE)
	f.store_string("\n".join(report)+"\nCAMERA HUD RESULT %d checks; %d failures\n" % [checks,failures]); f.close()
	print("CAMERA HUD RESULT %d checks; %d failures" % [checks,failures])
	await main.quit_game(1 if failures else 0)
