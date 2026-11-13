extends SceneTree
## Real gameplay integration: the new district uses the existing town menus,
## original player, exact navigation world and unchanged save schema.
var checked := 0
var failed := 0

func check(ok: bool, msg: String) -> void:
	checked += 1
	if ok: print("PASS CITY07.1: ", msg)
	else:
		failed += 1
		push_error("FAIL CITY07.1: " + msg)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://main.tscn")
	for i in 13: await physics_frame
	var g = current_scene
	check(g != null, "Main AOTL game scene loaded")
	if g == null: quit(1); return
	if g.hud.start_panel != null:
		g.hud.start_panel.queue_free()
		g.hud.start_panel = null
		g.hud._refresh_pause()
	var original_player = g.player
	var location: Vector2 = g.player.position
	var before: String = JSON.stringify(g.capture_save())
	var City = preload("res://scripts/two_point_five_d/crownsfall_royal_promenade_v07.gd")
	var cases := [
		{"service":"promenade_smith","page":"merchant"},
		{"service":"promenade_archivist","page":"lore"},
		{"service":"promenade_caravan","page":"stash"}
	]
	check(g.SERVICES.size() == 7, "Four plaza services and three district services available")
	for sample in cases:
		var id: String = String(sample.service)
		var page: String = String(sample.page)
		var at: Vector2 = g.SERVICES[id].pos
		check(City.contains(at), id + " is on district walkable ground")
		check(g._valid_floor_point(at), id + " accepted by game's real floor validator")
		check(g.world.has_node("ArtOnly_NPC_" + id), id + " has source-painted NPC stand-in")
		var sprite = g.world.get_node("ArtOnly_NPC_" + id).get_node("CanonClassIdle_ProvisionalNPC")
		check(sprite.texture != null, id + " reuses approved source sprite")
		check(g.SERVICES[id].page == page, id + " maps to the existing menu")
		g.player.position = at
		for k in 2: await process_frame
		g.interact()
		check(g.hud.page == page, id + " opens the LIVE existing " + page + " page with E")
		g.hud.close_page()
	g.player.position = location
	check(JSON.stringify(g.capture_save()) == before, "Town visits don't modify save schema or equipment")
	check(g.player == original_player, "No duplicate gameplay player was created")
	check(g.toggle_live_25d(), "3D city view enabled")
	check(g.live_25d.status().service_count == 7, "3D scene contains all seven authoritative service markers")
	check(not g.toggle_live_25d(), "Painted city restores safely")
	check(g.player == original_player, "Player survives render mode toggles")
	print("AOTL PHASE07.1 CONNECTED CITY SERVICES: ", checked - failed, "/", checked, " passed")
	quit(0 if failed == 0 else 1)
