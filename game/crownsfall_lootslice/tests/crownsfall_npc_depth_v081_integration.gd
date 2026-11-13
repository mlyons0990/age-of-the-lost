extends SceneTree
## Phase 08.1 — all six district NPCs share the knight's authentic 3D-depth
## presentation with NO extra gameplay actors, inventory, save or navigation.
var count := 0
var failed := 0
func check(ok: bool, description: String) -> void:
    count += 1
    if ok: print("PASS CITY08.1: ",description)
    else:
        failed += 1
        push_error("FAIL CITY08.1: "+description)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    change_scene_to_file("res://main.tscn")
    for i in 14: await physics_frame
    var g = current_scene
    check(g != null,"Main game loaded")
    if g == null: quit(1);return
    if g.hud.start_panel != null:
        g.hud.start_panel.queue_free()
        g.hud.start_panel = null
        g.hud._refresh_pause()
    var old_player = g.player
    var saved: String = JSON.stringify(g.capture_save())
    var sources := {}
    for key in g.SERVICES:
        if key.begins_with("promenade_") or key.begins_with("market_"):
            sources[key] = g.world.get_node("ArtOnly_NPC_"+String(key)).get_node("CanonClassIdle_ProvisionalNPC")
    check(sources.size()==6,"Six approved-source-art town stand-ins already exist")
    check(g.toggle_live_25d(),"Real 3D city scenery enabled")
    var bridge = g.live_25d
    check(bridge.npc_depth_mirrors.size()==6,"Six scene-native NPC Sprite3D mirrors created")
    for id in sources:
        var source: Sprite2D=sources[id]
        var mirror: Sprite3D=bridge.npc_depth_mirrors[id]
        check(mirror.texture == source.texture,"NPC "+String(id)+" uses same canonical source texture")
        check(mirror.no_depth_test==false,"NPC "+String(id)+" is real 3D-depth-tested")
        check(source.visible and not mirror.visible,"NPC "+String(id)+" starts in original safe 2D mode")
        check(mirror.global_position.distance_to(bridge.to_3d(g.SERVICES[id].pos)+Vector3.UP*1.14)<.01,
              "NPC "+String(id)+" matches actual gameplay service coordinate")
    check(bridge.set_knight_depth_enabled(true),"F10 enables true-depth presentation")
    for id in sources:
        var source: Sprite2D=sources[id]
        var mirror: Sprite3D=bridge.npc_depth_mirrors[id]
        check(not source.visible and mirror.visible,"NPC "+String(id)+" swaps to 3D depth without duplicate visible sprite")
    check(bridge.set_knight_depth_enabled(false)==false,"F10 exits true-depth presentation")
    for id in sources:
        var source: Sprite2D=sources[id]
        var mirror: Sprite3D=bridge.npc_depth_mirrors[id]
        check(source.visible and not mirror.visible,"NPC "+String(id)+" restores original painted art")
    bridge.set_knight_depth_enabled(true)
    check(not g.toggle_live_25d(),"F8 exits 3D while depth is active")
    for id in sources:
        check(sources[id].visible,"NPC "+String(id)+" auto-restores when 3D environment disabled")
    check(g.player==old_player,"Only one gameplay player remains")
    check(JSON.stringify(g.capture_save())==saved,"No modification to saved inventory, quests, stats, or schema")
    print("AOTL PHASE08.1 TOWN NPC DEPTH: ",count-failed,"/",count," passed")
    quit(0 if failed==0 else 1)
