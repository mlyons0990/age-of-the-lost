extends SceneTree
## Phase 17 art-only 1197-mesh masonry gate, Godot 4.6.3 import and route checks.
## After --editor --import:
## godot --headless --path game/crownsfall_lootslice --script res://tests/citadel_masonry_v17.gd
const BRIDGE := preload("res://scripts/two_point_five_d/live_courtyard_bridge.gd")
const SCENE := "res://assets/25d/citadel/AOTL_Citadel_MasonryArt_v17.glb"
const MANIFEST := "res://assets/25d/citadel/AOTL_Citadel_MasonryArt_v17.json"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, reason: String) -> void:
    checks += 1
    if not ok:
        failures.append(reason)
        printerr("CITADEL_MASONRY_V17 FAIL: " + reason)

func _collect(node: Node, meshes: Dictionary) -> void:
    if node is MeshInstance3D:
        meshes[String(node.name)] = node
    for child in node.get_children():
        _collect(child, meshes)

func _count_bodies(node: Node) -> int:
    var found: int = 1 if node is StaticBody3D else 0
    for child in node.get_children():
        found += _count_bodies(child)
    return found

func _top(instance: MeshInstance3D) -> float:
    var cuboid: AABB = instance.get_aabb()
    var maximum := -INF
    for x in [cuboid.position.x, cuboid.end.x]:
        for y in [cuboid.position.y, cuboid.end.y]:
            for z in [cuboid.position.z, cuboid.end.z]:
                var p: Vector3 = instance.global_transform * Vector3(x,y,z)
                maximum = maxf(maximum, p.y)
    return maximum

func _large_nav() -> NavigationRegion2D:
    var nav := NavigationRegion2D.new()
    var poly := NavigationPolygon.new()
    poly.vertices = PackedVector2Array([
        Vector2(-2000,-5000), Vector2(2000,-5000),
        Vector2(2000,5000), Vector2(-2000,5000)])
    poly.add_polygon(PackedInt32Array([0,1,2,3]))
    nav.navigation_polygon = poly
    return nav

func _run() -> void:
    _check(ResourceLoader.exists(SCENE), "v17 GLB imported by Godot")
    _check(FileAccess.file_exists(MANIFEST), "v17 manifest exists")
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
    _check(data is Dictionary, "valid art manifest")
    if not (data is Dictionary):
        quit(1)
        return
    _check(int(data.get("nodes",0)) == 1197, "expected production-detail mesh count")
    _check(bool(data.get("has_gameplay_colliders",true)) == false,
        "asset remains art-only with zero gameplay collision")
    _check(String(data.get("world_space","")) == "X_lateral_Y_up_Z_north",
        "measured 3D basis unchanged")
    _check(String(data.get("status","")) == "art_candidate_not_canon_not_higgsfield_export",
        "art remains explicitly noncanonical")
    var packed: PackedScene = ResourceLoader.load(SCENE) as PackedScene
    _check(packed != null, "portable GLB gives a PackedScene")
    if packed == null:
        quit(1)
        return
    var model: Node3D = packed.instantiate() as Node3D
    _check(model != null, "root is transformable Node3D")
    if model == null:
        quit(1)
        return
    root.add_child(model)
    var meshes: Dictionary = {}
    _collect(model, meshes)
    _check(meshes.size() == 1197, "all 1197 semantic meshes imported")
    _check(_count_bodies(model) == 0, "visual resource contains no collision bodies")
    _check(meshes.has("GATE_GothicVoussoir_01"), "original Gothic arch preserved")
    _check(meshes.has("GATE_GothicVoussoir_32"), "arch completes with 32nd stone")
    _check(meshes.has("ENV_UpperStoneCourt"), "upper courtyard retained")
    _check(meshes.has("ART_Niche_GothicRib_L_0_00"), "new Gothic niche relief appears")
    _check(meshes.has("ART_Fountain_Water_R_1"), "side water fountain appears")
    var floor_materials: Dictionary = {}
    for name in meshes:
        var m: MeshInstance3D = meshes[name]
        if m.mesh == null:
            continue
        for surface in range(m.mesh.get_surface_count()):
            var material: Material = m.mesh.surface_get_material(surface)
            if material is BaseMaterial3D:
                var base: BaseMaterial3D = material
                if base.albedo_texture != null:
                    floor_materials[base.albedo_texture.get_instance_id()] = true
    _check(floor_materials.size() >= 4,
        "four actual embedded painterly limestone images survive Godot import")
    for i in range(1,10):
        var name := "STAIR_Tread_%02d" % i
        _check(meshes.has(name), "step %d exists" % i)
        if meshes.has(name):
            _check(absf(_top(meshes[name]) - float(i)*0.2) < 0.005,
                "step %d top remains physically aligned" % i)
    _check(absf(_top(meshes["STAIR_UpperLanding"]) - 1.8) < 0.005,
        "upper landing stays exactly 1.8m")
    model.queue_free()
    await process_frame
    var bridge := BRIDGE.new()
    bridge.scenery = Node3D.new()
    bridge.is_ready = true
    _check(not bridge.install_verified_citadel_masonry_v17(),
        "cannot install the model before validating a 2D route")
    var nav := _large_nav()
    var start_px: Vector2 = bridge.to_2d(Vector3.ZERO)
    var end_px: Vector2 = bridge.to_2d(Vector3(0.0,0.0,9.0))
    _check(bridge.install_verified_citadel_grade(start_px,end_px,nav,9,1.8,7.5),
        "authored grade installs from verified navigation polygon")
    _check(bridge.install_verified_citadel_masonry_v17(),
        "v17 model installed on the same route physical grade")
    _check(bridge.citadel_art_variant == "v17",
        "bridge reports new optional masonry variant")
    _check(bridge.citadel_art_mesh_count == 1197,
        "bridge indexes every imported mesh")
    _check(not bridge.citadel_art_root.visible,
        "painterly fallback still default")
    _check(not bridge.install_verified_citadel_art(),
        "cannot accidentally install a second v15 layer")
    _check(_count_bodies(bridge.citadel_art_root) == 0,
        "new detail overlays do not create duplicate collisions")
    _check(_count_bodies(bridge.citadel_grade) == 64,
        "the original 64 physical Grade bodies remain authoritative in 3D")
    _check(bridge.set_citadel_art_enabled(true),
        "v17 opt-in preview selection")
    _check(bridge.set_citadel_grade_preview(true),
        "grade preview can be explicitly enabled")
    _check(bridge.citadel_art_root.visible,
        "selected v17 now visible")
    _check(bridge._citadel_height_at(end_px) > 1.7,
        "original depth avatar still receives upper grade height")
    var assembly: Node3D = bridge.citadel_grade.get_node(
        "AuthoritativeRoute_VisualMasonry_2DNavUnchanged")
    var collision: StaticBody3D = assembly.get_node(
        "Physical_Tread_01_Collision")
    _check(collision.collision_layer == 1,
        "actual authored collision enabled under decorated 3D mesh")
    _check(not bridge.set_citadel_grade_preview(false),
        "disabled preview returns original painted presentation")
    _check(not bridge.citadel_art_root.visible,
        "no invisible 3D geometry after F4 disabled")
    _check(collision.collision_layer == 0,
        "no invisible physical collision after F4 disabled")
    _check(bridge._citadel_height_at(end_px) == 0.0,
        "no lingering depth offset when preview disabled")
    bridge.scenery.free()
    bridge.free()
    nav.free()
    if failures.is_empty():
        print("CITADEL_MASONRY_V17 PASS %d/%d" % [checks,checks])
        quit(0)
    else:
        printerr("CITADEL_MASONRY_V17 FAIL %d/%d" % [failures.size(),checks])
        quit(1)
