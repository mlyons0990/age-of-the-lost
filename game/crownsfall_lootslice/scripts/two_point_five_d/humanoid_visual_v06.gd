extends Node3D
## Visual-only bridge: original painted movement/collision owns physics and combat;
## V06 implements directional locomotion, toe roll and knee pole targets from Higgsfield rev11.
## Turn on in the Phase02 scene with --aotl-v06. Never touches the save schema.
const MODEL_PATH := "res://models/AOTL_Humanoid_Master_V06.glb"
const REEL_MANIFEST := "res://data/humanoid_v06_reel_manifest.json"

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
var directional_target := Vector2.ZERO
var directional_current := Vector2.ZERO
var directional_run_weight := 0.0
var facing_lock_active := false
var turning_in_place := false
var turn_sign := 0
var toe_roll_enabled := true
var disabled_stage_lights := 0
var disabled_stage_cameras := 0

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
	name = "AOTL_V06_DirectionalToeRoll_Visual"
	actor_body = get_parent() as CharacterBody3D
	if not ResourceLoader.exists(MODEL_PATH):
		push_warning("V06 model missing. Run tools/restore_rig_v06.py; original painted Warrior stays intact.")
		return
	var resource := load(MODEL_PATH) as PackedScene
	if resource == null:
		push_error("Failed loading reconstructed humanoid GLB")
		return
	model_root = resource.instantiate() as Node3D
	model_root.name = "AOTL_Humanoid_Master_V06"
	_disable_imported_studio_nodes()
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
	ready_to_compare = clip_count == 23 and equipment.size() == 7 and foot_ik.size() == 2
	if ready_to_compare:
		_play_clip("Idle")
	visible = false

func _disable_imported_studio_nodes() -> void:
	# Blender's exported lighting and camera are for Higgsfield turntable renders.
	# Never let their 3 lights override the approved 21m Crownsfall world lighting.
	for node in model_root.find_children("*", "Node3D", true, false):
		if node is Light3D:
			var stage_light := node as Light3D
			stage_light.visible = false
			stage_light.light_energy = 0.0
			stage_light.process_mode = Node.PROCESS_MODE_DISABLED
			disabled_stage_lights += 1
		elif node is Camera3D:
			var stage_camera := node as Camera3D
			stage_camera.current = false
			stage_camera.visible = false
			stage_camera.process_mode = Node.PROCESS_MODE_DISABLED
			disabled_stage_cameras += 1

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
	if animation.add_animation_library("AOTL_V06", lib) != OK:
		push_error("Cannot register V03 action library")
		return
	for k in lib.get_animation_list():
		clips[String(k)] = "AOTL_V06/" + String(k)
	clip_count = clips.size()

func _build_locomotion() -> void:
	var keys := ["Idle","V06_WalkForward","V06_RunForward","V06_StrafeLeft","V06_StrafeRight","V06_WalkBackward"]
	for key in keys:
		if not clips.has(key):
			push_error("V06 directional clip absent: " + key)
			return
	# 2D directional blend: X = right strafe, Y = forward; back = -Y.
	var direction := AnimationNodeBlendSpace2D.new()
	direction.resource_name = "V06_X_Strafe_Y_Forward"
	direction.min_space = Vector2(-1.0,-1.0)
	direction.max_space = Vector2(1.0,1.0)
	direction.auto_triangles = true
	direction.sync = true
	for pair in [
		["Idle",Vector2.ZERO],
		["V06_WalkForward",Vector2(0,1)],
		["V06_WalkBackward",Vector2(0,-1)],
		["V06_StrafeLeft",Vector2(-1,0)],
		["V06_StrafeRight",Vector2(1,0)]
	]:
		var state := AnimationNodeAnimation.new()
		state.animation = clips[String(pair[0])]
		direction.add_blend_point(state, pair[1])
	# Run-forward is mixed in only when the character moves forward at sprint speed.
	var run := AnimationNodeAnimation.new()
	run.animation = clips["V06_RunForward"]
	locomotion = AnimationTree.new()
	locomotion.name = "V06_Directional_2D_Locomotion"
	model_root.add_child(locomotion)
	locomotion.anim_player = locomotion.get_path_to(animation)
	var graph := AnimationNodeBlendTree.new()
	graph.add_node("Direction",direction)
	graph.add_node("Run",run)
	graph.add_node("RunMix",AnimationNodeBlend2.new())
	graph.add_node("Rate",AnimationNodeTimeScale.new())
	graph.connect_node("RunMix",0,"Direction")
	graph.connect_node("RunMix",1,"Run")
	graph.connect_node("Rate",0,"RunMix")
	graph.connect_node("output",0,"Rate")
	locomotion.tree_root = graph
	locomotion.active = true
	locomotion.set("parameters/Direction/blend_position", Vector2.ZERO)
	locomotion.set("parameters/RunMix/blend_amount", 0.0)
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
		node.use_magnet = true
		node.max_iterations = 12
		node.min_distance = 0.009
		node.influence = 0.0
		node.start()
		foot_ik[side] = node

func _play_clip(clip: String) -> void:
	if not clips.has(clip):
		return
	if clip in ["Idle","Walk","Run","V06_WalkForward","V06_WalkBackward","V06_StrafeLeft","V06_StrafeRight","V06_RunForward"]:
		if locomotion != null and not locomotion.active:
			locomotion.active = true
		elif locomotion == null and current_clip != clip:
			animation.play(clips[clip],0.15)
	else:
		if locomotion != null and locomotion.active:
			locomotion.active = false
		if current_clip != clip:
			animation.play(clips[clip],0.12)
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
		directional_target = Vector2.ZERO
		directional_current = Vector2.ZERO
		directional_run_weight = 0.0
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
	var desired_yaw := rotation.y
	if look.length_squared() > 0.0001:
		desired_yaw = atan2(-look.x,-look.z)
	var turn_error := wrapf(desired_yaw - rotation.y,-PI,PI)
	var velocity_world := Vector3.ZERO
	if actor_body != null:
		velocity_world = Vector3(actor_body.velocity.x,0.0,actor_body.velocity.z)
	var horizontal_speed := velocity_world.length()
	facing_lock_active = bool(actor_body.v06_facing_locked) if actor_body != null else false
	turning_in_place = state == "idle" and horizontal_speed < 0.16 and absf(turn_error) > 0.13
	turn_sign = -1 if turn_error < 0.0 else 1
	if absf(turn_error) > 0.0001:
		var turn_rate := 7.5 if horizontal_speed < 0.2 else 11.0
		rotation.y = lerp_angle(rotation.y,desired_yaw,clampf(delta*turn_rate,0.0,1.0))
	# Convert actual world movement into the model's facing space.
	var local_velocity: Vector3 = global_basis.inverse() * velocity_world
	directional_target = Vector2(local_velocity.x,-local_velocity.z)
	if directional_target.length() > 0.16:
		directional_target = directional_target.normalized()
	else:
		directional_target = Vector2.ZERO
	directional_current = directional_current.lerp(directional_target,clampf(delta*11.0,0.0,1.0))
	# The pivot is only used while standing and turning enough to need a support step.
	var key := "Idle"
	match state:
		"walk","run": key = "V06_WalkForward"
		"dodge": key = "Dodge"
		"slash": key = "Slash"
		"heavy": key = "Cleave"
		"cast": key = "Cast"
	if turning_in_place and state == "idle":
		key = "V06_PivotLeft" if turn_sign < 0 else "V06_PivotRight"
	# Gait speed is tied to displacement in metres (V05 acceptance).
	var desired_rate := 1.0
	if state in ["walk","run"] and horizontal_speed > 0.16:
		var source_clip := "V06_RunForward" if state == "run" and directional_target.y > 0.30 else "V06_WalkForward"
		var source_seconds := animation.get_animation(clips[source_clip]).length
		var stride_metres := stride_run_m if source_clip == "V06_RunForward" else stride_walk_m
		desired_rate = clampf(source_seconds*horizontal_speed/stride_metres,0.68,2.75)
	gait_animation_rate=lerpf(gait_animation_rate,desired_rate,clampf(delta*13.0,0.0,1.0))
	if key != current_clip:
		_play_clip(key)
	if locomotion != null and locomotion.active:
		locomotion.set("parameters/Direction/blend_position",directional_current)
		var run_goal := clampf((directional_target.y-0.25)*1.5,0.0,1.0) if state == "run" else 0.0
		directional_run_weight=move_toward(directional_run_weight,run_goal,delta*5.0)
		locomotion.set("parameters/RunMix/blend_amount",directional_run_weight)
		locomotion.set("parameters/Rate/scale",gait_animation_rate)
	if previous_state == "dodge" and state != "dodge":
		recovered_from_dodge+=1
		action_recovery_progress=0.0
	if state != "dodge":
		action_recovery_progress=minf(1.0,action_recovery_progress+delta*3.6)
	_update_feet(state,delta)
	previous_state=state

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
		# Pole target follows the forward bend of the actual knee on turns and strafes.
		# Magnets are local to the IK node (not global world coordinates).
		var knee_index := skeleton.find_bone("Knee"+side)
		if knee_index >= 0:
			var knee_world := skeleton.to_global(skeleton.get_bone_global_pose(knee_index).origin)
			var knee_forward := -global_basis.z
			knee_forward.y = 0.0
			knee_forward = knee_forward.normalized()
			var lateral_offset := global_basis.x*(0.07 if side == "R" else -0.07)
			solver.magnet = solver.to_local(knee_world+knee_forward*0.24+lateral_offset)
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
		if turning_in_place:
			# One planted support foot while the free foot pivots underneath the hips.
			stance = side == ("L" if turn_sign < 0 else "R")
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
			var clearance := step_height_m * sin(swing_t * PI) if moving else (0.055 if turning_in_place else 0.0)
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

func get_direction_vector_for_test() -> Vector2:
	return directional_target

func get_turning_for_test() -> bool:
	return turning_in_place

func get_knee_magnet_for_test(side: String) -> Vector3:
	return (foot_ik[side] as SkeletonIK3D).magnet if foot_ik.has(side) else Vector3.ZERO
