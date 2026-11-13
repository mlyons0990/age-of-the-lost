extends Node2D
## No timers/callbacks survive a run. Committed warnings hold world positions.
const Rules := preload("res://scripts/encounter_rules.gd")
const Boss := preload("res://scripts/trial_boss.gd")
const GD := preload("res://scripts/game_data.gd")
const ARENA_RADIUS := 7.0
var main: Node2D
var active := false
var boss: Node2D
var warnings: Array = []
var impacts: Array = []
var center := Vector2.ZERO
var next_attack := 2.0
var attack_index := 0
var elapsed := 0.0
var second_phase := false
var tune := {}
var last_result := "No attempt yet"
var metrics := {}

func start_problem() -> String:
	if active: return "The trial is already active."
	if main.player.dead: return "Return to life before entering the trial."
	if main.rift.active: return "Close the Reality Scar first."
	if main.loot.size()>=main.LootRules.MAX_DROPS: return "Collect ground loot before entering another trial."
	if main.save_blocked: return "Resolve the protected save before entering the trial."
	return ""
func start() -> bool:
	var problem := start_problem()
	if problem != "": main.hud.toast(problem,Color("ffc28e"),true); return false
	if get_tree().paused: return false
	main.player.cancel_casts()
	main.player.path = PackedVector2Array(); main.player.target = null
	main.player.position = main.START
	center = main.START
	tune = Rules.tuning(main.player.level)
	warnings.clear(); impacts.clear(); attack_index = 0; elapsed = 0; second_phase = false; next_attack = 2.0
	metrics = {"warnings":0,"resolved":0,"contacts":0,"hp_removed":0.0,"adds_defeated":0,"reward_gold":0}
	active = true
	boss = Node2D.new(); boss.set_script(Boss); boss.main = main; boss.player = main.player
	boss.position = center + GD.to_px(Vector2(0,-2.6))
	boss.setup("revenant",true,int(tune.level)); boss.level = int(tune.level)
	boss.max_hp = tune.boss_hp; boss.hp = boss.max_hp; boss.ename = "The Unwritten Cantor"; boss.stun = 0
	boss.set_meta("cantor_trial",true)
	main.world.add_child(boss); main.enemies.append(boss)
	_spawn_adds()
	main.hud.banner("The Unwritten Cantor","Read the floor · R to retreat · T for trial briefing")
	main.dialogue.play_line("cantor_challenge")
	queue_redraw()
	return true
func _spawn_adds() -> void:
	for side in [-1,1]:
		main.spawn_enemy("slime",false,center+GD.to_px(Vector2(side*1.8,-1.5)))
		var e: Node2D = main.enemies[-1]
		e.set_meta("cantor_trial",true); e.level = int(tune.level)
		e.hp = tune.add_hp; e.max_hp = e.hp; e.dmg = float(tune.raw_hit)*0.35
		e.ename = "Unwritten Fragment"
func _process(delta: float) -> void: advance(delta)
func advance(delta: float) -> void:
	if not active or get_tree().paused: return
	delta = maxf(0,delta)
	if main.player.dead: finish(false,"Defeated"); return
	# A suspended browser/tab must not instantly resolve a backlog of attacks.
	if delta > 0.5: finish(false,"Trial suspended after a long frame; no reward"); return
	if GD.gdist(center,main.player.position) > ARENA_RADIUS:
		finish(false,"Retreated beyond the arena"); return
	elapsed += delta
	for impact in impacts: impact.left = float(impact.left)-delta
	impacts = impacts.filter(func(i: Dictionary) -> bool: return i.left > 0)
	for w in warnings.duplicate():
		w.left = float(w.left)-delta
		if w.left <= 0:
			warnings.erase(w); _resolve(w)
			if not active: return
	if not is_instance_valid(boss) or boss.dead_t >= 0: return
	if not second_phase and boss.hp <= boss.max_hp*0.5:
		second_phase = true; _spawn_adds()
		main.dialogue.play_line("cantor_second_verse")
		main.hud.toast("Second verse · quicker warnings, two new fragments",Color("ffd5a2"),true)
	next_attack -= delta
	if next_attack <= 0 and warnings.is_empty() and boss.stun <= 0:
		var kind: String = Rules.ORDER[attack_index%Rules.ORDER.size()]
		warnings.append(Rules.warning(kind,boss.position,main.player.position,second_phase))
		attack_index += 1; metrics.warnings += 1
		next_attack = 3.0 if second_phase else 3.7
	queue_redraw()
func _resolve(w: Dictionary) -> void:
	metrics.resolved += 1
	if Rules.contains(w,main.player.position):
		var before: float = main.player.hp
		metrics.contacts += 1
		main.player.hurt(float(tune.raw_hit),int(tune.level))
		metrics.hp_removed += maxf(0,before-main.player.hp)
	# hurt can synchronously end the run. Do not restore hazards after cleanup.
	if active:
		var impact: Dictionary = w.duplicate(true); impact.left = 0.22
		impacts.append(impact)
func on_defeated(e: Node2D) -> void:
	if not active: return
	if e == boss: finish(true,"Cantor silenced")
	else: metrics.adds_defeated += 1
func finish(victory: bool, reason: String, persist := true) -> void:
	if not active: return
	active = false; warnings.clear(); impacts.clear()
	main.dialogue.stop("encounter")
	main.player.cancel_casts(); main.player.target = null
	for e in main.enemies.duplicate():
		if e.has_meta("cantor_trial"):
			e.dead_t = 0; main.enemies.erase(e)
	last_result = "%s · %.1fs · %d/%d warned attacks contacted" % [reason,elapsed,int(metrics.contacts),int(metrics.resolved)]
	if victory:
		main.encounter_wins = mini(999999,main.encounter_wins+1)
		main.player.gold = mini(999999999,main.player.gold+int(tune.gold)); metrics.reward_gold = int(tune.gold)
		main.player.gain_xp(roundi(GD.xp_need(main.player.level)*0.2))
		var item: Dictionary = main.Systems.make_item(int(tune.level),0.4,"",main.player.class_id)
		main._drop(center,"item",0,item)
		main.hud.banner("Cantor silenced","+%d gold · +20%% level XP · one gear drop" % int(tune.gold))
	else: main.hud.toast(reason,Color("b3c4dc"),true)
	if persist: main.save_game()
	queue_redraw()

func _circle(at: Vector2, radius: float, color: Color, fill := true) -> void:
	var pts := PackedVector2Array()
	for i in 65: pts.append(at+GD.to_px(Vector2(cos(TAU*i/64.0),sin(TAU*i/64.0))*radius))
	if fill: draw_colored_polygon(pts,Color(color,0.24))
	draw_polyline(pts,color,2.5,true)
func _paint(w: Dictionary, impact := false) -> void:
	var color := Color("ffe2a2") if impact else Color("f77665")
	if w.kind == "line":
		var d: Vector2 = w.direction; var side := Vector2(-d.y,d.x)*float(w.half_width)
		var pts := PackedVector2Array()
		for p in [side,d*float(w.length)+side,d*float(w.length)-side,-side]: pts.append(w.origin+GD.to_px(p))
		draw_colored_polygon(pts,Color(color,0.38 if impact else 0.24)); pts.append(pts[0]); draw_polyline(pts,color,2.5,true)
		# Crossbars communicate the filled lane independently of color.
		for i in range(1,7): draw_line(w.origin+GD.to_px(d*i+side),w.origin+GD.to_px(d*i-side),color,1.0,true)
	elif w.kind == "seals":
		for at in w.centers:
			_circle(at,float(w.radius),color)
			for d in [Vector2(0.45,0.45),Vector2(-0.45,0.45)]: draw_line(at-GD.to_px(d),at+GD.to_px(d),color,2.0,true)
	else:
		# Fill an annulus, leaving the safe center visibly clear.
		for i in 64:
			var a := TAU*i/64.0; var b := TAU*(i+1)/64.0
			var pts := PackedVector2Array()
			for pair in [[a,w.inner],[a,w.outer],[b,w.outer],[b,w.inner]]: pts.append(w.origin+GD.to_px(Vector2(cos(pair[0]),sin(pair[0]))*float(pair[1])))
			draw_colored_polygon(pts,Color(color,0.24))
		_circle(w.origin,float(w.inner),color,false); _circle(w.origin,float(w.outer),color,false)
func _draw() -> void:
	if not active: return
	_circle(center,ARENA_RADIUS,Color("8b87af"),false)
	for w in warnings: _paint(w)
	for w in impacts: _paint(w,true)
