extends Node2D
## A Lorecasting point: a faint sigil on the ground where a lost memory lingers.
## Walk up and press E (or click it) to Lorecast and read what it remembers.

const GD := preload("res://scripts/game_data.gd")

var lore_id := ""
var main: Node2D
var t := 0.0
var hovered := false


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func known() -> bool:
	return main.player.lore.has(lore_id)


func pick_rect() -> Rect2:
	return Rect2(position + Vector2(-60, -120), Vector2(120, 150))


func _draw() -> void:
	var seen := known()
	var pulse := 0.5 + 0.5 * sin(t * 2.4)
	var col := Color(0.55, 0.3, 1.0) if not seen else Color(0.5, 0.5, 0.62)
	var a := (0.6 + 0.4 * pulse) if not seen else 0.3
	if hovered:
		a = 1.0
	# sigil on the ground, squashed to the camera angle; a soft violet glow makes it read on bright stone
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, GD.SQ))
	if not seen:
		for k in 4:
			draw_circle(Vector2.ZERO, 70.0 - k * 14.0, Color(0.5, 0.25, 1.0, (0.06 + 0.05 * pulse) * (k + 1) / 4.0))
	draw_set_transform(Vector2.ZERO, t * 0.3, Vector2(1.0, GD.SQ))
	draw_arc(Vector2.ZERO, 46, 0, TAU, 48, Color(0.1, 0.0, 0.2, a * 0.5), 7.0, true)
	draw_arc(Vector2.ZERO, 46, 0, TAU, 48, Color(col, a), 4.0, true)
	draw_arc(Vector2.ZERO, 31, 0, TAU, 36, Color(col.lightened(0.3), a * 0.85), 3.0, true)
	for i in 6:
		var ang := i / 6.0 * TAU
		draw_line(Vector2(cos(ang), sin(ang)) * 31, Vector2(cos(ang), sin(ang)) * 46, Color(col.lightened(0.2), a * 0.9), 3.0, true)
		draw_circle(Vector2(cos(ang), sin(ang)) * 52, 3.5, Color(col.lightened(0.4), a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not seen:
		# drifting motes rising from the sigil
		for i in 7:
			var ph := fmod(t * 0.45 + i / 7.0, 1.0)
			var x := sin(i * 2.3 + t) * 26.0
			draw_circle(Vector2(x, -ph * 110.0), 3.0 * (1.0 - ph) + 1.0, Color(0.85, 0.75, 1.0, (1.0 - ph) * 0.8))
	if hovered or not seen:
		var font := ThemeDB.fallback_font
		var title: String = GD.LORE[lore_id]["title"] if seen else "Lingering memory"
		var sub := "E or click to Lorecast" if not seen else "E or click to remember"
		for line in [[title, 17, Color("e6d8ff")], [sub, 13, Color("cfc6b2")]]:
			var w := font.get_string_size(line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[1]).x
			var y := -126.0 if line[1] == 17 else -108.0
			draw_string_outline(font, Vector2(-w / 2.0, y), line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[1], 5, Color(0, 0, 0, 0.85))
			draw_string(font, Vector2(-w / 2.0, y), line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[1], line[2])
