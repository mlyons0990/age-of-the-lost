extends "res://tests/reliability_integration.gd"
const RulesLoot := preload("res://scripts/loot_rules.gd")
func drop_here(kind := "item", amount := 0, base := "robe") -> Node2D:
	var item: Dictionary=SYS.make_item(40,0.5,base,"mage") if kind=="item" else {}
	var drop: Node2D=main._drop(p.position,kind,amount,item)
	drop.position=p.position+GD.to_px(Vector2(0.45,0)); drop.age=2; drop.set_process(false); return drop
func loot_fixture() -> void:
	main.save_store=Store.new(); await fixture(); ui.close_page(); await frames(3)
	main.loot_notice=""; main.pickup_notice_until=0; main.pickup_clock=0
	ui.toasts.clear(); ui.banner_t=99; main.fx_text.items.clear()
	p.inventory.clear(); p.gold=100; p.potions=2
func loot_shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/loot/"+name+".png")
func owned_count(uid: String) -> int:
	var count:=0
	for item in p.inventory:
		if item.uid==uid: count+=1
	for drop in main.loot:
		if drop.kind=="item" and drop.item.uid==uid: count+=1
	return count
func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main=current_scene; p=main.player; trial=main.encounter; ui=main.hud; path=main.SAVE_PATH
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); trial.set_process(false); await physics_frame
	DirAccess.make_dir_recursive_absolute("res://previews/loot")
	seed(9301); await loot_fixture()
	var drop:=drop_here(); var uid: String=drop.item.uid
	var baseline: Dictionary=main.capture_save()
	check(baseline.schema==6 and baseline.ground_loot.size()==1 and main._valid_save(baseline),"schema six captures valid uncollected ground ownership")
	var copy:=baseline.duplicate(true); copy.erase("ground_loot")
	check(not main._valid_save(copy),"schema six requires its ground container")
	copy=baseline.duplicate(true); copy.schema=5; copy.erase("ground_loot")
	check(main._valid_save(copy),"schema-five records remain valid imports without ground data")
	var malformed: Array=[{"kind":"unknown"},{"uid":""},{"amount":1},{"x":INF},{"x":-1000},{"y":NAN},{"kind":"gold","item":{},"amount":0},{"kind":"gold","item":{},"amount":0.5},{"kind":"potion","item":{},"amount":6},{"kind":"potion","item":{},"amount":"1"}]
	for patch in malformed:
		copy=baseline.duplicate(true); copy.ground_loot[0].merge(patch,true)
		check(not main._valid_save(copy),"validator rejects malformed ground record: "+str(patch.keys()))
	for item_patch in [{"rarity":99},{"rarity":-1},{"rarity":0.5},{"name":3},{"level":0},{"uid":""}]:
		copy=baseline.duplicate(true); copy.ground_loot[0].item.merge(item_patch,true)
		check(not main._valid_save(copy),"floor validation rejects unsafe item display fields: "+str(item_patch.keys()))
	copy=baseline.duplicate(true); copy.ground_loot.append(copy.ground_loot[0].duplicate(true))
	check(not main._valid_save(copy),"duplicate drop identities are rejected")
	copy=baseline.duplicate(true); var duplicate: Dictionary=copy.ground_loot[0].duplicate(true); duplicate.uid="different-drop"; copy.ground_loot.append(duplicate)
	check(not main._valid_save(copy),"different drop records cannot own the same item UID")
	copy=baseline.duplicate(true); copy.inventory.append(copy.ground_loot[0].item.duplicate(true)); copy.inventory[0].x=0; copy.inventory[0].y=0
	check(not main._valid_save(copy),"backpack and floor cannot both own one item UID")
	copy=baseline.duplicate(true); copy.ground_loot[0].item=p.gear.weapon.duplicate(true)
	check(not main._valid_save(copy),"equipped and ground item ownership are disjoint")
	copy=baseline.duplicate(true); copy.ground_loot[0].item=main.merchant_stock[0].duplicate(true)
	check(not main._valid_save(copy),"merchant and floor cannot share item ownership")
	var before:=JSON.stringify(baseline); var plan: Dictionary=RulesLoot.collect(p.inventory,p.gold,p.potions,drop.record())
	check(plan.ok and JSON.stringify(main.capture_save())==before,"collection planning cannot mutate actor or ground records")
	install_memory(baseline); var hp: float=p.hp; var mp: float=p.mp
	check(main._pick_up(drop) and Actions.find_uid(p.inventory,uid)>=0 and main.loot.is_empty(),"successful pickup transfers ownership once and removes the exact drop")
	check(JSON.parse_string(disk.files[path]).ground_loot.is_empty() and owned_count(uid)==1 and p.hp==hp and p.mp==mp,"committed pickup keeps disk/live ownership and paid resources consistent")
	before=live(); check(not main._pick_up(drop) and live()==before,"repeated pickup of a queued drop cannot duplicate items")
	await loot_fixture(); drop=drop_here("gold",20); p.gold=RulesLoot.GOLD_CAP-3; install_memory(main.capture_save())
	check(main._pick_up(drop) and p.gold==RulesLoot.GOLD_CAP and drop.amount==17 and main.loot.has(drop),"gold cap collects only available room and preserves the remainder")
	check(main.loot_notice=="Collected 3 gold","partial pickup reports only the amount actually collected")
	check(JSON.parse_string(disk.files[path]).ground_loot[0].amount==17,"partial gold remainder is committed with the wallet")
	before=live(); check(not main._pick_up(drop) and live()==before,"full wallet leaves the remaining pile unchanged")
	await loot_fixture(); drop=drop_here("potion",3); p.potions=4; install_memory(main.capture_save())
	check(main._pick_up(drop) and p.potions==5 and drop.amount==2,"potion stack collects only available capacity")
	before=live(); check(not main._pick_up(drop) and live()==before,"full potion stack preserves floor quantity")
	await loot_fixture(); drop=drop_here("item",0,"staff")
	for i in 59: SYS.insert(p.inventory,SYS.make_item(1,0,"ring"))
	before=live(); var age: float=drop.age
	check(not main._pick_up(drop) and live()==before and drop.age==age,"fragmented/full bag preserves both item ownership and animation age")
	check(main.loot_notice.contains("2 × 4"),"failed pickup reports the actual contiguous footprint needed")
	main._process(0.1); var toast_count: int=ui.toasts.size(); main._process(0.1)
	check(drop.age==age and drop.retry_at>main.pickup_clock and ui.toasts.size()==toast_count,"automatic retry uses a separate cooldown without replaying arrival or spamming notices")
	for fault in [["open",".tmp"],["flush",".tmp"],["copy",".bak.pending"],["rename","_v4.json"]]:
		await loot_fixture(); drop=drop_here(); install_memory(main.capture_save()); disk.fault_op=fault[0]; disk.fault_suffix=fault[1]; before=live(); var original: String=disk.files[path]
		check(not main._pick_up(drop),"failed %s rejects pickup" % fault[0])
		check(live()==before and disk.files[path]==original and main.loot.has(drop),"failed %s preserves item, floor record, currency and committed primary" % fault[0])
	await loot_fixture(); drop=drop_here(); uid=drop.item.uid; install_memory(main.capture_save()); disk.fault_op="rename"; disk.fault_suffix="_v4.json"
	check(not main._pick_up(drop),"failed collection exposes the current save error")
	disk.fault_op=""; key_f5()
	check(main.loot.size()==1 and p.inventory.is_empty() and JSON.parse_string(disk.files[path]).ground_loot.size()==1,"F5 retry saves current floor ownership without replaying rejected pickup")
	check(main.collect_drop(drop.uid) and owned_count(uid)==1,"explicit pickup succeeds after storage recovery")
	await loot_fixture(); drop=drop_here(); install_memory(main.capture_save()); disk.fault_op="rename"; disk.fault_suffix=".bak"
	check(main._pick_up(drop) and p.inventory.size()==1 and not main.save_warning.is_empty(),"post-commit backup warning applies the already-saved pickup once")
	await loot_fixture(); drop=drop_here(); main.save_blocked=true; before=live()
	check(not main._pick_up(drop) and live()==before,"protected-save mode cannot consume ground loot")
	main.save_blocked=false; p.dead=true; before=live()
	check(not main._pick_up(drop) and live()==before,"dead actor cannot claim a drop")
	p.dead=false; drop.position=main.START+GD.to_px(Vector2(4,0)); before=live()
	check(not main.collect_drop(drop.uid) and live()==before,"stale distant callbacks cannot remotely collect loot")
	await loot_fixture(); drop=drop_here(); uid=drop.item.uid; drop_here("gold",23).position=p.position+GD.to_px(Vector2(0.6,0.1)); drop_here("potion",1).position=p.position+GD.to_px(Vector2(-0.6,0))
	check(main.save_game(),"real disk saves mixed floor drops")
	var records: String=JSON.stringify(main.ground_snapshot()); var old_drop: Node2D=drop
	main.clear_ground_loot(); var loaded: bool=main.load_game()
	check(loaded and JSON.parse_string(JSON.stringify(main.ground_snapshot()))==JSON.parse_string(records),"real reload restores stable drop IDs, positions, item UIDs and quantities")
	check(not main._pick_up(old_drop) and main.loot.size()==3,"pre-reload node reference cannot collect the replacement record")
	check(main.loot.all(func(d: Node2D) -> bool: return d.age>=1),"restored loot does not replay its arrival animation")
	main.loot_notice=""; ui.toasts.clear(); ui.banner_t=99; main.fx_text.items.clear()
	ui.open_page("loot"); await frames(3)
	check(paused and ui.inventory_active() and ui.inventory_shell.stage.visible and ui.inventory_shell.service.rows.get_child_count()==3,"nearby loot and actual equipment/backpack are paired in one paused view")
	var committed_hash:=FileAccess.get_sha256(path); before=live(); var ground: Node2D=main.loot[0]
	ui.inventory_shell.show_external_item(ground.item,"ground:"+String(ground.uid),true); await frames(3)
	check(contains_text(ui.inspector,"IF EQUIPPED") and button(ui.inspector,"Collect to backpack")!=null,"ground item comparison is pure and has an explicit Collect action")
	check(live()==before and FileAccess.get_sha256(path)==committed_hash,"ground inspection changes no owned state or save bytes")
	await loot_shot("01_nearby_loot_comparison")
	var old_uid: String=ground.uid
	check(ui.collect_loot(old_uid) and p.inventory.size()==1 and main.loot.size()==2,"Collect button transfers the selected ground record into the real bag")
	await frames(3); await loot_shot("02_collected_item")
	before=live(); check(not ui.collect_loot(old_uid) and live()==before,"repeated Collect callback cannot duplicate its item")
	ui.close_page(); await frames(3); before=live()
	check(not ui.collect_loot(main.loot[0].uid) and live()==before,"closed nearby-loot page rejects stale UI actions")
	var event:=InputEventKey.new(); event.keycode=KEY_N; event.pressed=true; ui._input(event); await frames(3)
	check(ui.page=="loot" and paused,"N opens nearby loot through the actual HUD shortcut")
	ui._input(event); await frames(3); main.rift.active=true; ui.open_page("loot")
	check(ui.page!="loot" and not paused,"combat blocks opening the collection modal without blocking automatic pickup")
	main.rift.active=false
	# Exact schema-five upgrade preservation on real disk.
	var legacy: Dictionary=main.capture_save(); legacy.schema=5; legacy.erase("ground_loot")
	var file:=FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(legacy,"  ")); file.close(); var legacy_hash:=FileAccess.get_sha256(path)
	check(main.load_game() and main.loot.is_empty(),"schema-five import starts with an empty floor without changing the actor")
	check(main.save_game() and main._read_save(path).schema==6 and FileAccess.get_sha256(path+".pre-v6")==legacy_hash,"first upgrade preserves exact schema-five bytes before writing schema six")
	p.gold+=1; main.save_game()
	check(FileAccess.get_sha256(path+".pre-v6")==legacy_hash,"later saves never overwrite the pre-v6 recovery snapshot")
	await loot_fixture(); drop=drop_here(); install_memory(main.capture_save()); disk.files[path]=JSON.stringify(legacy); disk.fault_op="rename"; disk.fault_suffix=".pre-v6"; before=live(); var primary: String=disk.files[path]
	check(not main._pick_up(drop) and live()==before and disk.files[path]==primary,"failed pre-v6 snapshot blocks collection without touching the old primary")
	# Floor drops and exact paid resources survive the actual independent lab.
	main.save_store=Store.new(); main.save_error=""; main.save_blocked=false; ui.close_page(); await frames(3)
	p.position=main.START
	for d in main.loot: d.position=main.START+GD.to_px(Vector2(0.5,0))
	records=JSON.stringify(main.ground_snapshot()); hp=p.hp; mp=p.mp
	main._enter_articulation_lab(); await scene_changed
	check(current_scene is Node3D,"saved floor records allow guarded F7 entry")
	current_scene._back_to_plaza(); await scene_changed
	main=current_scene; p=main.player; ui=main.hud; trial=main.encounter
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); trial.set_process(false)
	check(JSON.parse_string(JSON.stringify(main.ground_snapshot()))==JSON.parse_string(records) and p.hp==hp and p.mp==mp,"actual F7 round trip preserves ground ownership and current paid resources")
	await frames(3); ui.open_page("loot"); await frames(3); await loot_shot("03_returned_ground_loot")
	# Bounded world ledger reserves a complete wave before allowing new spawns.
	ui.close_page(); await frames(3); main.clear_ground_loot()
	var item:=SYS.make_item(40,0.2,"ring"); var rec: Dictionary={"uid":"budget","kind":"gold","amount":1,"item":{},"x":main.START.x,"y":main.START.y}
	for i in RulesLoot.MAX_DROPS-RulesLoot.WAVE_RESERVE+1:
		rec.uid="budget-%d" % i; var d: Node2D=main.spawn_drop_record(rec,true); d.set_process(false)
	main.toggle_rift()
	check(not main.rift.active,"near-cap ledger rejects new Scar before reserving an unsafe wave")
	main.rift.active=true; main.spawn_wave()
	check(not main.rift.active and main.enemies.is_empty(),"automatic next-wave guard stops before creating enemies or excess rewards")
	for i in RulesLoot.WAVE_RESERVE-1:
		rec.uid="extra-%d" % i; var d: Node2D=main.spawn_drop_record(rec,true); d.set_process(false)
	check(main.loot.size()==RulesLoot.MAX_DROPS and not trial.start(),"full ledger rejects a new Cantor reward before combat starts")
	check(main._valid_save(main.capture_save()),"maximum-sized legal floor remains saveable")
	copy=main.capture_save(); copy.ground_loot.append(rec.duplicate(true))
	check(not main._valid_save(copy),"oversized serialized floor is rejected")
	before=live(); check(main._drop(main.START,"item",0,item)==null and live()==before,"internal drop API returns capacity failure without changing existing records")
	main.clear_ground_loot(); var off_floor: Node2D=main._drop(Vector2.ZERO,"item",0,item)
	check(main._valid_floor_point(off_floor.position) and main._valid_save(main.capture_save()),"empty/unready navigation cannot strand a drop at the world origin")
	main.clear_ground_loot(); await frames(3); ui.open_page("loot"); await frames(3)
	check(contains_text(ui.inventory_shell.service.rows,"No drops within reach"),"empty nearby-loot page has a readable state")
	await loot_shot("04_empty_nearby_loot")
	print("LOOT RESULT %d checks; %d failures" % [checks,failures])
	file=FileAccess.open("res://tests/LOOT_LAST_RUN.txt",FileAccess.WRITE); file.store_string("\n".join(report)+"\nLOOT RESULT %d checks; %d failures\n" % [checks,failures]); file.close()
	await main.quit_game(1 if failures else 0)
