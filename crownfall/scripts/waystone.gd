extends Node2D
## A Waystone: a rune circle with a floating crystal. Click it (or press E next to it)
## to travel to the zone it links to.

const GD := preload("res://scripts/game_data.gd")
const RANGE := 1.2   # ground units

var dest_name := ""
var t := 0.0
var hot := false


func pick_rect() -> Rect2:
	return Rect2(position + Vector2(-70, -150), Vector2(140, 175))


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(t * 2.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, GD.SQ))
	draw_circle(Vector2.ZERO, 70.0, Color(0.45, 0.3, 1.0, 0.12 + 0.08 * pulse))
	draw_arc(Vector2.ZERO, 66.0, 0.0, TAU, 64, Color(0.75, 0.6, 1.0, 0.85), 3.0, true)
	draw_arc(Vector2.ZERO, 52.0, t * 0.6, t * 0.6 + TAU * 0.8, 48, Color(0.9, 0.8, 1.0, 0.6), 2.0, true)
	for i in 6:
		var a := t * 0.4 + TAU * i / 6.0
		var p := Vector2(cos(a), sin(a)) * 59.0
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(5, 0), p + Vector2(0, 6), p + Vector2(-5, 0)]), Color(0.9, 0.85, 1.0, 0.9))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# floating crystal
	var y := -92.0 + sin(t * 1.8) * 8.0
	var c := Vector2(0, y)
	draw_circle(c, 30.0, Color(0.6, 0.45, 1.0, 0.18 + 0.1 * pulse))
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -34), c + Vector2(15, -4), c + Vector2(0, 30), c + Vector2(-15, -4)]), Color("8a6cff"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -34), c + Vector2(15, -4), c + Vector2(0, -2)]), Color("c9b6ff"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -2), c + Vector2(15, -4), c + Vector2(0, 30)]), Color("5a3fd0"))
	# label
	var font := ThemeDB.fallback_font
	var s := "Waystone  ·  %s" % dest_name
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
	var lr := Rect2(-w / 2 - 9, -172, w + 18, 30)
	draw_rect(lr, Color(0.03, 0.02, 0.06, 0.8 if hot else 0.6))
	draw_rect(lr, Color(0.75, 0.6, 1.0, 0.9 if hot else 0.5), false, 1.5)
	draw_string(font, Vector2(-w / 2, -150), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("e6d8ff"))
