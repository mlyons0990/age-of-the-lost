shader_type spatial;
// Flat ground decal (moss, leaves, roots, stones): blended onto the ground, lit per pixel by the zone light map so it
// sits in the same canopy shade as the ground under it. Never hides actors.
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
#include "res://shaders/kit_grade.gdshaderinc"
uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D light_map : filter_linear;
uniform sampler2D fx_map : filter_linear;
uniform vec4 mist_col : source_color = vec4(0.74, 0.64, 0.88, 1.0);
uniform vec2 zone_world;             // ground size in metres (x, z), centred on the origin
uniform bool flip = false;
uniform bool use_instance = false;   // MultiMesh batches: INSTANCE_CUSTOM.g = flip
varying vec3 wpos;
varying flat float v_flip;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_flip = use_instance ? INSTANCE_CUSTOM.g : (flip ? 1.0 : 0.0);
}
void fragment() {
	vec4 c = texture(tex, vec2(v_flip > 0.5 ? 1.0 - UV.x : UV.x, UV.y));
	float l = texture(light_map, wpos.xz / zone_world + 0.5).r * 2.0;
	vec2 zuv = wpos.xz / zone_world + 0.5;
	ALBEDO = mix(kit_graded(c.rgb) * l, kit_mist.rgb, clamp(texture(fx_map, zuv).r * 0.6, 0.0, 0.75));
	ALPHA = c.a;
}
