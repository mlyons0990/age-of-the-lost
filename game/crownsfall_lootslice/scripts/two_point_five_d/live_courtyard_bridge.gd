extends CanvasLayer
## Optional, integrated Crownsfall 2.5D renderer.
## The existing Node2D game is the ONLY gameplay authority: movement, NavServer2D,
## AI, loot, transactions, quest flags, skills, HUD, save schema and input are unchanged.
## This is *scenery behind* the genuine painted sprites, not a new 3D gameplay fork.
## F8 toggles this renderer; the approved painted plaza is always recoverable.

const COURTYARD := preload("res://scripts/two_point_five_d/crownsfall_courtyard_25d.gd")
const GD := preload("res://scripts/game_data.gd")
const RIGHT := Vector3(0.70710678, 0.0, -0.70710678)
const TOWARDS_CAMERA := Vector3(0.70710678, 0.0, 0.70710678)
const VIEW_OFFSET := Vector3(12.8, 16.4, 12.8)
const VIEW_ELEVATION_SINE := 16.4 / sqrt(12.8 * 12.8 * 2.0 + 16.4 * 16.4)
const WORLD_ORIGIN := Vector2(1350.0, 1020.0)

var game: Node2D
var game_camera: Camera2D
var viewport_3d: SubViewport
var camera_3d: Camera3D
var scenery: Node3D
var screen: SubViewportContainer
var service_nodes: Array[Node3D] = []
var service_markers: Dictionary = {}
var scar_marker: MeshInstance3D
var scar_material: StandardMaterial3D
var is_ready := false
var collision_audit: Dictionary = {}

func _ready() -> void:
    # CanvasLayer -1 draws under the real Node2D actors/HUD; not in the same world.
    layer = -1
    follow_viewport_enabled = false
    if game == null or game_camera == null:
        push_error("AOTL scenery bridge requires the original game and its Camera2D")
        return
    screen = SubViewportContainer.new()
    screen.name = "Scenery3D_VisualOnly_NoInput"
    screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    screen.stretch = true
    add_child(screen)
    viewport_3d = SubViewport.new()
    viewport_3d.name = "IndependentVisual3DWorld"
    viewport_3d.own_world_3d = true
    viewport_3d.handle_input_locally = false
    viewport_3d.disable_3d = false
    viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport_3d.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    viewport_3d.size = Vector2i(1440, 810)
    screen.add_child(viewport_3d)
    scenery = COURTYARD.new()
    viewport_3d.add_child(scenery)
    # The rendered walkable surface and navigation polygon now share one source.
    # In particular, this is not a hand-drawn second area the player could fall off.
    scenery.install_painted_walkway(PackedVector2Array(game.WALKABLE), Callable(self, "to_3d"))
    collision_audit = audit_visual_collision_footprints()
    camera_3d = Camera3D.new()
    camera_3d.name = "Follow_OriginalPlayer2D_NoIndependentMovement"
    camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
    viewport_3d.add_child(camera_3d)
    camera_3d.current = true
    _build_service_signposts()
    is_ready = true
    sync_view()

func to_3d(painted_world: Vector2) -> Vector3:
    # Fixed affine ground transform aligned to AOTL's 88px/unit navigation and
    # the orthographic camera. Source coordinates NEVER mutate.
    var delta := painted_world - WORLD_ORIGIN
    return RIGHT * (delta.x / GD.U) + TOWARDS_CAMERA * (delta.y / (GD.U * VIEW_ELEVATION_SINE))

func to_2d(ground_point: Vector3) -> Vector2:
    return WORLD_ORIGIN + Vector2(ground_point.dot(RIGHT) * GD.U, ground_point.dot(TOWARDS_CAMERA) * GD.U * VIEW_ELEVATION_SINE)

func audit_visual_collision_footprints() -> Dictionary:
    # Every existing 3D collision pedestal/column is tested against the exact
    # current 2D walking polygon. No independent 3D pathfinding is introduced.
    # A collision crossing into the game floor must be authored into 2D nav
    # before it is eligible to become a blocking object (see Phase 06 gate).
    var boundary := PackedVector2Array(game.WALKABLE)
    var overlapping: Array[String] = []
    var nearest_edge_px := INF
    var count := 0
    for footprint in scenery.collidable_world_footprints():
        count += 1
        var x: float = footprint.x
        var z: float = footprint.z
        var hx: float = footprint.width * 0.5
        var hz: float = footprint.depth * 0.5
        var corners := PackedVector2Array([
            to_2d(Vector3(x - hx, 0, z - hz)),
            to_2d(Vector3(x + hx, 0, z - hz)),
            to_2d(Vector3(x + hx, 0, z + hz)),
            to_2d(Vector3(x - hx, 0, z + hz)),
        ])
        for c in corners:
            for i in boundary.size():
                nearest_edge_px = minf(nearest_edge_px, c.distance_to(Geometry2D.get_closest_point_to_segment(c, boundary[i], boundary[(i + 1) % boundary.size()])))
        var clipping: Array[PackedVector2Array] = Geometry2D.intersect_polygons(corners, boundary)
        var collision_inside := false
        for polygon in clipping:
            if polygon.size() >= 3:
                var twice_area := 0.0
                for i in polygon.size():
                    twice_area += polygon[i].cross(polygon[(i + 1) % polygon.size()])
                if absf(twice_area) > 0.005:
                    collision_inside = true
        if collision_inside:
            overlapping.append(String(footprint.id))
    if not overlapping.is_empty():
        push_warning("AOTL: physical 3D props overlap original 2D nav; collision authoring required: " + str(overlapping))
    return {"audited": count, "inside_walkable": overlapping, "nav_authoritative": true, "screen_projection_px": 1.0, "closest_edge_px": nearest_edge_px}

func _build_service_signposts() -> void:
    # Their centers come from main.SERVICES, the real E-interaction locations,
    # not independent lookalike coordinates. 2D service text remains functional.
    for id in game.SERVICES:
        var entry: Dictionary = game.SERVICES[id]
        var pos_3d := to_3d(entry["pos"])
        var material := StandardMaterial3D.new()
        material.albedo_color = Color(String(entry["color"]))
        material.roughness = 0.83
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.27
        mesh.bottom_radius = 0.37
        mesh.height = 0.28
        mesh.radial_segments = 12
        var marker := MeshInstance3D.new()
        marker.name = "Service_" + String(id) + "_VisualOnly"
        marker.mesh = mesh
        marker.material_override = material
        marker.position = pos_3d + Vector3.UP * 0.16
        scenery.add_child(marker)
        service_nodes.append(marker)
        service_markers[id] = marker
    var circle := TorusMesh.new()
    circle.inner_radius = 0.88
    circle.outer_radius = 1.06
    circle.rings = 16
    circle.ring_segments = 40
    var seal := MeshInstance3D.new()
    scar_marker = seal
    seal.name = "RealityScar_2DQuestPosition_VisualOnly"
    seal.mesh = circle
    var seal_mat := StandardMaterial3D.new()
    seal_mat.albedo_color = Color(0.40, 0.26, 0.68, 0.68)
    seal_mat.emission_enabled = true
    seal_mat.emission = Color("55408e")
    seal_mat.emission_energy_multiplier = 0.24
    seal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    seal.material_override = seal_mat
    scar_material = seal_mat
    seal.position = to_3d(game.RIFT_POS) + Vector3.UP * 0.10
    scenery.add_child(seal)

func set_active(active: bool) -> void:
    visible = active
    set_process(active)
    if viewport_3d != null:
        viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
    if active:
        sync_view()
        sync_world_state()

func sync_world_state() -> void:
    if not is_ready or not is_instance_valid(game):
        return
    # Read-only presentation signals: no resource writes, no quests or combat rules.
    var scar_active: bool = bool(game.rift.get("active", false))
    if scar_material != null:
        scar_material.emission_energy_multiplier = 1.40 if scar_active else 0.20
        scar_material.albedo_color = Color(0.65, 0.32, 0.90, 0.92) if scar_active else Color(0.40, 0.26, 0.68, 0.68)
    for id in service_markers:
        var marker: MeshInstance3D = service_markers[id]
        var material: StandardMaterial3D = marker.material_override
        var near: bool = GD.gdist(game.player.position, game.SERVICES[id].pos) <= 1.8 and not game.player.dead
        material.emission_enabled = near
        if near:
            material.emission = material.albedo_color
            material.emission_energy_multiplier = 0.70

func sync_view() -> void:
    if not is_ready or not is_instance_valid(game_camera):
        return
    var size := get_viewport().get_visible_rect().size
    if size.x <= 0 or size.y <= 0:
        return
    var s := Vector2i(maxi(1, int(round(size.x))), maxi(1, int(round(size.y))))
    if viewport_3d.size != s:
        viewport_3d.size = s
    # Keep 2D camera smoothing and zoom authoritative. The 3D camera is a
    # projection of its centre, not a second movement controller.
    var ground := to_3d(game_camera.get_screen_center_position())
    camera_3d.global_position = ground + VIEW_OFFSET
    camera_3d.look_at(ground, Vector3.UP)
    camera_3d.size = maxf(4.0, float(s.y) / (GD.U * game_camera.zoom.y))

func _process(_delta: float) -> void:
    sync_view()
    sync_world_state()

func status() -> Dictionary:
    return {
        "visual_only": true,
        "real_game": game,
        "real_player": game.player if is_instance_valid(game) else null,
        "real_hud": game.hud if is_instance_valid(game) else null,
        "real_nav": game.nav_region if is_instance_valid(game) else null,
        "scenery_ready": is_ready,
        "service_count": service_nodes.size(),
        "has_3d_world": viewport_3d != null and viewport_3d.own_world_3d,
        "camera_size": camera_3d.size if camera_3d != null else 0.0,
        "painted_walkway_triangles": scenery.painted_walkway_triangle_count if is_instance_valid(scenery) else 0,
        "painted_walkway_area_px2": scenery.painted_walkway_area_pixels if is_instance_valid(scenery) else 0.0,
        "audited_collision_props": collision_audit.get("audited", 0),
        "collision_overlaps_nav": collision_audit.get("inside_walkable", []),
    }
