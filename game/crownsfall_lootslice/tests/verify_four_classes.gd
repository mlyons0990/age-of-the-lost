extends SceneTree
## The one hero, four classes (owner 11-27): each class plays its own rigged 3D outfit with its weapons on the hands,
## starts with the right gear, and every one of its six skills works on real monsters (Rogue and Cleric in full;
## Knight and Mage are covered by verify_skills.gd). Also: new-character naming, saving and reloading each class.
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


const MODELS := {"warrior": "knight_pilot_armed", "rogue": "rogue_armed", "mage": "mage_pilot_armed", "cleric": "cleric_armed"}
const WEAPONS := {"warrior": ["WEAPON_Blade"], "rogue": ["WEAPON_DaggerR", "WEAPON_DaggerL"], "mage": ["MAGE_Staff"], "cleric": ["WEAPON_Mace", "SHIELD_Sun"]}

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	for cls in ["warrior", "rogue", "mage", "cleric"]:
		load("res://scripts/game/game_state.gd").new_character(cls, "Test " + cls.capitalize())
		var named = load("res://scripts/game/game_state.gd").load_saved()
		check(named.hero_name == "Test " + cls.capitalize() and named.class_id == cls, "%s: a new hero keeps the chosen name" % cls)
		await _start(cls)
		var st = lab.game_state
		var p = lab.player
		var meshes: Array = p.find_children("*", "MeshInstance3D", true, false).map(func(m): return String(m.name))
		var found := true
		for w in WEAPONS[cls]:
			if meshes.filter(func(n): return n.begins_with(w)).is_empty(): found = false
		check(p.is_pilot_hero() and found, "%s: plays its 3D outfit with %s on the hands" % [cls, WEAPONS[cls]])
		check(p.animation.has_animation("Idle") and p.animation.has_animation("Left_Slash") or cls == "mage", "%s: has the shared library clips" % cls)
		var w_ok: bool = st.gear.get("weapon") != null and (st.gear.get("offhand") != null) == (cls in ["warrior", "cleric"])
		check(w_ok, "%s: starts with its weapon%s" % [cls, " and shield" if cls in ["warrior", "cleric"] else ""])
		if cls == "rogue":
			var pool: Array = load("res://scripts/systems.gd").drop_pool("rogue")
			check(not "offhand" in pool, "rogue: no shields drop for the twin-dagger class")
		# class weapon attacks: the basic attack (LMB) and Q play the class's own clip, hips stay planted
		var expect: Dictionary = {"warrior": {"Slash": "Pilot_Slash"}, "rogue": {"Slash": "Move_Slash", "Cleave": "Move_Cleave"},
			"cleric": {"Slash": "Move_Slash", "Cleave": "Move_Cleave"}}.get(cls, {})
		for kind in expect:
			p.global_position = lab.zone_px_to_world(5900, 1650) + Vector3.UP * 0.08; lab.zone_last_ok = p.global_position
			await _clear_area()
			var ms0 := _pack(1, 1.6)
			_aim(ms0[0].global_position)
			p.attack_t = 0.0; p.attack_cd = 0.0; p.dodge_t = 0.0
			var hp_before: float = ms0[0].hp
			p._attack(kind, 0.72)
			var playing: String = p.animation.current_animation
			var sk: Skeleton3D = p.find_children("*", "Skeleton3D", true, false)[0]
			var drift := 0.0
			var t := 0.0
			while p.attack_t > 0.0 and t < 2.5:
				await physics_frame; t += 1.0 / 60.0
				var hips: Vector3 = (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Hips"))).origin
				drift = maxf(drift, Vector2(hips.x - p.global_position.x, hips.z - p.global_position.z).length())
			await physics_frame
			check(playing == String(expect[kind]) and drift < 0.35, "%s: %s plays %s (hips drift %.2f m)" % [cls, kind, playing, drift])
		if cls in ["rogue", "cleric"]:
			st.add_xp(40000); st.unlock_skills(); g.apply_stats()
			p.global_position = lab.zone_px_to_world(5900, 1650) + Vector3.UP * 0.08; lab.zone_last_ok = p.global_position
			await _clear_area()
			for d in load("res://scripts/game/skills.gd").defs(cls):
				var id: String = d["id"]
				await _clear_area()
				p.global_position = lab.zone_px_to_world(5900, 1650) + Vector3.UP * 0.08; lab.zone_last_ok = p.global_position
				var ms := _pack(3, 2.0)
				_aim(ms[1].global_position)
				var hp0: Array = ms.map(func(m): return m.hp)
				var before: Vector3 = p.global_position
				var ok: bool = await _cast(id)
				if d["shape"] == "ground": await _wait(float(d.get("delay", 0.5)) + 0.3)
				var hit := 0
				for i in 3: if is_instance_valid(ms[i]) and ms[i].hp < hp0[i]: hit += 1
				var effect := ""
				match String(d["shape"]):
					"buff": effect = "buff" if g.buff_t > 0.0 else ""
					"ward": effect = "ward" if g.ward > 0.0 else ""
					"blink": effect = "moved" if p.global_position.distance_to(before) > 0.9 else ""
					_: effect = ("hit %d" % hit) if hit > 0 else ""
				check(ok and effect != "", "%s: %s (%s) works: %s" % [cls, d["name"], d["shape"], effect if effect != "" else "no effect"])
			g.autosave()
			var saved = load("res://scripts/game/game_state.gd").load_saved()
			check(saved.class_id == cls and saved.skills.size() == 6, "%s: class and its six skills save and reload" % cls)
	print("RESULT %d/%d" % [checks - failures, checks])
	quit(1 if failures > 0 else 0)
