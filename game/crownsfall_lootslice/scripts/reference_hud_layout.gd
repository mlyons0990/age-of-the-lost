extends RefCounted
## Shared geometry for the painted resources and R55's six clickable actions.
## Action indices 0–4 are the existing skills and index 5 is the Q potion.

static func scale_for(view: Vector2) -> float:
	return minf(view.x / 1672.0, view.y / 941.0)

static func action_rect(view: Vector2, index: int) -> Rect2:
	var scale := scale_for(view)
	var x := 194.0 * scale if index == 5 else view.x - (477.0 - index * 56.0) * scale
	return Rect2(Vector2(x, view.y - 94.0 * scale), Vector2.ONE * 51.0 * scale)

static func xp_rect(view: Vector2) -> Rect2:
	var scale := scale_for(view)
	return Rect2(492.0 * scale, view.y - 45.0 * scale, view.x - 992.0 * scale, 32.0 * scale)
