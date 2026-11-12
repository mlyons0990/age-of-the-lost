extends "res://tests/inventory_ui_integration.gd"
const ARTWORK := preload("res://scripts/art_library.gd")

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/skill_tiles/"+name+".png")

func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main=current_scene; p=main.player; trial=main.encounter; ui=main.hud
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); trial.set_process(false)
	await physics_frame
	DirAccess.make_dir_recursive_absolute("res://previews/skill_tiles")
	var profile: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/skill_tile_profile.json"))
	check(profile.tiles.size()==20,"all nineteen base abilities and Ember Aura have full-square paintings")
	for entry in profile.selections:
		var texture:=ARTWORK.action_icon(String(entry.id)); var image:=texture.get_image()
		check(texture.resource_path==profile.tiles[entry.id] and image.get_size()==Vector2i(128,128),"%s resolves to its square runtime painting" % entry.id)
		var opaque:=true
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x,y).a<1.0: opaque=false
		check(opaque,"%s has no transparent margins or empty background pixels" % entry.id)
		check(FileAccess.get_sha256("res://"+String(entry.runtime_path))==entry.runtime_sha256,"%s matches its accepted output hash" % entry.id)
	var coverage:=true
	for id in GD.spells(): coverage=coverage and profile.tiles.has(id)
	check(coverage,"tile IDs cover the actual implemented ability registry")
	check(ARTWORK.action_icon("ui_stash")==ARTWORK.icon("ui_stash"),"service symbols retain their transparent UI artwork")
	check(ARTWORK.action_icon("unknown_tile")==ARTWORK.icon("unknown_tile"),"unknown tiles retain the original safe fallback")
	ARTWORK.tiles.clear(); ARTWORK.tile_profile={"tiles":{"slash":"res://missing_tile.png"}}
	check(ARTWORK.action_icon("slash")==ARTWORK.icon("slash"),"a missing selected tile falls back to the earlier approved symbol")
	ARTWORK.tile_profile={"tiles":[]}
	check(ARTWORK.action_icon("slash")==ARTWORK.icon("slash"),"a malformed tile map does not break action rendering")
	ARTWORK.tile_profile=profile; ARTWORK.tiles.clear()
	for class_id in ["warrior","mage"]:
		reset_actor("",class_id,40); p.mp=p.stats().max_mp; p.hp=p.stats().max_hp
		check(ui._icon(String(p.hotbar[0]))==ARTWORK.action_icon(String(p.hotbar[0])),"%s HUD uses the painted action tile" % class_id)
		check(ARTWORK.icon(String(p.hotbar[0])).resource_path.begins_with("res://assets/art_expansion02/"),"%s earlier symbol remains preserved as fallback" % class_id)
		ui.draw_ctl.queue_redraw(); await shot(class_id+"_ready")
		ui.selected_spell=String(p.hotbar[0]); ui.open_page("spells"); await frames(4)
		var skill:=button(ui.char_panel,String(GD.spells()[p.hotbar[0]].name))
		check(skill!=null and skill.icon==ARTWORK.action_icon(String(p.hotbar[0])),"%s Grimoire uses the matching painting" % class_id)
		await shot(class_id+"_grimoire"); ui.close_page()
	reset_actor("","mage",40); p.mp=0; p.cds["arcane_fold"]=4.0; p.cd_full["arcane_fold"]=8.0
	ui.draw_ctl.queue_redraw(); await shot("mage_cooldown_low_mana")
	check(p.cds.arcane_fold==4.0 and p.mp==0,"painted cooldown preview preserves actual cooldown and low-mana state")
	check(main._valid_save(main.capture_save()),"painted tiles leave a valid schema-six save")
	reset_actor("cinder_bloom","mage",40); p.mp=p.stats().max_mp
	var started: bool=p.use_skill("s3",p.position)
	check(started and p.aura.running and ui._icon("ember_aura").resource_path==profile.tiles.ember_aura,"the transformed active aura uses its own full-square painting")
	ui.draw_ctl.queue_redraw(); await shot("mage_ember_aura_on"); p.aura.stop()
	var f:=FileAccess.open("res://tests/SKILL_TILES_LAST_RUN.txt",FileAccess.WRITE)
	f.store_string("\n".join(report)+"\nSKILL TILES RESULT %d checks; %d failures\n" % [checks,failures]); f.close()
	print("SKILL TILES RESULT %d checks; %d failures" % [checks,failures])
	await main.quit_game(1 if failures else 0)
