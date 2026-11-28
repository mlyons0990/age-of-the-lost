extends SceneTree
## Act I, second half (docs/AOTL_CAMPAIGN_ZONES.md #5, #9-#15), played through end to end:
## The Scorched Altar (Sunken Chapel: Drowned Oracle lorecast, the Choirmaster) -> The Wrong Tide (Smugglers' Grotto:
## Corsair Duelist lorecast, Corsair Queen Velka) -> The Keepers' Journal (Lanternfall Cliffs) -> Oldwatch (town,
## Ione Thessaly) -> Clockwork on the Moor (Riftscar Moor) -> Brackwater Echoes (Brackwater Ruins: Sentinel lorecast)
## -> The Star Chart (Shattered Observatory) -> The First Rift (the Riftwarden) -> Act I epilogue.
## Every zone: exits both ways, populated at its levels, every monster on walkable ground.
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
	if out != "": root.get_texture().get_image().save_png("%s/act1late_%s.png" % [out, name])
func _wait(s: float) -> void:
	await create_timer(s).timeout

var lab
var g
var st

func _kill(m) -> void:
	var hits := 0
	while is_instance_valid(m) and m.is_alive() and hits < 800:
		m.hit(lab.attack_damage("Slash")); hits += 1
	await process_frame

func _exit_to(zone: String) -> Dictionary:
	for e in lab.zone["exits"]:
		if e["to"] == zone: return e
	return {}

## Leave the current zone through its exit to `zone` (the exit must exist).
func _go(zone: String) -> void:
	var e := _exit_to(zone)
	var from: String = g.zone_id()
	check(not e.is_empty(), "%s has an exit to %s" % [from, zone])
	if e.is_empty(): return
	lab.travel_to(zone, e["arrive"])
	await _wait(1.8)
	check(g.zone_id() == zone and not _exit_to(from).is_empty(), "Arrived in %s, which leads back to %s" % [zone, from])
	lab.player.hp = lab.player.max_hp

func _zone_checks(lo: int, hi: int, types: Array) -> void:
	var zid: String = g.zone_id()
	var seen := {}; var mn := 99; var mx := 0; var n := 0; var off := 0
	for m in g.monsters:
		if not is_instance_valid(m): continue
		n += 1; seen[m.type_key] = true
		if m.drops_page == "" and not m.elite and not m.boss and m.unique_id == "": mn = mini(mn, m.level); mx = maxi(mx, m.level)
		if not lab.zone_walkable(m.global_position): off += 1
	var all_types := true
	for t in types: all_types = all_types and seen.has(t)
	check(n >= 25 and all_types and mn >= lo and mx <= hi, "%s: %d monsters, levels %d-%d (want %d-%d), types %s" % [zid, n, mn, mx, lo, hi, types])
	check(off == 0, "%s: every monster on walkable ground (%d off)" % [zid, off])

func _boss_fight(type_key: String, quest: String) -> void:
	check(g.boss != null and g.boss.type_key == type_key, "%s is present for %s" % [type_key, quest])
	if g.boss == null: return
	var b = g.boss
	lab.player.global_position = b.global_position + Vector3(3.0, 0.08, 0); lab.zone_last_ok = lab.player.global_position
	lab.player.hp = lab.player.max_hp
	await _wait(0.8)
	await _shot(type_key)
	while is_instance_valid(b) and b.is_alive() and b.hp > b.max_hp * 0.45: b.hit(lab.attack_damage("Slash"))
	await _wait(0.2)
	check(b.summoned, "%s calls its adds at half life" % type_key)
	await _kill(b)
	await _wait(0.2)
	check(st.quest_state(quest) == "ready", "%s slain: %s is ready" % [type_key, quest])

func _lorecast(site_id: String, skill: String) -> void:
	var ls = null
	for x in g.lore_sites:
		if x["site"]["id"] == site_id: ls = x
	check(ls != null and not st.skills.has(skill), "Lorecast site %s is here, %s not yet known" % [site_id, skill])
	if ls == null: return
	lab.player.global_position = ls["pos"] + Vector3(0.4, 0.08, 0.3); lab.zone_last_ok = lab.player.global_position
	lab.player.hp = lab.player.max_hp
	await _wait(0.5)
	var echo = null
	for m in g.monsters:
		if is_instance_valid(m) and m.unique_id == "lore_" + site_id: echo = m
	g.ui.close_panel()
	await _kill(echo)
	await _wait(0.3)
	g.ui.close_panel()
	check(echo != null and st.skills.has(skill), "Defeating the echo teaches %s" % skill)
	check(skill in lab.hud._skill_names(), "%s is offered in the skill-bar picker" % skill)
	if not skill in st.bar:                   # a full bar: the player slots it from the picker
		lab.hud.assign("skill", 4, skill)
		st.bar[4] = skill

func _collect(page_prefix: String, n: int) -> void:
	for i in n:
		var gd = null
		for m in g.monsters:
			if is_instance_valid(m) and m.drops_page == "%s_%d" % [page_prefix, i + 1]: gd = m
		check(gd != null, "Guardian of %s_%d" % [page_prefix, i + 1])
		if gd == null: continue
		await _kill(gd)
		await _wait(0.3)
		for l in g.loot.duplicate():
			if is_instance_valid(l) and String(l.kind) == "quest": g._pickup(l)

func _turn_in(zone: String, npc: String, quest: String, arrive: Array) -> void:
	lab.travel_to(zone, arrive)
	await _wait(1.8)
	g.talk(npc)
	var ok: bool = g.ui.panel_kind == "dialogue"
	g.ui.close_panel()
	g.complete_quest(quest)
	await _wait(0.2)
	check(ok and st.quest_state(quest) == "done", "%s turns in %s" % [npc, quest])

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var st_script = load("res://scripts/game/game_state.gd")
	var boot = load("res://scripts/game/game_boot.gd")
	st_script.new_character("cleric")
	boot.class_id = "cleric"; boot.new_game = true
	lab = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 12: await physics_frame
	g = lab.game; st = lab.game_state
	st.add_xp(20000)
	for id in ["city_reborn", "lost_tomes", "thornwarden", "into_the_mere", "drowned_lanterns"]: st.set_quest(id, "done")
	st.set_quest("drowned_matron", "ready", 1)
	g.complete_quest("drowned_matron")
	g.ui.close_panel()
	check(st.quest_state("the_scorched_altar") == "active", "The Drowned Matron turn-in opens The Scorched Altar")
	# --- #5 The Sunken Chapel ---
	lab.travel_to("hollowmere", [10300, 3000])
	await _wait(1.8)
	await _go("sunken_chapel")
	await _zone_checks(6, 7, ["drowned_acolyte", "chapel_eel", "font_horror"])
	await _lorecast("drowned_oracle", "tidecall")
	await _shot("chapel")
	await _boss_fight("choirmaster", "the_scorched_altar")
	await _turn_in("crownsfall", "ralden", "the_scorched_altar", [1920, 1100])
	# --- Tidewrought turn-in -> The Wrong Tide ---
	for id in ["the_greyfen_road", "the_tollkeeper", "the_dark_lighthouse"]: st.set_quest(id, "done")
	st.set_quest("the_tidewrought_warden", "ready", 1)
	await _turn_in("saltmarrow", "harbourmaster", "the_tidewrought_warden", [3800, 2650])
	g.ui.close_panel()
	check(st.quest_state("the_wrong_tide") == "active", "The Wrong Tide begins")
	# --- #9 Smugglers' Grotto ---
	lab.travel_to("wreckers_strand", [9100, 1350])
	await _wait(1.8)
	await _go("smugglers_grotto")
	await _zone_checks(9, 10, ["smuggler", "cave_crab", "grotto_brute"])
	await _lorecast("corsair_duelist", "riposte_flurry")
	await _boss_fight("corsair_velka", "the_wrong_tide")
	await _turn_in("saltmarrow", "harbourmaster", "the_wrong_tide", [3800, 2650])
	check(st.quest_state("the_keepers_journal") == "active", "The Keepers' Journal begins")
	# --- #10 Lanternfall Cliffs ---
	lab.travel_to("wreckers_strand", [7600, 600])
	await _wait(1.8)
	await _go("lanternfall_cliffs")
	await _zone_checks(10, 11, ["cliff_ghoul", "lantern_wisp", "cliff_brute"])
	await _collect("journal", 3)
	await _shot("lanternfall")
	check(st.quest_state("the_keepers_journal") == "ready", "Three journal pages recovered")
	# --- #11 Riftscar Moor -> #13 Oldwatch ---
	await _go("riftscar_moor")
	await _zone_checks(11, 12, ["clockwork_soldier", "rift_mite", "rift_beast"])
	await _shot("riftscar")
	check(g.boss == null, "The Centurion does not muster before its quest")
	await _go("oldwatch")
	check(g.in_town() and g.monsters.is_empty(), "Oldwatch is a sanctuary")
	var ids := []
	for n in g.npcs: ids.append(n["id"])
	check("ione" in ids and "hode" in ids, "Ione Thessaly and Sergeant Hode are at Oldwatch")
	g.talk("ione")
	await _shot("oldwatch")
	g.ui.close_panel(); g.complete_quest("the_keepers_journal")
	check(st.quest_state("clockwork_on_the_moor") == "active", "Clockwork on the Moor begins")
	g.talk("hode")
	check(g.ui.panel_kind == "shop", "Sergeant Hode sells supplies")
	g.ui.close_panel(); g.ui.inv.visible = false
	await _go("riftscar_moor")
	await _boss_fight("clockwork_centurion", "clockwork_on_the_moor")
	await _turn_in("oldwatch", "ione", "clockwork_on_the_moor", [3840, 2900])
	# --- #12 Brackwater Ruins ---
	lab.travel_to("riftscar_moor", [8200, 4400])
	await _wait(1.8)
	await _go("brackwater_ruins")
	await _zone_checks(12, 13, ["concord_phantom", "flicker_ooze", "ruin_golem"])
	await _collect("seal", 3)
	check(st.quest_state("brackwater_echoes") == "ready", "Three Concord seals recovered")
	await _lorecast("rift_sentinel", "phase_step")
	var before: Vector3 = lab.player.global_position
	lab.player.mana = lab.player.max_mana
	lab.player.aim_point = before + Vector3(-6, 0, 0)
	var used: bool = g.use_skill("phase_step")
	await _wait(0.3)
	check(used and lab.player.global_position.distance_to(before) > 3.0, "Phase Step moves the hero (%.1f m)" % lab.player.global_position.distance_to(before))
	await _shot("brackwater")
	await _turn_in("oldwatch", "ione", "brackwater_echoes", [3840, 2900])
	# --- #14 The Shattered Observatory ---
	await _go("shattered_observatory")
	await _zone_checks(13, 14, ["star_wraith", "astral_mote"])
	await _boss_fight("orrery_golem", "the_star_chart")
	await _turn_in("oldwatch", "ione", "the_star_chart", [3840, 2900])
	check(st.quest_state("the_first_rift") == "active", "The First Rift begins")
	# --- #15 The First Rift ---
	lab.travel_to("riftscar_moor", [11050, 2470])
	await _wait(1.8)
	await _go("first_rift")
	await _boss_fight("riftwarden", "the_first_rift")
	await _turn_in("oldwatch", "ione", "the_first_rift", [3840, 2900])
	check(g.ui.panel_kind == "epilogue", "Act I complete: epilogue")
	await _shot("epilogue")
	g.ui.close_panel()
	check(["radiant_spear", "tidecall", "riposte_flurry", "phase_step"].filter(func(s): return st.skills.has(s)).size() == 3, "Three Act I lorecasts learned on this run (Radiant Spear is in Mossbarrow)")
	var wm = lab.hud.world_map
	wm.open("world")
	await _wait(0.3)
	var locked := 0
	for n in wm.act_nodes(1): if bool(n.get("locked", false)): locked += 1
	check(wm.act_nodes(1).size() == 15 and locked == 0, "All 15 Act I zones are on the map and reachable")
	await _shot("world_map")
	wm.close()
	print("AOTL ACT I LATE RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
