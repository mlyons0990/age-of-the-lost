extends SceneTree
## AOTL phase 06: Tests real saved-game presentation, never creates a second player.
var checks := 0
var failed := 0

func verify(condition: bool, title: String) -> void:
    checks += 1
    if condition:
        print("PASS ", title)
    else:
        failed += 1
        push_error("FAIL " + title)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    change_scene_to_file("res://main.tscn")
    for i in 8: await process_frame
    var g: Node2D = current_scene
    verify(g != null, "Original saved AOTL main game loaded")
    if g == null: quit(1); return
    if g.hud.start_panel != null:
        g.hud.start_panel.queue_free()
        g.hud.start_panel = null
        g.hud._refresh_pause()
    for i in 3: await process_frame
    var actor: Node2D = g.player
    var saved_actor := actor
    var original_state: String = JSON.stringify(g.capture_save())
    verify(actor.sprite != null and actor.visual_root != null, "Approved 2D knight art remains the gameplay actor")
    verify(actor.foot_anchor_frames.size() == 27, "Source-driven foot contacts cover 27 existing class sprite sheets")
    verify(actor.current_foot_anchor_px > 0, "Live player reports first standing foot contact")
    var expected_idle: float = -actor.current_foot_anchor_px + float(actor.current_sheet_frame_size) * 0.5 + actor.FEET.y / actor.SPRITE_SCALE
    verify(absf(actor.sprite.offset.y - expected_idle) < 0.04, "Idle frame foot base follows the authored player transform")
    verify(g.live_25d == null, "3D depth renderer not allocated by default")
    verify(g.toggle_live_25d(), "F8 integrated 2.5D scenery enabled")
    var bridge = g.live_25d
    verify(bridge != null and bridge.is_ready, "Actual game owns integrated 3D bridge")
    verify(not bridge.knight_depth_enabled, "F10 real-depth mode safely defaults disabled")
    verify(actor.sprite.visible, "Default F8 mode retains original painterly sprite")
    verify(bridge.toggle_knight_depth(), "F10 enables true-depth painted knight")
    verify(bridge.knight_depth_avatar != null, "Live frame mirror lazily creates Sprite3D")
    verify(not actor.sprite.visible and not actor.shadow.visible, "Original painted art not double-rendered")
    verify(bridge.knight_depth_avatar.painted_sprite.texture != null, "Sprite3D receives the original class artwork")
    verify(not bridge.knight_depth_avatar.painted_sprite.no_depth_test, "Real 3D depth test is enabled")
    verify(bridge.knight_depth_avatar.painted_sprite.render_priority == 12, "Knight transparents render after alpha-blended painted ground")
    verify(bridge.knight_depth_avatar.contact_shadow != null, "Ground shadow is present in true-depth rendering")
    verify(bridge.knight_depth_avatar.contact_shadow.visible, "Shared painted knight shadow stays visible in F10 mode")
    verify(bridge.knight_depth_avatar.contact_shadow.texture == actor.shadow.texture, "3D contact shadow reuses original 2D radial shadow")
    verify(not bridge.knight_depth_avatar.contact_shadow.no_depth_test, "Contact shadow depth tests against architecture")
    verify(bridge.knight_depth_avatar.painted_sprite.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "Painted knight faces orthographic gameplay camera")
    verify(absf(bridge.knight_depth_avatar.painted_sprite.pixel_size - actor.sprite.scale.x / actor.GD.U) < 0.00005, "3D pixels use the same world scale as 2D")
    verify(bridge.knight_depth_avatar.status().authority == "original_2d_player_only", "Geometry is presentation-only, no duplicate game authority")
    verify(saved_actor == g.player, "Player identity is preserved")
    verify(bridge.knight_depth_avatar.painted_sprite.texture == actor.sprite.sprite_frames.get_frame_texture(actor.sprite.animation, actor.sprite.frame), "Live 3D knight uses exact original source frame")
    actor.facing = 1
    actor.sprite.play("walk_se")
    actor.sprite.frame = 2
    actor._apply_visual_footlock()
    bridge.sync_knight_depth()
    verify(bridge.knight_depth_avatar.last_frame_key.begins_with("walk_se:2"), "3D painter uses current live walk frame")
    verify(absf(bridge.knight_depth_avatar.last_boot_delta_px - actor.FEET.y / actor.SPRITE_SCALE) < 0.2, "Walk frame boots anchored to one ground point")
    actor.sprite.play("attack_se")
    actor.sprite.frame = 9
    actor._apply_visual_footlock()
    bridge.sync_knight_depth()
    verify(bridge.knight_depth_avatar.last_frame_key.begins_with("attack_se:9"), "3D painter also follows combat sword arcs")
    verify(absf(bridge.knight_depth_avatar.last_boot_delta_px - actor.FEET.y / actor.SPRITE_SCALE) < 0.2, "512px attack animation foot contact shares 384px walking baseline")
    verify(actor.current_sheet_frame_size == 512, "Sword arc uses its original 512px atlas, unmodified")
    actor.sprite.play("idle_se")
    actor.sprite.frame = 0
    actor._apply_visual_footlock()
    bridge.sync_knight_depth()
    verify(absf(bridge.knight_depth_avatar.last_boot_delta_px - actor.FEET.y / actor.SPRITE_SCALE) < 0.2, "Attack -> idle restores exactly the same ground contact")
    var remembered_class: String = actor.class_id
    actor.class_id = "mage"
    actor.refresh_visuals()
    actor.sprite.play("cast_se")
    actor.sprite.pause()
    actor.sprite.frame = 1
    actor._apply_visual_footlock()
    bridge.sync_knight_depth()
    verify(bridge.knight_depth_avatar.last_frame_key.begins_with("cast_se:1:mage"), "Same 3D-depth renderer supports authentic Mage casting artwork")
    verify(bridge.knight_depth_avatar.painted_sprite.texture == actor.sprite.sprite_frames.get_frame_texture("cast_se", 1), "Mage spellcasting shares original Godot frame, not a regenerated proxy")
    actor.class_id = remembered_class
    actor.refresh_visuals()
    actor._apply_visual_footlock()
    bridge.sync_knight_depth()
    verify(bridge.knight_depth_avatar.last_frame_key.ends_with(":warrior"), "Approved knight artwork returns after class-preview swap")
    verify(not bridge.toggle_knight_depth(), "F10 returns control to original 2D rendering")
    verify(actor.sprite.visible and actor.shadow.visible, "Original sprite and shadow both restored")
    verify(bridge.knight_depth_avatar != null and not bridge.knight_depth_avatar.visible, "3D actor mirror safely hidden when disabled")
    verify(bridge.knight_depth_avatar.contact_shadow != null and not bridge.knight_depth_avatar.visible, "Contact shadow stays hidden with optional 3D mirror")
    verify(not g.toggle_live_25d(), "F8 restores original Crownsfall painting")
    verify(actor.sprite.visible, "F8 reset preserves visible original player")
    verify(JSON.stringify(g.capture_save()) == original_state, "No gameplay/save changes from scene or art mode")
    verify(g.player == saved_actor, "Character identity survives both presentation toggles")
    print("AOTL KNIGHT + GEOMETRY INTEGRATION: ", checks - failed, "/", checks, " passed")
    quit(0 if failed == 0 else 1)
