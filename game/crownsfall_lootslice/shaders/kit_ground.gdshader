shader_type spatial;
// Kit ground: tileable painted ground layers blended by a splat map (R flagstone, G dirt, B water). Sampled in
// painting-pixel space (same projection as the zone paintings), with two offset/rotated samples blended by noise so
// repeats don't show. Unshaded: the painted light is in the textures.
render_mode unshaded, cull_disabled;
uniform sampler2D base_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D path_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D dirt_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D splat : filter_linear;
uniform vec2 zone_px;               // canvas size in painting px
uniform float base_tile = 560.0;    // painting px per texture repeat
uniform float path_tile = 800.0;
uniform float dirt_tile = 500.0;
uniform vec4 water_col : source_color = vec4(0.32, 0.48, 0.55, 1.0);
float h(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p){ vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(h(i), h(i+vec2(1,0)), f.x), mix(h(i+vec2(0,1)), h(i+vec2(1,1)), f.x), f.y); }
vec3 tiled(sampler2D t, vec2 px, float tile) {
	vec2 a = px / tile;
	vec2 b = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * (px / (tile * 1.37)) + vec2(0.37, 0.71);
	float m = smoothstep(0.25, 0.75, n2(px / (tile * 0.9)));
	return mix(texture(t, a).rgb, texture(t, b).rgb, m);
}
void fragment() {
	vec2 px = UV * zone_px;
	vec4 s = texture(splat, UV);
	vec3 c = tiled(base_tex, px, base_tile);
	c = mix(c, tiled(dirt_tex, px, dirt_tile), s.g);
	c = mix(c, tiled(path_tex, px, path_tile), s.r);
	float ripple = 0.92 + 0.08 * n2(px / 60.0 + vec2(TIME * 0.3, 0.0));
	c = mix(c, water_col.rgb * ripple, s.b * 0.92);
	float tone = 0.93 + 0.12 * n2(px / 900.0);     // broad light/shade variation
	ALBEDO = c * tone;
}
