extends RefCounted
## Source table for tools/build_class_resources.gd (runtime reads data/classes/*.tres). Hero skills for the playable game (owner 11-27 "make the character you play the most complete"): six skills per
## class, unlocked by level, ranked 1-5 with skill points (one per level), and a choice of one of two upgrades at
## rank 3. Each skill plays one of the hero's existing animations ("anim") and its effect is resolved by the game
## director in the shape given here (arc, line, circle at self, circle at the cursor, dash, blink, buff, ward).
## Names, icons and numbers come from the original Crownsfall design (scripts/game_data.gd, skill tiles).

const MAX_RANK := 5
const MOD_RANK := 3
const RANK_DMG := 0.14            # +14% damage per rank above 1

const DEFS := {
	"warrior": [
		{"id": "slash", "name": "Slash", "icon": "slash", "unlock": 1, "anim": "Slash", "shape": "arc", "dmg": 1.0, "range": 2.3, "arc": 0.25, "cost": 0.0, "cd": 0.0, "gain": 4.0, "basic": true,
			"desc": "A swift sword strike. Restores 4 mana on hit.",
			"mods": [{"id": "rend", "name": "Rending Edge", "desc": "Hits make enemies bleed for 45% of the hit over 3 s.", "burn": 0.45},
					 {"id": "riposte", "name": "Riposte", "desc": "Restores 9 mana on hit instead of 4.", "gain": 9.0}]},
		{"id": "cleave", "name": "Cleave", "icon": "cleave", "unlock": 1, "anim": "Cleave", "shape": "arc", "dmg": 1.55, "range": 3.4, "arc": -0.3, "cost": 12.0, "cd": 2.5,
			"desc": "A sweeping blow that strikes every enemy in front of you.",
			"mods": [{"id": "wide", "name": "Great Arc", "desc": "Strikes all around you and reaches further.", "arc": -1.0, "range": 3.9},
					 {"id": "stagger", "name": "Staggering Blow", "desc": "Knocks enemies back and stuns them for 0.6 s.", "stun": 0.6, "knock": 1.6}]},
		{"id": "charge", "name": "Shield Charge", "icon": "charge", "unlock": 3, "anim": "Dash", "shape": "dash", "dmg": 1.3, "range": 6.0, "width": 1.4, "cost": 15.0, "cd": 6.0, "stun": 0.5, "knock": 1.2,
			"desc": "Charge toward the cursor, bashing and stunning every enemy in your path.",
			"mods": [{"id": "relentless", "name": "Relentless", "desc": "Cooldown reduced to 3.5 s.", "cd": 3.5},
					 {"id": "shockwave", "name": "Shockwave", "desc": "Ends in a shockwave that hits everything within 2.5 m.", "end_radius": 2.5}]},
		{"id": "rally", "name": "Rallying Cry", "icon": "rally", "unlock": 5, "anim": "Cast", "shape": "buff", "cost": 20.0, "cd": 16.0, "heal": 0.25, "buff_dmg": 0.3, "duration": 6.0,
			"desc": "Restore 25% life and gain 30% damage for 6 s.",
			"mods": [{"id": "second_wind", "name": "Second Wind", "desc": "Restores 40% life instead.", "heal": 0.4},
					 {"id": "iron_will", "name": "Iron Will", "desc": "Also take 30% less damage while it lasts.", "buff_def": 0.3}]},
		{"id": "hammer", "name": "Sundering Standard", "icon": "hammer", "unlock": 8, "anim": "Slash", "shape": "ground", "dmg": 3.0, "radius": 2.4, "delay": 0.45, "reach": 7.0, "cost": 26.0, "cd": 7.0,
			"desc": "A delayed standard strike at the cursor that crushes everything in the circle.",
			"mods": [{"id": "broad", "name": "Broad Standard", "desc": "Radius increased by 40%.", "radius": 3.4},
					 {"id": "quake", "name": "Quake", "desc": "Stuns everything hit for 1 s.", "stun": 1.0}]},
		{"id": "reprisal", "name": "Citadel Reprisal", "icon": "harvest", "unlock": 12, "anim": "Cleave", "shape": "nova", "dmg": 2.1, "radius": 3.0, "cost": 26.0, "cd": 8.0, "heal_hit": 0.04,
			"desc": "Repel everything around you and recover 4% life per enemy hit.",
			"mods": [{"id": "bulwark", "name": "Bulwark", "desc": "Recover 7% life per enemy hit.", "heal_hit": 0.07},
					 {"id": "repel", "name": "Repel", "desc": "Hurls enemies away and stuns them for 1 s.", "knock": 3.0, "stun": 1.0}]},
	],
	"mage": [
		{"id": "cinder_thread", "name": "Cinder Thread", "icon": "cinder_thread", "unlock": 1, "anim": "Bolt", "shape": "line", "dmg": 1.05, "range": 8.0, "width": 0.9, "pierce": 1, "cost": 0.0, "cd": 0.0, "gain": 3.0, "basic": true,
			"desc": "A narrow fire projectile. Restores 3 mana when it hits.",
			"mods": [{"id": "kindle", "name": "Kindle", "desc": "Sets enemies on fire for 60% of the hit over 3 s.", "burn": 0.6},
					 {"id": "siphon", "name": "Siphon", "desc": "Restores 7 mana on hit instead of 3.", "gain": 7.0}]},
		{"id": "glacial_stitch", "name": "Glacial Stitch", "icon": "glacial_stitch", "unlock": 1, "anim": "Lance", "shape": "line", "dmg": 1.3, "range": 8.0, "width": 1.1, "pierce": 3, "cost": 14.0, "cd": 4.0, "slow": 0.3, "slow_t": 2.0,
			"desc": "Pierces up to 3 enemies and slows them by 30% for 2 s.",
			"mods": [{"id": "shatter", "name": "Shatterline", "desc": "Pierces every enemy in the line and freezes them for 0.8 s.", "pierce": 99, "stun": 0.8},
					 {"id": "deep_cold", "name": "Deep Cold", "desc": "Slows by 60% for 3 s.", "slow": 0.6, "slow_t": 3.0}]},
		{"id": "arcane_fold", "name": "Arcane Fold", "icon": "arcane_fold", "unlock": 3, "anim": "", "shape": "blink", "range": 7.0, "cost": 16.0, "cd": 8.0,
			"desc": "Blink up to 7 m to the cursor onto open ground.",
			"mods": [{"id": "fold_frost", "name": "Frost Wake", "desc": "Leaves a burst of cold where you were: 1.2x damage and 50% slow.", "dmg": 1.2, "radius": 2.5, "slow": 0.5, "slow_t": 2.0},
					 {"id": "fold_quick", "name": "Quickened Fold", "desc": "Cooldown reduced to 4.5 s.", "cd": 4.5}]},
		{"id": "ashen_ward", "name": "Ashen Ward", "icon": "ashen_ward", "unlock": 5, "anim": "Nova", "shape": "ward", "cost": 20.0, "cd": 12.0, "ward": 0.3, "duration": 4.0,
			"desc": "Absorb damage equal to 30% of your life for 4 s.",
			"mods": [{"id": "thick_ash", "name": "Thick Ash", "desc": "Absorbs 50% of your life instead.", "ward": 0.5},
					 {"id": "ember_burst", "name": "Ember Burst", "desc": "When the ward ends or breaks it bursts for 1.6x damage around you.", "burst": 1.6, "radius": 3.0}]},
		{"id": "starfall_script", "name": "Starfall Script", "icon": "starfall_script", "unlock": 8, "anim": "Judgment", "shape": "ground", "dmg": 2.6, "radius": 2.3, "delay": 0.8, "reach": 9.0, "cost": 24.0, "cd": 6.0,
			"desc": "Mark a circle at the cursor that strikes after 0.8 s.",
			"mods": [{"id": "wide_sky", "name": "Wide Sky", "desc": "Radius increased by 40%.", "radius": 3.2},
					 {"id": "scorch", "name": "Scorching Fall", "desc": "Burns everything hit for 80% of the hit over 3 s.", "burn": 0.8}]},
		{"id": "winter_crown", "name": "Winter Crown", "icon": "winter_crown", "unlock": 12, "anim": "Nova", "shape": "nova", "dmg": 2.0, "radius": 3.2, "cost": 26.0, "cd": 9.0, "stun": 1.0,
			"desc": "A freezing nova that stuns everything around you for 1 s.",
			"mods": [{"id": "crown_wide", "name": "Sovereign's Reach", "desc": "Radius increased by 30%.", "radius": 4.2},
					 {"id": "crown_hold", "name": "Long Winter", "desc": "Stuns for 1.8 s.", "stun": 1.8}]},
	],
}

static func defs(class_id: String) -> Array:
	return DEFS.get(class_id, DEFS["warrior"])

static func def(class_id: String, id: String) -> Dictionary:
	for d in defs(class_id):
		if d["id"] == id: return d
	return {}

## The skill's numbers with its chosen upgrade folded in (upgrade values replace the base ones).
static func resolved(class_id: String, id: String, mod_id: String) -> Dictionary:
	var d: Dictionary = def(class_id, id).duplicate(true)
	for m in d.get("mods", []):
		if m["id"] == mod_id:
			for k in m:
				if not k in ["id", "name", "desc"]: d[k] = m[k]
	return d

static func damage_mult(rank: int) -> float:
	return 1.0 + RANK_DMG * float(maxi(0, rank - 1))
