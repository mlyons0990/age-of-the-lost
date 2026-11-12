extends CharacterBody3D
## AOTL art-direction experiment: real 3D movement/collision with the EXISTING painted sprites.
## Separate from the save-bearing 2D player and independent 58-bone gameplay lab.

signal action_impact(kind: String, at: Vector3, forward: Vector3)
signal visual_changed(description: String)

const FRAME := 384
const ATTACK_FRAME := 512
const PIXEL_SIZE := 0.0053  # 384px painting ~2.04 world metres before transparent margins.
const WALK_SPEED := 4.3
const RUN_SPEED := 6.7
const DODGE_SPEED := 10.5
const GRAVITY := 24.0
const FACING_LOOKUP := [
    ["right", false], ["se", false], ["down", false], ["se", true],
    ["right", true], ["ne", true], ["up", false], ["ne", false]
]
const ATTACK_LOOKUP := [
    ["se", false], ["se", false], ["se", false], ["se", true],
    ["se", true], ["ne", true], ["ne", false], ["ne", false]
]

var camera: Camera3D
var player_class := "warrior"
var visual_mode := "painted"
var visual: Sprite3D
var skeleton_visual: Node3D
var skeleton_anims: AnimationPlayer
var skeleton_clips: Dictionary = {}
var shadow: MeshInstance3D
var target_position := Vector3.ZERO
var has_target := false
var facing_world := Vector3(0.0, 0.0, -1.0)
var motion_state := "idle"
var action_kind := ""
var action_t := 0.0
var action_duration := 0.0
var action_landed := false
var dodge_t := 0.0
var dodge_cd := 0.0
var frame_clock := 0.0
var active_texture_key := ""
var cached_textures: Dictionary = {}
var active_proxy_clip := ""

func _ready() -> void:
    name = "AOTL_PaintedActor_25D"
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.26
    capsule.height = 1.85
    var collision := CollisionShape3D.new()
    collision.name = "WorldCollision"
    collision.shape = capsule
    collision.position = Vector3(0, 0.94, 0)
    add_child(collision)

    visual = Sprite3D.new()
    visual.name = "PaintedDirectionalActor"
    visual.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    visual.shaded = false # Preserve baked hand-painted highlights, not flat 3D lighting.
    visual.pixel_size = PIXEL_SIZE
    visual.double_sided = true
    visual.transparent = true
    visual.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    add_child(visual)

    var shadow_mesh := PlaneMesh.new()
    shadow_mesh.size = Vector2(0.85, 0.52)
    shadow = MeshInstance3D.new()
    shadow.name = "ContactShadow"
    shadow.mesh = shadow_mesh
    shadow.position = Vector3(0, 0.024, 0)
    var shadow_mat := StandardMaterial3D.new()
    shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    shadow_mat.albedo_color = Color(0.07, 0.09, 0.16, 0.24)
    shadow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    shadow.material_override = shadow_mat
    add_child(shadow)

    # 3D proxy uses the original GLB; it is a comparison, not a replacement for art.
    var model_path := "res://models/AOTL_Wayfarer_Articulated_Proxy.glb"
    if ResourceLoader.exists(model_path):
        var model := load(model_path) as PackedScene
        if model != null:
            skeleton_visual = model.instantiate()
            skeleton_visual.name = "Existing58BoneProxy"
            skeleton_visual.visible = false
            add_child(skeleton_visual)
            skeleton_anims = skeleton_visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
            if skeleton_anims != null:
                for library_clip in skeleton_anims.get_animation_list():
                    var short_name := String(library_clip).get_file()
                    skeleton_clips[short_name] = library_clip
                    if short_name in ["Idle", "Walk", "Run"]:
                        skeleton_anims.get_animation(library_clip).loop_mode = Animation.LOOP_LINEAR
    _render_painted_frame("idle", true)
    visual_changed.emit("Painted sprites · Warrior")

func change_visual_mode() -> void:
    if visual_mode == "painted" and skeleton_visual != null:
        visual_mode = "proxy"
    else:
        visual_mode = "painted"
    visual.visible = visual_mode == "painted"
    if skeleton_visual != null:
        skeleton_visual.visible = visual_mode == "proxy"
    active_texture_key = ""
    active_proxy_clip = ""
    visual_changed.emit(("Painted sprites" if visual_mode == "painted" else "58-bone geometric proxy") + " · " + player_class.capitalize())

func toggle_class() -> void:
    player_class = "mage" if player_class == "warrior" else "warrior"
    active_texture_key = ""
    visual_changed.emit(("Painted sprites" if visual_mode == "painted" else "58-bone geometric proxy") + " · " + player_class.capitalize())

func move_to_ground(world_point: Vector3) -> void:
    target_position = Vector3(world_point.x, 0.0, world_point.z)
    has_target = true

func start_action(kind: String) -> void:
    if action_t > 0.0 or dodge_t > 0.0:
        return
    has_target = false
    action_kind = kind
    action_duration = 0.53 if kind == "slash" else (0.79 if kind == "heavy" else 0.92)
    action_t = action_duration
    action_landed = false
    frame_clock = 0.0

func start_dodge() -> void:
    if dodge_cd > 0.0 or dodge_t > 0.0 or action_t > 0.0:
        return
    dodge_t = 0.66
    dodge_cd = 1.10
    has_target = false
    frame_clock = 0.0
    # Painted sprites have NO authored dodge-roll frames. This is explicitly a placeholder.

func _physics_process(delta: float) -> void:
    dodge_cd = maxf(0.0, dodge_cd - delta)
    var direct := Vector2.ZERO
    if Input.is_key_pressed(KEY_A): direct.x -= 1.0
    if Input.is_key_pressed(KEY_D): direct.x += 1.0
    if Input.is_key_pressed(KEY_W): direct.y += 1.0
    if Input.is_key_pressed(KEY_S): direct.y -= 1.0
    var travel := Vector3.ZERO
    if camera != null:
        var right := camera.global_basis.x
        var forward := -camera.global_basis.z
        right.y = 0.0
        forward.y = 0.0
        right = right.normalized()
        forward = forward.normalized()
        if direct.length_squared() > 0.01:
            has_target = false
            travel = (right * direct.x + forward * direct.y).normalized()
        elif has_target:
            var delta_to := target_position - global_position
            delta_to.y = 0.0
            if delta_to.length() < 0.16:
                has_target = false
            else:
                travel = delta_to.normalized()
    if travel.length_squared() > 0.01:
        facing_world = travel
    if dodge_t > 0.0:
        dodge_t = maxf(0.0, dodge_t - delta)
        velocity.x = facing_world.x * DODGE_SPEED
        velocity.z = facing_world.z * DODGE_SPEED
        motion_state = "dodge"
    elif action_t > 0.0:
        var elapsed := action_duration - action_t
        action_t = maxf(0.0, action_t - delta)
        velocity.x = move_toward(velocity.x, 0.0, 32.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 32.0 * delta)
        motion_state = action_kind
        var hit_time := 0.36 if action_kind == "cast" else (0.39 if action_kind == "heavy" else 0.20)
        if not action_landed and elapsed >= hit_time:
            action_landed = true
            action_impact.emit(action_kind, global_position + facing_world * (2.1 if action_kind == "cast" else 1.3), facing_world)
    else:
        var sprint := Input.is_key_pressed(KEY_SHIFT)
        var speed := RUN_SPEED if sprint else WALK_SPEED
        velocity.x = travel.x * speed
        velocity.z = travel.z * speed
        motion_state = "run" if travel.length_squared() > 0.01 and sprint else ("walk" if travel.length_squared() > 0.01 else "idle")
    velocity.y = -GRAVITY if is_on_floor() else velocity.y - GRAVITY * delta
    move_and_slide()
    frame_clock += delta
    if visual_mode == "painted":
        _render_painted_frame(motion_state)
    else:
        _render_proxy_animation(motion_state, delta)

func _screen_facing() -> int:
    if camera == null:
        return 1
    var screen_right := facing_world.dot(camera.global_basis.x)
    var screen_down := -facing_world.dot(camera.global_basis.y)
    var angle := atan2(screen_down, screen_right)
    return posmod(roundi(angle / (PI / 4.0)), 8)

func _render_painted_frame(state: String, force := false) -> void:
    var f := _screen_facing()
    var table := ATTACK_LOOKUP if state in ["slash", "heavy"] else FACING_LOOKUP
    var direction_name: String = table[f][0]
    visual.flip_h = bool(table[f][1])
    var animation := "walk" if state in ["walk", "run", "dodge"] else "idle"
    var target_fps := 14.0 if player_class == "warrior" else 6.0
    if state in ["slash", "heavy"]:
        animation = "attack" if player_class == "warrior" else "cast"
        target_fps = 28.0 if player_class == "warrior" else 7.0
    elif state == "cast":
        animation = "cast" if player_class == "mage" else "attack"
        target_fps = 7.0 if player_class == "mage" else 28.0
    if animation == "attack" and direction_name not in ["ne", "se"]:
        direction_name = "se"
    # A Warrior has no authored cast strip: borrow sword animation transparently.
    if animation == "attack" and player_class == "warrior":
        var attack_info: Array = ATTACK_LOOKUP[f]
        direction_name = String(attack_info[0])
        visual.flip_h = bool(attack_info[1])
    var path := "res://assets/%s/%s_%s.png" % ["knight" if player_class == "warrior" else "mage", animation, direction_name]
    if not ResourceLoader.exists(path):
        path = "res://assets/%s/idle_se.png" % ["knight" if player_class == "warrior" else "mage"]
        target_fps = 1.0
    var frame_size := ATTACK_FRAME if animation == "attack" and path.contains("/knight/") else FRAME
    var key := path + "@" + str(frame_size)
    if active_texture_key != key or force:
        if not cached_textures.has(path):
            cached_textures[path] = load(path)
        var source: Texture2D = cached_textures[path]
        visual.texture = source
        visual.hframes = maxi(1, int(source.get_width() / frame_size))
        visual.vframes = 1
        visual.position.y = float(frame_size) * PIXEL_SIZE * 0.50 - 0.05
        active_texture_key = key
    var count := visual.hframes
    if state in ["idle"]:
        visual.frame = 0
    else:
        visual.frame = clampi(int(frame_clock * target_fps), 0, count - 1) if state in ["slash", "heavy", "cast"] else (int(frame_clock * target_fps) % count)
    # WARNING: Not a real painted roll. This illustrates the pending animation gap.
    visual.rotation.z = -0.08 if state == "dodge" else 0.0

func _render_proxy_animation(state: String, delta: float) -> void:
    if skeleton_visual == null:
        return
    var clip := "Idle"
    if state == "walk": clip = "Walk"
    elif state == "run": clip = "Run"
    elif state == "dodge": clip = "Dodge"
    elif state == "cast": clip = "Cast"
    elif state in ["slash", "heavy"]: clip = "Slash"
    if skeleton_anims != null and clip != active_proxy_clip and skeleton_clips.has(clip):
        skeleton_anims.play(skeleton_clips[clip], 0.15)
        active_proxy_clip = clip
    var yaw := atan2(-facing_world.x, -facing_world.z)
    skeleton_visual.rotation.y = lerp_angle(skeleton_visual.rotation.y, yaw, minf(1.0, delta * 13.0))