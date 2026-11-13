extends Node2D
## First connected CITY DISTRICT, not another separate wilderness zone.
## Existing Player/NavServer2D/quests/inventory/save authority is preserved.
## A deliberately preliminary painting supports navigation until custom buildings
## can be hand painted to the approved Crownsfall screenshot's quality.
const SOURCE_ART: Texture2D = preload("res://assets/25d/crownsfall_royal_promenade_v07.png")
const ORIGIN := Vector2(1500.0, 1536.0)
const DIMENSIONS := Vector2(1500.0, 1410.0)
const DISTRICT_ID := "crownsfall_royal_promenade"
const NAV_POINTS := [
    Vector2(320, 0), Vector2(840, 0), Vector2(910, 165),
    Vector2(1105, 300), Vector2(1190, 575), Vector2(1190, 925),
    Vector2(1100, 1190), Vector2(922, 1350), Vector2(515, 1350),
    Vector2(320, 1180), Vector2(260, 940), Vector2(258, 610),
    Vector2(280, 320), Vector2(300, 145)
]
var art: Sprite2D
var navigation: NavigationRegion2D
var triangle_count := 0

static func area_polygon() -> PackedVector2Array:
    var out := PackedVector2Array()
    for p in NAV_POINTS:
        out.append(ORIGIN + p)
    return out

static func contains(point: Vector2) -> bool:
    var poly := area_polygon()
    if Geometry2D.is_point_in_polygon(point, poly): return true
    for i in poly.size():
        if Geometry2D.get_closest_point_to_segment(point, poly[i], poly[(i + 1) % poly.size()]).distance_to(point) <= 1.0:
            return true
    return false

func _ready() -> void:
    name = "CROWNSFALL_D07_Royal_Promenade_Gameplay_Connected"
    art = Sprite2D.new()
    art.name = "Royal_Promenade_Street_Painted_Map_Blockout"
    art.texture = SOURCE_ART
    art.centered = false
    art.position = ORIGIN
    art.z_index = -11
    add_child(art)
    var poly := NavigationPolygon.new()
    var vertices := area_polygon()
    poly.vertices = vertices
    var tris := Geometry2D.triangulate_polygon(vertices)
    triangle_count = tris.size() / 3
    for i in range(0, tris.size(), 3):
        poly.add_polygon(PackedInt32Array([tris[i], tris[i + 1], tris[i + 2]]))
    navigation = NavigationRegion2D.new()
    navigation.name = "Authoritative_Royal_Promenade_Nav_Connected_to_Plaza"
    navigation.navigation_polygon = poly
    add_child(navigation)

func set_painted_background(visible_now: bool) -> void:
    if art != null:
        art.visible = visible_now

func status() -> Dictionary:
    return {
        "district": DISTRICT_ID,
        "connected_to_original_world": get_parent() != null,
        "nav_triangles": triangle_count,
        "nav_enabled": navigation.enabled if navigation != null else false,
        "native_art_available": SOURCE_ART != null,
        "origin": ORIGIN,
        "height_px": DIMENSIONS.y,
    }
