extends Node3D
## Phase 4 groundwork: "Hollow Sun" radiant spell FX, modelled on the user's
## Hollow Sun Arbiter reference (gold/white compass-star sigils, crescent light
## arcs, four-point starbursts, faint violet accents). Fully procedural:
## inline shaders + generated meshes, no textures, no paid assets.

const GOLD := Color(1.0, 0.76, 0.32)
const CORE := Color(1.0, 0.97, 0.86)
const VIOLET := Color(0.58, 0.42, 1.0)

const SIGIL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 gold : source_color = vec4(1.0, 0.76, 0.32, 1.0);
uniform vec4 core : source_color = vec4(1.0, 0.97, 0.86, 1.0);
uniform vec4 violet : source_color = vec4(0.58, 0.42, 1.0, 1.0);
uniform float intensity = 1.0;
uniform float spin = 0.0;
uniform float reveal = 1.0;
float band(float x, float c, float w) { return smoothstep(w, 0.0, abs(x - c)); }
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float asp = a + spin;
	float v = 0.0;
	// concentric rings
	v += band(r, 0.96, 0.022) * 1.3 + band(r, 0.885, 0.012) + band(r, 0.58, 0.016) + band(r, 0.33, 0.012);
	// fine ticks between the two outer rings (spin)
	float tk = step(0.885, r) * step(r, 0.96) * band(fract(asp * 48.0 / TAU), 0.5, 0.08);
	v += tk * 0.7;
	// runic dash ring (counter-spin)
	float seg = fract((a - spin * 1.6) * 16.0 / TAU);
	v += step(0.70, r) * step(r, 0.745) * step(0.12, seg) * step(seg, 0.62) * 0.55;
	// small diamonds on the 0.815 ring
	float dseg = fract(asp * 8.0 / TAU) - 0.5;
	v += smoothstep(0.035, 0.0, abs(dseg) * 0.55 + abs(r - 0.815)) * 1.2;
	// eight-point compass star: long cardinals, short diagonals
	float star = 0.0;
	float fill = 0.0;
	for (int k = 0; k < 8; k++) {
		float ang = float(k) * TAU / 8.0;
		float d = atan(sin(a - ang), cos(a - ang));
		bool cardinal = (k % 2) == 0;
		float len = cardinal ? 1.0 : 0.66;
		float w = cardinal ? 0.24 : 0.17;
		float edge = r - len * (1.0 - abs(d) / w);
		float inside = step(edge, 0.0) * step(abs(d), w);
		star += band(edge, 0.0, 0.022) * 1.4 * step(abs(d), w) * step(r, len);
		star += band(d * r, 0.0, 0.010) * step(r, len) * (cardinal ? 1.0 : 0.6);
		fill = max(fill, inside * (cardinal ? 0.55 : 0.38) * (1.0 - r / len * 0.7));
	}
	v += star + fill;
	float glow = exp(-r * r * 28.0) * 1.4;
	float halo = exp(-pow(r - 0.96, 2.0) * 900.0) * 0.4;
	float mask = step(r, 1.0) * smoothstep(reveal + 0.02, reveal - 0.06, r);
	float lum = clamp(v + glow + halo, 0.0, 3.0) * mask * intensity;
	vec3 col = mix(gold.rgb, core.rgb, clamp(glow + star * 0.35, 0.0, 1.0));
	col += violet.rgb * band(r, 0.70, 0.07) * 0.25;
	ALBEDO = col * lum;
	ALPHA = clamp(lum, 0.0, 1.0);
}
"""

const CRESCENT_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 gold : source_color = vec4(1.0, 0.76, 0.32, 1.0);
uniform vec4 core : source_color = vec4(1.0, 0.97, 0.86, 1.0);
uniform vec4 violet : source_color = vec4(0.58, 0.42, 1.0, 1.0);
uniform float progress = 1.0;
uniform float tail = 0.75;
uniform float intensity = 1.0;
void fragment() {
	float u = UV.x;
	float t = progress - u;
	float alive = step(0.0, t) * step(t, tail);
	float k = clamp(1.0 - t / tail, 0.0, 1.0);
	float across = UV.y;
	// crescent: thick near the head, tapering towards the tail; outer edge stays sharp
	float width = 0.15 + 0.85 * k * k;
	float body = smoothstep(1.0 - width, 1.0 - width * 0.7, across) * smoothstep(1.0, 0.94, across);
	float edge = smoothstep(0.82, 0.97, across) * smoothstep(1.0, 0.965, across);
	float head = exp(-pow(t * 18.0, 2.0));
	float lum = (body * (0.7 + 1.1 * k) + edge * 1.6 * k + head * 1.5 * body) * alive * intensity;
	vec3 col = mix(gold.rgb, core.rgb, clamp(edge * k + head, 0.0, 1.0));
	col = mix(col, violet.rgb, (1.0 - k) * 0.35 * (1.0 - edge));
	ALBEDO = col * lum;
	ALPHA = clamp(lum, 0.0, 1.0);
}
"""

const STAR_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 gold : source_color = vec4(1.0, 0.76, 0.32, 1.0);
uniform vec4 core : source_color = vec4(1.0, 0.97, 0.86, 1.0);
uniform float intensity = 1.0;
uniform float twist = 0.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float c = cos(twist), s = sin(twist);
	p = mat2(vec2(c, -s), vec2(s, c)) * p;
	float r = length(p);
	float cross4 = 0.010 / (abs(p.x * p.y) + 0.010) * (1.0 - r);
	vec2 q = mat2(vec2(0.7071, -0.7071), vec2(0.7071, 0.7071)) * p;
	float diag = 0.004 / (abs(q.x * q.y) + 0.006) * (1.0 - r * 1.8);
	float lum = (max(cross4, 0.0) + max(diag, 0.0) * 0.5 + exp(-r * r * 60.0)) * step(r, 1.0) * intensity;
	ALBEDO = mix(gold.rgb, core.rgb, clamp(lum - 0.3, 0.0, 1.0)) * lum;
	ALPHA = clamp(lum, 0.0, 1.0);
}
"""

static var _shaders := {}

static func _shader(key: String, code: String) -> Shader:
	if not _shaders.has(key):
		var s := Shader.new()
		s.code = code
		_shaders[key] = s
	return _shaders[key]

func _mat(key: String, code: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(key, code)
	return m

## Flat compass-star sigil on the ground (or any plane via `up`).
func sigil(at: Vector3, radius: float, duration := 1.1, spin_speed := 1.2, up := Vector3.UP) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(radius * 2.0, radius * 2.0)
	q.orientation = PlaneMesh.FACE_Y
	var o := MeshInstance3D.new()
	o.name = "RadiantSigil"
	o.mesh = q
	o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := _mat("sigil", SIGIL_SHADER)
	m.set_shader_parameter("reveal", 0.0)
	m.set_shader_parameter("spin", 0.0)
	m.set_shader_parameter("intensity", 1.0)
	o.material_override = m
	add_child(o, true)
	o.global_position = at + up * 0.04
	if not up.is_equal_approx(Vector3.UP):
		o.global_basis = Basis(Quaternion(Vector3.UP, up.normalized()))
	var tw := create_tween()
	tw.tween_property(m, "shader_parameter/reveal", 1.0, duration * 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(m, "shader_parameter/spin", spin_speed * duration, duration)
	tw.parallel().tween_property(m, "shader_parameter/intensity", 0.0, duration * 0.35).set_delay(duration * 0.65)
	tw.tween_callback(o.queue_free)
	return o

## Crescent of light sweeping around `at` through `arc` radians, centred on `facing`.
func crescent(at: Vector3, facing: Vector3, radius := 1.6, arc := deg_to_rad(220.0), duration := 0.45, height := 0.95, tilt := deg_to_rad(12.0), thickness := 0.55) -> MeshInstance3D:
	var f := Vector3(facing.x, 0, facing.z).normalized()
	if f.length() < 0.01: f = Vector3.FORWARD
	var yaw := atan2(f.x, f.z)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 64
	for i in n + 1:
		var u := float(i) / float(n)
		# sweep right-to-left across the front, as in the reference
		var a := yaw + arc * 0.5 - u * arc
		var dir := Vector3(sin(a), 0, cos(a))
		var r_in := radius - thickness
		st.set_uv(Vector2(u, 0.0)); st.add_vertex(dir * r_in)
		st.set_uv(Vector2(u, 1.0)); st.add_vertex(dir * radius)
	for i in n:
		var b := i * 2
		for idx in [b, b + 1, b + 3, b, b + 3, b + 2]:
			st.add_index(idx)
	var o := MeshInstance3D.new()
	o.name = "RadiantCrescent"
	o.mesh = st.commit()
	o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := _mat("crescent", CRESCENT_SHADER)
	m.set_shader_parameter("progress", 0.0)
	o.material_override = m
	add_child(o, true)
	o.global_position = at + Vector3.UP * height
	o.rotate_object_local(f.cross(Vector3.UP).normalized(), tilt)
	var tw := create_tween()
	tw.tween_property(m, "shader_parameter/progress", 1.0 + 0.75, duration * 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(o.queue_free)
	return o

## Billboard four-point starburst.
func starburst(at: Vector3, size := 0.7, duration := 0.5, delay := 0.0) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var o := MeshInstance3D.new()
	o.name = "RadiantStar"
	o.mesh = q
	o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := _mat("star", STAR_SHADER)
	m.set_shader_parameter("intensity", 0.0)
	m.set_shader_parameter("twist", randf_range(-0.3, 0.3))
	o.material_override = m
	add_child(o, true)
	o.global_position = at
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(m, "shader_parameter/intensity", 1.6, duration * 0.18)
	tw.tween_property(m, "shader_parameter/intensity", 0.0, duration * 0.82).set_ease(Tween.EASE_IN)
	tw.tween_callback(o.queue_free)
	return o

## Signature attack: "Judgment of the Lost Sun". Caster sigil, crescent sweep,
## starbursts trailing the arc, and a target sigil where the light lands.
func judgment(caster: Vector3, facing: Vector3, reach := 3.2) -> Array:
	var f := Vector3(facing.x, 0, facing.z).normalized()
	if f.length() < 0.01: f = Vector3.FORWARD
	var made: Array = []
	made.append(sigil(caster, 1.25, 1.2, 1.4))
	made.append(sigil(caster + Vector3.UP * 1.55 - f * 0.35, 0.75, 1.2, -1.0, -f))
	made.append(crescent(caster, f, 1.8, deg_to_rad(230.0), 0.6, 0.95, deg_to_rad(12.0), 0.85))
	made.append(crescent(caster, f, 2.35, deg_to_rad(170.0), 0.7, 0.7, deg_to_rad(-6.0), 0.45))
	var yaw := atan2(f.x, f.z)
	for i in 5:
		var a := yaw + deg_to_rad(80.0) - deg_to_rad(40.0) * i
		var p := caster + Vector3(sin(a), 0, cos(a)) * randf_range(1.8, 2.4) + Vector3.UP * randf_range(0.6, 1.6)
		made.append(starburst(p, randf_range(0.45, 0.9), 0.55, 0.04 * i))
	var land := caster + f * reach
	made.append(sigil(land, 0.9, 0.9, -2.0))
	made.append(starburst(land + Vector3.UP * 1.0, 1.4, 0.6, 0.12))
	return made
