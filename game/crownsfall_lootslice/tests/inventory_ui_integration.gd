extends "res://tests/encounter_integration.gd"
const SYS := preload("res://scripts/systems.gd")
var ui: CanvasLayer
func button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix): return node
	for child in node.get_children():
		var found:=button(child,prefix)
		if found!=null: return found
	return null
func contains_text(node: Node, value: String) -> bool:
	if node is Label and node.text.contains(value): return true
	for child in node.get_children():
		if contains_text(child,value): return true
	return false
func index_uid(id: String) -> int:
	for i in p.inventory.size():
		if p.inventory[i].uid==id: return i
	return -1
func gear_slot(slot: String) -> Button:
	for b in ui.gear_buttons:
		if b.slot==slot: return b
	return null
func bag_data(i: int) -> Dictionary: return {"source":"inventory","index":i,"uid":p.inventory[i].uid,"grab":Vector2i.ZERO}
func screen_setup() -> void:
	reset_actor("cinder_bloom"); ui=main.hud
	p.hero_name="Aurelia"; p.gold=1280; p.hp=333; p.mp=271
	p.gear.weapon=SYS.make_item(40,0.9,"staff","mage")
	p.gear.armor=SYS.make_item(40,0.8,"robe","mage")
	p.gear.helm=SYS.make_unique(); p.crafted_uniques=[SYS.UNIQUE_ID]
	p.gear.belt=SYS.make_item(40,0.4,"belt","mage")
	p.gear.boots=SYS.make_item(40,0.6,"slippers","mage")
	p.gear.gloves=SYS.make_item(40,0.4,"wraps","mage")
	p.gear.ring1=SYS.make_item(40,0.4,"ring","mage")
	p.gear.amulet=SYS.make_item(40,0.6,"amulet","mage")
	for base in ["wand","focus","hood","robe","ring","slippers"]: SYS.insert(p.inventory,SYS.make_item(40,0.8,base,"mage"))
func open_inventory() -> void:
	ui.open_page("inventory"); await frames(3)
func screenshot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/inventory/"+name+".png")
func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main=current_scene; p=main.player; trial=main.encounter; ui=main.hud
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); trial.set_process(false)
	await physics_frame
	DirAccess.make_dir_recursive_absolute("res://previews/inventory")
	seed(4102); screen_setup(); await open_inventory()
	var shell: Control=ui.inventory_shell
	check(paused and ui.char_panel==shell,"inventory uses the actual modal pause lifecycle")
	check(p.path.is_empty() and p.target==null and not p.mouse_held,"opening inventory clears movement and attack intent")
	var vp:=root.get_visible_rect().size; var rect:=Rect2(shell.dock.position,shell.dock.size*shell.dock.scale)
	check(rect.position.x>=vp.x*0.5 and rect.end.x<=vp.x and rect.position.y>=0 and rect.end.y<=vp.y,"entire panel fits the right side of the visible viewport")
	check(not shell is ColorRect,"inventory leaves the world visible without the former full-screen dimmer")
	check(shell.stage.visible and not shell.stats_area.visible,"default tab shows equipment above the bag")
	check(shell.bag.position.y>shell.stage.position.y+shell.stage.size.y,"inventory grid sits below every equipment slot")
	check(ui.gear_buttons.size()==10,"all ten real equipment slots are present")
	check(gear_slot("helm").position.y<gear_slot("armor").position.y,"helmet sits above body armour")
	check(gear_slot("weapon").position.x<gear_slot("armor").position.x and gear_slot("offhand").position.x>gear_slot("armor").position.x,"main and off hand flank the body")
	check(gear_slot("gloves").position.y>gear_slot("armor").position.y and gear_slot("boots").position.y>gear_slot("armor").position.y,"gloves and boots sit below torso")
	check(shell.bag.size==Vector2(SYS.WIDTH,SYS.HEIGHT)*shell.bag.cell_size and SYS.WIDTH*SYS.HEIGHT==60,"displayed bag geometry exactly matches sixty persisted cells")
	# FOOTPRINT ACCEPTANCE — authoritative widths/heights, not icon dimensions.
	var required_shapes: Dictionary = {"ring":Vector2i(1,1),"amulet":Vector2i(1,1),"weapon":Vector2i(1,3),"armor":Vector2i(2,3),"robe":Vector2i(2,3),"staff":Vector2i(2,4),"wand":Vector2i(1,2),"focus":Vector2i(1,2),"belt":Vector2i(2,1),"helm":Vector2i(2,2),"offhand":Vector2i(2,2),"gloves":Vector2i(2,2),"boots":Vector2i(2,2),"hood":Vector2i(2,2),"wraps":Vector2i(2,2),"slippers":Vector2i(2,2)}
	for base in required_shapes:
		var example: Dictionary = {"slot":base}
		var span: Vector2i = required_shapes[base]
		check(SYS.footprint(example)==span,"actual %s inventory footprint is %d×%d cells" % [base,span.x,span.y])
		var texture: Texture2D=ui._item_portrait(example)
		check(texture!=null and texture.get_size()==Vector2(span)*64.0,"%s uses a correctly proportioned transparent item portrait" % base)
		var preview: Control=ui.item_drag_preview({"slot":base,"uid":"preview","rarity":0})
		check(preview.size==Vector2(span)*50.0,"%s drag preview preserves actual cell width and height" % base)
		preview.free()
	var sword_test: Dictionary=SYS.make_item(1,0.0,"weapon","warrior")
	var ring_test: Dictionary=SYS.make_item(1,0.0,"ring","mage")
	var amulet_test: Dictionary=SYS.make_item(1,0.0,"amulet","mage")
	var armor_test: Dictionary=SYS.make_item(1,0.0,"armor","warrior")
	sword_test.x=0; sword_test.y=0
	ring_test.x=2; ring_test.y=0
	amulet_test.x=3; amulet_test.y=0
	armor_test.x=4; armor_test.y=2
	var original_grid_source: Array=shell.bag.source
	shell.bag.source=[sword_test,ring_test,amulet_test,armor_test]
	var cell: float=shell.bag.cell_size
	check(shell.bag.index_at(Vector2(0.5,2.5)*cell)==0,"vertical sword is selectable from its third occupied cell")
	check(shell.bag.index_at(Vector2(2.5,0.5)*cell)==1 and shell.bag.index_at(Vector2(2.5,1.5)*cell)==-1,"ring occupies exactly one cell")
	check(shell.bag.index_at(Vector2(3.5,0.5)*cell)==2 and shell.bag.index_at(Vector2(3.5,1.5)*cell)==-1,"amulet occupies exactly one cell")
	check(shell.bag.index_at(Vector2(5.5,4.5)*cell)==3,"chest armor occupies its full 2×3 rectangle")
	check(not SYS.fits(shell.bag.source,SYS.make_item(1,0.0,"ring"),Vector2i(0,2)),"cannot overlap the bottom cell of the sword")
	check(not SYS.fits([],sword_test,Vector2i(0,4)) and not SYS.fits([],armor_test,Vector2i(9,2)),"tall sword and chest armor cannot spill off the grid")
	shell.bag.source=original_grid_source
	shell.bag.queue_redraw()
	check(contains_text(shell,"GOLD  1280") and contains_text(shell,"333 /"),"panel shows actual currency and current resources")
	await screenshot("01_right_docked_equipment")
	ui._inspect(0); await frames(3)
	check(shell.card.visible and shell.pinned and ui.selected==0,"click pins an interactive item card beside the panel")
	check(shell.card.position.x+shell.card.size.x*shell.card.scale.x<shell.dock.position.x,"comparison card stays left of the dock")
	check(contains_text(ui.inspector,"IF EQUIPPED") and button(ui.inspector,"Equip →")!=null,"item card displays an actual equipment plan and working equip action")
	await screenshot("02_item_comparison")
	shell.unpin(); shell.show_bag_item(1); await frames()
	check(not shell.pinned and ui.selected==-1 and shell.card.visible,"hover previews do not select an item for accidental equipping")
	var focus_data:=bag_data(1); var before:=JSON.stringify({"bag":p.inventory,"gear":p.gear})
	check(not gear_slot("offhand")._can_drop_data(Vector2.ZERO,focus_data),"two-handed staff rejects focus drop before transaction")
	gear_slot("offhand")._drop_data(Vector2.ZERO,focus_data)
	check(JSON.stringify({"bag":p.inventory,"gear":p.gear})==before,"invalid equipment drop leaves ownership unchanged")
	var wand_uid: String=p.inventory[0].uid; var old_staff: String=p.gear.weapon.uid
	var plan: Dictionary=p.plan_equip(0,"weapon")
	check(plan.ok and JSON.stringify({"bag":p.inventory,"gear":p.gear})==before,"comparison and drop planning are pure")
	check(gear_slot("weapon")._can_drop_data(Vector2.ZERO,bag_data(0)),"matching legal wand can be dropped onto main hand")
	gear_slot("weapon")._drop_data(Vector2.ZERO,bag_data(0)); await frames(3)
	check(p.gear.weapon.uid==wand_uid and index_uid(old_staff)>=0,"drop equips wand and preserves displaced staff in bag")
	var focus_index: int=-1
	for i in p.inventory.size():
		if p.inventory[i].slot=="focus": focus_index=i
	check(gear_slot("offhand")._can_drop_data(Vector2.ZERO,bag_data(focus_index)),"wand loadout accepts a real focus offhand")
	gear_slot("offhand")._drop_data(Vector2.ZERO,bag_data(focus_index)); await frames(3)
	check(p.gear.offhand is Dictionary and p.gear.offhand.slot=="focus","offhand drop commits actual gear and derived stats")
	shell=ui.inventory_shell; shell.character_tab.pressed.emit(); await frames(3)
	check(shell.tab=="character" and shell.stats_area.visible and not shell.stage.visible,"character tab replaces equipment within the same right panel")
	check(shell.bag.visible and shell.bag.position.y>shell.stats_area.position.y+shell.stats_area.size.y,"backpack remains below the character sheet")
	check(contains_text(shell.stats_area,"Strength") and contains_text(shell.stats_area,"Charisma") and contains_text(shell.stats_area,"Mana regeneration"),"character sheet exposes all supported attributes and resources")
	check(contains_text(shell.stats_area,"%.1f" % p.stats().spell_power),"character sheet uses current authoritative gear-derived power")
	check(contains_text(shell.stats_area,"PRIMARY ATTRIBUTES") and contains_text(shell.stats_area,"Base "),"new character layout separates base attributes from gear contributions")
	check(contains_text(shell.stats_area,"Resistances") and contains_text(shell.stats_area,"not implemented"),"unsupported defenses are labeled as future systems, not fabricated")
	var cursor_before: Vector2i=shell.focus_cell
	shell.focus_step(1,0)
	check(shell.keyboard_mode and shell.focus_cell==Vector2i(mini(cursor_before.x+1,SYS.WIDTH-1),cursor_before.y),"keyboard cursor navigates backpack cells without moving any items")
	shell.focus_cell=Vector2i(SYS.WIDTH-1,SYS.HEIGHT-1)
	shell.focus_step(1,1)
	check(shell.focus_cell==Vector2i(SYS.WIDTH-1,SYS.HEIGHT-1),"focus cursor clamps to the preserved 10 by 6 backpack geometry")
	var joy:=InputEventJoypadButton.new(); joy.pressed=true; joy.button_index=JOY_BUTTON_DPAD_LEFT
	ui._input(joy)
	check(shell.focus_cell==Vector2i(SYS.WIDTH-2,SYS.HEIGHT-1),"gamepad D-pad moves the same focus cursor")
	shell.focus_cell=Vector2i(p.inventory[0].x,p.inventory[0].y)
	shell.focus_inspect()
	check(shell.pinned and shell.card.visible and ui.selected==0,"keyboard or gamepad inspect pins the real item card")
	shell.unpin(); shell.release_keyboard_cursor()
	await screenshot("03_right_docked_character")
	shell.equipment_tab.pressed.emit(); await frames()
	check(shell.tab=="equipment" and shell.stage.visible,"equipment tab restores the paper-doll layout")
	var bag: Control=shell.bag
	var data:=bag_data(0); var item: Dictionary=p.inventory[0]; var old_at:=Vector2i(item.x,item.y)
	var target:=Vector2i(-1,-1)
	for y in SYS.HEIGHT:
		for x in SYS.WIDTH:
			if Vector2i(x,y)!=old_at and SYS.fits(p.inventory,item,Vector2i(x,y),item.uid): target=Vector2i(x,y); break
		if target.x>=0: break
	check(target.x>=0 and bag._can_drop_data(Vector2(target)*bag.cell_size+Vector2(2,2),data),"dragging within bag validates actual item footprint")
	bag._drop_data(Vector2(target)*bag.cell_size+Vector2(2,2),data)
	check(Vector2i(p.inventory[0].x,p.inventory[0].y)==target,"bag drop commits the requested cell placement")
	check(bag.drop_cell(Vector2(101,101),{"grab":Vector2i(1,1)})==Vector2i(1,1),"dragged item preserves the grabbed cell offset")
	check(not bag._can_drop_data(Vector2(-2,0),data) and not bag._can_drop_data(Vector2(501,301),data),"negative and beyond-grid drops are rejected")
	check(not bag._can_drop_data(Vector2.ZERO,{"index":0}) and not bag._can_drop_data(Vector2.ZERO,{"index":0,"uid":"stale"}),"malformed and stale item tokens are rejected")
	var equipped_uid: String=p.gear.weapon.uid; var eq_data: Dictionary={"source":"equipment","slot":"weapon","uid":equipped_uid,"grab":Vector2i.ZERO}
	target=Vector2i(-1,-1)
	for y in SYS.HEIGHT:
		for x in SYS.WIDTH:
			if SYS.fits(p.inventory,p.gear.weapon,Vector2i(x,y)): target=Vector2i(x,y); break
		if target.x>=0: break
	check(target.x>=0 and bag._can_drop_data(Vector2(target)*bag.cell_size+Vector2(2,2),eq_data),"equipped item can be dragged into a fitting bag space")
	bag._drop_data(Vector2(target)*bag.cell_size+Vector2(2,2),eq_data); await frames(3)
	var idx:=index_uid(equipped_uid)
	check(p.gear.weapon==null and idx>=0 and Vector2i(p.inventory[idx].x,p.inventory[idx].y)==target,"gear-to-bag drop preserves identity and exact target position")
	check(p.hp==333 and p.mp==271,"gear transactions preserve paid resources without a refill")
	var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_RIGHT; event.pressed=true
	event.position=(Vector2(p.inventory[idx].x,p.inventory[idx].y)+Vector2(0.2,0.2))*ui.bag_view.cell_size
	ui.bag_view._gui_input(event); await frames(3)
	check(p.gear.weapon is Dictionary and p.gear.weapon.uid==equipped_uid,"right-click quick equip uses the same authoritative transaction")
	gear_slot("weapon").pressed.emit(); await frames(3)
	check(ui.inventory_shell.card.visible and contains_text(ui.inspector,"CURRENTLY EQUIPPED"),"clicking equipped gear opens its actual item card")
	check(button(ui.inspector,"Unequip to backpack")!=null,"equipped item card has a real unequip action")
	if DisplayServer.get_name()!="headless":
		ui.inventory_shell.unpin(); bag=ui.bag_view; data=bag_data(0); item=p.inventory[0]
		target=Vector2i(-1,-1)
		for y in SYS.HEIGHT:
			for x in SYS.WIDTH:
				if Vector2i(x,y)!=Vector2i(item.x,item.y) and SYS.fits(p.inventory,item,Vector2i(x,y),item.uid): target=Vector2i(x,y); break
			if target.x>=0: break
		bag.force_drag(data,ui.item_drag_preview(item))
		check(root.gui_is_dragging(),"native Godot drag lifecycle starts with the real item token")
		var point: Vector2=bag.get_global_transform_with_canvas()*(Vector2(target)*bag.cell_size+Vector2(4,4))
		point=root.get_final_transform()*point
		Input.warp_mouse(point); await frames(3)
		var release:=InputEventMouseButton.new(); release.button_index=MOUSE_BUTTON_LEFT; release.pressed=false; release.position=point; root.push_input(release,false); await frames(3)
		check(not root.gui_is_dragging() and Vector2i(p.inventory[0].x,p.inventory[0].y)==target,"native pointer drop reaches the grid and commits its cell")
	before=JSON.stringify(p.gear); p.inventory.clear()
	for i in 60: SYS.insert(p.inventory,SYS.make_item(1,0,"ring"))
	ui.open_page("inventory"); await frames()
	check(not p.unequip_item("weapon",Vector2i(0,0)) and JSON.stringify(p.gear)==before,"occupied-cell gear drop is atomic and preserves equipment")
	gear_slot("weapon").unequip(); await frames()
	check(JSON.stringify(p.gear)==before and p.inventory.size()==60,"full-backpack quick unequip preserves all sixty items")
	check(ui.status_label.text.contains("No room"),"failed unequip gives a visible reason in the right panel")
	ui.close_page(); await frames()
	check(not paused and ui.char_panel==null and ui.inventory_shell==null,"closing releases the pause state and dock reference")
	ui.open_page("inventory"); await frames(); var key:=InputEventKey.new(); key.pressed=true; key.keycode=KEY_C
	ui._input(key); await frames()
	check(ui.inventory_shell.tab=="character","C switches the open right panel to character stats")
	key.keycode=KEY_I; ui._input(key); await frames()
	check(ui.inventory_shell.tab=="equipment","I returns from character to equipment")
	ui._input(key); await frames()
	check(ui.char_panel==null and not paused,"I closes the equipment panel")
	seed(4102); screen_setup(); await open_inventory()
	var original_size:=root.size; root.size=Vector2i(1024,768); await frames(5)
	shell=ui.inventory_shell; vp=root.get_visible_rect().size; rect=Rect2(shell.dock.position,shell.dock.size*shell.dock.scale)
	check(rect.position.x>=0 and rect.end.x<=vp.x+1 and rect.end.y<=vp.y+1,"dock remains within resized four-to-three viewport")
	await screenshot("04_resized_inventory")
	root.size=original_size; await frames(5); ui._inspect(0); await frames(3)
	check(main._valid_save(main._read_save(main.SAVE_PATH)),"new UI writes a valid unchanged schema-six ownership record")
	ui.close_page(); await frames()
	print("INVENTORY UI RESULT %d checks; %d failures" % [checks,failures])
	var f:=FileAccess.open("res://tests/INVENTORY_UI_LAST_RUN.txt",FileAccess.WRITE); f.store_string("\n".join(report)+"\nINVENTORY UI RESULT %d checks; %d failures\n" % [checks,failures]);f.close()
	await main.quit_game(1 if failures else 0)
