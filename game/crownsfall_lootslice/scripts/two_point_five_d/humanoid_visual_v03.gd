extends Node3D
## Visual-only bridge: original painted movement/collision owns physics and combat;
## Higgsfield Master V02 owns the 58-joint mesh, 16 actions, optional terrain IK and sockets.
## Turn on in the Phase02 scene with --aotl-v03. Never touches the save schema.
const MODEL_PATH := "res://models/AOTL_Humanoid_Master_V02.glb"
const REEL_MANIFEST := "res://data/humanoid_v02_reel_manifest.json"

var model_root: Node3D
var skeleton: Skeleton3D
var animation: AnimationPlayer
var locomotion: AnimationTree
var clips: Dictionary = {}
var equipment: Dictionary = {}
var foot_ik: Dictionary = {}
var foot_target: Dictionary = {}
var foot_contacts: Dictionary = {"L": false, "R": false}
var foot_anchors: Dictionary = {}
var clip_count := 0
var ready_to_compare := false
var current_clip := ""
var locomotion_target := 0.0
var is_grounded := false
var previous_state := ""
var foot_ik_enabled := true
var actor_body: CharacterBody3D

func _ready() -> void:
	name = "AOTL_V03_Higgsfield_Humanoid_Visual"
	actor_body = get_parent() as CharacterBody3D
	if not ResourceLoader.exists(MODEL_PATH):
		push_warning("V03 rig not restored. Run tools/restore_rig_v02.py; painted mode stays playable.")
		return
	var resource := load(MODEL_PATH) as PackedScene
	if resource == null:
		push_error("Failed loading reconstructed humanoid GLB")
		return
	model_root = resource.instantiate() as Node3D
	model_root.name = "AOTL_Humanoid_Master_V02"
	add_child(model_root)
	animation = model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var all_skeletons: Array = model_root.find_children("*", "Skeleton3D", true, false)
	if all_skeletons.size() > 0:
		skeleton = all_skeletons[0] as Skeleton3D
	if animation == null or skeleton == null:
		push_error("V03 GLB missing skeleton or AnimationPlayer")
		return
	_split_export_reel()
	_build_locomotion()
	_build_sockets()
	_build_foot_ik()
	ready_to_compare = clip_count == 16 and equipment.size() == 7 and foot_ik.size() == 2
	if ready_to_compare:
		_play_clip("Idle")
	visible = false

func _sample_track(source: Animation, index: int, at_time: float) -> Variant:
	var v: Variant = null
	match source.track_get_type(index):
		Animation.TYPE_POSITION_3D:
			v = source.position_track_interpolate(index, at_time)
		Animation.TYPE_ROTATION_3D:
			v = source.rotation_track_interpolate(index, at_time)
		Animation.TYPE_SCALE_3D:
			v = source.scale_track_interpolate(index, at_time)
		Animation.TYPE_VALUE:
			v = source.value_track_interpolate(index, at_time)
		Animation.TYPE_BLEND_SHAPE:
			v = source.blend_shape_track_interpolate(index, at_time)
	if v != null:
		return v
	var key_count := source.track_get_key_count(index)
	if key_count == 0:
		return null
	var nearest := 0
	for i in key_count:
		if source.track_get_key_time(index, i) <= at_time:
			nearest = i
		else:
			break
	return source.track_get_key_value(index, nearest)

func _split_export_reel() -> void:
	if not FileAccess.file_exists(REEL_MANIFEST):
		push_error("V03 reel manifest missing")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REEL_MANIFEST))
	if not parsed is Dictionary:
		push_error("Invalid V03 reel JSON")
		return
	var source_name: StringName = &""
	for candidate in animation.get_animation_list():
		if String(candidate).contains("RIG_AOTL_Master_Humanoid_58"):
			source_name = candidate
			break
	if source_name == &"":
		push_error("V03 reel animation missing from exported GLB")
		return
	var reel: Animation = animation.get_animation(source_name)
	var fps := float(parsed.get("fps", 30))
	var lib := AnimationLibrary.new()
	for entry in parsed.get("clips", []):
		if not entry is Dictionary:
			continue
		var id := String(entry.get("name", ""))
		var begin := float(int(entry.get("start_frame", 0)) - 1) / fps
		var end := float(int(entry.get("end_frame", 0)) - 1) / fps
		if id.is_empty() or end <= begin:
			continue
		var sub := Animation.new()
		sub.length = end - begin + 1.0 / fps
		sub.loop_mode = Animation.LOOP_LINEAR if entry.get("loop", false) else Animation.LOOP_NONE
		for tr in reel.get_track_count():
			if reel.track_get_key_count(tr) == 0:
				continue
			var dest := sub.add_track(reel.track_get_type(tr))
			sub.track_set_path(dest, reel.track_get_path(tr))
			sub.track_set_interpolation_type(dest, reel.track_get_interpolation_type(tr))
			sub.track_set_enabled(dest, reel.track_is_enabled(tr))
			var first: Variant = _sample_track(reel, tr, begin)
			if first != null:
				sub.track_insert_key(dest, 0.0, first)
			for k in reel.track_get_key_count(tr):
				var at := reel.track_get_key_time(tr, k)
				if at > begin + 0.0005 and at < end - 0.0005:
					sub.track_insert_key(dest, at - begin, reel.track_get_key_value(tr, k))
			var last: Variant = _sample_track(reel, tr, end)
			if last != null:
				sub.track_insert_key(dest, end - begin, last)
		var err := lib.add_animation(id, sub)
		if err != OK:
			push_error("Cannot load V03 action: " + id)
	if animation.add_animation_library("AOTL_V03", lib) != OK:
		push_error("Cannot register V03 action library")
		return
	for k in lib.get_animation_list():
		clips[String(k)] = "AOTL_V03/" + String(k)
	clip_count = clips.size()

func _build_locomotion() -> void:
	if not clips.has("Idle") or not clips.has("Walk") or not clips.has("Run"):
		return
	var blend := AnimationNodeBlendSpace1D.new()
	blend.min_space = 0.0
	blend.max_space = 1.0
	for pair in [["Idle", 0.0], ["Walk", 0.55], ["Run", 1.0]]:
		var node := AnimationNodeAnimation.new()
		node.animation = clips[String(pair[0])]
		blend.add_blend_point(node, float(pair[1]))
	locomotion = AnimationTree.new()
	locomotion.name = "V03_Idle_Walk_Run_ContinuousBlend"
	model_root.add_child(locomotion)
	locomotion.anim_player = locomotion.get_path_to(animation)
	locomotion.tree_root = blend
	locomotion.active = true
	locomotion.set("parameters/blend_position", 0.0)

func _build_sockets() -> void:
	var bones := {
		"weapon": "WeaponRoot", "shield": "ShieldRoot",
		"spell_right": "HandR", "spell_left": "HandL",
		"back": "UpperChest", "helmet": "Head", "belt": "Hips"
	}
	for id in bones.keys():
		var bone: String = bones[id]
		if skeleton.find_bone(bone) == -1:
			push_error("Missing attachment bone " + bone)
			continue
		var mount := BoneAttachment3D.new()
		mount.name = "EQUIPMENT_" + String(id)
		mount.bone_name = bone
		skeleton.add_child(mount)
		equipment[id] = mount

func _build_foot_ik() -> void:
	# Godot 4.6 SkeletonIK3D is a real FABRIK solver but deprecated. Keep isolated,
	# weighted low while moving, and replace with a 4.6 native IKModifier after visual QA.
	for side in ["L", "R"]:
		var root: String = "Thigh" + String(side)
		var tip: String = "Ankle" + String(side)
		if skeleton.find_bone(root) == -1 or skeleton.find_bone(tip) == -1:
			push_warning("Cannot build "+side+" foot chain")
			continue
		var marker := Marker3D.new()
		marker.name = "FootTarget_" + side
		add_child(marker)
		foot_target[side] = marker
		var node := SkeletonIK3D.new()
		node.name = "GroundContactIK_" + side
		# Initialize the full chain before attaching to a live Skeleton3D.
		# Setting root/tip after parenting emits transient FABRIK invalid-root errors.
		node.root_bone = root
		node.tip_bone = tip
		skeleton.add_child(node)
		node.target_node = node.get_path_to(marker)
		node.override_tip_basis = false
		node.max_iterations = 12
		node.min_distance = 0.009
		node.influence = 0.0
		node.start()
		foot_ik[side] = node

func _play_clip(clip: String) -> void:
	if not clips.has(clip):
		return
	if clip in ["Idle", "Walk", "Run"]:
		locomotion_target = 0.0 if clip == "Idle" else (0.55 if clip == "Walk" else 1.0)
		if locomotion != null:
			if not locomotion.active:
				locomotion.active = true
		elif current_clip != clip:
			animation.play(clips[clip], 0.16)
	else:
		if locomotion != null and locomotion.active:
			locomotion.active = false
		if current_clip != clip:
			animation.play(clips[clip], 0.11)
	current_clip = clip

func set_visual_mode(enabled: bool) -> void:
	visible = enabled
	if not enabled:
		for side in foot_ik:
			(foot_ik[side] as SkeletonIK3D).influence = 0.0
	else:
		previous_state = ""
		current_clip = ""

func sync_actor(state: String, look: Vector3, delta: float) -> void:
	if not ready_to_compare or not visible:
		return
	if look.length_squared() > 0.0001:
		var yaw := atan2(-look.x, -look.z)
		rotation.y = lerp_angle(rotation.y, yaw, clampf(delta * 13.0, 0.0, 1.0))
	var key := "Idle"
	match state:
		"walk": key = "Walk"
		"run": key = "Run"
		"dodge": key = "Dodge"
		"slash": key = "Slash"
		"heavy": key = "Cleave"
		"cast": key = "Cast"
	if key != current_clip:
		_play_clip(key)
	if locomotion != null and locomotion.active:
		var current := float(locomotion.get("parameters/blend_position"))
		locomotion.set("parameters/blend_position", move_toward(current, locomotion_target, delta * 3.8))
	_update_feet(state, delta)
	previous_state = state

func _update_feet(state: String, delta: float) -> void:
	# Real 3D ray/target IK; avoids overconstraining a sprint or airborne dodge.
	var blend := 0.0
	match state:
		"idle": blend = 0.82
		"walk": blend = 0.38
		"run": blend = 0.12
		"slash", "heavy", "cast": blend = 0.55
	for side in foot_ik.keys():
		var ankle := skeleton.find_bone("Ankle" + String(side))
		var location := skeleton.to_global(skeleton.get_bone_global_pose(ankle).origin)
		var world := get_world_3d()
		if world == null:
			continue
		var query := PhysicsRayQueryParameters3D.create(location + Vector3.UP * 0.6, location + Vector3.DOWN * 0.90)
		query.collision_mask = 1
		if actor_body != null:
			query.exclude = [actor_body.get_rid()]
		var hit: Dictionary = world.direct_space_state.intersect_ray(query)
		var valid: bool = not hit.is_empty()
		foot_contacts[side] = valid
		var solver: SkeletonIK3D = foot_ik[side]
		solver.influence = move_toward(solver.influence, blend if valid and foot_ik_enabled else 0.0, delta * 3.0)
		if not valid:
			continue
		var desired := Vector3(location.x, float(hit.position.y) + 0.13, location.z)
		var target: Marker3D = foot_target[side]
		if previous_state != "idle" and state == "idle":
			foot_anchors[side] = desired
		if state == "idle" and foot_anchors.has(side):
			desired.x = float(foot_anchors[side].x)
			desired.z = float(foot_anchors[side].z)
		target.global_position = target.global_position.lerp(desired, clampf(delta * 17.0, 0.0, 1.0))
	if state != "idle":
		foot_anchors.clear()

func get_foot_contact_count() -> int:
	return int(bool(foot_contacts.get("L", false))) + int(bool(foot_contacts.get("R", false)))

func attach_equipment(slot: String, visual: Node3D) -> bool:
	## Only visual mounts; inventory IDs, stats and saves remain owned by original systems.
	if not equipment.has(slot):
		return false
	var mount: BoneAttachment3D = equipment[slot]
	for child in mount.get_children():
		child.queue_free()
	if visual != null:
		mount.add_child(visual)
		visual.transform = Transform3D.IDENTITY
	return true
