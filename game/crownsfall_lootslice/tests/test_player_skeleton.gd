extends SceneTree
## Player skeleton (owner project rules): the playable classes are data — ClassData / SkillData / SkillMod /
## ItemVisual Resources (data/classes, data/skills, data/item_visuals) with art assigned in the Inspector — and one
## hero controller plays them all (no class subclasses). Fully headless:
##   godot --headless --script res://tests/test_player_skeleton.gd
const SKILLS := preload("res://scripts/game/skills.gd")
const STATE := preload("res://scripts/game/game_state.gd")
const GEAR := preload("res://scripts/game/gear_visuals.gd")
const CONTROLLER := preload("res://scripts/three_d/rig_controller.gd")
const SHAPES := ["arc", "line", "dash", "nova", "ground", "blink", "buff", "ward"]
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + why)

func _initialize() -> void:
	# one controller script for every class; no class-specific subclasses of it anywhere in the project
	var subclasses := []
	for dir_path in ["res://scripts", "res://scripts/three_d", "res://scripts/game", "res://scripts/game/data"]:
		var d := DirAccess.open(dir_path)
		if d == null: continue
		for f in d.get_files():
			if f.ends_with(".gd"):
				var src := FileAccess.get_file_as_string(dir_path + "/" + f)
				if src.contains('extends "res://scripts/three_d/rig_controller.gd"') or src.contains("extends RigController"): subclasses.append(f)
	check(subclasses.is_empty(), "No class-specific subclasses of the hero controller (%s)" % ", ".join(subclasses))
	for cid in ["warrior", "mage"]:
		var cd: Resource = SKILLS.class_data(cid)
		var label: String = "Knight" if cid == "warrior" else "Mage"
		check(cd != null and cd.get_script().resource_path.ends_with("class_data.gd"), "%s: ClassData resource loads" % label)
		check(cd.id == cid and cd.display_name == label and cd.hero_name != "", "%s: identity fields" % label)
		check(cd.hero_model is PackedScene and cd.portrait is Texture2D and cd.idle_sprite is Texture2D, "%s: art assigned (hero model, portrait, idle sprite)" % label)
		check(cd.hero_model.resource_path.begins_with("res://models/") and cd.portrait.resource_path.begins_with("res://assets/"), "%s: art points at the existing assets in place" % label)
		check(cd.skills.size() == 6, "%s: six SkillData resources" % label)
		var basics := 0; var unlocks := []
		for s in cd.skills:
			var ok: bool = s.id != "" and s.display_name != "" and s.icon is Texture2D and s.shape in SHAPES and s.upgrades.size() == 2
			ok = ok and (s.animation == "None" or CONTROLLER.WARRIOR_SKILLS.has(s.animation) or CONTROLLER.MAGE_SPELLS.has(s.animation))
			check(ok, "%s / %s: complete (icon, shape %s, animation %s, 2 upgrades)" % [label, s.display_name, s.shape, s.animation])
			if s.basic: basics += 1
			unlocks.append(s.unlock_level)
			for m in s.upgrades:
				check(m.id != "" and not m.overrides.is_empty(), "%s / %s / %s: upgrade changes numbers" % [label, s.display_name, m.display_name])
		check(basics == 1, "%s: exactly one primary attack" % label)
		check(unlocks == [1, 1, 3, 5, 8, 12], "%s: unlock levels 1,1,3,5,8,12 (%s)" % [label, unlocks])
		for slot in ["weapon_visuals", "offhand_visuals", "armor_visuals"]:
			var vs: Array = cd.get(slot)
			check(vs.size() == 4, "%s: four %s (one per rarity)" % [label, slot])
		# rules on the character record (pure logic)
		var st = STATE.new()
		st.class_id = cid; st.level = 1
		st.bar = ["", "", "", "", "", "", "", ""]
		check(st.unlock_skills().size() == 2, "%s: two skills at level 1" % label)
		st.add_xp(100000)
		var learned: Array = st.unlock_skills()
		check(learned.size() == 4 and st.skill_points == st.level - 1, "%s: levelling learns the other four and grants points (%d)" % [label, st.skill_points])
		var sid: String = cd.skills[1].id
		for i in 2: st.rank_up(sid)
		check(st.rank(sid) == 3, "%s: rank up %s to 3" % [label, sid])
		var mod: Resource = cd.skills[1].upgrades[1]
		check(st.choose_mod(sid, mod.id) == "", "%s: choose upgrade %s" % [label, mod.display_name])
		var r: Dictionary = SKILLS.resolved(cid, sid, st.skill_mod(sid))
		var keys_ok := true
		for k in mod.overrides: keys_ok = keys_ok and r.get(k) == mod.overrides[k]
		check(keys_ok, "%s: the upgrade's numbers replace the skill's" % label)
		var before: int = st.skill_points
		st.respec()
		check(st.rank(sid) == 1 and st.skill_mod(sid) == "" and st.skill_points == before + 2, "%s: respec refunds points" % label)
		# gear on the real hero model (no rendering needed)
		var body: Node3D = cd.hero_model.instantiate()
		root.add_child(body)
		var gv = GEAR.new()
		root.add_child(gv)
		gv.setup(body, cd)
		var off_prefix: String = cd.offhand_visuals[0].mesh_prefix
		var w_prefix: String = cd.weapon_visuals[0].mesh_prefix
		check(not gv._meshes(w_prefix).is_empty() and not gv._meshes(off_prefix).is_empty(), "%s: hero has weapon (%s) and off-hand (%s) meshes" % [label, w_prefix, off_prefix])
		var SYS = load("res://scripts/systems.gd")
		var gear := {"weapon": {"slot": "weapon", "rarity": 0}}
		gv.apply(gear)
		check(gv._meshes(off_prefix).all(func(m): return not m.visible), "%s: no off-hand equipped -> hidden" % label)
		check(gv._meshes(w_prefix).all(func(m): return m.get_surface_override_material(0) == null), "%s: common weapon keeps its painted look" % label)
		gear = {"weapon": {"slot": "weapon", "rarity": 3}, "offhand": {"slot": "offhand", "rarity": 2}, "armor": {"slot": "armor", "rarity": 2}}
		gv.apply(gear)
		check(gv._meshes(off_prefix).all(func(m): return m.visible), "%s: off-hand equipped -> shown" % label)
		check(gv._meshes(w_prefix).all(func(m): return range(m.mesh.get_surface_count()).all(func(i): return m.get_surface_override_material(i) is BaseMaterial3D and m.get_surface_override_material(i).emission_enabled)), "%s: legendary weapon glows (every surface keeps its own material)" % label)
		var body_mesh: MeshInstance3D = body.find_child("char1", true, false)
		check(body_mesh != null and body_mesh.material_override is ShaderMaterial and body_mesh.material_override.get_shader_parameter("cloth").a > 0.0, "%s: rare armour recolours the body (armour tier)" % label)
		check(gv.applied["weapon"].ends_with("legendary") and gv.applied["armor"].ends_with("rare"), "%s: visuals chosen by rarity (%s, %s)" % [label, gv.applied["weapon"], gv.applied["armor"]])
		gv.apply({})
		check(body_mesh.material_override == null, "%s: unequipping restores the hero" % label)
		body.queue_free(); gv.queue_free()
	# a new Knight starts with sword and shield, a new Mage with staff
	var k = STATE.new_character("warrior")
	check(k.gear.has("weapon") and k.gear.has("offhand"), "New Knight: sword and shield equipped")
	var m = STATE.new_character("mage")
	check(m.gear.has("weapon") and String(m.gear["weapon"]["slot"]) == "staff", "New Mage: staff equipped")
	print("AOTL PLAYER SKELETON RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
