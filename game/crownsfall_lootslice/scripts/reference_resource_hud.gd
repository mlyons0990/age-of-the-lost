extends RefCounted

const LIFE := preload("res://assets/ui/reference_globes/life.png")
const LIFE_EMPTY := preload("res://assets/ui/reference_globes/life_empty.png")
const MANA := preload("res://assets/ui/reference_globes/mana.png")
const MANA_EMPTY := preload("res://assets/ui/reference_globes/mana_empty.png")
const RAIL := preload("res://assets/ui/reference_globes/xp_frame.png")

static func globe(canvas: Control, mana: bool, amount: float, capacity: float, scale: float) -> void:
	var full := MANA if mana else LIFE
	var empty := MANA_EMPTY if mana else LIFE_EMPTY
	var native_size := full.get_size()
	var size := native_size * scale
	var origin := Vector2(canvas.size.x - size.x if mana else 0.0, canvas.size.y - size.y)
	var fraction := clampf(amount / maxf(capacity, 1.0), 0.0, 1.0)
	canvas.draw_texture_rect(empty, Rect2(origin, size), false)
	if fraction <= 0.0:
		return
	var surface := lerpf(173.0, 35.0, fraction)
	var source := Rect2(0, surface, native_size.x, native_size.y - surface)
	canvas.draw_texture_rect_region(full, Rect2(origin + source.position * scale, source.size * scale), source)

static func experience(canvas: Control, rail: Rect2, scale: float, level: int, xp: int, needed: int, capped: bool) -> void:
	canvas.draw_texture_rect(RAIL, rail, false)
	var well := Rect2(rail.position + Vector2(3, 9) * scale, Vector2(rail.size.x - 6 * scale, 13 * scale))
	canvas.draw_rect(well, Color("120d17"))
	var filled := well
	filled.size.x *= 1.0 if capped else clampf(float(xp) / maxi(needed, 1), 0.0, 1.0)
	canvas.draw_rect(filled, Color("6726a0"))
	filled.size.y *= 0.45
	canvas.draw_rect(filled, Color("b86bdd"))
	var font := ThemeDB.fallback_font
	var label := "Lv. %d   (%s)" % [level, "MAX" if capped else "%d / %d" % [xp, needed]]
	var pixels := maxi(10, roundi(13 * scale))
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x + 22 * scale
	var mid := rail.get_center()
	var half := Vector2(width / 2.0, 10.5 * scale)
	var bevel := Vector2(6 * scale, 0)
	var corners := PackedVector2Array([mid-half+bevel, mid+Vector2(half.x,-half.y)-bevel, mid+Vector2(half.x,0), mid+half-bevel, mid+Vector2(-half.x,half.y)+bevel, mid-Vector2(half.x,0)])
	canvas.draw_colored_polygon(corners, Color("171318"))
	corners.append(corners[0])
	canvas.draw_polyline(corners, Color("ac8752"), maxf(1,scale), true)
	canvas.draw_string(font, mid + Vector2(-width / 2, (font.get_ascent(pixels) - font.get_descent(pixels)) / 2), label, HORIZONTAL_ALIGNMENT_CENTER, width, pixels, Color("f6eacb"))
