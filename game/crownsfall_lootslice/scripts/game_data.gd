extends RefCounted
## Shared game data: classes, specializations, enemies and items.
## Everything here is work in progress and meant to be edited freely.
##
## Warrior systems branch: specialization at 20, heroic identity at 40. Other classes are specified in data/class_roster.json.
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

const SPEC_LEVEL := 20
const ADVANCED_LEVEL := 40
const MAX_LEVEL := 60

const CLASSES := {
	"warrior": {"name": "Warrior", "armor": "Plate", "desc": "Measured sword strikes, sweeping control and an active rally.", "starting": ["slash", "cleave", "charge", "rally", ""], "paths": "Weaponmaster → Bladestorm Paragon / Bastion Guard → Citadel Sentinel / Berserker → Bloodbound Warlord"},
	"mage": {"name": "Mage", "armor": "Cloth", "desc": "Ranged fire and frost, arcane repositioning and a timed protective ward.", "starting": ["cinder_thread", "glacial_stitch", "arcane_fold", "ashen_ward", "starfall_script"], "paths": "Fire → Pyromancer / Frost → Glacial Sovereign / Arcane → Chronomancer"},
}
const MAGE_BASE := {
	"cinder_thread": {"id": "cinder_thread", "name": "Cinder Thread", "class": "mage", "type": "projectile", "scaling": "spell", "school": "fire", "color": "ffad64", "dmg": 1.05, "range": 8.0, "speed": 12.0, "cd": 0.7, "mana": 0.0, "gain_on_hit": 3.0, "cast_time": 0.16, "recovery": 0.28, "desc": "A narrow fire projectile. Restore 3 mana when it hits a living enemy."},
	"glacial_stitch": {"id": "glacial_stitch", "name": "Glacial Stitch", "class": "mage", "type": "projectile", "scaling": "spell", "school": "frost", "color": "8fe9ff", "dmg": 1.3, "range": 7.0, "speed": 11.0, "pierce": 3, "slow": 0.3, "slow_duration": 2.0, "cd": 5.0, "mana": 14.0, "cast_time": 0.25, "recovery": 0.38, "desc": "Pierce up to 3 enemies and slow 30% for 2s. Two hits within 6s freeze briefly; elites resist the duration."},
	"arcane_fold": {"id": "arcane_fold", "name": "Arcane Fold", "class": "mage", "type": "blink", "scaling": "spell", "school": "arcane", "range": 4.0, "cd": 8.0, "mana": 16.0, "recovery": 0.12, "desc": "Blink up to 4 ground units onto valid floor. Invalid destinations do not spend mana or cooldown."},
	"ashen_ward": {"id": "ashen_ward", "name": "Ashen Ward", "class": "mage", "type": "ward", "scaling": "spell", "school": "fire", "hp_fraction": 0.2, "ward_power": 2.0, "duration": 3.0, "cd": 12.0, "mana": 20.0, "recovery": 0.15, "desc": "Absorb incoming damage for 3s. This active ward does not heal or stack with itself."},
	"starfall_script": {"id": "starfall_script", "name": "Starfall Script", "class": "mage", "type": "ground", "scaling": "spell", "school": "arcane", "color": "c3a9ff", "dmg": 2.4, "range": 7.0, "radius": 2.3, "delay": 0.8, "cd": 7.0, "mana": 24.0, "cast_time": 0.3, "recovery": 0.45, "desc": "Cast for 0.3s, then mark a circle that strikes after another 0.8s. Damage snapshots on activation."},
}
const BASE := {
	"basic": {"id": "slash", "name": "Slash", "type": "melee", "dmg": 1.0, "range": 1.5, "arc": 1.6, "cd": 0.55, "mana": 0.0, "gain_on_hit": 4.0, "class": "warrior",
		"desc": "A swift sword strike. Restores 4 mana on the first successful hit."},
	"s1": {"id": "cleave", "class": "warrior", "name": "Cleave", "type": "arc", "dmg": 1.6, "range": 2.3, "arc": 2.6, "cd": 2.5, "mana": 12.0,
		"desc": "A sweeping blow that strikes all enemies in front of you."},
	"s2": {"id": "charge", "class": "warrior", "name": "Shield Charge", "type": "dash", "dmg": 1.3, "range": 5.5, "cd": 6.0, "mana": 15.0,
		"desc": "Charge toward the cursor, bashing every enemy in your path."},
	"s3": {"id": "rally", "class": "warrior", "name": "Rallying Cry", "type": "buff", "heal": 0.25, "dmg_buff": 0.3, "duration": 6.0, "cd": 16.0, "mana": 20.0,
		"desc": "Restore 25% HP and gain 30% damage for 6s."},
}

const SPECS := {
	"weaponmaster": {"class": "warrior", "name": "Weaponmaster", "color": "90c9ff", "fx": ["e9f6ff", "84bfff"], "tagline": "Control space with sweeping weapon techniques.", "passive": {"name": "None", "desc": "Identity comes from chosen abilities and equipment."},
		"skill": {"id": "hammer", "name": "Sundering Standard", "type": "ground", "dmg": 3.2, "radius": 2.4, "delay": 0.45, "cd": 7.0, "mana": 28.0, "level": 20, "desc": "A delayed standard strike at the cursor."},
		"advanced": [{"id": "bladestorm_paragon", "name": "Bladestorm Paragon", "desc": "Chosen training: +20% specialization damage.", "mods": {"spec_dmg": 0.2}}]},
	"bastion_guard": {"class": "warrior", "name": "Bastion Guard", "color": "ffd76a", "fx": ["fff3b0", "ffc94a"], "tagline": "Stand firm and recover through deliberate active defenses.", "passive": {"name": "None", "desc": "No automatic heal-on-hit passive."},
		"skill": {"id": "harvest", "name": "Citadel Reprisal", "type": "nova", "dmg": 2.2, "radius": 3.0, "heal_per_hit": 0.04, "cd": 8.0, "mana": 26.0, "level": 20, "desc": "Repel enemies and recover 4% life per target hit."},
		"advanced": [{"id": "citadel_sentinel", "name": "Citadel Sentinel", "desc": "Chosen training: +20% armor and +10% maximum life.", "mods": {"armor": 0.2, "hp": 0.1}}]},
	"berserker": {"class": "warrior", "name": "Berserker", "color": "ff9a4a", "fx": ["ffe2a0", "ff5a1f"], "tagline": "Commit to brutal attacks and an active burning technique.", "passive": {"name": "None", "desc": "Burn applies only when the selected technique hits."},
		"skill": {"id": "breath", "name": "Furnace Sweep", "type": "cone", "dmg": 2.4, "range": 5.0, "arc": 1.1, "burn": 0.6, "cd": 6.0, "mana": 25.0, "level": 20, "desc": "Sweep a fiery cone; burn for three seconds."},
		"advanced": [{"id": "bloodbound_warlord", "name": "Bloodbound Warlord", "desc": "Chosen training: burn damage doubled.", "mods": {"burn_mult": 2.0}}]},
	"mage_fire": {"class": "mage", "name": "Fire", "color": "ffad64", "fx": ["fff2be", "ff8f54"], "tagline": "Control space with an actively cast burning wave.",
		"skill": {"id": "solar_writ", "class": "mage", "name": "Solar Writ", "type": "cone", "scaling": "spell", "school": "fire", "dmg": 2.0, "burn": 1.2, "range": 5.0, "arc": 1.3, "cd": 8.0, "mana": 26.0, "level": 20, "cast_time": 0.25, "recovery": 0.4, "desc": "A committed fire wave leaves a 3s burn. Direct damage and burn use the same spell-power snapshot."},
		"advanced": [{"id": "pyromancer", "name": "Pyromancer", "desc": "Chosen training: +20% spell power.", "mods": {"spell_dmg": 0.2}}]},
	"mage_frost": {"class": "mage", "name": "Frost", "color": "8fe9ff", "fx": ["e2fbff", "78d7ff"], "tagline": "Hold ground with a deliberate freezing nova.",
		"skill": {"id": "winter_crown", "class": "mage", "name": "Winter Crown", "type": "nova", "scaling": "spell", "school": "frost", "dmg": 2.0, "radius": 3.2, "stun": 1.0, "cd": 9.0, "mana": 26.0, "level": 20, "cast_time": 0.25, "recovery": 0.4, "desc": "A freezing nova stuns for 1s. Elite control duration is halved."},
		"advanced": [{"id": "glacial_sovereign", "name": "Glacial Sovereign", "desc": "Chosen training: +30% specialization radius.", "mods": {"spec_radius": 0.3}}]},
	"mage_arcane": {"class": "mage", "name": "Arcane", "color": "c3a9ff", "fx": ["eee2ff", "ad86ff"], "tagline": "Align precise casts and control their timing.",
		"skill": {"id": "epoch_lance", "class": "mage", "name": "Epoch Lance", "type": "projectile", "scaling": "spell", "school": "arcane", "color": "c3a9ff", "dmg": 3.2, "range": 9.0, "speed": 14.0, "pierce": 3, "cd": 8.0, "mana": 28.0, "level": 20, "cast_time": 0.35, "recovery": 0.5, "desc": "A precise arcane lance pierces up to 3 enemies; each takes one hit."},
		"advanced": [{"id": "chronomancer", "name": "Chronomancer", "desc": "Chosen training: all ability cooldowns reduced by 20%, independent of hotbar slot.", "mods": {"cdr": 0.2}}]},
}
const HEROIC := [] # Per-skill heroic trees remain a design task; no level-60 forced passive.
const EXTRA_SKILLS := {
	"echo_strike": {"id": "echo_strike", "scaling": "spell", "school": "arcane", "name": "Echo Strike", "type": "ground", "dmg": 2.1, "radius": 1.8, "delay": 0.6, "cd": 5.0, "mana": 16.0, "level": 1, "discovery": "first_echo", "desc": "A recovered memory strikes after 0.6s. Reach: 7 ground units."},
	"frost_ring": {"id": "frost_ring", "scaling": "spell", "school": "frost", "name": "Winterglass Pulse", "type": "nova", "dmg": 1.5, "radius": 2.8, "cd": 8.0, "mana": 18.0, "level": 4, "stun": 1.2, "desc": "A cold pulse stuns nearby enemies for 1.2s."},
	"ember_cone": {"id": "ember_cone", "scaling": "spell", "school": "fire", "name": "Cinderwake", "type": "cone", "dmg": 1.8, "range": 4.5, "arc": 1.2, "burn": 0.5, "cd": 5.0, "mana": 18.0, "level": 6, "desc": "A Lorecasting training technique: scorch a cone and burn for 3s."},
	"dawnfall": {"id": "dawnfall", "scaling": "spell", "school": "radiant", "name": "Dawnfall", "type": "ground", "dmg": 3.0, "radius": 2.5, "delay": 0.8, "cd": 12.0, "mana": 30.0, "level": 10, "desc": "A large delayed radiant strike at the cursor. Reach: 7 units."},
}

static func spells() -> Dictionary:
	var result := EXTRA_SKILLS.duplicate(true)
	result.merge(MAGE_BASE)
	for sk in BASE.values(): result[sk.id] = sk
	for sp in SPECS.values():
		var sk: Dictionary = sp.skill.duplicate(true)
		sk["class"] = sp["class"]
		result[sk.id] = sk
	return result

static func unlocked(player: Node, id: String) -> bool:
	var sk: Dictionary = spells().get(id, {})
	if sk.is_empty() or player.level < int(sk.get("level", 1)): return false
	if sk.has("class") and sk["class"] != player.class_id: return false
	if sk.has("discovery") and not player.discoveries.has(sk.discovery): return false
	for key in SPECS:
		if SPECS[key].skill.id == id: return player.spec == key and SPECS[key]["class"] == player.class_id
	return true

## Enemy templates. Painted still sprites are animated procedurally by enemy.gd.
const ETYPES := {
	"slime": {"name": "Hollowling", "hp": 30.0, "dmg": 7.0, "speed": 2.0, "range": 1.0, "atk_cd": 1.4, "wind": 0.45, "rad": 0.35, "xp": 0.8, "h": 46.0},
	"revenant": {"name": "Veilbound Revenant", "hp": 46.0, "dmg": 10.0, "speed": 2.5, "range": 1.35, "atk_cd": 1.7, "wind": 0.5, "rad": 0.4, "xp": 1.15, "h": 96.0},
	"brute": {"name": "Thornhide Brute", "hp": 95.0, "dmg": 16.0, "speed": 1.7, "range": 1.6, "atk_cd": 2.3, "wind": 0.7, "rad": 0.6, "xp": 2.0, "h": 92.0},
}
const ELITE_PREFIX := ["Vile", "Dread", "Blighted", "Ancient", "Frenzied", "Gloomborn"]

const RARITY := [
	{"name": "Common", "color": "e4e0d6", "mult": 1.0},
	{"name": "Magic", "color": "6fa8ff", "mult": 1.25},
	{"name": "Rare", "color": "ffe066", "mult": 1.55},
	{"name": "Legendary", "color": "ff9a2e", "mult": 2.0},
]
static func visible_spells(class_id: String) -> Dictionary:
	var result := {}
	for id in spells():
		var sk: Dictionary = spells()[id]
		if not sk.has("class") or sk["class"] == class_id: result[id] = sk
	return result

static func specs_for(class_id: String) -> Dictionary:
	var result := {}
	for id in SPECS:
		if SPECS[id]["class"] == class_id: result[id] = SPECS[id]
	return result

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
	return preload("res://scripts/systems.gd").make_item(level, boost)


static func item_score(it) -> float:
	if it == null:
		return 0.0
	return float(it.get("dmg", 0.0)) * 3.0 + float(it.get("armor", 0.0)) * 0.6 + float(it.get("hp", 0.0)) * 0.35 + float(it.get("crit", 0.0)) * 400.0


static func item_line(it: Dictionary) -> String:
	var parts: Array[String] = []
	if float(it.get("dmg", 0.0)) > 0.0:
		parts.append("+%d damage" % int(it["dmg"]))
	if float(it.get("spell_power", 0.0)) > 0.0:
		parts.append("+%d spell power" % int(it["spell_power"]))
	if float(it.get("armor", 0.0)) > 0.0:
		parts.append("+%d armor" % int(it["armor"]))
	if float(it.get("hp", 0.0)) > 0.0:
		parts.append("+%d life" % int(it["hp"]))
	if float(it.get("crit", 0.0)) > 0.0:
		parts.append("+%.1f%% crit" % (float(it["crit"]) * 100.0))
	for key in preload("res://scripts/systems.gd").ATTRS:
		if float(it.get(key, 0)) > 0: parts.append("+%d %s" % [int(it[key]), key.capitalize()])
	return ", ".join(parts)
