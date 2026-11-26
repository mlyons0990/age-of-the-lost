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
uniform bool use_instance = false;
uniform bool soft_upright = false;   // non-occluding plants: depth-sorted at their foot (set back soft_back_m)
uniform float soft_back_m = 0.5;  // MultiMesh batches: INSTANCE_CUSTOM = (tint, flip, image rows, mist)
varying vec3 wpos;
varying flat float v_tint;
varying flat float v_flip;
varying flat float v_rows;
varying flat float v_mist;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_tint = tint; v_flip = flip ? 1.0 : 0.0; v_rows = tex_rows; v_mist = mist;
	if (use_instance) { v_tint = INSTANCE_CUSTOM.r; v_flip = INSTANCE_CUSTOM.g; v_rows = INSTANCE_CUSTOM.b; v_mist = INSTANCE_CUSTOM.a; }
}
vec2 kit_uv(vec2 uv) { bool f = use_instance ? v_flip > 0.5 : flip; return vec2(f ? 1.0 - uv.x : uv.x, uv.y); }
vec3 kit_colour(vec3 c, float uvy) {
	float m = (use_instance ? v_mist : mist) * (1.0 - smoothstep(0.0, mist_rows, foot_v - uvy));
	return mix(c * (use_instance ? v_tint : tint), mist_col.rgb, clamp(m, 0.0, 0.75));
}
float kit_depth(vec2 uv_, mat4 inv_view, mat4 view, mat4 proj) {
	bool up = occludes || soft_upright;
	float rows_raw = (foot_v - uv_.y) * (use_instance ? v_rows : tex_rows);
	// trees/rocks: rows below the foot stay on the ground (roots in front); low plants: the whole image is one plane
	float rows = up ? ((soft_upright && !occludes) ? rows_raw : max(0.0, rows_raw)) : 0.0;
	vec3 fwd = -inv_view[2].xyz;
	vec3 q = wpos - fwd * (rows * z_per_row / max(-fwd.z, 1e-4));
	// low plants: sorted at their own foot like trees, but set back so knee-high cover never hides the hero
	vec3 cam = inv_view[3].xyz;
	if (soft_upright && !occludes) {
		q += normalize(vec3(fwd.x, 0.0, fwd.z) + vec3(0.0, 0.0, -1e-4)) * soft_back_m;
		if (dot(q - cam, fwd) > dot(wpos - cam, fwd)) q = wpos;     // never behind the ground at this pixel
	} else if (occludes && rows_raw < 0.0) {
		q = wpos - fwd * 0.05;                                       // roots in front of the foot win ground ties
	}
	vec4 clip = proj * view * vec4(q, 1.0);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return clip.z / clip.w * 0.5 + 0.5;
#else
	return clip.z / clip.w;
#endif
}
