extends SceneTree
## Act I, east half: Drowned Matron turn-in -> The Greyfen Road -> Greyfen Causeway (arrival completes it) -> the
## Tollkeeper (boss, only on its quest) -> Saltmarrow (town: sanctuary, harbourmaster, chandler's shop) -> The Dark
## Lighthouse (3 lens guardians on the Wreckers' Strand) -> the Tidewrought Warden -> Act I epilogue. Exits both ways.
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
	if out != "": root.get_texture().get_image().save_png("%s/act1_%s.png" % [out, name])
func _wait(s: float) -> void:
	await create_timer(s).timeout

var lab
var g
var st
func _start() -> void:
	if lab != null: lab.queue_free(); await process_frame
	lab = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 12: await physics_frame
	g = lab.game
	st = lab.game_state

func _kill(m) -> void:
	var hits := 0
	while is_instance_valid(m) and m.is_alive() and hits < 600:
		m.hit(lab.attack_damage("Slash")); hits += 1
	await process_frame

func _guardian(page: String):
	for m in g.monsters:
		if is_instance_valid(m) and m.drops_page == page: return m
	return null

func _collect_quest_items() -> void:
	for l in g.loot.duplicate():
		if is_instance_valid(l) and String(l.kind) == "quest": g._pickup(l)

func _exit_to(zone: String) -> Dictionary:
	for e in lab.zone["exits"]:
		if e["to"] == zone: return e
	return {}

func _travel(zone: String, at: Array) -> void:
	lab.travel_to(zone, at)
	await _wait(1.8)

func _zone_checks(zid: String, lo: int, hi: int, types: Array) -> void:
	check(g.zone_id() == zid, "Arrived in %s" % zid)
	var seen := {}; var mn := 99; var mx := 0; var n := 0
	for m in g.monsters:
		if not is_instance_valid(m): continue
		n += 1; seen[m.type_key] = true
		if m.drops_page == "" and not m.elite: mn = mini(mn, m.level); mx = maxi(mx, m.level)
	check(n >= 50, "%s is populated (%d monsters)" % [zid, n])
	var all_types := true
	for t in types: all_types = all_types and seen.has(t)
	check(all_types, "%s monster types %s" % [zid, seen.keys()])
	check(mn >= lo and mx <= hi, "%s levels within %d-%d (%d-%d)" % [zid, lo, hi, mn, mx])
	var stuck := 0
	for m in g.monsters:
		if is_instance_valid(m) and not lab.zone_walkable(m.global_position): stuck += 1
	check(stuck == 0, "%s: every monster stands on walkable ground (%d off)" % [zid, stuck])

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var st_script = load("res://scripts/game/game_state.gd")
	var boot = load("res://scripts/game/game_boot.gd")
	st_script.new_character("rogue")
	boot.class_id = "rogue"; boot.new_game = true
	await _start()
	st.add_xp(40000)
	for id in ["city_reborn", "lost_tomes", "thornwarden", "into_the_mere", "drowned_lanterns"]: st.set_quest(id, "done")
	st.set_quest("drowned_matron", "ready", 1)
	g.complete_quest("drowned_matron")
	await _wait(0.2)
	check(g.ui.panel_kind == "epilogue" and st.quest_state("the_greyfen_road") == "active", "Chapter II epilogue, then The Greyfen Road")
	g.ui.close_panel()
	# Hollowmere -> Greyfen
	await _travel("hollowmere", [3700, 2150])
	var ex := _exit_to("greyfen_causeway")
	check(not ex.is_empty(), "Hollowmere has an exit to the Greyfen Causeway")
	await _travel("greyfen_causeway", ex["arrive"])
	await _wait(0.3)
	check(st.quest_state("the_greyfen_road") == "done" and st.quest_state("the_tollkeeper") == "active", "Arrival completes The Greyfen Road; The Tollkeeper begins")
	await _zone_checks("greyfen_causeway", 7, 8, ["salt_brigand", "causeway_brute", "brine_slime"])
	check(not _exit_to("hollowmere").is_empty() and not _exit_to("saltmarrow").is_empty(), "Greyfen exits: Hollowmere and Saltmarrow")
	lab.player.global_position = lab.zone_px_to_world(5200, 2350) + Vector3.UP * 0.08; lab.zone_last_ok = lab.player.global_position
	await _wait(0.8)
	await _shot("greyfen")
	check(g.boss != null and g.boss.type_key == "tollkeeper", "The Tollkeeper holds the Toll Tower")
	var b = g.boss
	lab.player.global_position = b.global_position + Vector3(3.0, 0.08, 0); lab.zone_last_ok = lab.player.global_position
	lab.player.hp = lab.player.max_hp
	await _wait(1.2)
	await _shot("tollkeeper")
	await _kill(b)
	check(st.quest_state("the_tollkeeper") == "ready", "Slaying the Tollkeeper: report to Saltmarrow")
	# Saltmarrow
	await _travel("saltmarrow", _exit_to("saltmarrow")["arrive"])
	check(g.zone_id() == "saltmarrow" and g.in_town() and g.monsters.is_empty(), "Saltmarrow is a sanctuary (no monsters)")
	var ids := []
	for n in g.npcs: ids.append(n["id"])
	check("harbourmaster" in ids and "chandler" in ids, "Harbourmaster and chandler are in the square")
	g.talk("chandler")
	check(g.ui.panel_kind == "shop", "The chandler runs a shop")
	g.ui.close_panel()
	g.talk("harbourmaster")
	check(g.ui.panel_kind == "dialogue", "The harbourmaster takes the news")
	await _shot("saltmarrow")
	g.ui.close_panel(); g.complete_quest("the_tollkeeper")
	check(st.quest_state("the_dark_lighthouse") == "active", "The Dark Lighthouse begins")
	check(not _exit_to("greyfen_causeway").is_empty() and not _exit_to("wreckers_strand").is_empty(), "Saltmarrow exits: Greyfen and the Strand")
	# Wreckers' Strand
	await _travel("wreckers_strand", _exit_to("wreckers_strand")["arrive"])
	await _zone_checks("wreckers_strand", 8, 9, ["drowned_sailor", "tide_crawler", "wreck_hulk"])
	check(g.boss == null, "Warden's Rock is quiet before its quest")
	for i in 3:
		var gd = _guardian("lens_%d" % (i + 1))
		check(gd != null, "Lens guardian %d (%s)" % [i + 1, gd.ename if gd else "missing"])
		if gd == null: continue
		await _kill(gd)
		await _wait(0.3)
		_collect_quest_items()
	check(st.quest_state("the_dark_lighthouse") == "ready" and int(st.quest("the_dark_lighthouse").get("progress", 0)) == 3, "Three Lighthouse Lenses recovered")
	lab.player.global_position = lab.zone_px_to_world(3600, 2300) + Vector3.UP * 0.08; lab.zone_last_ok = lab.player.global_position
	await _wait(0.8)
	await _shot("strand")
	await _travel("saltmarrow", [7300, 1900])
	g.talk("harbourmaster"); g.ui.close_panel(); g.complete_quest("the_dark_lighthouse")
	check(st.quest_state("the_tidewrought_warden") == "active", "The Tidewrought Warden begins")
	await _travel("wreckers_strand", [600, 2470])
	check(g.boss != null and g.boss.type_key == "tidewrought_warden", "The Tidewrought Warden rises on Warden's Rock")
	b = g.boss
	lab.player.global_position = b.global_position + Vector3(3.0, 0.08, 0); lab.zone_last_ok = lab.player.global_position
	lab.player.hp = lab.player.max_hp
	await _wait(1.2)
	await _shot("warden")
	while is_instance_valid(b) and b.is_alive() and b.hp > b.max_hp * 0.45: b.hit(lab.attack_damage("Slash"))
	for i in 40:                       # the summon fires on the boss's next chase tick (not mid-swing)
		if b.summoned: break
		await _wait(0.1)
	check(b.summoned, "The Warden calls tide crawlers at half life")
	await _kill(b)
	check(st.quest_state("the_tidewrought_warden") == "ready", "Slaying the Warden: return to Saltmarrow")
	await _travel("saltmarrow", [7300, 1900])
	g.talk("harbourmaster"); g.ui.close_panel(); g.complete_quest("the_tidewrought_warden")
	await _wait(0.2)
	check(g.ui.panel_kind == "epilogue", "Chapter III complete: epilogue (the warden came through a rift)")
	await _shot("epilogue")
	g.ui.close_panel()
	# the world map shows the whole campaign; reachable zones show their levels
	var wm = lab.hud.world_map
	wm.open("world")
	await _wait(0.3)
	check(wm.current_act() == 1 and wm.act_nodes(1).size() == 15, "World map shows Act I: The Lost Reach, all 15 zones")
	await _shot("world_map")
	wm.close()
	print("AOTL ACT I EAST RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
