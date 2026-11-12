extends "res://tests/town_ui_integration.gd"
const LAYOUT := [["weapon",0,0],["armor",1,0],["staff",3,0],["ring",5,0],["amulet",6,0],["belt",7,0],["helm",7,1],["gloves",5,1],["wand",5,3],["focus",6,3],["boots",7,3],["robe",0,3],["ring",9,5]]
func grid_fixture() -> void:
	reset_actor("","warrior",40); p.hero_name="Wayfarer"; p.hp=333; p.mp=170; p.gold=1280
	main.merchant_stock.clear(); main.buyback_stock.clear()
	for row in LAYOUT:
		var item:=SYS.make_item(40,0.4,row[0]); item.x=row[1]; item.y=row[2]; p.inventory.append(item)
	for base in ["weapon","offhand","armor","helm","gloves","belt","boots","amulet"]: p.gear[base]=SYS.make_item(40,0.4,base)
	p.gear.ring1=SYS.make_item(40,0.4,"ring"); p.gear.ring2=SYS.make_item(40,0.4,"ring")
	for base in ["hood","wraps","slippers","focus","wand"]: SYS.insert(p.stash,SYS.make_item(40,0.6,base,"mage"))
	SYS.insert(p.stash,SYS.make_unique()); p.position=main.SERVICES.stash.pos
	ui.inventory_query=""; ui.stash_query=""; ui.stash_category="all"
	ui.open_page("stash"); await frames(3)
func grid_shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/grid/"+name+".png")
func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main=current_scene; p=main.player; trial=main.encounter; ui=main.hud
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); trial.set_process(false); await physics_frame
	DirAccess.make_dir_recursive_absolute("res://previews/grid")
	seed(8201); await grid_fixture()
	check(main._valid_save(main.capture_save()),"mixed footprint display fixture is a valid actor and real ownership state")
	var bag: Control=ui.inventory_shell.bag; var stash: Control=ui.inventory_shell.service.grid
	check(bag.cell_size==stash.cell_size and bag.size==Vector2(10,6)*bag.cell_size,"backpack and stash use the same real ten-by-six cell geometry")
	for row in LAYOUT:
		var index: int=Actions.find_uid(p.inventory,p.inventory[LAYOUT.find(row)].uid)
		var item: Dictionary=p.inventory[index]; var span:=SYS.footprint(item)
		var rect:=Rect2(Vector2(item.x,item.y)*bag.cell_size,Vector2(span)*bag.cell_size)
		var art: Rect2=ui.item_art_rect(item,rect.grow(-2)); var tex: Texture2D=ui._item_portrait(item)
		check(rect.encloses(art) and is_equal_approx(art.size.x/art.size.y,tex.get_size().x/tex.get_size().y),"%s art preserves aspect ratio inside exactly its occupied cells" % item.slot)
		check(bag.index_at(rect.end-Vector2.ONE)==index,"%s can be inspected from its last occupied cell" % item.slot)
	var sword: Dictionary=p.inventory[0]; var sword_uid: String=sword.uid
	check(SYS.footprint(sword)==Vector2i(1,3) and bag.index_at(Vector2(25,125))==0,"one-handed sword is vertical and its third cell selects the same UID")
	check(bag.index_at(Vector2(25,175))!=0 and bag.index_at(Vector2(75,25))!=0,"sword cannot claim a fourth row or second column")
	check(bag.index_at(Vector2(275,25))==3 and bag.index_at(Vector2(325,25))==4,"ring and amulet each resolve from their own one-by-one cell")
	check(bag.index_at(Vector2(275,75))!=3 and bag.index_at(Vector2(325,75))!=4,"jewellery has no second-row hit area")
	var art: Rect2=ui.item_art_rect(sword,Rect2(0,0,50,150).grow(-2))
	var texture: Texture2D=ui._item_portrait(sword); var used: Rect2=texture.get_image().get_used_rect()
	var visible_top: float=art.position.y+used.position.y/texture.get_height()*art.size.y
	var visible_bottom: float=art.position.y+used.end.y/texture.get_height()*art.size.y
	check(visible_top<50 and visible_bottom>100,"sword silhouette visibly reaches all three vertical cell rows")
	var circlet:=SYS.make_unique()
	check(SYS.footprint(circlet)==Vector2i(2,2) and ui._item_portrait(circlet).get_size()==Vector2(128,128),"unique circlet uses the hood's same two-by-two footprint and portrait")
	var token:=bag_data(0); token.grab=Vector2i(0,2)
	var before:=state_hash()
	check(not bag._can_drop_data(Vector2(75,125),token),"third-cell sword drag cannot overlap chest armour")
	bag._drop_data(Vector2(75,125),token)
	check(state_hash()==before,"rejected overlap preserves every item coordinate and UID")
	check(not bag._can_drop_data(Vector2(475,325),token),"bottom-grab sword cannot extend past the final row")
	check(not stash._can_drop_data(Vector2(25,125),token),"cross-container validation rejects a sword over occupied stash cells")
	check(stash._can_drop_data(Vector2(475,225),token),"cross-container validation accepts a complete free one-by-three rectangle")
	ui.inventory_shell.show_bag_item(0,true); await frames(3)
	check(contains_text(ui.inspector,"1 × 3 cells"),"sword inspector reports width then height")
	await grid_shot("01_sword_and_paired_grids")
	ui.inventory_shell.unpin()
	for size in [Vector2i(1280,720),Vector2i(1440,810),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(960,720)]:
		root.size=size; await frames(4); ui.inventory_shell.layout(); bag=ui.inventory_shell.bag; stash=ui.inventory_shell.service.grid
		var pixels: Vector2=bag.get_global_transform_with_canvas().get_scale().abs()*bag.cell_size
		var grab:=Vector2(12.5,112.5); var preview: Control=ui.item_drag_preview(sword,bag,grab)
		check(preview.size.is_equal_approx(Vector2(1,3)*pixels),"sword drag ghost matches displayed grid cells at %s" % size)
		check(preview.get_child(0).position.is_equal_approx(-grab*bag.get_global_transform_with_canvas().get_scale().abs()),"drag ghost keeps its exact third-cell picked pixel at %s" % size)
		preview.free()
		preview=ui.item_drag_preview(sword,stash,grab)
		check(preview.size.is_equal_approx(Vector2(1,3)*stash.get_global_transform_with_canvas().get_scale().abs()*stash.cell_size),"stash uses its own effective drag scale at %s" % size)
		preview.free()
		var rect:=Rect2(ui.inventory_shell.dock.position,ui.inventory_shell.dock.size*ui.inventory_shell.dock.scale); var vp:=root.get_visible_rect().size
		check(rect.position.x>=vp.x*0.5 and rect.end.x<=vp.x and rect.end.y<=vp.y,"exact item display stays within the right dock at %s" % size)
		if size==Vector2i(960,720): await grid_shot("02_four_three_cells")
	root.size=Vector2i(1440,810); await frames(4); ui.inventory_shell.layout(); bag=ui.inventory_shell.bag
	var destination:=Vector2(475,125)
	if DisplayServer.get_name()!="headless":
		var grab:=Vector2(12.5,112.5); var preview: Control=ui.item_drag_preview(sword,bag,grab)
		bag.force_drag(token,preview); await frames(2)
		check(root.gui_is_dragging(),"native drag starts from the sword's third cell")
		var logical: Vector2=bag.get_global_transform()*destination
		Input.warp_mouse(root.get_final_transform()*logical); await frames(5)
		await grid_shot("03_native_sword_drag")
		var released:=InputEventMouseButton.new(); released.button_index=MOUSE_BUTTON_LEFT; released.pressed=false; released.position=root.get_final_transform()*logical
		root.push_input(released,false); await frames(5)
		check(not root.gui_is_dragging() and Vector2i(p.inventory[0].x,p.inventory[0].y)==Vector2i(9,0),"native bottom-grab drop commits the sword anchor without an offset error")
	else:
		bag._drop_data(destination,token)
	var saved: Dictionary=main._read_save(main.SAVE_PATH)
	check(p.inventory[0].uid==sword_uid and saved.inventory[0].uid==sword_uid and saved.inventory[0].x==9 and saved.inventory[0].y==0,"legal drag saves the same sword UID at its exact requested anchor")
	check(bag.index_at(Vector2(475,125))==0 and bag.index_at(Vector2(475,175))!=0,"moved sword's hit area follows exactly three rows")
	var count: int=p.inventory.size(); var gold: int=p.gold
	ui.town_action("deposit",sword_uid,Vector2i(9,2)); await frames(3)
	check(p.inventory.size()==count-1 and p.stash[-1].uid==sword_uid and Vector2i(p.stash[-1].x,p.stash[-1].y)==Vector2i(9,2),"exact stash transfer retains the full sword rectangle and identity")
	check(main.save_game() and main.load_game() and p.gold==gold and p.stash[-1].uid==sword_uid,"save reload preserves mixed footprints and town ownership without currency changes")
	ui.refresh_inventory(); await frames(3); await grid_shot("04_saved_stash_sword")
	print("GRID ALIGNMENT RESULT %d checks; %d failures" % [checks,failures])
	var file:=FileAccess.open("res://tests/GRID_ALIGNMENT_LAST_RUN.txt",FileAccess.WRITE); file.store_string("\n".join(report)+"\nGRID ALIGNMENT RESULT %d checks; %d failures\n" % [checks,failures]); file.close()
	await main.quit_game(1 if failures else 0)
