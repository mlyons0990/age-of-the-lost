shader_type spatial;
// Kit prop painted at the game camera, laid on the ground like the zone paintings. Upright props (trees, rocks,
// pillars) push every pixel above their foot row toward the camera onto the vertical plane at the foot, so 3D actors
// behind them are hidden (same depth model as the zone paintings, computed from UV instead of a baked map).
// Core pass: opaque + discard (lands in the depth buffer, so the occluded-hero silhouette sees it). The painted soft
// edge (alpha below CORE) is drawn by the kit_prop_fringe next pass, blended, so edges stay soft instead of jagged.
render_mode unshaded, cull_disabled;
#include "res://shaders/kit_grade.gdshaderinc"
#include "res://shaders/kit_depth.gdshaderinc"
uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
const float CORE = 0.9;
void fragment() {
	vec2 uv = kit_uv(UV);
	vec4 c = texture(tex, uv);
	if (c.a < CORE) discard;
	ALBEDO = kit_graded(kit_colour(c.rgb, UV.y));
	DEPTH = kit_depth(UV, INV_VIEW_MATRIX, VIEW_MATRIX, PROJECTION_MATRIX);
}
