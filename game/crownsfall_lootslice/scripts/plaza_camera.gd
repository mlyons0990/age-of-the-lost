extends Camera2D
## The source world is painted isometric; zoom never changes world/nav coordinates.
const DEFAULT_ZOOM := 0.52
const MAX_ZOOM := 1.10
const SCENIC_BOUNDS := Rect2(-816,-461,4352,2458)
var target_zoom := DEFAULT_ZOOM
var expanded_backdrop := false

func _ready() -> void:
	get_viewport().size_changed.connect(_fit_bounds)
	_fit_bounds()

func bounds() -> Rect2:
	return SCENIC_BOUNDS.grow(-40) if expanded_backdrop else Rect2(0,0,2720,1536)

func minimum_zoom() -> float:
	var view := get_viewport_rect().size
	var area := bounds().size
	return maxf(0.46,maxf(view.x/area.x,view.y/area.y))

func _fit_bounds() -> void:
	var area := bounds()
	limit_left = int(area.position.x); limit_top = int(area.position.y)
	limit_right = int(area.end.x); limit_bottom = int(area.end.y)
	set_distance(target_zoom)

func set_distance(value: float) -> void:
	if not is_finite(value): return
	target_zoom = clampf(value,minimum_zoom(),maxf(MAX_ZOOM,minimum_zoom()))
	zoom = Vector2.ONE*target_zoom
	force_update_scroll()

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or not event is InputEventMouseButton or not event.pressed: return
	if get_viewport().gui_get_hovered_control() != null: return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		set_distance(target_zoom*1.12)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		set_distance(target_zoom/1.12)
	else: return
	get_viewport().set_input_as_handled()
