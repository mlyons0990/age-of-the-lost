extends RefCounted
## Pure mastery transactions. Saved keys are stable node IDs, never slots.
const NODES := {
	"ward_temper": {"name":"Tempered Ward", "cost":1, "max_rank":3, "level":20, "requires":{}, "group":"", "desc":"Ward absorption +10% per rank. After transformation, ranks 2 and 3 each add 5% aura pulse damage."},
	"ember_aura": {"name":"Ember Aura", "cost":2, "max_rank":1, "level":40, "requires":{"ward_temper":1}, "group":"", "discovery":"first_echo", "desc":"Transform Ashen Ward into a paid toggle: 10 mana to start, 3 per 0.5s pulse, radius 2.5."},
	"cinder_bloom": {"name":"Cinder Bloom", "cost":2, "max_rank":1, "level":40, "requires":{"ember_aura":1}, "group":"ember_branch", "desc":"Aura radius +25%. A primary kill of a burning enemy leaves a non-stacking 1s cinder patch while aura runs."},
	"siphon_embers": {"name":"Siphon Embers", "cost":2, "max_rank":1, "level":40, "requires":{"ember_aura":1}, "group":"ember_branch", "desc":"Heal 2% of actual aura damage, capped at 3% max life in a rolling second. No overkill or secondary healing."},
	"steady_flame": {"name":"Steady Flame", "cost":1, "max_rank":2, "level":45, "requires":{"ember_aura":1}, "group":"", "desc":"Aura upkeep -5% per rank. Damage and pulse timing are unchanged."}}

static func earned(class_id: String, level: int) -> int:
	return maxi(0, int((mini(level, 60) - 15) / 5)) if class_id == "mage" else 0

static func spent(ranks: Dictionary) -> int:
	var total := 0
	for id in ranks:
		if NODES.has(id): total += int(ranks[id]) * int(NODES[id].cost)
	return total

static func problem(ranks: Variant, class_id: String, level: int, discoveries: Array) -> String:
	if not ranks is Dictionary: return "Mastery must be a node-rank dictionary."
	if class_id != "mage" and not ranks.is_empty(): return "Only Mage has this mastery graph."
	var groups := {}
	for id in ranks:
		if not NODES.has(id): return "Unknown mastery node."
		var rank: Variant = ranks[id]
		if not rank is float and not rank is int: return "Invalid mastery rank type."
		if not is_finite(float(rank)) or float(rank) != floor(float(rank)): return "Ranks must be whole numbers."
		var node: Dictionary = NODES[id]
		if rank < 1 or rank > node.max_rank: return "Rank is outside its allowed range."
		if level < node.level: return "Requires level %d." % int(node.level)
		if node.has("discovery") and not discoveries.has(node.discovery): return "Recover the plaza stone memory first."
		for prerequisite in node.requires:
			if float(ranks.get(prerequisite, 0)) < float(node.requires[prerequisite]): return "Missing prerequisite: " + String(NODES[prerequisite].name)
		var group: String = node.group
		if group != "":
			if groups.has(group): return "Cinder Bloom and Siphon Embers are mutually exclusive."
			groups[group] = id
	if spent(ranks) > earned(class_id, level): return "Not enough earned mastery points."
	return ""

static func invest(ranks: Dictionary, id: String, class_id: String, level: int, discoveries: Array) -> Dictionary:
	var error := problem(ranks, class_id, level, discoveries)
	if error != "": return {"ok":false,"reason":error}
	if not NODES.has(id): return {"ok":false,"reason":"Unknown mastery node."}
	var next := ranks.duplicate(true)
	next[id] = int(next.get(id, 0)) + 1
	error = problem(next, class_id, level, discoveries)
	return {"ok":error == "", "reason":error, "ranks":next}

static func refund(ranks: Dictionary, id: String) -> Dictionary:
	if not ranks.has(id): return {"ok":false,"reason":"This node has no investment."}
	var next := ranks.duplicate(true)
	next[id] = int(next[id]) - 1
	if next[id] <= 0: next.erase(id)
	var removed := true
	while removed:
		removed = false
		for node_id in next.keys():
			for prerequisite in NODES[node_id].requires:
				if int(next.get(prerequisite, 0)) < int(NODES[node_id].requires[prerequisite]):
					next.erase(node_id); removed = true; break
	return {"ok":true,"reason":"","ranks":next,"refunded":spent(ranks)-spent(next)}

static func definition(base: Dictionary, ranks: Dictionary, circlet := false) -> Dictionary:
	var skill := base.duplicate(true)
	if skill.get("id", "") != "ashen_ward": return skill
	var ward_scale := 1 + 0.1 * int(ranks.get("ward_temper", 0))
	skill.hp_fraction = float(skill.get("hp_fraction", 0.2)) * ward_scale
	skill.ward_power = float(skill.get("ward_power", 2)) * ward_scale
	if not ranks.has("ember_aura"): return skill
	var cadence := 0.8 if circlet else 1.0
	var temper_damage := 1 + 0.05 * maxi(0,int(ranks.get("ward_temper",1))-1)
	skill.merge({"variant":"ember_aura", "name":"Ember Aura", "type":"aura", "school":"fire", "scaling":"spell", "level":40,"mana":10.0, "cd":1.0, "cast_time":0.0, "recovery":0.15,
		"radius":2.5 * (1.25 if ranks.has("cinder_bloom") else 1.0), "dmg":0.3 * cadence * temper_damage, "pulse_interval":0.5 * cadence,
		"pulse_cost":3.0 * cadence * (1 - 0.05 * int(ranks.get("steady_flame", 0))), "burn_extension":0.15 if circlet else 0.0,"regen_multiplier":0.25,
		"desc":"Toggle a paid fire aura. Natural mana regeneration runs at 25% while active; generators still work. Insufficient upkeep stops before damage. Toggle off freely; base ID/cooldown stay Ashen Ward."},true)
	return skill
