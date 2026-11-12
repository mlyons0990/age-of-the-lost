extends Node2D
## Phase A on-body 2D appearance prototype. Each icon is painted original item
## artwork, not a skinned body mesh: final production uses rigged modular gear.
const Appearance := preload("res://scripts/equipment_appearance.gd")
const Art := preload("res://scripts/art_library.gd")

var actor
var layers: Dictionary = {}
var _signature := ""
var _state: Dictionary = {}
var _elapsed := 0.0

const LAYER_NAMES := ["boots", "body", "belt", "gloves", "head", "offhand", "weapon"]
const BOX_SIZES := {
	"boots": Vector2(75, 54),
	"body": Vector2(82, 112),
	"belt": Vector2(65, 29),
	"gloves": Vector2(92, 48),
	"head": Vector2(48, 52),
	"offhand": Vector2(70, 90),
	"weapon": Vector2(47, 132),
}

func _ready() -> void:
	for name in LAYER_NAMES:
		var sprite := Sprite2D.new()
		sprite.name = String(name).capitalize() + "Overlay"
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.visible = false
		sprite.z_index = 1
		add_child(sprite)
		layers[name] = sprite

func sync_gear(class_id: String, gear: Dictionary) -> void:
	var next_signature := Appearance.signature(class_id, gear)
	if next_signature == _signature:
		return
	_signature = next_signature
	_state = Appearance.snapshot(class_id, gear)
	var map := {
		"boots": "boots_art",
		"body": "body_art",
		"belt": "belt_art",
		"gloves": "gloves_art",
		"head": "head_art",
		"offhand": "offhand_art",
		"weapon": "weapon_art",
	}
	for key in map:
		_set_visual(key, String(_state[map[key]]))
	# Keep source sprite visible so the motion/casting strips remain authoritative.
	# These attached pieces are interim fitment previews, not production skins.
	if layers["body"].visible:
		layers["body"].modulate.a = 0.88
	if layers["weapon"].visible:
		layers["weapon"].modulate.a = 1.0
	_pose()

func _set_visual(key: String, art_id: String) -> void:
	var sprite: Sprite2D = layers[key]
	sprite.visible = not art_id.is_empty()
	if not sprite.visible:
		sprite.texture = null
		return
	var texture: Texture2D = Art.inventory_portrait(art_id)
	sprite.texture = texture
	if texture == null:
		sprite.visible = false
		return
	var box: Vector2 = BOX_SIZES[key]
	if key == "weapon" and not _state.is_empty() and bool(_state.get("two_handed", false)):
		box = Vector2(57, 154)
	var tex_size := texture.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		sprite.visible = false
		return
	var factor := minf(box.x / tex_size.x, box.y / tex_size.y)
	sprite.scale = Vector2.ONE * factor

func _process(delta: float) -> void:
	_elapsed += delta
	if actor != null and not _state.is_empty():
		_pose()

func _pose() -> void:
	if actor == null or layers.is_empty():
		return
	var facing_id := int(actor.get("facing"))
	var flip: bool = bool(actor.sprite.flip_h) if actor.sprite != null else false
	var side := -1.0 if flip else 1.0
	var walking: bool = actor.visual_state() == "walk"
	var attack: bool = actor.visual_state() == "attack"
	var bob := (sin(_elapsed * 12.0) * 2.2) if walking else 0.0
	layers["head"].position = Vector2(0, -210 + bob)
	layers["body"].position = Vector2(0, -135 + bob)
	layers["gloves"].position = Vector2(0, -100 + bob)
	layers["belt"].position = Vector2(0, -74 + bob)
	layers["boots"].position = Vector2(0, -28 + bob)
	var farther := facing_id in [0, 4]
	var hand_offset := 48.0 if farther else 44.0
	var two_hand := bool(_state.get("two_handed", false))
	layers["weapon"].position = Vector2(side * (29.0 if two_hand else hand_offset), -98 + bob)
	layers["offhand"].position = Vector2(-side * 47, -119 + bob)
	layers["weapon"].rotation = side * (0.32 if attack else (0.14 if two_hand else -0.16))
	layers["offhand"].rotation = side * -0.11
	for key in LAYER_NAMES:
		var s: Sprite2D = layers[key]
		s.flip_h = flip
	layers["offhand"].visible = not two_hand and layers["offhand"].texture != null
