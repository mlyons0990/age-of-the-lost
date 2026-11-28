extends Node3D
## Runtime 3D prototype FX: mesh-based sword arcs, expanding rings and sparks.
## All are code-generated, no external image or shader dependencies.

func _glow(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 2.8
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _vanish(node: MeshInstance3D, lifetime: float) -> void:
	var tw := create_tween()
	tw.tween_property(node, "transparency", 1.0, lifetime)
	tw.tween_callback(node.queue_free)

func ring(at: Vector3, radius: float, color: Color, duration := 0.5) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 64:
		var a := float(i) * TAU / 64.0
		var b := float(i + 1) * TAU / 64.0
		var thick := 0.05
		var a0 := Vector3(cos(a) * radius, 0.0, sin(a) * radius)
		var a1 := Vector3(cos(a) * (radius + thick), 0.0, sin(a) * (radius + thick))
		var b0 := Vector3(cos(b) * radius, 0.0, sin(b) * radius)
		var b1 := Vector3(cos(b) * (radius + thick), 0.0, sin(b) * (radius + thick))
		for v in [a0, a1, b1, a0, b1, b0]:
			mesh.surface_add_vertex(v)
	mesh.surface_end()
	var o := MeshInstance3D.new()
	o.mesh = mesh
	o.material_override = _glow(color)
	o.position = at + Vector3.UP * 0.07
	add_child(o)
	var tw := create_tween()
	tw.tween_property(o, "scale", Vector3(1.6, 1.0, 1.6), duration)
	tw.parallel().tween_property(o, "transparency", 1.0, duration)
	tw.tween_callback(o.queue_free)

func slash(at: Vector3, facing: Vector3, color: Color, wide := false) -> void:
	var radius := 1.75 if wide else 1.2
	var half := 1.8 if wide else 1.05
	var f := atan2(facing.x, -facing.z)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 40:
		var a := -half + float(i) * (2.0 * half) / 40.0 + f
		var b := -half + float(i + 1) * (2.0 * half) / 40.0 + f
		var t := 0.18
		var p0 := Vector3(sin(a) * (radius - t), 0, -cos(a) * (radius - t))
		var p1 := Vector3(sin(a) * (radius + t), 0, -cos(a) * (radius + t))
		var q0 := Vector3(sin(b) * (radius - t), 0, -cos(b) * (radius - t))
		var q1 := Vector3(sin(b) * (radius + t), 0, -cos(b) * (radius + t))
		for v in [p0, p1, q1, p0, q1, q0]:
			mesh.surface_add_vertex(v)
	mesh.surface_end()
	var o := MeshInstance3D.new()
	o.mesh = mesh
	o.material_override = _glow(color)
	o.position = at + Vector3.UP * 1.05
	add_child(o)
	var tw := create_tween()
	tw.tween_property(o, "scale", Vector3(1.15, 1.15, 1.15), 0.27)
	tw.parallel().tween_property(o, "transparency", 1.0, 0.27)
	tw.tween_callback(o.queue_free)
	sparks(at + facing.normalized() * 1.0 + Vector3.UP * 1.05, color, 13 if wide else 7)

func sparks(at: Vector3, color: Color, number := 16) -> void:
	for i in number:
		var sphere := SphereMesh.new()
		sphere.radius = randf_range(0.025, 0.075)
		sphere.height = 2.0 * sphere.radius
		var m := MeshInstance3D.new()
		m.mesh = sphere
		m.material_override = _glow(color.lerp(Color.WHITE, randf_range(0, 0.5)))
		m.position = at
		add_child(m)
		var direction := Vector3(randf_range(-1.0, 1.0), randf_range(-0.2, 1.0), randf_range(-1.0, 1.0)).normalized()
		var end := at + direction * randf_range(0.4, 1.2)
		var life := randf_range(0.2, 0.5)
		var tw := create_tween()
		tw.tween_property(m, "position", end, life).set_trans(Tween.TRANS_CUBIC)
		tw.parallel().tween_property(m, "transparency", 1.0, life)
		tw.tween_callback(m.queue_free)

func cast(at: Vector3, color: Color) -> void:
	ring(at, 0.65, color, 0.65)
	for i in 3:
		ring(at + Vector3.UP * (0.3 + i * 0.35), 0.24 + i * 0.16, color, 0.4 + i * 0.12)
	sparks(at + Vector3.UP * 1.3, color, 30)

## A straight beam (lorecast spears, lances): a glowing bar from `at` along `dir`, fading out.
func beam(at: Vector3, dir: Vector3, length: float, width: float, color: Color, duration := 0.35) -> void:
	var o := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(width, 0.18, length)
	o.mesh = bm
	o.material_override = _glow(color)
	add_child(o)
	var d := Vector3(dir.x, 0, dir.z).normalized()
	o.global_position = at + d * (length * 0.5) + Vector3.UP * 0.9
	o.look_at(o.global_position + d, Vector3.UP)
	var tw := create_tween()
	tw.tween_property(o, "scale", Vector3(0.2, 0.2, 1.0), duration)
	tw.parallel().tween_property(o, "transparency", 1.0, duration)
	tw.tween_callback(o.queue_free)
