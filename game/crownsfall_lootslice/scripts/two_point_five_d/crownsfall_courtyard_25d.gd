extends Node3D
## Separate, non-destructive 3D environment experiment for the painted AOTL 2.5D lab.
## Built from licensed-free procedural geometry and the existing AOTL ivory/blue/gold palette.
## NOT a replacement for the canonical Crownsfall illustration or the save-bearing 2D plaza.

const IVORY := Color("d2c5b1")
const LIMESTONE := Color("b4a593")
const WARM_STONE := Color("9d907c")
const GOLD := Color("a9884c")
const BLUE := Color("1c3f78")
const DEEP_BLUE := Color("142c53")
const GREEN := Color("62805c")
const GREEN_DARK := Color("41573b")
const WATER := Color("77c4cc")
const FLOWER := Color("f6e5bb")
const ORIGINAL_PLAZA_PAINTING: Texture2D = preload("res://assets/plaza.png")
const SOFT_WALKING_MASK: Texture2D = preload("res://assets/25d/crownsfall_nav_floor_softmask.png")
const ORIGINAL_STONE_PAVER: Texture2D = preload("res://assets/25d/crownsfall_ivory_paver_from_approved_art.png")

var collision_footprints: Array[Dictionary] = []
var painted_walkway: MeshInstance3D
var painted_walkway_triangle_count := 0
var painted_walkway_area_pixels := 0.0

func _ready() -> void:
    name = "Crownsfall_2P5D_Procedural_Courtyard"
    _lighting()
    _paving()
    _center_inlay()
    _royal_gate()
    _market()
    _fountain()
    _gardens()
    _lamps()

func _mat(color: Color, metal: float = 0.0, rough: float = 0.82, unshaded: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    if unshaded:
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return m

func _block(label: String, pos: Vector3, dimensions: Vector3, color: Color, metal: float = 0.0) -> MeshInstance3D:
    var geometry := BoxMesh.new()
    geometry.size = dimensions
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = geometry
    node.position = pos
    node.material_override = _mat(color, metal)
    add_child(node)
    return node

func _solid(label: String, pos: Vector3, dimensions: Vector3, color: Color) -> void:
    # Record identical XZ footprints for the real 2D nav vs 3D prop audit.
    collision_footprints.append({"id": label, "x": pos.x, "z": pos.z, "width": dimensions.x, "depth": dimensions.z})
    _block(label, pos, dimensions, color)
    var object := StaticBody3D.new()
    object.name = label + "_collision"
    object.position = pos
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = dimensions
    shape.shape = box
    object.add_child(shape)
    add_child(object)

func _sphere(label: String, pos: Vector3, scale_size: Vector3, color: Color, metal: float = 0.0) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mesh.radial_segments = 12
    mesh.rings = 8
    var obj := MeshInstance3D.new()
    obj.name = label
    obj.mesh = mesh
    obj.scale = scale_size
    obj.position = pos
    obj.material_override = _mat(color, metal)
    add_child(obj)
    return obj

func _cylinder(label: String, pos: Vector3, radius: float, height: float, color: Color, metal: float = 0.0) -> MeshInstance3D:
    var shape := CylinderMesh.new()
    shape.top_radius = radius
    shape.bottom_radius = radius
    shape.height = height
    shape.radial_segments = 36
    var item := MeshInstance3D.new()
    item.name = label
    item.mesh = shape
    item.position = pos
    item.material_override = _mat(color, metal)
    add_child(item)
    return item

func install_painted_walkway(original_floor_outline: PackedVector2Array, world_from_2d: Callable) -> void:
    # UV-map the *actual approved AOTL painted plaza floor* onto the identical
    # polygon used by the saved game's NavigationRegion2D. This is a 3D mesh
    # rendered from the locked painting, not a flat screenshot/background card.
    # The painting itself is not modified and remains the fallback on F8 off.
    if painted_walkway != null:
        return
    if original_floor_outline.size() < 3 or not world_from_2d.is_valid():
        push_error("AOTL painted floor requires the original WALKABLE polygon")
        return
    var tris: PackedInt32Array = Geometry2D.triangulate_polygon(original_floor_outline)
    if tris.size() < 3:
        push_error("AOTL original game navigation outline failed triangulation")
        return
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    var texturing_size := Vector2(float(ORIGINAL_PLAZA_PAINTING.get_width()), float(ORIGINAL_PLAZA_PAINTING.get_height()))
    for vertex_index in tris:
        var atlas_point: Vector2 = original_floor_outline[vertex_index]
        var ground_point: Vector3 = world_from_2d.call(atlas_point)
        builder.set_uv(atlas_point / texturing_size)
        builder.set_normal(Vector3.UP)
        builder.add_vertex(ground_point + Vector3.UP * 0.042)
    var mat := ShaderMaterial.new()
    mat.resource_name = "Art_Direction_PaintedFloor_SoftNavigationFalloff"
    var shader := Shader.new()
    shader.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform sampler2D aotl_plaza : source_color, filter_linear_mipmap;
uniform sampler2D nav_soft_mask : filter_linear_mipmap;
void fragment() {
    vec4 paint = texture(aotl_plaza, UV);
    ALBEDO = paint.rgb;
    ALPHA = texture(nav_soft_mask, UV).r;
}
"""
    mat.shader = shader
    mat.set_shader_parameter("aotl_plaza", ORIGINAL_PLAZA_PAINTING)
    mat.set_shader_parameter("nav_soft_mask", SOFT_WALKING_MASK)
    builder.set_material(mat)
    painted_walkway = MeshInstance3D.new()
    painted_walkway.name = "Original_AOTL_Painted_NavMesh_Floor"
    painted_walkway.mesh = builder.commit()
    add_child(painted_walkway)
    # The original paint contains a complete ornate floor crest; the geometry
    # mock-up's oversized gold disc would otherwise float over that original art.
    for child in get_children():
        if child is MeshInstance3D and (child.name.begins_with("Plaza_Royal_Seal") or child.name.begins_with("Seal_Brass_Ray")):
            child.visible = false
    painted_walkway_triangle_count = tris.size() / 3
    var signed_area := 0.0
    for i in original_floor_outline.size():
        var a: Vector2 = original_floor_outline[i]
        var b: Vector2 = original_floor_outline[(i + 1) % original_floor_outline.size()]
        signed_area += a.cross(b)
    painted_walkway_area_pixels = absf(signed_area) * 0.5

func collidable_world_footprints() -> Array[Dictionary]:
    # These include non-walkable Citadel walls, railings, stone columns, gardens,
    # and fountain plinths. Validation is performed by the read-only bridge.
    return collision_footprints.duplicate(true)

func _lighting() -> void:
    var env := WorldEnvironment.new()
    env.name = "Crownsfall_ArtDirection_Atmosphere"
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color("9eafbf")
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color("d1c2af")
    settings.ambient_light_energy = 0.34
    env.environment = settings
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.name = "Sun_Warm_Ivory_Stone"
    sun.rotation_degrees = Vector3(-58, -42, 0)
    sun.light_color = Color("fff0d4")
    sun.light_energy = 0.71
    sun.shadow_enabled = true
    add_child(sun)

func _paving() -> void:
    var floor := StaticBody3D.new()
    floor.name = "Walkable_Stone_Collision_60m"
    floor.position = Vector3(0, -0.225, 0)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(60, 0.45, 60)
    shape.shape = box
    floor.add_child(shape)
    add_child(floor)
    _block("Limestone_Underlay", Vector3(0, -0.228, 0), Vector3(60, 0.44, 60), WARM_STONE)

    # Four times the cobble density at roughly the same scene draw-call cost.
    # A genuine diffuse grain texture is derived from the user's *original*
    # Crownsfall painting instead of making every stone a flat white box.
    var positions := [[], [], []]
    for ix in range(-30, 31):
        for iz in range(-30, 31):
            var color_variant := posmod(ix * 7 + iz * 11, 11)
            var slot := 0 if color_variant < 3 else (1 if color_variant < 8 else 2)
            positions[slot].append(Vector3(float(ix) * 0.966, 0.012, float(iz) * 0.966))
    var palette := [Color("c2b6a6"), Color("d0c2ae"), Color("b3a698")]
    for variant in 3:
        var paving := BoxMesh.new()
        paving.size = Vector3(0.944, 0.025, 0.944)
        var multi := MultiMesh.new()
        multi.transform_format = MultiMesh.TRANSFORM_3D
        multi.mesh = paving
        multi.instance_count = positions[variant].size()
        for i in multi.instance_count:
            multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[variant][i]))
        var rendered := MultiMeshInstance3D.new()
        rendered.name = "Paved_Cobblestones_%02d" % variant
        rendered.multimesh = multi
        var material := _mat(palette[variant])
        material.albedo_texture = ORIGINAL_STONE_PAVER
        material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        rendered.material_override = material
        add_child(rendered)

func _center_inlay() -> void:
    _cylinder("Plaza_Royal_Seal_Stone", Vector3(0, 0.038, -2.0), 2.25, 0.035, Color("c1b6a1"))
    _cylinder("Plaza_Royal_Seal_Gold_Outer", Vector3(0, 0.063, -2.0), 2.15, 0.014, GOLD, 0.35)
    _cylinder("Plaza_Royal_Seal_Ivory_Inner", Vector3(0, 0.077, -2.0), 1.98, 0.014, LIMESTONE)
    _cylinder("Plaza_Royal_Seal_Center", Vector3(0, 0.090, -2.0), 0.36, 0.015, BLUE, 0.10)
    for i in 8:
        var angle := float(i) * TAU / 8.0
        var spoke := _block("Seal_Brass_Ray_%02d" % i, Vector3(sin(angle) * 1.20, 0.108, -2.0 + cos(angle) * 1.20), Vector3(0.04, 0.014, 1.05), GOLD, 0.4)
        spoke.rotation.y = angle

func _column(x: float, z: float, height: float = 4.9) -> void:
    _solid("Ivory_StonePillar_%d_%d" % [int(x), int(z)], Vector3(x, height * 0.5, z), Vector3(0.84, height, 0.84), IVORY)
    _block("Gilded_PillarCap", Vector3(x, height, z), Vector3(1.18, 0.24, 1.18), GOLD, 0.27)
    _block("Pillar_Platform", Vector3(x, 0.18, z), Vector3(1.40, 0.35, 1.40), LIMESTONE)
    _block("Pillar_Bevel", Vector3(x, height - .40, z), Vector3(1.06, 0.16, 1.06), WARM_STONE)

func _banner(x: float, z: float, y: float = 3.62) -> void:
    # 3D fabric panel and abstract filigree mark: geometry placeholder until canonical UV art exists.
    _block("Royal_Blue_Banner", Vector3(x, y, z), Vector3(0.92, 1.66, 0.09), BLUE)
    _block("Royal_Banner_Gold_Top", Vector3(x, y + .76, z + .06), Vector3(1.0, .10, .035), GOLD, 0.28)
    _block("Royal_Banner_Gold_Hem", Vector3(x, y - .77, z + .06), Vector3(.88, .065, .04), GOLD, .28)
    _block("Royal_Crest_Stem", Vector3(x, y + .12, z + .065), Vector3(.072, .92, .025), GOLD, .28)
    _block("Royal_Crest_Crossbar", Vector3(x, y + .30, z + .065), Vector3(.54, .075, .025), GOLD, .28)
    _sphere("Royal_Crest_Fleur", Vector3(x, y + .56, z + .073), Vector3(.17, .25, .04), GOLD, .25)

func _royal_gate() -> void:
    for x in [-9.5, 9.5]:
        _column(x, -17.6, 6.1)
        _banner(x, -17.05, 4.65)
    _block("Citadel_Ivory_Architrave", Vector3(0, 6.05, -17.6), Vector3(20.1, 0.84, 1.40), IVORY)
    _block("Citadel_Blue_RoofBand", Vector3(0, 6.60, -17.6), Vector3(20.8, 0.19, 1.58), DEEP_BLUE)
    _block("Citadel_Brass_Crown", Vector3(0, 6.78, -17.6), Vector3(21.15, .20, 1.72), GOLD, .33)
    for x in [-18.0, 18.0]:
        _column(x, -11.0, 4.6)
        _banner(x, -10.48, 3.4)
    for x in [-20.5, 20.5]:
        # When the Royal Promenade became a traversable street, the eastern
        # old plaza parapet extended across that entrance. Shorten only the
        # positive-X span to leave a physical gate; retain the west wall.
        var z_mid: float = -11.55 if x > 0 else -7.0
        var z_length: float = 8.9 if x > 0 else 18.0
        _solid("Limestone_Parapet", Vector3(x, 1.13, z_mid),
            Vector3(.72, 2.26, z_length), LIMESTONE)
        _block("Parapet_GoldCoping", Vector3(x, 2.28, z_mid),
            Vector3(.92, .12, z_length + .2), GOLD)
    for x in [-7.5, 7.5]:
        _column(x, -9.9, 3.6)
        _banner(x, -9.36, 2.42)
    _block("Outer_Citadel_Crest", Vector3(0, 6.08, -16.84), Vector3(1.3, .48, .12), BLUE)
    _block("Outer_Citadel_GoldRune", Vector3(0, 6.08, -16.72), Vector3(.14, .40, .11), GOLD)

func _market() -> void:
    var left := Vector3(-9.8, 0, -7.9)
    _solid("Market_Counter", left + Vector3(0, .88, 0), Vector3(5.4, 1.1, 1.35), WARM_STONE)
    _block("Merchant_Display", left + Vector3(0, 1.47, 0), Vector3(5.7, .19, 1.62), LIMESTONE)
    for x in [left.x - 2.3, left.x + 2.3]:
        for z in [left.z - 1.4, left.z + 1.4]:
            _block("Canopy_OakSupport", Vector3(x, 2.55, z), Vector3(.14, 3.12, .14), Color("6b4d3a"))
            _sphere("Tent_GoldFinial", Vector3(x, 4.15, z), Vector3(.21, .21, .21), GOLD, .28)
    _block("Market_Canopy_CrownBlue", left + Vector3(0, 4.01, 0), Vector3(5.60, .12, 3.75), BLUE)
    _block("Market_Canopy_Ivory_CentreStripe", left + Vector3(0, 4.08, 0), Vector3(1.08, .02, 3.77), IVORY)
    _block("Market_Canopy_GoldHem", left + Vector3(0, 3.91, 1.76), Vector3(5.60, .20, .10), GOLD)
    for i in 4:
        _block("Merchant_Parcel_%d" % i, left + Vector3(-1.7 + i * 1.0, 1.73, .25), Vector3(.54, .40 + i * .08, .5), Color("b89f7b"))

func _fountain() -> void:
    var center := Vector3(9.5, 0, 6.0)
    _cylinder("Fountain_Ivory_Platform", center + Vector3(0, .29, 0), 2.58, .56, LIMESTONE)
    _cylinder("Fountain_Gold_Inlay", center + Vector3(0, .62, 0), 2.31, .12, GOLD, .25)
    _cylinder("Fountain_Blue_Water", center + Vector3(0, .687, 0), 2.18, .035, WATER, .06)
    _cylinder("Fountain_Inner_Rim", center + Vector3(0, .71, 0), .82, .17, IVORY)
    _cylinder("Fountain_Center_Pillar", center + Vector3(0, 1.32, 0), .38, 1.15, IVORY)
    _cylinder("Fountain_Gold_SunBowl", center + Vector3(0, 1.92, 0), .72, .12, GOLD, .45)
    _sphere("Fountain_Azure_Gem", center + Vector3(0, 2.18, 0), Vector3(.35, .50, .35), WATER)
    _solid("Fountain_Base_Collision", center + Vector3(0, .32, 0), Vector3(3.5, .64, 3.5), LIMESTONE)

func _planter(x: float, z: float, seed: int) -> void:
    _solid("Ivory_Garden_Planter_%d" % seed, Vector3(x, .38, z), Vector3(3.5, .75, 1.28), LIMESTONE)
    _block("Planter_Soil", Vector3(x, .78, z), Vector3(3.18, .09, 1.02), Color("625949"))
    for i in 7:
        var dx := -1.42 + float(i) * .46
        var dz := sin(float(i + seed) * 2.3) * .23
        var tall := .73 + float((i + seed) % 3) * .12
        _sphere("Garden_Hedge", Vector3(x + dx, 1.08 + tall * .3, z + dz), Vector3(.69, tall, .68), GREEN if i % 2 == 0 else GREEN_DARK)
        if i % 2 == 0:
            _sphere("Garden_Flowers", Vector3(x + dx, 1.56, z + dz), Vector3(.17, .13, .17), FLOWER if i % 4 == 0 else Color("dfb3af"))

func _gardens() -> void:
    _planter(-12.5, 9.6, 1)
    _planter(15.2, -9.9, 2)
    _planter(-16.0, -3.9, 3)
    for x in [-18.2, 18.2]:
        _cylinder("Garden_Tree_StoneBase", Vector3(x, .37, 13.3), 1.14, .72, IVORY)
        _block("TreeTrunk", Vector3(x, 1.60, 13.3), Vector3(.42, 2.6, .42), Color("6c5942"))
        _sphere("TreeLeaf_Canopy", Vector3(x, 3.52, 13.3), Vector3(3.14, 3.20, 2.75), GREEN)
        _sphere("TreeLeaf_Sunlit", Vector3(x - .67, 4.07, 13.19), Vector3(1.85, 1.9, 1.75), Color("839b69"))

func _lamps() -> void:
    for x in [-15.5, 15.5]:
        for z in [-13.4, 10.5]:
            _cylinder("Bronze_Lamp_Post", Vector3(x, 1.70, z), .087, 3.4, GOLD, .5)
            _cylinder("Bronze_Lamp_Foundation", Vector3(x, .17, z), .26, .34, WARM_STONE)
            _sphere("Glass_Lantern", Vector3(x, 3.58, z), Vector3(.42, .62, .42), Color("ffe3a0"))
            _cylinder("Lamp_Cap_Gold", Vector3(x, 3.96, z), .24, .15, GOLD, .7)
            var point := OmniLight3D.new()
            point.name = "Warm_Lantern_Light"
            point.light_color = Color("ffda8a")
            point.light_energy = .4
            point.omni_range = 7.0
            point.shadow_enabled = false
            point.position = Vector3(x, 3.58, z)
            add_child(point)
