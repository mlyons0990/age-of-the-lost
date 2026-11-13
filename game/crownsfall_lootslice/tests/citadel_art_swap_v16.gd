extends SceneTree
## Phase 16: real Godot GLB art swap; the 2D game remains authoritative.
## Run AFTER `godot --headless --editor --import --quit`.
## Godot: --headless --path game/crownsfall_lootslice \
##     --script res://tests/citadel_art_swap_v16.gd
const BRIDGE := preload("res://scripts/two_point_five_d/live_courtyard_bridge.gd")
var checks := 0
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        errors.append(label)
        printerr("CITADEL_ART_SWAP_V16 FAIL: " + label)

func _rect(a: Vector2, b: Vector2) -> NavigationRegion2D:
    var nav := NavigationRegion2D.new()
    var polygon := NavigationPolygon.new()
    polygon.vertices = PackedVector2Array([
        a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)])
    polygon.add_polygon(PackedInt32Array([0, 1, 2, 3]))
    nav.navigation_polygon = polygon
    return nav

func _gap_region() -> NavigationRegion2D:
    var nav := NavigationRegion2D.new()
    var poly := NavigationPolygon.new()
    # Two legal islands. The old incorrect "vertices as outline" approach
    # could bridge the gap even though no NavigationPolygon covered it.
    poly.vertices = PackedVector2Array([
        Vector2(-900, -800), Vector2(-120, -800),
        Vector2(-120, 800), Vector2(-900, 800),
        Vector2(120, -800), Vector2(900, -800),
        Vector2(900, 800), Vector2(120, 800)])
    poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
    poly.add_polygon(PackedInt32Array([4, 5, 6, 7]))
    nav.navigation_polygon = poly
    return nav

func _count_collider_bodies(node: Node) -> int:
    var total := 1 if node is StaticBody3D else 0
    for child in node.get_children():
        total += _count_collider_bodies(child)
    return total

func _run() -> void:
    var bridge := BRIDGE.new()
    bridge.scenery = Node3D.new()
    bridge.is_ready = true
    _check(not bridge.install_verified_citadel_art(),
        "art installation rejected without verified route")
    _check(not bridge.set_citadel_art_enabled(true),
        "GLB cannot be shown without being installed")
    var islands := _gap_region()
    _check(not bridge._citadel_inside_authoritative_polygon(
        islands, Vector2.ZERO), "gap between legal nav islands is blocked")
    _check(bridge._citadel_inside_authoritative_polygon(
        islands, Vector2(-500, 0)), "indexed nav polygon 0 remains walkable")
    _check(bridge._citadel_inside_authoritative_polygon(
        islands, Vector2(500, 0)), "indexed nav polygon 1 remains walkable")
    var nav := _rect(Vector2(-9000, -9000), Vector2(9000, 9000))
    var start_px: Vector2 = bridge.to_2d(Vector3.ZERO)
    var end_px: Vector2 = bridge.to_2d(Vector3(0.0, 0.0, 9.0))
    _check(bridge._citadel_route_inside_navigation(
        start_px, end_px, nav, 7.5),
        "the entire measured 9m route fits real nav geometry")
    _check(bridge.install_verified_citadel_grade(
        start_px, end_px, nav, 9, 1.8, 7.5),
        "9m grade installs only with verified original nav")
    _check(not bridge.citadel_grade_preview,
        "painted geometry remains the default")
    _check(bridge.install_verified_citadel_art(),
        "art-only 220-mesh GLB attaches to physical route assembly")
    _check(not bridge.install_verified_citadel_art(),
        "duplicate GLB import denied")
    _check(bridge.citadel_art_root != null,
        "art root retained for reversible presentation")
    _check(bridge.citadel_art_mesh_count == 220,
        "220 imported GLB meshes independently indexed")
    _check(bridge.citadel_art_root.transform == Transform3D.IDENTITY,
        "GLB does not acquire an unmeasured offset or scaling")
    _check(not bridge.citadel_art_root.visible,
        "new GLB is hidden until explicitly enabled with F4 on")
    _check(_count_collider_bodies(bridge.citadel_art_root) == 0,
        "art mesh introduces no duplicate physics or navigation authority")
    _check(_count_collider_bodies(bridge.citadel_grade) == 64,
        "the one existing physical grade retains exactly 64 bodies")
    var assembly: Node3D = bridge.citadel_grade.get_node(
        "AuthoritativeRoute_VisualMasonry_2DNavUnchanged")
    var original_mesh: MeshInstance3D = assembly.get_node("Physical_Tread_01")
    var original_collision: StaticBody3D = assembly.get_node(
        "Physical_Tread_01_Collision")
    _check(original_mesh.visible,
        "original procedural stair preview remains available")
    _check(original_collision.collision_layer == 0,
        "before F4, 3D stair collision is disabled")
    _check(bridge.set_citadel_art_enabled(true),
        "art can be selected without accidentally enabling F4")
    _check(not bridge.citadel_art_root.visible,
        "art is still hidden while physical grade preview is off")
    _check(not original_mesh.visible,
        "when art selected, only procedural visuals are hidden")
    _check(bridge.set_citadel_grade_preview(true),
        "F4-equivalent grade preview explicitly enabled")
    _check(bridge.citadel_art_root.visible,
        "GLB is now rendered inside the actual grade route transform")
    _check(not original_mesh.visible,
        "do not render two overlapping stair surfaces")
    _check(original_collision.collision_layer == 1,
        "3D physics remains enabled beneath replacement visuals")
    _check(bridge._citadel_height_at(end_px) > 1.7,
        "F10 painted Knight still samples 1.8m upper grade")
    _check(bridge.citadel_grade.status().physics_3d_colliders == 64,
        "GLB visual swap does not duplicate 3D collision")
    _check(not bridge.set_citadel_grade_preview(false),
        "F4 toggling off restores painted default")
    _check(not bridge.citadel_art_root.visible,
        "F4 off hides the GLB even if previously selected")
    _check(original_collision.collision_layer == 0,
        "F4 off has no invisible physical colliders")
    _check(bridge._citadel_height_at(end_px) == 0.0,
        "F10 height reset is absolute, not cumulative")
    _check(not bridge.set_citadel_art_enabled(false),
        "return to procedural fallback without enabling F4")
    _check(original_mesh.visible,
        "all original procedural meshes restored after art disable")
    _check(bridge.set_citadel_grade_preview(true),
        "procedural preview can be restored independently")
    _check(original_mesh.visible and not bridge.citadel_art_root.visible,
        "exclusive visuals avoid double exposure")
    _check(bridge.citadel_grade.status().physics_3d_colliders == 64,
        "64 known collision proxies survive multiple toggles")
    _check(not bridge.citadel_art_enabled,
        "bridge restores the actual active visual path")
    _check(bridge.citadel_art_mesh_count == 220,
        "mesh inventory survives a complete art/fallback toggle")
    # Discard the isolated harness rather than leaving physics/Nav RIDs live
    # in the headless test process. The real gameplay tree owns this lifetime.
    bridge.scenery.free()
    nav.free()
    islands.free()
    bridge.free()
    if errors.is_empty():
        print("CITADEL_ART_SWAP_V16 PASS %d/%d" % [checks, checks])
        quit(0)
    else:
        printerr("CITADEL_ART_SWAP_V16 FAIL %d/%d" % [
            errors.size(), checks])
        quit(1)
