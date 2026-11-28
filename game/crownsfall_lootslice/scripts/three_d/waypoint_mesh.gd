extends RefCounted
## Real 3D waypoint platform (owner: "uniform around the entire circumference"). Geometry is exact and symmetric:
## an eight-point star base, a stone step disc, the gold filigree rim ring and a recessed basin. Every top face is
## textured from one top-down painting (tools/build_waypoint_topdown.py: the approved WP1-A art, un-tilted, one
## mirrored wedge repeated 8x), so the art lines up across all layers. Side walls are stone, shaded from the painted
## light (upper left). Because it is real geometry it lies flat at any camera angle and needs no offsets.

# radii as a fraction of the star-tip radius (measured from the top-down texture) and heights in metres per metre of
# tip radius: proportions measured from the approved WP1-A painting (tiers ~0.07 R each; art seen at 60 deg)
const STAR_VALLEY := 0.62
const DISC_R := 0.77
const BAND_R := 0.72       # second stone step; its top carries the gold filigree band (top tier)
const BASIN_R := 0.455
const H_STAR := 0.045
const H_DISC := 0.120
const H_BAND := 0.195
const H_BASIN := 0.140
const SEG := 96
const BLOCK_M := 0.32        # stone block length along the wall, in units of tip radius
## Step walls: cut stone blocks (vertical seams, worn edges, darker foot, lit lip) like the painted original.
const WALL_SHADER := """shader_type spatial;
render_mode unshaded, cull_disabled;
float h(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p){ vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
  return mix(mix(h(i), h(i+vec2(1,0)), f.x), mix(h(i+vec2(0,1)), h(i+vec2(1,1)), f.x), f.y); }
void fragment(){
  float gilt = COLOR.a < 0.5 ? 1.0 : 0.0;
  float u = UV.x; float v = UV.y;
  float blk = floor(u);
  float seam = smoothstep(0.0, 0.035, fract(u)) * smoothstep(1.0, 0.965, fract(u));
  float tint = 0.9 + 0.18 * h(vec2(blk, 3.0));
  float wear = 0.82 + 0.28 * n(vec2(u * 6.0, v * 3.0));
  float grad = mix(0.58, 1.08, smoothstep(0.0, 1.0, v));
  float lip = smoothstep(0.86, 0.97, v) * 0.22;
  vec3 c = COLOR.rgb * tint * wear * grad + lip;
  c *= mix(0.55, 1.0, mix(seam, 1.0, gilt));
  ALBEDO = clamp(c, 0.0, 1.0);
}"""
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
	var disc := _circle(DISC_R); var band := _circle(BAND_R); var basin := _circle(BASIN_R)
	# tops (planar UV from the top-down texture). Order as in the approved painting, outer -> inner:
	# star base, stone step, stone step whose top is the gold filigree band (highest tier), recessed rune basin
	_fan(top, star_dense, H_STAR, R)
	_ring(top, disc, band, H_DISC, R)
	_ring(top, band, basin, H_BAND, R)
	_fan(top, basin, H_BASIN, R)
	# walls
	_wall(side, star_dense, 0.0, H_STAR, R, Color("d9a64e"), true)       # gilded star edge
	_wall(side, disc, H_STAR, H_DISC, R, Color("d8c6ab"), false)          # warm ivory stone step 1
	_wall(side, band, H_DISC, H_BAND, R, Color("dccbb0"), false)          # warm ivory stone step 2
	_wall(side, basin, H_BASIN, H_BAND, R, Color("b3a28a"), false, true)  # basin inner wall
	var tm := StandardMaterial3D.new()
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.albedo_texture = top_tex
	tm.cull_mode = BaseMaterial3D.CULL_DISABLED
	tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var sm := ShaderMaterial.new()
	var wsd := Shader.new()
	wsd.code = WALL_SHADER
	sm.shader = wsd
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
	sd.code = "shader_type spatial; render_mode unshaded, blend_mix, depth_draw_never;\nvoid fragment(){ vec2 p = UV * 2.0 - 1.0 - vec2(0.02, 0.03); float r = length(p); ALBEDO = vec3(0.07,0.06,0.05); ALPHA = 0.32 * smoothstep(1.0, 0.80, r); }"
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

static func _wall(st: SurfaceTool, poly: PackedVector2Array, h0: float, h1: float, R: float, base: Color, gilt: bool, inward := false) -> void:
	var n := poly.size()
	var run := 0.0
	for i in n:
		var a := poly[i]; var b := poly[(i + 1) % n]
		var edge := (b - a)
		var nrm := Vector2(edge.y, -edge.x).normalized()
		if inward: nrm = -nrm
		var lit := clampf(0.80 + 0.30 * nrm.dot(Vector2(LIGHT.x, LIGHT.z).normalized()), 0.5, 1.1)
		var c := Color(base.r * lit, base.g * lit, base.b * lit, 0.0 if gilt else 1.0)
		var u0 := run / BLOCK_M; run += edge.length(); var u1 := run / BLOCK_M
		var A0 := Vector3(a.x * R, h0 * R, a.y * R); var B0 := Vector3(b.x * R, h0 * R, b.y * R)
		var A1 := Vector3(a.x * R, h1 * R, a.y * R); var B1 := Vector3(b.x * R, h1 * R, b.y * R)
		var tri := [[A0, Vector2(u0, 0)], [A1, Vector2(u0, 1)], [B0, Vector2(u1, 0)], [B0, Vector2(u1, 0)], [A1, Vector2(u0, 1)], [B1, Vector2(u1, 1)]]
		for t in tri:
			st.set_color(c); st.set_uv(t[1]); st.add_vertex(t[0])
