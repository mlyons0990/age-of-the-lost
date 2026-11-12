extends Node2D
## A townsperson standing in the plaza: one painted sprite, a name plate, a gentle idle sway.

var tex: Texture2D
var title := ""
var role := ""
var scale_k := 0.85
var t := 0.0
var hovered := false


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


## On-screen rectangle used for mouse picking, in world coordinates.
func pick_rect() -> Rect2:
	var w := tex.get_width() * scale_k
	var h := tex.get_height() * scale_k
	return Rect2(position + Vector2(-w * 0.4, -h), Vector2(w * 0.8, h))


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 40.0, Color(0.1, 0.08, 0.2, 0.3))
	var sway := sin(t * 1.6) * 0.012
	draw_set_transform(Vector2.ZERO, sway, Vector2(scale_k, scale_k * (1.0 + 0.006 * sin(t * 2.2))))
	draw_texture(tex, Vector2(-tex.get_width() / 2.0, -tex.get_height() + 6.0), Color(1.15, 1.12, 1.0) if hovered else Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font := ThemeDB.fallback_font
	var y := -tex.get_height() * scale_k - 14.0
	for line in [[title, 18, Color("ffe9a8")], [role, 14, Color("cfc6b2")]]:
		var w := font.get_string_size(line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[1]).x
		draw_string_outline(font, Vector2(-w / 2.0, y), line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[1], 5, Color(0, 0, 0, 0.85))
		draw_string(font, Vector2(-w / 2.0, y), line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[1], line[2])
		y += 20.0
