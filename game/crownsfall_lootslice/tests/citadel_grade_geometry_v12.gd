extends SceneTree
## Headless validation: godot --headless --path game/crownsfall_lootslice \
## --script res://tests/citadel_grade_geometry_v12.gd
const CitadelGrade := preload("res://scripts/two_point_five_d/citadel_grade_geometry_v12.gd")
var assertions := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _world(p: Vector2) -> Vector3:
    return Vector3(p.x / 100.0, 0.0, p.y / 100.0)

func _check(condition: bool, label: String) -> void:
    assertions += 1
    if not condition:
        failures.append(label)
        printerr("FAIL: " + label)

func _run() -> void:
    var preview := CitadelGrade.new()
    root.add_child(preview)
    _check(not preview.install(Vector2.ZERO, Vector2.ZERO,
        Callable(self, "_world")), "reject zero-length stairs")
    _check(not preview.install(Vector2.ZERO, Vector2(0, 900),
        Callable(self, "_world"), 1), "reject one riser")
    _check(preview.install(Vector2.ZERO, Vector2(0, 900),
        Callable(self, "_world"), 9, 1.8, 7.5), "install valid geometry")
    _check(not preview.install(Vector2.ZERO, Vector2(0, 900),
        Callable(self, "_world")), "prevent duplicate geometry")
    var stat: Dictionary = preview.status()
    _check(stat.treads == 9, "nine real tread meshes")
    _check(stat.arch_voussoirs == 32, "thirty-two actual arch stones")
    _check(stat.physics_3d_colliders == 9 + 18 + 1 + 2 + 2 + 32,
        "tread, parapet, landing, pier and arch colliders")
    _check(stat.navigation_authority == "existing NavigationRegion2D",
        "visual world leaves 2D authority intact")
    _check(stat.real_player_height_integration == false,
        "height integration is not falsely claimed")
    _check(is_equal_approx(preview.elevation_at(Vector2(0, 0)), 0.0),
        "at entrance start at zero height")
    _check(is_equal_approx(preview.elevation_at(Vector2(0, 900)), 1.8),
        "at final riser height is 1.8m")
    _check(is_equal_approx(preview.elevation_at(Vector2(0, 1100)), 1.8),
        "upper landing holds final elevation")
    for step in range(9):
        # The foot height must equal the actual collision-tread surface
        # at its center, not float through or sink below the painted step.
        var center_z: float = (float(step) + 0.5) * 100.0
        var ground_height: float = preview.elevation_at(Vector2(0.0, center_z))
        var physical_top: float = float(step + 1) * 1.8 / 9.0
        _check(absf(ground_height - physical_top) < 0.0001,
            "painted feet coincide with tread %d top" % (step + 1))
    _check(preview.elevation_at(Vector2(700, 400)) < 0.0,
        "outside corridor returns sentinel")
    _check(preview.elevation_at(Vector2(0, -300)) < 0.0,
        "southern plaza is not silently altered")
    var previous := -1.0
    for n in range(91):
        var h: float = preview.elevation_at(Vector2(0, float(n) * 10.0))
        _check(h >= previous - 0.0001, "no downward pop at stair sample %d" % n)
        previous = h
    _check(preview.get_child_count() == 1, "single non-destructive 3D assembly")
    if failures.is_empty():
        print("CITADEL_GRADE_V12 PASS %d/%d" % [assertions, assertions])
        quit(0)
    else:
        printerr("CITADEL_GRADE_V12 FAIL %d/%d" % [failures.size(), assertions])
        quit(1)
