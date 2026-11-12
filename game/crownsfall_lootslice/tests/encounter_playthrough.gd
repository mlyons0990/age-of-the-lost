extends "res://tests/encounter_integration.gd"
## Fixed-step scripted playthroughs. Navigation, cast roots, projectiles, burns,
## armor, mana and warning hits use production code. This is not human tuning.
const Projectile := preload("res://scripts/projectile.gd")
var bouts: Array = []
func safe(at: Vector2) -> bool:
	for w in trial.warnings:
		if Rules.contains(w,at,0.45): return false
	return true
func goal_for(target: Node2D) -> Vector2:
	var preferred := target.position+GD.to_px(Vector2(0,1.5 if p.class_id=="mage" else 0.8))
	if safe(preferred): return preferred
	var best := p.position; var distance := INF
	for radius in [0.6,1.0,1.8,2.8,4.0]:
		for i in 24:
			var a := TAU*i/24.0
			var at := target.position+GD.to_px(Vector2(cos(a),sin(a))*radius)
			if not safe(at) or GD.gdist(at,trial.center)>6.5: continue
			var nav := NavigationServer2D.map_get_closest_point(main.get_world_2d().navigation_map,at)
			if nav.distance_to(at)>6: continue
			var score := GD.gdist(p.position,at)+absf(radius-1.5)*0.12
			if score<distance: distance=score; best=at
	return best
func target_for() -> Node2D:
	var best: Node2D = trial.boss
	for e in main.enemies:
		if e!=trial.boss and e.dead_t<0: best=e; break
	return best
func bout(class_id: String, level: int, branch: String, run_seed: int) -> void:
	reset_actor(branch,class_id,level); await physics_frame; await frames()
	seed(run_seed)
	if branch != "": p.hotbar=["cinder_thread","solar_writ","arcane_fold","ashen_ward","starfall_script"]
	for fx in [main.fx_ground,main.fx_parts,main.fx_text]: fx.set_process(false)
	trial.start()
	if branch != "": p.hp *= 0.5
	var started_hp: float=p.hp; var step:=0.05; var ticks:=0; var casts:=0; var min_mana: float=p.mp
	var paid:=0; var bloom_seen:=false; var heal_total:=0.0
	while trial.active and not p.dead and ticks<2400:
		var target := target_for()
		var goal := goal_for(target)
		p._walk_to(goal,false)
		var can_commit := safe(p.position)
		if branch!="" and not p.aura.running and p.mp>30:
			if p.use_skill("s3",p.position): casts+=1
		elif can_commit:
			if p.class_id=="mage":
				if level>=20 and GD.gdist(p.position,target.position)<4.8 and float(p.cds.get("solar_writ",0))<=0:
					if p.use_skill("s1",target.position): casts+=1
				elif p.use_skill("basic",target.position): casts+=1
			elif GD.gdist(p.position,target.position)<p.primary_reach()+target.rad-0.15:
				if p.use_skill("basic",target.position): casts+=1
		if p.hp<p.stats().max_hp*0.35: p.drink_potion()
		var hp_before: float=p.hp
		p._physics_process(step)
		heal_total+=maxf(0,p.hp-hp_before)
		paid=maxi(paid,p.aura.paid_pulses); bloom_seen=bloom_seen or not p.aura.patches.is_empty()
		min_mana=minf(min_mana,p.mp)
		for child in main.get_children():
			if child.get_script()==Projectile:
				child.set_physics_process(false)
				if not child.is_queued_for_deletion(): child._physics_process(step)
		for e in main.world.get_children():
			if e.has_meta("cantor_trial"):
				e.set_process(false)
				if not e.is_queued_for_deletion(): e._process(step)
		for fx in [main.fx_ground,main.fx_parts,main.fx_text]: fx._process(step)
		trial.advance(step)
		ticks+=1
		if branch=="cinder_bloom" and OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name()!="headless" and ticks%4==0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://previews/encounter/trial_frame_%04d.png" % ticks)
		if ticks%10==0: await frames(1)
	var won: bool=main.encounter_wins==1
	var result := {"class":class_id,"level":level,"branch":branch,"seed":run_seed,"won":won,"seconds":snappedf(ticks*step,0.05),"casts":casts,"start_hp":started_hp,"end_hp":p.hp,"minimum_mana":min_mana,"aura_paid_pulses":paid,"bloom_patch_seen":bloom_seen,"total_positive_hp_changes":heal_total,"potions_remaining":p.potions,"metrics":trial.metrics.duplicate(true)}
	bouts.append(result); print(JSON.stringify(result))
	check(won,"scripted "+class_id+" level "+str(level)+" "+branch+" completes production encounter")
	check(not p.dead and trial.warnings.is_empty() and not p.aura.running,"completed bout clears attack and aura state")
	check(casts>0 and int(result.metrics.resolved)>0,"bout exercises real casts and at least one resolved warning")
	if branch!="": check(paid>0,"mastery bout pays actual aura upkeep")
	if branch=="cinder_bloom": check(bloom_seen,"Bloom playthrough produces a real fragment-death patch")
	if trial.active: trial.finish(false,"Bout timed out")
func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main=current_scene; p=main.player; trial=main.encounter; main.sound.set_muted(true)
	main.set_process(false); p.set_physics_process(false); trial.set_process(false)
	await bout("mage",1,"",1001)
	await bout("warrior",1,"",1002)
	await bout("mage",40,"cinder_bloom",1040)
	await bout("mage",40,"siphon_embers",2040)
	var f:=FileAccess.open("res://data/encounter_scripted_bouts.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"step":0.05,"method":"Scripted navigation and fixed-step production components; not human/hardware performance","bouts":bouts},"  ")); f.close()
	print("ENCOUNTER BOUT RESULT %d checks; %d failures" % [checks,failures])
	await main.quit_game(1 if failures else 0)
