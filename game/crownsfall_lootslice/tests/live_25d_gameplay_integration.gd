extends SceneTree
## The new 3D courtyard is VISUAL ONLY and must not fork any live game systems.
## Isolated test runner; never run against real user:// saves.

var passed := 0
var failed: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func test_ok(condition: bool, title: String) -> void:
    if condition:
        passed += 1
        print("PASS: ", title)
    else:
        failed.append(title)
        push_error("FAIL: " + title)

func _run() -> void:
    var scene := load("res://main.tscn") as PackedScene
    test_ok(scene != null, "The actual saved game scene exists")
    if scene == null:
        quit(2)
        return
    var game := scene.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    # The new-character onboarding panel pauses the real game; dismiss it in
    # this isolated fixture without writing any player save or changing class.
    if game.hud.start_panel != null:
        game.hud.start_panel.queue_free()
        game.hud.start_panel = null
        game.hud._refresh_pause()
    await process_frame
    var old_bg = game.plaza_art
    var old_player = game.player
    var old_hud = game.hud
    var old_nav = game.nav_region
    var old_pos: Vector2 = old_player.position
    var old_class: String = old_player.class_id
    var old_inventory: Array = old_player.inventory.duplicate(true)
    var old_hotbar: Array = old_player.hotbar.duplicate(true)
    var old_quest: int = old_player.quest
    var old_gold: int = old_player.gold
    var original_state := JSON.stringify(game.capture_save())
    test_ok(not game.live_25d_enabled, "Approved painted town starts as safe default")
    test_ok(old_bg.visible, "Original painted plaza is visible initially")
    test_ok(game.toggle_live_25d(), "F8 bridge can activate in actual game")
    test_ok(game.live_25d != null, "3D scenery renderer created on demand")
    await process_frame
    await process_frame
    await process_frame
    var bridge = game.live_25d
    var state: Dictionary = bridge.status()
    test_ok(state["scenery_ready"], "Courtyard scene instantiated")
    test_ok(state["has_3d_world"], "3D viewport has its own isolated world")
    test_ok(state["visual_only"], "Scenery makes no gameplay authority claim")
    test_ok(state["real_game"] == game, "Actual saved game is the authority")
    test_ok(state["real_player"] == old_player, "Original clickable Warrior/Mage actor is reused")
    test_ok(state["real_hud"] == old_hud, "Functional inventory, skills and HUD reused")
    test_ok(state["real_nav"] == old_nav, "Original NavigationServer2D region remains authoritative")
    test_ok(state["service_count"] == game.SERVICES.size(), "All live service interaction markers placed in 3D")
    test_ok(not old_bg.visible, "Original 2D backdrop hidden only while hybrid is on")
    test_ok(bridge.visible, "3D presentation appears under real 2D gameplay")
    test_ok(bridge.viewport_3d.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "Active render updates")
    test_ok(game.world.get_children().has(old_player), "Player still attached to world")
    test_ok(game.nav_region == old_nav, "Navigation scene node is unchanged")
    test_ok(old_player.main == game, "Player commands still route to actual game")
    test_ok(game.encounter != null and game.encounter.main == game, "Live Reality Scar wave director reused")
    test_ok(game.hud.player == old_player, "HUD still reflects real player stats")
    test_ok(game.loot is Array and game.enemies is Array, "Live loot and enemy collections retained")
    test_ok(game.player.inventory == old_inventory, "Inventory not changed by visual toggle")
    test_ok(game.player.hotbar == old_hotbar, "Five active skills not changed by visual toggle")
    test_ok(game.player.class_id == old_class, "Class identity remains unchanged")
    test_ok(game.player.quest == old_quest, "Quest flags preserved")
    test_ok(game.player.gold == old_gold, "Gold balance preserved")
    test_ok(game.player.position == old_pos, "World position preserved")
    test_ok(JSON.stringify(game.capture_save()) == original_state, "Schema-six save snapshot unchanged")
    var probes := [Vector2(1350,1020), Vector2(1540,900), Vector2(1290,1010), Vector2(2000,1300)]
    for p in probes:
        var roundtrip: Vector2 = bridge.to_2d(bridge.to_3d(p))
        test_ok(roundtrip.distance_to(p) < 0.03, "2D/3D ground projection roundtrips " + str(p))
    for id in game.SERVICES:
        var service: Dictionary = game.SERVICES[id]
        var marker = bridge.scenery.get_node_or_null("Service_" + String(id) + "_VisualOnly")
        test_ok(marker != null, "Functional service marker exists: " + String(id))
        if marker != null:
            test_ok(Vector3(marker.position.x, 0, marker.position.z).distance_to(bridge.to_3d(service.pos)) < 0.001, "Service marker maps to real E interaction: " + String(id))
    for id in game.SERVICES:
        var service_screen: Vector2 = game.get_viewport().get_canvas_transform() * game.SERVICES[id].pos
        var scenic_screen: Vector2 = bridge.camera_3d.unproject_position(bridge.to_3d(game.SERVICES[id].pos))
        test_ok(scenic_screen.distance_to(service_screen) < 1.0, "2.5D service projected onto original game interaction marker: " + String(id))
    # Exercise actual saved game's inventory, grimoire and interactive stash,
    # not a duplicated lab-only HUD. Modal UI pauses movement but the bridge
    # remains present and uses the same underlying game instance.
    game.hud.open_page("inventory")
    test_ok(game.hud.inventory_active() and game.hud.page == "inventory", "Real inventory opens with live 3D scenery")
    test_ok(is_instance_valid(game.hud.inventory_shell) and game.hud.inventory_shell.ui == game.hud, "Actual equipment/backpack UI stays connected")
    game.hud.close_page()
    game.hud.open_page("spells")
    test_ok(game.hud.page == "spells", "Actual Grimoire spellbook opens in hybrid view")
    game.hud.close_page()
    game.player.position = game.SERVICES["stash"].pos
    game.interact()
    test_ok(game.hud.page == "stash", "Actual E interaction opens live stash at aligned 3D marker")
    game.hud.close_page()
    game.player.position = old_pos
    test_ok(JSON.stringify(game.capture_save()) == original_state, "Inventory, Grimoire and stash viewing do not rewrite save")
    # Visual effects read the REAL quest/combat state; do not create a new quest.
    game.rift["active"] = false
    bridge.sync_world_state()
    var calm_glow: float = bridge.scar_material.emission_energy_multiplier
    game.rift["active"] = true
    bridge.sync_world_state()
    test_ok(bridge.scar_material.emission_energy_multiplier > calm_glow, "3D Reality Scar responds to actual live combat wave state")
    game.rift["active"] = false
    bridge.sync_world_state()
    test_ok(is_equal_approx(bridge.scar_material.emission_energy_multiplier, calm_glow), "3D Scar restores calm effect after combat")
    game.player.position = game.SERVICES["board"].pos
    bridge.sync_world_state()
    var board_emission: StandardMaterial3D = bridge.service_markers["board"].material_override
    test_ok(board_emission.emission_enabled, "Live quest noticeboard glows when original player enters interact range")
    game.player.position = old_pos
    bridge.sync_world_state()
    test_ok(not board_emission.emission_enabled, "Live quest noticeboard indicator clears when player leaves")
    test_ok(JSON.stringify(game.capture_save()) == original_state, "Quest/scar visual feedback remains save-neutral")
    var zoom_before: float = game.cam.zoom.y
    game._set_gameplay_zoom(0.76)
    bridge.sync_view()
    var zoom_after: float = bridge.camera_3d.size
    test_ok(zoom_after > 0, "3D camera follows source 2D camera zoom")
    game._set_gameplay_zoom(0.99)
    bridge.sync_view()
    test_ok(bridge.camera_3d.size < zoom_after, "Zoom-in yields a closer 3D view")
    game._set_gameplay_zoom(zoom_before)
    test_ok(not game.toggle_live_25d(), "F8 restores original painted plaza")
    test_ok(old_bg.visible, "Approved painting becomes visible again")
    test_ok(not bridge.visible, "Bridge is visually hidden when disabled")
    test_ok(bridge.viewport_3d.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Inactive 3D renderer stops spending GPU cycles")
    for cutout in game.layered_occluders:
        test_ok(cutout.visible, "Original painted cutout depth restored")
    test_ok(game.toggle_live_25d(), "Reactivates bridge without rebuilding player")
    test_ok(game.live_25d == bridge, "One bridge only, no duplicated actor or scene")
    test_ok(game.player == old_player and game.hud == old_hud, "Actor and inventory HUD identity stable after repeated toggles")
    test_ok(JSON.stringify(game.capture_save()) == original_state, "No save schema or progress changes after repeated toggles")
    game.toggle_live_25d()
    game.queue_free()
    await process_frame
    print("AOTL LIVE 2.5D INTEGRATION: ", passed, " checks | ", "PASS" if failed.is_empty() else "FAIL: " + str(failed))
    quit(0 if failed.is_empty() else 1)
