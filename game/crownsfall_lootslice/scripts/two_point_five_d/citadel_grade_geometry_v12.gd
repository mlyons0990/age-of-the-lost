extends Node3D
## Crownsfall Citadel graded masonry module.
## Independent of 2D navigation, inventory, quests and saves.
## Install only against a verified Phase 11 route; this file does NOT modify main.gd.
## World coordinate conversion comes from live_courtyard_bridge.to_3d().
const IVORY := Color("d7ccb9")
const LIMESTONE := Color("c1b4a1")
const WARM_SHADOW := Color("b2a590")
const GOLD := Color("b99b65")
const MIN_RUN_M := 0.5

var route_origin := Vector3.ZERO
var route_basis := Basis.IDENTITY
var run_length_m := 0.0
var ascent_m := 0.0
var width_m := 0.0
var steps := 0
## Matches the sculpt's 4m upper gate apron (Phase 14 asset).
var landing_length_m := 4.0
var installed := false
## Toggling off must disable collision too, not just hide meshes.
var collider_nodes: Array[StaticBody3D] = []
var colliders := 0
var arch_stones := 0
var tread_count := 0
var visual_count := 0
var assembly: Node3D = null
var world_converter: Callable

func _material(color: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.metallic = 0.0
    result.roughness = 0.91
    return result

func _masonry(parent: Node3D, label: String, location: Vector3,
        dimensions: Vector3, material: Material,
        solid: bool = true, tilt_radians: float = 0.0) -> MeshInstance3D:
    var stone := MeshInstance3D.new()
    stone.name = label
    var cube := BoxMesh.new()
    cube.size = dimensions
    stone.mesh = cube
    stone.material_override = material
    stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    stone.position = location
    stone.rotation.z = tilt_radians
    parent.add_child(stone)
    visual_count += 1
    if solid:
        var body := StaticBody3D.new()
        body.name = label + "_Collision"
        body.position = location
        body.rotation.z = tilt_radians
        # This module lives in the separate visual World3D. It cannot replace
        # the authoritative 2D walkable polygon or block a 2D actor.
        var shape := CollisionShape3D.new()
        var cuboid := BoxShape3D.new()
        cuboid.size = dimensions
        shape.shape = cuboid
        body.add_child(shape)
        parent.add_child(body)
        collider_nodes.append(body)
        colliders += 1
    return stone

func install(start_px: Vector2, finish_px: Vector2, converter: Callable,
        step_total: int = 9, total_ascent_m: float = 1.8,
        clear_width_m: float = 7.5) -> bool:
    if installed or not converter.is_valid():
        return false
    if step_total < 2 or total_ascent_m <= 0.0 or clear_width_m <= 2.0:
        return false
    var a: Vector3 = converter.call(start_px)
    var b: Vector3 = converter.call(finish_px)
    var ground_run := b - a
    ground_run.y = 0.0
    var length_m := ground_run.length()
    if length_m < MIN_RUN_M:
        return false
    route_origin = a
    run_length_m = length_m
    ascent_m = total_ascent_m
    width_m = clear_width_m
    steps = step_total
    world_converter = converter
    var ahead := ground_run.normalized()
    var lateral := Vector3(ahead.z, 0.0, -ahead.x)
    route_basis = Basis(lateral, Vector3.UP, ahead).orthonormalized()
    assembly = Node3D.new()
    assembly.name = "AuthoritativeRoute_VisualMasonry_2DNavUnchanged"
    assembly.transform = Transform3D(route_basis, route_origin)
    add_child(assembly)
    _build_stairs()
    _build_gateway()
    installed = true
    set_preview_enabled(false)
    return true

func _build_stairs() -> void:
    var tread_materials := [_material(IVORY), _material(LIMESTONE)]
    var stone_edge := _material(WARM_SHADOW)
    var tread_depth := run_length_m / float(steps)
    for i in range(steps):
        var height_m := ascent_m * float(i + 1) / float(steps)
        var center_z := (float(i) + 0.5) * tread_depth
        _masonry(assembly, "Physical_Tread_%02d" % (i + 1),
            Vector3(0.0, height_m * 0.5, center_z),
            Vector3(width_m, height_m, tread_depth + 0.012),
            tread_materials[i % 2])
        # A narrow edge reveals the individual riser without the black
        # horizontal bars that previously dominated the Citadel painting.
        _masonry(assembly, "Soft_Ivory_Riser_Trim_%02d" % (i + 1),
            Vector3(0.0, height_m - 0.035, (i + 1) * tread_depth - 0.035),
            Vector3(width_m + 0.02, 0.055, 0.07),
            stone_edge, false)
        tread_count += 1
        # Lateral coping must stay OUTSIDE the unobstructed nav corridor.
        for side in [-1, 1]:
            _masonry(assembly, "Exterior_Side_Parapet_%02d_%d" % [i, side],
                Vector3(float(side) * (width_m * 0.5 + 0.31),
                    height_m + 0.38, center_z),
                Vector3(0.38, 0.72, tread_depth + 0.012),
                tread_materials[0])
    # Upper walking surface must have the same Y as final tread.
    _masonry(assembly, "Upper_Royal_Landing",
        Vector3(0.0, ascent_m * 0.5, run_length_m + landing_length_m * 0.5),
        Vector3(width_m, ascent_m, landing_length_m + 0.012),
        tread_materials[0])
    for side in [-1, 1]:
        _masonry(assembly, "Upper_Landing_OuterCoping_%d" % side,
            Vector3(float(side) * (width_m * 0.5 + 0.31),
                ascent_m + 0.38, run_length_m + landing_length_m * 0.5),
            Vector3(0.38, 0.72, landing_length_m),
            tread_materials[0])

func _pointed_arch_height(x_m: float, half_clear_m: float,
        spring_height_m: float, point_height_m: float) -> float:
    var fraction := clampf(absf(x_m) / half_clear_m, 0.0, 1.0)
    return spring_height_m + (point_height_m - spring_height_m) * (1.0 - pow(fraction, 0.77))

func _build_gateway() -> void:
    var pale := _material(IVORY)
    var shadow := _material(LIMESTONE)
    var highlight := _material(GOLD)
    var half_clear := width_m * 0.5 + 0.30
    ## Sculpt uses Y=3.25m north of the ninth stair: +9m in route frame.
    var gate_z := run_length_m + 3.25
    var pier_height := 4.14
    for side in [-1, 1]:
        var x := float(side) * (half_clear + 0.64)
        _masonry(assembly, "Citadel_GatePier_%d" % side,
            Vector3(x, ascent_m + pier_height * 0.5, gate_z),
            Vector3(1.0, pier_height, 1.45), pale)
        _masonry(assembly, "GatePier_CarvedCapital_%d" % side,
            Vector3(x, ascent_m + pier_height - 0.08, gate_z),
            Vector3(1.15, 0.24, 1.62), highlight, false)
    var total := 32
    var segment_width := (half_clear * 2.0) / float(total)
    var point_height := 6.05
    for i in range(total):
        var x := -half_clear + (float(i) + 0.5) * segment_width
        var height_at_x := _pointed_arch_height(x, half_clear, pier_height, point_height)
        var next_height := _pointed_arch_height(
            x + segment_width * 0.3, half_clear, pier_height, point_height)
        var tilt := atan2(next_height - height_at_x, segment_width * 0.3)
        _masonry(assembly, "Actual_ArchVoussoir_%02d" % i,
            Vector3(x, ascent_m + height_at_x, gate_z),
            Vector3(segment_width * 1.20, 0.70, 1.40),
            pale if i % 3 != 0 else shadow, true, tilt)
        arch_stones += 1
    _masonry(assembly, "BlueGold_Keystone_Relief",
        Vector3(0.0, ascent_m + point_height - 0.08, gate_z - 0.73),
        Vector3(0.29, 0.41, 0.12), highlight, false)

func set_preview_enabled(enabled: bool) -> void:
    ## Prevent invisible masonry colliders when the preview is disabled.
    visible = enabled
    for body in collider_nodes:
        if is_instance_valid(body):
            body.collision_layer = 1 if enabled else 0
            body.collision_mask = 1 if enabled else 0

func is_on_stair_or_landing(painted_point: Vector2) -> bool:
    if not installed or not world_converter.is_valid():
        return false
    var point: Vector3 = world_converter.call(painted_point)
    var local: Vector3 = route_basis.inverse() * (point - route_origin)
    return absf(local.x) <= width_m * 0.5 and local.z >= 0.0 and local.z <= run_length_m + landing_length_m

func elevation_at(painted_point: Vector2) -> float:
    ## Returns -1 outside stair+landing. Do NOT replace existing world height
    ## with 0 outside the Citadel (that would snap actors on other terrain).
    if not is_on_stair_or_landing(painted_point):
        return -1.0
    var point: Vector3 = world_converter.call(painted_point)
    var local: Vector3 = route_basis.inverse() * (point - route_origin)
    if local.z >= run_length_m:
        return ascent_m
    # Match the real collision top across most of each tread. Blend the
    # leading 15% of each step from the previous surface so the painted
    # depth-avatar does not instantly jump at a riser.
    var t := clampf(local.z / run_length_m, 0.0, 1.0)
    var phase := t * float(steps)
    var step_index := floorf(phase)
    var within_tread := phase - step_index
    var fade := clampf(within_tread / 0.15, 0.0, 1.0)
    var eased := fade * fade * (3.0 - 2.0 * fade)
    return minf(ascent_m, (step_index + eased) * ascent_m / float(steps))

func status() -> Dictionary:
    return {
        "installed": installed,
        "collision_preview_enabled": visible and installed,
        "geometry_is_view_only": true,
        "navigation_authority": "existing NavigationRegion2D",
        "treads": tread_count,
        "arch_voussoirs": arch_stones,
        "physics_3d_colliders": colliders,
        "rendered_masonry_elements": visual_count,
        "total_ascent_m": ascent_m,
        "run_length_m": run_length_m,
        "upper_landing_m": landing_length_m,
        "gate_center_along_route_m": run_length_m + 3.25,
        "arch_clear_span_m": width_m + 0.60,
        "arch_spring_above_upper_floor_m": 4.14,
        "arch_apex_above_upper_floor_m": 6.05,
        "sculpt_reference": "AOTL_Citadel_Sculpt_Phase14",
        "real_player_height_integration": false,
        "painted_default_unchanged": true
    }
