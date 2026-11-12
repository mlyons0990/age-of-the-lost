extends RefCounted
## Runtime art routing. Optional painted assets keep stable gameplay IDs;
## editable vectors remain the fallback for unfinished/rejected paintings.
static var icons: Dictionary = {}
static var selected_profile: Dictionary = {}

static func profile() -> Dictionary:
	if selected_profile.is_empty() and FileAccess.file_exists("res://data/selected_art_profile.json"):
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/selected_art_profile.json"))
		if parsed is Dictionary: selected_profile=parsed
	return selected_profile

static func selected_texture(kind: String, id: String) -> Texture2D:
	var choices: Variant=profile().get(kind,{})
	if not choices is Dictionary: return null
	var path: Variant=choices.get(id,"")
	if not path is String or path.is_empty() or not ResourceLoader.exists(path): return null
	return load(path) as Texture2D

static func icon(id: String) -> Texture2D:
	if icons.has(id): return icons[id]
	var selected:=selected_texture("icons",id)
	if selected!=null:
		icons[id]=selected
		return selected
	var painted := "res://assets/painted_icons/%s.png" % id
	var vector := "res://assets/icons/%s.svg" % id
	var path := painted if ResourceLoader.exists(painted) else vector
	if not ResourceLoader.exists(path): path = "res://assets/icons/amulet.svg"
	var texture: Texture2D = load(path)
	icons[id] = texture
	return texture


## Backpack silhouettes are pre-rendered to the same aspect ratio as the real
## data footprint. This affects only illustration; inventory cells are always
## determined by Systems.footprint(item).
static var portraits: Dictionary = {}
static func inventory_portrait(id: String) -> Texture2D:
	if portraits.has(id): return portraits[id]
	var selected:=selected_texture("portraits",id)
	if selected!=null:
		portraits[id]=selected
		return selected
	var path := "res://assets/item_portraits/%s.png" % id
	var texture: Texture2D = load(path) if ResourceLoader.exists(path) else icon(id)
	portraits[id] = texture
	return texture

static func panel() -> StyleBoxTexture:
	var path := "res://assets/ui/royal_panel.png"
	if not ResourceLoader.exists(path): return null
	var style := StyleBoxTexture.new()
	style.texture = load(path)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 64)
		style.set_content_margin(side, 64)
	return style
