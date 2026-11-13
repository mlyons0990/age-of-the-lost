shader_type canvas_item;
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec2 edge_px = min(UV, vec2(1.0)-UV) / TEXTURE_PIXEL_SIZE;
	color.a *= smoothstep(0.0, 96.0, min(edge_px.x, edge_px.y));
	color.a *= smoothstep(0.0, 340.0, UV.y / TEXTURE_PIXEL_SIZE.y);
	COLOR = color;
}
