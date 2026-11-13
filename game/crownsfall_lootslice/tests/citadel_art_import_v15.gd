extends SceneTree
## Godot 4.6.3 headless import smoke test for the Phase15 art-only GLB.
## Generate the GLB with tools/build_citadel_art_glb_v15.py first, then:
## godot --headless --path game/crownsfall_lootslice --editor --import --quit
## godot --headless --path game/crownsfall_lootslice --script res://tests/citadel_art_import_v15.gd
const MODEL_PATH := "res://assets/25d/citadel/AOTL_Citadel_ArtFallback_v15.glb"
const MANIFEST_PATH := "res://assets/25d/citadel/AOTL_Citadel_ArtFallback_v15.json"
var checks := 0
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, desc: String) -> void:
    checks += 1
    if not ok:
        errors.append(desc)
        printerr("CITADEL V15 FAIL: " + desc)

func _collect_meshes(node: Node, indexed: Dictionary) -> void:
    if node is MeshInstance3D:
        indexed[String(node.name)] = node
    for child in node.get_children():
        _collect_meshes(child, indexed)

func _top_of(mesh: MeshInstance3D) -> float:
    var cube := mesh.get_aabb()
    var top := -INF
    for x in [cube.position.x, cube.end.x]:
        for y in [cube.position.y, cube.end.y]:
            for z in [cube.position.z, cube.end.z]:
                var point: Vector3 = mesh.global_transform * Vector3(x, y, z)
                top = maxf(top, point.y)
    return top

func _run() -> void:
    _check(FileAccess.file_exists(MODEL_PATH), "generated GLB is present")
    _check(FileAccess.file_exists(MANIFEST_PATH), "generated manifest is present")
    if errors.size() > 0:
        quit(1)
        return
    var raw: String = FileAccess.get_file_as_string(MANIFEST_PATH)
    var meta: Variant = JSON.parse_string(raw)
    _check(meta is Dictionary, "manifest parses as JSON")
    if not (meta is Dictionary):
        quit(1)
        return
    _check(meta.get("has_gameplay_colliders", true) == false,
        "3D scene must not own gameplay collision")
    _check(meta.get("world_space", "") == "X_lateral_Y_up_Z_north",
        "artist handoff uses the declared Godot-friendly axes")
    var packed: PackedScene = load(MODEL_PATH) as PackedScene
    _check(packed != null, "Godot 4 imported generated GLB")
    if packed == null:
        quit(1)
        return
    var instance := packed.instantiate()
    root.add_child(instance)
    var meshes := {}
    _collect_meshes(instance, meshes)
    _check(meshes.size() == int(meta.get("nodes", -1)),
        "all GLB mesh nodes survived Godot import")
    _check(meshes.size() >= 200, "full masonry detail is present")
    _check(meshes.has("STAIR_UpperLanding"), "upper landing exists")
    _check(meshes.has("ENV_UpperStoneCourt"), "upper courtyard exists")
    _check(meshes.has("GATE_GothicVoussoir_01"), "first cut Gothic stone exists")
    _check(meshes.has("GATE_GothicVoussoir_32"), "last cut Gothic stone exists")
    for step in range(1, 10):
        var name := "STAIR_Tread_%02d" % step
        _check(meshes.has(name), "tread %d imported" % step)
        if meshes.has(name):
            _check(absf(_top_of(meshes[name]) - float(step) * 0.2) < 0.007,
                "tread %d world height matches 0.2m increments" % step)
    if meshes.has("STAIR_UpperLanding"):
        _check(absf(_top_of(meshes["STAIR_UpperLanding"]) - 1.8) < 0.007,
            "landing matches last tread")
    if meshes.has("ENV_UpperStoneCourt"):
        _check(absf(_top_of(meshes["ENV_UpperStoneCourt"]) - 1.8) < 0.007,
            "upper court matches landing")
    for side in ["L", "R"]:
        var pier := "GATE_Pier_" + side
        _check(meshes.has(pier), "gate pier %s imported" % side)
    _check(instance is Node3D, "imported root remains a transformable 3D scene")
    instance.queue_free()
    if errors.is_empty():
        print("CITADEL_ART_IMPORT_V15 PASS %d/%d" % [checks, checks])
        quit(0)
    else:
        printerr("CITADEL_ART_IMPORT_V15 FAIL %d/%d" % [errors.size(), checks])
        quit(1)
