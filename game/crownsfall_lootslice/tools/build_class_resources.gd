extends SceneTree
## Writes the class / skill / item-visual Resources (data/classes, data/skills, data/item_visuals) from the skill
## table and the existing art. Run once (or after a design change) with:
##   godot --headless --script res://tools/build_class_resources.gd
const SKILL_DATA := preload("res://scripts/game/data/skill_data.gd")
const SKILL_MOD := preload("res://scripts/game/data/skill_mod.gd")
const CLASS_DATA := preload("res://scripts/game/data/class_data.gd")
const ITEM_VISUAL := preload("res://scripts/game/data/item_visual.gd")
const TABLE := preload("res://tools/skill_table.gd")
## The four classes of the one customizable hero (owner 11-27: "one fully customizable character that we can change
## any and all classes with it (warrior, rogue, mage, cleric)"). Same face, body and 24-bone rig; the outfit GLB changes.
const CLASSES := {
	"warrior": {"file": "knight", "name": "Knight", "hero": "Sir Aldric", "model": "res://models/higgsfield_pilot/knight_pilot_armed.glb", "portrait": "res://assets/portraits/warrior.png",
		"weapon_prefix": "WEAPON_", "offhand_prefix": "SHIELD_",
		"desc": "Sword and shield. Close-quarters strikes, a sweeping cleave and a charging dash. Plate armour and a deep well of life."},
	"rogue": {"file": "rogue", "name": "Rogue", "hero": "Aldric", "model": "res://models/higgsfield_rogue/rogue_armed.glb", "portrait": "res://assets/portraits/rogue.png",
		"weapon_prefix": "WEAPON_", "offhand_prefix": "OFFHAND_",
		"desc": "Twin daggers and a hooded cloak. Fast cuts, thrown knives, a shadowstep and a storm of blades. Light leather, quick to kill and quick to vanish."},
	"mage": {"file": "mage", "name": "Mage", "hero": "Maren", "model": "res://models/higgsfield_mage/mage_pilot_armed.glb", "portrait": "res://assets/portraits/mage.png",
		"weapon_prefix": "MAGE_Staff", "offhand_prefix": "MAGE_Tome",
		"desc": "Staff and spellbook. Fire and frost from afar, a blink, a ward and a falling star. Fragile, but devastating from range."},
	"cleric": {"file": "cleric", "name": "Cleric", "hero": "Brother Aldric", "model": "res://models/higgsfield_cleric/cleric_armed.glb", "portrait": "res://assets/portraits/cleric.png",
		"weapon_prefix": "WEAPON_", "offhand_prefix": "SHIELD_",
		"desc": "Mace and sun shield. Holy strikes that mend you, a shield of light, a prayer and pillars of dawn. Chainmail and steady healing."},
}
const SHAPE_KEYS := ["id", "name", "icon", "unlock", "anim", "shape", "cost", "cd", "desc", "mods", "basic"]

func _initialize() -> void:
	for cls in CLASSES:
		var C: Dictionary = CLASSES[cls]
		var cd = CLASS_DATA.new()
		cd.id = cls
		cd.display_name = C["name"]
		cd.hero_name = C["hero"]
		cd.description = C["desc"]
		# Rogue / Cleric: the class is offered on the title screen only once its rigged outfit GLB exists
		cd.hero_model = load(C["model"]) if ResourceLoader.exists(C["model"]) else null
		cd.portrait = load(C["portrait"]) if ResourceLoader.exists(C["portrait"]) else null
		var sprite: String = {"warrior": "res://assets/knight/idle_se.png", "mage": "res://assets/mage/idle_se.png"}.get(cls, C["portrait"])
		cd.idle_sprite = load(sprite) if ResourceLoader.exists(sprite) else cd.portrait
		cd.radiant_spells = cls == "mage"
		cd.starter_weapon = "staff" if cls == "mage" else "weapon"
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
		cd.weapon_visuals = _visuals(cls, "weapon", C["weapon_prefix"])
		cd.offhand_visuals = _visuals(cls, "offhand", C["offhand_prefix"])
		cd.armor_visuals = _visuals(cls, "armor", "")
		var cpath := "res://data/classes/%s.tres" % C["file"]
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
