extends CharacterBody3D
## Playable articulated GLB rig. Movement and attacks are controlled in 3D.
## Animation clips are real glTF skeleton keyframes imported by Godot.

signal impact(at: Vector3, kind: String, direction: Vector3)
signal health_changed(current: float, maximum: float)

const LEGACY_MODEL := preload("res://models/AOTL_Wayfarer_Articulated_Proxy.glb")
const WARRIOR_R36 := "res://models/AOTL_Warrior_R36.glb"
const TERRAIN_IK := preload("res://scripts/three_d/terrain_foot_ik.gd")
const WALK_SPEED := 4.3
const RUN_SPEED := 6.7
const DODGE_SPEED := 10.5
const GRAVITY := 24.0

var animation: AnimationPlayer = null
var body: Node3D
var camera: Camera3D
var max_hp := 130.0
var hp := 130.0
var attack_t := 0.0
var attack_duration := 0.72
var attack_type := "Slash"
var has_impacted := false
var dodge_t := 0.0
var spell_cd := 0.0
var attack_cd := 0.0
var dodge_cd := 0.0
var invulnerable := 0.0
var last_face := Vector3(0, 0, -1)
var anim_state := ""
var clip_names: Dictionary = {}
var terrain_foot_ik: Node3D = null
var terrain_ik_available := false
var active_model_source := "legacy_proxy"

func _ready() -> void:
	# Revision 36 is preferred, but the Git-LFS legacy proxy remains a permanent fallback.
	var selected_model: PackedScene = LEGACY_MODEL
	if ResourceLoader.exists(WARRIOR_R36):
		var imported_model := ResourceLoader.load(WARRIOR_R36, "PackedScene") as PackedScene
		if imported_model != null:
			selected_model = imported_model
			active_model_source = "warrior_r36"
	body = selected_model.instantiate()
	add_child(body)
	animation = body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation != null:
		for name in animation.get_animation_list():
			var logical := String(name).get_file()
			clip_names[logical] = name
			if logical in ["Idle", "Walk", "Run"]:
				animation.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.26
	capsule.height = 1.95
	var col := CollisionShape3D.new()
	col.shape = capsule
	col.position = Vector3(0, 1, 0)
	add_child(col)
	_play("Idle")
	# Optional: older proxy skeletons continue running without terrain IK.
	terrain_foot_ik = TERRAIN_IK.new()
	terrain_foot_ik.name = "TerrainFootIK"
	add_child(terrain_foot_ik)
	terrain_ik_available = terrain_foot_ik.configure(body, self, animation)

func _play(clip: String) -> void:
	if animation == null or not clip_names.has(clip):
		return
	if anim_state != clip:
		animation.play(clip_names[clip], 0.16)
		anim_state = clip

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_attack("Slash", 0.72)
	elif event is InputEventKey:
		match event.keycode:
			KEY_SPACE: _dodge()
			KEY_1: _attack("Cleave", 0.76)
			KEY_2: _attack("Dash", 0.68)
			KEY_3: _attack("Cast", 1.4)

func _attack(kind: String, duration: float) -> void:
	if attack_t > 0.0 or dodge_t > 0.0 or attack_cd > 0.0:
		return
	if kind == "Cast" and spell_cd > 0.0:
		return
	attack_t = duration
	attack_duration = duration
	attack_type = kind
	has_impacted = false
	attack_cd = 0.30
	if kind == "Cast": spell_cd = 3.5
	_play("Cast" if kind == "Cast" else "Slash")

func _dodge() -> void:
	if dodge_t > 0.0 or dodge_cd > 0.0 or attack_t > 0.0:
		return
	dodge_t = 0.65
	dodge_cd = 1.1
	invulnerable = 0.50
	_play("Dodge")

func _physics_process(delta: float) -> void:
	attack_cd = maxf(0.0, attack_cd - delta)
	spell_cd = maxf(0.0, spell_cd - delta)
	dodge_cd = maxf(0.0, dodge_cd - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_A): input.x -= 1.0
	if Input.is_key_pressed(KEY_D): input.x += 1.0
	if Input.is_key_pressed(KEY_W): input.y -= 1.0
	if Input.is_key_pressed(KEY_S): input.y += 1.0
	input = input.normalized()
	var cam_right := Vector3.RIGHT
	var cam_forward := Vector3.FORWARD
	if camera != null:
		cam_right = camera.global_basis.x
		cam_forward = -camera.global_basis.z
	cam_right.y = 0
	cam_forward.y = 0
	cam_right = cam_right.normalized()
	cam_forward = cam_forward.normalized()
	var moving := (cam_right * input.x + cam_forward * -input.y).normalized()
	var sprint := Input.is_key_pressed(KEY_SHIFT)
	if dodge_t > 0.0:
		dodge_t = maxf(0.0, dodge_t - delta)
		if moving.length() > 0.1:
			last_face = moving
		velocity.x = last_face.x * DODGE_SPEED
		velocity.z = last_face.z * DODGE_SPEED
		if dodge_t <= 0.0: anim_state = ""
	elif attack_t > 0.0:
		var elapsed := attack_duration - attack_t
		attack_t = maxf(0.0, attack_t - delta)
		velocity.x = move_toward(velocity.x, 0.0, 28.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 28.0 * delta)
		if attack_type == "Dash":
			velocity.x = last_face.x * 8.0
			velocity.z = last_face.z * 8.0
		if not has_impacted and elapsed >= (0.54 if attack_type == "Cast" else 0.25):
			has_impacted = true
			impact.emit(global_position + last_face * (2.2 if attack_type == "Cast" else 1.4), attack_type, last_face)
		if attack_t <= 0.0: anim_state = ""
	else:
		velocity.x = moving.x * (RUN_SPEED if sprint else WALK_SPEED)
		velocity.z = moving.z * (RUN_SPEED if sprint else WALK_SPEED)
		_play("Run" if sprint and moving.length() > 0.1 else ("Walk" if moving.length() > 0.1 else "Idle"))
	if moving.length() > 0.1 and dodge_t <= 0.0 and attack_t <= 0.0:
		last_face = moving
	if last_face.length() > 0.0:
		var desired_yaw := atan2(-last_face.x, -last_face.z)
		body.rotation.y = lerp_angle(body.rotation.y, desired_yaw, minf(1.0, delta * 13.0))
	velocity.y = -GRAVITY if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	if terrain_ik_available and animation != null:
		var cycle_phase := 0.0
		if animation.current_animation_length > 0.0:
			cycle_phase = fposmod(animation.current_animation_position / animation.current_animation_length, 1.0)
		terrain_foot_ik.update_foot_ik(delta, anim_state, cycle_phase)

func receive_damage(damage: float) -> void:
	if invulnerable > 0.0: return
	hp = maxf(0.0, hp - damage)
	health_changed.emit(hp, max_hp)
	if hp <= 0.0:
		hp = max_hp
		global_position = Vector3(0, 0.08, 0)
		health_changed.emit(hp, max_hp)
