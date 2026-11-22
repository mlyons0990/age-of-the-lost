shader_type spatial;
// Zone-exit glow laid ON a painted threshold (steps, doorway floor, cave mouth). UV.y = 0 at the exit edge, 1 at the
// far end of the glow; UV.x across the opening. Light gathers toward the exit and drifts toward it, fading at the sides,
// so it reads as magic spilling from the opening rather than a shape placed on the floor.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 blue : source_color = vec4(0.30, 0.60, 1.0, 1.0);
uniform vec4 gold : source_color = vec4(1.0, 0.80, 0.42, 1.0);
uniform float strength = 0.75;
float h(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p){ vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(h(i), h(i+vec2(1,0)), f.x), mix(h(i+vec2(0,1)), h(i+vec2(1,1)), f.x), f.y); }
void fragment() {
	float t = TIME;
	float toward = pow(1.0 - UV.y, 1.8);                          // brightest at the exit edge
	float sides = smoothstep(0.0, 0.18, UV.x) * smoothstep(1.0, 0.82, UV.x);
	float flow = 0.55 * n(vec2(UV.x * 7.0, UV.y * 4.0 + t * 0.9)) + 0.45 * n(vec2(UV.x * 15.0, UV.y * 9.0 + t * 1.6));
	float a = toward * sides * (0.45 + 0.8 * flow);
	float lip = smoothstep(0.06, 0.0, UV.y) * sides;              // bright line along the exit edge
	vec3 c = mix(blue.rgb, gold.rgb, 0.25 + 0.35 * flow) * a + gold.rgb * lip * 0.9;
	ALBEDO = c * strength * (0.88 + 0.12 * sin(t * 2.2));
}
