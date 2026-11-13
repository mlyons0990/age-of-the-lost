extends SceneTree
## Phase19: stress reversible Citadel art/physical preview in the isolated
## engine harness. No new gameplay/nav/save actor, and never enable at startup.
const BRIDGE := preload("res://scripts/two_point_five_d/live_courtyard_bridge.gd")
var assertions := 0
var errors: Array[String] = []
func _initialize() -> void:
    call_deferred("_run")
func _test(value: bool, explanation: String) -> void:
    assertions += 1
    if not value:
        errors.append(explanation)
        printerr("CITADEL_STRESS_V19 FAIL: " + explanation)
func _wide_region() -> NavigationRegion2D:
    var nav := NavigationRegion2D.new()
    var poly := NavigationPolygon.new()
    poly.vertices = PackedVector2Array([
        Vector2(-7000,-7000),Vector2(7000,-7000),
        Vector2(7000,7000),Vector2(-7000,7000)])
    poly.add_polygon(PackedInt32Array([0,1,2,3]))
    nav.navigation_polygon = poly
    return nav
func _body_count(node: Node) -> int:
    var count := 1 if node is StaticBody3D else 0
    for child in node.get_children():
        count += _body_count(child)
    return count
func _run() -> void:
    var bridge := BRIDGE.new()
    bridge.scenery = Node3D.new()
    bridge.is_ready = true
    var nav := _wide_region()
    var before_points := nav.navigation_polygon.vertices.duplicate()
    var start_px := bridge.to_2d(Vector3.ZERO)
    var end_px := bridge.to_2d(Vector3(0,0,9))
    _test(bridge.install_verified_citadel_grade(
        start_px,end_px,nav,9,1.8,7.5), "verified physical route installs")
    _test(bridge.install_verified_citadel_masonry_v17(), "1197-mesh art candidate installs")
    _test(bridge.citadel_art_root != null and bridge.citadel_art_mesh_count == 1197,
        "authored candidate art retained")
    _test(_body_count(bridge.citadel_grade)==64,"exactly 64 physical colliders")
    var original_count := bridge.citadel_grade.get_child_count()
    var assembly := bridge.citadel_grade.get_node(
        "AuthoritativeRoute_VisualMasonry_2DNavUnchanged")
    var collar := assembly.get_node("Physical_Tread_01_Collision") as StaticBody3D
    var procedural := assembly.get_node("Physical_Tread_01") as MeshInstance3D
    _test(collar.collision_layer==0,"preview off defaults collision disabled")
    _test(not bridge.citadel_grade_preview and not bridge.citadel_art_root.visible,
        "painted default has no visible imported geometry")
    for cycle in range(32):
        _test(bridge.set_citadel_art_enabled(true),"cycle %d selected art" % cycle)
        _test(bridge.set_citadel_grade_preview(true),"cycle %d enabled physical grade" % cycle)
        _test(bridge.citadel_art_root.visible and not procedural.visible,
            "cycle %d imported GLB only" % cycle)
        _test(collar.collision_layer==1,
            "cycle %d original physical collider enabled" % cycle)
        _test(not bridge.set_citadel_grade_preview(false),
            "cycle %d F4 preview off" % cycle)
        _test(not bridge.citadel_art_root.visible and collar.collision_layer==0,
            "cycle %d GLB and collision both hidden" % cycle)
        _test(not bridge.set_citadel_art_enabled(false),
            "cycle %d restored procedural candidate" % cycle)
        _test(procedural.visible,
            "cycle %d original procedural art retained" % cycle)
    _test(bridge.set_citadel_art_enabled(true),
        "F8 test: select 3D art as an opt-in candidate")
    _test(bridge.set_citadel_grade_preview(true),
        "F8 test: physical preview initially active")
    bridge.set_active(false)
    _test(not bridge.visible,"F8 painted fallback hides 3D renderer")
    _test(not bridge.citadel_grade_preview and collar.collision_layer==0,
        "F8 fallback disables 3D physical grade colliders")
    _test(not bridge.citadel_art_root.visible,
        "F8 fallback does not leave imported Citadel visible")
    bridge.set_active(true)
    _test(not bridge.citadel_grade_preview and collar.collision_layer==0,
        "reenabling 3D renderer never silently reenables Citadel physics")
    _test(not bridge.citadel_art_root.visible,
        "F8 reactivation retains painted safety until explicit F4 enable")
    bridge.set_citadel_art_enabled(false)
    _test(nav.navigation_polygon.vertices==before_points,
        "original authoritative nav polygon data unchanged")
    _test(bridge.citadel_grade.get_child_count()==original_count,
        "no duplicate 3D grade assembly across repeated toggles")
    _test(_body_count(bridge.citadel_grade)==64,
        "exact 64 original collision nodes after 32 reversals")
    _test(bridge.citadel_art_variant=="v17",
        "art candidate identity remains consistent")
    bridge.scenery.free()
    bridge.free()
    nav.free()
    await process_frame
    if errors.is_empty():
        print("CITADEL_STRESS_V19 PASS %d/%d" % [assertions,assertions])
        quit(0)
    else:
        printerr("CITADEL_STRESS_V19 FAIL %d/%d" % [errors.size(),assertions])
        quit(1)
