extends "res://tests/town_ui_integration.gd"
const Store := preload("res://scripts/save_store.gd")
class MemoryDisk extends RefCounted:
	var files: Dictionary={}
	var fault_op:=""
	var fault_suffix:=""
	var corrupt:=""
	var writes:=0
	func bad(operation: String, path: String) -> bool: return fault_op==operation and path.ends_with(fault_suffix)
	func exists(path: String) -> bool: return files.has(path)
	func read(path: String) -> Dictionary:
		return {"ok":files.has(path) and not bad("read",path),"text":files.get(path,"")}
	func write(path: String, content: String) -> bool:
		writes+=1
		if bad("open",path): return false
		files[path]=content.left(17) if corrupt=="write" else content
		return not bad("write",path) and not bad("flush",path)
	func copy(source: String, target: String) -> bool:
		if bad("copy",target) or not files.has(source): return false
		files[target]="damaged" if corrupt=="copy" else files[source]; return true
	func rename(source: String, target: String) -> bool:
		if bad("rename",target) or not files.has(source): return false
		files[target]=files[source]; files.erase(source); return true
	func remove(path: String) -> void: files.erase(path)
var disk: MemoryDisk
var path: String
func install_memory(data: Dictionary) -> void:
	disk=MemoryDisk.new(); disk.files[path]=JSON.stringify(data,"  "); disk.files[path+".bak"]="older recovery bytes"
	main.save_store=Store.new(); main.save_store.disk=disk
	main.save_blocked=false; main.save_error=""; main.save_warning=""
func live() -> String:
	return JSON.stringify({"save":main.capture_save(),"running":p.aura.running,"elapsed":p.aura.elapsed,"patches":p.aura.patches,"epoch":p.combat_epoch,"pending":p.pending_t})
func key_f5() -> void:
	var key:=InputEventKey.new(); key.keycode=KEY_F5; key.pressed=true; ui._input(key)
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/reliability/"+name+".png")
func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main=current_scene; p=main.player; trial=main.encounter; ui=main.hud; path=main.SAVE_PATH
	main.sound.set_muted(true); main.set_process(false); p.set_physics_process(false); trial.set_process(false); await physics_frame
	DirAccess.make_dir_recursive_absolute("res://previews/reliability")
	seed(6112); await fixture("merchant"); p.gold=50000
	var baseline: Dictionary=main.capture_save(); var proposed:=baseline.duplicate(true); proposed.gold+=7
	check(main._valid_save(baseline),"reliability fixture is a valid full schema-six record")
	seed(42); var expected:=randi(); seed(42); main._valid_save(baseline)
	check(randi()==expected,"validating existing item UIDs does not consume gameplay randomness")
	var immutable:=JSON.stringify(baseline); var snapshot: Dictionary=main.capture_save(); snapshot.inventory.clear()
	check(JSON.stringify(main.capture_save())==immutable,"save capture owns a deep snapshot rather than actor containers")
	for fault in [["open",".tmp"],["write",".tmp"],["flush",".tmp"],["read",".tmp"],["copy",".bak.pending"],["read",".bak.pending"],["rename","_v4.json"]]:
		install_memory(baseline); disk.fault_op=fault[0]; disk.fault_suffix=fault[1]
		var previous:=disk.files.duplicate(true); var result: Dictionary=main.save_store.commit(path,proposed,main._valid_save,main.SAVE_SCHEMA)
		check(not result.ok,"injected %s at %s reports failure" % [fault[0],fault[1]])
		check(disk.files==previous,"failed %s preserves primary and old recovery bytes and cleans staging" % fault[0])
	for damage in ["write","copy"]:
		install_memory(baseline); disk.corrupt=damage; var previous:=disk.files.duplicate(true)
		check(not main.save_store.commit(path,proposed,main._valid_save,main.SAVE_SCHEMA).ok and disk.files==previous,"readback rejects corrupted %s bytes without publishing" % damage)
	install_memory(baseline); disk.fault_op="read"; disk.fault_suffix="_v4.json"
	check(not main.save_game() and not main.save_blocked,"temporary primary read failure is retryable without overwriting")
	var legacy:=baseline.duplicate(true); legacy.schema=4; legacy.erase("buyback_stock")
	for fault in [["copy",".pre-v5.pending"],["read",".pre-v5.pending"],["rename",".pre-v5"]]:
		install_memory(legacy); disk.fault_op=fault[0]; disk.fault_suffix=fault[1]; var previous:=disk.files.duplicate(true)
		check(not main.save_game() and disk.files==previous,"failed upgrade snapshot %s preserves both existing records" % fault[0])
	install_memory(legacy); var original: String=disk.files[path]
	check(main.save_game() and disk.files[path+".pre-v5"]==original,"upgrade preserves exact original bytes before committing schema six")
	p.gold+=1; main.save_game()
	check(disk.files[path+".pre-v5"]==original,"later successful commits keep the one-time legacy snapshot")
	install_memory(baseline); var old: String=disk.files[path]; p.gold+=1
	check(main.save_game() and disk.files[path+".bak"]==old and JSON.parse_string(disk.files[path]).gold==p.gold,"normal save atomically publishes current state and previous-primary recovery")
	install_memory(baseline); disk.fault_op="rename"; disk.fault_suffix=".bak"; p.gold+=1
	check(main.save_game() and not main.save_warning.is_empty() and disk.files[path+".bak"]=="older recovery bytes","post-commit recovery publication failure is saved-with-warning, preserving older backup")
	check(JSON.parse_string(disk.files[path]).gold==p.gold and not disk.files.has(path+".bak.pending"),"backup warning never reports the committed primary as a failed action")
	install_memory(baseline); disk.files.erase(path)
	check(main.save_game() and disk.files.has(path) and not disk.files.has(path+".tmp"),"first save commits without requiring a previous primary")
	install_memory(baseline); disk.files[path]='{"schema":999}'
	check(not main.save_game() and main.save_blocked and disk.files[path]=='{"schema":999}',"newer on-disk save discovered during a session becomes write protected")
	var count:=disk.writes; key_f5()
	check(disk.writes==count and main.save_blocked,"manual retry cannot bypass newer-save protection")
	await frames(3)
	check(ui.save_strip.visible and ui.save_retry.disabled,"protected-state banner explains recovery and disables retry")
	install_memory(baseline); disk.files[path]="unreadable record"
	check(not main.save_game() and main.save_blocked and disk.files[path]=="unreadable record","invalid on-disk record is preserved for the loader recovery path")
	install_memory(baseline); var invalid:=baseline.duplicate(true); invalid.inventory.append(invalid.inventory[0])
	check(not main.save_store.commit(path,invalid,main._valid_save,main.SAVE_SCHEMA).ok and disk.writes==0,"invalid candidate is rejected before any write")
	for action in ["deposit","withdraw","deposit_matching","buy","sell","buyback","potion"]:
		await fixture("stash" if action in ["deposit","withdraw","deposit_matching"] else "merchant"); p.gold=50000; p.potions=2
		var uid: String=p.inventory[0].uid
		if action=="withdraw": p.stash.append(p.inventory.pop_front())
		if action=="buyback": main.buyback_stock.append(p.inventory.pop_front())
		if action=="buy": uid=main.merchant_stock[0].uid
		ui.refresh_inventory(); await frames(2)
		install_memory(main.capture_save()); disk.fault_op="rename"; disk.fault_suffix="_v4.json"
		var before:=live(); var prior: String=disk.files[path]
		check(not ui.town_action(action,uid),"failed persistence rejects %s transaction" % action)
		check(live()==before and disk.files[path]==prior,"failed %s preserves all ownership, currency, paid resources and effects" % action)
	await fixture("merchant"); p.gold=50000; ui.refresh_inventory(); await frames(3); var uid: String=main.merchant_stock[0].uid
	install_memory(main.capture_save()); disk.fault_op="open"; disk.fault_suffix=".tmp"
	var before:=live(); check(not ui.town_action("buy",uid),"failed purchase exposes a retryable save error")
	await frames(3)
	check(ui.save_strip.visible and not ui.save_retry.disabled and not ui.save_message.text.is_empty(),"storage error has a visible keyboard-reachable retry control")
	await capture("01_failed_purchase")
	disk.fault_op=""; key_f5(); await frames(3)
	check(live()==before and not ui.save_strip.visible and main.save_error.is_empty(),"F5 saves current state and clears the banner without replaying the rejected purchase")
	check(Actions.find_uid(main.merchant_stock,uid)>=0 and Actions.find_uid(p.inventory,uid)<0,"retry preserves the rejected item's original owner")
	check(ui.town_action("buy",uid) and JSON.parse_string(disk.files[path]).gold==p.gold,"explicitly repeated purchase succeeds once and matches durable currency")
	check(not ui.town_action("buy",uid),"stale callback after successful retry cannot purchase twice")
	await frames(3); await capture("02_recovered_purchase")
	await fixture(); ui.close_page(); await frames(3); p.use_skill("s3",p.position); p.pending_t=0.2; ui.open_page("inventory"); await frames(3)
	install_memory(main.capture_save()); disk.fault_op="flush"; disk.fault_suffix=".tmp"; before=live()
	check(p.aura.running,"failure fixture includes an actually activated paid aura")
	check(not p.equip_item(0,"weapon") and live()==before,"failed equip preserves gear, bag, current resources, cooldown and running aura")
	check(not p.unequip_item("weapon") and live()==before,"failed unequip preserves ownership and running effects")
	check(not p.assign_skill(3,"solar_writ") and live()==before,"failed hotbar assignment does not stop the existing aura")
	check(not p.change_mastery("ward_temper",true).ok and live()==before,"failed mastery refund cannot cancel casts or spend/refund points")
	p.gear.helm=null; p.crafted_uniques.clear(); p.gold=50000; install_memory(main.capture_save()); disk.fault_op="open"; disk.fault_suffix=".tmp"; before=live()
	check(not p.craft_circlet().ok and live()==before,"failed unique attunement preserves gold, unique eligibility, bag and effects")
	ui.close_page(); await frames(3); before=live()
	main._enter_articulation_lab(); await frames(3)
	check(current_scene==main and live()==before,"failed F7 save cannot change scenes or cancel paid casts")
	check(not main.request_exit() and current_scene==main,"failed save-and-quit keeps the active game available")
	await frames(3)
	check(ui.page=="pause" and button(ui.char_panel,"Leave without saving")!=null,"failed exit offers retry and an explicit unsaved-exit choice")
	main._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST); await frames(3)
	check(current_scene==main and ui.page=="pause","native window-close failure follows the same recovery flow")
	await capture("03_failed_exit")
	ui.open_page("inventory"); await frames(3); before=live()
	button(ui.inventory_shell,"Arrange bag").pressed.emit(); await frames(3)
	check(live()==before,"failed arrange leaves every original bag coordinate unchanged")
	var grid: Control=ui.inventory_shell.bag; var data:=bag_data(0)
	var at:=Vector2(451,201)
	check(grid._can_drop_data(at,data),"movement failure test uses a legal empty destination")
	grid._drop_data(at,data); check(live()==before,"failed within-bag drag preserves item placement")
	# Recovery-copy publication can fail after commit: apply the purchase exactly once.
	await fixture("merchant"); p.gold=50000; install_memory(main.capture_save()); disk.fault_op="rename"; disk.fault_suffix=".bak"; uid=main.merchant_stock[0].uid
	check(ui.town_action("buy",uid) and Actions.find_uid(p.inventory,uid)>=0,"post-commit backup warning still applies the durable purchase")
	check(JSON.parse_string(disk.files[path]).inventory.size()==p.inventory.size() and not main.save_warning.is_empty(),"warning state keeps live and disk ownership in agreement")
	await fixture(); p.hp=p.stats().max_hp; p.mp=p.stats().max_mp
	install_memory(main.capture_save()); var previous_hp: float=p.hp
	check(p.unequip_item("armor"),"successful unequip commits a legal candidate before changing ownership")
	var saved: Dictionary=JSON.parse_string(disk.files[path])
	check(saved.hp==p.hp and saved.mp==p.mp and p.hp<=previous_hp and p.hp<=p.stats().max_hp,"prospective gear clamps saved and live resources identically without refill")
	check(saved.gear.armor==null and saved.inventory.size()==p.inventory.size(),"successful equipment transaction publishes exactly the live containers")
	ui.open_page("inventory"); await frames(3); grid=ui.inventory_shell.bag; data=bag_data(0)
	grid._drop_data(Vector2(451,201),data)
	saved=JSON.parse_string(disk.files[path])
	check(p.inventory[0].x==9 and p.inventory[0].y==4 and saved.inventory[0].x==9 and saved.inventory[0].y==4,"successful within-bag drag saves the exact requested destination")
	button(ui.inventory_shell,"Arrange bag").pressed.emit(); await frames(3)
	saved=JSON.parse_string(disk.files[path]); var coordinates_match:=true
	for i in p.inventory.size():
		if saved.inventory[i].uid!=p.inventory[i].uid or saved.inventory[i].x!=p.inventory[i].x or saved.inventory[i].y!=p.inventory[i].y: coordinates_match=false
	check(coordinates_match,"successful arrange publishes the same UID order and coordinates shown in the bag")
	await fixture("stash"); p.stash.append(p.inventory.pop_front()); ui.refresh_inventory(); await frames(3); install_memory(main.capture_save())
	grid=ui.inventory_shell.service.grid; data={"source":"stash","index":0,"uid":p.stash[0].uid,"grab":Vector2i.ZERO}
	grid._drop_data(Vector2(451,201),data); saved=JSON.parse_string(disk.files[path])
	check(p.stash[0].x==9 and p.stash[0].y==4 and saved.stash[0].x==9 and saved.stash[0].y==4,"successful within-stash drag persists its own container rather than the backpack")
	# Real filesystem round trip, isolated by the runner's XDG directories.
	main.save_store=Store.new(); main.save_error=""; main.save_warning=""; ui.close_page(); await frames(3)
	check(main.save_game(),"real disk adapter writes and verifies the full actor")
	var paid_hp: float=p.hp; var paid_mp: float=p.mp; var saved_gold: int=p.gold
	p.gold=0; p.hp=1; p.mp=0
	check(main.load_game() and p.gold==saved_gold and p.hp==paid_hp and p.mp==paid_mp,"real disk reload restores exact ownership and paid resources without refill")
	var log:="\n".join(report)+"\nRELIABILITY RESULT %d checks; %d failures\n" % [checks,failures]
	print("RELIABILITY RESULT %d checks; %d failures" % [checks,failures])
	var file:=FileAccess.open("res://tests/RELIABILITY_LAST_RUN.txt",FileAccess.WRITE); file.store_string(log); file.close()
	await main.quit_game(1 if failures else 0)
