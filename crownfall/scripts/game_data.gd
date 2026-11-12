extends RefCounted
## Shared game data: classes, specializations, enemies and items.
## Everything here is work in progress and meant to be edited freely.
##
## Progression: Knight (Lv1) -> spec (Lv10) -> advanced spec (Lv40) -> Heroic Talent (Lv60).
##
## Skill "type" values the engine understands:
##   melee  - short swing in front of the knight           (range, arc)
##   arc    - wide cleave in front                          (range, arc)
##   dash   - charge toward the cursor, hitting everything  (range)
##   buff   - heal % of max HP and boost damage             (heal, dmg_buff, duration)
##   nova   - burst around the knight                       (radius, heal_per_hit)
##   cone   - long cone toward the cursor, can burn         (range, arc, burn)
##   ground - delayed blast at the cursor                   (radius, delay)
## Distances are in ground units (U pixels). dmg multiplies weapon damage.

const U := 88.0    # pixels per ground unit
const SQ := 0.72   # vertical squash of the painted camera (same as DEPTH_SQUASH)

const SPEC_LEVEL := 10

# ---------------------------------------------------------------- attributes
## The five main stats. Each class has one "main" stat that raises all its damage
## (like World of Warcraft's primary stat or Diablo's main stat). The rest work for every class.
const ATTRS := ["str", "dex", "vit", "int", "wis"]
const ATTR_NAME := {"str": "Strength", "dex": "Dexterity", "vit": "Vitality", "int": "Intelligence", "wis": "Wisdom"}

## What one point of each stat is worth. Tune here.
const PER_POINT := {
	"main_dmg": 0.005,      # +0.5% damage per point of the class's main stat
	"str_armor": 0.5,       # Strength: +0.5 armor
	"dex_crit": 0.0006,     # Dexterity: +0.06% critical strike chance
	"dex_dodge": 0.0005,    # Dexterity: +0.05% chance to dodge an attack
	"vit_life": 5.0,        # Vitality: +5 maximum life
	"int_mana": 3.0,        # Intelligence: +3 maximum mana
	"int_spell": 0.004,     # Intelligence: +0.4% damage with magical (specialization) skills
	"wis_regen": 0.15,      # Wisdom: +0.15 mana per second
	"wis_healing": 0.005,   # Wisdom: +0.5% healing received
}
const DODGE_CAP := 0.3

## Stat points you place yourself each level, like Diablo II.
const POINTS_PER_LEVEL := 5
## Gold to reset all placed points: this much per character level.
const RESPEC_COST_PER_LEVEL := 20

## Starting stats and automatic growth per level, by class.
const CLASS_ATTRS := {
	"knight": {
		"main": "str",
		"base": {"str": 20.0, "dex": 10.0, "vit": 18.0, "int": 8.0, "wis": 8.0},
		# Automatic growth per level (World of Warcraft style). Stat points add on top (Diablo II style).
		"per_level": {"str": 1.0, "dex": 0.5, "vit": 1.0, "int": 0.25, "wis": 0.25},
	},
}

## Help text shown on the character panel.
const ATTR_HELP := {
	"str": "Knight's main stat: +0.5% damage and +0.5 armor per point",
	"dex": "+0.06% critical strike and +0.05% dodge chance per point",
	"vit": "+5 maximum life per point",
	"int": "+3 maximum mana and +0.4% specialization skill damage per point",
	"wis": "+0.15 mana per second and +0.5% healing received per point",
}

## Which stats each item type can roll as bonuses, Diablo-style. Number of rolls depends on rarity.
const AFFIX_POOL := {
	"weapon": ["str", "dex", "int"], "offhand": ["vit", "str", "wis"], "helm": ["int", "vit", "wis"],
	"armor": ["vit", "str", "wis"], "gloves": ["dex", "str", "int"], "belt": ["vit", "str", "wis"],
	"boots": ["dex", "vit", "wis"], "ring": ["str", "dex", "vit", "int", "wis"], "amulet": ["str", "dex", "vit", "int", "wis"],
}
const AFFIX_COUNT := [0, 1, 2, 3]   # common, magic, rare, legendary

## Secondary bonuses, Diablo-style. Rare items roll 1, legendaries 2.
## Values are fractions (0.1 = 10%) except life per hit, which is flat and grows with item level.
const SECONDARY := {
	"crit_dmg": {"name": "critical strike damage", "min": 0.08, "max": 0.22, "pct": true},
	"atk_speed": {"name": "attack speed", "min": 0.04, "max": 0.1, "pct": true},
	"life_hit": {"name": "life per hit", "min": 1.0, "max": 3.0, "pct": false, "per_level": 0.25},
	"cdr": {"name": "cooldown reduction", "min": 0.03, "max": 0.08, "pct": true},
	"move": {"name": "movement speed", "min": 0.03, "max": 0.08, "pct": true},
}
const SECONDARY_POOL := {
	"weapon": ["crit_dmg", "atk_speed", "life_hit"], "offhand": ["life_hit", "cdr"], "helm": ["cdr", "crit_dmg"],
	"armor": ["life_hit", "cdr"], "gloves": ["atk_speed", "crit_dmg", "life_hit"], "belt": ["life_hit", "cdr"],
	"boots": ["move", "cdr"], "ring": ["crit_dmg", "atk_speed", "life_hit", "cdr"], "amulet": ["crit_dmg", "cdr", "move", "life_hit"],
}
const SECONDARY_COUNT := [0, 0, 1, 2]
## Caps so gear can't break the game.
const CAP := {"cdr": 0.5, "atk_speed": 0.75, "move": 0.4}
const ADVANCED_LEVEL := 40
const MAX_LEVEL := 60

const BASE := {
	"basic": {"id": "slash", "name": "Slash", "type": "melee", "dmg": 1.0, "range": 1.5, "arc": 1.6, "cd": 0.55, "mana": -4.0,
		"desc": "A swift sword strike. Restores 4 mana."},
	"s1": {"id": "cleave", "name": "Cleave", "type": "arc", "dmg": 1.6, "range": 2.3, "arc": 2.6, "cd": 2.5, "mana": 12.0,
		"desc": "A sweeping blow that strikes all enemies in front of you."},
	"s2": {"id": "charge", "name": "Shield Charge", "type": "dash", "dmg": 1.3, "range": 5.5, "cd": 6.0, "mana": 15.0,
		"desc": "Charge toward the cursor, bashing every enemy in your path."},
	"s3": {"id": "rally", "name": "Rallying Cry", "type": "buff", "heal": 0.25, "dmg_buff": 0.3, "duration": 6.0, "cd": 16.0, "mana": 20.0,
		"desc": "Restore 25% HP and gain 30% damage for 6s."},
}

const SPECS := {
	"paladin": {
		"name": "Paladin", "color": "ffd76a", "fx": ["fff3b0", "ffc94a"],
		"tagline": "Holy warrior of the dawn. Sustain and radiant burst.",
		"passive": {"name": "Oathbound", "desc": "Each hit heals you for 1% of max HP.", "heal_on_hit": 0.01},
		"skill": {"id": "hammer", "name": "Hammer of Dawn", "type": "ground", "dmg": 3.2, "radius": 2.4, "delay": 0.45, "cd": 7.0, "mana": 28.0,
			"desc": "Call down a radiant hammer at the cursor."},
		"advanced": [
			{"id": "pal_a", "name": "Crusader", "desc": "(Placeholder) Hammer of Dawn deals +40% damage.", "mods": {"spec_dmg": 0.4}},
			{"id": "pal_b", "name": "Lightwarden", "desc": "(Placeholder) +25% max HP. Rallying Cry heals for 40%.", "mods": {"hp": 0.25, "rally_heal": 0.15}},
		],
	},
	"deathknight": {
		"name": "Death Knight", "color": "7ff0d0", "fx": ["c6fff0", "7a4dff"],
		"tagline": "Oathbreaker bound to the grave. Drains life from foes.",
		"passive": {"name": "Grave Hunger", "desc": "6% of damage dealt is returned as health.", "lifesteal": 0.06},
		"skill": {"id": "harvest", "name": "Soul Harvest", "type": "nova", "dmg": 2.2, "radius": 3.0, "heal_per_hit": 0.04, "cd": 8.0, "mana": 26.0,
			"desc": "Rip the souls from nearby enemies, healing 4% HP per enemy hit."},
		"advanced": [
			{"id": "dk_a", "name": "Reaper", "desc": "(Placeholder) Soul Harvest radius +40% and +30% damage.", "mods": {"spec_dmg": 0.3, "spec_radius": 0.4}},
			{"id": "dk_b", "name": "Dread Lord", "desc": "(Placeholder) Lifesteal doubled.", "mods": {"lifesteal_mult": 2.0}},
		],
	},
	"dragonknight": {
		"name": "Dragon Knight", "color": "ff9a4a", "fx": ["ffe2a0", "ff5a1f"],
		"tagline": "Wields the fury of dragons. Fire and lingering burns.",
		"passive": {"name": "Ember Blood", "desc": "Cleave sets enemies ablaze.", "cleave_burn": true},
		"skill": {"id": "breath", "name": "Dragonfire Breath", "type": "cone", "dmg": 2.4, "range": 5.0, "arc": 1.1, "burn": 0.6, "cd": 6.0, "mana": 25.0,
			"desc": "Breathe a cone of dragonfire that burns enemies over time."},
		"advanced": [
			{"id": "dra_a", "name": "Wyrmblade", "desc": "(Placeholder) Burns deal double damage.", "mods": {"burn_mult": 2.0}},
			{"id": "dra_b", "name": "Scaleguard", "desc": "(Placeholder) +40% armor and +15% max HP.", "mods": {"armor": 0.4, "hp": 0.15}},
		],
	},
}

const HEROIC := [
	{"id": "h_unyield", "name": "Unyielding Bastion", "desc": "(Placeholder) +30% max HP and +20% armor.", "mods": {"hp": 0.3, "armor": 0.2}},
	{"id": "h_warlord", "name": "Warlord's Fury", "desc": "(Placeholder) +25% damage, +10% crit chance.", "mods": {"dmg": 0.25, "crit": 0.1}},
	{"id": "h_swift", "name": "Tempest Blade", "desc": "(Placeholder) All cooldowns 30% faster.", "mods": {"cdr": 0.3}},
]

## Placeholder enemies (drawn in code until real art exists).
const ETYPES := {
	"slime": {"name": "Hollowling", "hp": 30.0, "dmg": 7.0, "speed": 2.0, "range": 1.0, "atk_cd": 1.4, "wind": 0.45, "rad": 0.35, "xp": 0.8, "h": 46.0},
	"revenant": {"name": "Veilbound Revenant", "hp": 46.0, "dmg": 10.0, "speed": 2.5, "range": 1.35, "atk_cd": 1.7, "wind": 0.5, "rad": 0.4, "xp": 1.15, "h": 96.0},
	# Ranged caster: keeps its distance ("keep"), charges a bolt ("wind"), then fires it ("bolt_speed" ground units/s).
	"caster": {"name": "Hexbound Gravecaller", "hp": 34.0, "dmg": 11.0, "speed": 2.1, "range": 6.0, "keep": 3.2, "atk_cd": 2.4, "wind": 0.75, "rad": 0.4, "xp": 1.3, "h": 96.0, "ranged": true, "bolt_speed": 7.0},
	# Boss of every fifth wave. Uses the Brute art, much larger and darkened ("tex", "tint").
	# Slams the ground where the knight stands ("slam_*"), calls Hollowlings at half life and enrages below "enrage".
	"warden": {"name": "The Unwritten Warden", "hp": 640.0, "dmg": 20.0, "speed": 1.6, "range": 1.9, "atk_cd": 2.6, "wind": 0.8, "rad": 0.9, "xp": 14.0, "h": 150.0,
		"boss": true, "tex": "brute", "tint": "8a7aa8", "slam_cd": 5.0, "slam_radius": 2.1, "slam_delay": 1.1, "slam_dmg": 1.3, "enrage": 0.35},
	# Armoured skeleton swordsman (wave 3+) and a fast antlered charger (wave 4+), both animated from Higgsfield clips.
	"skeleton": {"name": "Dread Legionnaire", "hp": 62.0, "dmg": 12.0, "speed": 2.2, "range": 1.4, "atk_cd": 1.8, "wind": 0.55, "rad": 0.42, "xp": 1.35, "h": 96.0},
	"stag": {"name": "Root-bone Stag", "hp": 72.0, "dmg": 14.0, "speed": 3.3, "range": 1.5, "atk_cd": 2.2, "wind": 0.6, "rad": 0.55, "xp": 1.5, "h": 96.0},
	"brute": {"name": "Thornhide Brute", "hp": 95.0, "dmg": 16.0, "speed": 1.7, "range": 1.6, "atk_cd": 2.3, "wind": 0.7, "rad": 0.6, "xp": 2.0, "h": 92.0},
}
const ELITE_PREFIX := ["Vile", "Dread", "Blighted", "Ancient", "Frenzied", "Gloomborn"]

## Elite affixes, Diablo-style. Elites roll one; from level 15 they roll two.
## Numbers are tuned here; the behaviour lives in enemy.gd.
const ELITE_AFFIXES := {
	"swift": {"name": "Swift", "color": "9fe0ff", "desc": "Moves and attacks much faster.", "speed": 1.45, "attack": 0.7},
	"shielded": {"name": "Shielded", "color": "e6e0ff", "desc": "Raises a ward that blocks all damage for a few seconds.", "every": 7.0, "lasts": 2.2},
	"molten": {"name": "Molten", "color": "ff8a3a", "desc": "Explodes when it dies. Step out of the ring.", "radius": 2.0, "delay": 1.3, "dmg": 1.6},
	"summoner": {"name": "Summoner", "color": "c9a8ff", "desc": "Calls Hollowlings to its side when wounded.", "at": [0.6, 0.25], "count": 2},
}
const ELITE_TWO_AFFIX_LEVEL := 15
## Every this-many waves the Reality Scar sends a boss.
const BOSS_EVERY := 5

const RARITY := [
	{"name": "Common", "color": "e4e0d6", "mult": 1.0},
	{"name": "Magic", "color": "6fa8ff", "mult": 1.25},
	{"name": "Rare", "color": "ffe066", "mult": 1.55},
	{"name": "Legendary", "color": "ff9a2e", "mult": 2.0},
]
## Item types that can drop. Weapons and chest armor are listed twice so they drop a little more often.
const ITEM_TYPES := ["weapon", "weapon", "armor", "armor", "helm", "offhand", "gloves", "belt", "boots", "ring", "amulet"]
const ITEM_BASES := {
	"offhand": ["Kite Shield", "Heater Shield", "Tower Shield"],
	"gloves": ["Gauntlets", "Mail Gloves", "Vambraces"],
	"belt": ["War Belt", "Girdle", "Sash"],
	"boots": ["Greaves", "Sabatons", "Riding Boots"],
	"ring": ["Band", "Signet", "Loop"],
	"weapon": ["Longsword", "Arming Sword", "Bastard Sword", "War Axe", "Flanged Mace"],
	"armor": ["Chainmail", "Brigandine", "Plate Cuirass"],
	"helm": ["Barbute", "Sallet", "Great Helm"],
	"amulet": ["Pendant", "Talisman", "Sigil"],
}
## Painted portrait for each item base (files in assets/items/painted/, from the
## art/item_taxonomy library). Bases not listed use the slot's default below.
const ITEM_ART := {
	"Longsword": "one_hand_melee_sword", "Arming Sword": "one_hand_melee_sword", "Bastard Sword": "one_hand_melee_sword",
	"Greatsword": "one_hand_melee_sword", "War Axe": "one_hand_melee_axe", "Flanged Mace": "one_hand_melee_mace",
	"Kite Shield": "off_hand_kite_shield", "Heater Shield": "off_hand_shield", "Tower Shield": "off_hand_tower_shield",
	"Great Helm": "armor_plate_plate_head", "Barbute": "armor_mail_mail_head", "Sallet": "armor_leather_leather_head",
	"Plate Cuirass": "armor_plate_plate_chest", "Chainmail": "armor_mail_mail_chest", "Brigandine": "armor_leather_leather_chest",
	"Gauntlets": "armor_plate_plate_gloves", "Mail Gloves": "armor_mail_mail_gloves", "Vambraces": "armor_leather_leather_gloves",
	"War Belt": "armor_plate_plate_belt", "Girdle": "armor_mail_mail_belt", "Sash": "armor_cloth_cloth_belt",
	"Greaves": "armor_plate_plate_boots", "Sabatons": "armor_mail_mail_boots", "Riding Boots": "armor_leather_leather_boots",
}
const SLOT_ART := {
	"weapon": "one_hand_melee_sword", "offhand": "off_hand_kite_shield", "helm": "armor_plate_plate_head",
	"armor": "armor_plate_plate_chest", "gloves": "armor_plate_plate_gloves", "belt": "armor_plate_plate_belt",
	"boots": "armor_plate_plate_boots", "ring": "jewelry_ring", "amulet": "jewelry_amulet",
}


## The item's base type ("Chainmail", "Kite Shield"...). Older saves have no "base",
## so it is read back from the name where possible.
static func item_base(it: Dictionary) -> String:
	if it.has("base"):
		return String(it["base"])
	var n := String(it.get("name", ""))
	for b in ITEM_BASES.get(String(it.get("slot", "")), []):
		if n.ends_with(String(b)):
			return String(b)
	return ""


## Id of the painted portrait for an item.
static func item_art(it: Dictionary) -> String:
	return String(ITEM_ART.get(item_base(it), SLOT_ART.get(String(it.get("slot", "")), "")))


const ITEM_PREFIX := ["Gilded", "Valorous", "Dawnforged", "Grim", "Wyrmscale", "Hallowed", "Stalwart", "Ashen", "Sunlit", "Oathsworn"]
const ITEM_LEGEND := {
	"offhand": ["Bulwark of the First Anchor", "Dawnwall"],
	"gloves": ["Hands of the Remnant Court"],
	"belt": ["Girdle of Names"],
	"boots": ["Wayfarer's Stride"],
	"ring": ["Band of Continuance", "Ring of the Unwritten"],
	"weapon": ["Oathkeeper", "Crown's Edge", "Emberfang"],
	"armor": ["Aegis of Crownsfall", "Wyrmplate"],
	"helm": ["Crown of Vigil", "Gravewarden Helm"],
	"amulet": ["Heart of the Dawn", "Sigil of the Last Oath"],
}


## A plain level-1 item of a given type, used for a new character's starting kit.
static func starter_item(slot: String, name: String, stats: Dictionary) -> Dictionary:
	var it := {"slot": slot, "rarity": 0, "level": 1, "dmg": 0.0, "armor": 0.0, "hp": 0.0, "crit": 0.0, "name": name}
	for k in stats:
		it[k] = stats[k]
	return it


# ---------------------------------------------------------------- Lorecasting
## Lost memories the player can Lorecast. "pos" is where it lingers in the plaza
## (painting pixels); entries without "pos" appear elsewhere (an elite's echo).
const LORE := {
	"veiled_lady": {
		"title": "The Veiled Lady",
		"pos": Vector2(1560, 830),
		"text": "For an instant the fountain runs the wrong way. The statue's hands are not folded in prayer but raised, holding a crown nobody remembers carving, and the plaque beneath her bears a name in letters no scholar in Crownsfall can read.\n\nThen the water falls again, and her hands are folded, as they always were.",
	},
	"worn_steps": {
		"title": "The Worn Steps",
		"pos": Vector2(1010, 430),
		"text": "The stairs are worn hollow in the middle, as old stone is. But the city's records say these steps were laid within living memory, and the hollows are a thousand years deep.\n\nFor a breath you hear a procession climbing them, singing in a language that ended before Crownsfall began.",
	},
	"blank_notice": {
		"title": "Notice From No Year",
		"pos": Vector2(1880, 1290),
		"text": "Among the bounties pinned to the board is a notice you are sure was not there a moment ago: a reward for any word of a royal guard, last seen descending beneath the cathedral. It is dated in a calendar no one in Crownsfall uses.\n\nWhen you look again, the paper is blank.",
	},
	"sleeping_saint": {
		"title": "The Sleeping Saint",
		"pos": Vector2(1530, 710),
		"zone": "whisperwood",
		"text": "The fallen statue is the same woman who stands veiled in the Crownsfall fountain, carved by the same hand. Here she lies on her back with her eyes open, and the moss has grown everywhere except the crown on her brow.\n\nSomeone has been cleaning it. The cloth is still damp.",
	},
	"echo_elite": {
		"title": "Echo of the Fallen",
		"text": "Ash and violet light gather where it fell. For a heartbeat you see a soldier in polished armour, laughing with someone just out of sight, a doorway with blue shutters, a child's hand.\n\nThen only the Scar, and the sense of something that wanted, very badly, to go home.",
	},
}
## Experience for each memory uncovered, as a share of the current level's requirement.
const LORE_XP := 0.3


static func xp_need(level: int) -> int:
	return int(floor(60.0 * pow(float(level), 1.6)))


## Ground offset (in units) from one painting position to another.
static func ground(from: Vector2, to: Vector2) -> Vector2:
	return Vector2(to.x - from.x, (to.y - from.y) / SQ) / U


static func gdist(a: Vector2, b: Vector2) -> float:
	return ground(a, b).length()


## Converts a ground vector in units into a painting pixel offset.
static func to_px(g: Vector2) -> Vector2:
	return Vector2(g.x, g.y * SQ) * U


static func make_item(level: int, boost: float = 0.0) -> Dictionary:
	var roll: float = randf() + boost
	var ri: int = 3 if roll > 0.965 else (2 if roll > 0.83 else (1 if roll > 0.55 else 0))
	var slot: String = ITEM_TYPES[randi() % ITEM_TYPES.size()]
	var v: float = randf_range(0.85, 1.15) * float(RARITY[ri]["mult"])
	var it := {"slot": slot, "rarity": ri, "level": level, "dmg": 0.0, "armor": 0.0, "hp": 0.0, "crit": 0.0}
	for a in ATTRS:
		it[a] = 0.0
	match slot:
		"weapon":
			it["dmg"] = round((3.0 + level * 1.6) * v)
		"armor":
			it["armor"] = round((8.0 + level * 3.0) * v)
			it["hp"] = round(level * 2.0 * v)
		"helm":
			it["armor"] = round((4.0 + level * 1.5) * v)
			it["hp"] = round(level * 1.5 * v)
		"amulet":
			it["crit"] = snappedf(0.02 * v, 0.001)
			it["hp"] = round(level * 3.0 * v)
		"offhand":
			it["armor"] = round((6.0 + level * 2.2) * v)
		"gloves":
			it["armor"] = round((2.0 + level * 0.8) * v)
			it["dmg"] = round((1.0 + level * 0.4) * v)
		"belt":
			it["armor"] = round((2.0 + level * 0.6) * v)
			it["hp"] = round((4.0 + level * 2.5) * v)
		"boots":
			it["armor"] = round((3.0 + level * 1.0) * v)
			it["hp"] = round(level * 1.2 * v)
		"ring":
			it["crit"] = snappedf(0.012 * v, 0.001)
			it["dmg"] = round((1.0 + level * 0.3) * v)
	var pool: Array = (AFFIX_POOL.get(slot, ATTRS) as Array).duplicate()
	pool.shuffle()
	for i in mini(int(AFFIX_COUNT[ri]), pool.size()):
		it[pool[i]] = float(roundi((randf_range(1.0, 2.0) + level * 0.35 * randf_range(0.8, 1.2)) * (1.0 + 0.15 * ri)))
	var pool2: Array = (SECONDARY_POOL.get(slot, []) as Array).duplicate()
	pool2.shuffle()
	for i in mini(int(SECONDARY_COUNT[ri]), pool2.size()):
		var a2: Dictionary = SECONDARY[pool2[i]]
		var val := randf_range(float(a2["min"]), float(a2["max"]))
		if a2["pct"]:
			it[pool2[i]] = snappedf(val, 0.01)
		else:
			it[pool2[i]] = float(roundi(val + level * float(a2.get("per_level", 0.0))))
	var bases: Array = ITEM_BASES[slot]
	var base: String = bases[randi() % bases.size()]
	it["base"] = base
	if ri == 3:
		var legends: Array = ITEM_LEGEND[slot]
		it["name"] = legends[randi() % legends.size()]
	elif ri >= 1:
		it["name"] = "%s %s" % [ITEM_PREFIX[randi() % ITEM_PREFIX.size()], base]
	else:
		it["name"] = base
	return it


static func item_score(it) -> float:
	if it == null:
		return 0.0
	return float(it.get("dmg", 0.0)) * 3.0 + float(it.get("armor", 0.0)) * 0.6 + float(it.get("hp", 0.0)) * 0.35 + float(it.get("crit", 0.0)) * 400.0


static func item_line(it: Dictionary) -> String:
	var parts: Array[String] = []
	for a in ATTRS:
		if float(it.get(a, 0.0)) > 0.0:
			parts.append("+%d %s" % [int(it[a]), ATTR_NAME[a]])
	if float(it.get("dmg", 0.0)) > 0.0:
		parts.append("+%d damage" % int(it["dmg"]))
	if float(it.get("armor", 0.0)) > 0.0:
		parts.append("+%d armor" % int(it["armor"]))
	if float(it.get("hp", 0.0)) > 0.0:
		parts.append("+%d life" % int(it["hp"]))
	if float(it.get("crit", 0.0)) > 0.0:
		parts.append("+%.1f%% crit" % (float(it["crit"]) * 100.0))
	for k in SECONDARY:
		var v := float(it.get(k, 0.0))
		if v > 0.0:
			parts.append(("+%d%% " % roundi(v * 100.0) if SECONDARY[k]["pct"] else "+%d " % int(v)) + String(SECONDARY[k]["name"]))
	return ", ".join(parts)
