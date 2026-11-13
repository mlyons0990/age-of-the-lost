extends Node3D
## View-only 3D quarter of Crownsfall. No independent player/nav authority.
## All structural columns and shop footprints sit OUTSIDE the connected 2D
## walkable polygon. Placeholders must be replaced by art-reviewed architecture.
const CITY := preload("res://scripts/two_point_five_d/crownsfall_merchants_quarter_v08.gd")
const STONE := Color("c1b8a4")
const STONE_DARK := Color("6c6870")
const ROYAL_BLUE := Color("25477e")
const NAVY := Color("1b2a4e")
const GOLD := Color("bb9558")
const ROOF := Color("45577a")
const WOOD := Color("665044")
const ART: Texture2D = preload("res://assets/25d/crownsfall_merchants_quarter_v08.webp")
const FACADES := [
    preload("res://assets/25d/royal_promenade_facade_0.png"),
    preload("res://assets/25d/royal_promenade_facade_1.png"),
    preload("res://assets/25d/royal_promenade_facade_2.png"),
    preload("res://assets/25d/royal_promenade_facade_3.png"),
]
var collidable_footprints: Array[Dictionary] = []
var building_count := 0
var collider_count := 0
var paintings: MeshInstance3D
var installed := false
var market_stall_count := 0

func _mat(c: Color,metal := 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metal
    m.roughness = 0.88
    return m

func _box(parent: Node3D,name: String,at: Vector3,size: Vector3,col: Color,metal := 0.0) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var node := MeshInstance3D.new()
    node.name = name
    node.mesh = mesh
    node.position = at
    node.material_override = _mat(col,metal)
    parent.add_child(node)
    return node

func _district_frame(world: Vector2,converter: Callable) -> Node3D:
    var frame := Node3D.new()
    frame.name = "Modular_AOTL_Ivory_Architecture"
    frame.position = converter.call(world)
    frame.rotation.y = deg_to_rad(45.0)
    add_child(frame)
    return frame

func _house(at: Vector2,converter: Callable,left: bool,idx: int) -> void:
    # Tall silhouette with distinct roof / columns / blue canopy, rather than
    # a single cube. Shadowed side faces support the canonical isometric read.
    var node := _district_frame(at,converter)
    node.name = "MerchantsQuarter_GothicShop_%02d" % idx
    var w := 3.8
    var d := 4.7
    var height := 3.2 + float(idx % 3) * 0.28
    _box(node,"Pale_Limestone_Facade",Vector3(0,height*.5,0),Vector3(w,height,d),STONE)
    # Physics proxy belongs to the 3D architectural shell. The actual 2D
    # game's city polygon remains the authoritative walkability boundary.
    var solid := StaticBody3D.new()
    solid.name = "Architectural_Blocker_3D_ExteriorOnly"
    solid.position.y=height*.5
    var collision := CollisionShape3D.new()
    var bounds := BoxShape3D.new()
    bounds.size=Vector3(w,height,d)
    collision.shape=bounds
    solid.add_child(collision)
    node.add_child(solid)
    collider_count+=1
    collidable_footprints.append({"center":at,"half_x":w*44.0,"half_y":d*44.0*.674,"id":node.name})
    _box(node,"Old_Stone_Socle",Vector3(0,.35,0),Vector3(w+.22,.7,d+.2),STONE_DARK)
    for x in [-w*.41,w*.41]:
        _box(node,"Carved_Pilaster",Vector3(x,height*.45,-d*.52),Vector3(.26,height*.84,.25),Color("f0e6d6"))
        _box(node,"Gilded_Capital",Vector3(x,height*.82,-d*.53),Vector3(.35,.22,.31),GOLD,.55)
    for x in [-1.1,0.0,1.1]:
        _box(node,"Deep_Arched_Window",Vector3(x,height*.56,-d*.52),Vector3(.66,1.35,.09),Color("26354e"))
        _box(node,"Gold_Window_Arch",Vector3(x,height*.78,-d*.55),Vector3(.81,.13,.13),GOLD,.44)
    _box(node,"Cornice_Silhouette",Vector3(0,height*.93,0),Vector3(w+.4,.22,d+.3),STONE_DARK)
    # Architectural painting is reused from the *approved Crownsfall plaza*
    # instead of rendering twelve featureless box facades. The card stays in
    # 3D depth and is explicitly temporary while detailed meshes are authored.
    var card := MeshInstance3D.new()
    card.name="Canon_Painterly_Facade_Source_Projection"
    var plane := QuadMesh.new()
    plane.size=Vector2(w*.81,height*.80)
    card.mesh=plane
    card.position=Vector3(0,height*.47,-d*.535)
    var surf := _mat(Color.WHITE)
    surf.albedo_texture = FACADES[idx % FACADES.size()]
    surf.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    surf.cull_mode=BaseMaterial3D.CULL_DISABLED
    card.material_override=surf
    node.add_child(card)
    var roof := _box(node,"Blue_Slate_Gabled_Roof",Vector3(0,height+.38,0),Vector3(w+1.0,.58,d+.85),ROOF)
    roof.rotation.z = .18 if left else -.18
    _box(node,"Ridge_Gold_Finial",Vector3(0,height+.81,0),Vector3(.11,.48,d+.65),GOLD,.55)
    _box(node,"Shop_Porch_Blue_Canopy",Vector3(0,1.22,-d*.65),Vector3(w*.82,.12,1.12),ROYAL_BLUE)
    _box(node,"Canopy_Hem_Gold",Vector3(0,1.12,-d*.93),Vector3(w*.85,.08,.13),GOLD)
    building_count += 1

func _light(at: Vector2, converter: Callable, idx: int) -> void:
    var node := _district_frame(at,converter)
    node.name = "City_Lamp_%02d" % idx
    _box(node,"Bronze_Lamp_Pole",Vector3(0,1.55,0),Vector3(.13,3.1,.13),WOOD)
    _box(node,"Lantern_Warm_Glass",Vector3(0,3.15,0),Vector3(.45,.7,.45),Color("efd09a"))
    _box(node,"Lantern_Roof",Vector3(0,3.58,0),Vector3(.56,.15,.56),GOLD,.5)
    var light := OmniLight3D.new()
    light.name="Warm_Practical"
    light.position=Vector3(0,3.0,0)
    light.light_color=Color("ffc989")
    light.light_energy=.23
    light.omni_range=4.7
    node.add_child(light)

func _put_painted_context(conv: Callable) -> void:
    # A backplate covers the architecture OUTSIDE the navigation mask.
    # This allows the whole illustrated market to read correctly at PoE zoom.
    # The real navigation surface sits 0.010m above this, so no z fighting.
    # It is visual only; no independent geometry or walking authority.
    var corners := [
        CITY.ORIGIN,
        CITY.ORIGIN + Vector2(CITY.DIMENSIONS.x, 0),
        CITY.ORIGIN + CITY.DIMENSIONS,
        CITY.ORIGIN + Vector2(0, CITY.DIMENSIONS.y)
    ]
    var quad := SurfaceTool.new()
    quad.begin(Mesh.PRIMITIVE_TRIANGLES)
    for idx in [0,1,2,0,2,3]:
        var pt: Vector2 = corners[idx]
        quad.set_uv((pt - CITY.ORIGIN) / CITY.DIMENSIONS)
        quad.set_normal(Vector3.UP)
        quad.add_vertex(conv.call(pt) + Vector3.UP * .057)
    var backdrop := MeshInstance3D.new()
    backdrop.name = "MerchantsQuarter_FullPaintedContext_UnderNav"
    backdrop.mesh = quad.commit()
    var m := _mat(Color.WHITE)
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.albedo_texture = ART
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    backdrop.material_override = m
    add_child(backdrop)


func _put_floor(outline: PackedVector2Array,conv: Callable) -> void:
    var tris := Geometry2D.triangulate_polygon(outline)
    var surf := SurfaceTool.new()
    surf.begin(Mesh.PRIMITIVE_TRIANGLES)
    for index in tris:
        var p: Vector2 = outline[index]
        var ground: Vector3 = conv.call(p)
        surf.set_uv((p - CITY.ORIGIN) / CITY.DIMENSIONS)
        surf.set_normal(Vector3.UP)
        surf.add_vertex(ground+Vector3.UP*.067)
    var mat := StandardMaterial3D.new()
    mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_texture=ART
    mat.roughness=1.0
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    surf.set_material(mat)
    paintings = MeshInstance3D.new()
    paintings.name="MerchantsQuarter_PaintedNavSurface_Actual2DArea"
    paintings.mesh=surf.commit()
    add_child(paintings)

func _stall(at: Vector2, converter: Callable, idx: int) -> void:
    # Distinctive market geometry; intentionally visual only until approved
    # exact collision geometry and pathfinding obstacles are authored.
    var frame := _district_frame(at, converter)
    frame.name = "Market_Stall_Canopy_%02d" % idx
    var tone: Color = ROYAL_BLUE if idx % 2 == 0 else Color("763f4f")
    _box(frame,"Carved_Oak_Trade_Counter",Vector3(0,.82,0),Vector3(2.65,.17,1.0),WOOD)
    _box(frame,"Brass_Edge_Along_Counter",Vector3(0,.92,-.55),Vector3(2.7,.09,.09),GOLD)
    for x in [-1.22,1.22]:
        _box(frame,"Awning_Lattice_Post",Vector3(x,1.55,-.08),Vector3(.10,3.1,.10),WOOD)
        _box(frame,"Gilded_Support_Collar",Vector3(x,2.72,-.08),Vector3(.18,.12,.18),GOLD)
    var canvas := _box(frame,"Tailored_RoyalBlue_Market_Awning",
        Vector3(0,2.95,-.22),Vector3(2.95,.11,1.80),tone)
    canvas.rotation.x = deg_to_rad(-9.0)
    _box(frame,"Embroidered_Gold_Front_Hem",Vector3(0,2.71,-1.05),
        Vector3(3.02,.10,.08),GOLD)
    for j in range(3):
        _box(frame,"Merchant_Trade_Parcel_%d" % j,
            Vector3(-.75+j*.73,1.05,.04),Vector3(.45,.30,.45),
            GOLD if j == 1 else Color("93817a"))
    market_stall_count += 1


func install(conv: Callable) -> void:
    if installed: return
    if not conv.is_valid(): return
    installed=true
    name="CROWNSFALL_MerchantsQuarter_3D_RenderOnly"
    _put_painted_context(conv)
    _put_floor(CITY.area_polygon(),conv)
    # Both building rows stand OUTSIDE the exact 2D NAV_POINTS polygon.
    for idx in range(5):
        var sx: float = 2850.0 + float(idx) * 305.0
        _house(Vector2(sx,1500.0),conv,true,idx)
        _house(Vector2(sx,3400.0),conv,false,idx+5)
    for idx in range(4):
        var sx: float = 3000.0 + float(idx) * 335.0
        _light(Vector2(sx,1960),conv,idx)
        _light(Vector2(sx,2840),conv,idx+4)
    for idx in range(4):
        var x: float = 3050.0 + float(idx) * 300.0
        _stall(Vector2(x,1810.0),conv,idx)
        _stall(Vector2(x,3030.0),conv,idx+4)
    # Decorative overhead sign and two free-standing towers: exterior art,
    # without additional StaticBody collision inside any walkable region.
    var arcade := _district_frame(Vector2(2710.0,2290.0),conv)
    arcade.name = "Royal_Promenade_To_Market_Gate_Threshold"
    for x in [-3.6,3.6]:
        _box(arcade,"Stone_Sign_Tower",Vector3(x,2.1,0),Vector3(.65,4.2,.74),STONE)
        _box(arcade,"Brass_Tower_Finial",Vector3(x,4.33,0),Vector3(.81,.25,.81),GOLD)
    _box(arcade,"Overhead_Merchant_Gate",Vector3(0,4.35,0),
        Vector3(8.1,.42,.88),STONE_DARK)
    _box(arcade,"Royal_Blue_Banner",Vector3(0,3.85,-.50),
        Vector3(5.5,.72,.09),NAVY)

func status() -> Dictionary:
    var nav := CITY.area_polygon()
    var intrusions: Array[String] = []
    for footprint in collidable_footprints:
        var c: Vector2 = footprint.center
        var hx: float = footprint.half_x
        var hy: float = footprint.half_y
        var outline := PackedVector2Array([
            c + Vector2(-hx,-hy), c + Vector2(hx,-hy),
            c + Vector2(hx,hy), c + Vector2(-hx,hy)])
        for overlap in Geometry2D.intersect_polygons(outline,nav):
            if overlap.size()>=3:
                var twice_area := 0.0
                for i in overlap.size(): twice_area+=overlap[i].cross(overlap[(i+1)%overlap.size()])
                if absf(twice_area)>0.1: intrusions.append(String(footprint.id))
    return {"district":"merchants_quarter","installed":installed,"houses":building_count,
        "render_only_navigation":true,"nav_surface":paintings!=null,
        "physics_collision_shells":collider_count,
        "stalls":market_stall_count,
        "collision_overlaps_authoritative_2d_nav":intrusions,
        "shadowing_geometry":true}
