extends Node2D
## Third contiguous Crownfall district, connected to Royal Promenade. Uses the
## original game's player, inventory, save schema 6 and NavigationServer2D.
const SOURCE_ART: Texture2D = preload("res://assets/25d/crownsfall_merchants_quarter_v08.webp")
const ORIGIN := Vector2(2580.0, 1650.0)
const DIMENSIONS := Vector2(1650.0, 1240.0)
const DISTRICT_ID := "crownsfall_merchants_quarter"
const NAV_POINTS := [
	Vector2(110, 461), Vector2(440, 300),
	Vector2(700, 310), Vector2(1000, 315), Vector2(1240, 425),
	Vector2(1440, 540), Vector2(1550, 680), Vector2(1510, 835),
	Vector2(1360, 890), Vector2(1120, 815), Vector2(950, 800),
	Vector2(740, 730), Vector2(530, 710), Vector2(330, 750),
	Vector2(110, 811)
]
var art: Sprite2D
var navigation: NavigationRegion2D
var triangle_count := 0

static func area_polygon() -> PackedVector2Array:
	var out := PackedVector2Array()
	for vertex in NAV_POINTS:
		out.append(ORIGIN + vertex)
	return out

static func contains(point: Vector2) -> bool:
	var poly := area_polygon()
	if Geometry2D.is_point_in_polygon(point, poly):
		return true
	for i in poly.size():
		if Geometry2D.get_closest_point_to_segment(point, poly[i], poly[(i + 1) % poly.size()]).distance_to(point) <= 1.0:
			return true
	return false

func _ready() -> void:
	name = "CROWNSFALL_D08_Merchants_Quarter_Connected"
	art = Sprite2D.new()
	art.name = "MerchantsQuarter_PaintedArtwork"
	art.texture = SOURCE_ART
	art.centered = false
	art.position = ORIGIN
	art.z_index = -12
	add_child(art)
	var nav_poly := NavigationPolygon.new()
	var vertices := area_polygon()
	nav_poly.vertices = vertices
	var tris := Geometry2D.triangulate_polygon(vertices)
	triangle_count = tris.size() / 3
	for i in range(0, tris.size(), 3):
		nav_poly.add_polygon(PackedInt32Array([tris[i], tris[i + 1], tris[i + 2]]))
	navigation = NavigationRegion2D.new()
	navigation.name = "MerchantsQuarter_RealGameplayNav"
	navigation.navigation_polygon = nav_poly
	add_child(navigation)

func set_painted_background(visible_now: bool) -> void:
	if art != null:
		art.visible = visible_now

func status() -> Dictionary:
	return {
		"district": DISTRICT_ID,
		"walkable_tris": triangle_count,
		"nav_enabled": navigation.enabled if navigation != null else false,
		"source_texture": SOURCE_ART != null,
		"connected_to_game": get_parent() != null,
		"origin": ORIGIN,
		"dimensions": DIMENSIONS
	}
