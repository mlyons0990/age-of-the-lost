extends SceneTree
## Chapter II, end to end: Thornwarden turn-in -> "Into the Mere" -> the Whisperwood's mossy arch -> Hollowmere
## (arrival completes the quest) -> marsh monsters at levels 5-9 -> the three lantern guardians drop Warden's Flames ->
## turn in -> the Drowned Matron appears only with its quest -> she summons mire wisps -> turn in -> Chapter II epilogue.
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
	if out != "": root.get_texture().get_image().save_png("%s/hollowmere_%s.png" % [out, name])
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

func _kill(m) -> void:
	var hits := 0
	while is_instance_valid(m) and m.is_alive() and hits < 400:
		m.hit(lab.attack_damage("Slash")); hits += 1
	await process_frame

func _guardian(page: String):
	for m in g.monsters:
		if is_instance_valid(m) and m.drops_page == page: return m
	return null

func _collect_quest_items() -> int:
	var n := 0
	for l in g.loot.duplicate():
		if is_instance_valid(l) and String(l.kind) == "quest": g._pickup(l); n += 1
	return n

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var st_script = load("res://scripts/game/game_state.gd")
	var boot = load("res://scripts/game/game_boot.gd")
	st_script.new_character("mage")
	boot.class_id = "mage"; boot.new_game = true
	await _start()
	var st = lab.game_state
	# a hero who has finished Chapter I up to the Thornwarden turn-in
	st.add_xp(6000)
	for id in ["city_reborn", "lost_tomes"]: st.set_quest(id, "done")
	st.set_quest("thornwarden", "ready", 1)
	g.complete_quest("thornwarden")
	await _wait(0.2)
	check(g.ui.panel_kind == "epilogue", "Thornwarden turn-in still shows the Chapter I epilogue")
	check(st.quest_state("into_the_mere") == "active", "Chapter II begins: Into the Mere")
	await _shot("epilogue_ch1")
	g.ui.close_panel()
	# the arch in the Whisperwood
	lab.travel_to("whisperwood", [0, 0])
	await _wait(1.6)
	var arch := {}
	for e in lab.zone["exits"]:
		if e["to"] == "hollowmere": arch = e
	check(not arch.is_empty(), "The Whisperwood has an exit to Hollowmere")
	var qv := {}
	for q in g.quest_view(): if q["id"] == "into_the_mere": qv = q
	check(not qv.is_empty() and qv["markers"].size() == 1 and qv["markers"][0]["zone"] == "whisperwood_forest", "Tracker marks the mossy arch")
	lab.travel_to("hollowmere", arch["arrive"])
	await _wait(1.8)
	check(g.zone_id() == "hollowmere", "The arch leads to Hollowmere")
	check(st.quest_state("into_the_mere") == "done" and st.quest_state("drowned_lanterns") == "active", "Arriving completes Into the Mere; The Drowned Lanterns begins")
	var types := {}; var lo := 99; var hi := 0; var n := 0
	for m in g.monsters:
		if not is_instance_valid(m): continue
		n += 1; types[m.type_key] = true
		if m.drops_page == "": lo = mini(lo, m.level); hi = maxi(hi, m.level)
	check(n >= 60, "Hollowmere is populated (%d monsters)" % n)
	check(types.has("bog_ghoul") and types.has("mire_lurker") and types.has("mire_wisp"), "Marsh monster types present %s" % [types.keys()])
	check(lo >= 5 and hi <= 9, "Monster levels within 5-9 (%d-%d)" % [lo, hi])
	check(g.boss == null, "The Drowned Matron is not there before her quest")
	var wisp = null
	for m in g.monsters:
		if m.type_key == "mire_wisp": wisp = m; break
	check(wisp != null and wisp.type_tint != Color.WHITE and wisp.sprite != null, "Marsh types reuse painted art with their own tint")
	lab.player.global_position = lab.zone_px_to_world(3700, 2150) + Vector3.UP * 0.08; lab.zone_last_ok = lab.player.global_position
	await _wait(0.8)
	await _shot("ferry")
	# the three lanterns
	for i in 3:
		var page := "lantern_%d" % (i + 1)
		var gd = _guardian(page)
		check(gd != null and gd.unique_id != "", "Lantern guardian %s (%s)" % [page, gd.ename if gd else "missing"])
		if gd == null: continue
		if i == 0:
			lab.player.global_position = gd.global_position + Vector3(3.5, 0.08, 0); lab.zone_last_ok = lab.player.global_position
			await _wait(0.8)
			await _shot("guardian")
		await _kill(gd)
		await _wait(0.3)
		var got := _collect_quest_items()      # (or already picked up by walking over it)
		check(got <= 1 and int(st.quest("drowned_lanterns").get("progress", 0)) == i + 1, "Guardian drops a Warden's Flame (%d/3)" % (i + 1))
	check(st.quest_state("drowned_lanterns") == "ready", "Three flames: return to Ralden")
	var hidden := true
	for q in g.quest_view():
		if q["id"] == "drowned_lanterns":
			for mk in q["markers"]: if mk.has("page"): hidden = false
	check(hidden, "Collected lanterns leave the tracker")
	lab.travel_to("crownsfall", [1920, 1100])
	await _wait(1.6)
	g.talk("ralden")
	check(g.ui.panel_kind == "dialogue", "Ralden speaks of the flames")
	await _shot("ralden_flames")
	g.ui.close_panel(); g.complete_quest("drowned_lanterns")
	check(st.quest_state("drowned_matron") == "active", "The Drowned Matron quest begins")
	# save + continue keeps Chapter II
	g.autosave()
	boot.class_id = ""; boot.new_game = false
	await _start()
	st = lab.game_state
	check(st.quest_state("drowned_matron") == "active" and st.dead_uniques.has("lantern_willow"), "Continue restores Chapter II quests and slain guardians")
	# the boss — reached via the Ferryman's Rest waypoint
	lab.travel_to("hollowmere", [3700, 2150])
	await _wait(1.8)
	check(g.boss != null and g.boss.type_key == "drowned_matron" and _guardian("lantern_2") == null, "The Drowned Matron rises in the Sunken Chapel; slain guardians stay dead")
	lab.player.global_position = g.boss.global_position + Vector3(3.0, 0.08, 0); lab.zone_last_ok = lab.player.global_position
	lab.player.hp = lab.player.max_hp
	await _wait(2.0)
	check(g.boss.state != "idle" and g.ui.boss_bar.visible, "Boss engages; boss bar shows")
	await _shot("boss")
	var b = g.boss
	while is_instance_valid(b) and b.is_alive() and b.hp > b.max_hp * 0.45: b.hit(lab.attack_damage("Slash"))
	await _wait(0.3)
	var wisps := 0
	for m in g.monsters:
		if is_instance_valid(m) and m.type_key == "mire_wisp" and m.global_position.distance_to(b.global_position) < 8.0: wisps += 1
	check(b.summoned and wisps > 0, "She calls mire wisps at half life (%d nearby)" % wisps)
	await _kill(b)
	check(st.quest_state("drowned_matron") == "ready", "Slaying the Drowned Matron completes the objective")
	lab.travel_to("crownsfall", [1920, 1100])
	await _wait(1.6)
	g.talk("ralden"); g.ui.close_panel(); g.complete_quest("drowned_matron")
	await _wait(0.2)
	check(g.ui.panel_kind == "epilogue", "Chapter II complete: epilogue")
	await _shot("epilogue_ch2")
	print("AOTL HOLLOWMERE RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
