extends CanvasLayer
## Waypoint travel window (opens when the hero walks onto a waypoint they clicked). Lists every waypoint by zone in
## world order; unlocked ones are clickable, locked ones show as "???". Esc, the close button or walking away closes it.
signal travel_requested(id: String)
const GOLD := Color("e8b85c")
const IVORY := Color("efe6d2")
var net                      # waypoints.gd
var current_id := ""
var panel: PanelContainer
var list: VBoxContainer
var buttons := {}            # id -> Button

func _init(network, here_id: String) -> void:
	net = network
	current_id = here_id
	layer = 40
	name = "WaypointPanel"

func _ready() -> void:
	panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.07, 0.94)
	sb.border_color = Color("9b7a44"); sb.set_border_width_all(2); sb.set_corner_radius_all(6)
	sb.content_margin_left = 18; sb.content_margin_right = 18; sb.content_margin_top = 12; sb.content_margin_bottom = 14
	sb.shadow_color = Color(0, 0, 0, 0.6); sb.shadow_size = 12
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(560, 150)
	panel.custom_minimum_size = Vector2(360, 0)
	add_child(panel)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	var head := HBoxContainer.new()
	var t := Label.new(); t.text = "Waypoints"; t.add_theme_font_size_override("font_size", 24); t.add_theme_color_override("font_color", GOLD)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var x := Button.new(); x.text = "✕"; x.flat = true; x.pressed.connect(close); x.name = "Close"
	head.add_child(x)
	v.add_child(head)
	var sep := HSeparator.new(); v.add_child(sep)
	list = VBoxContainer.new(); list.add_theme_constant_override("separation", 4)
	v.add_child(list)
	var zone_seen := ""
	for e in net.entries:
		if e["zone_name"] != zone_seen:
			zone_seen = e["zone_name"]
			var zl := Label.new(); zl.text = zone_seen + ("   (Town)" if e["town"] else "")
			zl.add_theme_font_size_override("font_size", 15); zl.add_theme_color_override("font_color", Color("a99a80"))
			list.add_child(zl)
		var b := Button.new()
		var open: bool = net.is_unlocked(e["id"])
		b.text = ("◆  " + e["name"]) if open else "◆  ???"
		if e["id"] == current_id: b.text += "   — you are here"
		b.disabled = not open or e["id"] == current_id
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", IVORY)
		b.add_theme_color_override("font_hover_color", GOLD)
		b.name = "WP_" + e["id"]
		var id: String = e["id"]
		b.pressed.connect(func(): travel_requested.emit(id))
		list.add_child(b)
		buttons[id] = b

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()

func close() -> void:
	queue_free()
