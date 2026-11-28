shader_type spatial;
// Zone-exit aura: a shimmering blue/gold light curtain standing on the exit, fading upward. Alpha-blended so the
// colour reads on pale stone (additive washed out to white).
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 core : source_color = vec4(0.30, 0.62, 1.0, 1.0);
uniform vec4 rim : source_color = vec4(1.0, 0.80, 0.38, 1.0);
uniform float strength = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;            // 0 centre .. 1 sides
	float up = 1.0 - UV.y;                      // 0 ground .. 1 top
	float t = TIME;
	float streaks = noise(vec2(UV.x * 14.0, UV.y * 2.0 + t * 1.3)) * 0.6 + noise(vec2(UV.x * 31.0, UV.y * 5.0 + t * 2.1)) * 0.4;
	float fade_up = pow(1.0 - up, 1.6);
	float side = smoothstep(1.0, 0.55, x);
	float a = fade_up * side * (0.45 + 0.75 * streaks);
	vec3 c = mix(core.rgb, rim.rgb, smoothstep(0.35, 0.95, x) * 0.85 + (1.0 - fade_up) * 0.25);
	c += rim.rgb * smoothstep(0.02, 0.0, up) * 0.8 * side;   // bright gold line on the ground
	ALBEDO = c * 1.25;
	ALPHA = clamp(a * strength * (0.85 + 0.15 * sin(t * 2.4)), 0.0, 0.92);
}
