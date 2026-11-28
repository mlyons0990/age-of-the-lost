shader_type spatial;
// Painted 2D zone on the ground plane. The depth map gives each pixel the image row where the thing drawn there meets
// the ground; pixels of railings / lamps in front of the floor are pushed toward the camera (onto the vertical plane at
// their foot line), so 3D actors that walk behind them are hidden by the painting itself.
render_mode unshaded, cull_disabled;
uniform sampler2D painting : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D depthmap : filter_nearest;
uniform float z_per_row = 0.01;     // world metres along z per image row
uniform bool use_depth = true;
uniform vec2 uv_offset = vec2(0.0);   // tile: where the mesh rect sits inside the (guttered) tile image
uniform vec2 uv_scale = vec2(1.0);
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 uv = uv_offset + UV * uv_scale;
	ALBEDO = texture(painting, uv).rgb;
	float rows = use_depth ? texture(depthmap, uv).r * 255.0 * 4.0 : 0.0;
	vec3 fwd = -INV_VIEW_MATRIX[2].xyz;
	float t = rows * z_per_row / max(-fwd.z, 1e-4);
	vec3 q = wpos - fwd * t;
	vec4 clip = PROJECTION_MATRIX * VIEW_MATRIX * vec4(q, 1.0);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	DEPTH = clip.z / clip.w * 0.5 + 0.5;
#else
	DEPTH = clip.z / clip.w;
#endif
}
