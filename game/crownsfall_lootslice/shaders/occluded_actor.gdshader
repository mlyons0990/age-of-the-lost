shader_type spatial;
// Occluded-actor silhouette (blueprint CAM-04): drawn over an actor only where something solid is clearly in front of
// it (a pillar, railing, tree), so the hero never disappears behind scenery. Applied as material_overlay.
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_back, shadows_disabled;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec4 tint : source_color = vec4(1.0, 0.82, 0.42, 1.0);
uniform float opacity = 0.55;
uniform float min_gap = 0.45;      // metres: ignore the actor's own depth (limbs behind torso)
void fragment() {
	float d = texture(depth_tex, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, d * 2.0 - 1.0);
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, d);
#endif
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	if (-view.z > -VERTEX.z - min_gap) {
		discard;
	}
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 1.6);
	ALBEDO = tint.rgb;
	ALPHA = opacity * (0.35 + 0.65 * rim);
}
