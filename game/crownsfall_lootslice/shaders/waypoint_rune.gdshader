shader_type spatial;
// Waypoint: a carved rune circle on the ground. Locked = faint grey; unlocked = blue/gold glow, slowly turning runes.
render_mode unshaded, blend_mix, depth_draw_never, shadows_disabled;
uniform float lit = 0.0;          // 0 locked .. 1 unlocked
uniform float hover = 0.0;
uniform vec4 blue : source_color = vec4(0.32, 0.64, 1.0, 1.0);
uniform vec4 gold : source_color = vec4(1.0, 0.80, 0.40, 1.0);
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float t = TIME * 0.25;
	float ring1 = smoothstep(0.035, 0.0, abs(r - 0.92));
	float ring2 = smoothstep(0.025, 0.0, abs(r - 0.70));
	float ring3 = smoothstep(0.02, 0.0, abs(r - 0.38));
	float runes = step(0.74, r) * step(r, 0.88) * step(0.55, fract((ang + t) * 12.0 / 6.2832)) * step(fract((ang + t) * 12.0 / 6.2832), 0.8);
	float star = smoothstep(0.03, 0.0, abs(sin((ang - t * 1.5) * 4.0)) * r) * step(r, 0.68);
	float core = smoothstep(0.35, 0.0, r);
	float m = ring1 + ring2 * 0.8 + ring3 * 0.7 + runes * 0.9 + star * 0.5;
	vec3 locked = vec3(0.55, 0.55, 0.6) * m * 0.35;
	vec3 on = (gold.rgb * (ring1 + runes * 0.9 + ring3 * 0.6) + blue.rgb * (ring2 * 0.9 + star * 0.6 + core * 0.18)) * 0.55;
	vec3 c = mix(locked, on * (1.0 + 0.25 * sin(TIME * 2.0)), lit) * (1.0 + hover * 0.6);
	float a = clamp(m * mix(0.35, 0.95, lit) + core * 0.35 * lit, 0.0, 1.0) * step(r, 1.0) * (1.0 + hover * 0.3);
	vec3 col = mix(vec3(0.45, 0.45, 0.5), mix(blue.rgb, gold.rgb, clamp(ring1 + runes + ring3, 0.0, 1.0)) * 1.2, lit);
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 1.0);
}
