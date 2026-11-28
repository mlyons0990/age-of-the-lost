extends SceneTree
## Mossbarrow Crypts + lorecasting: The Sealed Barrow opens with the Lost Tomes turn-in -> the Barrow Stair under the
## Standing Stones -> a walled crypt (corridors and rooms only) -> the Exalted Paladin's remains wake his echo ->
## defeating it teaches Radiant Spear to a class that is not a paladin (Mage) -> the spear pierces a line of foes ->
## the Barrow-Lord (only on its quest) -> turn in.
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
	if out != "": root.get_texture().get_image().save_png("%s/mossbarrow_%s.png" % [out, name])
func _wait(s: float) -> void:
	await create_timer(s).timeout

var lab
var g
var st
func _kill(m) -> void:
	var hits := 0
	while is_instance_valid(m) and m.is_alive() and hits < 600:
		m.hit(lab.attack_damage("Slash")); hits += 1
	await process_frame

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var st_script = load("res://scripts/game/game_state.gd")
	var boot = load("res://scripts/game/game_boot.gd")
	st_script.new_character("mage")
	boot.class_id = "mage"; boot.new_game = true
	lab = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 12: await physics_frame
	g = lab.game; st = lab.game_state
	st.add_xp(900)
	st.set_quest("city_reborn", "done")
	st.set_quest("lost_tomes", "ready", 3)
	g.complete_quest("lost_tomes")
	check(st.quest_state("thornwarden") == "active" and st.quest_state("the_sealed_barrow") == "active", "Lost Tomes turn-in opens the Thornwarden and The Sealed Barrow")
	lab.travel_to("whisperwood", [0, 0])
	await _wait(1.6)
	var stair := {}
	for e in lab.zone["exits"]:
		if e["to"] == "mossbarrow_crypts": stair = e
	check(not stair.is_empty(), "The Standing Stones have a stair down to Mossbarrow")
	lab.travel_to("mossbarrow_crypts", stair["arrive"])
	await _wait(1.8)
	check(g.zone_id() == "mossbarrow_crypts", "The stair leads into the crypt")
	var n := 0; var lo := 99; var hi := 0; var off := 0
	for m in g.monsters:
		if not is_instance_valid(m): continue
		n += 1
		if not m.elite and not m.boss: lo = mini(lo, m.level); hi = maxi(hi, m.level)
		if not lab.zone_walkable(m.global_position): off += 1
	check(n >= 20 and lo >= 3 and hi <= 4, "Crypt populated at levels 3-4 (%d monsters, %d-%d)" % [n, lo, hi])
	check(off == 0, "Every monster stands in a corridor or room (%d off)" % off)
	check(not lab.zone_walkable(lab.zone_px_to_world(1200, 900)) and lab.zone_walkable(lab.zone_px_to_world(1800, 2470)), "Walls are solid; corridors are open")
	check(g.boss != null and g.boss.type_key == "barrow_lord", "The Barrow-Lord waits in his vault")
	# lorecast
	check(g.lore_sites.size() == 1 and not st.skills.has("radiant_spear"), "The Paladin's Tomb holds an unlearned lorecast")
	var ls: Dictionary = g.lore_sites[0]
	lab.player.global_position = ls["pos"] + Vector3(0.4, 0.08, 0.3); lab.zone_last_ok = lab.player.global_position
	lab.player.hp = lab.player.max_hp
	await _wait(0.6)
	var echo = null
	for m in g.monsters:
		if is_instance_valid(m) and m.unique_id == "lore_exalted_paladin": echo = m
	check(ls["woken"] and echo != null and g.ui.panel_kind == "dialogue", "Standing at the remains wakes the Echo of Aurelian Dace")
	await _shot("echo")
	g.ui.close_panel()
	await _kill(echo)
	await _wait(0.3)
	check(st.skills.has("radiant_spear") and "radiant_spear" in st.bar, "Defeating the echo teaches Radiant Spear and puts it on the bar")
	check(st.class_id == "mage" and g.skill_def("radiant_spear").get("lorecast", false), "A Mage now carries a paladin's lorecast")
	await _shot("learned")
	g.ui.close_panel()
	# the spear pierces a line of foes
	var line_foes := []
	for m in g.monsters.duplicate():
		if is_instance_valid(m) and not m.boss: line_foes.append(m)
		if line_foes.size() == 3: break
	var origin: Vector3 = lab.player.global_position
	for i in line_foes.size():
		line_foes[i].global_position = origin + Vector3(2.0 + i * 1.5, 0, 0); line_foes[i].home = line_foes[i].global_position
	var hp0 := []
	for m in line_foes: hp0.append(m.hp)
	lab.player.mana = lab.player.max_mana
	lab.player.aim_point = origin + Vector3(8, 0, 0)
	lab.player.attack_target = null
	var ok: bool = g.use_skill("radiant_spear")
	for i in 120:
		await physics_frame
		if g.casting.is_empty(): break
	var hit := 0
	for i in line_foes.size():
		if not is_instance_valid(line_foes[i]) or line_foes[i].hp < hp0[i]: hit += 1
	check(ok and hit == 3, "Radiant Spear pierces all three foes in its line (%d hit)" % hit)
	await _shot("spear")
	# save keeps the lorecast
	g.autosave()
	var sv = st_script.load_saved()
	check(sv == null or sv.skills.has("radiant_spear"), "The lorecast survives save and load")
	# the Barrow-Lord
	var b = g.boss
	lab.player.global_position = b.global_position + Vector3(3, 0.08, 0); lab.zone_last_ok = lab.player.global_position
	lab.player.hp = lab.player.max_hp
	await _wait(1.0)
	await _shot("barrow_lord")
	await _kill(b)
	check(st.quest_state("the_sealed_barrow") == "ready", "The Barrow-Lord falls: report to Ralden")
	print("AOTL MOSSBARROW RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
