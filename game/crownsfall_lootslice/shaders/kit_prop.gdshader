shader_type spatial;
// Kit prop painted at the game camera, laid on the ground like the zone paintings. Upright props (trees, rocks,
// pillars) push every pixel above their foot row toward the camera onto the vertical plane at the foot, so 3D actors
// behind them are hidden (same depth model as the zone paintings, computed from UV instead of a baked map).
render_mode unshaded, cull_disabled;   // opaque + discard: lands in the depth buffer, so the occluded-hero silhouette sees it
uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic;
uniform float foot_v = 1.0;          // foot row as UV.y
uniform float tex_rows = 1000.0;     // image height in painting px (after scale)
uniform float z_per_row = 0.01;
uniform bool occludes = true;
uniform bool flip = false;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 uv = vec2(flip ? 1.0 - UV.x : UV.x, UV.y);
	vec4 c = texture(tex, uv);
	if (c.a < 0.5) discard;
	ALBEDO = c.rgb;
	float rows = occludes ? max(0.0, (foot_v - UV.y) * tex_rows) : 0.0;
	vec3 fwd = -INV_VIEW_MATRIX[2].xyz;
	vec3 q = wpos - fwd * (rows * z_per_row / max(-fwd.z, 1e-4));
	vec4 clip = PROJECTION_MATRIX * VIEW_MATRIX * vec4(q, 1.0);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	DEPTH = clip.z / clip.w * 0.5 + 0.5;
#else
	DEPTH = clip.z / clip.w;
#endif
}
