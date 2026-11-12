extends RefCounted
## Skill and potion icons drawn in code, shared by the skill bar and the spellbook.
## A painted icon in assets/skills/<id>.png replaces the drawn one.


static var _tex := {}


## Painted full-square tile for a skill, if assets/skills/<id>.png exists (from art/skill_tiles).
static func texture(id: String) -> Texture2D:
	if not _tex.has(id):
		var path := "res://assets/skills/%s.png" % id
		_tex[id] = load(path) if ResourceLoader.exists(path) else null
	return _tex[id]


## Darkens the part of a square still on cooldown, sweeping clockwise from the top (Diablo style).
static func draw_cooldown(ci: CanvasItem, r: Rect2, frac: float) -> void:
	frac = clampf(frac, 0.0, 1.0)
	if frac <= 0.0:
		return
	var c := r.get_center()
	var rad := r.size.length() * 0.5 + 2.0
	var pts := PackedVector2Array([c])
	var start := -PI / 2.0 + TAU * (1.0 - frac)
	var steps := maxi(2, int(48 * frac))
	for i in steps + 1:
		var a := start + TAU * frac * i / steps
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	# clip to the square by drawing the pie and then masking the outside with the frame colour is costly;
	# instead clamp each point into the rect, which keeps the shape square at the corners
	for i in range(1, pts.size()):
		pts[i] = Vector2(clampf(pts[i].x, r.position.x, r.end.x), clampf(pts[i].y, r.position.y, r.end.y))
	ci.draw_colored_polygon(pts, Color(0, 0, 0, 0.66))
	ci.draw_line(c, pts[1], Color(1, 0.9, 0.6, 0.7), 2.0, true)


static func draw_icon(ci: CanvasItem, id: String, r: Rect2, col: Color) -> void:
	if id == "potion" and ResourceLoader.exists("res://assets/ui/potion.png"):
		# painted potion bottle (Higgsfield), fitted inside the square
		if not _tex.has("ui_potion"):
			_tex["ui_potion"] = load("res://assets/ui/potion.png")
		var pt: Texture2D = _tex["ui_potion"]
		var inner := r.grow(-4)
		var kk: float = minf(inner.size.x / pt.get_width(), inner.size.y / pt.get_height())
		var sz := Vector2(pt.get_width(), pt.get_height()) * kk
		ci.draw_texture_rect(pt, Rect2(inner.get_center() - sz / 2.0, sz), false, col)
		return
	var tex := texture(id)
	if tex != null:
		# a grey colour means locked or unavailable: dim the painting
		var dim: bool = col.s < 0.05 and col.v < 0.6
		# full-bleed framed tiles (art/skill_tiles, Higgsfield) fill the whole square
		ci.draw_texture_rect(tex, r, false, Color(0.4, 0.4, 0.42) if dim else Color.WHITE)
		return
	var c := r.get_center()
	match id:
		"slash":
			ci.draw_line(c + Vector2(-16, 16), c + Vector2(16, -16), col, 6.0, true)
			ci.draw_line(c + Vector2(-20, 6), c + Vector2(-6, 20), col, 4.0, true)
		"cleave":
			ci.draw_arc(c + Vector2(0, 10), 24, PI * 1.1, PI * 1.9, 24, col, 7.0, true)
			ci.draw_arc(c + Vector2(0, 10), 14, PI * 1.15, PI * 1.85, 24, col, 3.0, true)
		"charge":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -22), c + Vector2(19, -15), c + Vector2(17, 6), c + Vector2(0, 22), c + Vector2(-17, 6), c + Vector2(-19, -15)]), col)
			ci.draw_rect(Rect2(c + Vector2(-2, -17), Vector2(4, 32)), Color(0, 0, 0, 0.35))
			ci.draw_rect(Rect2(c + Vector2(-13, -7), Vector2(26, 4)), Color(0, 0, 0, 0.35))
		"rally":
			for i in 8:
				var a := i / 8.0 * TAU
				ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a), sin(a)) * 24, c + Vector2(cos(a + 0.3), sin(a + 0.3)) * 10]), col)
		"hammer":
			ci.draw_set_transform(c, -0.7, Vector2.ONE)
			ci.draw_rect(Rect2(-3, -6, 6, 28), col)
			ci.draw_rect(Rect2(-14, -20, 28, 15), col)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"harvest":
			ci.draw_arc(c, 19, 0, TAU, 32, col, 4.0, true)
			ci.draw_circle(c + Vector2(0, -2), 10, col)
			ci.draw_rect(Rect2(c + Vector2(-6, -5), Vector2(4, 4)), Color.BLACK)
			ci.draw_rect(Rect2(c + Vector2(2, -5), Vector2(4, 4)), Color.BLACK)
		"breath":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-22, 2), c + Vector2(-4, -20), c + Vector2(22, -12), c + Vector2(8, -4), c + Vector2(20, 4), c + Vector2(6, 8), c + Vector2(18, 20), c + Vector2(-8, 18)]), col)
		"lock":
			ci.draw_arc(c + Vector2(0, -5), 9, PI, TAU, 16, Color(0.6, 0.6, 0.6), 4.0, true)
			ci.draw_rect(Rect2(c + Vector2(-13, -5), Vector2(26, 20)), Color(0.6, 0.6, 0.6))
		"potion":
			ci.draw_rect(Rect2(c + Vector2(-5, -24), Vector2(10, 9)), Color("c9b38a"))
			ci.draw_circle(c + Vector2(0, 6), 16, Color("a8121c"))
			ci.draw_circle(c + Vector2(-2, 4), 11, Color("e0434a"))
			ci.draw_circle(c + Vector2(-6, 0), 4, Color(1, 1, 1, 0.5))
