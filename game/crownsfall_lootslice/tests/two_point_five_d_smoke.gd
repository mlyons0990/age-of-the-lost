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
    var success := failures.is_empty()
    print("AOTL 2.5D SMOKE: %d checks | %s" % [checks, "PASS" if success else "FAILED: " + ", ".join(failures)])
    lab.queue_free()
    quit(0 if success else 1)