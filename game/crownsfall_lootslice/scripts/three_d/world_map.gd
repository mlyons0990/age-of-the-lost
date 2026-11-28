extends Control
## Full-screen map (owner 11-26, opened with M): a ZONE tab (the zone drawn from its own data, fog of war over what the
## hero has not explored, waypoints, exits, points of interest, quest objectives, the hero) and a WORLD tab (every zone,
## how they connect, which are discovered, where the hero is and where active quests lead). Tab switches, Esc / M
## closes, mouse wheel zooms, drag pans, hovering a marker names it. Clicking a discovered zone on the world map opens
## its zone map. Exploration is saved per zone in the [map] section of the one save file.
const SAVE := preload("res://scripts/three_d/aotl_save.gd")
const GOLD := Color("d9b46a")
const GOLD_DIM := Color("8f7444")
const IVORY := Color("efe6cf")
const INK := Color(0.045, 0.04, 0.04, 0.96)
const FOG_CELL := 160.0            # zone painting px per exploration cell
const REVEAL_PX := 1000.0          # explored radius around the hero

var lab: Node3D
var hud
var font: Font
var font_regular: Font
var mode := "zone"
var view_zone := ""                # zone id shown on the zone tab ("" = current)
var zoom := 1.0
var centre := Vector2.ZERO         # zone px at the middle of the map area
var dragging := false
var hover := {}                    # marker under the mouse: {name, sub, at}
var explored := {}                 # zone id -> {"w": int, "h": int, "bits": PackedByteArray}
var world: Dictionary
var quests: Array = []
var zone_cache := {}               # zone id -> zone JSON
var tex_cache := {}
var fog_tex: ImageTexture
var fog_dirty := true
var area := Rect2()                # map drawing area (screen)
var side := Rect2()                # legend / quest column
var tabs := {}                     # "zone"/"world" -> Rect2
var close_rect := Rect2()
var world_nodes := []              # [{rect/centre, node}]
var reveal_t := 0.0

func setup(owner_lab: Node3D, owner_hud) -> void:
	lab = owner_lab
	hud = owner_hud
	font = hud.font
	font_regular = hud.font_regular
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	world = JSON.parse_string(FileAccess.get_file_as_string("res://assets/zones/world.json"))
	quests = JSON.parse_string(FileAccess.get_file_as_string("res://data/quests.json"))["quests"]
	_load_explored()
	lab.zone_changed.connect(func(_to): view_zone = ""; fog_dirty = true; reveal_t = 0.0; save_explored())

# ---------------- data ----------------

func current_zone_id() -> String:
	var z := String(lab.painted_zone)
	return z.get_file().get_basename() if z.begins_with("res://") else z

func world_id_of(zid: String) -> String:
	return String(zone_data(zid).get("world_id", zid))

func zone_data(zid: String) -> Dictionary:
	if zid == current_zone_id(): return lab.zone
	if not zone_cache.has(zid):
		var path := "res://assets/zones/%s.json" % zid
		zone_cache[zid] = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	return zone_cache[zid]

func _tex(path: String) -> Texture2D:
	if not tex_cache.has(path): tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return tex_cache[path]

func map_texture(zid: String) -> Texture2D:
	var z := zone_data(zid)
	for k in ["map", "overview"]:
		if z.has(k):
			var t := _tex("res://assets/zones/" + String(z[k]))
			if t != null: return t
	return null

## Active quests: [{id, name, objective, progress, count, done, markers}] — from the game (character's real quest
## state) or, in the labs, the first step of each quest in data/quests.json.
func active_quests() -> Array:
	if lab.get("game") != null: return lab.game.quest_view()
	var out := []
	for q in quests.slice(0, 2):       # labs: the first two quests as a static sample
		var step: Dictionary = q.get("steps", {}).get("active", {})
		var ms := []
		for m in step.get("markers", []):
			if m.has("at"): ms.append(m)
		out.append({"id": q["id"], "name": q["name"], "objective": step.get("objective", ""), "progress": hud.quest_progress if q["id"] == "lost_tomes" else 0, "count": int(q.get("count", 0)), "done": false, "markers": ms})
	return out

## Quest markers in a zone: [{quest, label, at, r, done}]
func quest_markers(zid: String) -> Array:
	var out := []
	for q in active_quests():
		for m in q.get("markers", []):
			if String(m["zone"]) == zid and m.has("at"):
				out.append({"quest": q["name"], "label": String(m.get("label", q["objective"])), "at": Vector2(float(m["at"][0]), float(m["at"][1])), "r": float(m.get("r", 0)), "done": bool(q["done"])})
	return out

func quest_progress(q: Dictionary) -> int:
	return int(q.get("progress", 0))

func quest_done(q: Dictionary) -> bool:
	return bool(q.get("done", false))

# ---------------- exploration (fog of war) ----------------

func _grid(zid: String) -> Dictionary:
	if not explored.has(zid):
		var sz: Array = zone_data(zid).get("size", [1, 1])
		var w := int(ceil(float(sz[0]) / FOG_CELL)); var h := int(ceil(float(sz[1]) / FOG_CELL))
		var bits := PackedByteArray(); bits.resize(w * h)
		explored[zid] = {"w": w, "h": h, "bits": bits}
	return explored[zid]

func reveal(zid: String, at: Vector2, radius := REVEAL_PX) -> bool:
	var g := _grid(zid); var changed := false
	var r := int(ceil(radius / FOG_CELL))
	var cx := int(at.x / FOG_CELL); var cy := int(at.y / FOG_CELL)
	for y in range(maxi(0, cy - r), mini(g["h"], cy + r + 1)):
		for x in range(maxi(0, cx - r), mini(g["w"], cx + r + 1)):
			if Vector2((x + 0.5) * FOG_CELL - at.x, ((y + 0.5) * FOG_CELL - at.y) / 0.6).length() <= radius:
				var i: int = y * g["w"] + x
				if g["bits"][i] == 0:
					g["bits"][i] = 1; changed = true
	return changed

func explored_fraction(zid: String) -> float:
	var g := _grid(zid); var n := 0
	for b in g["bits"]: n += int(b)
	return float(n) / float(maxi(1, g["bits"].size()))

func is_discovered(world_node_id: String) -> bool:
	if world_node_id == String(world.get("town", "crownsfall")): return true
	for zid in explored:
		if world_id_of(zid) == world_node_id and explored_fraction(zid) > 0.0: return true
	return world_id_of(current_zone_id()) == world_node_id

func _load_explored() -> void:
	var cf: ConfigFile = SAVE.open()
	if not cf.has_section("map"): return
	for zid in cf.get_section_keys("map"):
		var v = cf.get_value("map", zid)
		if v is Dictionary and v.has("bits"): explored[zid] = v

func save_explored() -> void:
	var cf: ConfigFile = SAVE.open()
	for zid in explored: cf.set_value("map", zid, explored[zid])
	SAVE.commit(cf)

## Called by the HUD every frame: reveal around the hero (cheap, 4x a second), save on zone change.
func tick(delta: float) -> void:
	reveal_t -= delta
	if reveal_t > 0.0: return
	reveal_t = 0.25
	if lab.zone.is_empty(): return
	if reveal(current_zone_id(), lab.zone_world_to_px(lab.player.global_position)):
		fog_dirty = true
		if visible: queue_redraw()

func _fog_texture(zid: String) -> ImageTexture:
	var g := _grid(zid)
	var img := Image.create(g["w"], g["h"], false, Image.FORMAT_LA8)
	for y in g["h"]:
		for x in g["w"]:
			img.set_pixel(x, y, Color(0, 0, 0, 0.0 if g["bits"][y * g["w"] + x] else 1.0))
	img.resize(g["w"] * 4, g["h"] * 4, Image.INTERPOLATE_CUBIC)     # soft-edged fog
	return ImageTexture.create_from_image(img)

# ---------------- open / close / input ----------------

func open(tab := "zone") -> void:
	visible = true
	mode = tab
	view_zone = ""
	_fit_zone()
	fog_dirty = true
	save_explored()
	queue_redraw()

func close() -> void:
	visible = false
	save_explored()

func toggle() -> void:
	if visible: close()
	else: open()

func shown_zone() -> String:
	return view_zone if view_zone != "" else current_zone_id()

func _layout() -> void:
	var vs := get_viewport_rect().size
	var frame := Rect2(Vector2(40, 34), vs - Vector2(80, 68))
	area = Rect2(frame.position + Vector2(18, 70), Vector2(frame.size.x - 36 - 330, frame.size.y - 88))
	side = Rect2(Vector2(area.end.x + 16, area.position.y), Vector2(314, area.size.y))
	tabs = {"zone": Rect2(frame.position + Vector2(18, 22), Vector2(150, 36)), "world": Rect2(frame.position + Vector2(176, 22), Vector2(150, 36))}
	close_rect = Rect2(Vector2(frame.end.x - 50, frame.position.y + 18), Vector2(34, 34))

func _fit_zone() -> void:
	_layout()
	zoom = 1.0
	var z := zone_data(shown_zone())
	var sz: Array = z.get("size", [1, 1])
	centre = Vector2(float(sz[0]), float(sz[1])) * 0.5
	if shown_zone() == current_zone_id():
		zoom = 1.0

func _base_scale() -> float:
	var sz: Array = zone_data(shown_zone()).get("size", [1, 1])
	return minf(area.size.x / float(sz[0]), area.size.y / float(sz[1]))

func px_to_screen(px: Vector2) -> Vector2:
	return area.get_center() + (px - centre) * _base_scale() * zoom

func screen_to_px(sp: Vector2) -> Vector2:
	return centre + (sp - area.get_center()) / (_base_scale() * zoom)

func _clamp_centre() -> void:
	var sz: Array = zone_data(shown_zone()).get("size", [1, 1])
	var half := area.size * 0.5 / (_base_scale() * zoom)
	var zs := Vector2(float(sz[0]), float(sz[1]))
	centre.x = clampf(centre.x, minf(half.x, zs.x * 0.5), maxf(zs.x - half.x, zs.x * 0.5))
	centre.y = clampf(centre.y, minf(half.y, zs.y * 0.5), maxf(zs.y - half.y, zs.y * 0.5))

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		var a: String = hud.kb.action_for_event(event)
		if event.keycode == KEY_ESCAPE or a == "map":
			close(); get_viewport().set_input_as_handled()
		elif event.keycode == KEY_TAB:
			set_tab("world" if mode == "zone" else "zone"); get_viewport().set_input_as_handled()

func set_tab(t: String) -> void:
	mode = t
	if t == "zone" and view_zone == "": _fit_zone()
	hover = {}
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if close_rect.has_point(event.position): close(); accept_event(); return
			for t in tabs:
				if tabs[t].has_point(event.position):
					if t == "zone": view_zone = ""
					set_tab(t); accept_event(); return
			if mode == "world":
				for wn in world_nodes:
					if wn["centre"].distance_to(event.position) < 40.0 and wn.has("zone"):
						view_zone = wn["zone"]; mode = "zone"; _fit_zone(); fog_dirty = true; queue_redraw(); accept_event(); return
			if mode == "zone" and area.has_point(event.position): dragging = true
		elif mode == "zone" and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and area.has_point(event.position):
			var before := screen_to_px(event.position)
			zoom = clampf(zoom * (1.25 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.8), 1.0, 5.0)
			centre += before - screen_to_px(event.position)
			_clamp_centre(); queue_redraw()
		accept_event()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = false
		accept_event()
	elif event is InputEventMouseMotion:
		if dragging and mode == "zone":
			centre -= event.relative / (_base_scale() * zoom)
			_clamp_centre()
		_update_hover(event.position)
		queue_redraw()
		accept_event()

# ---------------- markers ----------------

## Everything drawn on the zone map, as data: [{kind, name, sub, at (zone px), r?, angle?}]
func zone_markers(zid: String) -> Array:
	var z := zone_data(zid)
	var out := []
	for ex in z.get("exits", []):
		var c := Vector2.ZERO
		for p in ex["poly"]: c += Vector2(float(p[0]), float(p[1]))
		out.append({"kind": "exit", "name": String(ex["name"]), "sub": "Exit to " + String(ex["name"]), "at": c / float(ex["poly"].size())})
	for w in z.get("waypoints", []):
		var unlocked: bool = lab.waypoint_net != null and lab.waypoint_net.is_unlocked(String(w["id"]))
		if unlocked:
			out.append({"kind": "waypoint", "name": String(w.get("name", "Waypoint")), "sub": "Waypoint", "at": Vector2(float(w["at"][0]), float(w["at"][1]))})
	for p in z.get("map_pois", []):
		var at := Vector2(float(p["at"][0]), float(p["at"][1]))
		if p.get("kind", "") != "npc" and not _seen(zid, at): continue        # places appear once explored
		out.append({"kind": String(p.get("kind", "landmark")), "name": String(p["name"]), "sub": String(p.get("blurb", "")), "at": at})
	for m in quest_markers(zid):
		out.append({"kind": "quest_done" if m["done"] else "quest", "name": m["label"], "sub": m["quest"] + (" (complete)" if m["done"] else ""), "at": m["at"], "r": m["r"]})
	if zid == current_zone_id():
		var face: Vector3 = lab.player.last_face if "last_face" in lab.player else Vector3.FORWARD
		var p0: Vector2 = lab.zone_world_to_px(lab.player.global_position)
		var p1: Vector2 = lab.zone_world_to_px(lab.player.global_position + Vector3(face.x, 0, face.z).normalized())
		out.append({"kind": "hero", "name": "You", "sub": "", "at": p0, "angle": (p1 - p0).angle()})
	return out

func _seen(zid: String, at: Vector2) -> bool:
	var g := _grid(zid)
	var x := int(at.x / FOG_CELL); var y := int(at.y / FOG_CELL)
	return x >= 0 and y >= 0 and x < g["w"] and y < g["h"] and g["bits"][y * g["w"] + x] == 1

func _update_hover(mp: Vector2) -> void:
	hover = {}
	if mode == "zone" and area.has_point(mp):
		var best := 18.0
		for m in zone_markers(shown_zone()):
			if m["kind"] in ["hero"]: continue
			var d := px_to_screen(m["at"]).distance_to(mp)
			if d < best: best = d; hover = m
	elif mode == "world":
		for wn in world_nodes:
			if wn["centre"].distance_to(mp) < 40.0: hover = {"name": wn["node"]["name"], "sub": wn["sub"], "screen": wn["centre"]}

# ---------------- drawing ----------------

func _draw() -> void:
	_layout()
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.55))
	var frame := Rect2(Vector2(40, 34), vs - Vector2(80, 68))
	draw_rect(frame, INK)
	draw_rect(frame, GOLD, false, 2.0)
	draw_rect(frame.grow(-6), GOLD_DIM, false, 1.0)
	for t in tabs:
		var r: Rect2 = tabs[t]; var on: bool = t == mode
		draw_rect(r, Color(0.16, 0.12, 0.07, 0.95) if on else Color(0.08, 0.07, 0.06, 0.9))
		draw_rect(r, GOLD if on else GOLD_DIM, false, 1.5)
		_text(r.position + Vector2(r.size.x * 0.5, 25), "ZONE MAP" if t == "zone" else "WORLD MAP", 17, GOLD if on else Color("a8977a"), true)
	draw_rect(close_rect, Color(0.1, 0.08, 0.07), true)
	draw_rect(close_rect, GOLD_DIM, false, 1.5)
	_text(close_rect.get_center() + Vector2(0, 8), "✕", 20, IVORY, true)
	_text(Vector2(frame.end.x - 70, frame.position.y + 44), "M / Esc to close  ·  Tab to switch", 14, Color("a8977a"), false, HORIZONTAL_ALIGNMENT_RIGHT)
	if mode == "zone": _draw_zone()
	else: _draw_world()
	_draw_side()
	if not hover.is_empty(): _draw_tooltip()

func _text(at: Vector2, s: String, size: int, col: Color, bold := true, align := HORIZONTAL_ALIGNMENT_CENTER, width := -1.0) -> void:
	var f: Font = font if bold else font_regular
	var w: float = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := at
	if align == HORIZONTAL_ALIGNMENT_CENTER: p.x -= w * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT: p.x -= w
	draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, width, size, 4, Color(0, 0, 0, 0.9))
	draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, width, size, col)

func _draw_zone() -> void:
	var zid := shown_zone()
	var z := zone_data(zid)
	var nm := String(z.get("name", zid)).split(" — ")[0]
	_text(Vector2(area.get_center().x, area.position.y - 18), nm.to_upper(), 26, GOLD)
	draw_rect(area, Color(0.02, 0.02, 0.02))
	var tex := map_texture(zid)
	var sz: Array = z.get("size", [1, 1])
	var zr := Rect2(px_to_screen(Vector2.ZERO), Vector2(float(sz[0]), float(sz[1])) * _base_scale() * zoom)
	# clip to the map area by drawing only the visible part of the texture
	var vis := zr.intersection(area)
	if tex != null and vis.size.x > 0:
		var tk := Vector2(tex.get_width(), tex.get_height()) / zr.size
		draw_texture_rect_region(tex, vis, Rect2((vis.position - zr.position) * tk, vis.size * tk), Color(0.92, 0.9, 0.86))
	if fog_dirty or fog_tex == null:
		fog_tex = _fog_texture(zid); fog_dirty = false
	if vis.size.x > 0:
		var fk := Vector2(fog_tex.get_width(), fog_tex.get_height()) / zr.size
		draw_texture_rect_region(fog_tex, vis, Rect2((vis.position - zr.position) * fk, vis.size * fk), Color(0.07, 0.06, 0.06, 0.86))
	# markers (quest areas first, then icons, hero last)
	var ms := zone_markers(zid)
	ms.sort_custom(func(a, b): return _order(a["kind"]) < _order(b["kind"]))
	for m in ms:
		var p := px_to_screen(m["at"])
		if not area.grow(-4).has_point(p): continue
		_draw_marker(m, p, true)
	draw_rect(area, GOLD_DIM, false, 1.5)
	var pct := int(round(explored_fraction(zid) * 100.0))
	_text(area.position + Vector2(12, area.size.y - 12), "Explored %d%%" % pct, 15, IVORY, false, HORIZONTAL_ALIGNMENT_LEFT)
	_text(area.end - Vector2(12, 12), "Wheel: zoom  ·  Drag: pan", 14, Color("a8977a"), false, HORIZONTAL_ALIGNMENT_RIGHT)

func _order(k: String) -> int:
	return {"quest": 0, "quest_done": 0, "landmark": 1, "secret": 1, "cache": 1, "npc": 2, "exit": 3, "waypoint": 4, "hero": 9}.get(k, 5)

## One marker icon. `label` adds its name beside it (full map); the minimap passes false.
func _draw_marker(m: Dictionary, p: Vector2, label: bool, scale_ := 1.0, canvas: CanvasItem = null) -> void:
	var c: CanvasItem = canvas if canvas != null else self
	var s := scale_
	match m["kind"]:
		"hero":
			var a: float = m.get("angle", -PI * 0.5)
			var pts := PackedVector2Array([p + Vector2(12, 0).rotated(a) * s, p + Vector2(-7, 7).rotated(a) * s, p + Vector2(-3, 0).rotated(a) * s, p + Vector2(-7, -7).rotated(a) * s])
			c.draw_circle(p, 10.0 * s, Color(0, 0, 0, 0.55))
			c.draw_colored_polygon(pts, Color("f2d27a"))
			c.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.2, 0.12, 0.02), 1.5 * s, true)
		"waypoint":
			var d := PackedVector2Array([p + Vector2(0, -9) * s, p + Vector2(8, 0) * s, p + Vector2(0, 9) * s, p + Vector2(-8, 0) * s])
			c.draw_colored_polygon(d, Color(0.45, 0.75, 1.0))
			c.draw_polyline(d + PackedVector2Array([d[0]]), GOLD, 2.0 * s, true)
		"exit":
			c.draw_circle(p, 8.0 * s, Color(0.3, 0.6, 1.0, 0.9))
			c.draw_arc(p, 10.0 * s, 0, TAU, 24, GOLD, 2.5 * s, true)
			c.draw_circle(p, 3.0 * s, Color(1, 1, 1, 0.9))
		"npc":
			c.draw_circle(p, 8.0 * s, Color(0.1, 0.08, 0.05, 0.9))
			c.draw_arc(p, 8.0 * s, 0, TAU, 20, GOLD, 2.0 * s, true)
			c.draw_circle(p + Vector2(0, -2.5) * s, 2.6 * s, IVORY)
			c.draw_arc(p + Vector2(0, 5) * s, 4.0 * s, PI, TAU, 10, IVORY, 2.0 * s)
		"cache":
			c.draw_rect(Rect2(p - Vector2(7, 5) * s, Vector2(14, 10) * s), Color(0.55, 0.36, 0.16))
			c.draw_rect(Rect2(p - Vector2(7, 5) * s, Vector2(14, 10) * s), GOLD, false, 1.5 * s)
			c.draw_line(p + Vector2(-7, -1) * s, p + Vector2(7, -1) * s, GOLD, 1.5 * s)
		"secret":
			c.draw_circle(p, 7.0 * s, Color(0.55, 0.35, 0.75, 0.9))
			c.draw_arc(p, 9.0 * s, 0, TAU, 20, Color("e0c8ff"), 1.5 * s, true)
		"quest", "quest_done":
			var done: bool = m["kind"] == "quest_done"
			var col := Color(0.55, 0.55, 0.55) if done else Color("f2c14e")
			if m.get("r", 0.0) > 0.0 and label:
				var rr: float = m["r"] * _base_scale() * zoom
				c.draw_arc(p, rr, 0, TAU, 48, Color(col, 0.75), 2.0, true)
				c.draw_circle(p, rr, Color(col, 0.1))
			var d := PackedVector2Array([p + Vector2(0, -11) * s, p + Vector2(9, 0) * s, p + Vector2(0, 11) * s, p + Vector2(-9, 0) * s])
			c.draw_colored_polygon(d, Color(0.08, 0.06, 0.03, 0.95))
			c.draw_polyline(d + PackedVector2Array([d[0]]), col, 2.0 * s, true)
			c.draw_string(font, p + Vector2(-2.6, 5.5) * s, "✓" if done else "!", HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * s), col)
		_:
			c.draw_circle(p, 7.0 * s, Color(0.12, 0.1, 0.07, 0.9))
			c.draw_arc(p, 7.0 * s, 0, TAU, 20, GOLD, 2.0 * s, true)
			c.draw_circle(p, 2.5 * s, GOLD)
	if label and m["kind"] != "hero":
		var q: bool = m["kind"] in ["quest", "quest_done"]
		_text(p + Vector2(0, 30 if q else -16), String(m["name"]), 15, Color("f2c14e") if q else IVORY)   # quest names below

func _draw_world() -> void:
	var wm: Dictionary = world.get("map", {})
	_text(Vector2(area.get_center().x, area.position.y - 18), String(wm.get("title", "World")).to_upper(), 26, GOLD)
	draw_rect(area, Color(0.07, 0.06, 0.045))
	# faint parchment grid
	for i in range(1, 12):
		var x := area.position.x + area.size.x * i / 12.0
		draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), Color(1, 0.9, 0.7, 0.035), 1.0)
	for i in range(1, 8):
		var y := area.position.y + area.size.y * i / 8.0
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(1, 0.9, 0.7, 0.035), 1.0)
	var pos := {}
	for n in wm.get("nodes", []):
		pos[n["id"]] = area.position + Vector2(float(n["at"][0]), float(n["at"][1])) * area.size
	for l in wm.get("links", []):
		if not (pos.has(l[0]) and pos.has(l[1])): continue
		var known := is_discovered(l[0]) and is_discovered(l[1])
		_dashed(pos[l[0]], pos[l[1]], Color(GOLD, 0.8) if known else Color(0.6, 0.55, 0.45, 0.35), 3.0 if known else 2.0)
	world_nodes.clear()
	var here := world_id_of(current_zone_id())
	var quest_nodes := {}
	for q in active_quests():
		if quest_done(q): continue
		for m in q.get("markers", []): quest_nodes[world_id_of(String(m["zone"]))] = true
	for n in wm.get("nodes", []):
		var c: Vector2 = pos[n["id"]]
		var known: bool = is_discovered(String(n["id"])) and not bool(n.get("locked", false))
		var col := GOLD if known else Color(0.45, 0.42, 0.38)
		draw_circle(c, 34.0, Color(0.1, 0.085, 0.06, 0.97))
		draw_arc(c, 34.0, 0, TAU, 48, col, 3.0, true)
		draw_arc(c, 28.0, 0, TAU, 48, Color(col, 0.5), 1.0, true)
		_node_icon(String(n.get("kind", "")) if known else "unknown", c, col)
		_text(c + Vector2(0, 56), String(n["name"]) if known else "???", 19, IVORY if known else Color(0.6, 0.58, 0.55))
		# every reachable zone shows its level range (an undiscovered one too, so the player can judge the danger)
		if n.has("levels") and not bool(n.get("locked", false)):
			_text(c + Vector2(0, 78), String(n["levels"]), 16, Color("d9b46a") if known else Color(0.7, 0.62, 0.48), false)
		if n["id"] == here:
			draw_arc(c, 42.0, 0, TAU, 48, Color("f2d27a"), 2.5, true)
			_draw_marker({"kind": "hero", "angle": -PI * 0.5}, c + Vector2(0, -50), false)
			_text(c + Vector2(0, -66), "You are here", 14, Color("f2d27a"))
		if quest_nodes.has(n["id"]) and known:
			_draw_marker({"kind": "quest", "name": ""}, c + Vector2(30, -26), false)
		var sub := String(n.get("blurb", "")) if known else "Not yet discovered."
		var wps := _waypoint_count(String(n["id"]))
		if known and wps.y > 0: sub += "\nWaypoints: %d / %d" % [wps.x, wps.y]
		var entry := {"centre": c, "node": n, "sub": sub}
		var zid := _zone_for_world(String(n["id"]))
		if known and zid != "": entry["zone"] = zid
		world_nodes.append(entry)
	draw_rect(area, GOLD_DIM, false, 1.5)
	_text(area.end - Vector2(12, 12), "Click a discovered zone to open its map", 14, Color("a8977a"), false, HORIZONTAL_ALIGNMENT_RIGHT)

func _zone_for_world(wid: String) -> String:
	if world_id_of(current_zone_id()) == wid: return current_zone_id()
	for zid in explored:
		if world_id_of(zid) == wid: return zid
	return wid if FileAccess.file_exists("res://assets/zones/%s.json" % wid) else ""

func _waypoint_count(wid: String) -> Vector2i:
	var zid := _zone_for_world(wid)
	if zid == "": return Vector2i.ZERO
	var n := 0; var have := 0
	for w in zone_data(zid).get("waypoints", []):
		n += 1
		if lab.waypoint_net != null and lab.waypoint_net.is_unlocked(String(w["id"])): have += 1
	return Vector2i(have, n)

func _node_icon(kind: String, c: Vector2, col: Color) -> void:
	match kind:
		"town":   # crown
			var pts := PackedVector2Array([c + Vector2(-15, 9), c + Vector2(-15, -6), c + Vector2(-8, 2), c + Vector2(0, -11), c + Vector2(8, 2), c + Vector2(15, -6), c + Vector2(15, 9)])
			draw_colored_polygon(pts, col)
		"forest": # two trees
			for o in [Vector2(-7, 2), Vector2(7, -2)]:
				draw_colored_polygon(PackedVector2Array([c + o + Vector2(0, -15), c + o + Vector2(9, 5), c + o + Vector2(-9, 5)]), col)
				draw_rect(Rect2(c + o + Vector2(-1.5, 5), Vector2(3, 6)), col)
		"marsh":  # reeds over water
			for i in 3: draw_line(c + Vector2(-8 + i * 8, 8), c + Vector2(-10 + i * 9, -12), col, 2.5)
			draw_line(c + Vector2(-14, 10), c + Vector2(14, 10), col, 2.0)
		_:
			_text(c + Vector2(0, 10), "?", 30, col)

func _dashed(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var L := a.distance_to(b); var n := int(L / 14.0)
	for i in n:
		if i % 2 == 0: draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), col, w, true)

func _draw_side() -> void:
	draw_rect(side, Color(0.06, 0.05, 0.045, 0.95))
	draw_rect(side, GOLD_DIM, false, 1.5)
	var y := side.position.y + 30
	_text(Vector2(side.position.x + 16, y), "QUESTS", 19, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT); y += 12
	for q in active_quests():
		y += 26
		var done := quest_done(q)
		_text(Vector2(side.position.x + 16, y), ("✓  " if done else "◆  ") + String(q["name"]), 16, Color(0.6, 0.6, 0.6) if done else Color("e8b85c"), true, HORIZONTAL_ALIGNMENT_LEFT)
		y += 21
		var obj := String(q["objective"]) + ((" (%d/%d)" % [quest_progress(q), int(q["count"])]) if int(q.get("count", 0)) > 0 else "")
		_text(Vector2(side.position.x + 34, y), obj, 14, Color("cfc7b8"), false, HORIZONTAL_ALIGNMENT_LEFT)
		var zs := {}
		for m in q.get("markers", []): zs[world_id_of(String(m["zone"]))] = true
		var where := []
		for wid in zs:
			for n in world.get("map", {}).get("nodes", []):
				if n["id"] == wid: where.append(String(n["name"]))
		if where.is_empty(): continue
		y += 19
		_text(Vector2(side.position.x + 34, y), "In: " + ", ".join(where), 13, Color("a8977a"), false, HORIZONTAL_ALIGNMENT_LEFT)
	y += 42
	_text(Vector2(side.position.x + 16, y), "LEGEND", 19, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT); y += 8
	for e in [["hero", "You"], ["waypoint", "Waypoint (discovered)"], ["exit", "Zone exit"], ["quest", "Quest objective"], ["npc", "Character"], ["landmark", "Point of interest"], ["cache", "Cache"], ["secret", "Secret (once found)"]]:
		y += 30
		_draw_marker({"kind": e[0], "name": "", "angle": -PI * 0.5}, Vector2(side.position.x + 30, y - 5), false, 0.9)
		_text(Vector2(side.position.x + 52, y), e[1], 15, IVORY, false, HORIZONTAL_ALIGNMENT_LEFT)

func _draw_tooltip() -> void:
	var at: Vector2 = hover["screen"] if hover.has("screen") else px_to_screen(hover["at"])
	var lines: Array = [String(hover["name"])]
	for l in String(hover.get("sub", "")).split("\n"):
		if l != "": lines.append(l)
	var w := 0.0
	for i in lines.size(): w = maxf(w, (font if i == 0 else font_regular).get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16 if i == 0 else 14).x)
	var r := Rect2(at + Vector2(18, -10), Vector2(w + 24, 14 + 22 * lines.size()))
	if r.end.x > get_viewport_rect().size.x - 10: r.position.x = at.x - 18 - r.size.x
	draw_rect(r, Color(0.04, 0.035, 0.03, 0.96))
	draw_rect(r, GOLD, false, 1.5)
	for i in lines.size():
		_text(r.position + Vector2(12, 26 + 22 * i), lines[i], 16 if i == 0 else 14, GOLD if i == 0 else Color("cfc7b8"), i == 0, HORIZONTAL_ALIGNMENT_LEFT)
