extends SceneTree
## Opt-in, standalone test; never touches the gameplay save directory.
## godot --headless --path . --script res://tests/two_point_five_d_smoke.gd

var checks := 0
var failures: PackedStringArray = []

func _initialize() -> void:
    call_deferred("_run")

func _check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        push_error("2.5D SMOKE FAILED: " + label)

func _run() -> void:
    var path := "res://scenes/two_point_five_d/aotl_25d_lab.tscn"
    var resource := load(path) as PackedScene
    if resource == null:
        push_error("Could not load 2.5D scene")
        quit(1)
        return
    var lab = resource.instantiate()
    root.add_child(lab)
    await process_frame
    if lab.get_script() == null:
        push_error("2.5D scene root script did not load")
        lab.queue_free()
        quit(1)
        return
    _check(lab.player != null, "painted actor exists")
    _check(lab.camera != null, "orthographic camera exists")
    _check(lab.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "camera uses orthographic perspective")
    _check(lab.player.visual_mode == "painted", "painted mode is default")
    _check(lab.player.visual.texture != null, "original painted texture loaded")
    _check(lab.player.visual.texture.get_size() == Vector2(384, 384), "original 384px idle asset used")
    _check(lab.player.visual.hframes == 1, "idle frame splitting")
    lab.player.start_action("slash")
    lab.player._render_painted_frame("slash", true)
    _check(lab.player.visual.hframes >= 8, "real painted attack frames used")
    lab.player.action_t = 0.0
    lab.player.toggle_class()
    lab.player._render_painted_frame("idle", true)
    _check(lab.player.player_class == "mage", "Mage visual toggle")
    _check(lab.player.visual.texture != null, "Mage painted texture loaded")
    lab.player.change_visual_mode()
    _check(lab.player.visual_mode == "proxy" or lab.player.skeleton_visual == null, "proxy comparison mode if GLB imported")
    lab.player.change_visual_mode()
    _check(lab.player.visual_mode == "painted", "round-trip to painted mode")
    _check(lab.dummies.size() == 3, "existing training construct logic reused")
    _check(lab.fx != null, "existing 3D effect engine reused")
    _check(ResourceLoader.exists("res://assets/plaza.png"), "existing Crownsfall painting retained")
    _check(is_equal_approx(lab.camera.size, 21.0), "PoE-like wide camera is the default")
    _check(lab.camera.size / 14.5 > 1.35, "camera shows substantially more ground than prior lab")
    _check(not lab.reference_panel.visible, "reference image is hidden by default for gameplay clarity")
    _check(lab.world_environment != null, "procedural Crownsfall environment instantiated")
    _check(lab.world_environment.find_child("Paved_Cobblestones_00", true, false) != null, "batched limestone paving present")
    _check(lab.world_environment.find_child("Royal_Blue_Banner", true, false) != null, "royal-blue canonical art marker present")
    _check(lab.world_environment.find_child("Fountain_Blue_Water", true, false) != null, "fountain landmark present")
    _check(lab.world_environment.find_child("Walkable_Stone_Collision_60m", true, false) != null, "expanded 60-metre courtyard collision present")
    lab._set_camera_zoom(99.0)
    _check(is_equal_approx(lab.camera_size_for_test(), 28.0), "zoom-out range clamps at 28 m")
    lab._set_camera_zoom(1.0)
    _check(is_equal_approx(lab.camera_size_for_test(), 14.0), "zoom-in range clamps at 14 m")
    lab._set_camera_zoom(21.0)
    _check(is_equal_approx(lab.camera_size_for_test(), 21.0), "camera returns to default")
    _check(lab.player.foot_anchor_metadata.size() == 27, "original 27 sprite strips have source-derived foot anchors")
    _check(lab.player.last_anchor_bottom_px > 300.0, "painted feet reference actual alpha bounds")
    _check(lab.player.shadow.mesh is ArrayMesh, "contact shadow has radial alpha mesh")
    lab.player.start_dodge()
    lab.player.dodge_t = 0.33
    lab.player._render_painted_frame("dodge", true)
    _check(absf(lab.player.visual.rotation.z) > 0.2, "dodge anticipation and rotation visible")
    _check(lab.player.shadow.scale.x > 1.05, "dodge shadow grows with body compression")
    lab.player.dodge_t = 0.0
    lab.player._render_painted_frame("idle", true)
    _check(is_zero_approx(lab.player.visual.rotation.z), "dodge presentation resets cleanly")

    var success := failures.is_empty()
    print("AOTL 2.5D SMOKE: %d checks | %s" % [checks, "PASS" if success else "FAILED: " + ", ".join(failures)])
    lab.queue_free()
    quit(0 if success else 1)