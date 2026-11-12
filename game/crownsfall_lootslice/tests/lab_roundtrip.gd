extends SceneTree
## Persistent scene-tree test: survives F7 scene replacement.
var checks := 0
var failures := 0
var report: Array[String] = []
var capture := false
var prefix := "res://previews/three_d/"
func _initialize() -> void:
	capture = DisplayServer.get_name() != "headless"
	_run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1; report.append(("PASS " if ok else "FAIL ") + message); print(report[-1])
	if not ok: failures += 1
func frames(n := 3) -> void:
	for i in n: await process_frame
func wait(seconds: float) -> void:
	await create_timer(seconds).timeout
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.pressed = pressed
	Input.parse_input_event(event)
	await frames(2)
func shot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(prefix + name + ".png")
func finish() -> void:
	var file := FileAccess.open("res://tests/LAB_LAST_RUN.txt", FileAccess.WRITE)
	file.store_string("Godot " + Engine.get_version_info().string + " / " + DisplayServer.get_name() + "\n" + "\n".join(report) + "\n%d checks; %d failures\n" % [checks, failures]); file.close()
	print("LAB RESULT %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(prefix)
	change_scene_to_file("res://main.tscn")
	await frames(5)
	var main: Node2D = current_scene
	if main == null: check(false, "plaza loads"); finish(); return
	if main.hud.start_panel != null:
		main.hud.start_panel.queue_free(); main.hud.start_panel = null; main.hud._refresh_pause()
	main.had_save = false; main.save_blocked = false
	check(main.create_character("mage", "Rig Wayfarer"), "Mage fixture created on authoritative mechanics")
	main.had_save = true
	var player: Node2D = main.player
	player.level = 10; player.gold = 123; player.potions = 2
	check(player.equip_item(0, "weapon"), "staff gear fixture equips before scene switch")
	var weapon_uid: String = player.gear.weapon.uid
	var bag_uids: Array[String] = []
	for item in player.inventory: bag_uids.append(item.uid)
	var ring: Dictionary = preload("res://scripts/systems.gd").make_item(1, 0, "ring")
	preload("res://scripts/systems.gd").insert(player.stash, ring)
	var stash_uid: String = ring.uid
	player.hp = 53; player.mp = 27
	player.cds = {"arcane_fold": 7.5}; player.cd_full = {"arcane_fold": 8.0}
	main.rift.active = true
	main._enter_articulation_lab()
	check(current_scene == main, "F7 refuses to discard an active Scar encounter")
	main.rift.active = false
	await key(KEY_F7, true)
	await key(KEY_F7, false)
	await frames(6)
	var lab: Node3D = current_scene as Node3D
	check(lab != null, "F7 enters the real 3D lab scene")
	if lab == null: finish(); return
	await wait(0.35)
	var rig: CharacterBody3D = lab.player
	check(rig != null and rig.body != null, "GLB scene instantiated under CharacterBody3D")
	var skeletons: Array = rig.body.find_children("*", "Skeleton3D", true, false)
	check(skeletons.size() == 1 and skeletons[0].get_bone_count() == 58, "imported runtime skeleton has 58 bones")
	check(rig.animation != null and rig.clip_names.size() == 6, "runtime AnimationPlayer has all six named clips")
	var required := ["Idle", "Walk", "Run", "Slash", "Dodge", "Cast"]
	check(required.all(func(name: String) -> bool: return rig.clip_names.has(name)), "clip library names resolve all required actions")
	check(rig.animation.get_animation(rig.clip_names.Walk).loop_mode == Animation.LOOP_LINEAR and rig.animation.get_animation(rig.clip_names.Idle).loop_mode == Animation.LOOP_LINEAR, "locomotion and idle explicitly loop in-engine")
	rig.set_physics_process(false)
	rig.animation.play(rig.clip_names.Walk, 0)
	rig.animation.advance(0.1)
	var poses: Array[Transform3D] = []
	for i in skeletons[0].get_bone_count(): poses.append(skeletons[0].get_bone_pose(i))
	rig.animation.advance(0.3)
	var changed := 0
	for i in poses.size():
		if not poses[i].is_equal_approx(skeletons[0].get_bone_pose(i)): changed += 1
	check(changed > 0, "Walk animation changes actual runtime bone poses")
	rig.anim_state = ""; rig._play("Idle"); rig.set_physics_process(true)
	await shot("01_runtime_rig_lab")
	var before: Vector3 = rig.position
	await key(KEY_W, true); await wait(0.2)
	check(rig.position.distance_to(before) > 0.25, "WASD input moves imported actor on the 3D floor")
	var walk_speed := Vector2(rig.velocity.x, rig.velocity.z).length()
	await key(KEY_SHIFT, true); await wait(0.12)
	check(Vector2(rig.velocity.x, rig.velocity.z).length() > walk_speed + 1, "Shift changes real locomotion speed")
	await key(KEY_SHIFT, false); await key(KEY_W, false)
	var target: Node3D = lab.targets[0]
	target.position = rig.position + rig.last_face * 1.4; target.position.y = 0
	var hp_before: float = target.hp
	rig._attack("Slash", 0.72)
	await wait(0.12)
	check(target.hp == hp_before, "3D slash waits for its contact event")
	await wait(0.23)
	check(target.hp == hp_before - 32, "3D slash applies one timed target impact")
	await wait(0.45)
	check(target.hp == hp_before - 32, "slash recovery does not reapply damage each frame")
	rig._dodge()
	var hero_hp: float = rig.hp
	rig.receive_damage(50)
	check(rig.dodge_t > 0 and rig.hp == hero_hp, "dodge plays and grants its bounded invulnerability")
	await wait(0.7)
	rig.receive_damage(25)
	check(rig.hp == hero_hp - 25, "damage resumes after dodge invulnerability ends")
	target.position = rig.position + rig.last_face * 1.4; target.position.y = 0
	hp_before = target.hp
	rig._attack("Cast", 1.4)
	await wait(0.3)
	check(target.hp == hp_before, "3D cast anticipation precedes damage")
	await wait(0.35)
	check(target.hp == hp_before - 53, "3D cast resolves on its scheduled impact")
	await wait(0.85)
	target.hp = 1
	rig._attack("Slash", 0.72); await wait(0.4)
	var kills_before: int = lab.kills
	lab._on_impact(rig.global_position, "Slash", rig.last_face)
	check(target.inactive_t > 0 and lab.kills == kills_before, "inactive dummy cannot yield repeated kill credit")
	await shot("02_runtime_contact")
	if capture:
		await wait(0.4)
		rig.spell_cd = 0; rig.attack_cd = 0; rig.attack_t = 0
		for i in 20:
			if i == 1: rig._attack("Cast", 1.4)
			if i == 15: rig._dodge()
			await wait(0.08); await shot("rig_frame_%02d" % i)
	await key(KEY_F7, true); await key(KEY_F7, false); await frames(6)
	var restored: Node2D = current_scene as Node2D
	check(restored != null, "F7 returns from lab to 2D gameplay")
	if restored == null: finish(); return
	var returned: Node2D = restored.player
	check(returned.class_id == "mage" and returned.hero_name == "Rig Wayfarer", "return preserves chosen Mage class and player name")
	check(returned.gold == 123 and returned.potions == 2, "return preserves currency and potions")
	check(returned.gear.weapon != null and returned.gear.weapon.uid == weapon_uid, "return preserves equipped staff UID")
	var restored_uids: Array[String] = []
	for item in returned.inventory: restored_uids.append(item.uid)
	check(restored_uids == bag_uids and returned.stash.size() == 1 and returned.stash[0].uid == stash_uid, "return preserves backpack and stash ownership exactly")
	check(returned.hp < 56 and returned.mp < 30, "lab return does not refill persistent gameplay resources")
	check(returned.cds.get("arcane_fold", 0) > 7, "main-world cooldown remains frozen during independent lab session")
	check(not paused and restored.hud.start_panel == null, "return leaves gameplay unpaused without duplicate creation")
	await shot("03_returned_mage")
	finish()
