extends Node3D
## Phase 23: independent physical ramp/stair walk arena, not main playable Crownsfall.
const HERO := preload("res://scripts/three_d/rig_controller.gd")
const STEP_ASSIST := preload("res://scripts/three_d/phase23_step_assist.gd")
const GOLD := Color("e4c38a")
const BLUE := Color("335b8e")
const PAVING := Color("817e84")
const FLOOR_Y := 0.0

var player: CharacterBody3D
var step_assist: Node3D
var camera: Camera3D
var status: Label
var contact_markers: Array[MeshInstance3D] = []
var animated_sole_markers: Array[MeshInstance3D] = []
var max_contact_gap_m := 0.0
var contact_gap_total_m := 0.0
var contact_gap_samples := 0
var show_contact := true
var follow_camera := true
var terrain_info := ""
var step_top_heights: Array[float] = []
var terrain_nodes: Array[StaticBody3D] = []
var ready_world := false
var safety_resets := 0

func _ready() -> void:
    _build_course()
    _build_player()
    _build_camera()
    _build_hud()
    _build_contact_markers()
    ready_world = true

func _material(color: Color, emissive: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = 0.12
    m.roughness = 0.73
    if emissive:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = 1.6
    return m

func _obstacle(name: String, where: Vector3, dims: Vector3, color: Color, x_rotation_degrees: float = 0.0) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = name
    body.position = where
    body.rotation_degrees.x = x_rotation_degrees
    body.collision_layer = 1
    add_child(body)
    var collision := CollisionShape3D.new()
    var box_shape := BoxShape3D.new()
    box_shape.size = dims
    collision.shape = box_shape
    body.add_child(collision)
    var mesh := MeshInstance3D.new()
    var box_mesh := BoxMesh.new()
    box_mesh.size = dims
    mesh.mesh = box_mesh
    mesh.material_override = _material(color)
    body.add_child(mesh)
    terrain_nodes.append(body)
    return body

func _build_course() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color("1b2532")
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color("d1dcf4")
    e.ambient_light_energy = 0.58
    env.environment = e
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-58.0, -32.0, 0.0)
    sun.light_energy = 1.17
    sun.light_color = Color("f3ddbf")
    sun.shadow_enabled = true
    add_child(sun)
    _obstacle("Ground_AllLanes",Vector3(0,-0.25,0),Vector3(26,0.5,30),Color("383f4d"))
    _obstacle("Left_Ramp_18deg",Vector3(-7,0.50,-3.5),Vector3(3.5,0.24,5.4),BLUE,18.0).add_to_group("phase23_step")
    _obstacle("Left_Ramp_Landing",Vector3(-7,1.12,-7.4),Vector3(3.5,0.28,2.1),Color("c4a76d"))
    # Physically collidable staircase: seven successive 0.14 m rises.
    for index in range(7):
        var height := 0.14 * float(index+1)
        step_top_heights.append(height)
        _obstacle("Middle_Step_%02d" % index,Vector3(0,height*0.5,-2.15-float(index)*0.72),Vector3(3.0,height,0.73),Color("777e8b") if index%2==0 else Color("9c958a")).add_to_group("phase23_step")
    _obstacle("Middle_UpperLanding",Vector3(0,0.49,-7.65),Vector3(3.0,0.98,2.3),Color("b29b76")).add_to_group("phase23_step")
    _obstacle("Right_Flat_Lane",Vector3(7,-0.025,-3.65),Vector3(3.5,0.05,12.5),Color("5d6268"))
    _obstacle("Right_Steep_Reject_65deg",Vector3(7,1.18,-8.0),Vector3(2.6,0.22,2.5),Color("8a5158"),65.0)
    _scene_label("18° RAMP",Vector3(-7.0,1.85,-3.4),Color("8bc9ff"))
    _scene_label("SEVEN 14cm RISERS",Vector3(0.0,1.38,-3.6),GOLD)
    _scene_label("65° NO-CLIMB",Vector3(7.0,2.8,-8.0),Color("ff9e98"))
    # Clear high contrast paths for contact inspection in an orthographic view.
    for x in [-9.0,-5.0,-2.0,2.0,5.0,9.0]:
        _obstacle("LaneRail_%.0f" % x,Vector3(x,0.035,2.8),Vector3(0.09,0.07,2.8),GOLD)

func _scene_label(message: String, where: Vector3, color: Color) -> void:
    var sign := Label3D.new()
    sign.name = "TerrainLabel_" + message.replace(" ","_")
    sign.text = message
    sign.font_size = 92
    sign.pixel_size = 0.004
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.modulate = color
    sign.position = where
    add_child(sign)

func _build_player() -> void:
    player = HERO.new()
    player.name = "RoyalWayfarer_Phase23_TerrainOnly"
    player.position = Vector3(0,0.12,5)
    add_child(player)
    # Safe snap length assists downward contact on gently varying terrain;
    # it does not add stair-stepping or fake foot IK success.
    player.floor_snap_length = 0.28
    player.floor_max_angle = deg_to_rad(48.0)
    step_assist = STEP_ASSIST.new()
    step_assist.name = "Phase23_SafeStepAssist_StairsOnly"
    step_assist.configure(player)
    add_child(step_assist)

func _build_camera() -> void:
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 13.5
    camera.current = true
    add_child(camera)
    player.camera = camera
    camera.global_position = Vector3(10,12,17)
    camera.look_at(player.global_position+Vector3(0,0.9,-2.5),Vector3.UP)

func _build_hud() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)
    var panel := PanelContainer.new()
    canvas.add_child(panel)
    panel.position = Vector2(24,20)
    panel.custom_minimum_size = Vector2(650,0)
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.025,0.038,0.066,0.94)
    skin.border_color = GOLD
    skin.set_border_width_all(2)
    skin.set_content_margin_all(12)
    panel.add_theme_stylebox_override("panel",skin)
    var column := VBoxContainer.new()
    panel.add_child(column)
    var heading := Label.new()
    heading.text = "AGE OF THE LOST   |   PHASE 23 TERRAIN / FOOT LAB"
    heading.add_theme_color_override("font_color",GOLD)
    heading.add_theme_font_size_override("font_size",22)
    column.add_child(heading)
    status = Label.new()
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status.add_theme_font_size_override("font_size",15)
    column.add_child(status)
    var controls := Label.new()
    controls.text = "WASD move · Shift sprint · F11 IK on/off · 7 foot/target markers · 8 camera · 9 smooth step visuals · 1/2/3 reset to ramp/stairs/flat · F7 back"
    controls.add_theme_color_override("font_color",GOLD)
    controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(controls)

func _build_contact_markers() -> void:
    for index in range(2):
        var dot := MeshInstance3D.new()
        dot.name = "ContactTarget_%s" % ("L" if index == 0 else "R")
        var sphere := SphereMesh.new()
        sphere.radius = 0.085
        sphere.height = 0.17
        dot.mesh = sphere
        dot.material_override = _material(Color("40d1f3") if index==0 else Color("f6ad50"),true)
        dot.visible = show_contact
        add_child(dot)
        contact_markers.append(dot)
        var sole := MeshInstance3D.new()
        sole.name = "AnimatedFootBone_%s" % ("L" if index == 0 else "R")
        var sole_mesh := SphereMesh.new()
        sole_mesh.radius = 0.045
        sole_mesh.height = 0.09
        sole.mesh = sole_mesh
        sole.material_override = _material(Color("bc8bf5") if index==0 else Color("c3e37e"),true)
        sole.visible = show_contact
        add_child(sole)
        animated_sole_markers.append(sole)

func teleport_lane(index: int) -> void:
    if player == null: return
    var where := Vector3(-7,0.15,5) if index==1 else (Vector3(0,0.15,5) if index==2 else Vector3(7,0.15,5))
    player.velocity = Vector3.ZERO
    player.global_position = where
    if player.body != null:
        player.body.position = Vector3.ZERO
    max_contact_gap_m = 0.0
    contact_gap_total_m = 0.0
    contact_gap_samples = 0
    player.last_face = Vector3.FORWARD
    if player.ik_available:
        player.foot_ik.set_active(player.foot_ik.active)

func _process(delta: float) -> void:
    if not ready_world or player == null or camera == null:
        return
    if player.global_position.y < -4.0 or absf(player.global_position.x) > 16.0 or player.global_position.z < -14.5:
        teleport_lane(2)
        safety_resets += 1
    if follow_camera:
        var target := player.global_position + Vector3(8.5,11.0,12.0)
        camera.global_position = camera.global_position.lerp(target,minf(1.0,delta*4.0))
        camera.look_at(player.global_position+Vector3(0,1.0,-2.3),Vector3.UP)
    if player.ik_available:
        for index in range(2):
            contact_markers[index].global_position = player.foot_ik.targets[index].global_position
            contact_markers[index].visible = show_contact and player.foot_ik.active
            var foot_bone: int = player.foot_ik.foot_bones[index]
            var animated_foot: Vector3 = player.foot_ik.skeleton.global_transform * player.foot_ik.skeleton.get_bone_global_pose(foot_bone).origin
            animated_sole_markers[index].global_position = animated_foot
            animated_sole_markers[index].visible = show_contact and player.foot_ik.active
            if player.foot_ik.active and player.foot_ik.locked[index]:
                var gap := animated_foot.distance_to(contact_markers[index].global_position)
                max_contact_gap_m = maxf(max_contact_gap_m,gap)
                contact_gap_total_m += gap
                contact_gap_samples += 1
    var floor_text := "ON FLOOR" if player.is_on_floor() else "AIR / EDGE"
    var detail: String = player.foot_ik_status() if player.ik_available else "Skeleton unavailable"
    status.text = "%s   ·   World y %.3f m   ·   Speed %.2f m/s
%s
Plants %d  Releases %d  Rays %d  Steep rejections %d  Step assists %d · visual blends %d · safety resets %d
Foot-bone↔target gap: peak %.3f m / mean %.3f m (%d sampled frames)" % [floor_text,player.global_position.y,Vector2(player.velocity.x,player.velocity.z).length(),detail,player.foot_ik.plant_events if player.ik_available else 0,player.foot_ik.release_events if player.ik_available else 0,player.foot_ik.ray_hits if player.ik_available else 0,player.foot_ik.rejected_steep if player.ik_available else 0, step_assist.step_events if step_assist != null else 0,step_assist.visual_applies if step_assist != null else 0,safety_resets, max_contact_gap_m, contact_gap_total_m/float(maxi(1,contact_gap_samples)),contact_gap_samples]

func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed and not event.echo): return
    match event.keycode:
        KEY_F11:
            player.toggle_foot_ik()
            get_viewport().set_input_as_handled()
        KEY_7:
            show_contact = not show_contact
            get_viewport().set_input_as_handled()
        KEY_8:
            follow_camera = not follow_camera
            get_viewport().set_input_as_handled()
        KEY_9:
            step_assist.smoothing_enabled = not step_assist.smoothing_enabled
            get_viewport().set_input_as_handled()
        KEY_1, KEY_2, KEY_3:
            teleport_lane(event.keycode-KEY_1+1)
            get_viewport().set_input_as_handled()
        KEY_F7, KEY_ESCAPE:
            get_tree().change_scene_to_file("res://scenes/rig_lab_3d.tscn")