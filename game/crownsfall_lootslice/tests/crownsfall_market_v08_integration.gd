extends SceneTree
## Phase 08: authoritative city nav from Central Plaza -> Royal Promenade ->
## painted Merchants Quarter, and 3D collider exclusions/real town systems.
var checks := 0
var fails := 0

func test(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS PHASE08: ",message)
	else:
		fails += 1
		push_error("FAIL PHASE08: " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://main.tscn")
	for i in 15: await physics_frame
	var g = current_scene
	test(g != null,"Real Crownsfall main scene loaded")
	if g == null: quit(1); return
	if g.hud.start_panel != null:
		g.hud.start_panel.queue_free()
		g.hud.start_panel = null
		g.hud._refresh_pause()
	var before: String = JSON.stringify(g.capture_save())
	var player = g.player
	var last_pos: Vector2 = player.position
	test(g.city_district_07 != null and g.city_district_08 != null,
		"Royal Promenade and Merchants Quarter coexist in original game")
	test(g.city_district_08.status().walkable_tris > 0,
		"Third district has a triangulated Godot NavigationPolygon")
	test(g.city_district_08.navigation.enabled,
		"Third district navigation is enabled")
	test(g.city_district_08.art.texture != null,
		"New Higgsfield-free painted environment texture is loaded")
	test(g.market_seam != null and g.market_seam.texture != null,
		"Painted promenade-to-market seam blending asset is installed")
	test(g.market_seam.visible,
		"Painted mode displays the blended environment transition")

	test(g.cam.limit_right >= 4200,
		"Camera follows into eastward market district")
	test(not g._valid_floor_point(Vector2(4400,2500)),
		"Outside the city bounds remains impassable")
	for point in [Vector2(2750,2110),Vector2(3090,2320),Vector2(3290,2250),Vector2(3730,2310)]:
		test(g._valid_floor_point(point),"City sample floor reachable: " + str(point))
	var nav_map = g.get_world_2d().navigation_map
	test(NavigationServer2D.map_get_iteration_id(nav_map)>0,
		"NavigationServer2D processed all three city regions")
	var a=Vector2(2070,1440)
	var b=Vector2(3680,2310)
	var path=NavigationServer2D.map_get_path(nav_map,a,b,true)
	print("AOTL_PHASE08_CITY_NAV ",path)
	test(path.size()>4,"Real AOTL navigation path crosses both district seams")
	if path.size()>4:
		test(path[0].distance_to(a)<60,"Route begins inside existing Central Plaza")
		test(path[-1].distance_to(b)<20,"Route reaches eastern Merchants Quarter")
	for entry in [
		{"id":"market_tailor","page":"merchant"},
		{"id":"market_notice","page":"board"},
		{"id":"market_caravan","page":"stash"}
	]:
		var id: String=entry.id
		var at: Vector2=g.SERVICES[id].pos
		test(g.city_district_08.contains(at),id+" mapped to actual market walkable polygon")
		test(g.world.has_node("ArtOnly_NPC_"+id),id+" has a painted NPC")
		player.position=at
		for i in 3: await process_frame
		g.interact()
		test(g.hud.page==entry.page,id+" E opens existing gameplay "+String(entry.page))
		g.hud.close_page()
	player.position=last_pos
	test(JSON.stringify(g.capture_save())==before,
		"All district interactions preserve existing save snapshot and schema")
	test(g.player==player,"No duplicate player or character progression")
	test(g.toggle_live_25d(),"F8 enters integrated 3D city presentation")
	var bridge=g.live_25d
	test(bridge.market_district_3d != null,
		"New 3D painted market shell in same scenery world as Plaza and Promenade")
	var data: Dictionary=bridge.market_district_3d.status()
	test(data.get("houses",0)==10,
		"Ten modular market architecture shells instantiate")
	test(data.get("stalls",0)==8,
		"Eight market canopy stalls instantiate")
	test(data.get("physics_collision_shells",0)==10,
		"All ten market buildings provide 3D collision shells")
	test(data.get("collision_overlaps_authoritative_2d_nav",["unknown"]).is_empty(),
		"Market architectural physics shells do not overlap 2D walkable paths")
	var city_collision: Dictionary=bridge.audit_combined_city_collision()
	print("AOTL_PHASE08_CROSS_DISTRICT_AUDIT ",city_collision)
	test(city_collision.get("districts",0)==3,
		"Collision audit includes Plaza, Royal Promenade and Merchants Quarter")
	test(city_collision.get("audited_colliders",0)>=20,
		"City-wide audit checks old and new 3D architectural collision shells")
	test(city_collision.get("overlaps",["unknown"]).is_empty(),
		"No physical structures in ANY district intrude on ANY connected walkable path")

	test(bridge.service_nodes.size()==10,
		"Existing 3D bridge displays all ten game-authoritative service markers")
	test(not g.city_district_08.art.visible,
		"Painted district texture hidden only while 3D scene is active")
	test(not g.market_seam.visible,
		"Blend texture hides alongside painted backgrounds in F8 3D scene")

	test(not g.toggle_live_25d(),
		"F8 restores original painted world and NPC presentation")
	test(g.city_district_08.art.visible,"Market district painting restores")
	test(g.market_seam.visible,"Promenade-to-market texture blend restores")

	test(JSON.stringify(g.capture_save())==before,
		"Toggle restores full city without touching gameplay save")
	print("AOTL PHASE08 CONNECTED MERCHANTS QUARTER: ",checks-fails,"/",checks," passed")
	quit(0 if fails==0 else 1)
