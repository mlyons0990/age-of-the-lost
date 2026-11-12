extends "res://tests/inventory_ui_integration.gd"
const ARTWORK := preload("res://scripts/art_library.gd")

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/art_integration/"+name+".png")

func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main=current_scene; p=main.player; trial=main.encounter; ui=main.hud
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); trial.set_process(false)
	await physics_frame
	DirAccess.make_dir_recursive_absolute("res://previews/art_integration")
	var profile:=ARTWORK.profile().duplicate(true)
	check(profile.portraits.size()==12,"twelve selected equipment variants are registered")
	check(profile.icons.size()==30,"nineteen skill and eleven service icons are registered")
	check(GD.spells().size()==19,"runtime ability coverage comes from all nineteen implemented definitions")
	for id in GD.spells():
		var texture:=ARTWORK.icon(id)
		check(texture!=null and texture.get_size()==Vector2(128,128) and texture.resource_path.begins_with("res://assets/art_expansion02/"),"implemented ability %s loads its selected icon" % id)
	for id in profile.icons:
		if not String(id).begins_with("ui_"): continue
		var texture:=ARTWORK.icon(id)
		check(texture!=null and texture.get_size()==Vector2(128,128) and texture.resource_path==profile.icons[id],"service artwork %s resolves without fallback" % id)
	for id in profile.portraits:
		var texture:=ARTWORK.inventory_portrait(id)
		check(texture!=null and texture.get_size()==Vector2(SYS.footprint({"slot":id}))*64 and texture.resource_path==profile.portraits[id],"selected %s portrait preserves authoritative inventory dimensions" % id)
	check(ARTWORK.icon("unknown_art_id").resource_path.ends_with("amulet.svg"),"unknown artwork remains readable through vector fallback")
	ARTWORK.icons.clear(); ARTWORK.portraits.clear()
	ARTWORK.selected_profile={"icons":{"slash":"res://assets/missing_selected_icon.png"},"portraits":{"weapon":"res://assets/missing_selected_portrait.png"}}
	check(ARTWORK.icon("slash").resource_path.ends_with("slash.svg"),"a missing selected icon falls back to its original vector")
	check(ARTWORK.inventory_portrait("weapon").resource_path=="res://assets/item_portraits/weapon.png","a missing selected portrait falls back to the preserved original")
	ARTWORK.selected_profile=profile; ARTWORK.icons.clear(); ARTWORK.portraits.clear()
	for class_id in ["warrior","mage"]:
		reset_actor("",class_id,40)
		var bases: Array=["weapon","offhand","armor","helm","gloves","boots","belt","ring"] if class_id=="warrior" else ["wand","focus","robe","hood","wraps","slippers","belt","ring"]
		for base in bases:
			var slot: String={"weapon":"weapon","wand":"weapon","focus":"offhand","robe":"armor","hood":"helm","wraps":"gloves","slippers":"boots","ring":"ring1"}.get(base,base)
			p.gear[slot]=SYS.make_item(40,0.4,base,class_id)
		for base in ["weapon","armor","helm","ring"] if class_id=="warrior" else ["staff","hood","robe","ring"]:
			SYS.insert(p.inventory,SYS.make_item(40,0.4,base,class_id))
		await open_inventory()
		for slot in p.gear:
			if not p.gear[slot] is Dictionary: continue
			var item: Dictionary=p.gear[slot]; var widget:=gear_slot(slot)
			var rect: Rect2=widget.art_rect(item); var texture: Texture2D=ui._item_portrait(item)
			check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=widget.size.x and rect.end.y<=widget.size.y-20 and is_equal_approx(rect.size.x/rect.size.y,texture.get_size().x/texture.get_size().y),"%s %s fitted equipment art keeps aspect and caption clearance" % [class_id,slot])
		check(ui._item_icon(p.gear.weapon)==ui._item_portrait(p.gear.weapon),"%s equipment and backpack share the same selected artwork" % class_id)
		check(ui.inventory_shell.equipment_tab.icon==ARTWORK.icon("ui_inventory") and ui.inventory_shell.character_tab.icon==ARTWORK.icon("ui_character"),"%s right-panel tabs show the selected service symbols" % class_id)
		await shot(class_id+"_inventory")
		ui.inventory_shell.show_bag_item(0,true); await frames(3)
		var equip:=button(ui.inspector,"Equip →")
		check(equip!=null and equip.icon==ARTWORK.icon("ui_equip"),"%s real equipment action retains its selected symbol" % class_id)
		await shot(class_id+"_comparison")
		ui.close_page(); ui.selected_spell="arcane_fold" if class_id=="mage" else "cleave"; ui.open_page("spells"); await frames(4)
		var skill_button:=button(ui.char_panel,"Arcane Fold" if class_id=="mage" else "Cleave")
		check(skill_button!=null and skill_button.icon==ARTWORK.icon(ui.selected_spell),"%s Grimoire list uses the selected active ability icon" % class_id)
		await shot(class_id+"_grimoire"); ui.close_page()
	reset_actor("","mage",40); p.discoveries=[]
	ui.open_page("lore"); await frames(3)
	var recover:=button(ui.char_panel,"Lorecast:")
	check(recover!=null and recover.icon==ARTWORK.icon("ui_interact"),"existing Lorecast action shows the interaction symbol")
	if recover!=null: recover.pressed.emit()
	await frames(4)
	var craft:=button(ui.char_panel,"Attune Emberwake")
	check(p.discoveries.has("first_echo") and craft!=null and craft.icon==ARTWORK.icon("ui_blacksmith"),"decorated discovery callback still commits and reveals the crafting symbol")
	ui.close_page()
	check(ARTWORK.inventory_portrait(SYS.UNIQUE_ID).resource_path=="res://assets/item_portraits/emberwake_circlet.png","unique circlet retains its original dedicated portrait")
	check(main._valid_save(main.capture_save()),"art selection leaves a valid schema-six gameplay save")
	var f:=FileAccess.open("res://tests/SELECTED_ART_LAST_RUN.txt",FileAccess.WRITE)
	f.store_string("\n".join(report)+"\nSELECTED ART RESULT %d checks; %d failures\n" % [checks,failures]); f.close()
	print("SELECTED ART RESULT %d checks; %d failures" % [checks,failures])
	await main.quit_game(1 if failures else 0)
