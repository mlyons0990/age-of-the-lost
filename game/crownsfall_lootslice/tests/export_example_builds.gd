extends SceneTree
const SYS := preload("res://scripts/systems.gd")
const DATA := preload("res://scripts/game_data.gd")
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	change_scene_to_file("res://main.tscn")
	for i in 5: await process_frame
	var main: Node2D=current_scene
	var p: Node2D=main.player
	main.set_process(false);p.set_physics_process(false)
	if main.hud.start_panel!=null:
		main.hud.start_panel.queue_free();main.hud.start_panel=null;main.hud._refresh_pause()
	DirAccess.make_dir_recursive_absolute("res://data/example_builds")
	for build in ["ward_level20","bloom_level40","siphon_level40"]:
		seed(20261111)
		main.had_save=false;main.save_blocked=false;main.create_character("mage","Aster Demo")
		p.level=20 if build=="ward_level20" else 40
		p.spec="mage_fire";p.adv="" if p.level==20 else "pyromancer"
		p.discoveries=["first_echo"];p.mastery={"ward_temper":1}
		if p.level==40:
			p.mastery.ember_aura=1
			p.mastery["cinder_bloom" if build=="bloom_level40" else "siphon_embers"]=1
		p.inventory.clear();p.gold=500
		for base in ["staff","robe"]:
			var item:=SYS.make_item(p.level,0,base,"mage")
			item.uid="demo_"+build+"_"+base
			p.gear[SYS.default_slot(item)]=item
		if p.level==40:
			var unique:=SYS.make_unique();unique.uid="demo_"+build+"_emberwake"
			p.gear.helm=unique;p.crafted_uniques=[SYS.UNIQUE_ID]
		for base in ["wand","focus","wraps","slippers"]:
			var item:=SYS.make_item(p.level,0,base,"mage");item.uid="demo_"+build+"_bag_"+base
			assert(SYS.insert(p.inventory,item))
		main.merchant_stock.clear()
		for base in ["hood","belt","ring","amulet"]:
			var item:=SYS.make_item(p.level,0,base,"mage");item.uid="demo_"+build+"_vendor_"+base
			main.merchant_stock.append(item)
		p.hp=p.stats().max_hp;p.mp=p.stats().max_mp
		main.save_game()
		var saved:Dictionary=main._read_save(main.SAVE_PATH)
		assert(main._valid_save(saved),build)
		var out:=FileAccess.open("res://data/example_builds/"+build+".json",FileAccess.WRITE)
		out.store_string(JSON.stringify(saved,"  "));out.close()
	print("Exported and validated three deliberately authored demo save records.")
	await main.quit_game()
