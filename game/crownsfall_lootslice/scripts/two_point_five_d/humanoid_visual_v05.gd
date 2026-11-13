extends Node3D
## Visual-only bridge: original painted movement/collision owns physics and combat;
## V05 synchronizes authored gait with physics displacement and improves planted-foot weight transfer.
## Turn on in the Phase02 scene with --aotl-v03. Never touches the save schema.
const MODEL_PATH := "res://models/AOTL_Humanoid_Master_V04.glb"
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
# World-space stance anchors persist across character movement (the V03 solver did not).
var gait_phase := 0.0
var gait_travel_m := 0.0
var locked_foot: Dictionary = {"L": false, "R": false}
var planted_world: Dictionary = {}
var planted_frames: Dictionary = {"L": 0, "R": 0}
var contact_transitions := 0
var contact_release_count := 0
var gait_current_speed := 0.0
var stride_walk_m := 1.9   # two steps per full gait cycle, physically relative to velocity
var stride_run_m := 2.6
var step_height_m := 0.16
var peak_plant_error_m := 0.0
var gait_animation_rate := 1.0
var action_compression_m := 0.0
var action_recovery_progress := 1.0
var recovered_from_dodge := 0
var stride_contact_window_walk := 0.30
var stride_contact_window_run := 0.23


var clip_count := 0
var ready_to_compare := false
var current_clip := ""
var locomotion_target := 0.0
var is_grounded := false
var previous_state := ""
var foot_ik_enabled := true
var actor_body: CharacterBody3D

func _ready() -> void:
	name = "AOTL_V05_PhysicsSynchronized_Gait_Visual"
	actor_body = get_parent() as CharacterBody3D
	if not ResourceLoader.exists(MODEL_PATH):
		push_warning("V05 needs V04 weighted humanoid. Run tools/restore_rig_v04.py.")
		return
	var resource := load(MODEL_PATH) as PackedScene
	if resource == null:
		push_error("Failed loading reconstructed humanoid GLB")
		return
	model_root = resource.instantiate() as Node3D
	model_root.name = "AOTL_Humanoid_Master_V04"
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
	# Godot 4.6.3 supports sync=true; cyclic sync modes arrive in 4.7.
	# Keep inactive blend points advancing, with our physics-derived speed_scale.
	blend.sync = true
	for pair in [["Idle", 0.0], ["Walk", 0.55], ["Run", 1.0]]:
		var node := AnimationNodeAnimation.new()
		node.animation = clips[String(pair[0])]
		blend.add_blend_point(node, float(pair[1]))
	locomotion = AnimationTree.new()
	locomotion.name = "V03_Idle_Walk_Run_ContinuousBlend"
	model_root.add_child(locomotion)
	locomotion.anim_player = locomotion.get_path_to(animation)
	# Godot 4.6-compatible speed control: AnimationNodeTimeScale in BlendTree.
	# The tree has Movement -> Rate -> output; no invalid AnimationTree.speed_scale.
	var graph := AnimationNodeBlendTree.new()
	graph.add_node("Movement", blend)
	graph.add_node("Rate", AnimationNodeTimeScale.new())
	graph.connect_node("Rate", 0, "Movement")
	graph.connect_node("output", 0, "Rate")
	locomotion.tree_root = graph
	locomotion.active = true
	locomotion.set("parameters/Movement/blend_position", 0.0)
	locomotion.set("parameters/Rate/scale", 1.0)

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
		_release_all_contacts()
	else:
		previous_state = ""
		current_clip = ""
		gait_phase = 0.0
		gait_travel_m = 0.0
		gait_animation_rate = 1.0
		_release_all_contacts()

func _release_all_contacts() -> void:
	for side in ["L", "R"]:
		locked_foot[side] = false
		foot_contacts[side] = false
	planted_world.clear()
	foot_anchors.clear()


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
	# Synchronize the gait cycle to physical displacement, not a constant clip FPS.
	var horizontal_speed: float = Vector2(actor_body.velocity.x, actor_body.velocity.z).length() if actor_body != null else 0.0
	var desired_rate := 1.0
	if state == "walk" and horizontal_speed > 0.16:
		var walk_seconds := float(animation.get_animation(clips["Walk"]).length)
		desired_rate = clampf(walk_seconds * horizontal_speed / stride_walk_m, 0.68, 2.55)
	elif state == "run" and horizontal_speed > 0.16:
		var run_seconds := float(animation.get_animation(clips["Run"]).length)
		desired_rate = clampf(run_seconds * horizontal_speed / stride_run_m, 0.65, 2.35)
	gait_animation_rate = lerpf(gait_animation_rate, desired_rate, clampf(delta * 13.0, 0.0, 1.0))
	if key != current_clip:
		_play_clip(key)
	if locomotion != null and locomotion.active:
		var current := float(locomotion.get("parameters/Movement/blend_position"))
		locomotion.set("parameters/Movement/blend_position", move_toward(current, locomotion_target, delta * 3.8))
		locomotion.set("parameters/Rate/scale", gait_animation_rate)
	if previous_state == "dodge" and state != "dodge":
		recovered_from_dodge += 1
		action_recovery_progress = 0.0
	if state != "dodge":
		action_recovery_progress = minf(1.0, action_recovery_progress + delta * 3.6)
	_update_feet(state, delta)
	previous_state = state

func _update_feet(state: String, delta: float) -> void:
	# Contact-phase aware feet: stance target remains at its captured WORLD position,
	# swing is released and lifted, and IK fades during dodge. State is reproducible
	# from measured physics velocity, not a screen-space sprite animation.
	var walking: bool = state == "walk" or state == "run"
	var calm: bool = state == "idle"
	var guarding: bool = state in ["slash", "heavy", "cast"]
	var speed := Vector2(actor_body.velocity.x, actor_body.velocity.z).length() if actor_body != null else 0.0
	gait_current_speed = speed
	var moving: bool = walking and speed > 0.18
	if moving:
		var cycle_metres := stride_run_m if state == "run" else stride_walk_m
		var travelled := speed * clampf(delta, 0.0, 0.075)
		gait_travel_m += travelled
		gait_phase = fposmod(gait_phase + travelled / cycle_metres, 1.0)
	var ground := get_world_3d()
	if ground == null:
		_release_all_contacts()
		return
	var horizontal_forward := Vector3.FORWARD
	if actor_body != null and speed > 0.2:
		horizontal_forward = Vector3(actor_body.velocity.x, 0.0, actor_body.velocity.z).normalized()
	for side in ["L", "R"]:
		var ankle_id := skeleton.find_bone("Ankle" + side)
		if ankle_id == -1 or not foot_ik.has(side):
			continue
		var ankle_world: Vector3 = skeleton.to_global(skeleton.get_bone_global_pose(ankle_id).origin)
		var query := PhysicsRayQueryParameters3D.create(
			ankle_world + Vector3.UP * 0.76,
			ankle_world + Vector3.DOWN * 1.22
		)
		query.collision_mask = 1
		if actor_body != null:
			query.exclude = [actor_body.get_rid()]
		var ray: Dictionary = ground.direct_space_state.intersect_ray(query)
		var on_floor: bool = not ray.is_empty()
		foot_contacts[side] = on_floor
		var solver: SkeletonIK3D = foot_ik[side]
		var marker: Marker3D = foot_target[side]
		if not on_floor or not foot_ik_enabled:
			solver.influence = move_toward(solver.influence, 0.0, delta * 5.0)
			locked_foot[side] = false
			planted_world.erase(side)
			continue
		var floor_y: float = float(ray.position.y)
		var natural := Vector3(ankle_world.x, floor_y + 0.10, ankle_world.z)
		var side_phase := fposmod(gait_phase + (0.0 if side == "L" else 0.50), 1.0)
		var stance_window := stride_contact_window_run if state == "run" else stride_contact_window_walk
		# Speed-based stride timing + explicit swing/stance; never lock dodge feet.
		var stance: bool = calm or guarding or (moving and side_phase < stance_window)
		if state == "dodge":
			stance = false
		if stance and not bool(locked_foot[side]):
			planted_world[side] = natural
			locked_foot[side] = true
			planted_frames[side] = 0
			contact_transitions += 1
		elif not stance and bool(locked_foot[side]):
			locked_foot[side] = false
			planted_world.erase(side)
			contact_release_count += 1
		var target_world := natural
		var wanted_influence := 0.0
		if bool(locked_foot[side]) and planted_world.has(side):
			var anchor: Vector3 = planted_world[side]
			# Releasing an overextended support is safer than stretching the knee
			# backwards or teleporting the foot to a different ground point.
			var upper_leg_id := skeleton.find_bone("Thigh" + side)
			var hip_world: Vector3 = skeleton.to_global(skeleton.get_bone_global_pose(upper_leg_id).origin)
			var xz_reach := Vector2(anchor.x - hip_world.x, anchor.z - hip_world.z).length()
			if xz_reach > 0.52 or absf(hip_world.y - anchor.y) > 1.05:
				locked_foot[side] = false
				planted_world.erase(side)
				contact_release_count += 1
			else:
				target_world = anchor
				planted_frames[side] = int(planted_frames[side]) + 1
				wanted_influence = 1.0 if calm else (0.99 if state == "walk" else (0.92 if state == "run" else 0.92))
				peak_plant_error_m = maxf(peak_plant_error_m, target_world.distance_to(anchor))
		if not bool(locked_foot[side]):
			# Swing foot follows its sampled animated ankle with a real clearance arc.
			var swing_t := clampf((side_phase - stance_window) / maxf(.01, 1.0 - stance_window), 0.0, 1.0)
			var clearance := step_height_m * sin(swing_t * PI) if moving else 0.0
			target_world = natural + Vector3.UP * clearance
			if moving:
				target_world += horizontal_forward * (0.055 * sin(swing_t * PI))
			wanted_influence = 0.07 if moving else 0.0
		if state == "dodge":
			wanted_influence = 0.0
		# Prevent the new anchor itself from lerping away during stance. The solver
		# weight still ramps in smoothly to avoid hard IK pops at foot strike.
		if bool(locked_foot[side]):
			marker.global_position = target_world
		else:
			marker.global_position = marker.global_position.lerp(target_world, clampf(delta * 18.0, 0.0, 1.0))
		solver.influence = move_toward(solver.influence, wanted_influence, delta * 17.0)
	# Small center-of-mass settle and subtle forward lean; actual foot targets remain
	# anchored in world space and do not inherit screen-facing sprite offsets.
	var motion_factor := clampf(speed / 6.7, 0.0, 1.0) if moving else 0.0
	var bob := -0.017 * absf(sin(gait_phase * TAU * 2.0)) * motion_factor
	var lateral_transfer := 0.014 * sin(gait_phase * TAU) * motion_factor
	var pitch_target := -0.040 * motion_factor
	action_compression_m = 0.0
	if state == "dodge" and actor_body != null:
		var dodge_phase := clampf(1.0 - actor_body.dodge_t / 0.66, 0.0, 1.0)
		action_compression_m = -0.085 * sin(dodge_phase * PI)
		pitch_target -= 0.16 * sin(dodge_phase * PI)
	elif state in ["slash", "heavy", "cast"]:
		action_compression_m = -0.022
	elif action_recovery_progress < 1.0:
		action_compression_m = -0.023 * (1.0 - action_recovery_progress)
	model_root.position.y = lerpf(model_root.position.y, bob + action_compression_m, clampf(delta * 10.0, 0.0, 1.0))
	model_root.position.x = lerpf(model_root.position.x, lateral_transfer, clampf(delta * 8.0, 0.0, 1.0))
	model_root.rotation.x = lerpf(model_root.rotation.x, pitch_target, clampf(delta * 8.0, 0.0, 1.0))

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

func is_foot_planted(side: String) -> bool:
	return bool(locked_foot.get(side, false))

func get_plant_position(side: String) -> Vector3:
	return planted_world.get(side, Vector3.ZERO)

func get_plant_stance_frames(side: String) -> int:
	return int(planted_frames.get(side, 0))

func get_cadence_ratio_for_test() -> float:
	return gait_animation_rate

func is_dodge_recovering() -> bool:
	return action_recovery_progress < 1.0
