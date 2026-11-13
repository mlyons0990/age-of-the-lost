extends CanvasLayer
## Optional, integrated Crownsfall 2.5D renderer.
## The existing Node2D game is the ONLY gameplay authority: movement, NavServer2D,
## AI, loot, transactions, quest flags, skills, HUD, save schema and input are unchanged.
## This is *scenery behind* the genuine painted sprites, not a new 3D gameplay fork.
## F8 toggles this renderer; the approved painted plaza is always recoverable.

const COURTYARD := preload("res://scripts/two_point_five_d/crownsfall_courtyard_25d.gd")
const CITY_DISTRICT3D := preload("res://scripts/two_point_five_d/crownsfall_royal_promenade_3d_v07.gd")
const CITY_DISTRICT08_3D := preload("res://scripts/two_point_five_d/crownsfall_merchants_quarter_3d_v08.gd")
const GD := preload("res://scripts/game_data.gd")
const LIVE_KNIGHT := preload("res://scripts/two_point_five_d/knight_depth_billboard.gd")
const CITADEL_GRADE := preload("res://scripts/two_point_five_d/citadel_grade_geometry_v12.gd")
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
var city_district_3d: Node3D
var market_district_3d: Node3D
var screen: SubViewportContainer
var service_nodes: Array[Node3D] = []
var service_markers: Dictionary = {}
var scar_marker: MeshInstance3D
var scar_material: StandardMaterial3D
var is_ready := false
var collision_audit: Dictionary = {}
var knight_depth_avatar: Node3D = null
var knight_depth_enabled := false
## No separate town NPC simulation. These are depth-tested visual proxies
## of the SAME already-instantiated painted NPC nodes in main.world.
var npc_depth_mirrors: Dictionary = {}
var npc_depth_sources: Dictionary = {}
## Phase 13 adapter: no guessed geometry placement. A verified Citadel
## NavigationRegion2D must be supplied by the recovered Phase 11 scene.
var citadel_grade: Node3D = null
var citadel_grade_nav: NavigationRegion2D = null
var citadel_grade_preview := false
var citadel_grade_foot_samples := 0


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
    city_district_3d = CITY_DISTRICT3D.new()
    scenery.add_child(city_district_3d)
    city_district_3d.install(Callable(self, "to_3d"))
    market_district_3d = CITY_DISTRICT08_3D.new()
    scenery.add_child(market_district_3d)
    market_district_3d.install(Callable(self, "to_3d"))

    collision_audit = audit_visual_collision_footprints()
    camera_3d = Camera3D.new()
    camera_3d.name = "Follow_OriginalPlayer2D_NoIndependentMovement"
    camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
    viewport_3d.add_child(camera_3d)
    camera_3d.current = true
    _build_service_signposts()
    _build_town_npc_mirrors()
    is_ready = true
    sync_view()

func to_3d(painted_world: Vector2) -> Vector3:
    # Fixed affine ground transform aligned to AOTL's 88px/unit navigation and
    # the orthographic camera. Source coordinates NEVER mutate.
    var delta := painted_world - WORLD_ORIGIN
    return RIGHT * (delta.x / GD.U) + TOWARDS_CAMERA * (delta.y / (GD.U * VIEW_ELEVATION_SINE))

func to_2d(ground_point: Vector3) -> Vector2:
    return WORLD_ORIGIN + Vector2(ground_point.dot(RIGHT) * GD.U, ground_point.dot(TOWARDS_CAMERA) * GD.U * VIEW_ELEVATION_SINE)

func _citadel_route_inside_navigation(start_px: Vector2, end_px: Vector2,
        route_nav: NavigationRegion2D, clear_width_m: float) -> bool:
    # Fail closed if the actual route is not loaded. Never infer a path from
    # a painting: route and corridor width are measured in the Phase 11 scene.
    if route_nav == null or not is_instance_valid(route_nav):
        return false
    if route_nav.navigation_polygon == null or clear_width_m <= 2.0:
        return false
    var outline: PackedVector2Array = route_nav.navigation_polygon.vertices
    if outline.size() < 3:
        return false
    var from_ground := to_3d(start_px)
    var to_ground := to_3d(end_px)
    var axis := to_ground - from_ground
    axis.y = 0.0
    if axis.length() < 0.5:
        return false
    axis = axis.normalized()
    var side := Vector3(axis.z, 0.0, -axis.x)
    # Test the center and shoulders of 17 cross-sections against the same
    # NavigationRegion2D that the live player uses. No new navigation authority.
    for i in range(17):
        var t := float(i) / 16.0
        var center_3d := from_ground.lerp(to_ground, t)
        for fraction in [-0.40, 0.0, 0.40]:
            var sample_3d := center_3d + side * clear_width_m * float(fraction)
            var sample_world := to_2d(sample_3d)
            if not Geometry2D.is_point_in_polygon(
                    route_nav.to_local(sample_world), outline):
                return false
    return true

func install_verified_citadel_grade(start_px: Vector2, end_px: Vector2,
        route_nav: NavigationRegion2D, steps: int = 9,
        rise_m: float = 1.8, clear_width_m: float = 7.5) -> bool:
    # Call this only from a recovered Phase 11 Citadel scene integration.
    # Does not touch gameplay NavigationServer2D, saves or world districts.
    if citadel_grade != null or not is_ready or not is_instance_valid(scenery):
        return false
    if steps < 2 or rise_m <= 0.0:
        return false
    if not _citadel_route_inside_navigation(start_px, end_px,
            route_nav, clear_width_m):
        push_warning("AOTL: Citadel route not inside authoritative nav corridor")
        return false
    var grade: Node3D = CITADEL_GRADE.new()
    grade.name = "Citadel_PhysicalGrade_OptIn_PaintedDefaultSafe"
    scenery.add_child(grade)
    if not grade.install(start_px, end_px, Callable(self, "to_3d"),
            steps, rise_m, clear_width_m):
        grade.queue_free()
        return false
    citadel_grade = grade
    citadel_grade_nav = route_nav
    citadel_grade.visible = false
    citadel_grade_preview = false
    return true

func set_citadel_grade_preview(enabled: bool) -> bool:
    # F4 caller in the *actual* Phase 11 bridge may opt into this, never
    # force it into the Phase 08 default painted/live modes.
    if citadel_grade == null or not is_instance_valid(citadel_grade):
        return false
    citadel_grade_preview = enabled
    citadel_grade.visible = enabled
    _sync_citadel_service_height()
    sync_knight_depth()
    return citadel_grade_preview

func _citadel_height_at(painted_point: Vector2) -> float:
    if not citadel_grade_preview or citadel_grade == null:
        return 0.0
    if not is_instance_valid(citadel_grade):
        return 0.0
    var sampled: float = citadel_grade.elevation_at(painted_point)
    return maxf(sampled, 0.0)

func _sync_citadel_service_height() -> void:
    if not is_ready or not is_instance_valid(game):
        return
    # Recompute absolute presentation transforms each time; never accumulate
    # Y offsets. Keeps both service markers and their F10 NPC sprites grounded.
    for id in service_markers:
        var sign: MeshInstance3D = service_markers[id]
        var at: Vector2 = game.SERVICES[id].pos
        sign.position = to_3d(at) + Vector3.UP * (0.16 + _citadel_height_at(at))
    for id in npc_depth_mirrors:
        var npc: Sprite3D = npc_depth_mirrors[id]
        var at: Vector2 = game.SERVICES[id].pos
        npc.position = to_3d(at) + Vector3.UP * (1.14 + _citadel_height_at(at))

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

func audit_combined_city_collision() -> Dictionary:
    # A district cannot ignore a neighboring district's nav polygon. The
    # Phase 07 eastern Royal wall originally occupied Phase 08's new street.
    # Audit existing plaza props and ALL facades against the full connected
    # city, not just the polygon owned by a particular visual script.
    var regions: Array[Dictionary] = [
        {"id":"plaza","outline":PackedVector2Array(game.WALKABLE)},
        {"id":"royal_promenade","outline":game.city_district_07.navigation.navigation_polygon.vertices},
        {"id":"merchants_quarter","outline":game.city_district_08.navigation.navigation_polygon.vertices}
    ]
    var candidates: Array[Dictionary] = []
    for physical in scenery.collidable_world_footprints():
        var x: float = physical.x
        var z: float = physical.z
        var hx: float = physical.width * .5
        var hz: float = physical.depth * .5
        var rect := PackedVector2Array([
            to_2d(Vector3(x-hx,0,z-hz)),to_2d(Vector3(x+hx,0,z-hz)),
            to_2d(Vector3(x+hx,0,z+hz)),to_2d(Vector3(x-hx,0,z+hz))
        ])
        candidates.append({"id":"plaza/"+String(physical.id),"outline":rect})
    for source in [
        {"id":"promenade","shells":city_district_3d.collidable_footprints},
        {"id":"merchants","shells":market_district_3d.collidable_footprints}
    ]:
        for physical in source.shells:
            var pos: Vector2 = physical.center
            var hx: float = physical.half_x
            var hy: float = physical.half_y
            candidates.append({
                "id":String(source.id)+"/"+String(physical.id),
                "outline":PackedVector2Array([
                    pos+Vector2(-hx,-hy),pos+Vector2(hx,-hy),
                    pos+Vector2(hx,hy),pos+Vector2(-hx,hy)
                ])
            })
    var intersects: Array[String] = []
    for candidate in candidates:
        for region in regions:
            var pieces: Array[PackedVector2Array] = Geometry2D.intersect_polygons(candidate.outline,region.outline)
            for piece in pieces:
                var twice_area := 0.0
                for i in piece.size():
                    twice_area += piece[i].cross(piece[(i+1)%piece.size()])
                if absf(twice_area) > 1.0:
                    intersects.append(String(candidate.id) + " intrudes " + String(region.id))
    return {
        "districts":regions.size(),
        "audited_colliders":candidates.size(),
        "overlaps":intersects
    }


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

func _build_town_npc_mirrors() -> void:
    # The existing game already owns all service art (and E interactions).
    # We reuse exactly those AtlasTextures in one real World3D. No extra actor,
    # no new collision body and no independent game state.
    for id in game.SERVICES:
        var original_name := "ArtOnly_NPC_" + String(id)
        if not game.world.has_node(original_name):
            continue
        var source: Node2D = game.world.get_node(original_name)
        var original: Sprite2D = source.get_node("CanonClassIdle_ProvisionalNPC")
        if original.texture == null:
            continue
        var mirror := Sprite3D.new()
        mirror.name = "PaintedNPC_DepthMirror_" + String(id)
        mirror.texture = original.texture
        mirror.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        mirror.shaded = false
        mirror.double_sided = true
        mirror.no_depth_test = false
        mirror.render_priority = 12
        mirror.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        mirror.pixel_size = absf(original.scale.x) / GD.U
        # Full 384px source sheet at 0.52 scale: visible height ~2.27m.
        # Place the feet on the ground, not halfway under the 3D painted floor.
        mirror.position = to_3d(game.SERVICES[id].pos) + Vector3.UP * 1.14
        mirror.modulate = original.modulate
        mirror.visible = false
        scenery.add_child(mirror)
        npc_depth_mirrors[id] = mirror
        npc_depth_sources[id] = original

func _set_npc_depth_enabled(enabled: bool) -> void:
    for id in npc_depth_mirrors:
        var mirror: Sprite3D = npc_depth_mirrors[id]
        var source: Sprite2D = npc_depth_sources[id]
        if not is_instance_valid(mirror) or not is_instance_valid(source):
            continue
        mirror.visible = enabled
        source.visible = not enabled

func set_knight_depth_enabled(enabled: bool) -> bool:
    # This only swaps the visual path for the EXISTING Player AnimatedSprite2D.
    # No new actor has physics/input/saves. F10 is an opt-in development toggle.
    if not is_ready or not is_instance_valid(game) or not visible:
        if not enabled:
            knight_depth_enabled = false
            if is_instance_valid(game) and game.player != null:
                game.player.sprite.visible = true
                game.player.shadow.visible = true
            if knight_depth_avatar != null: knight_depth_avatar.visible = false
            _set_npc_depth_enabled(false)
        return false
    if enabled and knight_depth_avatar == null:
        knight_depth_avatar = LIVE_KNIGHT.new()
        knight_depth_avatar.name = "SourcePaintedKnight_True3DDepth_Test"
        scenery.add_child(knight_depth_avatar)
    knight_depth_enabled = enabled
    if knight_depth_avatar != null:
        knight_depth_avatar.visible = enabled
    game.player.sprite.visible = not enabled
    game.player.shadow.visible = not enabled
    _set_npc_depth_enabled(enabled)
    if enabled: sync_knight_depth()
    return enabled

func toggle_knight_depth() -> bool:
    return set_knight_depth_enabled(not knight_depth_enabled)

func sync_knight_depth() -> void:
    if knight_depth_enabled and knight_depth_avatar != null and is_instance_valid(game):
        knight_depth_avatar.sync_from_player(game.player, Callable(self, "to_3d"))
        # The 2D Player position is read-only; only the rendered F10 proxy
        # climbs the authored physical 3D stair, including its contact shadow.
        var ground_rise := _citadel_height_at(game.player.global_position)
        knight_depth_avatar.global_position.y += ground_rise
        if ground_rise > 0.0:
            citadel_grade_foot_samples += 1

func set_active(active: bool) -> void:
    if not active: set_knight_depth_enabled(false)
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
    if citadel_grade != null:
        _sync_citadel_service_height()
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
    sync_knight_depth()

func status() -> Dictionary:
    return {
        "visual_only": true,
        "knight_depth_enabled": knight_depth_enabled,
        "citadel_grade_installed": citadel_grade != null,
        "citadel_geometry_preview": citadel_grade_preview,
        "citadel_grade_height_samples": citadel_grade_foot_samples,
        "citadel_uses_existing_nav": citadel_grade_nav != null,
        "citadel_physical_geometry": citadel_grade.status() if citadel_grade != null else {},
        "painted_town_npc_mirrors": npc_depth_mirrors.size(),
        "town_npc_depth_enabled": knight_depth_enabled,
        "knight_depth_avatar": knight_depth_avatar,
        "real_game": game,
        "real_player": game.player if is_instance_valid(game) else null,
        "real_hud": game.hud if is_instance_valid(game) else null,
        "real_nav": game.nav_region if is_instance_valid(game) else null,
        "scenery_ready": is_ready,
        "service_count": service_nodes.size(),
        "has_3d_world": viewport_3d != null and viewport_3d.own_world_3d,
        "adjacent_royal_promenade": city_district_3d.status() if city_district_3d != null else {},
        "adjacent_merchants_quarter": market_district_3d.status() if market_district_3d != null else {},
        "connected_city_collision": audit_combined_city_collision() if is_ready else {},
        "camera_size": camera_3d.size if camera_3d != null else 0.0,
        "painted_walkway_triangles": scenery.painted_walkway_triangle_count if is_instance_valid(scenery) else 0,
        "painted_walkway_area_px2": scenery.painted_walkway_area_pixels if is_instance_valid(scenery) else 0.0,
        "audited_collision_props": collision_audit.get("audited", 0),
        "collision_overlaps_nav": collision_audit.get("inside_walkable", []),
    }
