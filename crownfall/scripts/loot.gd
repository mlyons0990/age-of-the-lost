extends Node2D
## A drop on the ground: gold, a potion or an item. Picked up by walking over it,
## or by clicking its label (the knight walks there).
##
## Labels follow Path of Exile: items show a name plate in their rarity colour.
## Common items and gold only show a plate while Alt is held or the mouse is near,
## so the ground stays readable. main.gd stacks the plates so they never overlap.

const GD := preload("res://scripts/game_data.gd")
const LABEL_SIZE := 17

var kind := "gold"       # "gold", "potion" or "item"
var amount := 0
var item: Dictionary = {}
var age := 0.0
var wait_leave := false   # dropped by the player: not picked up until they walk away from it
var show_label := false   # set by main.gd each frame
var label_rect := Rect2() # world-space rect of the name plate, set by main.gd
var hot := false          # mouse is over the plate


func rarity() -> int:
	return int(item.get("rarity", 0)) if kind == "item" else -1


func color() -> Color:
	match kind:
		"gold":
			return Color("ffd84a")
		"potion":
			return Color("ff8a8a")
	return Color(String(GD.RARITY[int(item["rarity"])]["color"]))


func label_text() -> String:
	match kind:
		"gold":
			return "%d gold" % amount
		"potion":
			return "Health Potion"
	return String(item["name"])


## Size of the name plate in pixels.
func label_size() -> Vector2:
	var w := ThemeDB.fallback_font.get_string_size(label_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	return Vector2(w + 18.0, 26.0)


## Whether the plate shows without Alt held: magic items and better.
func always_labelled() -> bool:
	return kind == "item" and rarity() >= 1


func _process(delta: float) -> void:
	age += delta
	queue_redraw()


func _draw() -> void:
	var drop: float = maxf(0.0, 80.0 - age * 320.0)
	var bob: float = sin(age * 3.0) * 3.0
	var r := rarity()
	var col := color()
	# light beams by rarity: magic a soft glow, rare a beam, legendary a tall pulsing pillar and ground ring
	if kind == "item" and r >= 1 and drop <= 0.0:
		var pulse := 0.5 + 0.5 * sin(age * 4.0)
		if r == 1:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, GD.SQ))
			draw_circle(Vector2.ZERO, 26.0, Color(col.r, col.g, col.b, 0.12 + 0.06 * pulse))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var hgt := 300.0 if r == 2 else 560.0
			var w := 8.0 if r == 2 else 13.0
			var base := Color(col.r, col.g, col.b, (0.32 if r == 2 else 0.5) + 0.15 * pulse)
			var top := Color(col.r, col.g, col.b, 0.0)
			draw_polygon(PackedVector2Array([Vector2(-w, 0), Vector2(w, 0), Vector2(w * 0.4, -hgt), Vector2(-w * 0.4, -hgt)]), PackedColorArray([base, base, top, top]))
			var core := Color(1, 1, 1, 0.35 + 0.2 * pulse)
			draw_polygon(PackedVector2Array([Vector2(-w * 0.3, 0), Vector2(w * 0.3, 0), Vector2(0, -hgt * 0.8), Vector2(0, -hgt * 0.8)]), PackedColorArray([core, core, Color(1, 1, 1, 0), Color(1, 1, 1, 0)]))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, GD.SQ))
			if r == 3:
				for k in 2:
					var rr: float = 30.0 + fmod(age * 40.0 + k * 35.0, 70.0)
					draw_arc(Vector2.ZERO, rr, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.6 * (1.0 - (rr - 30.0) / 70.0)), 3.0, true)
			draw_circle(Vector2.ZERO, 22.0, Color(col.r, col.g, col.b, 0.22))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_set_transform(Vector2(0, -drop), 0.0, Vector2.ONE)
	match kind:
		"gold":
			for p in [Vector2(-7, -3), Vector2(5, -5), Vector2(0, -9), Vector2(9, 0), Vector2(-10, 2)]:
				draw_set_transform(Vector2(p.x, p.y - drop), 0.0, Vector2(1.0, 0.55))
				draw_circle(Vector2.ZERO, 7.0, Color("a8801e"))
				draw_circle(Vector2.ZERO, 5.5, Color("ffd84a"))
		"potion":
			draw_rect(Rect2(-4, -34 + bob, 8, 8), Color("c9b38a"))
			draw_circle(Vector2(0, -14 + bob), 13.0, Color("a8121c"))
			draw_circle(Vector2(-2, -16 + bob), 9.0, Color("e0434a"))
			draw_circle(Vector2(-5, -19 + bob), 3.5, Color(1, 1, 1, 0.5))
		"item":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -26 + bob), Vector2(12, -12 + bob), Vector2(0, 2 + bob), Vector2(-12, -12 + bob)]), col)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -20 + bob), Vector2(6, -12 + bob), Vector2(0, -4 + bob), Vector2(-6, -12 + bob)]), Color(1, 1, 1, 0.5))

	# name plate (position worked out by main.gd so plates never overlap)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if show_label and drop <= 0.0:
		var lr := Rect2(label_rect.position - position, label_rect.size)
		var bg := Color(0.02, 0.02, 0.04, 0.88 if hot else 0.72)
		draw_rect(lr, bg)
		if kind == "item" and r >= 1:
			draw_rect(lr, Color(col.r, col.g, col.b, 0.9 if hot else 0.6), false, 2.0 if r >= 2 else 1.0)
		elif hot:
			draw_rect(lr, Color(1, 1, 1, 0.5), false, 1.0)
		var font := ThemeDB.fallback_font
		draw_string(font, lr.position + Vector2(9, 19), label_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, col.lightened(0.15) if hot else col)
		# a thin line down to the drop when the plate was pushed up
		var foot := Vector2(lr.get_center().x, lr.end.y)
		if foot.y < -40.0:
			draw_line(foot, Vector2(0, -30), Color(col.r, col.g, col.b, 0.35), 1.0)
