extends RefCounted
## Pure combat math. Power, buffs and modifiers snapshot at activation;
## variance and crit roll at contact. DOT does not roll crit or variance.
static func snapshot(skill: Dictionary, stats: Dictionary, damage_mult := 1.0) -> Dictionary:
	var power: float = float(stats.get("spell_power", 0.0) if skill.get("scaling", "weapon") == "spell" else stats.get("dmg", 0.0))
	var duration: float = float(skill.get("burn_duration", 3.0))
	var burn_mult: float = float(stats.get("m", {}).get("burn_mult", 1.0))
	return {"ability_id": String(skill.get("id", "")), "school": String(skill.get("school", "physical")),
		"power": power, "direct": power * float(skill.get("dmg", 0.0)) * damage_mult,
		"burn_dps": power * float(skill.get("burn", 0.0)) * burn_mult * damage_mult / maxf(0.1, duration),
		"burn_duration": duration, "crit_chance": clampf(float(stats.get("crit", 0.0)), 0, 0.6),
		"crit_multiplier": 1.75, "mana_gain": float(skill.get("gain_on_hit", 0.0)), "rewarded": false,
		"slow": float(skill.get("slow", 0.0)), "slow_duration": float(skill.get("slow_duration", 0.0)),
		"stun": float(skill.get("stun", 0.0)), "kb": float(skill.get("kb", 0.15)),
		"is_frost_stitch": skill.get("id", "") == "glacial_stitch"}

static func resolve(packet: Dictionary, variance := 1.0, crit_roll := 1.0) -> Dictionary:
	var critical: bool = crit_roll < float(packet.get("crit_chance", 0.0))
	var damage: float = float(packet.get("direct", 0.0)) * clampf(variance, 0.9, 1.1)
	if critical: damage *= float(packet.get("crit_multiplier", 1.75))
	return {"damage": maxi(1, roundi(damage)) if damage > 0.0 else 0, "crit": critical,
		"school": packet.get("school", "physical"), "burn_dps": packet.get("burn_dps", 0.0)}

static func summary(skill: Dictionary, stats: Dictionary, damage_mult := 1.0) -> String:
	var p := snapshot(skill, stats, damage_mult)
	var lines: Array[String] = []
	if float(p.direct) > 0:
		lines.append("%s: %.1f–%.1f %s (non-crit)" % ["Pulse hit" if skill.get("type") == "aura" else "Direct hit",p.direct * 0.9, p.direct * 1.1, p.school])
	if float(p.burn_dps) > 0:
		lines.append("Burn: %.1f/s for %.1fs · %.1f total" % [p.burn_dps, p.burn_duration, p.burn_dps * p.burn_duration])
	if float(p.mana_gain) > 0: lines.append("Restore %d mana on first hit per cast" % int(p.mana_gain))
	if skill.get("type") == "ward": lines.append("Ward: %d absorbed damage for %.1fs" % [ward_capacity(skill, stats), float(skill.get("duration", 3))])
	if skill.get("type") == "aura":
		lines.append("Pulse: %.1fs / %.2f mana · radius %.2f" % [skill.pulse_interval,skill.pulse_cost,skill.radius])
		lines.append("Upkeep: %.2f mana/s before regeneration" % [skill.pulse_cost / skill.pulse_interval])
		lines.append("Natural mana regeneration: 25% while active.")
		if float(skill.get("burn_extension",0)) > 0: lines.append("Emberwake: +0.15s to existing burns per hit, capped at 4s.")
	if float(p.slow) > 0: lines.append("Slow: %d%% for %.1fs" % [p.slow * 100, p.slow_duration])
	return "\n".join(lines)

static func ward_capacity(skill: Dictionary, stats: Dictionary) -> float:
	return round(float(stats.max_hp) * float(skill.get("hp_fraction", 0.2)) + float(stats.spell_power) * float(skill.get("ward_power", 2.0)))
