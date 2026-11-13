extends SceneTree
## Phase21: read-only explicit candidate GLB import smoke test in real Godot.
## No scene insertion into the approved game and no scene/save mutation.
##
## CI:
## godot --headless --path game/crownsfall_lootslice \
##   --script res://tests/citadel_external_glb_import_v21.gd \
##   -- --model=res://assets/25d/citadel/AOTL_Citadel_MasonryArt_v17.glb --variant=v17
##
## After placing an independently verified optimized GLB in a disposable clone:
## godot --headless --path game/crownsfall_lootslice \
##   --script res://tests/citadel_external_glb_import_v21.gd \
##   -- --model=ABSOLUTE_PATH_TO_V10_GLB --variant=v10
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_execute")

func _check(condition: bool, note: String) -> void:
    checks += 1
    if not condition:
        failures.append(note)
        printerr("CITADEL_EXTERNAL_GLB_V21 FAIL: " + note)

func _node_walk(node: Node, names: Dictionary, totals: Dictionary) -> void:
    if node is CollisionObject3D or node is CollisionShape3D:
        totals["collision"] = int(totals.get("collision", 0)) + 1
    if node is MeshInstance3D:
        names[String(node.name)] = node
        totals["mesh_nodes"] = int(totals.get("mesh_nodes", 0)) + 1
        if node.mesh != null:
            for surface in range(node.mesh.get_surface_count()):
                totals["surfaces"] = int(totals.get("surfaces", 0)) + 1
    for child in node.get_children():
        _node_walk(child, names, totals)

func _args() -> Dictionary:
    var result := {"model":"", "variant":"v10"}
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--model="):
            result["model"] = argument.substr(8)
        if argument.begins_with("--variant="):
            result["variant"] = argument.substr(10)
    return result

func _execute() -> void:
    var args := _args()
    var filename: String = String(args["model"])
    var variant: String = String(args["variant"])
    _check(not filename.is_empty(), "explicit GLB model path is mandatory")
    _check(variant in ["v10", "v17"], "candidate variant is explicitly selected")
    if checks != 2 or not failures.is_empty():
        quit(1)
        return
    _check(FileAccess.file_exists(filename), "GLB exists at explicit selected path")
    if not failures.is_empty():
        quit(1)
        return
    var document := GLTFDocument.new()
    var state := GLTFState.new()
    var err: Error = document.append_from_file(filename, state)
    _check(err == OK, "Godot GLTFDocument parses actual portable GLB")
    if err != OK:
        quit(1)
        return
    var scene: Node = document.generate_scene(state)
    _check(scene is Node3D, "GLB becomes transformable 3D scene")
    if scene == null or not (scene is Node3D):
        quit(1)
        return
    root.add_child(scene)
    var names: Dictionary = {}
    var totals: Dictionary = {"collision":0, "mesh_nodes":0, "surfaces":0}
    _node_walk(scene, names, totals)
    var expected_count := 309 if variant == "v10" else 1197
    _check(int(totals["mesh_nodes"]) == expected_count,
        "expected %d 3D mesh nodes imported" % expected_count)
    _check(int(totals["collision"]) == 0,
        "external visual GLB never installs gameplay collision")
    _check(int(totals["surfaces"]) > 0,
        "imported GLB retains visible mesh surfaces")
    var prefix := "GATE_Gothic_Voussoir_" if variant == "v10" else "GATE_GothicVoussoir_"
    for i in range(1, 33):
        _check(names.has(prefix + ("%02d" % i)),
            "Gothic voussoir %02d survives Godot import" % i)
    for i in range(1, 10):
        _check(names.has("STAIR_Tread_%02d" % i),
            "stair tread %02d survives Godot import" % i)
    _check(not names.has("StaticBody3D"),
        "GLB does not carry player collision authority")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("CITADEL_EXTERNAL_GLB_V21 PASS %d/%d (%s)" %
            [checks,checks,variant])
        quit(0)
    else:
        printerr("CITADEL_EXTERNAL_GLB_V21 FAIL %d/%d (%s)" %
            [failures.size(),checks,variant])
        quit(1)
