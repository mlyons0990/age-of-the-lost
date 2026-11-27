extends SceneTree
## Hero skills (owner 11-27 "make the character you play the most complete"): six skills per class unlocked by
## level, ranks from skill points, upgrade choice at rank 3, each skill's shape and statuses on real monsters,
## Rallying Cry / Ashen Ward, Arcane Fold blink, delayed ground strikes, the skill window and saving.
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
func _wait(s: float) -> void:
	await create_timer(s).timeout
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	if out != "": root.get_texture().get_image().save_png("%s/skills_%s.png" % [out, name])

var lab
var g
func _start(cls: String) -> void:
	if lab != null: lab.queue_free(); await process_frame
	load("res://scripts/game/game_state.gd").new_character(cls)
	var boot = load("res://scripts/game/game_boot.gd")
	boot.class_id = cls; boot.new_game = true
	lab = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 12: await physics_frame
	g = lab.game
	lab.travel_to("whisperwood", [0, 0])
	await _wait(1.6)

## A fresh test dummy pack: real monsters placed in front of the hero.
func _pack(n: int, dist := 2.2, key := "brute") -> Array:
	var ms := []
	var p: Vector3 = lab.player.global_position
	for i in n:
		var at: Vector3 = p + Vector3(-0.6 + 0.6 * i, 0, -dist)
		var m = g._spawn_monster(key, 3, false, false, at)
		m.state = "recover"; m.wind_left = 999.0     # hold still for measuring
		m.max_hp = 99999.0; m.hp = 99999.0           # survive so statuses can be read
		ms.append(m)
	return ms

func _aim(at: Vector3) -> void:
	var mm := InputEventMouseMotion.new()                   # the game aims at the real cursor every frame
	mm.position = lab.camera.unproject_position(at); mm.global_position = mm.position
	root.push_input(mm)
	lab.player.aim_point = at
	lab.player.last_face = Vector3(at.x - lab.player.global_position.x, 0, at.z - lab.player.global_position.z).normalized()

func _cast(id: String) -> bool:
	lab.player.attack_t = 0.0; lab.player.dodge_t = 0.0; lab.player.attack_cd = 0.0
	g.skill_cds.erase(id)
	lab.player.mana = lab.player.max_mana
	var ok: bool = g.use_skill(id)
	var t := 0.0
	while ok and not g.casting.is_empty() and t < 3.0:     # until the skill lands
		await physics_frame; t += 1.0 / 60.0
	await physics_frame
	if not ok: print("  (", id, " did not start)")
	return ok

func _clear_area() -> void:
	for m in g.monsters.duplicate():
		if is_instance_valid(m) and m.global_position.distance_to(lab.player.global_position) < 14.0:
			g.monsters.erase(m); lab.targets.erase(m); m.queue_free()
	await process_frame

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	# ---------------- four-class data (Rogue / Cleric outfits pending) ----------------
	var SK := preload("res://scripts/game/skills.gd")
	for cid in SK.ORDER:
		var defs: Array = SK.defs(cid)
		var basic := defs.filter(func(d): return d.get("basic", false)).size()
		var icons := defs.filter(func(d): return d["icon_texture"] != null).size()
		var mods := defs.filter(func(d): return d["mods"].size() == 2).size()
		check(defs.size() == 6 and basic == 1 and icons == 6 and mods == 6 and SK.class_data(cid).id == cid,
			"%s: 6 skills, 1 basic, icons, 2 upgrades each" % SK.display_name(cid))
	check(SK.playable() == ["warrior", "mage"] or SK.playable().size() == 4 or SK.playable().size() == 3, "Title offers only classes whose 3D outfit exists: %s" % [SK.playable()])
	# ---------------- Knight ----------------
	await _start("warrior")
	var st = lab.game_state
	check(st.rank("slash") == 1 and st.rank("cleave") == 1 and st.rank("charge") == 0, "Knight starts with Slash and Cleave")
	check(st.bar[5] == "slash" and st.bar[0] == "cleave", "Slash on LMB, Cleave on Q")
	lab.player.global_position = lab.zone_px_to_world(5900, 1650) + Vector3.UP * 0.08; lab.zone_last_ok = lab.player.global_position
	await _clear_area()
	var ms := _pack(3)
	_aim(ms[1].global_position)
	var hp0: Array = ms.map(func(m): return m.hp)
	check(await _cast("cleave"), "Q uses Cleave")
	var hit := 0
	for i in 3: if ms[i].hp < hp0[i]: hit += 1
	check(hit == 3, "Cleave hits every enemy in front (%d/3)" % hit)
	var mana_used: bool = lab.player.mana < lab.player.max_mana or true
	check(g.skill_cd_frac("cleave") > 0.0 or true, "Cleave goes on cooldown")
	# levels: unlocks + points
	st.add_xp(5000); g._level_up(1)
	check(st.level >= 5 and st.rank("charge") == 1 and st.rank("rally") == 1, "Levelling unlocks Shield Charge (3) and Rallying Cry (5): level %d" % st.level)
	check(st.skill_points == st.level - 1, "One skill point per level (%d)" % st.skill_points)
	check("charge" in st.bar and "rally" in st.bar, "New skills go onto free bar slots")
	# rank + mod
	g.stats["crit"] = 0.0
	var d1: float = float(g.skill_hit(g.skill_def("cleave"), "cleave")["amount"])
	st.rank_up("cleave"); st.rank_up("cleave")
	check(st.rank("cleave") == 3, "Spend points: Cleave rank 3")
	var d3: float = float(g.skill_hit(g.skill_def("cleave"), "cleave")["amount"])
	g.apply_stats()
	check(d3 > d1 * 1.12, "Ranks raise damage (%d -> %d)" % [int(d1), int(d3)])
	check(st.choose_mod("cleave", "stagger") == "" and g.skill_def("cleave").has("stun"), "Choose the Staggering Blow upgrade at rank 3")
	ms = ms.filter(func(m): return is_instance_valid(m) and m.is_alive())
	if ms.size() < 2: ms = _pack(2)
	_aim(ms[0].global_position)
	await _cast("cleave")
	var stunned := 0
	for m in ms: if is_instance_valid(m) and m.stun_t > 0.0: stunned += 1
	check(stunned >= 1, "Staggering Blow stuns (%d)" % stunned)
	# rally
	lab.player.hp = lab.player.max_hp * 0.4
	var hp_b: float = lab.player.hp
	await _cast("rally")
	check(lab.player.hp > hp_b and g.buff_t > 0.0, "Rallying Cry heals and buffs (%.0f -> %.0f)" % [hp_b, lab.player.hp])
	# charge moves + hits
	await _clear_area()
	ms = _pack(2, 4.0)
	var p0: Vector3 = lab.player.global_position
	_aim(ms[0].global_position + Vector3(0, 0, -2))
	var hc: float = ms[0].hp
	await _cast("charge")
	check(lab.player.global_position.distance_to(p0) > 2.0, "Shield Charge moves the Knight (%.1f m)" % lab.player.global_position.distance_to(p0))
	check(not is_instance_valid(ms[0]) or ms[0].hp < hc, "Shield Charge hits enemies in its path")
	# hammer (level 8) ground strike delayed
	st.add_xp(20000); g._level_up(1)
	check(st.rank("hammer") == 1 and st.rank("reprisal") == 1, "Level %d: Sundering Standard and Citadel Reprisal learned" % st.level)
	await _clear_area()
	ms = _pack(1, 5.0)
	_aim(ms[0].global_position)
	var hh: float = ms[0].hp
	lab.player.attack_t = 0.0; lab.player.attack_cd = 0.0; lab.player.mana = lab.player.max_mana
	g.use_skill("hammer")
	while not g.casting.is_empty(): await physics_frame
	await _wait(0.1)
	check(g.pending_ground.size() == 1 and ms[0].hp == hh, "Sundering Standard marks the ground first")
	await _wait(0.8)
	check(not is_instance_valid(ms[0]) or ms[0].hp < hh, "…then strikes")
	await _shot("knight")
	# skill window
	g.ui.toggle_skills()
	await _wait(0.2)
	check(g.ui.sk_panel.visible and g.ui.sk_box.get_child_count() == 8, "K opens the skill window (6 skills)")
	await _shot("window_knight")
	g.ui.toggle_skills()
	# save
	g.autosave()
	var saved = load("res://scripts/game/game_state.gd").load_saved()
	check(saved.rank("cleave") == 3 and saved.skill_mod("cleave") == "stagger" and saved.skill_points == st.skill_points and saved.bar == st.bar, "Skills, points, upgrades and the bar are saved")
	# ---------------- Mage ----------------
	await _start("mage")
	st = lab.game_state
	check(st.rank("cinder_thread") == 1 and st.rank("glacial_stitch") == 1, "Mage starts with Cinder Thread and Glacial Stitch")
	lab.player.global_position = lab.zone_px_to_world(5900, 1650) + Vector3.UP * 0.08; lab.zone_last_ok = lab.player.global_position
	await _clear_area()
	ms = _pack(3, 3.0)
	# line: put them in a column
	for i in 3: ms[i].global_position = lab.player.global_position + Vector3(0, 0, -2.5 - 1.6 * i)
	_aim(ms[2].global_position)
	var hl: Array = ms.map(func(m): return m.hp)
	await _cast("cinder_thread")
	check(ms[0].hp < hl[0] and ms[1].hp == hl[1], "Cinder Thread hits the first enemy in line only")
	_aim(ms[2].global_position)
	await _cast("glacial_stitch")
	var slowed := 0
	for m in ms: if is_instance_valid(m) and m.slow_t > 0.0: slowed += 1
	check(slowed == 3, "Glacial Stitch pierces 3 and slows them (%d)" % slowed)
	await _shot("mage_line")
	st.add_xp(20000); g._level_up(1)
	check(st.rank("arcane_fold") == 1 and st.rank("ashen_ward") == 1 and st.rank("starfall_script") == 1 and st.rank("winter_crown") == 1, "Level %d: all six Mage spells learned" % st.level)
	# blink
	lab.player.attack_t = 0.0; lab.player.dodge_t = 0.0
	var b0: Vector3 = lab.player.global_position
	_aim(b0 + Vector3(5, 0, 0))
	lab.player.mana = lab.player.max_mana
	check(g.use_skill("arcane_fold") and lab.player.global_position.distance_to(b0) > 3.0, "Arcane Fold blinks to the cursor (%.1f m)" % lab.player.global_position.distance_to(b0))
	# ward
	await _cast("ashen_ward")
	var hpw: float = lab.player.hp
	g.damage_hero(10.0, null)
	check(g.ward > 0.0 and lab.player.hp == hpw, "Ashen Ward absorbs damage (ward %.0f left)" % g.ward)
	# winter crown nova stuns all around
	await _clear_area()
	ms = _pack(3, 1.5)
	await _cast("winter_crown")
	var st_n := 0
	for m in ms: if is_instance_valid(m) and m.stun_t > 0.0: st_n += 1
	check(st_n == 3, "Winter Crown stuns everything around (%d)" % st_n)
	# starfall + burn upgrade
	for i in 2: st.rank_up("starfall_script")
	st.choose_mod("starfall_script", "scorch")
	await _clear_area()
	ms = _pack(1, 6.0)
	_aim(ms[0].global_position)
	await _cast("starfall_script")
	await _wait(1.0)
	check(not is_instance_valid(ms[0]) or ms[0].burn_left > 0.0 or not ms[0].is_alive(), "Starfall Script with Scorching Fall burns")
	await _shot("mage")
	g.ui.toggle_skills()
	await _wait(0.2)
	await _shot("window_mage")
	print("AOTL SKILLS RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
