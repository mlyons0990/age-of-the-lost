shader_type spatial;
// Soft painted edge of a kit prop (alpha below the core pass's cut), alpha-blended over whatever is behind it.
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
#include "res://shaders/kit_grade.gdshaderinc"
#include "res://shaders/kit_depth.gdshaderinc"
uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
const float CORE = 0.9;
void fragment() {
	vec2 uv = kit_uv(UV);
	vec4 c = texture(tex, uv);
	if (c.a >= CORE || c.a < 0.01) discard;
	ALBEDO = kit_graded(kit_colour(c.rgb, UV.y));
	ALPHA = c.a;
	DEPTH = kit_depth(UV, INV_VIEW_MATRIX, VIEW_MATRIX, PROJECTION_MATRIX);
}
