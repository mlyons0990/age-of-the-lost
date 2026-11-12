extends Node
## Integration tests use an isolated XDG_DATA_HOME (see README). Never point
## this test at a real player's data directory: it intentionally exercises saves.
const Systems := preload("res://scripts/systems.gd")
const GDData := preload("res://scripts/game_data.gd")
var main: Node2D
var failures := 0
var checks := 0
var report: Array[String] = []
var capture := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	capture = DisplayServer.get_name() != "headless"
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	report.append(("PASS " if ok else "FAIL ") + message)
	print(report[-1])
	if not ok: failures += 1

func wait_frame() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

func shot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://previews")
	get_viewport().get_texture().get_image().save_png("res://previews/" + name + ".png")

func key(code: Key) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.pressed = true
	Input.parse_input_event(event)
	await wait_frame()
	event = InputEventKey.new(); event.keycode = code; event.pressed = false
	Input.parse_input_event(event)
	await wait_frame()

func find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix): return node
	for child in node.get_children():
		var found := find_button(child, prefix)
		if found != null: return found
	return null

func _run() -> void:
	await get_tree().create_timer(0.15).timeout
	var p: Node2D = main.player
	var ui: CanvasLayer = main.hud
	# Grid geometry, collisions, bounds, no-loss packing.
	var bag: Array = []
	var sword := Systems.make_item(1, 0, "weapon")
	check(Systems.insert(bag, sword), "sword first-fit insertion")
	check(not Systems.fits(bag, Systems.make_item(1, 0, "armor"), Vector2i.ZERO), "overlap rejected")
	check(not Systems.fits(bag, sword, Vector2i(9, 5)), "out-of-bounds footprint rejected")
	check(Systems.fits(bag, sword, Vector2i(9, 0), sword.uid), "moving ignores only its own UID")
	var full: Array = []
	for y in 6:
		for x in 10: Systems.insert(full, Systems.make_item(1, 0, "ring"))
	check(full.size() == 60 and not Systems.insert(full, sword), "full grid rejects item without deletion")
	var before_sort := full.size()
	check(Systems.sort_bag(full) and full.size() == before_sort, "auto-sort conserves items")
	# Controlled equipment and stat data.
	p.inventory.clear(); p.stash.clear()
	for slot in p.gear: p.gear[slot] = null
	p.class_id = "warrior"; p.level = 1; p.spec = ""; p.adv = ""; p.discoveries.clear()
	var s: Dictionary = p.stats()
	check(is_equal_approx(s.max_hp, 100) and is_equal_approx(s.max_mp, 49), "level-one health and mana formula")
	check(is_equal_approx(s.dmg, 10.8) and is_equal_approx(s.crit, 0.042), "level-one power and crit formula")
	var magic := Systems.derive(1, {"amulet": {"intelligence": 10}}, {})
	check(magic.spell_power > s.spell_power and magic.max_mp > s.max_mp and magic.dmg == s.dmg, "Intelligence scales recovered magic and mana without inflating weapon power")
	var test_weapon := Systems.make_item(1, 0, "weapon"); test_weapon.dmg = 10.0
	for attr in Systems.ATTRS: test_weapon[attr] = 0.0
	Systems.insert(p.inventory, test_weapon)
	check(p.equip_item(0, "weapon") and p.inventory.is_empty(), "explicit equip transfers ownership")
	check(is_equal_approx(p.stats().dmg, 21.6), "weapon contribution reaches combat stats")
	Systems.insert(p.inventory, Systems.make_item(1, 0, "ring"))
	check(p.equip_item(0, "ring2"), "second ring can be equipped")
	p.inventory.assign(full.duplicate(true))
	var held: String = p.gear.weapon.uid
	check(not p.unequip_item("weapon") and p.gear.weapon.uid == held, "full bag unequip rolls back")
	p.inventory.clear()
	var high := Systems.make_item(20, 0, "armor"); Systems.insert(p.inventory, high)
	check(not p.equip_item(0, "armor"), "level requirement enforced")
	check(not p.equip_item(0, "offhand"), "wrong equipment slot rejected")
	p.inventory.clear()
	for slot in ["helm", "armor", "weapon", "offhand", "gloves", "boots", "ring", "amulet"]:
		Systems.insert(p.inventory, Systems.make_item(1, 0, slot))
	# ID-based build records and guards.
	p.cds.clear(); p.hotbar = ["slash", "cleave", "charge", "rally", ""]
	p.cds["cleave"] = 2.0
	check(p.assign_skill(4, "cleave") and p.hotbar[4] == "cleave" and p.hotbar[1] == "", "skill assignment swaps without duplicates")
	check(p.cds.cleave > 0, "cooldown survives slot reassignment")
	check(not p.assign_skill(1, "echo_strike"), "Lorecasting requirement enforced")
	check(not p.assign_skill(1, "dawnfall"), "spell level requirement enforced")
	p.level = 10; p.mp = p.stats().max_mp; p.hp = p.stats().max_hp
	p.discoveries = ["first_echo"]
	check(p.assign_skill(1, "echo_strike"), "discovery unlocks equippable ability")
	p.hotbar = ["slash", "cleave", "charge", "rally", "echo_strike"]
	p.cds.clear()
	p.use_skill("basic", p.position + Vector2(100, 0))
	check(not p.use_skill("s1", p.position), "pending melee contact cannot be overwritten")
	await get_tree().create_timer(0.6).timeout
	# Actual hotkeys and modals.
	await key(KEY_I)
	check(ui.page == "inventory" and get_tree().paused, "I opens inventory and pauses world")
	await wait_frame()
	var grid: Control = ui.bag_view
	var drag := {"index": 0, "uid": p.inventory[0].uid}
	check(not grid._can_drop_data(Vector2(10, 6) * grid.cell_size - Vector2.ONE, drag), "drag refuses footprint beyond bag edge")
	check(grid._can_drop_data(Vector2(8, 4) * grid.cell_size, drag), "drag accepts legal empty cells")
	grid._drop_data(Vector2(8, 4) * grid.cell_size, drag)
	check(int(p.inventory[0].x) == 8 and int(p.inventory[0].y) == 4, "drop commits cell coordinates")
	ui._inspect(0); await wait_frame()
	await shot("01_inventory")
	await key(KEY_ESCAPE)
	check(ui.page == "" and not get_tree().paused, "Escape closes modal without quitting")
	await key(KEY_K)
	check(ui.page == "spells" and get_tree().paused, "K opens Grimoire")
	ui.selected_spell = "echo_strike"; ui.open_page("spells"); await wait_frame()
	await shot("02_grimoire")
	ui.close_page()
	# Town service coordinates are reachable and ranged.
	for service in main.SERVICES.values():
		var closest := NavigationServer2D.map_get_closest_point(main.get_world_2d().navigation_map, service.pos)
		check(closest.distance_to(service.pos) < 2, "service on navigation floor: " + service.label)
	p.position = main.SERVICES.lore.pos
	await key(KEY_E)
	check(ui.page == "lore", "E opens nearest service")
	await shot("03_lorecasting")
	ui.close_page()
	p.position = main.SERVICES.stash.pos
	await key(KEY_E)
	check(ui.page == "stash", "stash uses proximity interaction")
	await shot("04_stash")
	var stash_before: int = p.stash.size()
	var pack_before: int = p.inventory.size()
	var grids: Array = get_tree().get_nodes_in_group("inventory_grid")
	var pack_grid: Control = null
	for control in grids:
		if control.source == p.inventory: pack_grid = control; break
	check(pack_grid != null, "stash exposes a functional backpack grid")
	if pack_grid != null:
		var click:=InputEventMouseButton.new(); click.button_index=MOUSE_BUTTON_LEFT; click.pressed=true; click.ctrl_pressed=true
		click.position=(Vector2(p.inventory[0].x,p.inventory[0].y)+Vector2(0.2,0.2))*pack_grid.cell_size
		pack_grid._gui_input(click)
		await wait_frame()
		check(p.inventory.size() == pack_before - 1 and p.stash.size() == stash_before + 1, "stash transfer conserves item ownership")
	ui.close_page()
	p.gold = 1000
	ui.open_page("merchant"); await wait_frame(); await shot("05_merchant")
	var stock_count: int = main.merchant_stock.size()
	var first_name: String = main.merchant_stock[0].name
	var buy: Button=null
	for candidate in ui.char_panel.find_children("*","Button",true,false):
		if candidate.get_meta("item_uid","")==main.merchant_stock[0].uid and candidate.get_meta("service_action","")=="buy": buy=candidate; break
	var gold_before: int = p.gold
	pack_before = p.inventory.size()
	if buy != null: buy.pressed.emit()
	await wait_frame()
	check(main.merchant_stock.size() == stock_count - 1 and p.inventory.size() == pack_before + 1 and p.gold < gold_before, "merchant purchase transfers item and charges gold")
	p.potions = 2; p.gold = 20
	var refill := find_button(ui.char_panel, "Buy health potion")
	if refill != null: refill.pressed.emit()
	await wait_frame()
	check(p.potions == 3 and p.gold == 15, "potion purchase charges five gold")
	ui.selected = 0
	var sell := find_button(ui.char_panel, "Sell selected")
	pack_before = p.inventory.size()
	if sell != null: sell.pressed.emit()
	await wait_frame()
	check(p.inventory.size() == pack_before - 1 and p.gold > 15, "explicit merchant sale removes one item and grants gold")
	ui.close_page()
	# Save/load, sanitation, backup and unknown future versions.
	p.hero_name = "Test Wayfarer"; p.gold = 123; main.save_game(); main.save_game()
	var saved_count: int = p.inventory.size()
	p.gold = 0; p.hotbar = ["", "", "", "", ""]
	check(main.load_game() and p.gold == 123 and p.inventory.size() == saved_count and p.hotbar[4] == "echo_strike", "save roundtrip includes inventory and skill IDs")
	var f := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE); f.store_string("{broken"); f.close()
	check(main.load_game() and p.gold == 123 and FileAccess.file_exists(main.SAVE_PATH + ".corrupt"), "corrupt primary recovers backup and retains evidence")
	var data: Dictionary = main._read_save(main.SAVE_PATH)
	data.schema = 99
	f = FileAccess.open(main.SAVE_PATH, FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(not main.load_game() and main.save_blocked, "future save blocks destructive downgrade writes")
	main.save_game()
	check(int(main._read_save(main.SAVE_PATH).schema) == 99, "blocked save leaves future-version bytes intact")
	data.schema=main.SAVE_SCHEMA
	f=FileAccess.open(main.SAVE_PATH,FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	main.save_blocked=false; main.save_notice=""; main.save_error=""; main.save_game()
	data = main._read_save(main.SAVE_PATH)
	data.inventory[0].uid = data.gear.weapon.uid
	check(not main._valid_save(data), "duplicate ownership IDs rejected before loading")
	data = main._read_save(main.SAVE_PATH)
	data.gold = "bad-value"
	check(not main._valid_save(data), "wrong save field types rejected safely")
	# Live contact, delayed blast, stun and burn.
	p.position = main.START; p.cds.clear(); p.pending_t = 0; p.swinging = 0; p.dash = {}; p.mp = 999
	main.spawn_enemy("brute", false, p.position + Vector2(100, 0))
	var enemy: Node2D = main.enemies[-1]
	enemy.hp = 10000; enemy.max_hp = 10000; enemy.stun = 100
	p.use_skill("basic", enemy.position)
	var hp_before: float = enemy.hp
	await get_tree().create_timer(0.1).timeout
	check(enemy.hp == hp_before, "melee waits for its contact time")
	await get_tree().create_timer(0.2).timeout
	check(enemy.hp < hp_before, "melee applies damage after contact delay")
	await get_tree().create_timer(0.3).timeout
	p.hotbar[4] = "frost_ring"; p.cds.clear(); p.mp = 999; enemy.stun = 0
	p.use_skill("s4", enemy.position)
	check(enemy.stun >= 1.19, "Winterglass applies documented stun")
	await get_tree().create_timer(0.25).timeout
	p.hotbar[4] = "ember_cone"; p.cds.clear(); p.mp = 999
	p.use_skill("s4", enemy.position)
	check(enemy.burn > 0 and enemy.burn_dps > 0, "Cinderwake applies damage-over-time")
	await get_tree().create_timer(0.25).timeout
	p.hotbar[4] = "echo_strike"; p.cds.clear(); p.mp = 999
	var ground_before: float = enemy.hp
	p.use_skill("s4", enemy.position)
	check(enemy.hp == ground_before, "ground ability does not hit before telegraph delay")
	await get_tree().create_timer(0.7).timeout
	check(enemy.hp < ground_before, "ground ability resolves delayed damage")
	main.close_rift()
	for e in main.enemies: e.queue_free()
	main.enemies.clear()
	# Full-bag loot stays on ground.
	p.inventory.assign(full.duplicate(true))
	main._drop(p.position, "item", 0, Systems.make_item(1))
	var drop: Node2D = main.loot[-1]
	check(not main._pick_up(drop) and is_instance_valid(drop), "full bag pickup leaves world loot available")
	p.inventory.clear()
	check(main._pick_up(drop) and p.inventory.size() == 1, "pickup adds item to inventory instead of auto-selling")
	main.loot.erase(drop); drop.queue_free()
	# Clean visual fixture and genuine runtime capture.
	p.inventory.clear()
	for slot in ["armor", "weapon", "helm", "ring", "gloves", "boots"]: Systems.insert(p.inventory, Systems.make_item(1, 0.3, slot))
	p.hp = p.stats().max_hp; p.mp = p.stats().max_mp; p.cds.clear(); p.invuln = 20
	p.hotbar = ["slash", "cleave", "charge", "rally", "echo_strike"]
	ui.toasts.clear(); ui.banner_t = 99
	await shot("06_plaza")
	if capture:
		main.spawn_enemy("brute", false, p.position + Vector2(120, 0))
		var target: Node2D = main.enemies[-1]; target.hp = 10000; target.max_hp = 10000; target.stun = 100
		for i in 32:
			if i == 1: p.use_skill("s1", target.position)
			if i == 10: p.use_skill("s4", target.position)
			if i == 23: p.use_skill("basic", target.position)
			await get_tree().create_timer(0.08).timeout
			await shot("combat_%02d" % i)
	ui.open_page("inventory"); await wait_frame(); ui._inspect(0); await wait_frame(); await shot("01_inventory")
	var file := FileAccess.open("res://tests/LAST_RUN.txt", FileAccess.WRITE)
	file.store_string("Godot " + Engine.get_version_info().string + " / " + DisplayServer.get_name() + "\n" + "\n".join(report) + "\n%d checks; %d failures\n" % [checks, failures]); file.close()
	print("RESULT %d checks; %d failures" % [checks, failures])
	await main.quit_game(1 if failures else 0)
