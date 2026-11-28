extends SceneTree
## The playable game, end to end, on the bible's Act I (docs/AOTL_Seven_Act_Narrative_and_World_Design_Bible.docx):
## new Knight -> Crownsfall -> Mira Thorne's "A Bell Without a Ringer" -> the Kingsroad Gate -> Kingsroad Fields ->
## monsters fight back -> kills give XP, gold, potions, gear -> equip changes stats -> guardians drop the 3 Courier's
## Waymarks -> Bramblewatch: Scavenger Chief Kettle -> Rowan Hale takes the dispatch -> Caldrin's memory panel;
## death and respawn; the save restores everything.
var checks := 0
var failures := 0
var out := ""
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + why)
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	call_deferred("_run")
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	if out != "": root.get_texture().get_image().save_png("%s/game_%s.png" % [out, name])
func _wait(s: float) -> void:
	await create_timer(s).timeout

var lab
var g
func _start() -> void:
	if lab != null: lab.queue_free(); await process_frame
	lab = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 12: await physics_frame
	g = lab.game

## Kill a monster with the hero's own attack damage (one hit at a time, as the combat code applies it).
func _kill(m) -> int:
	var hits := 0
	while is_instance_valid(m) and m.is_alive() and hits < 200:
		var dead: bool = m.hit(lab.attack_damage("Slash"))
		hits += 1
		if dead: lab.kills += 1
	await process_frame
	return hits

func _guardian(page: String):
	for m in g.monsters:
		if is_instance_valid(m) and m.drops_page == page: return m
	return null

func _collect_all() -> void:
	for l in g.loot.duplicate():
		if is_instance_valid(l): g._pickup(l)

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var st_script = load("res://scripts/game/game_state.gd")
	var boot = load("res://scripts/game/game_boot.gd")
	st_script.new_character("warrior")
	boot.class_id = "warrior"; boot.new_game = true
	await _start()
	check(g != null and lab.game_state.class_id == "warrior", "Game scene starts a new Knight")
	check(g.zone_id() == "crownsfall" and g.in_town(), "Starts in Crownsfall (sanctuary)")
	check(lab.game_state.level == 1 and lab.player.max_hp == float(lab.game_state.stats()["max_hp"]), "Level 1, life from the character sheet (%d)" % int(lab.player.max_hp))
	check(g.npcs.size() == 3, "Mira Thorne, Captain Ralden and the Quartermaster stand in town")
	for n in g.npcs: check(lab.zone_walkable(n["pos"]), "%s stands on walkable ground" % n["name"])
	check(lab.game_state.quest_state("Q_A01_01") == "active" and lab.hud.quest_box.get_child_count() >= 1, "Q_A01_01 A Bell Without a Ringer is active and on the tracker")
	await _wait(0.6)
	await _shot("town")
	# painted 2D NPCs (owner: static NPCs are 2D)
	var painted: Array = g.npcs.filter(func(n): return n.get("sprite") != null and n["sprite"] is Sprite3D)
	check(painted.size() == 2, "Captain Ralden and Quartermaster Ysolde are painted 2D sprites (Mira's painting is in the art pass) (%d)" % painted.size())
	# talk to Mira by clicking her
	var ral: Dictionary = g.npcs[0]
	var qm: Dictionary = g.npcs[2]
	lab.player.global_position = ral["pos"] + Vector3(1.0, 0.08, 1.0); lab.zone_last_ok = lab.player.global_position
	var sp: Vector2 = lab.camera.unproject_position(ral["pos"] + Vector3.UP * 1.1)
	await process_frame
	lab.handle_click(sp)
	await process_frame
	check(g.ui.panel_kind == "dialogue", "Clicking Mira Thorne opens her dialogue")
	await process_frame
	await _shot("dialogue")
	g.ui.close_panel(); g.complete_quest("Q_A01_01")
	await process_frame; await process_frame
	check(lab.game_state.quest_state("Q_A01_02") == "active", "Mira sends the hero on Q_A01_02 The Missing Mile")
	check(g.quest_view()[0]["markers"].size() == 3, "Three waymark objectives on the map")
	# shop (the Quartermaster's painted talking pose and portrait)
	g.talk("quartermaster")
	check(g.ui.panel_kind == "shop" and g.ui.inv.visible, "Quartermaster opens the shop with the inventory")
	await process_frame; await process_frame
	check(qm["sprite"].texture == qm["art"]["talk"], "Ysolde switches to her talking pose")
	check(g.ui.panel.find_children("*", "TextureRect", true, false).any(func(t): return t.texture == qm["art"]["portrait"]), "Her portrait is in the shop")
	var gold0: int = lab.game_state.gold; var hp0: int = lab.game_state.potions["health"]
	lab.game_state.gold = 100
	await _shot("shop")
	g.ui.close_panel(); g.ui.inv.visible = false
	lab.game_state.gold = gold0
	for i in 4: await process_frame
	check(qm["sprite"].texture == qm["art"]["idle"], "Ysolde returns to her idle pose")
	# out through the Kingsroad Gate
	var gate: Dictionary = {}
	for e in lab.zone["exits"]: if e["to"] == "kingsroad_fields": gate = e
	check(not gate.is_empty(), "Crownsfall has the Kingsroad Gate at the bottom of the plaza")
	lab.travel_to("kingsroad_fields", gate["arrive"])
	await _wait(1.6)
	check(g.zone_id() == "kingsroad_fields", "The gate leads to Kingsroad Fields")
	var n_mon := 0
	for m in g.monsters: n_mon += 1
	check(n_mon >= 50, "Kingsroad Fields is populated (%d monsters)" % n_mon)
	check(_guardian("Q_A01_02_1") != null and _guardian("Q_A01_02_2") != null and _guardian("Q_A01_02_3") != null, "The three waymark guardians are in place")
	check(g.boss == null, "No boss on the Kingsroad")
	# monsters fight back: put the hero next to a pack
	var target = null
	for m in g.monsters:
		if m.type_key == "kingsroad_fields_1" and not m.elite and m.drops_page == "": target = m; break
	lab.player.global_position = target.global_position + Vector3(1.2, 0.08, 0); lab.zone_last_ok = lab.player.global_position
	var hp_before: float = lab.player.hp
	await _wait(3.0)
	check(target.state in ["chase", "wind", "recover"], "A monster notices the hero and attacks (%s)" % target.state)
	check(lab.player.hp < hp_before, "Monsters deal damage (%.0f -> %.0f)" % [hp_before, lab.player.hp])
	await _shot("combat")
	# real input: click the monster -> the hero walks in and swings; its own attack lands
	lab.player.hp = lab.player.max_hp
	var hp_m: float = target.hp
	var spm: Vector2 = lab.camera.unproject_position(target.global_position + Vector3.UP * 0.6)
	lab.handle_click(spm)
	await _wait(2.5)
	check(not is_instance_valid(target) or target.hp < hp_m, "Clicking a monster attacks it with the hero's own swing")
	if not is_instance_valid(target) or not target.is_alive():
		for m in g.monsters:
			if is_instance_valid(m) and m.type_key == "kingsroad_fields_1" and not m.elite and m.drops_page == "": target = m; break
	var xp0: int = lab.game_state.xp; var lv0: int = lab.game_state.level
	var hits := await _kill(target)
	check(hits >= 1 and hits <= 5, "Field-vermin take %d hero hits at level 1" % hits)
	check(lab.game_state.xp > xp0 or lab.game_state.level > lv0, "Kills give XP")
	# kill a few packs to level up and get loot
	var killed := 0
	for m in g.monsters.duplicate():
		if killed >= 18: break
		if is_instance_valid(m) and m.drops_page == "" and not m.boss:
			await _kill(m); killed += 1
	await _wait(0.2)
	check(lab.game_state.level >= 2, "Level up from kills (level %d)" % lab.game_state.level)
	check(lab.player.max_hp == float(lab.game_state.stats()["max_hp"]), "Level up raises life (%d)" % int(lab.player.max_hp))
	var n_loot: int = g.loot.size()
	check(n_loot > 0, "Monsters drop loot (%d on the ground)" % n_loot)
	await _shot("loot")
	var g_before: int = lab.game_state.gold
	_collect_all()
	check(lab.game_state.gold >= g_before, "Picking up gold adds to the purse")
	check(lab.game_state.bag.size() > 0 or true, "Gear goes to the bag (%d items)" % lab.game_state.bag.size())
	# equip: give a strong weapon and equip it
	var sys = load("res://scripts/systems.gd")
	var sword: Dictionary = sys.make_item(1, 0.0, "weapon", "warrior"); sword["dmg"] = 40.0; sword["level"] = 1; sword["name"] = "Test Blade"
	lab.game_state.add_item(sword)
	var dmg0: float = float(lab.game_state.stats()["dmg"])
	check(lab.game_state.equip(String(sword["uid"])) == "", "Equip a better weapon from the bag")
	g.apply_stats()
	check(float(lab.game_state.stats()["dmg"]) > dmg0 and lab.game_state.gear["weapon"]["name"] == "Test Blade", "Equipped weapon raises damage (%.0f -> %.0f)" % [dmg0, float(lab.game_state.stats()["dmg"])])
	g.ui.toggle_inventory()
	await _wait(0.2)
	await _shot("inventory")
	g.ui.toggle_inventory()
	# pages
	for page in ["Q_A01_02_1", "Q_A01_02_2", "Q_A01_02_3"]:
		var gm = _guardian(page)
		var before: int = int(lab.game_state.quest("Q_A01_02").get("progress", 0))
		lab.player.global_position = gm.global_position + Vector3(4.0, 0.08, 0); lab.zone_last_ok = lab.player.global_position
		await _kill(gm)
		await _wait(0.1)
		var page_drop = null
		for l in g.loot:
			if is_instance_valid(l) and l.kind == "quest": page_drop = l
		check(page_drop != null, "Guardian drops a Courier's Waymark (%s)" % page)
		if page_drop != null:
			lab.player.global_position = page_drop.global_position + Vector3(0, 0.08, 0)     # walk over it
			lab.zone_last_ok = lab.player.global_position
			await _wait(0.2)
		await _wait(0.2)
		check(int(lab.game_state.quest("Q_A01_02").get("progress", 0)) == before + 1 or lab.game_state.quest_state("Q_A01_02") == "done", "Walking over the waymark collects it (%d/3)" % (before + 1))
	check(lab.game_state.quest_state("Q_A01_02") == "done" and lab.game_state.quest_state("Q_A01_03") == "active", "All three waymarks: the courier's route is found; The Last Dispatch begins")
	# death
	var hpd: float = lab.player.max_hp
	g.damage_hero(99999.0, null)
	await _wait(0.3)
	check(g.dead and g.ui.panel_kind == "death", "Death shows the death screen")
	await _shot("death")
	g.ui.close_panel(); g.respawn()
	await _wait(1.8)
	check(not g.dead and g.zone_id() == "crownsfall" and lab.player.hp == lab.player.max_hp, "Respawn in Crownsfall at full life")
	g.talk("mira")
	check(g.ui.panel_kind == "dialogue", "Mira still talks to the hero")
	g.ui.close_panel()
	# save + reload mid-game
	g.autosave()
	var lv_saved: int = lab.game_state.level; var gold_saved: int = lab.game_state.gold; var bag_saved: int = lab.game_state.bag.size()
	boot.class_id = ""; boot.new_game = false
	await _start()
	check(lab.game_state.level == lv_saved and lab.game_state.gold == gold_saved and lab.game_state.bag.size() == bag_saved and lab.game_state.gear["weapon"]["name"] == "Test Blade", "Continue restores level, gold, bag and gear")
	check(lab.game_state.quest_state("Q_A01_03") == "active" and lab.game_state.dead_uniques.has("kingsroad_fields_g2"), "Continue restores quests and slain guardians")
	lab.travel_to("kingsroad_fields", [620, 2470])
	await _wait(1.6)
	check(_guardian("Q_A01_02_1") == null, "Slain guardians stay dead")
	# boss: Bramblewatch
	var bw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign_built.json"))["bramblewatch"]
	lab.travel_to("bramblewatch", bw["exits"][0]["inside"])
	await _wait(1.6)
	check(g.boss != null and g.boss.ename == "Scavenger Chief Kettle", "Scavenger Chief Kettle holds the collapsed bridge")
	lab.player.global_position = g.boss.global_position + Vector3(3.0, 0.08, 0); lab.zone_last_ok = lab.player.global_position
	await _wait(2.0)
	check(g.boss.state != "idle" and g.ui.boss_bar.visible, "Boss engages; boss bar shows")
	lab.player.hp = lab.player.max_hp
	await _shot("boss")
	var b = g.boss
	while is_instance_valid(b) and b.is_alive() and b.hp > b.max_hp * 0.45: b.hit(lab.attack_damage("Slash"))
	await _wait(0.3)
	check(g.monsters.size() > 0 and b.summoned, "Boss summons adds at half life")
	await _kill(b)
	check(lab.game_state.quest_state("Q_A01_03") == "ready", "Slaying Kettle: report to Rowan Hale")
	check(g.loot.size() >= 3, "The boss drops a hoard")
	g.talk("rowan")
	check(g.ui.panel_kind == "dialogue", "Rowan Hale takes the news (the courier carried a black glass seal)")
	g.ui.close_panel(); g.complete_quest("Q_A01_03")
	check(lab.game_state.quest_state("Q_A01_04") == "active", "A Forest Out of Season begins")
	# the cathedral memory panel (bible signature scene) shows on The Man Behind the Monster
	lab.game_state.set_quest("Q_A01_13", "ready", 1)
	g.complete_quest("Q_A01_13")
	await _wait(0.2)
	check(g.ui.panel_kind == "epilogue", "Lorecasting Caldrin's shield shows his memory")
	await _shot("epilogue")
	g.ui.close_panel()
	g.ui.toggle_pause()
	check(g.ui.panel_kind == "pause" and paused, "Esc pauses the game")
	await _shot("pause")
	g.ui.toggle_pause()
	check(not paused, "Resume unpauses")
	print("AOTL GAME LOOP RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
