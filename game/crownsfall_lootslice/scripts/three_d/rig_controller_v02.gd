extends "res://scripts/three_d/rig_controller.gd"
## Opt-in V02 humanoid controller. Main 2D game and F7 proxy remain untouched by default.
## Original game logic (physics, hit timing, cooldowns, save boundaries) is inherited.
const MASTER_MODEL: PackedScene = preload("res://models/AOTL_Humanoid_Master_V02.glb")
const REEL_MANIFEST := "res://data/humanoid_v02_reel_manifest.json"

var master_skeleton: Skeleton3D
var equipment_sockets: Dictionary = {}
var movement_tree: AnimationTree
var movement_target := 0.0
var split_clip_count := 0
var rig_release_ready := false

func _ready() -> void:
	super._ready()
	# The inherited constructor adds the protected old proxy, collision and test semantics.
	if body != null:
		body.free()
	body = MASTER_MODEL.instantiate()
	body.name = "AOTL_Humanoid_Master_V02"
	add_child(body)
	animation = body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skeletons: Array = body.find_children("*", "Skeleton3D", true, false)
	master_skeleton = skeletons[0] as Skeleton3D if skeletons.size() > 0 else null
	clip_names.clear()
	if animation == null or master_skeleton == null:
		push_error("V02 missing AnimationPlayer or Skeleton3D")
		return
	_install_reel_subclips()
	_install_equipment_sockets()
	_install_movement_blend()
	anim_state = ""
	_play("Idle")
	rig_release_ready = split_clip_count == 16 and equipment_sockets.size() == 7

func _sample_track(source: Animation, track: int, time: float) -> Variant:
	var v: Variant = null
	match source.track_get_type(track):
		Animation.TYPE_POSITION_3D:
			v = source.position_track_interpolate(track, time)
		Animation.TYPE_ROTATION_3D:
			v = source.rotation_track_interpolate(track, time)
		Animation.TYPE_SCALE_3D:
			v = source.scale_track_interpolate(track, time)
		Animation.TYPE_BLEND_SHAPE:
			v = source.blend_shape_track_interpolate(track, time)
		Animation.TYPE_VALUE:
			v = source.value_track_interpolate(track, time)
		Animation.TYPE_BEZIER:
			v = source.bezier_track_interpolate(track, time)
	if v != null:
		return v
	var key_count: int = source.track_get_key_count(track)
	if key_count == 0:
		return null
	var nearest := 0
	for k in key_count:
		if source.track_get_key_time(track, k) <= time:
			nearest = k
		else:
			break
	return source.track_get_key_value(track, nearest)

func _install_reel_subclips() -> void:
	if not FileAccess.file_exists(REEL_MANIFEST):
		push_error("V02 animation reel manifest missing")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REEL_MANIFEST))
	if not parsed is Dictionary:
		push_error("V02 invalid animation reel manifest")
		return
	var source_key: StringName = &""
	for candidate in animation.get_animation_list():
		if String(candidate).contains("RIG_AOTL_Master_Humanoid_58"):
			source_key = candidate
			break
	if source_key == &"":
		push_error("V02 glTF export reel missing")
		return
	var reel: Animation = animation.get_animation(source_key)
	var fps := float(parsed.get("fps", 30))
	var library := AnimationLibrary.new()
	for raw in parsed.get("clips", []):
		if not raw is Dictionary:
			continue
		var id := String(raw.get("name", ""))
		var a := float(int(raw.get("start_frame", 0)) - 1) / fps
		var b := float(int(raw.get("end_frame", 0)) - 1) / fps
		if id.is_empty() or a < 0.0 or b <= a:
			continue
		var clip := Animation.new()
		clip.length = (b - a) + 1.0 / fps
		clip.loop_mode = Animation.LOOP_LINEAR if raw.get("loop", false) else Animation.LOOP_NONE
		for index in reel.get_track_count():
			var keys := reel.track_get_key_count(index)
			if keys == 0:
				continue
			var target_idx := clip.add_track(reel.track_get_type(index))
			clip.track_set_path(target_idx, reel.track_get_path(index))
			clip.track_set_interpolation_type(target_idx, reel.track_get_interpolation_type(index))
			clip.track_set_enabled(target_idx, reel.track_is_enabled(index))
			var start_value: Variant = _sample_track(reel, index, a)
			if start_value != null:
				clip.track_insert_key(target_idx, 0.0, start_value)
			for k in keys:
				var t := reel.track_get_key_time(index, k)
				if t > a + 0.0005 and t < b - 0.0005:
					clip.track_insert_key(target_idx, t - a, reel.track_get_key_value(index, k))
			var end_value: Variant = _sample_track(reel, index, b)
			if end_value != null:
				clip.track_insert_key(target_idx, b - a, end_value)
		var err: Error = library.add_animation(id, clip)
		if err != OK:
			push_error("V02 failed splitting clip " + id)
	var added := animation.add_animation_library("AOTL_V02", library)
	if added != OK:
		push_error("V02 failed adding animation library")
		return
	for name in library.get_animation_list():
		clip_names[String(name)] = "AOTL_V02/" + String(name)
	split_clip_count = library.get_animation_list().size()

func _install_equipment_sockets() -> void:
	var mapping := {
		"weapon": "WeaponRoot",
		"shield": "ShieldRoot",
		"vfx_right": "HandR",
		"vfx_left": "HandL",
		"back": "UpperChest",
		"head": "Head",
		"waist": "Hips"
	}
	for slot in mapping.keys():
		var bone_name: String = mapping[slot]
		if master_skeleton.find_bone(bone_name) < 0:
			push_error("Missing V02 socket joint: " + bone_name)
			continue
		var attachment := BoneAttachment3D.new()
		attachment.name = "SOCKET_" + String(slot)
		attachment.bone_name = bone_name
		master_skeleton.add_child(attachment)
		equipment_sockets[slot] = attachment

func _install_movement_blend() -> void:
	if not clip_names.has("Idle") or not clip_names.has("Walk") or not clip_names.has("Run"):
		return
	var blend := AnimationNodeBlendSpace1D.new()
	blend.min_space = 0.0
	blend.max_space = 1.0
	for entry in [["Idle", 0.0], ["Walk", 0.55], ["Run", 1.0]]:
		var state := AnimationNodeAnimation.new()
		state.animation = clip_names[String(entry[0])]
		blend.add_blend_point(state, float(entry[1]))
	movement_tree = AnimationTree.new()
	movement_tree.name = "AOTL_V02_LocomotionBlend"
	body.add_child(movement_tree)
	movement_tree.anim_player = movement_tree.get_path_to(animation)
	movement_tree.tree_root = blend
	movement_tree.active = true
	movement_tree.set("parameters/blend_position", 0.0)

func _play(clip: String) -> void:
	if animation == null or not clip_names.has(clip):
		return
	if clip in ["Idle", "Walk", "Run"]:
		movement_target = 0.0 if clip == "Idle" else (0.55 if clip == "Walk" else 1.0)
		if movement_tree != null and not movement_tree.active:
			movement_tree.active = true
		elif movement_tree == null and anim_state != clip:
			animation.play(clip_names[clip], 0.20)
		anim_state = clip
	else:
		if movement_tree != null:
			movement_tree.active = false
		if anim_state != clip:
			animation.play(clip_names[clip], 0.12)
			anim_state = clip

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if movement_tree != null and movement_tree.active:
		var current := float(movement_tree.get("parameters/blend_position"))
		movement_tree.set("parameters/blend_position", move_toward(current, movement_target, 3.4 * delta))

func _attack(kind: String, duration: float) -> void:
	var before := attack_t
	super._attack(kind, duration)
	if before <= 0.0 and attack_t > 0.0 and attack_type == kind:
		if kind == "Cleave":
			_play("Cleave")
		elif kind == "Dash":
			_play("DashStrike")

func set_equipment_visual(slot: String, visual: Node3D) -> bool:
	## Attach an instanced item mesh/scene to a real rig joint. Does not touch item rules.
	if not equipment_sockets.has(slot):
		return false
	var mount: BoneAttachment3D = equipment_sockets[slot]
	for child in mount.get_children():
		child.queue_free()
	if visual != null:
		mount.add_child(visual)
		visual.transform = Transform3D.IDENTITY
	_show_embedded(slot, false)
	return true

func clear_equipment_visual(slot: String) -> bool:
	if not equipment_sockets.has(slot):
		return false
	var mount: BoneAttachment3D = equipment_sockets[slot]
	for child in mount.get_children():
		child.queue_free()
	_show_embedded(slot, true)
	return true

func _show_embedded(slot: String, show_embedded: bool) -> void:
	var prefix := "WEAPON_" if slot == "weapon" else ("SHIELD_" if slot == "shield" else "")
	if prefix.is_empty():
		return
	for node in body.find_children("*", "MeshInstance3D", true, false):
		if String(node.name).begins_with(prefix):
			(node as MeshInstance3D).visible = show_embedded
