extends SceneTree
const Rules := preload("res://scripts/encounter_rules.gd")
const GD := preload("res://scripts/game_data.gd")
var main: Node2D
var p: Node2D
var trial: Node2D
var checks := 0
var failures := 0
var report: Array[String] = []
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1; report.append(("PASS " if ok else "FAIL ")+message); print(report[-1])
	if not ok: failures += 1
func frames(n := 3) -> void:
	for i in n: await process_frame
func reset_actor(branch := "", class_id := "mage", level := 40) -> void:
	paused = false
	trial.finish(false,"Fixture reset",false)
	for e in main.enemies.duplicate(): e.queue_free()
	main.enemies.clear()
	for child in main.world.get_children():
		if child.has_meta("cantor_trial") or child.get_script() == load("res://scripts/loot.gd"): child.queue_free()
	main.loot.clear()
	for fx in [main.fx_ground,main.fx_parts,main.fx_text]: fx.items.clear()
	var ui: CanvasLayer = main.hud
	for field in ["choice_panel","death_panel","start_panel","char_panel"]:
		if ui.get(field) != null: ui.get(field).queue_free(); ui.set(field,null)
	ui.page = ""; ui._refresh_pause()
	main.save_blocked = false; main.rift.active = false; main.encounter_wins = 0
	p.cancel_casts(); p.aura.healing.clear(); p.class_id = class_id; p.level = level; p.xp = 0
	p.spec = "mage_fire" if class_id == "mage" and level >= 20 else ""
	p.adv = "pyromancer" if class_id == "mage" and level >= 40 else ""
	p.mastery = {}
	if branch != "": p.mastery = {"ward_temper":1,"ember_aura":1,branch:1}
	p.discoveries = ["first_echo"]; p.crafted_uniques.clear(); p.inventory.clear(); p.stash.clear()
	for slot in p.gear: p.gear[slot] = null
	p.hotbar = GD.CLASSES[class_id].starting.duplicate()
	p.dead = false; p.invuln = 0; p.cds.clear(); p.cd_full.clear(); p.clock = 0
	p.attack_anim = 0; p.rally = 0; p.last_hurt = -100; p.position = main.START
	p.path = PackedVector2Array(); p.target = null; p.mouse_held = false
	p.gold = 100; p.potions = 3; p.hp = p.stats().max_hp; p.mp = p.stats().max_mp
	p.refresh_visuals()
func freeze_enemies() -> void:
	for e in main.enemies: e.set_process(false)
func tick(duration: float) -> void:
	var left := duration
	while left > 0:
		var step := minf(0.05,left); trial.advance(step); left -= step
func point(origin: Vector2, x: float, y: float) -> Vector2: return origin+GD.to_px(Vector2(x,y))
func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/encounter/"+name+".png")
func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main = current_scene; p = main.player; trial = main.encounter
	main.sound.set_muted(true) # Cues have their own audible integration suite; deterministic stepping does not clock the mixer.
	main.dialogue.set_voice_enabled(false) # Dialogue playback is exercised by its own integration suite.
	main.set_process(false); p.set_physics_process(false); trial.set_process(false)
	DirAccess.make_dir_recursive_absolute("res://previews/encounter")
	reset_actor()
	var o: Vector2 = main.START
	var line := Rules.warning("line",o,point(o,5,0),false)
	check(Rules.contains(line,point(o,4,0)),"locked lane contains its center")
	check(not Rules.contains(line,point(o,4,0.9)),"sideways movement clears lane including actor radius")
	check(not Rules.contains(line,point(o,-0.5,0)),"positions behind lane origin are safe")
	check(not Rules.contains(line,point(o,7.5,0)),"lane has a finite endpoint")
	check(Rules.contains(line,point(o,4,0.7)),"actor-radius contact at lane edge is counted")
	var seals := Rules.warning("seals",o,point(o,2,1),false)
	check(seals.centers.size()==3 and Rules.contains(seals,seals.centers[0]),"seal volley holds three captured centers")
	check(not Rules.contains(seals,point(o,2,3)),"moving away from captured seals is safe")
	var ring := Rules.warning("ring",o,point(o,2,0),false)
	check(not Rules.contains(ring,o),"ring center is a real safe zone")
	check(Rules.contains(ring,point(o,2,0)),"ring annulus damages occupied band")
	check(not Rules.contains(ring,point(o,3.7,0)),"ring exterior is safe including actor radius")
	check(Rules.contains(ring,point(o,1.1,0)),"ring inner-edge collision includes actor radius")
	var minimum := 100.0
	for kind in Rules.ORDER: minimum = minf(minimum,Rules.warning(kind,o,point(o,1,0),true).duration)
	check(minimum>=1.05,"second-verse warnings retain at least 1.05 seconds")
	check(Rules.tuning(1).boss_hp==360 and Rules.tuning(60).boss_hp>Rules.tuning(40).boss_hp,"authored health curve scales from level one through sixty")
	check(Rules.tuning(100).level==60 and Rules.tuning(-1).level==1,"encounter tuning clamps supported levels")
	main.rift.active = true
	check(not trial.start() and main.enemies.is_empty(),"Reality Scar blocks trial without spawning anything")
	main.rift.active = false; main.save_blocked = true
	check(not trial.start(),"protected save blocks trial rewards and entry")
	main.save_blocked = false; p.dead = true
	check(not trial.start(),"dead player cannot enter")
	p.dead = false; paused = true
	check(not trial.start(),"entry requires dismissing the paused briefing")
	paused = false; p.hp = 333; p.mp = 91; p.cds.cinder_thread = 2
	check(trial.start() and main.combat_active() and main.enemies.size()==3,"entry spawns one boss and two real fragments")
	freeze_enemies()
	check(p.hp==333 and p.mp==91 and p.cds.cinder_thread==2,"entry preserves resources and cooldowns")
	check(not trial.start() and main.enemies.size()==3,"repeated entry cannot duplicate boss or adds")
	check(not p.change_mastery("ward_temper").ok,"active trial blocks mastery transactions")
	main.hud.open_page("merchant")
	check(main.hud.char_panel==null and not paused,"active trial blocks town merchant")
	main._enter_articulation_lab()
	check(current_scene==main,"active trial blocks F7 scene changes")
	var clock_before: float = trial.elapsed
	main.hud.open_page("inventory"); trial.advance(0.2)
	check(paused and trial.elapsed==clock_before,"inventory freezes encounter warnings and elapsed time")
	main.hud.close_page()
	tick(2.05)
	check(trial.warnings.size()==1 and trial.warnings[0].kind=="line","rotation starts with one committed line warning")
	var warning: Dictionary = trial.warnings[0]
	var captured: Vector2 = warning.direction
	p.position = point(trial.boss.position,-2,0)
	check(warning.direction==captured,"moving after warning cannot retarget line")
	var before: float = p.hp
	tick(1.3)
	check(p.hp==before and trial.metrics.resolved==1,"dodging live warning avoids damage at resolution")
	tick(2.5)
	check(trial.warnings.size()==1 and trial.warnings[0].kind=="seals","rotation advances to captured ground seals")
	p.position = trial.warnings[0].centers[0]; before = p.hp
	tick(1.55)
	check(p.hp<before and trial.metrics.contacts==1,"standing in a seal damages through real armor resolver")
	before = p.hp; tick(0.5)
	check(p.hp==before and trial.metrics.contacts==1,"impact art cannot apply repeated damage")
	trial.boss.hp = trial.boss.max_hp*0.49; trial.advance(0.01); freeze_enemies()
	check(trial.second_phase and main.enemies.size()==5,"half-health phase adds exactly two fragments")
	trial.advance(0.05)
	check(main.enemies.size()==5,"second verse cannot repeatedly spawn adds")
	var gold: int = p.gold
	main.toggle_rift()
	check(not trial.active and not main.rift.active and main.enemies.is_empty(),"R retreats instead of opening a concurrent Scar")
	check(trial.warnings.is_empty() and trial.impacts.is_empty() and p.gold==gold,"retreat clears hazards and awards no gold")
	before = p.hp; trial.advance(0.2)
	check(p.hp==before,"no delayed warning can damage after retreat")
	reset_actor(); trial.start(); freeze_enemies(); p.position = point(trial.center,7.1,0); trial.advance(0.05)
	check(not trial.active and trial.last_result.begins_with("Retreated beyond"),"leaving arena ends trial without an invisible wall")
	reset_actor(); trial.start(); freeze_enemies(); trial.advance(0.6)
	check(not trial.active and trial.metrics.resolved==0,"long frames stop trial without resolving a damage backlog")
	reset_actor(); trial.start(); freeze_enemies(); tick(2.1); p.hp = 1; p.invuln = 0
	p.position = trial.warnings[0].origin+GD.to_px(trial.warnings[0].direction*1.8); tick(1.3)
	check(p.dead and not trial.active and main.enemies.is_empty(),"lethal seal ends encounter and cleans every owned enemy")
	check(trial.warnings.is_empty() and trial.impacts.is_empty(),"synchronous death cannot restore impact hazards after cleanup")
	reset_actor(); trial.start(); freeze_enemies(); gold = p.gold; var earned: int = trial.tune.gold
	p.damage_enemy(trial.boss,trial.boss.hp*2)
	check(not trial.active and main.encounter_wins==1,"real boss killing hit commits victory once")
	check(p.gold==gold+earned and trial.metrics.reward_gold==earned,"victory grants exact level-scaled gold")
	check(main.loot.size()==1 and main.loot[0].kind=="item" and int(main.loot[0].item.level)<=60,"victory produces one valid collectable gear drop")
	check(p.xp>0 and main.enemies.is_empty(),"victory awards XP and clears surviving fragments")
	gold = p.gold; trial.finish(true,"Duplicate finish")
	check(p.gold==gold and main.encounter_wins==1 and main.loot.size()==1,"duplicate terminal calls cannot duplicate rewards")
	var saved: Dictionary = main._read_save(main.SAVE_PATH)
	check(main._valid_save(saved) and saved.encounter_wins==1,"victory count persists in valid schema-six save")
	var legacy := saved.duplicate(true); legacy.erase("encounter_wins")
	check(main._valid_save(legacy),"earlier schema-six saves default to zero victories")
	var rejects := true
	for value in [-1,0.5,"4",1000000]:
		var invalid := saved.duplicate(true); invalid.encounter_wins = value
		rejects = rejects and not main._valid_save(invalid)
	check(rejects,"save validation rejects negative fractional string and oversized records")
	trial.start(); freeze_enemies(); tick(2.1)
	check(main.load_game() and not trial.active and trial.warnings.is_empty() and main.encounter_wins==1,"loading cancels transient run and restores committed record")
	for branch in ["cinder_bloom","siphon_embers"]:
		reset_actor(branch); trial.start(); freeze_enemies()
		for e in main.enemies:
			if e != trial.boss: e.hp = 10000; e.max_hp = e.hp
		p.position = point(trial.boss.position,0,1.4); p.hp = p.stats().max_hp*0.5
		check(p.use_skill("s3",p.position) and p.aura.running,branch+" enters trial with actual equipped aura")
		before = trial.boss.hp; var hp_before: float = p.hp
		p.clock += 0.5; p.aura.advance(0.5)
		check(trial.boss.hp<before,branch+" paid pulse damages real rooted boss")
		if branch == "siphon_embers": check(p.hp>hp_before,"Siphon restores bounded health from actual boss HP removed")
		else:
			var add: Node2D = main.enemies[1]; add.position = p.position; add.hp = 1; add.burn = 1; add.burn_dps = 0.1
			p.clock += 0.5; p.aura.advance(0.5)
			check(p.aura.patches.size()==1 and trial.metrics.adds_defeated==1,"Bloom turns burning trial fragment death into one live patch")
			# Reproduce a secondary killing hit that synchronously clears its own patch list.
			trial.boss.position = p.aura.patches[0].at; trial.boss.hp = 1
			p.clock += 0.5; p.aura.advance(0.5)
			check(not trial.active and not p.aura.running,"patch boss kill safely cancels aura during patch iteration")
		if trial.active: trial.finish(false,"Branch check")
		check(not p.aura.running and p.aura.patches.is_empty(),branch+" leaves no aura or patch after terminal cleanup")
	reset_actor("cinder_bloom"); trial.start(); freeze_enemies(); trial.next_attack = 0; trial.advance(0.01)
	main.hud.banner_t = 10; main.hud.toasts.clear(); await shot("cantor_line")
	trial.warnings = [Rules.warning("seals",trial.boss.position,p.position,false)]; trial.queue_redraw(); await shot("cantor_seals")
	trial.warnings = [Rules.warning("ring",trial.boss.position,p.position,false)]; trial.queue_redraw(); await shot("cantor_ring")
	main.hud.open_page("trial"); await shot("cantor_briefing")
	check(paused and main.hud.page=="trial","trial briefing opens during combat with frozen warnings and retreat action")
	main.hud.close_page(); trial.finish(false,"Preview complete")
	reset_actor("","warrior",1)
	check(trial.start() and trial.boss.level==1 and trial.boss.max_hp==360,"level-one Warrior can enter the same authored encounter")
	freeze_enemies(); trial.finish(false,"Warrior smoke")
	report.append("ENCOUNTER RESULT %d checks; %d failures" % [checks,failures]); print(report[-1])
	var f := FileAccess.open("res://ENCOUNTER_TEST_RESULTS.txt",FileAccess.WRITE); f.store_string("\n".join(report)+"\n"); f.close()
	await main.sound.drain()
	quit(1 if failures else 0)
