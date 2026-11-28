extends SceneTree
## A campaign act played end to end from the generated data (tools/campaign_build.py; bible register):
## every zone of the act loads, its monsters stand on walkable ground at the act's levels, every arrival point other
## zones use to enter it is walkable, its exits lead to zones that exist; every quest (Q_A0n_01..15) is played through
## its mechanic (talk / collect from guardians / boss / arrive) and handed in to its NPC; lorecast sites wake echoes
## and teach their skills once Lorecasting is unlocked; act finale epilogue.  --act=1 (default)  --out=<dir>
var checks := 0
var failures := 0
var out := ""
var act := 1
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + why)
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		if a.begins_with("--act="): act = int(a.substr(6))
	call_deferred("_run")
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	if out != "": root.get_texture().get_image().save_png("%s/act%d_%s.png" % [out, act, name])
func _wait(s: float) -> void:
	await create_timer(s).timeout

var lab
var g
var st
var built: Dictionary
var levels := {1: [1, 10], 2: [11, 20], 3: [21, 30], 4: [31, 40], 5: [41, 50], 6: [51, 60], 7: [61, 70]}

func _kill(m) -> void:
	var hits := 0
	while is_instance_valid(m) and m.is_alive() and hits < 2000:
		m.hit(lab.attack_damage("Slash") * 3.0); hits += 1
	await process_frame

func _json(p: String):
	return JSON.parse_string(FileAccess.get_file_as_string(p))

func _go(zone: String) -> void:
	var at: Array = [620, 2470]
	var b: Dictionary = built.get(zone, {})
	if not b.get("exits", []).is_empty(): at = b["exits"][0]["inside"]
	lab.travel_to(zone, at)
	await _wait(1.6)
	lab.player.hp = lab.player.max_hp; lab.player.mana = lab.player.max_mana

func _zone_checks(zone: String) -> void:
	check(g.zone_id() == zone, "Entered %s" % zone)
	var n := 0; var off := 0; var lo := 99; var hi := 0
	for m in g.monsters:
		if not is_instance_valid(m): continue
		n += 1
		if not lab.zone_walkable(m.global_position): off += 1
		if not m.elite and not m.boss and m.unique_id == "": lo = mini(lo, m.level); hi = maxi(hi, m.level)
	var band: Array = levels[act]
	if g.in_town():
		check(n == 0, "%s is a sanctuary" % zone)
	else:
		check(n >= 10 and off == 0, "%s: %d monsters, all on walkable ground (%d off)" % [zone, n, off])
		check(lo >= int(band[0]) and hi <= int(band[1]), "%s: monster levels %d-%d inside the act band %s" % [zone, lo, hi, band])
	# every zone that leads here lands the hero on walkable ground, and every exit leads to a zone that exists
	var bad := []
	for zk in built:
		var zj = _json("res://assets/zones/%s.json" % zk)
		if zj == null: continue
		for e in zj.get("exits", []):
			if e["to"] == zone:
				var w: Vector3 = lab.zone_px_to_world(float(e["arrive"][0]), float(e["arrive"][1]))
				if not lab.zone_walkable(w): bad.append(zk)
	check(bad.is_empty(), "%s: arrivals from %s are walkable %s" % [zone, built.keys().filter(func(k): return k != zone).size(), bad])
	var missing := []
	for e in lab.zone.get("exits", []):
		if not FileAccess.file_exists("res://assets/zones/%s.json" % e["to"]): missing.append(e["to"])
	check(missing.is_empty(), "%s: every exit leads somewhere %s" % [zone, missing])

func _do_lorecasts(zone: String) -> void:
	for ls in g.lore_sites:
		var skill := String(load(String(ls["site"]["skill"])).id)
		if st.skills.has(skill): continue
		lab.player.global_position = ls["pos"] + Vector3(0.4, 0.08, 0.3); lab.zone_last_ok = lab.player.global_position
		await _wait(0.5)
		var echo = null
		for m in g.monsters:
			if is_instance_valid(m) and m.unique_id == "lore_" + String(ls["site"]["id"]): echo = m
		g.ui.close_panel()
		await _kill(echo)
		await _wait(0.3)
		g.ui.close_panel()
		check(echo != null and st.skills.has(skill), "%s: lorecast %s learned from %s" % [zone, skill, ls["site"]["figure"]])

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	built = _json("res://data/campaign_built.json")
	# campaign order (quests.json lists the main route first, in order, then the act's side quests)
	var quests: Array = _json("res://data/quests.json")["quests"].filter(func(q): return String(q["id"]).begins_with("Q_A0%d_" % act))
	var mains: Array = quests.filter(func(q): return not q.get("side", false))
	check(mains.size() >= 15, "Act %d has its main route (%d quests, %d side)" % [act, mains.size(), quests.size() - mains.size()])
	var st_script = load("res://scripts/game/game_state.gd")
	var boot = load("res://scripts/game/game_boot.gd")
	st_script.new_character("warrior")
	boot.class_id = "warrior"; boot.new_game = true
	lab = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 12: await physics_frame
	g = lab.game; st = lab.game_state
	if act == 1: check(st.quest_state("Q_A01_01") == "active", "A new hero starts on Q_A01_01")
	st.add_xp(int(60.0 * pow(float(levels[act][0]), 1.6)) * levels[act][0])
	var zone_of := {}
	for zid in built: zone_of[built[zid]["zid"]] = zid
	var reg: Array = _json("res://data/campaign_zones.json")
	var seen := {}
	for q in quests:
		var qid := String(q["id"])
		if st.quest_state(qid) == "": st.set_quest(qid, "active", 0)
		var zid := String(q["zone_id"])
		var zone := String(zone_of.get(zid, ""))
		check(zone != "", "%s has a built zone (%s)" % [qid, zid])
		if zone == "": continue
		if g.zone_id() != zone: await _go(zone)
		if not seen.has(zone):
			seen[zone] = true
			await _zone_checks(zone)
			await _shot(zone)
		if q.has("ambush"):     # a sanctuary event: safe until the NPC is spoken to, then the tear opens at the court
			check(g.in_town() and g.boss == null, "%s: the court is a sanctuary before the ambush" % qid)
			g.talk(String(q["ambush"]["npc"]))
			check(g.ui.panel_kind == "dialogue", "%s: %s speaks before the ambush" % [qid, q["ambush"]["npc"]])
			g.ui.close_panel(); g.spring_ambush(qid)
			await _wait(0.4)
			check(not g.in_town() and g.boss != null and g.monsters.size() > 1, "%s: ambush! the tear and its escort attack the court (%d foes)" % [qid, g.monsters.size()])
			if g.boss: lab.player.global_position = g.boss.global_position + Vector3(4.5, 0.08, 2.0); lab.zone_last_ok = lab.player.global_position
			await _wait(2.5)
			await _shot("ambush_" + qid)
		if q.has("boss"):
			var b = g.boss
			check(b != null and b.unique_id == q["boss"], "%s: the boss %s is here" % [qid, b.ename if b else "?"])
			if b:
				lab.player.global_position = b.global_position + Vector3(3, 0.08, 0); lab.zone_last_ok = lab.player.global_position
				await _wait(0.4)
				await _kill(b)
				await _wait(0.4)
		elif int(q.get("count", 0)) > 0 and q.has("item_name"):
			for mk in q["steps"]["active"]["markers"]:
				if not mk.has("page"): continue
				var gd = null
				for m in g.monsters:
					if is_instance_valid(m) and m.drops_page == mk["page"]: gd = m
				check(gd != null, "%s: guardian %s" % [qid, mk.get("label", mk["page"])])
				if gd == null: continue
				await _kill(gd)
				await _wait(0.3)
				for l in g.loot.duplicate():
					if is_instance_valid(l) and String(l.kind) == "quest": g._pickup(l)
				await _wait(0.1)
		if q.get("talk_complete", false):
			g.talk(String(q["giver"]))
			check(g.ui.panel_kind == "dialogue", "%s: %s speaks" % [qid, q["giver"]])
			g.ui.close_panel(); g.complete_quest(qid)
		elif String(q.get("giver", "")) != "" and st.quest_state(qid) == "ready":
			g.talk(String(q["giver"]))
			check(g.ui.panel_kind == "dialogue", "%s: hand in to %s" % [qid, q["giver"]])
			g.ui.close_panel(); g.complete_quest(qid)
		await _wait(0.3)
		var shown: bool = g.ui.panel_kind == "epilogue"
		if q.has("epilogue"):
			check(shown, "%s: %s" % [qid, q["epilogue"]["title"]])
			await _shot("epilogue_" + qid)
		g.ui.close_panel()
		check(st.quest_state(qid) == "done", "%s %s complete" % [qid, q["name"]])
		if q.has("ambush"): check(g.in_town(), "%s: the court is a sanctuary again" % qid)
		await _do_lorecasts(zone)
	if act == 1: check(g.lorecasting_unlocked(), "Lorecasting is unlocked")
	var wm = lab.hud.world_map
	wm.open("world")
	await _wait(0.3)
	var zones_in_act := 0
	for zk in built: if String(built[zk]["zid"]).begins_with("ACT0%d_" % act): zones_in_act += 1
	check(wm.act_nodes(act).size() == zones_in_act, "World map: Act %d shows all %d of its zones" % [act, zones_in_act])
	await _shot("world_map")
	wm.close()
	print("AOTL CAMPAIGN ACT %d RESULT %d checks; %d failures" % [act, checks, failures])
	quit(0 if failures == 0 else 1)
