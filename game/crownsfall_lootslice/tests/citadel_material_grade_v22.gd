extends SceneTree
## Phase22 actual optimized binary: independent Godot texture, material and grade gate.
## Run only in isolated test tree; never edits the actual Phase11 playable project.
const ART := "res://assets/25d/citadel/AOTL_Citadel_Higgsfield_Optimized_v10.glb"
var failures: Array[String] = []
var assertions := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, note: String) -> void:
    assertions += 1
    if not ok:
        failures.append(note)
        printerr("CITADEL_V22_MATERIAL_GRADE FAIL " + note)

func _collect(node: Node, meshes: Dictionary, body_count: Array[int]) -> void:
    if node is CollisionObject3D or node is CollisionShape3D:
        body_count[0] += 1
    if node is MeshInstance3D:
        meshes[String(node.name)] = node
    for child in node.get_children():
        _collect(child,meshes,body_count)

func _world_top(mesh: MeshInstance3D) -> float:
    var aabb := mesh.get_aabb()
    var result := -INF
    for x in [aabb.position.x,aabb.end.x]:
        for y in [aabb.position.y,aabb.end.y]:
            for z in [aabb.position.z,aabb.end.z]:
                result = maxf(result, (mesh.global_transform * Vector3(x,y,z)).y)
    return result

func _run() -> void:
    var packed := load(ART) as PackedScene
    _check(packed != null, "optimized v10 is a Godot-imported PackedScene")
    if packed == null:
        quit(1)
        return
    var art := packed.instantiate() as Node3D
    _check(art != null, "real v10 GLB root is Node3D")
    if art == null:
        quit(1)
        return
    root.add_child(art)
    var named: Dictionary = {}
    var bodies: Array[int] = [0]
    _collect(art,named,bodies)
    _check(named.size() == 309, "all 309 real v10 meshes imported")
    _check(bodies[0] == 0, "no gameplay collision authority embedded")
    var unique_materials := {}
    var unique_textures := {}
    var textured_surface_count := 0
    var surfaces := 0
    for mesh_name in named:
        var mesh: MeshInstance3D = named[mesh_name]
        if mesh.mesh == null:
            continue
        for index in range(mesh.mesh.get_surface_count()):
            surfaces += 1
            var material: Material = mesh.get_surface_override_material(index)
            if material == null:
                material = mesh.mesh.surface_get_material(index)
            if material != null:
                unique_materials[material.get_instance_id()] = true
                if material is BaseMaterial3D:
                    var m := material as BaseMaterial3D
                    if m.albedo_texture != null:
                        unique_textures[m.albedo_texture.get_instance_id()] = true
                        textured_surface_count += 1
    _check(surfaces >= 250, "real GLB has at least 250 render surfaces")
    _check(unique_materials.size() >= 5, "at least five distinct imported materials")
    _check(unique_textures.size() >= 2, "both embedded painterly texture images survive import")
    _check(textured_surface_count >= 5, "multiple stone mesh surfaces use real images")
    for i in range(1,10):
        var name := "STAIR_Tread_%02d" % i
        _check(named.has(name), "stair tread %02d exists in imported v10" % i)
        if named.has(name):
            var top := _world_top(named[name])
            _check(absf(top-float(i)*0.2)<0.01,
                "tread %02d top remains %.1fm" % [i,float(i)*0.2])
    for i in range(1,33):
        _check(named.has("GATE_Gothic_Voussoir_%02d" % i),
            "Gothic voussoir %02d preserved" % i)
    art.queue_free()
    await process_frame
    if failures.is_empty():
        print("CITADEL_V22_MATERIAL_GRADE PASS %d/%d meshes=309 materials=%d embedded_textures=%d textured_surfaces=%d" %
            [assertions,assertions,unique_materials.size(),unique_textures.size(),textured_surface_count])
        quit(0)
    else:
        printerr("CITADEL_V22_MATERIAL_GRADE FAIL %d/%d" % [failures.size(),assertions])
        quit(1)
