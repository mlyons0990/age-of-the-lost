shader_type spatial;
// Hero body with the equipped armour tier (owner 11-27 visible gear): the hero's own painted texture, with its
// blue cloth recoloured to the tier's cloth colour and its steel / trim tinted toward the tier's metal. Hue, light and
// painted detail are kept (only hue/saturation of the masked parts change), so it stays in the painted style.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 cloth : source_color = vec4(0.0);
uniform vec4 metal : source_color = vec4(0.0);
uniform float roughness_v = 0.75;
vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}
vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * clamp(p - 1.0, 0.0, 1.0);
}
void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	vec3 hsv = rgb2hsv(c);
	if (cloth.a > 0.0) {
		// the hero's blue cloth (hue ~0.55-0.72, saturated)
		float m = smoothstep(0.50, 0.56, hsv.x) * (1.0 - smoothstep(0.70, 0.76, hsv.x)) * smoothstep(0.22, 0.38, hsv.y);
		vec3 ch = rgb2hsv(cloth.rgb);
		vec3 rec = hsv2rgb(vec3(ch.x, mix(hsv.y, ch.y, 0.7), hsv.z * mix(1.0, ch.z * 1.6, 0.6)));
		c = mix(c, rec, m * cloth.a);
	}
	if (metal.a > 0.0) {
		// steel and trim: low saturation, mid-to-bright value
		float m = (1.0 - smoothstep(0.12, 0.26, hsv.y)) * smoothstep(0.35, 0.6, hsv.z);
		c = mix(c, c * metal.rgb * 1.15, m * metal.a * 0.85);
	}
	ALBEDO = c;
	ROUGHNESS = roughness_v;
}
