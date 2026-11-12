extends Control
const Rules := preload("res://scripts/encounter_rules.gd")
var main: Node2D
func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void: queue_redraw()
func _text(value: String, at: Vector2, size: int, color: Color) -> void:
	draw_string_outline(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,5,Color("10121e"))
	draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func _draw() -> void:
	var trial: Node2D = main.encounter
	if not trial.active or not is_instance_valid(trial.boss): return
	var w := get_viewport_rect().size.x
	var bar := Rect2(w/2-280,40,560,20)
	draw_rect(bar.grow(9),Color("131725")); draw_rect(bar,Color("4c2532"))
	draw_rect(Rect2(bar.position,Vector2(bar.size.x*clampf(trial.boss.hp/trial.boss.max_hp,0,1),20)),Color("bb7561"))
	draw_rect(bar,Color("d8ad68"),false,1.5)
	_text("THE UNWRITTEN CANTOR · VERSE %d · %d / %d" % [2 if trial.second_phase else 1,ceili(trial.boss.hp),int(trial.boss.max_hp)],bar.position+Vector2(0,-10),18,Color("f5ddb5"))
	if trial.warnings.is_empty():
		_text("Read the next seal · R: retreat · T: briefing",bar.position+Vector2(0,45),17,Color("d5d0e2"))
	else:
		var warning: Dictionary = trial.warnings[0]
		_text("%s · %.1fs · %s" % [Rules.NAMES[warning.kind],maxf(0,warning.left),Rules.HINTS[warning.kind]],bar.position+Vector2(-40,45),17,Color("ffd5b0"))
		var progress := 1.0-float(warning.left)/float(warning.duration)
		draw_rect(Rect2(bar.position+Vector2(0,54),Vector2(560,4)),Color("332e40"))
		draw_rect(Rect2(bar.position+Vector2(0,54),Vector2(560*clampf(progress,0,1),4)),Color("ffe2a2"))
