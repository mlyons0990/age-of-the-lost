extends Node
const Systems := preload("res://scripts/systems.gd")
const GDData := preload("res://scripts/game_data.gd")
const Resolver := preload("res://scripts/effect_resolver.gd")
var main: Node2D
var checks := 0
var failures := 0
var report: Array[String] = []
var capture := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	capture = DisplayServer.get_name() != "headless"
	_run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1; report.append(("PASS " if ok else "FAIL ") + message); print(report[-1])
	if not ok: failures += 1
func frames() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
func shot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://previews/" + name + ".png")
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
func find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix): return node
	for child in node.get_children():
		var found := find_button(child, prefix)
		if found != null: return found
	return null
func reset_actor(class_id := "mage") -> void:
	var p: Node2D = main.player
	p.cancel_casts(); p.attack_anim = 0; p.invuln = 0
	p.class_id = class_id; p.level = 1; p.spec = ""; p.adv = ""; p.dead = false
	p.mastery.clear(); p.crafted_uniques.clear()
	p.cds.clear(); p.cd_full.clear(); p.discoveries.clear()
	p.inventory.clear(); p.stash.clear(); p.hotbar = GDData.CLASSES[class_id].starting.duplicate()
	for slot in p.gear: p.gear[slot] = null
	p.position = main.START; p.path = PackedVector2Array(); p.target = null; p.mouse_held = false
	p.hp = p.stats().max_hp; p.mp = p.stats().max_mp
func dummy(offset := Vector2(160, 0), elite := false) -> Node2D:
	main.spawn_enemy("brute", elite, main.player.position + offset)
	var e: Node2D = main.enemies[-1]
	e.hp = 10000; e.max_hp = 10000; e.stun = 100; e.kb = Vector2.ZERO
	return e
func clear_enemies() -> void:
	for e in main.enemies.duplicate(): e.queue_free()
	main.enemies.clear()

func _run() -> void:
	await wait(0.15)
	var p: Node2D = main.player
	var ui: CanvasLayer = main.hud
	main.save_blocked = false; main.had_save = false
	ui._open_start(); await frames()
	var mage_button := find_button(ui.start_panel, "Mage")
	check(mage_button != null, "creation offers a selectable Mage")
	if mage_button != null: mage_button.pressed.emit()
	await frames(); await shot("01_class_selection")
	check(ui.creation_class == "mage", "class selection updates preview model")
	var name_fields: Array = ui.start_panel.find_children("*", "LineEdit", true, false)
	if not name_fields.is_empty(): name_fields[0].text = "Aster"
	var begin := find_button(ui.start_panel, "Enter Crownsfall")
	if begin != null: begin.pressed.emit()
	await frames()
	check(p.class_id == "mage" and p.hero_name == "Aster" and not get_tree().paused, "creation commits chosen class and name")
	check(p.inventory.size() == 5 and p.inventory.any(func(it: Dictionary) -> bool: return it.slot == "staff"), "Mage starter inventory has real staff and cloth equipment")
	check(p.hotbar.size() == 5 and p.hotbar.all(func(id: String) -> bool: return GDData.unlocked(p, id)), "all five Mage base spells available at level one")
	check(not GDData.unlocked(p, "slash"), "Warrior skills cannot be assigned to Mage")
	check(GDData.specs_for("mage").size() == 3 and GDData.specs_for("warrior").size() == 3, "each playable class has exactly three specialization choices")
	check(not GDData.visible_spells("mage").has("cleave") and GDData.visible_spells("mage").size() == 12, "Grimoire filters other classes but retains recovered magic")
	reset_actor()
	var mage: Dictionary = p.stats()
	check(mage.max_hp == 92 and mage.max_mp == 64, "Mage level-one attribute and resource curve")
	check(is_equal_approx(mage.spell_power, 12.16), "Mage level-one spell-power formula")
	var boosted := Systems.derive(1, {"amulet": {"intelligence": 10}}, p.mods(), "mage")
	check(boosted.spell_power > mage.spell_power and boosted.dmg == mage.dmg, "Intelligence increases Mage spells without weapon inflation")
	check(Systems.footprint(Systems.make_item(1, 0, "staff")) == Vector2i(2, 4), "staff occupies 2x4 real inventory cells")
	var wand := Systems.make_item(1, 0, "wand"); Systems.insert(p.inventory, wand)
	check(p.equip_item(0, "weapon"), "Mage equips wand in weapon destination")
	var focus := Systems.make_item(1, 0, "focus"); Systems.insert(p.inventory, focus)
	check(p.equip_item(0, "offhand"), "wand supports focus in offhand")
	var staff := Systems.make_item(1, 0, "staff"); Systems.insert(p.inventory, staff)
	check(p.equip_item(0, "weapon") and p.gear.offhand == null and p.inventory.size() == 2, "staff transaction returns displaced wand and focus to bag")
	var focus_index: int = p.inventory.find(focus)
	if focus_index < 0:
		for i in p.inventory.size():
			if p.inventory[i].slot == "focus": focus_index = i
	check(not p.equip_item(focus_index, "offhand") and p.gear.offhand == null, "two-handed staff rejects an offhand")
	var old_weapon: String = p.gear.weapon.uid
	p.inventory.clear()
	for i in 60: Systems.insert(p.inventory, Systems.make_item(1, 0, "ring"))
	p.inventory.remove_at(10); p.inventory.remove_at(0)
	Systems.insert(p.inventory, wand)
	var wand_index: int = p.inventory.size() - 1
	check(not p.equip_item(wand_index, "weapon") and p.gear.weapon.uid == old_weapon and p.inventory.size() == 59, "full bag weapon swap preserves staff and candidate atomically")
	p.inventory.clear(); Systems.insert(p.inventory, Systems.make_item(1, 0, "armor"))
	check(not p.equip_item(0, "armor"), "Mage cannot equip plate chest armor")
	p.inventory.clear(); Systems.insert(p.inventory, Systems.make_item(1, 0, "robe"))
	check(p.equip_item(0, "armor"), "Mage robe maps to chest destination")
	# Same snapshots drive direct damage, DOT and tooltips.
	var cone: Dictionary = GDData.EXTRA_SKILLS.ember_cone
	var packet: Dictionary = p.make_packet(cone)
	var snap_power: float = packet.power
	check(is_equal_approx(packet.burn_dps, snap_power * 0.5 / 3), "burn uses the same spell-power snapshot as direct cone damage")
	var low := Resolver.resolve(packet, 0.9, 1)
	var high := Resolver.resolve(packet, 1.1, 1)
	check(low.damage <= high.damage and not low.crit, "damage variance resolves within shared bounds")
	var crit_packet: Dictionary = packet.duplicate(); crit_packet.crit_chance = 0.6
	var critical := Resolver.resolve(crit_packet, 1, 0)
	check(critical.crit and critical.damage == roundi(packet.direct * 1.75), "critical direct damage uses defined multiplier")
	check(Resolver.summary(cone, p.stats()).contains("Burn:"), "tooltip includes actual burn rate and duration")
	p.gear.amulet = {"uid": Systems.uid(), "slot": "amulet", "level": 1, "rarity": 0, "name": "Fixture", "intelligence": 100}
	check(packet.power == snap_power and p.ability_power(cone) > packet.power, "cast snapshot is immutable when gear changes before impact")
	p.gear.amulet = null
	var burn_target := dummy(Vector2(100, 0))
	burn_target.burn = 3; burn_target.burn_dps = 20; burn_target.burn_tick = 0
	for i in 6: burn_target._advance_burn(0.5)
	check(is_equal_approx(burn_target.hp, 9940) and burn_target.burn == 0, "three-second burn resolves all six half-second ticks without losing the last tick")
	burn_target.hp = 10000; burn_target.burn = 1.25; burn_target.burn_dps = 20; burn_target.burn_tick = 0
	burn_target._advance_burn(1.25)
	check(is_equal_approx(burn_target.hp, 9975), "partial final burn interval preserves the exact damage budget")
	reset_actor(); clear_enemies()
	var enemy := dummy()
	p.mp = 10
	var before: float = enemy.hp
	check(p.use_skill("basic", enemy.position), "Cinder Thread accepts aimed cast")
	check(not p.use_skill("s1", enemy.position), "cast recovery blocks simultaneous spell overwrite")
	await wait(0.1)
	check(enemy.hp == before, "projectile does not hit before cast release")
	await wait(0.5)
	check(enemy.hp < before and p.mp >= 13, "projectile travels, impacts and restores mana on a hit")
	p.attack_anim = 0; p.cds.clear(); p.mp = 10
	var generator: Dictionary = p.make_packet(GDData.MAGE_BASE.cinder_thread)
	p.apply_packet(enemy, generator); p.apply_packet(enemy, generator)
	check(is_equal_approx(p.mp, 13), "generator grants mana only once per cast")
	p.attack_anim = 0; p.cds.clear(); p.mp = p.stats().max_mp
	check(p.use_skill("s1", enemy.position), "Glacial Stitch accepts cast")
	await wait(0.65)
	check(enemy.slow_time > 0 and is_equal_approx(enemy.slow_factor, 0.7), "frost projectile applies its real slow")
	var frost: Dictionary = p.make_packet(GDData.MAGE_BASE.glacial_stitch)
	enemy.stun = 0
	p.apply_packet(enemy, frost)
	check(enemy.stun > 0, "second frost stitch within six seconds freezes")
	# Swept collision can hit a target crossed in a single large physics step.
	p.cancel_casts(); p.attack_anim = 0; p.cds.clear()
	var Projectile := preload("res://scripts/projectile.gd")
	var projectile := Projectile.new(); projectile.setup(p, GDData.MAGE_BASE.cinder_thread, p.make_packet(GDData.MAGE_BASE.cinder_thread), enemy.position)
	main.add_child(projectile)
	before = enemy.hp; projectile._physics_process(0.3)
	check(enemy.hp < before, "swept projectile collision prevents tunneling")
	# Blink prevalidation is ahead of the resource/cooldown transaction.
	p.cancel_casts(); p.attack_anim = 0; p.cds.clear(); p.mp = 40
	var origin: Vector2 = p.position
	check(p.use_skill("s2", p.position + Vector2(100, 0)) and p.position.distance_to(origin) > 90, "Arcane Fold moves to valid ground immediately")
	p.position = main.START; p.attack_anim = 0; p.cds.clear(); p.mp = 40
	check(not p.use_skill("s2", p.position + Vector2(0, 1000)) and p.mp == 40 and not p.cds.has("arcane_fold"), "invalid blink spends neither mana nor cooldown")
	# Ward absorbs after armor and expires without healing.
	p.attack_anim = 0; p.cds.clear(); p.mp = p.stats().max_mp; p.hp = 40
	check(p.use_skill("s3", p.position) and p.ward_amount > 0, "Ashen Ward creates a timed damage barrier")
	var ward_before: float = p.ward_amount
	p.hurt(15, 1)
	check(p.hp == 40 and p.ward_amount < ward_before, "ward absorbs mitigated incoming damage without healing")
	p.ward_time = 0.01
	await wait(0.05)
	check(p.ward_amount == 0, "expired ward cannot absorb further damage")
	# Death invalidates delayed contacts, including effects already telegraphed.
	p.cancel_casts(); p.attack_anim = 0; p.cds.clear(); p.mp = p.stats().max_mp
	p.use_skill("s4", enemy.position)
	await wait(0.4)
	before = enemy.hp
	p.dead = true; p.cancel_casts()
	await wait(0.85)
	check(enemy.hp == before, "death cancels a queued ground impact")
	p.dead = false; p.hp = p.stats().max_hp
	# Primary-slot targeting follows spell reach rather than melee reach.
	p.cancel_casts(); p.attack_anim = 0; p.cds.clear(); p.target = enemy
	p._physics_process(0.016)
	check(p.cast_remaining > 0 and p.path.is_empty(), "ranged primary attacks from range without walking to melee distance")
	p.cancel_casts(); p.attack_anim = 0; p.cds.clear(); p.target = enemy; p.hotbar[0] = ""
	p._physics_process(0.016)
	check(p.target == null and p.path.is_empty(), "empty primary slot clears chase intent")
	reset_actor(); clear_enemies()
	p.level = 20; p.spec = "mage_fire"
	check(GDData.unlocked(p, "solar_writ") and not GDData.unlocked(p, "winter_crown"), "Fire specialization unlocks only its own technique")
	p.spec = "mage_frost"
	check(GDData.unlocked(p, "winter_crown") and not GDData.unlocked(p, "epoch_lance"), "Frost specialization keeps Arcane technique locked")
	p.spec = "mage_arcane"; p.level = 40
	ui.open_choice("adv"); await frames()
	var identity_labels: Array = ui.choice_panel.find_children("*", "Label", true, false)
	check(identity_labels.any(func(label: Label) -> bool: return label.text == "Chronomancer"), "heroic selection names Chronomancer for Arcane Mage")
	ui._choose("adv", "chronomancer", "Chronomancer", Color("c3a9ff"))
	await frames()
	check(p.adv == "chronomancer" and is_equal_approx(p.mods().cdr, 0.2), "Arcane advances to selected Chronomancer identity")
	p.mp = p.stats().max_mp; p.attack_anim = 0; p.cds.clear()
	p.use_skill("basic", p.position + Vector2(100, 0))
	check(is_equal_approx(p.cd_full.cinder_thread, 0.56), "chosen cooldown reduction applies to primary slot")
	p.cancel_casts(); p.attack_anim = 0; p.cds.clear()
	p.assign_skill(4, "cinder_thread"); p.use_skill("s4", p.position + Vector2(100, 0))
	check(is_equal_approx(p.cd_full.cinder_thread, 0.56), "cooldown duration does not depend on hotbar position")
	# Persist current resources and stable-ID cooldowns, with explicit class data.
	p.cancel_casts(); p.attack_anim = 0; p.cds = {"cinder_thread": 0.4}; p.cd_full = {"cinder_thread": 0.56}
	p.hp = 53; p.mp = 27; main.save_game()
	var saved: Dictionary = main._read_save(main.SAVE_PATH)
	check(int(saved.schema) == 6 and saved.class_id == "mage", "schema six stores class identity")
	p.hp = 1; p.mp = 1; p.class_id = "warrior"; p.cds.clear()
	check(main.load_game() and p.class_id == "mage" and p.hp == 53 and p.mp == 27 and is_equal_approx(p.cds.cinder_thread, 0.4), "save reload preserves Mage, resources and cooldowns")
	var malformed: Dictionary = saved.duplicate(true); malformed.gear = "bad"
	check(not main._valid_save(malformed), "malformed gear is rejected before typed model calls")
	malformed = saved.duplicate(true); malformed.cooldowns.cinder_thread = -10
	check(not main._valid_save(malformed), "negative cooldown save values are rejected")
	malformed = saved.duplicate(true); malformed.class_id = "unknown"
	check(not main._valid_save(malformed), "unknown saved class cannot silently become Warrior")
	var legacy: Dictionary = saved.duplicate(true); legacy.schema = 2; legacy.erase("class_id"); legacy.gear = {}; legacy.hotbar = ["slash", "cleave", "charge", "rally", ""]
	check(main._valid_save(legacy), "schema two Warrior state remains explicitly importable")
	# Stable content and vendor state; an empty vendor remains empty after reload.
	main.merchant_stock.clear(); main.save_game(); main.load_game()
	check(main.merchant_stock.is_empty(), "empty merchant stock survives save/load without regeneration")
	# Visual captures use known gear and named test character.
	reset_actor(); p.hero_name = "Aster"; p.level = 10; p.hp = p.stats().max_hp; p.mp = p.stats().max_mp
	for base in ["staff", "wand", "focus", "robe", "hood", "wraps", "slippers", "ring"]: Systems.insert(p.inventory, Systems.make_item(1, 0.2, base, "mage"))
	p.equip_item(0, "weapon")
	ui.toasts.clear(); ui.banner_t = 99
	ui.open_page("inventory"); await frames(); await shot("02_mage_inventory"); ui.close_page()
	ui.selected_spell = "glacial_stitch"; ui.open_page("spells"); await frames(); await shot("03_mage_grimoire"); ui.close_page()
	p.level = 20; p.spec = "mage_arcane"; ui.open_choice("adv"); await frames()
	var locked_choice := find_button(ui.choice_panel, "Choose")
	check(locked_choice != null and locked_choice.disabled, "future heroic preview cannot invest before level forty")
	if ui.choice_panel != null: ui.choice_panel.queue_free(); ui.choice_panel = null; ui._refresh_pause()
	p.level = 40; ui.open_choice("adv"); await frames(); await shot("04_chronomancer"); ui._choose("adv", "chronomancer", "Chronomancer", Color("c3a9ff")); await frames()
	p.level = 10; p.spec = ""; p.adv = ""; p.hp = p.stats().max_hp; p.mp = p.stats().max_mp
	p.cds.clear(); p.attack_anim = 0; p.invuln = 30
	ui.toasts.clear(); ui.banner_t = 99
	await shot("05_mage_plaza")
	if capture:
		var target := dummy(Vector2(190, 10)); target.hp = 10000; target.max_hp = 10000
		for i in 42:
			if i == 1 or i == 10 or i == 31: p.use_skill("basic", target.position)
			if i == 7: p.use_skill("s1", target.position)
			if i == 16: p.use_skill("s4", target.position)
			if i == 25: p.use_skill("s3", p.position)
			await wait(0.08); await shot("mage_combat_%02d" % i)
	var file := FileAccess.open("res://tests/MAGE_LAST_RUN.txt", FileAccess.WRITE)
	file.store_string("Godot " + Engine.get_version_info().string + " / " + DisplayServer.get_name() + "\n" + "\n".join(report) + "\n%d checks; %d failures\n" % [checks, failures]); file.close()
	print("MAGE RESULT %d checks; %d failures" % [checks, failures])
	await main.quit_game(1 if failures else 0)
