extends SceneTree

const Progress := preload("res://scripts/three_d/practice_progress.gd")
const Rules := preload("res://scripts/game_data.gd")

func _initialize() -> void:
	var p := Progress.new()
	var first := Rules.xp_need(25)
	var checks := []
	checks.append(p.level == 25 and p.xp == 0 and p.fraction() == 0)
	p.award_defeat()
	checks.append(p.xp == roundi(first / 13.75) and p.fraction() > 0)
	var before := p.xp
	p.add_xp(-20)
	checks.append(p.xp == before)
	p.add_xp(first - before + 37)
	checks.append(p.level == 26 and p.xp == 37 and p.caption().contains("37 / "))
	p.add_xp(Rules.xp_need(26) + Rules.xp_need(27))
	checks.append(p.level == 28 and p.xp == 37)
	p.add_xp(999999999)
	checks.append(p.level == Rules.MAX_LEVEL and p.xp == 0 and p.fraction() == 1)
	p.award_defeat()
	checks.append(p.caption().contains("MAX") and p.xp == 0)
	var boundary := Progress.new()
	for level in range(boundary.level, Rules.MAX_LEVEL):
		boundary.add_xp(Rules.xp_need(level) - 1)
		checks.append(boundary.level == level and boundary.xp == Rules.xp_need(level) - 1 and boundary.fraction() < 1.0)
		boundary.add_xp(1)
		checks.append(boundary.level == level + 1 and boundary.xp == 0)
	var readout := Progress.new()
	readout.add_xp(1234)
	checks.append(readout.caption() == "Lv. 25  (1,234 / 10,347)")
	# A large grant must reach the cap even when the balance is already positive.
	readout.add_xp(9223372036854775807)
	checks.append(readout.level == Rules.MAX_LEVEL and readout.xp == 0 and readout.fraction() == 1.0)
	print("Practice XP checks: ", checks.count(true), "/", checks.size())
	quit(1 if false in checks else 0)
