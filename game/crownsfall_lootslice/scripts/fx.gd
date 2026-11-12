extends Node2D
## Combat effects. One script, three layers created by main.gd:
##   GROUND    - rings, slashes, blast circles drawn flat on the floor (additive)
##   PARTICLES - sparks and embers above everything (additive)
##   TEXT      - floating damage numbers

const GD := preload("res://scripts/game_data.gd")
enum { GROUND, PARTICLES, TEXT }

var mode := GROUND
var items: Array = []
var main: Node2D


func _ready() -> void:
	if mode != TEXT:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m


func _process(delta: float) -> void:
	var i := items.size() - 1
	while i >= 0:
		var f: Dictionary = items[i]
		f["t"] += delta
		if mode == PARTICLES:
			var v: Vector2 = f["vel"]
			if f.has("drag"):
				v *= pow(0.1, delta * float(f["drag"]))
				f["vel"] = v
			f["pos"] += GD.to_px(v) * delta
			f["z"] += f["vz"] * delta
			f["vz"] -= f["g"] * delta
			if f["z"] < 0.0:
				f["z"] = 0.0
				f["vz"] *= -0.3
		elif mode == TEXT:
			f["z"] += delta * 90.0
		elif f.get("kind", "") == "hammer" and not f["done"] and f["t"] >= f["delay"]:
			f["done"] = true
			var cb: Callable = f["on_hit"]
			cb.call()
		if f["t"] >= f["life"]:
			items.remove_at(i)
		i -= 1
	queue_redraw()


# ---------------------------------------------------------------- spawners
func ring(at: Vector2, r0: float, r1: float, life: float, color: Color, fill := false, width := 0.16) -> void:
	items.append({"kind": "ring", "pos": at, "r0": r0, "r1": r1, "life": life, "t": 0.0, "color": color, "fill": fill,"width":width})


func slash(at: Vector2, ang: float, r: float, arc: float, life: float, color: Color, width: float) -> void:
	items.append({"kind": "slash", "pos": at, "ang": ang, "r": r, "arc": arc, "life": life, "t": 0.0, "color": color, "w": width})


func hammer(at: Vector2, r: float, delay: float, c1: Color, c2: Color, on_hit: Callable) -> void:
	items.append({"kind": "hammer", "pos": at, "r": r, "delay": delay, "life": delay + 0.5, "t": 0.0, "c1": c1, "c2": c2, "done": false, "on_hit": on_hit})


func pillar(at: Vector2, life: float, color: Color) -> void:
	items.append({"kind": "pillar", "pos": at, "life": life, "t": 0.0, "color": color})


func burst(at: Vector2, n: int, colors: Array, speed := 4.0, z := 60.0, size := 5.0, life := 0.9) -> void:
	for i in n:
		var a := randf() * TAU
		var s := randf_range(1.0, speed)
		spark(at, Vector2(cos(a), sin(a)) * s, z, randf_range(40.0, 240.0), 480.0, randf_range(0.4, life), colors[randi() % colors.size()], randf_range(size * 0.5, size))


func spark(at: Vector2, vel: Vector2, z: float, vz: float, g: float, life: float, color: Color, size: float, drag := 0.0) -> void:
	var p := {"pos": at, "vel": vel, "z": z, "vz": vz, "g": g, "life": life, "t": 0.0, "color": color, "size": size}
	if drag > 0.0:
		p["drag"] = drag
	items.append(p)


func text(at: Vector2, s: String, color: Color, big := false) -> void:
	items.append({"pos": at + Vector2(randf_range(-14, 14), 0), "z": 150.0 if big else 130.0, "str": s, "color": color, "big": big, "life": 1.2 if big else 0.9, "t": 0.0})


# ---------------------------------------------------------------- drawing
func _draw() -> void:
	match mode:
		GROUND:
			_draw_ground()
		PARTICLES:
			for p in items:
				var k: float = 1.0 - p["t"] / p["life"]
				var c: Color = p["color"]
				c.a = maxf(0.0, k)
				draw_circle(p["pos"] - Vector2(0, p["z"]), float(p["size"]) * (0.5 + 0.5 * k), c)
		TEXT:
			var font := ThemeDB.fallback_font
			for t in items:
				var size: int = 38 if t["big"] else 26
				var a: float = minf(1.0, (t["life"] - t["t"]) * 2.5)
				var pos: Vector2 = t["pos"] - Vector2(0, t["z"])
				var s: String = t["str"]
				var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
				var c: Color = t["color"]
				c.a = a
				draw_string_outline(font, pos - Vector2(w / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 8, Color(0, 0, 0, 0.85 * a))
				draw_string(font, pos - Vector2(w / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)


func _draw_ground() -> void:
	var u := GD.U
	if main != null and main.rift["active"]:
		draw_set_transform(main.RIFT_POS, 0.0, Vector2(1.0, GD.SQ))
		var now := Time.get_ticks_msec() / 1000.0
		draw_circle(Vector2.ZERO, 1.7 * u, Color(0.45, 0.25, 1.0, 0.16))
		draw_circle(Vector2.ZERO, 0.9 * u, Color(0.6, 0.35, 1.0, 0.18))
		for i in 4:
			var dir := -1.0 if i % 2 == 1 else 1.0
			var a := now * dir * (0.6 + i * 0.2)
			var col := Color(0.48, 0.3, 1.0, 0.7) if i % 2 == 1 else Color(0.85, 0.72, 1.0, 0.7)
			draw_arc(Vector2.ZERO, (0.7 + i * 0.42 + 0.08 * sin(now * 2.0 + i)) * u, a, a + 4.4, 40, col, 4.0, true)
	for f in items:
		var k: float = f["t"] / f["life"]
		draw_set_transform(f["pos"], 0.0, Vector2(1.0, GD.SQ))
		match f["kind"]:
			"ring":
				var r: float = lerpf(f["r0"], f["r1"], 1.0 - pow(1.0 - k, 2.0)) * u
				var c: Color = f["color"]
				c.a = 1.0 - k
				draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, c, float(f.get("width",0.16)) * u, true)
				if f["fill"]:
					c.a = (1.0 - k) * 0.25
					draw_circle(Vector2.ZERO, r, c)
			"slash":
				var arc: float = f["arc"]
				var a0: float = f["ang"] - arc / 2.0
				var sweep: float = arc * minf(1.0, k * 1.6)
				var r1: float = f["r"] * u
				var r0: float = r1 * (1.0 - float(f["w"]))
				var pts := PackedVector2Array()
				var n := 18
				for i in n + 1:
					var a: float = a0 + sweep * i / n
					pts.append(Vector2(cos(a), sin(a)) * r1)
				for i in n + 1:
					var a: float = a0 + sweep * (n - i) / n
					pts.append(Vector2(cos(a), sin(a)) * r0)
				var c: Color = f["color"]
				c.a = (1.0 - k) * 0.75
				if sweep > 0.05:
					draw_colored_polygon(pts, c)
					draw_arc(Vector2.ZERO, r1, a0, a0 + sweep, 24, Color(1, 1, 1, (1.0 - k)), 3.0, true)
			"hammer":
				var r: float = f["r"] * u
				if f["t"] < f["delay"]:
					var q: float = f["t"] / f["delay"]
					var c2: Color = f["c2"]
					c2.a = 0.8
					draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, c2, 5.0, true)
					var c1: Color = f["c1"]
					c1.a = 0.25
					draw_circle(Vector2.ZERO, r * q, c1)
				else:
					var q: float = (f["t"] - f["delay"]) / (f["life"] - f["delay"])
					var c2: Color = f["c2"]
					c2.a = (1.0 - q) * 0.6
					draw_circle(Vector2.ZERO, r * (1.0 + q * 0.6), c2)
					draw_circle(Vector2.ZERO, r * 0.5 * (1.0 + q), Color(1, 1, 1, (1.0 - q) * 0.8))
			"pillar":
				draw_set_transform(f["pos"], 0.0, Vector2.ONE)
				var c: Color = f["color"]
				var w: float = 24.0 * (1.0 - k * 0.5)
				var top := Color(c.r, c.g, c.b, 0.0)
				c.a = (1.0 - k) * 0.16
				draw_polygon(PackedVector2Array([Vector2(-w, 0), Vector2(w, 0), Vector2(w, -300), Vector2(-w, -300)]), PackedColorArray([c, c, top, top]))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
