extends RefCounted
## Presentation-only geometry shared by the painted HUD and its clickable hitboxes.
## Zero inventory/cooldown/save responsibilities; input semantics stay in hud.gd.
## Screenshot direction: ornate HP orb at outer-left, Flask bank left, wide XP
## spine through the middle, five active skills right, Mana orb outer-right.

const SKILLS := 5
const FLASKS := 5
const DEFAULT_ZOOM := 0.84
const ZOOM_MIN := 0.74
const ZOOM_MAX := 1.12

static func compute(view: Vector2) -> Dictionary:
	# Scaling uses the short axis AND available width: never let ornaments collide.
	var scale: float = clampf(minf(view.y / 810.0, view.x / 1440.0), 0.58, 1.20)
	var radius: float = 69.0 * scale
	var slot: float = 53.0 * scale
	var gap: float = 5.5 * scale
	var edge: float = 12.0 * scale
	var spacing: float = 17.0 * scale
	var cy: float = view.y - radius - 9.0 * scale
	var left_orb := Vector2(radius + edge, cy)
	var right_orb := Vector2(view.x - radius - edge, cy)
	var y: float = view.y - slot - 22.0 * scale
	var left_x: float = left_orb.x + radius + spacing
	var right_end: float = right_orb.x - radius - spacing
	var bank_width: float = SKILLS * slot + float(SKILLS - 1) * gap
	var right_x: float = right_end - bank_width
	var flask_rects: Array[Rect2] = []
	var skill_rects: Array[Rect2] = []
	for i in FLASKS:
		flask_rects.append(Rect2(left_x + float(i) * (slot + gap), y, slot, slot))
	for i in SKILLS:
		skill_rects.append(Rect2(right_x + float(i) * (slot + gap), y, slot, slot))
	var left_panel := Rect2(left_x - 8.0 * scale, y - 9.0 * scale, bank_width + 16.0 * scale, slot + 16.0 * scale)
	var right_panel := Rect2(right_x - 8.0 * scale, y - 9.0 * scale, bank_width + 16.0 * scale, slot + 16.0 * scale)
	var xp_left: float = left_panel.end.x + 15.0 * scale
	var xp_right: float = right_panel.position.x - 15.0 * scale
	var xp_rect := Rect2(xp_left, view.y - 16.0 * scale, maxf(0.0, xp_right - xp_left), 7.0 * scale)
	return {
		"scale": scale,
		"radius": radius,
		"left_orb": left_orb,
		"right_orb": right_orb,
		"flasks": flask_rects,
		"skills": skill_rects,
		"left_panel": left_panel,
		"right_panel": right_panel,
		"xp_rect": xp_rect
	}

static func clickable_rect(view: Vector2, index: int) -> Rect2:
	var g := compute(view)
	if index >= 0 and index < SKILLS:
		return g["skills"][index]
	if index >= SKILLS and index < SKILLS + FLASKS:
		return g["flasks"][index - SKILLS]
	return Rect2()

static func check_geometry(view: Vector2) -> bool:
	var g := compute(view)
	var left_panel: Rect2 = g["left_panel"]
	var right_panel: Rect2 = g["right_panel"]
	var xp: Rect2 = g["xp_rect"]
	var r: float = g["radius"]
	var l: Vector2 = g["left_orb"]
	var right: Vector2 = g["right_orb"]
	if l.x - r < 0 or right.x + r > view.x or left_panel.end.x >= right_panel.position.x:
		return false
	if xp.size.x < 40 or xp.position.x < left_panel.end.x or xp.end.x > right_panel.position.x:
		return false
	for rect in g["flasks"]:
		if not left_panel.encloses(rect): return false
	for rect in g["skills"]:
		if not right_panel.encloses(rect): return false
	return true