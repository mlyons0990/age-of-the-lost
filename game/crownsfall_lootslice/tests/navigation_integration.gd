extends "res://tests/town_ui_integration.gd"
func key(code: Key, shift := false) -> void:
	var event:=InputEventKey.new(); event.keycode=code; event.shift_pressed=shift; event.pressed=true; ui._input(event)
func joy(code: JoyButton) -> void:
	var event:=InputEventJoypadButton.new(); event.button_index=code; event.pressed=true; ui._input(event)
func nav_shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/navigation/"+name+".png")
func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main=current_scene; p=main.player; trial=main.encounter; ui=main.hud
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); trial.set_process(false); await physics_frame
	DirAccess.make_dir_recursive_absolute("res://previews/navigation")
	seed(7121); await fixture(); ui.open_page("inventory"); await frames(3)
	check(main.save_game(),"navigation fixture has a committed actor before pure inspection")
	var original:=live_save(); var disk_hash:=FileAccess.get_sha256(main.SAVE_PATH)
	var shell: Control=ui.inventory_shell
	key(KEY_RIGHT); key(KEY_DOWN)
	check(shell.keyboard_mode and shell.focus_cell==Vector2i(1,1),"arrow key events enter navigation mode and move the real cell cursor")
	key(KEY_TAB)
	check(shell.tab=="character" and shell.stats_area.visible,"Tab switches to the character sheet without replacing the backpack")
	key(KEY_TAB)
	check(shell.tab=="equipment" and shell.stage.visible,"second Tab restores equipment")
	joy(JOY_BUTTON_RIGHT_SHOULDER)
	check(shell.tab=="character","right shoulder chooses character tab")
	joy(JOY_BUTTON_LEFT_SHOULDER)
	check(shell.tab=="equipment","left shoulder chooses equipment tab")
	joy(JOY_BUTTON_DPAD_LEFT); joy(JOY_BUTTON_DPAD_UP)
	check(shell.focus_cell==Vector2i.ZERO,"D-pad routes through the same clamped navigation state")
	shell.focus_cell=Vector2i(p.inventory[0].x,p.inventory[0].y); key(KEY_ENTER)
	check(shell.pinned and ui.selected==0 and shell.card.visible,"Enter inspects the actual item at the cursor")
	shell.unpin(); joy(JOY_BUTTON_A)
	check(shell.pinned and ui.selected==0,"gamepad A pins the same real item card")
	check(live_save()==original and FileAccess.get_sha256(main.SAVE_PATH)==disk_hash,"navigation, tabbing and inspection cannot change ownership, progression or disk bytes")
	shell.focus_cell=Vector2i(9,5); key(KEY_RIGHT); key(KEY_DOWN)
	check(shell.focus_cell==Vector2i(9,5),"keyboard clamps at bottom-right boundary")
	shell.focus_cell=Vector2i.ZERO; key(KEY_LEFT); key(KEY_UP)
	check(shell.focus_cell==Vector2i.ZERO,"keyboard clamps at top-left boundary")
	shell.search.grab_focus(); await frames(); key(KEY_RIGHT); joy(JOY_BUTTON_DPAD_RIGHT); joy(JOY_BUTTON_X)
	check(shell.search.has_focus() and shell.focus_cell==Vector2i.ZERO and live_save()==original,"focused text input prevents keyboard navigation and controller quick-equip")
	joy(JOY_BUTTON_B)
	check(ui.inventory_active() and not shell.search.has_focus(),"first gamepad B releases search focus without closing inventory")
	joy(JOY_BUTTON_B); await frames(3)
	check(not ui.inventory_active() and not paused,"next gamepad B closes and resumes the world")
	ui.open_page("inventory"); await frames(3); shell=ui.inventory_shell
	shell.focus_cell=Vector2i(p.inventory[0].x,p.inventory[0].y); shell.keyboard_mode=true
	var uid: String=p.inventory[0].uid; var cell: Vector2i=shell.focus_cell
	key(KEY_ENTER,true); await frames(3); shell=ui.inventory_shell
	check(p.gear.weapon is Dictionary and p.gear.weapon.uid==uid,"Shift+Enter equips through the authoritative gear transaction")
	check(shell.keyboard_mode and shell.focus_cell==cell,"successful gear refresh preserves navigation mode and selected coordinate")
	var saved: Dictionary=main._read_save(main.SAVE_PATH)
	check(saved.gear.weapon.uid==uid and saved.hp==p.hp and saved.mp==p.mp,"keyboard equip is persisted with exact current resources")
	var focus_index: int=-1
	for i in p.inventory.size():
		if p.inventory[i].slot=="focus": focus_index=i
	uid=p.inventory[focus_index].uid; shell.focus_cell=Vector2i(p.inventory[focus_index].x,p.inventory[focus_index].y)
	joy(JOY_BUTTON_X); await frames(3); shell=ui.inventory_shell
	check(p.gear.offhand is Dictionary and p.gear.offhand.uid==uid,"gamepad X quick-equips a legal focus through the same transaction")
	var staff_index: int=-1
	for i in p.inventory.size():
		if p.inventory[i].slot=="staff": staff_index=i
	shell.show_bag_item(staff_index,true)
	check(contains_text(ui.inspector,"Moves to backpack") and contains_text(ui.inspector,p.gear.offhand.name),"staff comparison names the displaced offhand before any swap")
	var before:=live_save(); ui.refresh_inventory(); await frames(3); shell=ui.inventory_shell
	check(live_save()==before and shell.keyboard_mode,"refreshing a focus inspector preserves the actor and navigation mode")
	var mouse:=InputEventMouseButton.new(); mouse.button_index=MOUSE_BUTTON_LEFT; mouse.pressed=true
	mouse.position=(Vector2(p.inventory[0].x,p.inventory[0].y)+Vector2(0.1,0.1))*shell.bag.cell_size
	shell.bag._gui_input(mouse)
	check(not shell.keyboard_mode,"pointer selection returns the backpack to mouse mode")
	key(KEY_TAB); await frames(3)
	var base: Dictionary=SYS.derive(p.level,{},p.mods(),p.class_id)
	check(contains_text(shell.stats_area,"Base "+str(snappedf(base.attributes.dexterity,0.1))),"Mage fractional base Dexterity is derived and rendered without integer truncation")
	check(contains_text(shell.stats_area,"%.1f" % p.stats().spell_power),"character offense comes from the actual equipped build")
	await nav_shot("01_character_sheet")
	for size in [Vector2i(1280,720),Vector2i(1440,810),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(960,720)]:
		root.size=size; await frames(5); shell.layout()
		var vp:=root.get_visible_rect().size; var rect:=Rect2(shell.dock.position,shell.dock.size*shell.dock.scale)
		check(rect.position.x>=vp.x*0.5 and rect.end.x<=vp.x and rect.position.y>=0 and rect.end.y<=vp.y,"character and backpack stay fully right-docked at %s" % size)
		check(shell.bag.visible and shell.stats_area.visible and shell.bag.position.y>shell.stats_area.position.y+shell.stats_area.size.y,"character resources and real bag remain available at %s" % size)
		if size==Vector2i(960,720): await nav_shot("02_character_four_three")
	ui.close_page(); await frames(3); reset_actor("","warrior",40); p.hero_name="Wayfarer"; ui.open_page("inventory"); ui.inventory_shell.set_tab("character"); await frames(3)
	check(contains_text(ui.inventory_shell.stats_area,"Weapon power") and not contains_text(ui.inventory_shell.stats_area,"Spell power"),"Warrior sheet uses its weapon-based offense instead of Mage power")
	check(main._valid_save(main.capture_save()),"navigation leaves an importable schema-six actor")
	print("NAVIGATION RESULT %d checks; %d failures" % [checks,failures])
	var file:=FileAccess.open("res://tests/NAVIGATION_LAST_RUN.txt",FileAccess.WRITE); file.store_string("\n".join(report)+"\nNAVIGATION RESULT %d checks; %d failures\n" % [checks,failures]); file.close()
	await main.quit_game(1 if failures else 0)
func live_save() -> String: return JSON.stringify(main.capture_save())
