shader_type spatial;
// Kit ground: tileable painted ground layers blended by a splat map (R flagstone, G dirt, B water).
// v2 kits (world_space): textures are painted top-down and repeat every tile_m metres on the ground, so the camera
// foreshortens them exactly like the props. v1 kits sample in painting-pixel space. Grass and dirt mix two rotated
// samples by noise so repeats don't show; flagstone uses one sample (blending two paving patterns ghosts the stones).
// light_map (R = light, 0.5 = neutral) carries baked canopy shadow and sun pools. Unshaded: the light is painted.
render_mode unshaded, cull_disabled;
#include "res://shaders/kit_grade.gdshaderinc"
uniform sampler2D base_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D path_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D dirt_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D splat : filter_linear;
uniform sampler2D light_map : filter_linear;
uniform bool use_light = false;
uniform sampler2D fx_map : filter_linear;      // R: ground mist
uniform vec4 mist_col : source_color = vec4(0.74, 0.64, 0.88, 1.0);
uniform bool world_space = false;
uniform vec2 zone_px;               // canvas size in painting px
uniform float ppm = 71.8;           // painting px per metre (world_space)
uniform float sin_pitch = 0.515;
uniform float base_tile = 560.0;    // painting px (v1) or metres (v2) per texture repeat
uniform float path_tile = 800.0;
uniform float dirt_tile = 500.0;
uniform vec4 water_col : source_color = vec4(0.32, 0.48, 0.55, 1.0);
float h(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p){ vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(h(i), h(i+vec2(1,0)), f.x), mix(h(i+vec2(0,1)), h(i+vec2(1,1)), f.x), f.y); }
vec3 tiled(sampler2D t, vec2 p, float tile, bool two) {
	vec2 a = p / tile;
	if (!two) return texture(t, a).rgb;
	vec2 b = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * (p / (tile * 1.37)) + vec2(0.37, 0.71);
	float m = smoothstep(0.25, 0.75, n2(p / (tile * 0.9)));
	return mix(texture(t, a).rgb, texture(t, b).rgb, m);
}
void fragment() {
	vec2 px = UV * zone_px;
	vec2 p = world_space ? vec2(px.x, px.y / sin_pitch) / ppm : px;
	vec4 s = texture(splat, UV);
	vec3 c = tiled(base_tex, p, base_tile, true);
	// dirt edges break up into grass at ~1 m scale instead of a smooth fade (worn trails, leaf litter)
	float dg = world_space ? smoothstep(0.3, 0.7, s.g + (n2(p * 1.4) - 0.5) * 0.55 + (n2(p * 4.0) - 0.5) * 0.2) : s.g;
	c = mix(c, tiled(dirt_tex, p, dirt_tile, true), dg);
	c = mix(c, tiled(path_tex, p, path_tile, !world_space), s.r);
	float ripple = 0.92 + 0.08 * n2(px / 60.0 + vec2(TIME * 0.3, 0.0));
	c = kit_graded(c);
	c = mix(c, kit_water.rgb * ripple, s.b * 0.92);
	if (use_light) {
		c *= texture(light_map, UV).r * 2.0;
		float drift = n2(px / 420.0 + vec2(TIME * 0.04, TIME * 0.015));
		c = mix(c, kit_mist.rgb, clamp(texture(fx_map, UV).r * (0.45 + 0.35 * drift), 0.0, 0.75));
	}
	else c *= 0.93 + 0.12 * n2(px / 900.0);     // v1: broad light/shade variation
	ALBEDO = c;
}
