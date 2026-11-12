extends SceneTree
func _initialize() -> void:
	root.size = Vector2i(1220, 1420)
	root.content_scale_size = Vector2i(1220, 1420)
	call_deferred("capture")
func label_at(text: String, at: Vector2, width: float, size: int) -> void:
	var label := Label.new()
	label.text = text; label.position = at; label.size.x = width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("e8c77a"))
	root.add_child(label)
func capture() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1220, 1420)
	await process_frame
	var bg := ColorRect.new(); bg.color = Color("101827"); bg.size = Vector2(1220, 1420); root.add_child(bg)
	label_at("AGE OF THE LOST / SYSTEMS ICON KIT", Vector2(20, 25), 1180, 30)
	label_at("24 editable SVG assets / vector placeholders / November 11, 2026", Vector2(20, 72), 1180, 18)
	var manifest: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/icon_manifest.json"))
	for i in manifest.size():
		var row: Dictionary = manifest[i]
		var x := 30 + (i % 6) * 195
		var y := 132 + int(i / 6) * 181
		var art := TextureRect.new(); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.texture = load("res://" + row.path); art.position = Vector2(x + 44, y); art.size = Vector2(104, 104)
		root.add_child(art)
		label_at(row.id, Vector2(x, y + 114), 193, 17)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/07_icon_atlas.png")
	quit()
