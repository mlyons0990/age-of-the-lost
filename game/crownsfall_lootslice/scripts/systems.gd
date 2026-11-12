extends RefCounted
## Pure inventory and stat operations. Coordinates use whole cells; no UI state.
const WIDTH := 10
const HEIGHT := 6
const SLOTS := ["weapon", "offhand", "helm", "armor", "gloves", "belt", "boots", "amulet", "ring1", "ring2"]
const ATTRS := ["strength", "dexterity", "vitality", "intelligence", "wisdom", "charisma"]
const FOOTPRINTS := {"weapon": Vector2i(1, 3), "offhand": Vector2i(2, 2), "helm": Vector2i(2, 2), "armor": Vector2i(2, 3), "gloves": Vector2i(2, 2), "belt": Vector2i(2, 1), "boots": Vector2i(2, 2), "amulet": Vector2i(1, 1), "ring": Vector2i(1, 1), "staff": Vector2i(2, 4), "wand": Vector2i(1, 2), "focus": Vector2i(1, 2), "robe": Vector2i(2, 3), "hood": Vector2i(2, 2), "wraps": Vector2i(2, 2), "slippers": Vector2i(2, 2)}
const NAMES := {"weapon": "Longsword", "offhand": "Kite Shield", "helm": "Sallet", "armor": "Plate Cuirass", "gloves": "Gauntlets", "belt": "War Belt", "boots": "Sabatons", "amulet": "Memory Sigil", "ring": "Signet Ring", "staff": "Aurelian Staff", "wand": "Ember Wand", "focus": "Prismatic Focus", "robe": "Wayfarer Robe", "hood": "Scholar Hood", "wraps": "Silk Wraps", "slippers": "Spellweave Slippers"}
const MULT := [1.0, 1.25, 1.55, 2.0]
const UNIQUE_ID := "emberwake_circlet"

## Whitelisted, stable cosmetic variants sourced from Higgsfield. This is not a
## new loot-system schema: art_id is optional and existing saves remain valid.
const VARIANT_SPECS := {
	"dawnforged_flail": {"name":"Dawnforged Chain Flail", "slot":"weapon", "class":"warrior", "size":Vector2i(1,3), "hands":1, "weapon_style":"flail", "armor_family":""},
	"ashensteel_short_spear": {"name":"Ashensteel Short Spear", "slot":"weapon", "class":"warrior", "size":Vector2i(1,3), "hands":1, "weapon_style":"spear", "armor_family":""},
	"riftglass_sceptre": {"name":"Riftglass Sceptre", "slot":"wand", "class":"mage", "size":Vector2i(1,3), "hands":1, "weapon_style":"sceptre", "armor_family":""},
	"vesper_talon": {"name":"Vesper Talon Fist Weapon", "slot":"weapon", "class":"warrior", "size":Vector2i(2,2), "hands":1, "weapon_style":"fist", "armor_family":""},
	"bastion_greataxe": {"name":"Bastion Greataxe", "slot":"weapon", "class":"warrior", "size":Vector2i(2,4), "hands":2, "weapon_style":"greataxe", "armor_family":""},
	"ironwake_warhammer": {"name":"Ironwake Warhammer", "slot":"weapon", "class":"warrior", "size":Vector2i(2,4), "hands":2, "weapon_style":"warhammer", "armor_family":""},
	"crownspine_halberd": {"name":"Crownspine Halberd", "slot":"weapon", "class":"warrior", "size":Vector2i(2,4), "hands":2, "weapon_style":"glaive", "armor_family":""},
	"wayfarer_oak_quarterstaff": {"name":"Wayfarer's Oak Quarterstaff", "slot":"staff", "class":"mage", "size":Vector2i(2,4), "hands":2, "weapon_style":"quarterstaff", "armor_family":""},
	"greyfen_hauberk": {"name":"Greyfen Warden Hauberk", "slot":"armor", "class":"warrior", "size":Vector2i(2,3), "hands":0, "weapon_style":"", "armor_family":"mail"},
	"greyfen_coif": {"name":"Greyfen Warden Coif", "slot":"helm", "class":"warrior", "size":Vector2i(2,2), "hands":0, "weapon_style":"", "armor_family":"mail"},
	"greyfen_gauntlets": {"name":"Greyfen Warden Gauntlets", "slot":"gloves", "class":"warrior", "size":Vector2i(2,2), "hands":0, "weapon_style":"", "armor_family":"mail"},
	"greyfen_boots": {"name":"Greyfen Warden Boots", "slot":"boots", "class":"warrior", "size":Vector2i(2,2), "hands":0, "weapon_style":"", "armor_family":"mail"},
	"greyfen_belt": {"name":"Greyfen Warden Warbelt", "slot":"belt", "class":"warrior", "size":Vector2i(2,1), "hands":0, "weapon_style":"", "armor_family":"mail"},
	"moonweave_robe": {"name":"Moonweave Arcanist Robe", "slot":"robe", "class":"mage", "size":Vector2i(2,3), "hands":0, "weapon_style":"", "armor_family":"cloth"},
	"moonweave_hood": {"name":"Moonweave Arcanist Hood", "slot":"hood", "class":"mage", "size":Vector2i(2,2), "hands":0, "weapon_style":"", "armor_family":"cloth"},
	"moonweave_gloves": {"name":"Moonweave Arcanist Gloves", "slot":"wraps", "class":"mage", "size":Vector2i(2,2), "hands":0, "weapon_style":"", "armor_family":"cloth"},
	"moonweave_boots": {"name":"Moonweave Arcanist Boots", "slot":"slippers", "class":"mage", "size":Vector2i(2,2), "hands":0, "weapon_style":"", "armor_family":"cloth"},
	"moonweave_belt": {"name":"Moonweave Arcanist Sash", "slot":"belt", "class":"mage", "size":Vector2i(2,1), "hands":0, "weapon_style":"", "armor_family":"cloth"},
	"thornveil_jerkin": {"name":"Thornveil Pathfinder Jerkin", "slot":"armor", "class":"warrior", "size":Vector2i(2,3), "hands":0, "weapon_style":"", "armor_family":"leather"},
	"thornveil_hood": {"name":"Thornveil Pathfinder Hood", "slot":"helm", "class":"warrior", "size":Vector2i(2,2), "hands":0, "weapon_style":"", "armor_family":"leather"},
	"thornveil_gloves": {"name":"Thornveil Pathfinder Gloves", "slot":"gloves", "class":"warrior", "size":Vector2i(2,2), "hands":0, "weapon_style":"", "armor_family":"leather"},
	"thornveil_boots": {"name":"Thornveil Pathfinder Boots", "slot":"boots", "class":"warrior", "size":Vector2i(2,2), "hands":0, "weapon_style":"", "armor_family":"leather"},
	"thornveil_belt": {"name":"Thornveil Pathfinder Belt", "slot":"belt", "class":"warrior", "size":Vector2i(2,1), "hands":0, "weapon_style":"", "armor_family":"leather"},
	"greyfen_shield": {"name":"Greyfen Warden Kite Shield", "slot":"offhand", "class":"warrior", "size":Vector2i(2,2), "hands":0, "weapon_style":"shield", "armor_family":""},
	"moonweave_staff": {"name":"Moonweave Chronicle Staff", "slot":"staff", "class":"mage", "size":Vector2i(2,4), "hands":2, "weapon_style":"staff", "armor_family":""},
	"thornveil_dagger": {"name":"Thornveil Pathfinder Dagger", "slot":"weapon", "class":"warrior", "size":Vector2i(1,2), "hands":1, "weapon_style":"dagger", "armor_family":""},
	"thornveil_buckler": {"name":"Thornveil Pathfinder Buckler", "slot":"offhand", "class":"warrior", "size":Vector2i(2,2), "hands":0, "weapon_style":"shield", "armor_family":""}
}

static func make_unique() -> Dictionary:
	var item := make_item(40, 3.0, "hood", "mage")
	for key in ATTRS: item.erase(key)
	item.merge({"name":"Emberwake Circlet", "unique_id":UNIQUE_ID, "armor":60.0, "intelligence":12.0, "value":125},true)
	return item

static func unique_valid(item: Dictionary) -> bool:
	if not item.has("unique_id"): return true
	var required: Variant = item.get("level",0)
	if not required is float and not required is int: return false
	return is_finite(float(required)) and item.unique_id is String and item.unique_id == UNIQUE_ID and item.get("slot") == "hood" and float(required) >= 40

static func footprint(item: Dictionary) -> Vector2i:
	var id := String(item.get("art_id", ""))
	if VARIANT_SPECS.has(id) and VARIANT_SPECS[id].slot == item.get("slot"):
		return VARIANT_SPECS[id].size
	return FOOTPRINTS.get(String(item.get("slot", "ring")), Vector2i.ONE)

static func variant_valid(item: Dictionary) -> bool:
	if not item.has("art_id"): return true
	var id := String(item.get("art_id", ""))
	return VARIANT_SPECS.has(id) and VARIANT_SPECS[id].slot == item.get("slot")

static func two_handed(item: Variant) -> bool:
	if not item is Dictionary: return false
	if String(item.get("slot", "")) == "staff": return true
	var id := String(item.get("art_id", ""))
	return VARIANT_SPECS.has(id) and VARIANT_SPECS[id].slot == item.get("slot") and int(VARIANT_SPECS[id].hands) == 2

static func make_variant(level: int, art_id: String) -> Dictionary:
	if not VARIANT_SPECS.has(art_id): return {}
	var v: Dictionary = VARIANT_SPECS[art_id]
	var item := make_item(level, 0.0, String(v.slot), String(v["class"]))
	item["name"] = String(v.name)
	item["art_id"] = art_id
	return item

static func shop_variants(class_id: String) -> Array:
	if class_id == "mage":
		return ["moonweave_robe", "moonweave_hood", "moonweave_gloves", "moonweave_boots", "moonweave_belt", "riftglass_sceptre", "wayfarer_oak_quarterstaff", "moonweave_staff"]
	return ["greyfen_hauberk", "greyfen_coif", "greyfen_gauntlets", "greyfen_boots", "greyfen_belt", "greyfen_shield", "thornveil_jerkin", "thornveil_dagger", "thornveil_buckler", "dawnforged_flail", "ashensteel_short_spear", "vesper_talon", "bastion_greataxe", "ironwake_warhammer", "crownspine_halberd"]


static func fits(bag: Array, item: Dictionary, at: Vector2i, ignore := "") -> bool:
	var r := Rect2i(at, footprint(item))
	if at.x < 0 or at.y < 0 or r.end.x > WIDTH or r.end.y > HEIGHT:
		return false
	for other in bag:
		if String(other.get("uid", "")) == ignore and ignore != "":
			continue
		if r.intersects(Rect2i(Vector2i(int(other.get("x", 0)), int(other.get("y", 0))), footprint(other))):
			return false
	return true

static func insert(bag: Array, item: Dictionary) -> bool:
	for y in HEIGHT:
		for x in WIDTH:
			if fits(bag, item, Vector2i(x, y)):
				item["x"] = x
				item["y"] = y
				bag.append(item)
				return true
	return false

static func sort_bag(bag: Array) -> bool:
	var ordered := bag.duplicate(true)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var aa := footprint(a); var bb := footprint(b)
		return aa.x * aa.y > bb.x * bb.y)
	var result: Array = []
	for item in ordered:
		if not insert(result, item):
			return false # preserve original placement when packing fails
	bag.assign(result)
	return true

static func uid() -> String:
	return "%x-%x-%x" % [Time.get_ticks_usec(), randi(), randi()]

static func make_item(level: int, boost := 0.0, forced := "", class_id := "warrior") -> Dictionary:
	level = clampi(level,1,60)
	var keys := drop_pool(class_id)
	var slot: String = forced if NAMES.has(forced) else keys[randi() % keys.size()]
	var roll := randf() + boost
	var rarity := 3 if roll > 0.965 else (2 if roll > 0.83 else (1 if roll > 0.55 else 0))
	var v: float = MULT[rarity] * randf_range(0.85, 1.15)
	var it := {"uid": uid(), "slot": slot, "rarity": rarity, "level": maxi(1, level), "name": NAMES[slot], "dmg": 0.0, "armor": 0.0, "hp": 0.0, "crit": 0.0, "spell_power": 0.0}
	match slot:
		"weapon": it["dmg"] = round((3 + level * 1.6) * v)
		"staff": it["spell_power"] = round((4 + level * 1.9) * v)
		"wand": it["spell_power"] = round((2 + level * 1.1) * v)
		"focus": it["spell_power"] = round((1 + level * 0.6) * v)
		"robe":
			it["armor"] = round((4 + level * 1.4) * v)
			it["intelligence"] = maxi(1, roundi((1 + level * 0.2) * v))
		"hood", "wraps", "slippers": it["armor"] = round((2 + level * 0.7) * v)
		"armor":
			it["armor"] = round((8 + level * 3) * v)
			it["hp"] = round(level * 2 * v)
		"offhand", "helm", "gloves", "boots": it["armor"] = round((4 + level * 1.5) * v)
		"belt": it["hp"] = round((4 + level * 3) * v)
		"ring", "amulet":
			it["crit"] = snappedf(0.012 * v, 0.001)
			it["hp"] = round(level * 2 * v)
	if rarity >= 1:
		var attr: String = ATTRS[randi() % ATTRS.size()]
		it[attr] = float(it.get(attr, 0)) + maxi(1, roundi((1 + level * 0.2) * v))
		it["name"] = ["", "Etched ", "Dawnforged ", "Epochbound "][rarity] + String(NAMES[slot])
	it["value"] = roundi((5 + level * 2) * MULT[rarity] * (1 + rarity))
	return it

static func drop_pool(class_id: String) -> Array:
	return ["staff", "wand", "focus", "robe", "hood", "wraps", "slippers", "belt", "amulet", "ring"] if class_id == "mage" else ["weapon", "offhand", "armor", "helm", "gloves", "boots", "belt", "amulet", "ring"]

static func default_slot(item: Dictionary) -> String:
	return {"ring": "ring1", "staff": "weapon", "wand": "weapon", "focus": "offhand", "robe": "armor", "hood": "helm", "wraps": "gloves", "slippers": "boots"}.get(String(item.get("slot", "")), String(item.get("slot", "")))

static func legal_slot(item: Dictionary, slot: String) -> bool:
	return default_slot(item) == slot or (item.get("slot") == "ring" and slot == "ring2")

static func class_allows(item: Dictionary, class_id: String) -> bool:
	var art_id := String(item.get("art_id", ""))
	if item.has("art_id") and (not variant_valid(item) or String(VARIANT_SPECS[art_id]["class"]) != class_id):
		return false
	return drop_pool(class_id).has(String(item.get("slot", "")))

static func gear_valid(gear: Dictionary, class_id: String, level: int) -> bool:
	var unique_ids := {}
	for slot in gear:
		var item = gear[slot]
		if item == null: continue
		if not item is Dictionary or not variant_valid(item) or not legal_slot(item, slot) or not class_allows(item, class_id) or int(item.get("level", 1)) > level: return false
		if not unique_valid(item): return false
		if item.has("unique_id"):
			if unique_ids.has(item.unique_id): return false
			unique_ids[item.unique_id] = true
	if two_handed(gear.get("weapon")) and gear.get("offhand") != null: return false
	return true

static func derive(level: int, gear: Dictionary, modifiers: Dictionary, class_id := "warrior") -> Dictionary:
	var a := {"strength": 10.0 + 2 * (level - 1), "dexterity": 8.0 + level - 1, "vitality": 10.0 + 2 * (level - 1), "intelligence": 6.0 + level - 1, "wisdom": 7.0 + level - 1, "charisma": 5.0 + floor((level - 1) / 2.0)}
	if class_id == "mage":
		a = {"strength": 4.0, "dexterity": 8.0 + 0.5 * (level - 1), "vitality": 8.0 + level - 1, "intelligence": 12.0 + 3 * (level - 1), "wisdom": 10.0 + 2 * (level - 1), "charisma": 5.0 + floor((level - 1) / 2.0)}
	var g := {"dmg": 0.0, "armor": 0.0, "hp": 0.0, "crit": 0.0, "spell_power": 0.0}
	for it in gear.values():
		if it is Dictionary:
			for k in a: a[k] += float(it.get(k, 0.0))
			for k in g: g[k] += float(it.get(k, 0.0))
	var power: float = (10 + 3 * (level - 1) + g.dmg) * (1 + 0.008 * a.strength + float(modifiers.get("dmg", 0)))
	var spell: float = power * (1 + 0.006 * a.intelligence) + g.spell_power
	if class_id == "mage": spell = (10 + 2.5 * (level - 1) + g.spell_power) * (1 + 0.018 * a.intelligence + float(modifiers.get("spell_dmg", 0)))
	return {"max_hp": round((60 + (8 if class_id == "mage" else 12) * (level - 1) + 4 * a.vitality + g.hp) * (1 + float(modifiers.get("hp", 0)))),
		"max_mp": round(30 + 3 * (level - 1) + 2 * a.intelligence + a.wisdom),
		"dmg": power, "spell_power": spell,
		"armor": (5 + 2 * level + g.armor) * (1 + float(modifiers.get("armor", 0))),
		"crit": clampf(0.03 + 0.0015 * a.dexterity + g.crit + float(modifiers.get("crit", 0)), 0, 0.6),
		"mana_regen": 2 + 0.12 * a.wisdom, "attributes": a, "m": modifiers}

static func clean_item(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not NAMES.has(String(raw.get("slot", ""))): return {}
	var out := {"uid": (String(raw.uid) if raw.has("uid") else uid()), "slot": String(raw.slot), "name": String(raw.get("name", "Recovered gear")).left(64), "rarity": clampi(int(raw.get("rarity", 0)), 0, 3), "level": clampi(int(raw.get("level", 1)), 1, 60)}
	for k in ATTRS + ["dmg", "armor", "hp", "crit", "spell_power"]:
		var value: float = float(raw.get(k, 0))
		out[k] = clampf(value, 0, 0.2 if k == "crit" else 10000) if is_finite(value) else 0.0
	out["x"] = clampi(int(raw.get("x", 0)), 0, WIDTH - 1)
	out["y"] = clampi(int(raw.get("y", 0)), 0, HEIGHT - 1)
	out["value"] = clampi(int(raw.get("value", 5)), 1, 100000)
	if raw.has("unique_id") and unique_valid(raw): out.unique_id = raw.unique_id
	if variant_valid(raw) and raw.has("art_id"): out["art_id"] = String(raw.art_id)
	return out

