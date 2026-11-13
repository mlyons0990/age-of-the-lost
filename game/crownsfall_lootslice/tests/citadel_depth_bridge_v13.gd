extends SceneTree
## Phase 13 deterministic geometry-adapter checks. No saved-game mutation.
## godot --headless --path game/crownsfall_lootslice \
##     --script res://tests/citadel_depth_bridge_v13.gd
const Bridge := preload("res://scripts/two_point_five_d/live_courtyard_bridge.gd")
var assertions := 0
var errors: Array[String] = []

func _check(ok: bool, label: String) -> void:
    assertions += 1
    if not ok:
        errors.append(label)
        printerr("FAIL: " + label)

func _initialize() -> void:
    call_deferred("_execute")

func _region(vertices: PackedVector2Array) -> NavigationRegion2D:
    var nav := NavigationRegion2D.new()
    var area := NavigationPolygon.new()
    area.vertices = vertices
    area.add_polygon(PackedInt32Array([0, 1, 2, 3]))
    nav.navigation_polygon = area
    return nav

func _execute() -> void:
    var bridge := Bridge.new()
    # Deliberately no _ready/game scene: testing just the opt-in API.
    bridge.is_ready = true
    bridge.scenery = Node3D.new()
    var narrow := _region(PackedVector2Array([
        Vector2(-50, -50), Vector2(50, -50),
        Vector2(50, 1000), Vector2(-50, 1000)
    ]))
    var wide := _region(PackedVector2Array([
        Vector2(-900, -300), Vector2(900, -300),
        Vector2(900, 1500), Vector2(-900, 1500)
    ]))
    var a := Vector2(0, 0)
    var b := Vector2(0, 900)
    _check(not bridge.install_verified_citadel_grade(a, b, null),
        "reject missing navigation source")
    _check(not bridge.install_verified_citadel_grade(a, b, narrow),
        "reject a route with blocked shoulders")
    _check(bridge.citadel_grade == null, "no grade after rejected nav")
    _check(not bridge.set_citadel_grade_preview(true),
        "cannot show uninstalled geometry")
    _check(bridge.install_verified_citadel_grade(a, b, wide),
        "install route validated against actual nav polygon")
    _check(bridge.citadel_grade != null, "real 3D node exists")
    _check(not bridge.citadel_grade.visible,
        "geometry opt-in off by default")
    var tread: StaticBody3D = bridge.citadel_grade.get_node(
        "AuthoritativeRoute_VisualMasonry_2DNavUnchanged/Physical_Tread_01_Collision")
    _check(tread.collision_layer == 0,
        "no invisible collision when preview starts disabled")
    _check(bridge._citadel_height_at(Vector2(0, 500)) == 0.0,
        "no visual elevation when opt-in disabled")
    _check(bridge.set_citadel_grade_preview(true),
        "enable 3D grade")
    _check(bridge.citadel_grade.visible, "geometry visibility enabled")
    _check(tread.collision_layer == 1,
        "physical 3D stair collision enabled with preview")
    _check(bridge._citadel_height_at(Vector2(0, 900)) > 1.7,
        "upper landing Y is sampled")
    _check(bridge._citadel_height_at(Vector2(1000, 500)) == 0.0,
        "no height adjustment outside corridor")
    _check(not bridge.install_verified_citadel_grade(a, b, wide),
        "reject a duplicate route")
    _check(not bridge.set_citadel_grade_preview(false),
        "disable preview")
    _check(not bridge.citadel_grade.visible, "geometry hidden again")
    _check(tread.collision_layer == 0,
        "stair collider disabled with preview")
    _check(bridge._citadel_height_at(Vector2(0, 900)) == 0.0,
        "height restored after preview is disabled")
    _check(bridge.citadel_grade.status().physics_3d_colliders == 64,
        "phase12 physical masonry retained")
    # Release the isolated bridge and its 64 physics/Nav RIDs before process exit.
    # Tests run without a real SceneTree parent, so this cleanup is essential.
    bridge.scenery.free()
    bridge.free()
    narrow.free()
    wide.free()
    if errors.is_empty():
        print("CITADEL_DEPTH_BRIDGE_V13 PASS %d/%d" % [assertions, assertions])
        quit(0)
    else:
        printerr("CITADEL_DEPTH_BRIDGE_V13 FAIL %d/%d" % [errors.size(), assertions])
        quit(1)
