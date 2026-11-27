extends SceneTree
## Writes the class / skill / item-visual Resources (data/classes, data/skills, data/item_visuals) from the skill
## table and the existing art. Run once (or after a design change) with:
##   godot --headless --script res://tools/build_class_resources.gd
const SKILL_DATA := preload("res://scripts/game/data/skill_data.gd")
const SKILL_MOD := preload("res://scripts/game/data/skill_mod.gd")
const CLASS_DATA := preload("res://scripts/game/data/class_data.gd")
const ITEM_VISUAL := preload("res://scripts/game/data/item_visual.gd")
const TABLE := preload("res://tools/skill_table.gd")
const SHAPE_KEYS := ["id", "name", "icon", "unlock", "anim", "shape", "cost", "cd", "desc", "mods", "basic"]

func _initialize() -> void:
	for cls in ["warrior", "mage"]:
		var cd = CLASS_DATA.new()
		cd.id = cls
		cd.display_name = "Knight" if cls == "warrior" else "Mage"
		cd.hero_name = "Sir Aldric" if cls == "warrior" else "Maren"
		cd.description = "Sword and shield. Close-quarters strikes, a sweeping cleave and a charging dash. Plate armour and a deep well of life." if cls == "warrior" else "Staff and spellbook. Fire and frost from afar, a blink, a ward and a falling star. Fragile, but devastating from range."
		cd.hero_model = load("res://models/higgsfield_pilot/knight_pilot_armed.glb" if cls == "warrior" else "res://models/higgsfield_mage/mage_pilot_armed.glb")
		cd.portrait = load("res://assets/%s/idle_se.png" % ("knight" if cls == "warrior" else "mage"))
		cd.idle_sprite = cd.portrait
		cd.radiant_spells = cls == "mage"
		cd.starter_weapon = "weapon" if cls == "warrior" else "staff"
		var skills: Array[SkillData] = []
		for d in TABLE.DEFS[cls]:
			var s = SKILL_DATA.new()
			s.id = d["id"]; s.display_name = d["name"]; s.description = d["desc"]
			s.icon = load("res://assets/skill_tiles/%s.png" % d["icon"])
			s.unlock_level = int(d["unlock"]); s.basic = bool(d.get("basic", false))
			s.animation = d["anim"] if d["anim"] != "" else "None"; s.shape = d["shape"]
			s.mana_cost = float(d.get("cost", 0)); s.cooldown = float(d.get("cd", 0))
			s.sound = d["id"] if ResourceLoader.exists("res://assets/audio/%s.wav" % d["id"]) else ""
			var nums := {}
			for k in d:
				if not k in SHAPE_KEYS: nums[k] = d[k]
			s.numbers = nums
			var mods: Array[SkillMod] = []
			for m in d.get("mods", []):
				var sm = SKILL_MOD.new()
				sm.id = m["id"]; sm.display_name = m["name"]; sm.description = m["desc"]
				var ov := {}
				for k in m:
					if not k in ["id", "name", "desc"]: ov[k] = m[k]
				sm.overrides = ov
				mods.append(sm)
			s.upgrades = mods
			var path := "res://data/skills/%s.tres" % s.id
			ResourceSaver.save(s, path)
			skills.append(load(path))
		cd.skills = skills
		cd.weapon_visuals = _visuals(cls, "weapon", "WEAPON_" if cls == "warrior" else "MAGE_Staff")
		cd.offhand_visuals = _visuals(cls, "offhand", "SHIELD_" if cls == "warrior" else "MAGE_Tome")
		cd.armor_visuals = _visuals(cls, "armor", "")
		var cpath := "res://data/classes/%s.tres" % ("knight" if cls == "warrior" else "mage")
		print("saved ", cpath, " ", ResourceSaver.save(cd, cpath))
	quit()

## Four looks per slot, by item rarity (Common, Magic, Rare, Legendary), in the hero's painted palette.
func _visuals(cls: String, slot: String, prefix: String) -> Array[ItemVisual]:
	var out: Array[ItemVisual] = []
	var looks := [
		{"name": "common", "tint": Color(1, 1, 1), "glow": Color(0, 0, 0, 0), "cloth": Color(0, 0, 0, 0), "metal": Color(0, 0, 0, 0)},
		{"name": "magic", "tint": Color(0.92, 0.97, 1.08), "glow": Color(0.45, 0.65, 1.0, 0.35), "cloth": Color("2f5fa8"), "metal": Color("cfd8e6")},
		{"name": "rare", "tint": Color(1.08, 1.0, 0.86), "glow": Color(1.0, 0.82, 0.35, 0.55), "cloth": Color("8a2230"), "metal": Color("e3c27a")},
		{"name": "legendary", "tint": Color(1.12, 0.95, 0.8), "glow": Color(1.0, 0.55, 0.15, 0.8), "cloth": Color("2a1d3a"), "metal": Color("f0b85a")}]
	for i in looks.size():
		var v = ITEM_VISUAL.new()
		var L: Dictionary = looks[i]
		v.id = "%s_%s_%s" % [cls, slot, L["name"]]
		v.slot = slot
		v.mesh_prefix = prefix
		v.tint = L["tint"]
		v.glow = L["glow"]
		if slot == "armor": v.cloth = L["cloth"]; v.metal = L["metal"]
		var path := "res://data/item_visuals/%s.tres" % v.id
		ResourceSaver.save(v, path)
		out.append(load(path))
	return out
