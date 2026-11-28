// Per-zone biome grade for kit art (zone JSON "grade"): lets one kit read as marsh, heath, coast or snow until the
// biome's own art exists. Set by rig_lab._build_kit_zone through global shader parameters (project.godot).
global uniform vec4 kit_grade;      // rgb multiply
global uniform vec4 kit_lift;       // rgb added after the multiply (a = amount): frost, haze, dust
global uniform float kit_desat;     // 0 = kit colours, 1 = grey
global uniform vec4 kit_mist;       // ground-mist colour
global uniform vec4 kit_water;      // water colour
vec3 kit_graded(vec3 c) {
	c = mix(c, vec3(dot(c, vec3(0.299, 0.587, 0.114))), kit_desat);
	return c * kit_grade.rgb + kit_lift.rgb * kit_lift.a;
}
