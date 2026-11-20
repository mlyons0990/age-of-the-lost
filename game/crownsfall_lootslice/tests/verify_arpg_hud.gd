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
	check(not a.number_keys_for_skills, "1-5 are potions; skills on Q W E R T")
	check(a.click_to_move, "Click-to-move enabled (ARPG HUD labs)")
	check(hud.bar_layout == hud.MAGE_BAR, "Mage skill bar (Q Lance, W Nova, E Judgment, R/T locked)")
	for spec in hud.MAGE_BAR:
		if spec[1] != "":
			check(ResourceLoader.exists(hud.TILES + spec[1] + ".png"), "Skill icon exists: " + spec[1])
	for t in ["orb_life_full", "orb_life_empty", "orb_mana_full", "orb_mana_empty", "belt_plate", "slot_socket", "potion", "potion_mana", "lock"]:
		check(ResourceLoader.exists(hud.UI + t + ".png"), "HUD art exists: " + t)
	var vw: float = lab.get_viewport().get_visible_rect().size.x
	var vh: float = lab.get_viewport().get_visible_rect().size.y
	var lr: Rect2 = hud.left_piece.get_global_rect()
	var rr: Rect2 = hud.right_piece.get_global_rect()
	check(absf(lr.position.x) < 1.0 and absf(lr.end.y - vh) < 1.0, "Left statue/orb/belt flush to the left and bottom edges (%s)" % lr)
	check(absf(rr.end.x - vw) < 1.0 and absf(rr.end.y - vh) < 1.0, "Right skills/orb/statue flush to the right and bottom edges (%s)" % rr)
	check(hud.strip_rect.position.x <= lr.end.x and hud.strip_rect.end.x >= rr.position.x and absf(hud.strip_rect.end.y - vh) < 12.0, "XP strip joins the two pieces along the bottom (no gap)")
	check(absf(hud.orb_l.z - hud.orb_r.z) / hud.orb_l.z < 0.05, "Both orb rings the same size on screen (%.1f / %.1f px)" % [hud.orb_l.z, hud.orb_r.z])
	check(hud.left_piece.texture.get_width() == roundi(hud.left_piece.size.x) and hud.right_piece.texture.get_width() == roundi(hud.right_piece.size.x), "Pieces draw 1:1 at 1080p (no runtime downscale aliasing)")
	check(hud.bar_slots.size() == 5 and hud.potion_slots.size() == 5, "5 potion wells + 5 skill wells, as in the mockup")
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
	check(absf(hud.hp_frac - 0.5) < 0.01, "HP orb shaded to 50%% (%.2f)" % hud.hp_frac)
	check(absf(float((hud.hp_shade.material as ShaderMaterial).get_shader_parameter("fill")) - 0.5) < 0.01, "HP disc shader fill follows HP")
	check(absf(hud.mp_frac - 0.25) < 0.03, "MP orb shaded to ~25%% (%.2f)" % hud.mp_frac)
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
	_key(KEY_1)
	await physics_frame
	check(a.spell_variant == "Lance" and a.attack_t <= 0.0, "Key 1 no longer casts a skill in the ARPG HUD")
	var before: float = a.mana
	await create_timer(0.5).timeout
	check(a.mana > before, "Mana regenerates")
	# --- click-to-move ---
	while a.attack_t > 0.0 or a.attack_cd > 0.0: await physics_frame
	a.mana = a.max_mana
	_key(KEY_W)
	await physics_frame
	check(a.spell_variant == "Nova" and a.attack_t > 0.0, "W casts Nova (click-to-move frees W)")
	while a.attack_t > 0.0 or a.attack_cd > 0.0: await physics_frame
	for t in lab.targets: t.global_position += Vector3(0, 0, -30)   # clear the field
	var start: Vector3 = a.global_position
	var dest: Vector3 = start + Vector3(3.0, 0, 1.0)
	lab.handle_click(lab.camera.unproject_position(dest))
	check(a.move_target.is_finite() and Vector2(a.move_target.x - dest.x, a.move_target.z - dest.z).length() < 0.15, "LMB on the ground sets the destination under the cursor")
	await create_timer(1.6).timeout
	var arrived := Vector2(a.global_position.x - dest.x, a.global_position.z - dest.z).length()
	check(arrived < 0.35 and not a.move_target.is_finite(), "Hero walks to the clicked point and stops (%.2f m off)" % arrived)
	var held: Vector3 = a.global_position
	var e := InputEventKey.new(); e.keycode = KEY_D; e.pressed = true
	Input.parse_input_event(e)
	await create_timer(0.3).timeout
	e = InputEventKey.new(); e.keycode = KEY_D; e.pressed = false
	Input.parse_input_event(e)
	check(a.global_position.distance_to(held) < 0.05, "WASD ignored in click-to-move")
	var dummy = lab.targets[0]
	dummy.global_position = a.global_position + Vector3(-7.5, 0, 0)
	dummy.hp = dummy.max_hp
	dummy.inactive_t = 0.0
	await physics_frame
	var aim: Vector2 = lab.camera.unproject_position(dummy.global_position + Vector3.UP)
	check(lab.enemy_under(aim) == dummy, "Cursor over an enemy picks it")
	lab.handle_click(aim)
	check(a.attack_target == dummy, "LMB on an enemy targets it")
	var t0 := Time.get_ticks_msec()
	while dummy.hp >= dummy.max_hp and Time.get_ticks_msec() - t0 < 5000: await physics_frame
	var gap := Vector2(dummy.global_position.x - a.global_position.x, dummy.global_position.z - a.global_position.z).length()
	check(dummy.hp < dummy.max_hp, "Hero walks into range and attacks the clicked enemy (cast from %.1f m)" % gap)
	check(gap <= a.primary_range() + 0.3, "Attack starts only once in range (%.1f <= %.1f m)" % [gap, a.primary_range()])
	while a.attack_t > 0.0 or a.attack_cd > 0.0: await physics_frame
	var stand: Vector3 = a.global_position
	lab.handle_click(lab.camera.unproject_position(stand + Vector3(4, 0, 0)), true)
	await physics_frame
	check(a.attack_t > 0.0 and a.global_position.distance_to(stand) < 0.05, "Shift+LMB attacks in place toward the cursor")
	check(a.last_face.dot(Vector3.RIGHT) > 0.9, "Attack faces the cursor")
	lab.queue_free()
	await process_frame
	# knight bar + legacy lab
	var k: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	root.add_child(k)
	for i in 6: await physics_frame
	check(k.hud != null and k.hud.bar_layout == k.hud.WARRIOR_BAR, "Knight lab: warrior skill bar")
	var kp = k.player
	var kd = k.targets[1]
	kd.global_position = kp.global_position + Vector3(4.0, 0, 0)
	kd.hp = kd.max_hp
	await physics_frame
	k.handle_click(k.camera.unproject_position(kd.global_position + Vector3.UP))
	var k0 := Time.get_ticks_msec()
	while kd.hp >= kd.max_hp and Time.get_ticks_msec() - k0 < 5000: await physics_frame
	var kgap := Vector2(kd.global_position.x - kp.global_position.x, kd.global_position.z - kp.global_position.z).length()
	check(kd.hp < kd.max_hp and kgap <= kp.MELEE_RANGE + 0.4, "Knight: click an enemy -> walks up and slashes it (%.1f m)" % kgap)
	k.queue_free()
	await process_frame
	var legacy = load("res://scripts/three_d/rig_lab.gd").new()
	root.add_child(legacy)
	for i in 4: await physics_frame
	check(legacy.hud == null and legacy.info != null and legacy.player.number_keys_for_skills, "Legacy lab keeps its debug HUD and 1/2/3 skills")
	print("AOTL ARPG HUD RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
