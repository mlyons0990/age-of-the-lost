shader_type spatial;
// Kit light shafts: warm slanted bands from the upper left (fx map G says where), added over everything like the
// shafts painted in W1. Slow drift; low strength so they never wash out the hero.
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, depth_test_disabled;
uniform sampler2D fx_map : filter_linear;
uniform vec4 shaft_col : source_color = vec4(1.0, 0.9, 0.66, 1.0);
uniform float shaft_amt = 0.16;
uniform vec2 zone_px;
float h(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n1(float x){ float i = floor(x); float f = fract(x); f = f*f*(3.0-2.0*f); return mix(h(vec2(i, 0.0)), h(vec2(i + 1.0, 0.0)), f); }
void fragment() {
	vec2 px = UV * zone_px;
	float band = px.x * 0.82 - px.y * 0.57 + TIME * 6.0;
	float s = smoothstep(0.45, 0.85, n1(band / 70.0)) * (0.5 + 0.5 * n1(band / 23.0 + 7.0));
	ALBEDO = shaft_col.rgb * texture(fx_map, UV).g * shaft_amt * s;
}
