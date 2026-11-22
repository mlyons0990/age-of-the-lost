extends RefCounted
## Real 3D waypoint platform (owner: "uniform around the entire circumference"). Geometry is exact and symmetric:
## an eight-point star base, a stone step disc, the gold filigree rim ring and a recessed basin. Every top face is
## textured from one top-down painting (tools/build_waypoint_topdown.py: the approved WP1-A art, un-tilted, one
## mirrored wedge repeated 8x), so the art lines up across all layers. Side walls are stone, shaded from the painted
## light (upper left). Because it is real geometry it lies flat at any camera angle and needs no offsets.

# radii as a fraction of the star-tip radius (measured from the top-down texture) and heights in metres per metre of
# tip radius (low inlaid dais: flush with the painted floor, owner 11-22)
const STAR_VALLEY := 0.62
const DISC_R := 0.77
const RIM_R := 0.535
const BASIN_R := 0.455
const H_STAR := 0.010
const H_DISC := 0.022
const H_RIM := 0.036
const H_BASIN := 0.028
const SEG := 96
const LIGHT := Vector3(-0.55, 0.0, -0.55)       # painted light from the upper left (screen), i.e. -x, -z

static func build(radius_m: float, top_tex: Texture2D) -> Node3D:
	var root := Node3D.new()
	root.name = "Platform"
	var top := SurfaceTool.new(); top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side := SurfaceTool.new(); side.begin(Mesh.PRIMITIVE_TRIANGLES)
	var R := radius_m
	# outlines (xz, unit radius)
	var star := PackedVector2Array()
	for i in 16:
		var a := -PI / 2.0 + TAU * float(i) / 16.0
		var r := 1.0 if i % 2 == 0 else STAR_VALLEY
		star.append(Vector2(cos(a), sin(a)) * r)
	var star_dense := _densify(star, 6)
	var disc := _circle(DISC_R); var rim := _circle(RIM_R); var basin := _circle(BASIN_R)
	# tops (planar UV from the top-down texture)
	_fan(top, star_dense, H_STAR, R)
	_fan(top, disc, H_DISC, R)
	_ring(top, rim, basin, H_RIM, R)          # rim ring top
	_fan(top, basin, H_BASIN, R)              # recessed basin floor
	# walls
	_wall(side, star_dense, 0.0, H_STAR, R, Color("b9a88f"), true)
	_wall(side, disc, H_STAR, H_DISC, R, Color("d8ccb8"), false)
	_wall(side, rim, H_DISC, H_RIM, R, Color("c9a55e"), false)   # gilded rim edge
	_wall(side, basin, H_BASIN, H_RIM, R, Color("b8ab96"), false, true)  # inner wall of the basin, facing in
	var tm := StandardMaterial3D.new()
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.albedo_texture = top_tex
	tm.cull_mode = BaseMaterial3D.CULL_DISABLED
	tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.vertex_color_use_as_albedo = true
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mt := MeshInstance3D.new(); mt.name = "Top"; mt.mesh = top.commit(); mt.material_override = tm
	var ms := MeshInstance3D.new(); ms.name = "Sides"; ms.mesh = side.commit(); ms.material_override = sm
	for m in [mt, ms]:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(m)
	# soft contact shadow under the platform
	var sh := MeshInstance3D.new(); sh.name = "ContactShadow"
	var q := PlaneMesh.new(); q.size = Vector2(R * 2.1, R * 2.1); sh.mesh = q
	var shm := ShaderMaterial.new()
	var sd := Shader.new()
	sd.code = "shader_type spatial; render_mode unshaded, blend_mix, depth_draw_never;\nvoid fragment(){ vec2 p = UV * 2.0 - 1.0 - vec2(0.02, 0.03); float r = length(p); ALBEDO = vec3(0.07,0.06,0.05); ALPHA = 0.22 * smoothstep(0.98, 0.80, r); }"
	shm.shader = sd
	sh.material_override = shm
	sh.position.y = 0.004
	sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(sh)
	return root

static func set_top(root: Node3D, tex: Texture2D) -> void:
	((root.get_node("Top") as MeshInstance3D).material_override as StandardMaterial3D).albedo_texture = tex

static func _circle(r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in SEG:
		var a := -PI / 2.0 + TAU * float(i) / float(SEG)
		p.append(Vector2(cos(a), sin(a)) * r)
	return p

static func _densify(poly: PackedVector2Array, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in poly.size():
		var a := poly[i]; var b := poly[(i + 1) % poly.size()]
		for k in n: out.append(a.lerp(b, float(k) / float(n)))
	return out

static func _uv(p: Vector2) -> Vector2:
	return Vector2(p.x * 0.5 + 0.5, p.y * 0.5 + 0.5)

static func _v(st: SurfaceTool, p: Vector2, h: float, R: float) -> void:
	st.set_uv(_uv(p)); st.add_vertex(Vector3(p.x * R, h * R, p.y * R))

static func _fan(st: SurfaceTool, poly: PackedVector2Array, h: float, R: float) -> void:
	for i in poly.size():
		_v(st, Vector2.ZERO, h, R); _v(st, poly[(i + 1) % poly.size()], h, R); _v(st, poly[i], h, R)

static func _ring(st: SurfaceTool, outer: PackedVector2Array, inner: PackedVector2Array, h: float, R: float) -> void:
	for i in outer.size():
		var j := (i + 1) % outer.size()
		_v(st, outer[i], h, R); _v(st, inner[i], h, R); _v(st, outer[j], h, R)
		_v(st, outer[j], h, R); _v(st, inner[i], h, R); _v(st, inner[j], h, R)

static func _wall(st: SurfaceTool, poly: PackedVector2Array, h0: float, h1: float, R: float, base: Color, gilt_top: bool, inward := false) -> void:
	var n := poly.size()
	for i in n:
		var a := poly[i]; var b := poly[(i + 1) % n]
		var edge := (b - a)
		var nrm := Vector2(edge.y, -edge.x).normalized()
		if inward: nrm = -nrm
		var lit := clampf(0.78 + 0.32 * nrm.dot(Vector2(LIGHT.x, LIGHT.z).normalized()), 0.45, 1.1)
		var c := Color(base.r * lit, base.g * lit, base.b * lit)
		var ct := Color("e2b866") * lit if gilt_top else c
		var A0 := Vector3(a.x * R, h0 * R, a.y * R); var B0 := Vector3(b.x * R, h0 * R, b.y * R)
		var A1 := Vector3(a.x * R, h1 * R, a.y * R); var B1 := Vector3(b.x * R, h1 * R, b.y * R)
		var tri := [[A0, c], [A1, ct], [B0, c], [B0, c], [A1, ct], [B1, ct]] if not inward else [[A0, c], [B0, c], [A1, ct], [B0, c], [B1, ct], [A1, ct]]
		for t in tri:
			st.set_color(t[1]); st.add_vertex(t[0])
