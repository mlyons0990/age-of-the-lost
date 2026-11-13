extends RefCounted
## Phase 20: sample feet through an optional master animation.
## Results are bone-relative trajectory indicators, not ground-contact proof.
const FEET := ["FootL", "FootR"]
const DEFAULT_SAMPLES := 25
const CONTACT_BAND := 0.085

static func foot_world_position(skeleton: Skeleton3D, bone_index: int) -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(bone_index).origin

static func summarize_path(positions: Array[Vector3], contact_band: float = CONTACT_BAND) -> Dictionary:
	if positions.is_empty():
		return {"samples": 0, "error": "no samples"}
	var min_height := INF
	var max_height := -INF
	for p in positions:
		min_height = minf(min_height, p.y)
		max_height = maxf(max_height, p.y)
	var path_m := 0.0
	var contact_path_m := 0.0
	var contact_samples := 0
	for i in positions.size():
		if positions[i].y <= min_height + contact_band:
			contact_samples += 1
		if i > 0:
			var delta := positions[i] - positions[i - 1]
			var segment := Vector2(delta.x, delta.z).length()
			path_m += segment
			if positions[i].y <= min_height + contact_band and positions[i - 1].y <= min_height + contact_band:
				contact_path_m += segment
	return {"loop_seam_m": positions[0].distance_to(positions[-1]),
		"samples": positions.size(), "min_y": min_height, "max_y": max_height,
		"vertical_range_m": max_height - min_height,
		"horizontal_path_m": path_m, "low_foot_path_m": contact_path_m,
		"near_lowest_samples": contact_samples, "points": positions}

static func inspect_clip(animator: AnimationPlayer, skeleton: Skeleton3D, clip_key: String, sample_count: int = DEFAULT_SAMPLES) -> Dictionary:
	if animator == null or skeleton == null or not animator.has_animation(clip_key):
		return {"ok": false, "error": "missing animator, skeleton, or animation"}
	var bones: Array[int] = []
	for name in FEET:
		var index := skeleton.find_bone(name)
		if index < 0:
			return {"ok": false, "error": "missing bone " + name}
		bones.append(index)
	var clip := animator.get_animation(clip_key)
	var count := maxi(3, sample_count)
	var previous := animator.current_animation
	var previous_position := animator.current_animation_position
	var previous_playing := animator.is_playing()
	var tracks := [[], []]
	for i in range(count):
		var t := clip.length * float(i) / float(count - 1)
		animator.play(clip_key, 0.0)
		animator.seek(t, true)
		animator.advance(0.0)
		for side in range(2):
			tracks[side].append(foot_world_position(skeleton, bones[side]))
	if previous != "" and animator.has_animation(previous):
		animator.play(previous, 0.0)
		animator.seek(previous_position, true)
		animator.advance(0.0)
		if not previous_playing:
			animator.pause()
	else:
		animator.stop()
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for p in tracks[0]:
		left.append(p)
	for p in tracks[1]:
		right.append(p)
	return {"ok": true, "clip": clip_key, "duration_s": clip.length,
		"left": summarize_path(left), "right": summarize_path(right), "samples": count}
