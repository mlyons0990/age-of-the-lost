extends RefCounted
## Per-visit progression for the opt-in combat labs. Campaign saves are separate.
const Rules := preload("res://scripts/game_data.gd")
signal changed
var level := 25
var xp := 0

func award_defeat() -> void:
	# Apply the campaign's base, non-elite, equal-level enemy reward.
	add_xp(roundi(Rules.xp_need(level) / (5.0 + level * 0.35)))

func add_xp(amount: int) -> void:
	if amount <= 0 or level >= Rules.MAX_LEVEL:
		return
	xp += amount
	while level < Rules.MAX_LEVEL and xp >= Rules.xp_need(level):
		xp -= Rules.xp_need(level)
		level += 1
	if level == Rules.MAX_LEVEL:
		xp = 0
	changed.emit()

func fraction() -> float:
	return 1.0 if level == Rules.MAX_LEVEL else float(xp) / Rules.xp_need(level)

func caption() -> String:
	return "Lv. %d  (MAX)" % level if level == Rules.MAX_LEVEL else "Lv. %d  (%d / %d)" % [level, xp, Rules.xp_need(level)]
