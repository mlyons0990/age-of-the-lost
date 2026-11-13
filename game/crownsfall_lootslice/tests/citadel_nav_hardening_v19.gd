extends SceneTree
## Phase19: Route sampling must reject narrow gaps, shoulder clipping and
## unsupported long routes before installing any optional masonry.
const BRIDGE := preload("res://scripts/two_point_five_d/live_courtyard_bridge.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _check(value: bool, explanation: String) -> void:
    checks += 1
    if not value:
        failures.append(explanation)
        printerr("CITADEL_NAV_HARDENING_V19 FAIL: " + explanation)

func _nav_from_rects(bridge: Node, rects: Array, offset: Vector2 = Vector2.ZERO,
        turn: float = 0.0) -> NavigationRegion2D:
    var nav := NavigationRegion2D.new()
    nav.position = offset
    nav.rotation = turn
    root.add_child(nav)
    var poly := NavigationPolygon.new()
    var all_points := PackedVector2Array()
    for rect in rects:
        var begin: Vector2 = rect[0]
        var end: Vector2 = rect[1]
        var local_corners := [
            bridge.to_2d(Vector3(begin.x, 0.0, begin.y)),
            bridge.to_2d(Vector3(end.x, 0.0, begin.y)),
            bridge.to_2d(Vector3(end.x, 0.0, end.y)),
            bridge.to_2d(Vector3(begin.x, 0.0, end.y))]
        var indices := PackedInt32Array()
        for corner in local_corners:
            indices.append(all_points.size())
            all_points.append(nav.to_local(corner))
        poly.add_polygon(indices)
    poly.vertices = all_points
    nav.navigation_polygon = poly
    return nav

func _run() -> void:
    var bridge := BRIDGE.new()
    bridge.scenery = Node3D.new()
    bridge.is_ready = true
    var start_px: Vector2 = bridge.to_2d(Vector3.ZERO)
    var end_px: Vector2 = bridge.to_2d(Vector3(0.0, 0.0, 9.0))
    var full := _nav_from_rects(bridge, [[Vector2(-5,-1),Vector2(5,10)]])
    _check(bridge._citadel_route_inside_navigation(start_px,end_px,full,7.5),
        "full 9m central route and near-edge lanes are traversable")
    _check(bridge._citadel_inside_authoritative_polygon(full,
        bridge.to_2d(Vector3(3.6,0,4.0))), "near-edge lane inside true polygon")
    var narrow_gap := _nav_from_rects(bridge, [
        [Vector2(-5,-1),Vector2(5,3.10)],
        [Vector2(-5,3.30),Vector2(5,10)]])
    _check(not bridge._citadel_route_inside_navigation(start_px,end_px,narrow_gap,7.5),
        "0.20m disconnected gap cannot evade adaptive cross-sections")
    _check(bridge._citadel_inside_authoritative_polygon(narrow_gap,
        bridge.to_2d(Vector3(0.0,0,3.0))), "lower island valid")
    _check(bridge._citadel_inside_authoritative_polygon(narrow_gap,
        bridge.to_2d(Vector3(0.0,0,4.0))), "upper island valid")
    _check(not bridge._citadel_inside_authoritative_polygon(narrow_gap,
        bridge.to_2d(Vector3(0.0,0,3.20))), "center gap truly non-walkable")
    var clipped := _nav_from_rects(bridge, [
        [Vector2(-3.38,-1),Vector2(3.38,10)]])
    _check(not bridge._citadel_route_inside_navigation(start_px,end_px,clipped,7.5),
        "7.5m route rejected when shoulders narrow to 6.76m")
    var turned := _nav_from_rects(bridge,
        [[Vector2(-5,-1),Vector2(5,10)]], Vector2(225.0,-193.0),0.45)
    _check(bridge._citadel_route_inside_navigation(start_px,end_px,turned,7.5),
        "nonidentity NavigationRegion2D transform correctly respected")
    _check(not bridge._citadel_route_inside_navigation(start_px,end_px,null,7.5),
        "missing authoritative navigation still fails closed")
    _check(not bridge._citadel_route_inside_navigation(start_px,end_px,full,0.1),
        "invalid clearance width still rejected")
    var far_end := bridge.to_2d(Vector3(0.0,0.0,80.0))
    var long_nav := _nav_from_rects(bridge, [
        [Vector2(-5,-1),Vector2(5,82)]])
    _check(not bridge._citadel_route_inside_navigation(start_px,far_end,long_nav,7.5),
        "implausibly long route rejects undersampled corridor")
    var prior_count := narrow_gap.navigation_polygon.get_polygon_count()
    _check(prior_count==2,
        "two indexed disconnected island polygons preserved")
    _check(not bridge.install_verified_citadel_grade(start_px,end_px,narrow_gap),
        "invalid disconnected route never creates a physical stair")
    _check(bridge.citadel_grade == null, "no geometry installed on invalid route")
    for nav in [full,narrow_gap,clipped,turned,long_nav]:
        nav.queue_free()
    bridge.scenery.free()
    bridge.free()
    await process_frame
    if failures.is_empty():
        print("CITADEL_NAV_HARDENING_V19 PASS %d/%d" % [checks,checks])
        quit(0)
    else:
        printerr("CITADEL_NAV_HARDENING_V19 FAIL %d/%d" % [failures.size(),checks])
        quit(1)
