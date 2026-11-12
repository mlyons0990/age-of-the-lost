extends "res://tests/inventory_ui_integration.gd"
const Actions := preload("res://scripts/town_actions.gd")
func fixture(kind := "stash") -> void:
	screen_setup(); main.buyback_stock.clear(); main.merchant_stock.clear()
	ui.inventory_query=""; ui.stash_query=""; ui.stash_category="all"; ui.shop_query=""; ui.shop_mode="stock"; ui.service_notice=""
	for base in ["wand","focus","hood","robe","ring"]: main.merchant_stock.append(SYS.make_item(40,0.7,base,"mage"))
	p.position=main.SERVICES[kind].pos
	ui.open_page(kind); await frames(3)
func state_hash() -> String: return JSON.stringify(ui.town_state())
func town_shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/town/"+name+".png")
func current_grid(source_id: String) -> Control:
	return ui.inventory_shell.bag if source_id=="inventory" else ui.inventory_shell.service.grid
func click_transfer(source_id: String, index: int) -> void:
	var grid:=current_grid(source_id); var items: Array=p.inventory if source_id=="inventory" else p.stash
	var e:=InputEventMouseButton.new(); e.pressed=true; e.button_index=MOUSE_BUTTON_LEFT; e.ctrl_pressed=true
	e.position=(Vector2(items[index].x,items[index].y)+Vector2(0.2,0.2))*grid.cell_size
	grid._gui_input(e); await frames(3)
func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main=current_scene; p=main.player; trial=main.encounter; ui=main.hud
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); trial.set_process(false); await physics_frame
	DirAccess.make_dir_recursive_absolute("res://previews/town")
	seed(5101); await fixture()
	var shell: Control=ui.inventory_shell; var left: Control=shell.service.frame
	var vp:=root.get_visible_rect().size
	var lr:=Rect2(left.position,left.size*left.scale); var rr:=Rect2(shell.dock.position,shell.dock.size*shell.dock.scale)
	check(paused and ui.page=="stash" and lr.end.x<rr.position.x,"stash and real equipment/inventory occupy separate left/right panes")
	check(lr.position.x>=0 and rr.end.x<=vp.x and lr.end.y<=vp.y,"both service panes fit the viewport")
	check(shell.stage.visible and shell.bag.visible and shell.service.grid.visible,"equipment and both real container grids are reachable together")
	var id: String=p.inventory[0].uid; var before:=state_hash(); var plan:=Actions.plan(ui.town_state(),"deposit",id)
	check(plan.ok and state_hash()==before,"town planning cannot mutate actor ownership or currency")
	await click_transfer("inventory",0)
	check(Actions.find_uid(p.inventory,id)<0 and Actions.find_uid(p.stash,id)>=0,"Ctrl-click deposits the same item UID into stash")
	check(ui.page=="stash" and is_instance_valid(ui.inventory_shell.service),"transfer rebuild preserves service context")
	await click_transfer("stash",0)
	check(Actions.find_uid(p.inventory,id)>=0 and p.stash.is_empty(),"Ctrl-click withdraw reverses ownership without duplicating it")
	check(p.hp==333 and p.mp==271,"town transfers preserve current paid resources")
	var index:=Actions.find_uid(p.inventory,id); var data: Dictionary={"source":"inventory","index":index,"uid":id,"grab":Vector2i.ZERO}
	var stash_grid:=current_grid("stash")
	check(stash_grid._can_drop_data(Vector2(152,52),data),"cross-container drag validates item footprint at exact cells")
	stash_grid._drop_data(Vector2(152,52),data); await frames(3)
	var si:=Actions.find_uid(p.stash,id)
	check(si>=0 and Vector2i(p.stash[si].x,p.stash[si].y)==Vector2i(3,1),"stash drag commits requested coordinates")
	before=state_hash()
	check(not current_grid("inventory")._can_drop_data(Vector2.ZERO,{"source":"stash","index":si,"uid":"stale"}),"stale cross-container identity is rejected")
	check(not ui.town_action("withdraw",id,Vector2i(-1,-1)) and state_hash()==before,"explicit negative destination cannot fall back to auto-place")
	await fixture(); p.stash.clear()
	for i in 60: SYS.insert(p.stash,SYS.make_item(1,0,"ring"))
	ui.refresh_inventory(); await frames(3); id=p.inventory[0].uid; before=state_hash()
	check(not ui.town_action("deposit",id) and state_hash()==before,"full stash leaves both containers unchanged")
	check(ui.status_label.text.contains("full"),"failed transfer explains its reason in the live panel")
	await fixture(); p.stash.clear()
	for i in 59: SYS.insert(p.stash,SYS.make_item(1,0,"ring"))
	before=state_hash(); plan=Actions.plan(ui.town_state(),"deposit_matching")
	check(not plan.ok and state_hash()==before,"batch deposit is atomic even when some items would fit")
	await fixture(); ui.inventory_shell.search.text="ring"; ui.inventory_shell.search.text_changed.emit("ring")
	var matching:=0
	for item in p.inventory:
		if Actions.matches(item,"ring"): matching+=1
	check(matching>0 and not current_grid("inventory").matching(p.inventory[0]),"backpack search dims non-matching items without moving them")
	var original_count: int=p.inventory.size()
	check(ui.town_action("deposit_matching"),"matching batch deposit commits when the complete selection fits")
	await frames(3)
	check(p.stash.size()==matching and p.inventory.size()==original_count-matching and ui.inventory_query=="ring","batch uses the active backpack search and preserves that search")
	ui.inventory_shell.search.text=""; ui.inventory_shell.search.text_changed.emit("")
	check(Actions.matches(p.stash[0],"", "jewellery") and not Actions.matches(p.stash[0],"", "armour"),"category filters reflect actual item families")
	check(Actions.matches({"slot":"wand","name":"Etched Ember Wand"},"ETCHED wand") and not Actions.matches({"slot":"wand","name":"Ember Wand"},"etched wand"),"search is case-insensitive and requires each typed word")
	await fixture(); id=p.inventory[0].uid; ui.town_action("deposit",id); await frames(3)
	ui.inventory_shell.service.search.text="zzzz"; ui.inventory_shell.service.search.text_changed.emit("zzzz")
	check(current_grid("stash").index_at(Vector2(4,4))==-1 and p.stash.size()==1,"filtered stash items remain owned but cannot be picked invisibly")
	check(not current_grid("stash")._can_drop_data(Vector2(4,4),{"source":"inventory","index":0,"uid":p.inventory[0].uid}),"dimmed items still occupy and protect their cells")
	await fixture(); ui.inventory_shell.search.grab_focus(); await frames()
	var key:=InputEventKey.new(); key.pressed=true; key.keycode=KEY_I; key.unicode=105
	ui._input(key)
	check(ui.page=="stash" and ui.inventory_shell.search.has_focus(),"typing I in a search field cannot close inventory")
	key.keycode=KEY_C; ui._input(key)
	check(ui.inventory_shell.tab=="equipment","typing C in a search field cannot switch character tabs")
	key.keycode=KEY_ESCAPE; ui._input(key)
	check(ui.page=="stash" and not ui.inventory_shell.search.has_focus(),"first Escape releases text focus without closing the paired service")
	key.keycode=KEY_F; key.ctrl_pressed=true; ui._input(key)
	check(ui.inventory_shell.search.has_focus(),"Ctrl-F focuses backpack search")
	ui.inventory_shell.search.release_focus()
	await fixture("merchant"); shell=ui.inventory_shell
	check(shell.service.rows.get_child_count()==main.merchant_stock.size() and shell.stage.visible,"shop stock list and the equipped character are visible together")
	var stock: Dictionary=main.merchant_stock[0]; id=stock.uid; var price:=Actions.sale_price(stock)*3
	p.gold=maxi(p.gold,price); var gold: int=p.gold
	shell.show_external_item(stock,"stock",true); await frames(3)
	check(shell.card.visible and contains_text(ui.inspector,"IF EQUIPPED") and button(ui.inspector,"Buy for")!=null,"unowned stock has a pure gear comparison and explicit purchase action")
	before=state_hash()
	check(state_hash()==before,"viewing merchant stock changes no owned containers")
	check(ui.town_action("buy",id),"purchase accepts available stock and exact currency")
	await frames(3)
	check(p.gold==gold-price and Actions.find_uid(p.inventory,id)>=0 and Actions.find_uid(main.merchant_stock,id)<0,"purchase transfers one UID and charges exactly the displayed price")
	before=state_hash()
	check(not ui.town_action("buy",id) and state_hash()==before,"repeating a stale purchase cannot charge or duplicate items")
	await fixture("merchant"); p.gold=0; before=state_hash(); id=main.merchant_stock[0].uid
	check(not ui.town_action("buy",id) and state_hash()==before,"unaffordable purchase preserves stock and gold")
	await fixture("merchant"); p.inventory.clear()
	for i in 60: SYS.insert(p.inventory,SYS.make_item(1,0,"ring"))
	before=state_hash(); id=main.merchant_stock[0].uid
	check(not ui.town_action("buy",id) and state_hash()==before,"full bag cannot consume shop stock or gold")
	await fixture("merchant"); id=p.inventory[0].uid; gold=p.gold; var sale:=Actions.sale_price(p.inventory[0]); var count: int=p.inventory.size()
	check(ui.town_action("sell",id),"explicit sale creates a recoverable buyback record")
	await frames(3)
	check(p.inventory.size()==count-1 and p.gold==gold+sale and main.buyback_stock[-1].uid==id,"sale conserves identity and grants exactly its value")
	check(button(ui.char_panel,"Undo last sale")!=null,"a completed sale exposes a one-click undo action")
	before=state_hash()
	check(not ui.town_action("sell",id) and state_hash()==before,"duplicate sale cannot grant gold twice")
	check(ui.town_action("buyback",id),"buyback can restore the sold item")
	await frames(3)
	check(Actions.find_uid(p.inventory,id)>=0 and p.gold==gold and main.buyback_stock.is_empty(),"sell and buyback return the exact UID with zero gold profit")
	await fixture("merchant"); id=p.inventory[0].uid; ui.town_action("sell",id); await frames(3); p.gold=0; before=state_hash()
	check(not ui.town_action("buyback",id) and state_hash()==before,"unaffordable buyback preserves the recovery record")
	await fixture("merchant"); id=p.inventory[0].uid; ui.town_action("sell",id); await frames(3); p.inventory.clear()
	for i in 60: SYS.insert(p.inventory,SYS.make_item(1,0,"ring"))
	before=state_hash()
	check(not ui.town_action("buyback",id) and state_hash()==before,"full bag buyback preserves history and currency")
	await fixture("merchant"); p.gold=Actions.GOLD_CAP; before=state_hash()
	check(not ui.town_action("sell",p.inventory[0].uid) and state_hash()==before,"gold cap cannot silently consume a sale")
	await fixture("merchant"); p.potions=2; p.gold=20
	check(ui.town_action("potion") and p.potions==3 and p.gold==15,"potion transaction adds exactly one potion for five gold")
	await frames(3); p.potions=5; before=state_hash()
	check(not ui.town_action("potion") and state_hash()==before,"full potion stack is not charged")
	p.potions=2; p.gold=4; before=state_hash()
	check(not ui.town_action("potion") and state_hash()==before,"unaffordable potion cannot overdraw currency")
	await fixture("merchant"); main.rift.active=true; before=state_hash()
	check(not ui.town_action("sell",p.inventory[0].uid) and state_hash()==before,"active combat rejects service transactions")
	main.rift.active=false; main.save_blocked=true
	check(not ui.town_action("sell",p.inventory[0].uid) and state_hash()==before,"protected save rejects service transactions")
	main.save_blocked=false; p.dead=true
	check(not ui.town_action("sell",p.inventory[0].uid) and state_hash()==before,"dead actor cannot sell items")
	p.dead=false; ui.close_page(); await frames()
	check(not ui.town_action("sell",p.inventory[0].uid),"closed service rejects stale button callbacks")
	await fixture("merchant"); p.inventory.clear()
	for i in 13: SYS.insert(p.inventory,SYS.make_item(1,0,"ring"))
	var first: String=p.inventory[0].uid; var last: String=p.inventory[-1].uid
	while not p.inventory.is_empty():
		ui.town_action("sell",p.inventory[0].uid)
		await frames(1)
	check(main.buyback_stock.size()==12 and Actions.find_uid(main.buyback_stock,first)<0 and main.buyback_stock[-1].uid==last,"buyback retains exactly the newest twelve sold items")
	main.save_game(); var saved: Dictionary=main._read_save(main.SAVE_PATH)
	check(saved.schema==6 and saved.buyback_stock.size()==12 and main._valid_save(saved),"schema six persists validated buyback history")
	var copied:=saved.duplicate(true); copied.buyback_stock.append(copied.buyback_stock[0].duplicate(true))
	check(not main._valid_save(copied),"oversized buyback history is rejected")
	copied=saved.duplicate(true); copied.buyback_stock[1].uid=copied.buyback_stock[0].uid
	check(not main._valid_save(copied),"duplicate buyback ownership is rejected")
	copied=saved.duplicate(true); copied.buyback_stock[0].uid=copied.gear.weapon.uid
	check(not main._valid_save(copied),"gear and buyback cannot claim the same UID")
	copied=saved.duplicate(true); copied.buyback_stock="invalid"
	check(not main._valid_save(copied),"malformed buyback container is rejected")
	copied=saved.duplicate(true); copied.erase("buyback_stock")
	check(not main._valid_save(copied),"schema-six records require the buyback field")
	copied=saved.duplicate(true); copied.schema=4; copied.erase("buyback_stock")
	check(main._valid_save(copied),"prior schema-four inventory records remain importable")
	main.buyback_stock.clear(); p.gold=1
	check(main.load_game() and main.buyback_stock.size()==12 and main.buyback_stock[-1].uid==last and p.gold==saved.gold,"save reload restores exact buyback ownership and currency")
	ui.close_page(); await frames()
	main._enter_articulation_lab(); await scene_changed
	check(current_scene is Node3D,"schema-six actor can enter the independent rig lab")
	current_scene._back_to_plaza(); await scene_changed
	main=current_scene; p=main.player; ui=main.hud; trial=main.encounter
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); trial.set_process(false)
	check(main.buyback_stock.size()==12 and main.buyback_stock[-1].uid==last and p.gold==saved.gold,"actual scene round-trip preserves buyback history and currency")
	var f:=FileAccess.open(main.SAVE_PATH,FileAccess.WRITE); f.store_string(JSON.stringify(copied)); f.close()
	var imported: bool=main.load_game()
	var expected_ranks: Dictionary={}
	for node in copied.mastery: expected_ranks[node]=int(copied.mastery[node])
	check(imported and main.buyback_stock.is_empty() and p.mastery==expected_ranks,"schema-four migration retains mastery and starts empty buyback")
	var legacy_hash:=FileAccess.get_sha256(main.SAVE_PATH)
	main.save_game()
	check(main._read_save(main.SAVE_PATH).schema==6,"first successful save upgrades the imported record to schema six")
	check(FileAccess.file_exists(main.SAVE_PATH+".pre-v5") and FileAccess.get_sha256(main.SAVE_PATH+".pre-v5")==legacy_hash,"upgrade keeps an exact one-time pre-v5 snapshot")
	p.gold+=1; main.save_game()
	check(FileAccess.get_sha256(main.SAVE_PATH+".pre-v5")==legacy_hash,"later saves cannot overwrite the preserved pre-upgrade snapshot")
	await fixture("stash"); ui.inventory_shell.set_tab("character")
	ui.town_action("deposit",p.inventory[0].uid); await frames(3)
	check(ui.page=="stash" and ui.inventory_shell.tab=="character","service transactions preserve the open character tab")
	await fixture("merchant"); ui.inventory_shell.service.mode_tabs[1].pressed.emit(); await frames(3)
	check(ui.shop_mode=="buyback" and contains_text(ui.inventory_shell.service.rows,"Nothing sold yet"),"empty buyback has a readable state")
	ui.inventory_shell.service.mode_tabs[0].pressed.emit(); await frames()
	ui.inventory_shell.service.search.text="zzzz"; ui.inventory_shell.service.search.text_changed.emit("zzzz"); await frames()
	check(contains_text(ui.inventory_shell.service.rows,"No matching items"),"shop search exposes an empty-result state without changing stock")
	await fixture("stash"); var size_before:=root.size; root.size=Vector2i(1024,768); await frames(5)
	shell=ui.inventory_shell; vp=root.get_visible_rect().size; lr=Rect2(shell.service.frame.position,shell.service.frame.size*shell.service.frame.scale); rr=Rect2(shell.dock.position,shell.dock.size*shell.dock.scale)
	check(lr.end.x<rr.position.x and rr.end.x<=vp.x+1 and lr.end.y<=vp.y+1,"paired panes stay separate after four-to-three resizing")
	root.size=size_before; await frames(5)
	if DisplayServer.get_name()!="headless":
		var bag:=current_grid("inventory"); stash_grid=current_grid("stash"); id=p.inventory[0].uid
		data={"source":"inventory","index":0,"uid":id,"grab":Vector2i.ZERO}
		bag.force_drag(data,ui.item_drag_preview(p.inventory[0]))
		check(root.gui_is_dragging(),"native cross-panel drag starts with actual item data")
		var point: Vector2=root.get_final_transform()*(stash_grid.get_global_transform_with_canvas()*Vector2(154,54))
		Input.warp_mouse(point); await frames(3)
		var release:=InputEventMouseButton.new(); release.button_index=MOUSE_BUTTON_LEFT; release.pressed=false; release.position=point; root.push_input(release,false); await frames(4)
		si=Actions.find_uid(p.stash,id)
		check(not root.gui_is_dragging() and si>=0 and Vector2i(p.stash[si].x,p.stash[si].y)==Vector2i(3,1),"native drop survives the paired UI rebuild and transfers exact cells")
	await fixture("stash"); ui.town_action("deposit",p.inventory[0].uid); await frames(3); await town_shot("01_paired_stash")
	ui.inventory_shell.show_external_item(p.stash[0],"stash",true); await frames(3); await town_shot("02_stash_comparison")
	await fixture("merchant"); p.gold=8500; ui.refresh_inventory(); await frames(3); ui.inventory_shell.unpin()
	if DisplayServer.get_name()!="headless": Input.warp_mouse(root.get_final_transform()*Vector2(960,200))
	await frames(3); await town_shot("03_paired_merchant")
	ui.inventory_shell.show_external_item(main.merchant_stock[0],"stock",true); await frames(3); await town_shot("04_merchant_comparison")
	ui.town_action("sell",p.inventory[0].uid); await frames(3); ui.inventory_shell.service.mode_tabs[1].pressed.emit(); await frames(3); await town_shot("05_buyback")
	ui.close_page(); await frames(3)
	print("TOWN UI RESULT %d checks; %d failures" % [checks,failures])
	f=FileAccess.open("res://tests/TOWN_UI_LAST_RUN.txt",FileAccess.WRITE); f.store_string("\n".join(report)+"\nTOWN UI RESULT %d checks; %d failures\n" % [checks,failures]); f.close()
	await main.quit_game(1 if failures else 0)
