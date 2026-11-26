extends Node3D
## Something on the ground: gold, a potion, a piece of gear or a quest item. Name label in its rarity colour, a light
## pillar for rare and better items and quest items, a small bob. Gold, potions and quest items are picked up by
## walking over them; gear by clicking it (the hero walks there and picks it up).
const GD := preload("res://scripts/game_data.gd")
var kind := "gold"               # gold | potion | item | quest
var amount := 0
var potion := "health"
var item: Dictionary = {}
var quest_id := ""
var t := 0.0
var label: Label3D
var icon: Sprite3D
var beam: MeshInstance3D

func text() -> String:
	match kind:
		"gold": return "%d Gold" % amount
		"potion": return ("Health" if potion == "health" else "Mana") + " Potion"
		"quest": return String(item.get("name", "Quest Item"))
	return String(item.get("name", "Item"))

func colour() -> Color:
	match kind:
		"gold": return Color("f2d27a")
		"potion": return Color("ff8a7a") if potion == "health" else Color("8ab4ff")
		"quest": return Color("ff9a2e")
	return Color(String(GD.RARITY[clampi(int(item.get("rarity", 0)), 0, 3)]["color"]))

func auto_pickup() -> bool:
	return kind != "item"

func _ready() -> void:
	label = Label3D.new()
	label.text = text()
	label.modulate = colour()
	label.outline_modulate = Color(0, 0, 0, 0.95)
	label.outline_size = 10
	label.font_size = 34
	label.pixel_size = 0.0055
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 8
	label.position = Vector3(0, 0.75, 0)
	label.font = load("res://assets/fonts/LiberationSerif-Bold.ttf")
	add_child(label)
	var tex: Texture2D = null
	match kind:
		"item":
			tex = preload("res://scripts/art_library.gd").inventory_portrait(String(item.get("slot", "weapon")))
		"potion":
			var p := "res://assets/ui/arpg_hud/%s.png" % ("potion" if potion == "health" else "potion_mana")
			if ResourceLoader.exists(p): tex = load(p)
	if tex != null:
		icon = Sprite3D.new()
		icon.texture = tex
		icon.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		icon.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		icon.shaded = false
		icon.pixel_size = 0.55 / float(tex.get_height())
		icon.position = Vector3(0, 0.3, 0)
		add_child(icon)
	var rare: bool = kind == "quest" or (kind == "item" and int(item.get("rarity", 0)) >= 2)
	var glow := MeshInstance3D.new()
	var gm := PlaneMesh.new(); gm.size = Vector2(1.1, 1.1)
	glow.mesh = gm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_texture = _glow_tex()
	mat.albedo_color = Color(colour(), 0.75)
	mat.render_priority = 3
	glow.material_override = mat
	glow.position.y = 0.03
	add_child(glow)
	if rare:
		beam = MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.05; cm.bottom_radius = 0.16; cm.height = 4.0
		beam.mesh = cm
		var bm := StandardMaterial3D.new()
		bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		bm.albedo_color = Color(colour(), 0.28)
		bm.cull_mode = BaseMaterial3D.CULL_DISABLED
		beam.material_override = bm
		beam.position.y = 2.0
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(beam)

static var _g: ImageTexture
static func _glow_tex() -> ImageTexture:
	if _g == null:
		var n := 64
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var d := Vector2(x - n * 0.5 + 0.5, (y - n * 0.5 + 0.5)).length() / (n * 0.5)
				img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 2))
		_g = ImageTexture.create_from_image(img)
	return _g

func _process(delta: float) -> void:
	t += delta
	if icon != null: icon.position.y = 0.3 + sin(t * 2.5) * 0.06
	if beam != null: (beam.material_override as StandardMaterial3D).albedo_color.a = 0.22 + 0.1 * sin(t * 3.0)
