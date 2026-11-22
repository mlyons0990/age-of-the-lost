// Shared by the kit prop passes: push pixels above the foot row onto the vertical plane at the foot (see kit_prop).
uniform float foot_v = 1.0;          // foot row as UV.y
uniform float tex_rows = 1000.0;     // image height in painting px (after scale)
uniform float z_per_row = 0.01;
uniform bool occludes = true;
uniform bool flip = false;
uniform float tint = 1.0;            // light-map value at the foot (props standing in canopy shade)
uniform float mist = 0.0;            // ground-mist amount at the foot
uniform vec4 mist_col : source_color = vec4(0.74, 0.64, 0.88, 1.0);
uniform float mist_rows = 0.3;       // trees: mist only on the lowest part (trunk base, roots); bushes: whole prop
vec3 kit_colour(vec3 c, float uvy) {
	float m = mist * (1.0 - smoothstep(0.0, mist_rows, foot_v - uvy));
	return mix(c * tint, mist_col.rgb, clamp(m, 0.0, 0.75));
}
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float kit_depth(vec2 uv_, mat4 inv_view, mat4 view, mat4 proj) {
	float rows = occludes ? max(0.0, (foot_v - uv_.y) * tex_rows) : 0.0;
	vec3 fwd = -inv_view[2].xyz;
	vec3 q = wpos - fwd * (rows * z_per_row / max(-fwd.z, 1e-4));
	vec4 clip = proj * view * vec4(q, 1.0);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return clip.z / clip.w * 0.5 + 0.5;
#else
	return clip.z / clip.w;
#endif
}
