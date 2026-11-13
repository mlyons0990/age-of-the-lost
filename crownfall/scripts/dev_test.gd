extends Node
## Developer self-test, only active when the game is started with `-- --autotest`.
## Plays a scripted session (walk, fight a wave, level to 60 with choices) and
## saves screenshots to the folder given by `--shots=<dir>`. Not used in normal play.

var main: Node2D
var dir := "user://shots"
var log_lines: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			dir = a.substr(8)
	_run.call_deferred()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])


func _note(s: String) -> void:
	log_lines.append(s)
	print("[autotest] ", s)


var checks := 0
var finished: Array = []   # test sections that ran to the end (a script error stops one silently)
var fails := 0


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		_note("FAIL: " + what)


func _click(at: Vector2, button := MOUSE_BUTTON_LEFT, ctrl := false) -> void:
	# A real input event through the viewport, as a mouse would send it.
	Input.warp_mouse(at)   # moves the real cursor, so hover positions match the click
	var mv := InputEventMouseMotion.new()
	mv.position = at
	mv.global_position = at
	Input.parse_input_event(mv)
	await get_tree().process_frame
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		ev.pressed = pressed
		ev.position = at
		ev.global_position = at
		ev.ctrl_pressed = ctrl
		Input.parse_input_event(ev)
		await get_tree().process_frame
	await get_tree().process_frame


## Press at one point, move in steps, release at another: a real drag.
func _drag(from: Vector2, to: Vector2) -> void:
	Input.warp_mouse(from)
	var mv := InputEventMouseMotion.new()
	mv.position = from
	mv.global_position = from
	Input.parse_input_event(mv)
	await get_tree().process_frame
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.position = from
	down.global_position = from
	Input.parse_input_event(down)
	await get_tree().process_frame
	for k in range(1, 7):
		var at := from.lerp(to, k / 6.0)
		Input.warp_mouse(at)
		var m2 := InputEventMouseMotion.new()
		m2.position = at
		m2.global_position = at
		m2.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(m2)
		await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = to
	up.global_position = to
	Input.parse_input_event(up)
	await get_tree().process_frame
	await get_tree().process_frame


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame
	await get_tree().process_frame


func _inventory_tests() -> void:
	# Under a virtual display no real mouse ever enters the window, and Godot drops GUI clicks
	# until it has. Tell the window the pointer is inside so simulated clicks are delivered.
	get_window().notification(NOTIFICATION_WM_MOUSE_ENTER)
	var Inv := load("res://scripts/inventory_logic.gd")
	var GD := load("res://scripts/game_data.gd")
	var p: Node2D = main.player
	var hud: CanvasLayer = main.hud
	# ---- pure grid rules
	var grid: Array = []
	var sword: Dictionary = GD.starter_item("weapon", "T Sword", {"dmg": 5.0})
	var chest: Dictionary = GD.starter_item("armor", "T Chest", {"armor": 9.0})
	_check(Inv.size_of(sword) == Vector2i(1, 3) and Inv.size_of(chest) == Vector2i(2, 3), "footprints")
	_check(Inv.add(grid, 10, 6, sword) and Inv.add(grid, 10, 6, chest), "add two items")
	_check(not Inv.can_place(grid, 10, 6, chest, 0, 0), "overlap refused")
	_check(not Inv.can_place(grid, 10, 6, chest, 9, 0) and not Inv.can_place(grid, 10, 6, sword, 0, 4), "out of bounds refused")
	var n := 2
	while Inv.add(grid, 10, 6, GD.starter_item("armor", "Fill", {})):
		n += 1
	_check(Inv.is_valid(grid, 10, 6), "full grid has no overlaps")
	_check(n == 10, "ten 2x3-or-smaller pieces fit before chest armor stops fitting (got %d)" % n)
	var before := grid.size()
	var packed: Array = Inv.sorted(grid, 10, 6)
	_check(packed.size() == before and Inv.is_valid(packed, 10, 6), "sort keeps every item and stays valid")
	# 200 random items: nothing lost, nothing overlapping
	var big: Array = []
	var placed := 0
	for i in 200:
		if Inv.add(big, 10, 8, GD.make_item(1 + i % 30)):
			placed += 1
	_check(big.size() == placed and Inv.is_valid(big, 10, 8), "random fill valid")
	_check(Inv.sorted(big, 10, 8).size() == placed, "random sort keeps count")
	_check(Inv.accepts("offhand", sword) and not Inv.accepts("helm", sword) and Inv.accepts("ring2", GD.starter_item("ring", "r", {})), "slot rules")
	_check(is_equal_approx(Inv.gear_totals({"weapon": sword, "offhand": sword})["dmg"], 7.5), "dual wield counts half damage in the off hand")

	# ---- the real window, driven by simulated mouse clicks
	main.close_rift()
	p.bag = []
	p.stash = []
	for k in p.gear.keys():
		p.gear[k] = null
	var s1: Dictionary = GD.starter_item("weapon", "Test Blade", {"dmg": 40.0})
	var s2: Dictionary = GD.starter_item("weapon", "Second Blade", {"dmg": 20.0})
	var ring_a: Dictionary = GD.starter_item("ring", "Ring A", {"dmg": 2.0})
	var ring_b: Dictionary = GD.starter_item("ring", "Ring B", {"dmg": 3.0})
	var helm: Dictionary = _item_of("helm", 30, 1.0)
	for it in [s1, s2, ring_a, ring_b, helm, GD.make_item(20, 0.5), GD.make_item(25, 0.9), GD.make_item(12)]:
		Inv.add(p.bag, Inv.BAG_COLS, Inv.BAG_ROWS, it)
	var dmg0: float = p.stats()["dmg"]
	# talents such as Warlord's Fury, and the main stat, scale gear damage too
	var dmult: float = (1.0 + float(p.stats()["m"]["dmg"])) * (1.0 + float(p.attributes()["str"]) * float(GD.PER_POINT["main_dmg"]))
	await _key(KEY_I)
	_check(hud.inv_window != null and hud.inv_window.inv_open and not hud.inv_window.left_open() and not get_tree().paused, "I opens only the inventory, without pausing")
	await get_tree().process_frame
	var w: Control = hud.inv_window
	_check(w.size.x >= 1200.0 and w._right_rect().position.x > w.size.x / 2.0, "inventory docks on the right (size %s)" % str(w.size))
	_check(w._doll_rect("helm").end.y < w._bag_origin().y, "gear slots sit above the backpack")
	var bo: Vector2 = w._bag_origin()
	var C: float = w.CELL
	# right-click the first sword (cell 0,0): equips to main hand
	await _click(bo + Vector2(0.5, 0.5) * C, MOUSE_BUTTON_RIGHT)
	_check(p.gear["weapon"] == s1, "right click equips the sword")
	_check(is_equal_approx(p.stats()["dmg"], dmg0 + 40.0 * dmult), "damage rises by the sword's 40")
	# lift the second sword with a left click and put it in the off hand
	var e2: Dictionary = p.bag[Inv.entry_at(p.bag, 1, 0)] if Inv.entry_at(p.bag, 1, 0) >= 0 else {}
	_check(not e2.is_empty() and e2["item"] == s2, "second sword sits at column 1")
	await _click(bo + Vector2(1.5, 0.5) * C)
	_check(w.held == s2, "left click lifts an item onto the cursor")
	var off: Rect2 = w._doll_rect("offhand")
	await _click(off.get_center())
	_check(p.gear["offhand"] == s2 and w.held == null, "held sword drops into the off hand")
	_check(is_equal_approx(p.stats()["dmg"], dmg0 + 50.0 * dmult), "off-hand sword adds half of its 20")
	# a sword must be refused by the helm slot
	await _click(off.get_center())
	var helm_r: Rect2 = w._doll_rect("helm")
	await _click(helm_r.get_center())
	_check(p.gear["helm"] == null and w.held == s2, "helm slot refuses a sword")
	await _click(off.get_center())
	# both rings by right click fill ring1 then ring2
	var ia := -1
	for i in p.bag.size():
		if p.bag[i]["item"] == ring_a:
			ia = i
	await _click(bo + (Vector2(p.bag[ia]["x"], p.bag[ia]["y"]) + Vector2(0.5, 0.5)) * C, MOUSE_BUTTON_RIGHT)
	for i in p.bag.size():
		if p.bag[i]["item"] == ring_b:
			ia = i
	await _click(bo + (Vector2(p.bag[ia]["x"], p.bag[ia]["y"]) + Vector2(0.5, 0.5)) * C, MOUSE_BUTTON_RIGHT)
	_check(p.gear["ring1"] == ring_a and p.gear["ring2"] == ring_b, "two rings fill both ring slots")
	# hover the helm for a tooltip screenshot
	for i in p.bag.size():
		if p.bag[i]["item"] == helm:
			ia = i
	var mv := InputEventMouseMotion.new()
	mv.position = bo + (Vector2(p.bag[ia]["x"], p.bag[ia]["y"]) + Vector2(1.0, 1.0)) * C
	mv.global_position = mv.position
	Input.warp_mouse(mv.position)
	Input.parse_input_event(mv)
	await _wait(0.2)
	_check(w.get_local_mouse_position().distance_to(mv.position) < 2.0, "window sees the hover position (%s vs %s)" % [str(w.get_local_mouse_position()), str(mv.position)])
	_check(Inv.entry_at(p.bag, int(p.bag[ia]["x"]), int(p.bag[ia]["y"])) == ia and p.bag[ia]["item"] == helm, "hovering the helm")
	await _shot("g8_inventory")
	# selling is only at the merchant: ctrl+click here does nothing
	var gold0: int = p.gold
	var count0: int = p.bag.size()
	var last: Dictionary = p.bag[p.bag.size() - 1]
	await _click(bo + (Vector2(last["x"], last["y"]) + Vector2(0.5, 0.5)) * C, MOUSE_BUTTON_LEFT, true)
	_check(p.gold == gold0 and w.held == last["item"], "ctrl+click away from the merchant just picks the item up")
	await _click(bo + (Vector2(last["x"], last["y"]) + Vector2(0.5, 0.5)) * C)
	_check(p.bag.size() == count0 and w.held == null, "and clicking again puts it back")
	# drag and drop: drag the ring out of ring2 into an empty backpack corner, then back onto the doll
	var r2: Rect2 = w._doll_rect("ring2")
	await _drag(r2.get_center(), bo + Vector2(9.5, 5.5) * C)
	_check(p.gear["ring2"] == null and Inv.entry_at(p.bag, 9, 5) >= 0 and p.bag[Inv.entry_at(p.bag, 9, 5)]["item"] == ring_b, "drag a ring from the doll into the backpack corner")
	_check(w.held == null, "nothing left on the cursor after a drag")
	await _drag(bo + Vector2(9.5, 5.5) * C, r2.get_center())
	_check(p.gear["ring2"] == ring_b, "drag the ring back onto the doll")
	# a drag released on a slot that does not take the item puts it back where it came from
	var cnt: int = p.bag.size()
	var ib := -1
	for i in p.bag.size():
		if p.bag[i]["item"] == helm:
			ib = i
	var hx: int = p.bag[ib]["x"]
	var hy: int = p.bag[ib]["y"]
	await _drag(bo + (Vector2(hx, hy) + Vector2(0.5, 0.5)) * C, w._doll_rect("boots").get_center())
	_check(p.bag.size() == cnt and w.held == null and p.bag[Inv.entry_at(p.bag, hx, hy)]["item"] == helm, "failed drag returns the helm to its spot")
	# a drag released on the world drops the item on the ground, as in Path of Exile
	var loot_n: int = main.loot.size()
	await _drag(bo + (Vector2(hx, hy) + Vector2(0.5, 0.5)) * C, Vector2(900, 500))
	_check(p.bag.size() == cnt - 1 and w.held == null and main.loot.size() == loot_n + 1 and main.loot[loot_n].item == helm, "drag released on the world drops the helm on the ground")
	if main.loot.size() > loot_n:
		var ln: Node2D = main.loot[loot_n]
		main.loot.erase(ln)
		ln.queue_free()
	p.bag.append({"item": helm, "x": hx, "y": hy})
	# comparison: hovering a backpack item shows its stats against the worn one
	var cmp_new: Dictionary = GD.starter_item("weapon", "Compare Blade", {"dmg": 60.0})
	var cmp_lines: Array = w._item_lines(cmp_new, p.gear["weapon"])
	var has_delta := false
	for l in cmp_lines:
		if String(l[0]).contains("(+20)") and l[2] == w.GOOD:
			has_delta = true
	_check(has_delta, "comparison shows +20 damage in green against the worn sword")
	var then_s: Dictionary = w.stats_if_equipped(cmp_new)
	_check(float(then_s["dmg"]) > float(p.stats()["dmg"]) and p.gear["weapon"] == s1, "simulated swap raises damage and leaves the gear alone")
	Inv.add(p.bag, Inv.BAG_COLS, Inv.BAG_ROWS, cmp_new)
	var ic: int = p.bag.size() - 1
	var hov: Vector2 = bo + (Vector2(p.bag[ic]["x"], p.bag[ic]["y"]) + Vector2(0.5, 1.0)) * C
	Input.warp_mouse(hov)
	var mv2 := InputEventMouseMotion.new()
	mv2.position = hov
	mv2.global_position = hov
	Input.parse_input_event(mv2)
	await _wait(0.2)
	await _shot("g8b_compare")
	p.bag.remove_at(ic)
	# dragging the helm onto the helm slot equips it
	await _drag(bo + (Vector2(hx, hy) + Vector2(0.5, 0.5)) * C, w._doll_rect("helm").get_center())
	_check(p.gear["helm"] == helm, "drag the helm onto the helm slot equips it")
	await _click(w._doll_rect("helm").get_center(), MOUSE_BUTTON_RIGHT)
	# unequip by right click on the doll
	var wr: Rect2 = w._doll_rect("weapon")
	await _click(wr.get_center(), MOUSE_BUTTON_RIGHT)
	_check(p.gear["weapon"] == null, "right click on the doll unequips")
	# stash: K switches tab, right click moves an item across and back
	await _key(KEY_K)
	_check(hud.inv_window != null and hud.inv_window.mode == "stash" and hud.inv_window.inv_open, "K shows the stash on the left beside the inventory")
	var total: int = p.bag.size()
	var first: Dictionary = p.bag[0]
	await _click(bo + (Vector2(first["x"], first["y"]) + Vector2(0.5, 0.5)) * C, MOUSE_BUTTON_RIGHT)
	_check(p.stash.size() == 1 and p.bag.size() == total - 1, "right click moves an item into the stash")
	await _click(bo + (Vector2(p.bag[0]["x"], p.bag[0]["y"]) + Vector2(0.5, 0.5)) * C, MOUSE_BUTTON_RIGHT)
	await _wait(0.1)
	await _shot("g9_stash")
	await _click(w._left() + Vector2(0.5, 0.5) * C, MOUSE_BUTTON_RIGHT)
	_check(p.stash.size() == 1 and p.bag.size() == total - 1, "right click moves an item back to the backpack")
	# closing with an item on the cursor must not lose it
	await _click(bo + (Vector2(p.bag[0]["x"], p.bag[0]["y"]) + Vector2(0.5, 0.5)) * C)
	_check(hud.inv_window.held != null, "holding an item before closing")
	var all0: int = p.bag.size() + p.stash.size() + 1
	await _key(KEY_ESCAPE)
	_check(hud.inv_window == null and not get_tree().paused, "Esc closes the panels")
	_check(p.bag.size() + p.stash.size() == all0, "held item returns to the backpack on close")
	# a full backpack leaves loot on the ground
	while Inv.add(p.bag, Inv.BAG_COLS, Inv.BAG_ROWS, GD.starter_item("armor", "Filler", {})):
		pass
	var full: int = p.bag.size()
	main._drop(p.position, "item", 0, GD.starter_item("armor", "Left Behind", {}))
	var drop: Node2D = main.loot[main.loot.size() - 1]
	drop.position = p.position
	await _wait(0.8)
	_check(p.bag.size() == full and main.loot.has(drop), "full backpack leaves the item on the ground")
	p.bag.pop_back()
	await _wait(0.3)
	_check(not main.loot.has(drop) and p.bag.size() == full, "item is picked up once there is room")
	# stash is refused while the Scar is open
	main.toggle_rift()
	await _key(KEY_K)
	_check(hud.inv_window == null, "stash stays shut while the Scar is open")
	main.close_rift()
	# save and reload keeps bag, stash and gear
	var bag_n: int = p.bag.size()
	var stash_n: int = p.stash.size()
	main.save_game()
	p.bag = []
	p.stash = []
	p.gear["ring1"] = null
	_check(main.load_game() and p.bag.size() == bag_n and p.stash.size() == stash_n, "save and load keep backpack and stash")
	_check(p.gear["ring1"] != null and String(p.gear["ring1"]["name"]) == "Ring A" and p.gear["offhand"] != null, "save and load keep equipment")
	_check(Inv.is_valid(p.bag, Inv.BAG_COLS, Inv.BAG_ROWS) and Inv.is_valid(p.stash, Inv.STASH_COLS, Inv.STASH_ROWS), "loaded grids are valid")
	await _merchant_tests()
	await _lore_tests()
	await _caster_tests()
	await _affix_tests()
	await _boss_tests()
	await _loot_label_tests()
	await _death_tests()
	await _anim_tests()
	await _zone_tests()
	await _evade_tests()
	await _binding_tests()
	await _stat_tests()
	_check(finished.size() == 12, "every test section ran to the end (%s)" % ", ".join(finished))
	_note("sounds played during the test: %d" % main.audio.played_count)
	_check(main.audio.played_count > 20, "sounds play during play")
	_note("inventory and stat checks: %d run, %d failed" % [checks, fails])


func _lore_tests() -> void:
	var GD := load("res://scripts/game_data.gd")
	var p: Node2D = main.player
	var hud: CanvasLayer = main.hud
	main.close_rift()
	p.lore = []
	p.position = main.START
	await _wait(0.2)
	var in_plaza: int = main.memories.filter(func(m): return m.visible).size()
	_check(in_plaza == 3 and main.memories.size() == 4, "three memories linger in the plaza, one in the Whisperwood (%d visible of %d)" % [in_plaza, main.memories.size()])
	await _shot("g15_memory_plaza")
	# click-walk to the statue memory
	var lady: Node2D = null
	for m in main.memories:
		if m.lore_id == "veiled_lady":
			lady = m
	var lvl_saved: int = p.level
	p.level = 5   # below the cap, so experience can be gained
	p.xp = 0
	var xp0: int = p.xp
	var lvl0: int = p.level
	p.go_to_memory(lady)
	for i in 80:
		await _wait(0.1)
		if hud.lore_panel != null:
			break
	_check(hud.lore_panel != null and p.lore.has("veiled_lady"), "walking to the statue's memory Lorecasts it")
	_check(p.xp > xp0 or p.level > lvl0, "the first Lorecast grants experience")
	await _wait(0.6)
	await _shot("g16_lorecast")
	await _key(KEY_ESCAPE)
	_check(hud.lore_panel == null and not get_tree().paused, "Esc closes the memory")
	# reading it again gives no more experience
	var xp1: int = p.xp
	await _key(KEY_E)
	_check(hud.lore_panel != null and p.xp == xp1 and p.lore.size() == 1, "E rereads it without more experience")
	hud.close_lore()
	# journal
	await _key(KEY_J)
	_check(hud.journal_panel != null, "J opens the journal")
	var jb: Button = hud.journal_panel.find_child("journal_veiled_lady", true, false)
	var jx: Button = hud.journal_panel.find_child("journal_worn_steps", true, false)
	_check(jb != null and not jb.disabled and jx != null and jx.disabled, "journal lists found memories and hides the rest")
	await _shot("g17_journal")
	if jb != null:
		await _click(jb.get_global_rect().get_center())
	_check(hud.lore_panel != null and hud.journal_panel == null, "a journal entry opens the memory")
	hud.close_lore()
	# an elite leaves an echo; reading it removes it
	main.toggle_rift()
	await _wait(0.1)
	main.spawn_enemy("revenant", true, p.position + Vector2(120, 40))
	var elite: Node2D = main.enemies[main.enemies.size() - 1]
	main.kill_enemy(elite)
	var echo: Node2D = null
	for m in main.memories:
		if m.lore_id == "echo_elite":
			echo = m
	_check(echo != null, "the first elite leaves an echo")
	main.close_rift()
	if echo != null:
		main.lorecast(echo)
	_check(p.lore.has("echo_elite") and not main.memories.has(echo), "reading the echo records it and it fades")
	hud.close_lore()
	# saving keeps the journal
	main.save_game()
	p.lore = []
	main.load_game()
	_check(p.lore.has("veiled_lady") and p.lore.has("echo_elite") and p.lore.size() == 2, "journal survives save and load")
	p.level = lvl_saved
	finished.append("_lore_tests")


func _merchant_tests() -> void:
	var GD := load("res://scripts/game_data.gd")
	var Inv := load("res://scripts/inventory_logic.gd")
	var p: Node2D = main.player
	var hud: CanvasLayer = main.hud
	main.close_rift()
	if hud.inv_window != null:
		hud.close_inventory()
	p.position = main.START
	await _wait(0.2)
	# far away: the Merchant tab is refused
	hud.open_inventory("merchant")
	_check(hud.inv_window == null, "merchant refused from across the plaza")
	await get_tree().process_frame
	# clicking her walks the knight over and opens the trade window
	p.talk_to_merchant()
	for i in 80:
		await _wait(0.1)
		if hud.inv_window != null:
			break
	_check(hud.inv_window != null and hud.inv_window.mode == "merchant", "walking to Maren opens the merchant (dist %.2f)" % GD.gdist(p.position, main.MERCHANT_POS))
	if hud.inv_window == null:
		return
	await get_tree().process_frame
	var w: Control = hud.inv_window
	var bo: Vector2 = w._bag_origin()
	var C: float = w.CELL
	p.bag = []
	p.buyback = []
	var white: Dictionary = GD.starter_item("boots", "Plain Boots", {"armor": 2.0})
	var white2: Dictionary = GD.starter_item("belt", "Plain Belt", {"hp": 3.0})
	var good: Dictionary = _item_of("armor", 20, 1.0)
	for it in [good, white, white2]:
		Inv.add(p.bag, Inv.BAG_COLS, Inv.BAG_ROWS, it)
	# drag the good chest onto the sell zone
	var g0: int = p.gold
	var price: int = w.sell_value(good)
	await _drag(bo + Vector2(0.5, 0.5) * C, w._sell_zone().get_center())
	_check(p.gold == g0 + price and p.bag.size() == 2 and p.buyback.size() == 1, "drag onto Maren sells for %d gold" % price)
	await _wait(0.1)
	await _shot("g11_merchant")
	# buy it back
	await _click(w._buyback_rect(0).get_center())
	_check(p.gold == g0 and p.bag.size() == 3 and p.buyback.is_empty(), "click a sold item to buy it back")
	# sell all commons
	var n: int = w.sell_commons()
	_check(n == 2 and p.bag.size() == 1 and p.bag[0]["item"] == good, "sell all common items keeps the legendary")
	# right click sells
	await _click(bo + Vector2(0.5, 0.5) * C, MOUSE_BUTTON_RIGHT)
	_check(p.bag.is_empty() and p.buyback.size() == 3, "right click sells at the merchant")
	# buy a potion
	p.potions = 2
	p.gold = 100
	var b: Dictionary = w._button_rects()
	await _click((b["buy_potion"] as Rect2).get_center())
	_check(p.potions == 3 and p.gold == 75, "buy a potion for 25 gold")
	p.gold = 10
	await _click((b["buy_potion"] as Rect2).get_center())
	_check(p.potions == 3 and p.gold == 10, "can't buy a potion without the gold")
	# gear for sale: buy one
	_check(main.shop.size() == main.SHOP_SIZE, "Maren has %d items for sale" % main.shop.size())
	var stock: Dictionary = main.shop[0]
	var cost: int = w.shop_price(stock)
	_check(cost == w.sell_value(stock) * 4, "shop price is four times the sell value")
	p.gold = cost - 1
	await _click(w._shop_rect(0).get_center())
	_check(main.shop.size() == main.SHOP_SIZE and p.gold == cost - 1, "can't buy without enough gold")
	p.gold = cost + 50
	await _click(w._shop_rect(0).get_center())
	_check(main.shop.size() == main.SHOP_SIZE - 1 and p.gold == 50 and p.bag.size() == 1 and p.bag[0]["item"] == stock, "buy gear from Maren")
	await _shot("g13_shop")
	await _key(KEY_ESCAPE)
	# the stock changes after a cleared wave
	var old_first: Dictionary = main.shop[0]
	main.rift["active"] = true
	main.rift["wave"] = 2
	main.close_rift()
	_check(main.shop.size() == main.SHOP_SIZE and main.shop[0] != old_first, "stock refreshes after clearing waves")
	# E opens the merchant when standing next to her
	await _key(KEY_E)
	_check(hud.inv_window != null and hud.inv_window.mode == "merchant", "E opens the merchant up close")
	await _key(KEY_ESCAPE)
	await _wait(0.2)
	await _shot("g12_merchant_world")


## Rolls real items until one of the wanted type comes up, so names and stats match the type.
	finished.append("_merchant_tests")
func _item_of(slot: String, lvl: int, boost: float) -> Dictionary:
	var GD := load("res://scripts/game_data.gd")
	for i in 500:
		var it: Dictionary = GD.make_item(lvl, boost)
		if it["slot"] == slot:
			return it
	return GD.make_item(lvl, boost)


## A level-up during earlier tests can queue a class choice a moment later, which pauses
## the game. Let it appear, then dismiss it so the next checks run unpaused.
func _dismiss_choice() -> void:
	await _wait(1.1)
	if main.hud.choice_panel != null:
		main.hud.choice_panel.queue_free()
		main.hud.choice_panel = null
		main.hud._refresh_pause()


func _stat_tests() -> void:
	await _dismiss_choice()
	var GD := load("res://scripts/game_data.gd")
	var Inv := load("res://scripts/inventory_logic.gd")
	var p: Node2D = main.player
	for k in p.gear.keys():
		p.gear[k] = null
	var lvl0: int = p.level
	p.level = 1
	var a1: Dictionary = p.attributes()
	_check(a1["str"] == 20.0 and a1["dex"] == 10.0 and a1["vit"] == 18.0 and a1["int"] == 8.0 and a1["wis"] == 8.0, "level 1 Knight stats %s" % str(a1))
	var s1: Dictionary = p.stats()
	p.level = 11
	var a11: Dictionary = p.attributes()
	_check(a11["str"] == 30.0 and a11["vit"] == 28.0 and a11["int"] == 10.0, "stats grow each level %s" % str(a11))
	# stat points: 5 per level, placed by hand, refunded for gold
	_check(p.points_earned() == 50 and p.points_free() == 50, "50 points to spend at level 11")
	_check(p.allocate("str", 12) == 12 and p.attributes()["str"] == 42.0 and p.points_free() == 38, "placing 12 points in Strength")
	_check(p.allocate("vit", 999) == 38 and p.points_free() == 0 and p.allocate("dex", 1) == 0, "can't place more points than earned")
	p.gold = 1000
	_check(p.respec() and p.gold == 1000 - 11 * 20 and p.points_free() == 50 and p.attributes()["str"] == 30.0, "reset returns every point for 20 gold per level")
	p.gold = 0
	p.allocate("dex", 3)
	_check(not p.respec() and p.spent["dex"] == 3, "reset refused without the gold")
	# the + button on the character panel
	main.hud.toggle_character()
	await _wait(0.2)
	var cw: Control = main.hud.inv_window
	_check(cw != null and cw.mode == "character" and cw._left_rect().position.x == 0.0 and not get_tree().paused, "C opens the character panel on the left")
	var plus: Rect2 = cw.plus_rects.get("wis", Rect2()) if cw != null else Rect2()
	_check(plus.size.x > 0.0, "character panel shows a + button")
	if plus.size.x > 0.0:
		await _click(plus.get_center())
	_check(p.spent["wis"] == 1, "clicking + places a point in Wisdom")
	await _wait(0.1)
	await _shot("g14_stat_points")
	main.hud.toggle_character()
	# saving keeps placed points; a save with too many points is reset
	var lvl_before: int = p.level
	main.save_game()
	p.spent["dex"] = 0
	p.spent["wis"] = 0
	main.load_game()
	_check(p.spent["dex"] == 3 and p.spent["wis"] == 1, "placed points survive save and load")
	# Maren's stock and the buyback row are saved too
	main.restock_shop()
	var first_name: String = main.shop[0]["name"]
	p.buyback = [GD.starter_item("ring", "Sold Ring", {})]
	main.save_game()
	main.shop = []
	p.buyback = []
	main.load_game()
	_check(main.shop.size() == main.SHOP_SIZE and main.shop[0]["name"] == first_name and p.buyback.size() == 1, "shop stock and buyback survive save and load")
	for k in p.spent:
		p.spent[k] = 0
	p.level = lvl_before
	p.level = 1
	# each stat on its own, via a ring carrying 20 points of it
	var base: Dictionary = p.stats()
	var rows := {}
	for a in GD.ATTRS:
		var ring: Dictionary = GD.starter_item("ring", "Test Ring", {a: 20.0})
		p.gear["ring1"] = ring
		rows[a] = p.stats()
		p.gear["ring1"] = null
	var m: float = 1.0 + float(base["m"]["dmg"])
	_check(is_equal_approx(rows["str"]["dmg"], 10.0 * (1.0 + 40.0 * 0.005) * m), "Strength raises damage (%.2f)" % rows["str"]["dmg"])
	_check(is_equal_approx(float(rows["str"]["armor"]) - float(base["armor"]), 10.0 * (1.0 + float(base["m"]["armor"]))), "Strength raises armor")
	_check(is_equal_approx(float(rows["dex"]["crit"]) - float(base["crit"]), 0.012) and is_equal_approx(float(rows["dex"]["dodge"]) - float(base["dodge"]), 0.01), "Dexterity raises crit and dodge")
	_check(is_equal_approx(float(rows["vit"]["max_hp"]) - float(base["max_hp"]), round(100.0 * (1.0 + float(base["m"]["hp"])))) or absf(float(rows["vit"]["max_hp"]) - float(base["max_hp"]) - 100.0 * (1.0 + float(base["m"]["hp"]))) <= 1.0, "Vitality raises life")
	_check(is_equal_approx(float(rows["int"]["max_mp"]) - float(base["max_mp"]), 60.0) and is_equal_approx(float(rows["int"]["spell"]) - float(base["spell"]), 0.08), "Intelligence raises mana and skill damage")
	_check(is_equal_approx(float(rows["wis"]["mana_regen"]) - float(base["mana_regen"]), 3.0) and is_equal_approx(float(rows["wis"]["healing"]) - float(base["healing"]), 0.1), "Wisdom raises mana regen and healing")
	_check(s1["max_hp"] >= 100.0 and s1["max_hp"] <= 150.0, "level 1 life stays near the old balance (%d)" % int(s1["max_hp"]))
	# dodge cap and dodge actually happening
	var dex_ring: Dictionary = GD.starter_item("ring", "Huge Dex", {"dex": 5000.0})
	p.gear["ring1"] = dex_ring
	_check(is_equal_approx(p.stats()["dodge"], GD.DODGE_CAP), "dodge is capped at 30 percent")
	p.dead = false
	p.invuln = 0.0
	var dodged := 0
	for i in 400:
		p.hp = 1e6
		var before: float = p.hp
		p.hurt(10.0, 1)
		if p.hp == before:
			dodged += 1
	_check(dodged > 80 and dodged < 160, "about 30%% of 400 hits dodged (%d)" % dodged)
	p.gear["ring1"] = null
	# healing is scaled by Wisdom
	p.gear["ring1"] = GD.starter_item("ring", "Wis", {"wis": 100.0})
	p.hp = 1.0
	p.heal(10.0, true)
	_check(is_equal_approx(p.hp, 1.0 + 10.0 * (1.0 + (8.0 + 100.0) * 0.005)), "Wisdom scales healing (%.1f)" % p.hp)
	p.gear["ring1"] = null
	# gear rolls one stat bonus per rarity step, from the right pool
	var ok := true
	for i in 300:
		var it: Dictionary = GD.make_item(20, randf())
		var n := 0
		for a in GD.ATTRS:
			if float(it.get(a, 0.0)) > 0.0:
				n += 1
				if not (GD.AFFIX_POOL[it["slot"]] as Array).has(a):
					ok = false
		if n != int(GD.AFFIX_COUNT[int(it["rarity"])]):
			ok = false
	_check(ok, "items roll 0/1/2/3 stat bonuses by rarity, from their type's pool")
	var leg: Dictionary = GD.make_item(30, 1.0)
	_check(GD.item_line(leg).contains("Strength") or GD.item_line(leg).contains("Dexterity") or GD.item_line(leg).contains("Vitality") or GD.item_line(leg).contains("Intelligence") or GD.item_line(leg).contains("Wisdom"), "stat bonuses show in item text: " + GD.item_line(leg))
	# secondary bonuses (Diablo-style)
	var okk := true
	for i in 300:
		var it2: Dictionary = GD.make_item(25, randf())
		var n2 := 0
		for k in GD.SECONDARY:
			if float(it2.get(k, 0.0)) > 0.0:
				n2 += 1
				if not (GD.SECONDARY_POOL[it2["slot"]] as Array).has(k):
					okk = false
		if n2 != int(GD.SECONDARY_COUNT[int(it2["rarity"])]):
			okk = false
	_check(okk, "rare items roll 1 secondary bonus, legendaries 2, from their type's pool")
	p.gear["ring1"] = GD.starter_item("ring", "Sec", {"crit_dmg": 0.5, "atk_speed": 0.2, "life_hit": 7.0, "cdr": 0.1, "move": 0.1})
	var s2: Dictionary = p.stats()
	_check(is_equal_approx(s2["crit_mult"], 2.25) and is_equal_approx(s2["atk_speed"], 0.2) and is_equal_approx(s2["life_hit"], 7.0) and is_equal_approx(s2["move"], 0.1), "secondary bonuses reach the stats")
	_check(is_equal_approx(s2["cdr"], float(s2["m"]["cdr"]) + 0.1), "gear cooldown reduction adds to talents")
	p.cds.clear()
	p.cd_full.erase("basic")
	var used: bool = p.use_skill("basic", p.position + Vector2(60, 20))
	if not used:
		_note("basic attack refused: dead %s paused %s mp %.1f choice %s death %s" % [str(p.dead), str(get_tree().paused), p.mp, str(main.hud.choice_panel), str(main.hud.death_panel)])
	_check(used and is_equal_approx(float(p.cd_full.get("basic", -1.0)), 0.55 / 1.2), "attack speed shortens the basic attack (%.3f)" % float(p.cd_full.get("basic", -1.0)))
	p.gear["ring1"] = GD.starter_item("ring", "Caps", {"cdr": 5.0, "atk_speed": 5.0, "move": 5.0})
	var s3: Dictionary = p.stats()
	_check(s3["cdr"] <= 0.5 and s3["atk_speed"] <= 0.75 and s3["move"] <= 0.4, "secondary bonuses are capped")
	p.gear["ring1"] = null
	var line: String = GD.item_line(GD.starter_item("gloves", "x", {"atk_speed": 0.07, "life_hit": 5.0}))
	_check(line.contains("+7% attack speed") and line.contains("+5 life per hit"), "secondary text: " + line)
	# sounds
	_check(main.audio.streams.size() == main.audio.VOLUME.size(), "every sound in the mixer list loaded (%d)" % main.audio.streams.size())
	_check(main.audio.music_now == "plaza" and (main.audio.music_a.playing or main.audio.music_b.playing), "plaza music is playing")
	main.toggle_rift()
	await _wait(0.2)
	_check(main.audio.music_now == "scar", "music switches to the battle loop when the Scar opens")
	main.close_rift()
	await _wait(0.2)
	_check(main.audio.music_now == "plaza", "and back to the plaza when it closes")
	# old saved items without stat fields still work
	p.gear["helm"] = {"slot": "helm", "rarity": 1, "level": 3, "dmg": 0.0, "armor": 4.0, "hp": 2.0, "crit": 0.0, "name": "Old Helm"}
	_check(p.stats()["max_hp"] > 0.0, "old items without stats load fine")
	p.gear["helm"] = null
	p.level = lvl0
	# a screenshot of the character panel with gear showing bonuses
	p.gear["weapon"] = _item_of("weapon", lvl0, 1.0)
	p.gear["amulet"] = _item_of("amulet", lvl0, 1.0)
	p.gear["armor"] = _item_of("armor", lvl0, 0.2)
	main.hud.toggle_character()
	await _wait(0.3)
	await _shot("g10_stats")
	main.hud.toggle_character()
	finished.append("_stat_tests")


func _run() -> void:
	var p: Node2D = main.player
	await _wait(1.0)
	if OS.get_cmdline_user_args().has("--invonly"):
		await _inventory_tests()
		main.quit_game()
		return
	await _shot("g1_start")
	# long walk that needs pathfinding: up the stairs
	p._walk_to(Vector2(930, 420), true)
	await _wait(1.2)
	await _shot("g2_walk")
	await _wait(4.0)
	_note("after stairs walk: %s (want about 930,420)" % str(p.position.round()))
	p.position = main.START
	main.toggle_rift()
	await _wait(3.0)
	_note("wave %d, enemies %d" % [int(main.rift["wave"]), main.enemies.size()])
	# sword swing in both diagonal directions, captured mid-swing
	var dummy: Node2D = main.enemies[0]
	dummy.position = p.position + Vector2(120, 50)
	p.use_skill("basic", dummy.position)
	await _wait(0.2)
	await _shot("g3a_swing_front")
	await _wait(0.5)
	if is_instance_valid(dummy) and dummy.dead_t < 0.0:
		dummy.position = p.position + Vector2(110, -70)
		p.use_skill("basic", dummy.position)
		await _wait(0.2)
		await _shot("g3b_swing_back")
		await _wait(0.4)
	for i in 40:
		var best: Node2D = null
		for e in main.enemies:
			if e.dead_t < 0.0 and (best == null or p.position.distance_to(e.position) < p.position.distance_to(best.position)):
				best = e
		if best != null:
			p.target = best
			if i % 3 == 0:
				p.use_skill("s1", best.position)
			if i % 7 == 3:
				p.use_skill("s2", best.position)
			if i == 6:
				p.use_skill("s3", best.position)
		var max_hp: float = p.stats()["max_hp"]
		if p.hp / max_hp < 0.4:
			p.drink_potion()
		await _wait(0.3)
		if i == 5:
			await _shot("g3_fight")
		if i == 14:
			await _shot("g4_fight2")
	_note("after fight: level %d, kills %d, hp %d, wave %d, dead %s, gold %d" % [p.level, p.kills, int(p.hp), int(main.rift["wave"]), str(p.dead), p.gold])
	main.close_rift("The Scar Closes")
	if p.dead:
		main.hud.death_panel.queue_free()
		main.hud.death_panel = null
		main.respawn()
	await _wait(1.0)
	# level to the spec choice
	while p.level < 10:
		p.xp = 0
		p.level_up()
	await _wait(1.6)
	_note("choice open at 10: %s, paused %s" % [str(main.hud.choice_open()), str(get_tree().paused)])
	await _shot("g5_spec_choice")
	main.hud._choose("spec", "paladin", "Paladin", Color("ffd76a"))
	await _wait(1.0)
	main.toggle_rift()
	await _wait(3.0)
	if main.enemies.size() > 0:
		p.use_skill("s4", main.enemies[0].position)
	await _wait(0.75)
	await _shot("g6_hammer")
	await _wait(1.0)
	main.close_rift()
	while p.level < 40:
		p.xp = 0
		p.level_up()
	await _wait(1.6)
	_note("choice open at 40: %s" % str(main.hud.choice_open()))
	main.hud._choose("adv", "pal_a", "Crusader", Color("ffd76a"))
	while p.level < 60:
		p.xp = 0
		p.level_up()
	await _wait(1.8)
	_note("choice open at 60: %s" % str(main.hud.choice_open()))
	main.hud._choose("heroic", "h_warlord", "Warlord's Fury", Color("ffd76a"))
	await _wait(0.8)
	main.hud.toggle_character()
	main.hud.open_inventory("inventory")
	Input.warp_mouse(Vector2(960, 300))
	await _wait(0.3)
	await _shot("g7_character")
	main.hud.close_inventory()
	await _key(KEY_P)
	_check(main.hud.inv_window != null and main.hud.inv_window.mode == "spellbook", "P opens the spellbook")
	await _wait(0.2)
	await _shot("g15_spellbook")
	await _key(KEY_P)
	_check(main.hud.inv_window == null, "P again closes it")
	_note("final: level %d, %s, heroic %s" % [p.level, p.title(), p.heroic])
	await _inventory_tests()
	main.save_game()
	var ok: bool = main.load_game()
	_note("save reload ok: %s, level %d spec %s" % [str(ok), p.level, p.spec])
	main.quit_game()


## The ranged caster: fires bolts, keeps its distance, and its bolts can be sidestepped.
func _caster_tests() -> void:
	var GD := load("res://scripts/game_data.gd")
	var p: Node2D = main.player
	if main.hud.inv_window != null:
		main.hud.close_inventory()
	main.close_rift()
	p.position = main.RIFT_POS + GD.to_px(Vector2(-2.2, 0.0))   # the open middle of the plaza
	p.path = PackedVector2Array()
	p.target = null
	p.hp = float(p.stats()["max_hp"])
	await _wait(0.3)
	# a caster at mid range starts casting and its bolt hits a knight who stands still
	var fired0: int = main.bolts_fired
	var hits0: int = main.bolt_hits
	main.spawn_enemy("caster", false, main.RIFT_POS + GD.to_px(Vector2(2.3, 0.0)))
	var c: Node2D = main.enemies[main.enemies.size() - 1]
	c.stun = 0.0
	c.atk_cd = 0.0
	var saw_windup := false
	for i in 40:
		await _wait(0.05)
		if c.state == "windup":
			saw_windup = true
		if main.bolts_fired > fired0:
			break
	_check(saw_windup and main.bolts_fired == fired0 + 1, "caster charges and fires a bolt")
	await _wait(0.12)
	await _shot("g18_caster")
	for i in 30:
		await _wait(0.05)
		if main.bolt_hits > hits0:
			break
	_check(main.bolt_hits == hits0 + 1, "the bolt hits a knight who stands still")
	# stepping out of the bolt's path avoids it
	var hits1: int = main.bolt_hits
	main.fire_bolt(c.position, p.position, 5.0, 1, 7.0, 6.0)
	p.position += GD.to_px(Vector2(0.0, 2.0))
	await _wait(1.4)
	_check(main.bolt_hits == hits1, "sidestepping the bolt avoids it")
	# walking up to the caster makes it back away
	c.atk_cd = 99.0
	p.position = NavigationServer2D.map_get_closest_point(main.get_world_2d().navigation_map, c.position + GD.to_px(Vector2(-1.5, 0.0)))
	var d0: float = GD.gdist(c.position, p.position)
	var c0: Vector2 = c.position
	var p0: Vector2 = p.position
	await _wait(0.8)
	_note("caster retreat: state %s, caster moved %s, knight moved %s" % [c.state, str(c.position - c0), str(p.position - p0)])
	_check(GD.gdist(c.position, p.position) > d0 + 0.5, "caster backs away when the knight closes in (%.2f -> %.2f)" % [d0, GD.gdist(c.position, p.position)])
	main.kill_enemy(c)
	await _wait(0.3)


## Elite affixes: Swift, Shielded, Molten and Summoner each do what they say.
	finished.append("_caster_tests")
func _affix_tests() -> void:
	var GD := load("res://scripts/game_data.gd")
	var p: Node2D = main.player
	p.position = main.RIFT_POS + GD.to_px(Vector2(-2.5, 0.0))
	p.hp = float(p.stats()["max_hp"])
	var at: Vector2 = main.RIFT_POS + GD.to_px(Vector2(2.0, 0.0))
	# every elite rolls affixes; two at level 15 and above
	main.spawn_enemy("revenant", true, at)
	var e: Node2D = main.enemies[main.enemies.size() - 1]
	var want: int = 2 if p.level >= GD.ELITE_TWO_AFFIX_LEVEL else 1
	_check(e.affixes.size() == want, "elite rolls %d affix(es): %s" % [want, e.affix_names()])
	# Swift: faster than a plain elite
	e.set_affixes(["swift"])
	_check(e.speed_mult() > 1.2 and e.attack_mult() < 1.0, "Swift elites move and attack faster")
	# Shielded: the ward blocks damage
	e.set_affixes(["shielded", "summoner"])
	e.stun = 99.0
	e.ward = 1.0
	var hp0: float = e.hp
	var got: int = e.take_hit(50, false, p.position, {})
	_check(got == 0 and e.hp == hp0, "Shielded ward blocks all damage")
	e.ward = 0.0
	await _wait(0.2)
	await _shot("g19_elite_affixes")
	# Summoner: dropping below 60% life calls two Hollowlings
	var n0: int = main.enemies.size()
	e.take_hit(int(e.hp - e.max_hp * 0.55), false, p.position, {})
	_check(main.enemies.size() == n0 + 2 and e.summons_done == 1, "Summoner calls two Hollowlings when wounded (%d -> %d)" % [n0, main.enemies.size()])
	for x in main.enemies.duplicate():
		if x != e:
			main.kill_enemy(x)
	# Molten: dying leaves a blast that hurts a knight who stays in the ring...
	e.set_affixes(["molten"])
	p.position = e.position + GD.to_px(Vector2(-1.0, 0.0))
	var h0: int = main.hazard_hits
	main.kill_enemy(e)
	await _wait(0.6)
	await _shot("g20_molten")
	await _wait(1.0)
	_check(main.hazard_hits == h0 + 1, "Molten death blast hurts a knight who stays in the ring")
	# ...and misses one who steps out in time
	main.spawn_enemy("brute", true, at)
	var e2: Node2D = main.enemies[main.enemies.size() - 1]
	e2.set_affixes(["molten"])
	p.position = e2.position + GD.to_px(Vector2(-1.0, 0.0))
	var h1: int = main.hazard_hits
	main.kill_enemy(e2)
	await _wait(0.3)
	p.position = e2.position + GD.to_px(Vector2(-3.5, 0.0))
	await _wait(1.4)
	_check(main.hazard_hits == h1, "stepping out of the Molten ring avoids the blast")
	main.close_rift()
	await _wait(0.3)


## The Warden: arrives on wave 5, slams the ground, calls help, enrages, drops a legendary.
	finished.append("_affix_tests")
func _boss_tests() -> void:
	var GD := load("res://scripts/game_data.gd")
	var p: Node2D = main.player
	p.position = main.RIFT_POS + GD.to_px(Vector2(-2.5, 0.0))
	p.hp = float(p.stats()["max_hp"])
	main.toggle_rift()
	main.rift["wave"] = GD.BOSS_EVERY - 1
	main.spawn_wave()
	var boss: Node2D = null
	for e in main.enemies:
		if e.boss:
			boss = e
	_check(boss != null and main.enemies.size() == 3, "wave %d brings the Warden and two Hollowlings" % GD.BOSS_EVERY)
	if boss == null:
		return
	for e in main.enemies.duplicate():
		if e != boss:
			main.kill_enemy(e)
	_check(boss.max_hp > 400.0 and boss.affixes.has("summoner"), "the Warden is tough (%d life) and can call help" % int(boss.max_hp))
	# it slams the ground where the knight stands
	boss.slam_cd = 0.05
	boss.stun = 0.0
	var hz0: int = _count_hazards()
	await _wait(0.2)
	_check(_count_hazards() == hz0 + 1, "the Warden slams the ground under the knight")
	await _wait(0.4)
	await _shot("g21_warden")
	# enrage below 35%: faster, and slams twice
	boss.take_hit(int(boss.hp - boss.max_hp * 0.3), false, p.position, {})
	await _wait(0.1)
	_check(boss.enraged and boss.speed_mult() > 1.2, "the Warden enrages below 35% life")
	_check(boss.summons_done >= 1, "and has called Hollowlings on the way down")
	await _shot("g22_warden_enraged")
	# defeat: a legendary drops and the kill is counted
	var loot0: int = main.loot.size()
	var kills0: int = p.bosses_killed
	main.kill_enemy(boss)
	var legendary := false
	for i in range(loot0, main.loot.size()):
		var l: Node2D = main.loot[i]
		if l.kind == "item" and int(l.item["rarity"]) == 3:
			legendary = true
	_check(legendary and p.bosses_killed == kills0 + 1, "defeating the Warden drops a legendary")
	main.ground_blast(p.position, 2.0, 1.0, 999.0, 99, Color.RED)
	main.close_rift()
	await _wait(0.1)
	_check(_count_hazards() == 0, "closing the Scar clears pending blasts")
	await _wait(0.3)
	finished.append("_boss_tests")


func _count_hazards() -> int:
	var n := 0
	for c in main.world.get_children():
		if c.get_script() == main.Hazard and not c.done:
			n += 1
	return n


## Ground loot: plates never overlap, commons hide until Alt or hover, clicking a plate walks there.
func _loot_label_tests() -> void:
	var GD := load("res://scripts/game_data.gd")
	var p: Node2D = main.player
	for l in main.loot.duplicate():
		main.loot.erase(l)
		l.queue_free()
	p.position = main.RIFT_POS + GD.to_px(Vector2(-3.0, 0.0))
	var spot: Vector2 = main.RIFT_POS + GD.to_px(Vector2(1.5, 0.0))
	var items: Array = []
	for r in [3, 2, 1, 0]:
		var it: Dictionary = GD.make_item(10, 0.0)
		it["rarity"] = r
		it["name"] = ["Plain", "Magic", "Rare", "Legendary"][r] + " Test Item"
		items.append(it)
	var toasts0: int = main.hud.toasts.size()
	for it in items:
		main._drop(spot, "item", 0, it)
	for l in main.loot:
		l.position = spot   # all on the same spot, the worst case for overlap
		l.wait_leave = true
	_check(main.hud.toasts.any(func(t): return String(t["text"]).begins_with("Legendary:")), "a legendary drop announces itself")
	Input.warp_mouse(Vector2(20, 900))
	await _wait(0.6)
	var shown: Array = main.loot.filter(func(l): return l.show_label)
	_check(shown.size() == 3, "magic, rare and legendary plates show; the common one waits for Alt (%d shown)" % shown.size())
	var overlap := false
	for a2 in shown:
		for b2 in shown:
			if a2 != b2 and (a2.label_rect as Rect2).intersects(b2.label_rect):
				overlap = true
	_check(not overlap, "loot plates never overlap")
	var leg: Node2D = null
	for l in main.loot:
		if l.rarity() == 3:
			leg = l
	_check(leg != null and leg.label_rect.end.y <= leg.position.y - 30.0, "the legendary keeps the plate nearest its drop")
	await _shot("g23_loot_labels")
	# click the rare item's plate: the knight walks to it
	var rare: Node2D = null
	for l in main.loot:
		if l.rarity() == 2:
			rare = l
	var screen: Vector2 = main.get_viewport().get_canvas_transform() * (rare.label_rect as Rect2).get_center()
	await _click(screen)
	_check(main.pick_loot((rare.label_rect as Rect2).get_center()) == rare and p.path.size() > 0, "clicking a loot plate walks the knight to it")
	p.path = PackedVector2Array()
	for l in main.loot.duplicate():
		main.loot.erase(l)
		l.queue_free()
	# painted portraits: every item base has one, and old saves without a base still find theirs
	var missing: Array = []
	for slot in GD.ITEM_BASES:
		for base in GD.ITEM_BASES[slot]:
			var art: String = GD.item_art({"slot": slot, "base": base})
			if not ResourceLoader.exists("res://assets/items/painted/%s.png" % art):
				missing.append(base)
	_check(missing.is_empty(), "every item base has a painted portrait (missing: %s)" % str(missing))
	var old_save: Dictionary = {"slot": "armor", "name": "Grim Chainmail", "rarity": 1}
	_check(GD.item_art(old_save) == "armor_mail_mail_chest", "an old saved Chainmail still shows the mail art")
	var IW := load("res://scripts/inventory_window.gd")
	var tex: Texture2D = IW.icon_for(GD.make_item(10, 0.0))
	_check(tex != null and tex.resource_path.contains("/painted/"), "new drops use painted portraits (%s)" % (tex.resource_path if tex != null else "none"))
	finished.append("_loot_label_tests")


## Dying: the death screen names the killer and the cost, Enter brings the knight back.
func _death_tests() -> void:
	var GD := load("res://scripts/game_data.gd")
	var p: Node2D = main.player
	p.position = main.RIFT_POS
	p.invuln = 0.0
	p.gold = 500
	var deaths0: int = p.deaths
	main.toggle_rift()
	main.rift["wave"] = 3
	p.hp = 1.0
	var s: Dictionary = p.stats()
	p.gear["offhand"] = null
	# knight animations from the Higgsfield clips: flinch, cast, fall
	p.hp = 500.0
	p.swinging = 0.0
	var flinched := false
	for i in 20:
		p.hurt(1.0, 1, "Test Revenant")
		if String(p.sprite.animation).begins_with("hit_"):
			flinched = true
			break
	_check(flinched, "the knight flinches when hit (%s)" % p.sprite.animation)
	await _wait(0.5)
	p.cds.clear()
	p.mp = 999.0
	p.use_skill("s3", p.position + Vector2(40, 10))
	_check(String(p.sprite.animation).begins_with("cast_"), "Rallying Cry plays the cast animation (%s)" % p.sprite.animation)
	await _wait(0.1)
	await _shot("g28_knight_cast")
	await _wait(0.6)
	p.hp = 1.0
	p.invuln = 0.0
	# keep hitting until a hit lands (dodge can avoid one)
	for i in 50:
		p.hurt(99999.0, 1, "Test Revenant")
		if p.dead:
			break
	_check(p.dead and main.death_info.get("killer", "") == "Test Revenant", "the death screen knows what killed you")
	_check(p.gold == 450 and int(main.death_info["lost"]) == 50 and p.deaths == deaths0 + 1, "dying costs 10%% of carried gold (%d left)" % p.gold)
	_check(not main.rift["active"] and int(main.death_info["wave"]) == 3, "the Scar closes and the wave reached is shown")
	await _wait(0.1)
	_check(String(p.sprite.animation).begins_with("death_"), "the knight plays his fall (%s)" % p.sprite.animation)
	await _wait(1.5)
	_check(main.hud.death_panel != null, "death screen appears after the fall")
	await _shot("g24_death")
	await _key(KEY_ENTER)
	await _wait(0.3)
	_check(not p.dead and main.hud.death_panel == null and p.hp >= float(p.stats()["max_hp"]) - 0.5, "Enter rises again with full life")
	_check(GD.gdist(p.position, main.START) < 0.5 and p.sprite.rotation == 0.0, "back on your feet at the plaza")
	finished.append("_death_tests")


## Enemy animations from the Higgsfield clips, and the two new enemies.
func _anim_tests() -> void:
	var GD := load("res://scripts/game_data.gd")
	var EA := load("res://scripts/enemy_anims.gd")
	var Enemy := load("res://scripts/enemy.gd")
	var p: Node2D = main.player
	# every sheet loads and every frame rect fits inside it
	var bad: Array = []
	for key in EA.ANIMS:
		for anim in EA.ANIMS[key]:
			var m: Dictionary = EA.ANIMS[key][anim]
			var tex: Texture2D = Enemy.sheet(key, anim)
			var rows: int = (int(m["frames"]) + int(m["cols"]) - 1) / int(m["cols"])
			if tex == null or tex.get_width() < int(m["cw"]) * int(m["cols"]) or tex.get_height() < int(m["ch"]) * rows:
				bad.append(key + "_" + anim)
	_check(bad.is_empty(), "every enemy animation sheet loads and fits its frames (bad: %s)" % str(bad))
	# new enemies join later waves
	var seen := {}
	for i in 400:
		seen[main.wave_enemy(6)] = true
	_check(seen.has("skeleton") and seen.has("stag") and seen.has("caster"), "wave 6 can bring Legionnaires, Stags and Gravecallers (%s)" % str(seen.keys()))
	var early := {}
	for i in 300:
		early[main.wave_enemy(1)] = true
	_check(not early.has("skeleton") and not early.has("stag"), "the first wave sticks to the basic enemies")
	# a Legionnaire walks, winds up and strikes with animation frames
	p.position = main.RIFT_POS + GD.to_px(Vector2(-3.0, 0.0))
	main.spawn_enemy("skeleton", false, main.RIFT_POS + GD.to_px(Vector2(2.0, 0.0)))
	var e: Node2D = main.enemies[main.enemies.size() - 1]
	e.stun = 0.0
	var walk_frames := {}
	for i in 12:
		await _wait(0.05)
		var fr: Array = e.current_frame()
		if not fr.is_empty() and fr[0] == "walk":
			walk_frames[fr[1]] = true
	_check(walk_frames.size() >= 3, "the Legionnaire's walk cycles through frames (%d seen)" % walk_frames.size())
	await _shot("g25_legionnaire_walk")
	e.state = "windup"
	e.wind_left = 0.2
	_check(e.current_frame()[0] == "wind", "winding up uses the wind-up frames")
	e.strike_t = 0.3
	e.state = "chase"
	_check(e.current_frame()[0] == "strike", "a landed attack plays the strike frames")
	# dying plays the death animation before the body is removed
	main.kill_enemy(e)
	await _wait(0.6)
	var mid: Array = e.current_frame() if is_instance_valid(e) else []
	_check(is_instance_valid(e) and not mid.is_empty() and mid[0] == "death" and mid[1] > 0, "a defeated Legionnaire plays its collapse")
	await _shot("g26_legionnaire_death")
	await _wait(1.3)
	_check(not is_instance_valid(e), "and is removed once it finishes")
	# wolves and wraiths join later waves; enemies walking up the screen use the up-right cycle
	var later := {}
	for i in 500:
		later[main.wave_enemy(8)] = true
	_check(later.has("wolf") and later.has("wraith"), "wave 8 can bring Void-glass Wolves and Lantern Wraiths (%s)" % str(later.keys()))
	main.spawn_enemy("revenant", false, main.RIFT_POS)
	var rv: Node2D = main.enemies[main.enemies.size() - 1]
	rv.stun = 99.0
	rv.moving = true
	rv.last_step = Vector2(0.2, -1.0)
	_check(rv.current_frame()[0] == "walkne", "walking up the screen uses the up-right walk (%s)" % str(rv.current_frame()))
	rv.last_step = Vector2(1.0, 0.4)
	_check(rv.current_frame()[0] == "walk", "and walking down uses the down-right walk")
	main.kill_enemy(rv)
	main.spawn_enemy("wraith", false, main.RIFT_POS + GD.to_px(Vector2(3.0, 0.0)))
	var wr: Node2D = main.enemies[main.enemies.size() - 1]
	var b: Node2D = main.fire_bolt(wr.position, p.position, 1.0, 1, 6.0, 6.0, wr.ename)
	b.col = wr.bolt_color()
	_check(b.col.is_equal_approx(Color("c58cff")), "the Wraith throws violet lantern fire")
	main.spawn_enemy("wolf", false, main.RIFT_POS + GD.to_px(Vector2(-1.0, 1.4)))
	# a Stag in a screenshot for review
	main.spawn_enemy("stag", false, main.RIFT_POS + GD.to_px(Vector2(1.0, 1.0)))
	main.spawn_enemy("brute", false, main.RIFT_POS + GD.to_px(Vector2(-0.5, 1.6)))
	main.spawn_enemy("caster", false, main.RIFT_POS + GD.to_px(Vector2(2.5, -0.5)))
	for x in main.enemies:
		x.stun = 99.0
	await _wait(0.9)
	await _shot("g27_new_enemies")
	for x in main.enemies.duplicate():
		main.kill_enemy(x)
	await _wait(1.6)
	finished.append("_anim_tests")


## Zones: the Waystone takes the knight to the Whisperwood Ruins and back.
func _zone_tests() -> void:
	var GD := load("res://scripts/game_data.gd")
	var Z := load("res://scripts/zones.gd")
	var p: Node2D = main.player
	main.close_rift()
	for e in main.enemies.duplicate():
		main.kill_enemy(e)
	await _wait(0.2)
	# the Waystone stands on walkable floor in both zones
	for zid in Z.ZONES:
		var z: Dictionary = Z.ZONES[zid]
		var walk: Array = main.WALKABLE if z["walk"] is String else z["walk"]
		_check(Geometry2D.is_point_in_polygon(z["portal"], PackedVector2Array(walk)) and Geometry2D.is_point_in_polygon(z["arrive"], PackedVector2Array(walk)), "%s: Waystone and arrival point are on the floor" % zid)
	# click the Waystone: the knight walks over and travels
	p.position = main.waystone.position + GD.to_px(Vector2(-3.0, -1.0))
	p.path = PackedVector2Array()
	await _wait(0.2)
	var screen: Vector2 = main.get_viewport().get_canvas_transform() * (main.waystone.position + Vector2(0, -90))
	await _click(screen)
	for i in 60:
		await _wait(0.1)
		if main.zone == "whisperwood":
			break
	_check(main.zone == "whisperwood", "clicking the Waystone walks the knight there and into the Whisperwood")
	_check(not main.merchant.visible and main.bg.texture == main.zone_tex and main.zone_tex.get_width() == 2720, "the ruins replace the plaza and Maren stays in town")
	_check(GD.gdist(p.position, Z.ZONES["whisperwood"]["arrive"]) < 1.0, "the knight arrives by the ruins' Waystone")
	var sigils: Array = main.memories.filter(func(m): return m.visible)
	_check(sigils.size() == 1 and sigils[0].lore_id == "sleeping_saint", "the Sleeping Saint's memory lingers in the ruins")
	# the knight can walk the ruins (navigation rebuilt)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var dest: Vector2 = Vector2(1330, 1000)
	p._walk_to(dest, true)
	for i in 40:
		await _wait(0.1)
		if GD.gdist(p.position, dest) < 0.6:
			break
	_check(GD.gdist(p.position, dest) < 0.8, "the knight walks to the centre of the ruins (%.2f away)" % GD.gdist(p.position, dest))
	# roaming packs arrive on their own, a level above the knight
	main.pack_timer = 0.0
	await _wait(0.3)
	_check(main.enemies.size() >= 2, "a roaming pack appears in the ruins (%d)" % main.enemies.size())
	_check(main.enemies.all(func(e): return e.level >= p.level), "ruins monsters are at least the knight's level")
	main.toggle_rift()
	_check(not main.rift["active"], "the Reality Scar stays shut outside Crownsfall")
	for x in main.enemies:
		x.stun = 99.0
	await _wait(0.6)
	await _shot("g29_whisperwood")
	# dying in the ruins brings you back to town
	p.invuln = 0.0
	for i in 50:
		p.hurt(99999.0, 1, "Test Stag")
		if p.dead:
			break
	await _wait(1.6)
	await _key(KEY_ENTER)
	await _wait(0.3)
	_check(main.zone == "plaza" and not p.dead and main.merchant.visible, "rising again returns you to Crownsfall")
	_check(main.enemies.is_empty(), "the ruins' monsters stay in the ruins")
	finished.append("_zone_tests")


## Evade on Space: a roll with a moment of invulnerability; a blink is ready for future specs.
func _evade_tests() -> void:
	var GD := load("res://scripts/game_data.gd")
	var p: Node2D = main.player
	main.close_rift()
	p.position = main.RIFT_POS
	p.path = PackedVector2Array()
	p.cds.erase("evade")
	p.invuln = 0.0
	p.hp = float(p.stats()["max_hp"])
	await _wait(0.2)
	# Space rolls toward the mouse
	var aim: Vector2 = p.position + GD.to_px(Vector2(4.0, 0.0))
	Input.warp_mouse(main.get_viewport().get_canvas_transform() * aim)
	await _wait(0.05)
	var start: Vector2 = p.position
	await _key(KEY_SPACE)
	_check(not p.rolling.is_empty() and p.invuln > 0.2, "Space starts a dodge roll with i-frames")
	_check(String(p.sprite.animation).begins_with("roll_"), "the roll animation plays (%s)" % p.sprite.animation)
	# an enemy strike mid-roll does nothing
	var hp0: float = p.hp
	p.hurt(9999.0, 99, "Test Brute")
	_check(p.hp == hp0, "a blow during the roll is evaded")
	await _wait(0.1)
	await _shot("g30_dodge_roll")
	await _wait(0.5)
	var moved: float = GD.gdist(start, p.position)
	_check(p.rolling.is_empty() and moved > 2.4 and moved < 3.3, "the roll carries the knight about 3 units (%.2f)" % moved)
	_check(GD.ground(start, p.position).x > 0.0, "toward the cursor")
	_check(not p.evade(p.position + Vector2(100, 0)), "the roll has a cooldown")
	await _wait(1.0)
	p.invuln = 0.0
	p.hurt(1.0, 1, "Test")
	_check(p.hp < hp0 or p.evade_t <= 0.0, "after the roll the knight can be hit again")
	# a blink (for a future Mage spec) goes farther and stays untouchable longer
	p.evade_override = "blink"
	p.cds.erase("evade")
	p.mp = 100.0
	var b0: Vector2 = p.position
	_check(p.evade(p.position + GD.to_px(Vector2(-6.0, 0.0))), "a blink can be used")
	var bd: float = GD.gdist(b0, p.position)
	_check(bd > 3.5 and p.invuln >= 0.55, "a blink teleports farther with longer i-frames (%.2f units, %.2fs)" % [bd, p.invuln])
	p.evade_override = ""
	finished.append("_evade_tests")


## Skill bar: any skill in any slot, by dragging.
func _binding_tests() -> void:
	var GD := load("res://scripts/game_data.gd")
	var p: Node2D = main.player
	var hud: CanvasLayer = main.hud
	if hud.inv_window != null:
		hud.close_inventory()
	p.bindings = p.DEFAULT_BINDINGS.duplicate()
	p.position = main.RIFT_POS
	p.mp = 999.0
	p.cds.clear()
	await _wait(0.2)
	_check(p.bindings == ["s2", "s3", "s4", "", "basic", "s1"], "default bar: Charge, Rally, spec skill, empty | Slash, Cleave")
	# keys follow the bar
	await _key(KEY_2)
	_check(float(p.cds.get("s3", 0.0)) > 0.0, "key 2 uses what is in slot 2 (Rallying Cry)")
	# drag slot 1 onto slot 4: they swap (slot 4 was empty)
	var r: Array = hud.bar_rects
	await _drag((r[0] as Rect2).get_center(), (r[3] as Rect2).get_center())
	_check(p.bindings[0] == "" and p.bindings[3] == "s2", "dragging a skill to another slot moves it (%s)" % str(p.bindings))
	await _drag((r[3] as Rect2).get_center(), (r[4] as Rect2).get_center())
	_check(p.bindings[3] == "basic" and p.bindings[4] == "s2", "dropping on a filled slot swaps the two (%s)" % str(p.bindings))
	# drag off the bar to empty a slot
	await _drag((r[5] as Rect2).get_center(), (r[5] as Rect2).get_center() + Vector2(0, -320))
	_check(p.bindings[5] == "", "dragging a skill off the bar empties its slot")
	# from the spellbook: pick up Cleave and drop it on RMB
	await _key(KEY_P)
	hud.start_skill_drag("s1")
	var at: Vector2 = (r[5] as Rect2).get_center()
	Input.warp_mouse(at)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = at
	up.global_position = at
	Input.parse_input_event(up)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(p.bindings[5] == "s1", "a skill dragged from the spellbook lands in the slot")
	hud.start_skill_drag("s1")
	var at2: Vector2 = (r[0] as Rect2).get_center()
	var up2 := up.duplicate()
	up2.position = at2
	up2.global_position = at2
	Input.parse_input_event(up2)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(p.bindings[0] == "s1" and p.bindings[5] == "", "placing a skill already on the bar moves it there (no duplicates)")
	await _shot("g31_skill_binding")
	await _key(KEY_P)
	# LMB attacks with whatever is on LMB
	p.bindings = ["s2", "s3", "s4", "basic", "s1", ""]
	p.cds.clear()
	p.mp = 999.0
	main.spawn_enemy("brute", false, p.position + GD.to_px(Vector2(1.6, 0.0)))
	var e: Node2D = main.enemies[main.enemies.size() - 1]
	e.stun = 99.0
	p.target = e
	for i in 20:
		await _wait(0.05)
		if float(p.cds.get("s1", 0.0)) > 0.0:
			break
	_check(float(p.cds.get("s1", 0.0)) > 0.0, "clicking an enemy attacks with the skill on LMB (Cleave)")
	p.target = null
	main.kill_enemy(e)
	# saved with the character
	main.save_game()
	p.bindings = p.DEFAULT_BINDINGS.duplicate()
	main.load_game()
	_check(p.bindings == ["s2", "s3", "s4", "basic", "s1", ""], "the bar layout survives save and load")
	p.bindings = p.DEFAULT_BINDINGS.duplicate()
	await _wait(1.6)
	finished.append("_binding_tests")
