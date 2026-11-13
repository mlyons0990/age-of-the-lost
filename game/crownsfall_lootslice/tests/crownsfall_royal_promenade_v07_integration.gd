extends SceneTree
## Existing game remains authoritative: test real 2D nav across Central Plaza
## to the new Royal Promenade, plus the matching 3D visual district.
var assertions := 0
var failures := 0
func check(ok: bool,label: String) -> void:
    assertions += 1
    if ok:
        print("PASS V07: ",label)
    else:
        failures += 1
        push_error("FAIL V07: "+label)
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    change_scene_to_file("res://main.tscn")
    for i in 12: await physics_frame
    var g = current_scene
    if g == null: quit(1);return
    if g.hud.start_panel != null:
        g.hud.start_panel.queue_free()
        g.hud.start_panel=null
        g.hud._refresh_pause()
    var original=g.capture_save()
    var player=g.player
    check(g.city_district_07 != null,"Royal Promenade is part of the original playable main scene")
    check(g.city_district_07.navigation != null,"Its authoritative NavigationRegion2D is connected")
    check(g.city_district_07.status().nav_triangles > 0,"Triangulated floor has walkable nav")
    check(g.city_district_07.art.visible,"Original painted mode supports the new street")
    check(g._valid_floor_point(Vector2(2230,2250)),"Royal Promenade destination is valid city ground")
    check(not g._valid_floor_point(Vector2(3300,2700)),"Outside the city district remains impassable")
    check(g.cam.limit_bottom >= 2900,"Camera can follow to the city south end")
    var nav_map = g.get_world_2d().navigation_map
    var nav_iterations=NavigationServer2D.map_get_iteration_id(nav_map)
    check(nav_iterations > 0,"NavigationServer2D processed the connected city regions")
    var start=Vector2(2070,1440)
    var end=Vector2(2230,2420)
    var path=NavigationServer2D.map_get_path(nav_map,start,end,true)
    print("AOTL_V07_NAV_PATH ",path)
    check(path.size() >= 2,"A real Godot navigation path connects the central gate and district")
    if path.size() >= 2:
        check(path[0].distance_to(start) < 90,"City route begins at the original plaza gate")
        check(path[-1].distance_to(end) < 15,"City route reaches the Royal Promenade destination")
    check(player == g.player,"No duplicate player is created")
    check(g.toggle_live_25d(),"Integrated city scenery starts")
    var bridge=g.live_25d
    check(bridge.city_district_3d != null,"3D connected city shell is installed")
    check(bridge.city_district_3d.status().houses == 12,"Twelve articulated modular architectural facades loaded")
    check(bridge.city_district_3d.status().physics_collision_shells == 12,"Twelve test-only 3D static collision shells match the houses")
    check(bridge.city_district_3d.status().collision_overlaps_authoritative_2d_nav.is_empty(),"No building collider overlaps the authoritative city walkable region")
    check(bridge.city_district_3d.status().nav_surface,"3D painted district floor uses same 2D nav outline")
    check(not g.city_district_07.art.visible,"2D district painting hides cleanly during true 3D view")
    check(bridge.knight_depth_enabled == false,"Real source-painted knight remains default visual")
    check(not g.toggle_live_25d(),"Original 2D city presentation restores")
    check(g.city_district_07.art.visible,"Royal Promenade source painting returns")
    check(g.player == player,"The actual original player remains in place")
    check(JSON.stringify(g.capture_save()) == JSON.stringify(original),"Switching district render modes preserves save snapshot")
    print("AOTL PHASE07 CONNECTED CITY: ",assertions-failures,"/",assertions," passed")
    quit(0 if failures==0 else 1)
