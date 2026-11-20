extends SceneTree
## ARPG HUD (owner's 2.5D lab mockup) in the pilot labs: layout pieces exist, globes track HP/MP, spells cost
## mana, potions restore and cool down, Q/W/E cast, legacy labs keep their old HUD.
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + why)
func _initialize() -> void:
	call_deferred("_run")
func _key(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	root.get_viewport().push_input(e)
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_mage_combat_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 6: await physics_frame
	var a = lab.player
	var hud = lab.hud
	check(hud != null and lab.info == null, "Mage lab uses the ARPG HUD instead of the debug panel")
	check(not a.number_keys_for_skills, "1-5 are potions; skills move to Q E R")
	check(hud.bar_layout == hud.MAGE_BAR, "Mage skill bar (LMB Bolt, Q Lance, E Nova, R Judgment)")
	for spec in hud.MAGE_BAR:
		if spec[1] != "":
			check(ResourceLoader.exists(hud.TILES + spec[1] + ".png"), "Skill icon exists: " + spec[1])
	for t in ["orb_life_full", "orb_life_empty", "orb_mana_full", "orb_mana_empty", "belt_plate", "slot_socket", "potion", "potion_mana", "lock"]:
		check(ResourceLoader.exists(hud.UI + t + ".png"), "HUD art exists: " + t)
	check(hud.minimap_vp.world_3d == lab.get_world_3d(), "Minimap renders the lab world")
	check(hud.quest_progress == 0 and hud.find_child("Quest_ALostTomes", true, false) == null and hud.find_child("Quest_TheLostTomes", true, false) != null, "Quest tracker shows both quests")
	var hidden := true
	for t in lab.targets: hidden = hidden and not t.title.visible
	check(hidden, "Dummy 3D titles replaced by HUD enemy bars")
	# globes follow HP / MP
	a.hp = a.max_hp * 0.5
	a.mana = a.max_mana * 0.25
	await process_frame
	await process_frame
	check(absf(hud.hp_globe.value - 500.0) < 2.0, "HP globe at 50%% (%.0f)" % hud.hp_globe.value)
	check(absf(hud.mp_globe.value - 250.0) < 20.0, "MP globe at ~25%% (%.0f)" % hud.mp_globe.value)
	check(hud.hp_label.text == "HP %d / %d" % [roundi(a.hp), roundi(a.max_hp)], "HP label " + hud.hp_label.text)
	# potions
	var hp0: float = a.hp
	check(hud.drink(0) and a.hp > hp0, "Health potion (1) heals")
	check(not hud.drink(0), "Potion slot cools down after use")
	var mp0: float = a.mana
	check(hud.drink(3) and a.mana > mp0, "Mana potion (4) restores mana")
	a.hp = a.max_hp
	check(not hud.drink(1), "Health potion is not wasted at full HP")
	# mana costs
	a.mana = 10.0
	check(not a.cast_spell("Nova"), "Nova (30 MP) refused at 10 MP")
	a.mana = a.max_mana
	var m0: float = a.mana
	_key(KEY_Q)
	await physics_frame
	check(a.spell_variant == "Lance" and a.attack_t > 0.0, "Q casts Lance")
	check(absf((m0 - a.mana) - 18.0) < 1.0, "Lance spends 18 MP (%.1f)" % (m0 - a.mana))
	while a.attack_t > 0.0 or a.attack_cd > 0.0: await physics_frame
	check(hud._cooldown_fraction("Lance") > 0.0, "Skill bar shows Lance cooling down")
	_key(KEY_W)
	await physics_frame
	check(a.attack_t <= 0.0, "W stays a movement key (no skill)")
	_key(KEY_1)
	await physics_frame
	check(a.spell_variant == "Lance" and a.attack_t <= 0.0, "Key 1 no longer casts a skill in the ARPG HUD")
	var before: float = a.mana
	await create_timer(0.5).timeout
	check(a.mana > before, "Mana regenerates")
	lab.queue_free()
	await process_frame
	# knight bar + legacy lab
	var k: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	root.add_child(k)
	for i in 6: await physics_frame
	check(k.hud != null and k.hud.bar_layout == k.hud.WARRIOR_BAR, "Knight lab: warrior skill bar")
	k.queue_free()
	await process_frame
	var legacy = load("res://scripts/three_d/rig_lab.gd").new()
	root.add_child(legacy)
	for i in 4: await physics_frame
	check(legacy.hud == null and legacy.info != null and legacy.player.number_keys_for_skills, "Legacy lab keeps its debug HUD and 1/2/3 skills")
	print("AOTL ARPG HUD RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
