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
	while level < Rules.MAX_LEVEL:
		var remaining := Rules.xp_need(level) - xp
		if amount < remaining:
			xp += amount
			break
		amount -= remaining
		xp = 0
		level += 1
	changed.emit()

func fraction() -> float:
	return 1.0 if level == Rules.MAX_LEVEL else float(xp) / Rules.xp_need(level)

func caption() -> String:
	if level >= Rules.MAX_LEVEL:
		return "Lv. %d  (MAX)" % level
	return "Lv. %d  (%s / %s)" % [level, _group_digits(xp), _group_digits(Rules.xp_need(level))]

func _group_digits(value: int) -> String:
	var digits := str(value)
	for index in range(digits.length() - 3, 0, -3):
		digits = digits.insert(index, ",")
	return digits
