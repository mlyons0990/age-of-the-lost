extends SceneTree
const MD := preload("res://scripts/mastery_data.gd")
const SYS := preload("res://scripts/systems.gd")
const DATA := preload("res://scripts/game_data.gd")
var main: Node2D
var p: Node2D
var checks := 0
var failures := 0
var report: Array[String] = []
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1; report.append(("PASS " if ok else "FAIL ") + message); print(report[-1])
	if not ok: failures += 1
func frames(n := 3) -> void:
	for i in n: await process_frame
func reset_actor(branch := "") -> void:
	main.save_blocked = false; main.rift.active = false
	for e in main.enemies.duplicate(): e.queue_free()
	main.enemies.clear()
	for child in main.world.get_children():
		if child.get_script() == load("res://scripts/enemy.gd") or child.get_script() == load("res://scripts/loot.gd"): child.queue_free()
	main.loot.clear()
	for effect in [main.fx_ground,main.fx_parts,main.fx_text]: effect.items.clear()
	var ui: CanvasLayer = main.hud
	for field in ["choice_panel","death_panel","start_panel","char_panel"]:
		if ui.get(field) != null: ui.get(field).queue_free(); ui.set(field,null)
	ui.page = ""; ui._refresh_pause()
	p.cancel_casts(); p.aura.healing.clear()
	p.class_id = "mage"; p.level = 40; p.xp = 0; p.spec = "mage_fire"; p.adv = "pyromancer"
	p.dead = false; p.invuln = 0; p.attack_anim = 0; p.rally = 0; p.clock = 0; p.cds.clear(); p.cd_full.clear()
	p.mastery = {"ward_temper":1,"ember_aura":1}
	if branch != "": p.mastery[branch] = 1
	p.discoveries = ["first_echo"]; p.crafted_uniques.clear(); p.inventory.clear(); p.stash.clear()
	for slot in p.gear: p.gear[slot] = null
	p.hotbar = DATA.CLASSES.mage.starting.duplicate(); p.kills = 0; p.elite_kills = 0; p.quest = 0; p.opened_rift = false
	p.position = main.START; p.path = PackedVector2Array(); p.target = null; p.mouse_held = false
	p.gold = 500; p.hp = p.stats().max_hp; p.mp = 100
	p.refresh_visuals()
func dummy(offset := Vector2(70,0), hp := 100000.0) -> Node2D:
	main.spawn_enemy("slime",false,p.position+offset)
	var e: Node2D = main.enemies[-1]
	e.set_process(false); e.hp = hp; e.max_hp = hp; e.stun = 100; return e
func start_aura() -> bool:
	p.attack_anim = 0; p.cds.clear()
	var ok: bool = p.use_skill("s3",p.position)
	if ok: p.aura.packet.crit_chance = 0.0
	return ok
func step(delta: float) -> void:
	p.clock += delta; p.aura.advance(delta)
func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/mastery/"+name+".png")
func _run() -> void:
	change_scene_to_file("res://main.tscn"); await frames(5)
	main = current_scene; p = main.player
	main.set_process(false); p.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute("res://previews/mastery")
	reset_actor()
	check(MD.earned("mage",19)==0 and MD.earned("mage",20)==1 and MD.earned("mage",40)==5 and MD.earned("mage",60)==9,"mastery points follow the documented level schedule")
	check(MD.earned("warrior",60)==0,"Warrior does not inherit Mage mastery points")
	var empty := {}; var plan := MD.invest(empty,"ward_temper","mage",20,[])
	check(plan.ok and empty.is_empty() and plan.ranks.ward_temper==1,"pure investment validates without mutating caller state")
	check(not MD.invest({},"ember_aura","mage",40,["first_echo"]).ok,"transformation requires the ward prerequisite")
	check(not MD.invest({"ward_temper":1},"ember_aura","mage",40,[]).ok,"transformation requires discovery as well as level")
	check(not MD.invest({"ward_temper":1},"ember_aura","mage",39,["first_echo"]).ok,"heroic transformation cannot be bought before level forty")
	check(not MD.invest({"ward_temper":1},"ward_temper","mage",20,[]).ok,"investment cannot exceed earned point budget")
	var bloom := {"ward_temper":1,"ember_aura":1,"cinder_bloom":1}
	check(MD.problem(bloom,"mage",40,["first_echo"])=="" and MD.spent(bloom)==5,"complete Bloom build fits exactly five level-forty points")
	check(not MD.invest(bloom,"siphon_embers","mage",60,["first_echo"]).ok,"exclusive branches cannot coexist even with spare points")
	for bad in [{"unknown":1},{"ward_temper":1.5},{"ward_temper":-1},{"ward_temper":"1"},{"ward_temper":4},{"ward_temper":3,"ember_aura":1,"cinder_bloom":1}]:
		check(MD.problem(bad,"mage",40,["first_echo"])!="","malformed or overspent mastery state rejected: "+str(bad))
	var refund := MD.refund(bloom,"ward_temper")
	check(refund.ok and refund.ranks.is_empty() and refund.refunded==5,"refunding prerequisite atomically refunds the dependent graph")
	var partial := MD.refund({"ward_temper":3,"ember_aura":1},"ward_temper")
	check(partial.ranks.get("ward_temper")==2 and partial.ranks.has("ember_aura") and partial.refunded==1,"refunding a spare prerequisite rank preserves valid downstream nodes")
	check(not MD.invest({"ward_temper":1,"ember_aura":1},"steady_flame","mage",40,["first_echo"]).ok,"Steady Flame retains its separate level-forty-five gate")
	var base: Dictionary = DATA.spells().ashen_ward
	var original := JSON.stringify(base)
	var ward := MD.definition(base,{"ward_temper":2})
	check(is_equal_approx(ward.hp_fraction,0.24) and JSON.stringify(base)==original,"ward ranks improve the active barrier without mutating definitions")
	var transformed: Dictionary = p.skill_def("s3")
	check(transformed.id=="ashen_ward" and transformed.variant=="ember_aura" and transformed.type=="aura","transformation preserves stable base identity and hotbar slot")
	var e := dummy(); var before_hp: float = e.hp
	check(start_aura() and p.aura.running and p.mp==90 and p.ward_amount==0,"activation pays ten mana and replaces the timed ward")
	step(0.49)
	check(e.hp==before_hp and p.mp==90 and p.aura.paid_pulses==0,"aura waits a full interval before its first paid pulse")
	step(0.01)
	check(e.hp<before_hp and p.mp==87 and p.aura.paid_pulses==1,"pulse pays upkeep before damaging living targets")
	reset_actor(); e=dummy(); p.mp=12.99; start_aura(); before_hp=e.hp; step(0.5)
	check(not p.aura.running and e.hp==before_hp and is_equal_approx(p.mp,2.99),"insufficient upkeep stops before damage and never overdraws mana")
	reset_actor(); p.mp=9; var failed: bool=start_aura()
	check(not failed and not p.aura.running and p.mp==9 and p.cds.is_empty(),"insufficient activation mana commits nothing")
	reset_actor(); start_aura(); step(0.5)
	check(p.mp==87 and p.aura.paid_pulses==1,"empty-space pulses still pay and never refund mana")
	reset_actor(); start_aura(); var natural_regen: float=p.stats().mana_regen; p._physics_process(0.1)
	check(is_equal_approx(p.mp,90+natural_regen*0.025),"active aura reduces actual natural regeneration to one quarter")
	p.use_skill("s3",p.position); var stopped_mp: float=p.mp; p._physics_process(0.1)
	check(is_equal_approx(p.mp,stopped_mp+natural_regen*0.1),"toggling off restores normal natural regeneration")
	reset_actor(); e=dummy(); start_aura(); step(2.0)
	check(p.aura.paid_pulses==4 and p.mp==78,"frame catch-up preserves four separate paid half-second pulses")
	var old_power: float=p.aura.packet.power; p.gear.weapon={"spell_power":999.0}
	check(p.aura.packet.power==old_power and p.stats().spell_power>old_power,"active aura uses its immutable activation snapshot")
	p.mp=0; var remaining: float=p.cds.ashen_ward
	check(p.use_skill("s3",p.position) and not p.aura.running and p.mp==0 and p.cds.ashen_ward==remaining,"toggle off bypasses resource and recovery locks without resetting cooldown")
	reset_actor(); start_aura(); p.assign_skill(3,"solar_writ")
	check(not p.aura.running and not p.hotbar.has("ashen_ward"),"removing aura from the five active slots stops it")
	reset_actor(); start_aura(); p.cancel_casts()
	check(not p.aura.running and p.aura.patches.is_empty(),"cast cancellation clears aura and secondary ground effects")
	reset_actor(); start_aura(); p.hurt(1000000,40)
	check(p.dead and not p.aura.running,"death cancels the paid aura before further pulses")
	reset_actor("cinder_bloom"); start_aura(); main.rift.active=true
	var previous: Dictionary=p.mastery.duplicate(true)
	check(not p.change_mastery("ward_temper",true).ok and p.mastery==previous and p.aura.running,"combat respec rejection preserves ranks and running effects")
	main.rift.active=false; p.change_mastery("ward_temper",true)
	check(p.mastery.is_empty() and not p.aura.running,"town respec refunds dependents and reconciles transient effects")
	reset_actor(); e=dummy(DATA.to_px(Vector2(3.1,0))); start_aura(); before_hp=e.hp; step(0.5)
	check(e.hp==before_hp,"base aura respects its actual collision radius")
	reset_actor("cinder_bloom"); e=dummy(DATA.to_px(Vector2(3.1,0))); start_aura(); before_hp=e.hp; step(0.5)
	check(e.hp<before_hp,"Cinder Bloom expands actual pulse reach rather than only its label")
	reset_actor(); p.level=50; p.mastery.steady_flame=2; start_aura(); step(0.5)
	check(is_equal_approx(p.mp,87.3) and p.aura.skill.dmg==0.3,"Steady Flame reduces actual upkeep without reducing damage coefficient")
	reset_actor(); p.level=60; p.mastery.ward_temper=3; start_aura()
	check(is_equal_approx(p.aura.packet.direct,p.aura.packet.power*0.33),"upper ward ranks remain useful after transformation through snapshotted pulse damage")
	reset_actor("siphon_embers"); start_aura(); p.hp=100; e=dummy(Vector2(70,0),1)
	p.aura.packet.direct=100000
	var actual: float=p.apply_packet(e,p.aura.packet)
	check(actual==1 and is_equal_approx(p.hp,100.02),"Siphon heals from one actual HP of damage rather than overkill")
	reset_actor("siphon_embers"); start_aura(); p.hp=100; e=dummy(); e.invulnerable=true
	check(p.apply_packet(e,p.aura.packet)==0 and p.hp==100,"invulnerable targets produce neither damage nor healing")
	e.invulnerable=false; e.hp=10000000; p.aura.packet.direct=1000000
	var cap: float=p.stats().max_hp*0.03; p.apply_packet(e,p.aura.packet)
	check(is_equal_approx(p.hp,100+cap),"Siphon caps recovery at three percent max life in a rolling second")
	var capped: float=p.hp; p.apply_packet(e,p.aura.packet)
	check(p.hp==capped,"additional same-window hits cannot exceed recovery cap")
	p.aura.stop(); p.aura.start(p.skill_def("s3"),p.make_packet(p.skill_def("s3"))); p.aura.packet.direct=1000000; p.aura.packet.crit_chance=0
	p.apply_packet(e,p.aura.packet)
	check(p.hp==capped,"toggling cannot reset the rolling recovery cap")
	p.clock=1.001; p.apply_packet(e,p.aura.packet)
	check(is_equal_approx(p.hp,capped+cap),"recovery budget becomes available after its rolling window expires")
	var healed: float=p.hp; p.aura.on_damage(e,1000000,{"origin":"cinder_patch","proc_depth":1})
	check(p.hp==healed,"secondary damage cannot feed the aura lifesteal trigger")
	reset_actor("cinder_bloom"); start_aura(); e=dummy(Vector2(70,0),1); e.burn=2; e.burn_dps=1
	var hit: Dictionary=p.make_packet({"id":"fixture","dmg":100,"scaling":"spell"})
	p.apply_packet(e,hit)
	check(p.aura.patches.size()==1,"a primary kill of a burning target creates one Cinder patch")
	e=dummy(Vector2(90,0),1); e.burn=2; p.apply_packet(e,hit)
	check(p.aura.patches.size()==1,"overlapping Cinder patches do not stack or refresh")
	e=dummy(Vector2(80,0),1); e.burn=2; p.aura._advance_patches(0.5)
	check(e.dead_t>=0 and p.aura.patches.size()==1,"a secondary patch kill cannot create another patch")
	var kills_before: int=p.kills; main.kill_enemy(e,{"was_burning":true})
	check(p.kills==kills_before and p.aura.patches.size()==1,"duplicate kill callbacks do not grant credit or create patches")
	p.aura._advance_patches(0.5)
	check(p.aura.patches.is_empty(),"Cinder patch expires after its two half-second ticks")
	for i in 12:
		e=dummy(DATA.to_px(Vector2(i*3,0)))
		p.aura.on_kill(e,{"origin":"primary","was_burning":true,"proc_depth":0})
	check(p.aura.patches.size()==8,"aura has a hard eight-patch visual and simulation cap")
	reset_actor(); var normal: Dictionary=p.skill_def("s3")
	var unique:=SYS.make_unique(); SYS.insert(p.inventory,unique)
	check(p.equip_item(0,"helm") and p.has_circlet(),"named cloth circlet equips in Mage head slot")
	var altered: Dictionary=p.skill_def("s3")
	check(is_equal_approx(altered.pulse_interval,0.4) and is_equal_approx(altered.pulse_cost,2.4),"Emberwake adjusts actual pulse cadence and payment")
	check(is_equal_approx(altered.dmg/altered.pulse_interval,normal.dmg/normal.pulse_interval) and is_equal_approx(altered.pulse_cost/altered.pulse_interval,normal.pulse_cost/normal.pulse_interval),"unique cadence preserves baseline damage and mana per second")
	check(SYS.clean_item(unique).unique_id==SYS.UNIQUE_ID,"item sanitizer retains the recognized unique identity")
	check(SYS.make_item(62,0,"staff","mage").level==60,"elite drops above character cap still generate usable level-sixty gear")
	start_aura(); e=dummy(); step(0.399)
	check(p.aura.paid_pulses==0 and p.mp==90,"unique cadence does not emit an early pulse")
	step(0.001)
	check(p.aura.paid_pulses==1 and is_equal_approx(p.mp,87.6),"unique emits a real paid 0.4-second pulse at the adjusted cost")
	e.burn=3.95; e.burn_tick=0.21; p.aura.on_damage(e,5,p.aura.packet)
	check(e.burn==4 and e.burn_tick==0.21,"burn extension caps remaining duration without resetting tick progress")
	p.aura.on_damage(e,5,p.aura.packet)
	check(e.burn==4,"repeated unique extensions never exceed four seconds")
	e.burn=5; p.aura.on_damage(e,5,p.aura.packet)
	check(e.burn==5,"extension never shortens a pre-existing longer burn")
	check(p.unequip_item("helm") and not p.aura.running and not p.has_circlet(),"unequipping unique stops snapshot effects and removes cadence modifier")
	reset_actor(); p.inventory.clear()
	for i in 60: SYS.insert(p.inventory,SYS.make_item(1,0,"ring"))
	var old_gold: int=p.gold
	check(not p.craft_circlet().ok and p.gold==old_gold and p.crafted_uniques.is_empty() and p.inventory.size()==60,"full-bag crafting fails atomically without charging or consuming the memory")
	p.inventory.clear(); p.gold=249
	check(not p.craft_circlet().ok and p.gold==249 and p.inventory.is_empty(),"underfunded crafting preserves ownership and currency")
	p.gold=500
	check(p.craft_circlet().ok and p.gold==250 and p.inventory.size()==1 and p.crafted_uniques==[SYS.UNIQUE_ID],"lore attunement charges once and grants the actual unique item")
	check(not p.craft_circlet().ok and p.gold==250 and p.inventory.size()==1,"unique memory cannot be crafted repeatedly")
	p.equip_item(0,"helm"); p.mastery=bloom.duplicate(); start_aura()
	check(p.aura.running,"save fixture contains a genuinely running aura before serialization")
	p.hp=123; p.mp=55; p.cds={"ashen_ward":0.7}; p.cd_full={"ashen_ward":1.0}
	main.save_game(); var saved: Dictionary=main._read_save(main.SAVE_PATH)
	check(int(saved.schema)==6 and saved.mastery.size()==3 and saved.mastery.keys().all(func(id: String) -> bool: return bloom.has(id) and int(saved.mastery[id])==1) and saved.crafted_uniques==[SYS.UNIQUE_ID],"schema six saves stable node ranks and once-only crafting state")
	var saved_hp: float=p.hp; var saved_mp: float=p.mp
	check(main.load_game() and p.mastery==bloom and p.has_circlet() and p.hp==saved_hp and p.mp==saved_mp and p.cds.ashen_ward==0.7 and not p.aura.running,"reload preserves build, unique, resources and cooldown while dropping transient aura")
	var bad: Dictionary=saved.duplicate(true); bad.mastery.siphon_embers=1
	check(not main._valid_save(bad),"save validator rejects exclusive-branch corruption")
	bad=saved.duplicate(true); bad.gear.helm.unique_id="invented"
	check(not main._valid_save(bad),"save validator rejects unknown named powers")
	bad=saved.duplicate(true); bad.gold=1.5
	check(not main._valid_save(bad),"fractional currency cannot be silently truncated during load")
	bad=saved.duplicate(true); bad.schema=3.5
	check(not main._valid_save(bad),"unrecognized fractional schema values are rejected")
	var legacy: Dictionary=saved.duplicate(true); legacy.schema=3; legacy.erase("mastery"); legacy.erase("crafted_uniques")
	check(main._valid_save(legacy),"prior schema-three saves remain explicitly importable")
	legacy.mastery="unrecognized legacy extra field"; legacy.crafted_uniques=["invalid_new_field"]
	var f:=FileAccess.open(main.SAVE_PATH,FileAccess.WRITE); f.store_string(JSON.stringify(legacy)); f.close(); main.load_game()
	check(p.mastery.is_empty() and p.skill_def("s3").type=="ward" and p.hp==123 and p.mp==55,"schema-three import starts with unspent points and does not auto-transform or heal")
	var future: Dictionary=saved.duplicate(true); future.schema=7
	f=FileAccess.open(main.SAVE_PATH,FileAccess.WRITE); f.store_string(JSON.stringify(future)); f.close()
	var future_hash:=FileAccess.get_sha256(main.SAVE_PATH)
	check(not main.load_game() and main.save_blocked,"future mastery saves activate write protection")
	main.save_game()
	check(FileAccess.get_sha256(main.SAVE_PATH)==future_hash,"protected future save bytes remain unchanged after a save attempt")
	f=FileAccess.open(main.SAVE_PATH,FileAccess.WRITE); f.store_string(JSON.stringify(saved)); f.close(); main.save_blocked=false; main.load_game()
	reset_actor("cinder_bloom"); p.hero_name="Aster"; p.level=40; p.hp=p.stats().max_hp; p.mp=p.stats().max_mp
	main.hud.banner_t=99; main.hud.toasts.clear(); main.hud.open_page("mastery"); await frames(); await shot("01_mastery_bloom"); main.hud.close_page()
	p.gold=500; p.craft_circlet(); main.hud.open_page("inventory"); main.hud._inspect(0); await frames(); await shot("02_emberwake_unique"); main.hud.close_page()
	for effect in [main.fx_ground,main.fx_parts,main.fx_text]: effect.items.clear()
	start_aura(); e=dummy(Vector2(145,20)); e.burn=2; e.burn_dps=1; step(0.5); await frames(); await shot("03_ember_aura")
	if DisplayServer.get_name() != "headless":
		p.set_physics_process(true)
		for i in 20:
			await create_timer(0.1).timeout; await shot("aura_frame_%02d" % i)
		p.set_physics_process(false)
	p.cancel_casts()
	reset_actor("siphon_embers"); p.hero_name="Aster"; main.hud.banner_t=99; main.hud.toasts.clear()
	main.hud.open_page("mastery"); await frames(); await shot("04_mastery_siphon"); main.hud.close_page()
	p.craft_circlet(); p.equip_item(0,"helm"); main.hud.selected_spell="ashen_ward"; main.hud.open_page("spells"); await frames(); await shot("05_ember_aura_grimoire")
	var scrolls: Array=main.hud.char_panel.find_children("*","ScrollContainer",true,false)
	var details: ScrollContainer=scrolls[1]; details.scroll_vertical=10000; await frames()
	var assign_buttons: Array=details.find_children("*","Button",true,false).filter(func(b: Button) -> bool: return b.text.begins_with("Equip → 4"))
	check(assign_buttons.size()==1 and details.get_global_rect().encloses(assign_buttons[0].get_global_rect()),"long aura descriptions can scroll to the final actual assignment button")
	await shot("06_grimoire_assignment_scroll"); main.hud.close_page()
	p.mastery=bloom.duplicate(); start_aura(); p.hp=123; p.mp=55; p.cds={"ashen_ward":0.7}; p.cd_full={"ashen_ward":1.0}
	var equipped_uid: String=p.gear.helm.uid
	main._enter_articulation_lab(); await scene_changed
	check(current_scene is Node3D,"an actual level-forty mastery build enters the independent 3D lab")
	current_scene._back_to_plaza(); await scene_changed
	main=current_scene; p=main.player; main.set_process(false);p.set_physics_process(false)
	check(p.mastery==bloom and p.class_id=="mage" and p.level==40,"scene round-trip restores the exact canonical mastery build")
	check(p.mage_art_active,"scene return selects Mage art before the first physics update")
	check(p.has_circlet() and p.gear.helm.uid==equipped_uid and p.crafted_uniques==[SYS.UNIQUE_ID],"scene round-trip preserves named-item ownership and consumed attunement")
	check(p.hp==123 and p.mp==55 and is_equal_approx(p.cds.ashen_ward,0.7),"scene round-trip preserves paid resources and stable cooldown without a reload heal")
	check(not p.aura.running and p.aura.patches.is_empty() and not paused,"scene round-trip discards transient aura and resumes ordinary gameplay")
	var out:=FileAccess.open("res://tests/MASTERY_LAST_RUN.txt",FileAccess.WRITE)
	out.store_string("Godot "+Engine.get_version_info().string+" / "+DisplayServer.get_name()+"\n"+"\n".join(report)+"\n%d checks; %d failures\n" % [checks,failures]); out.close()
	print("MASTERY RESULT %d checks; %d failures" % [checks,failures])
	await main.quit_game(1 if failures else 0)
