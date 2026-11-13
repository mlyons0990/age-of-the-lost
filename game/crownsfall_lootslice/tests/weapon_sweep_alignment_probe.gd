extends SceneTree
## Quantify real R39 socket-local blade axis against front-facing training dummy.
const LAB := preload("res://scripts/three_d/rig_lab.gd")
const SWEEP := preload("res://scripts/three_d/weapon_sweep3d.gd")

const DIRECTIONS = {
	"neg_x": Vector3(-1,0,0),
	"pos_x": Vector3(1,0,0),
	"neg_y": Vector3(0,-1,0),
	"pos_y": Vector3(0,1,0),
	"neg_z": Vector3(0,0,-1),
	"pos_z": Vector3(0,0,1)
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var lab := LAB.new()
	root.add_child(lab)
	await physics_frame
	await physics_frame
	var actor = lab.player
	if actor == null or actor.active_model_source != "warrior_r39":
		push_error("BLADE ALIGNMENT PROBE FAIL: wrong model")
		quit(1)
		return
	var socket: BoneAttachment3D = actor.equipment_sockets.get_socket("weapon")
	if socket == null:
		push_error("BLADE ALIGNMENT PROBE FAIL: missing socket")
		quit(1)
		return
	var target: Node3D = lab.targets[0]
	target.global_position = actor.global_position + Vector3(0,0,-1.35)
	var center := target.global_position + Vector3.UP * 1.2
	var min_distance: Dictionary = {}
	var samples_by_axis: Dictionary = {}
	for label in DIRECTIONS:
		min_distance[label] = 999.0
		samples_by_axis[label] = []
	actor._attack("Slash", 0.72)
	var contact_samples := 0
	for i in range(55):
		await physics_frame
		var position: float = actor.animation.current_animation_position
		var duration: float = actor.animation.current_animation_length
		if duration <= 0.0:
			continue
		var phase := position / duration
		if not SWEEP.in_contact_window("Slash", phase):
			continue
		contact_samples += 1
		var hilt := socket.global_position
		for label in DIRECTIONS:
			var tip: Vector3 = socket.to_global(DIRECTIONS[label] * 0.85)
			var distance := sqrt(SWEEP.point_segment_distance_squared(center, hilt, tip))
			min_distance[label] = minf(float(min_distance[label]), distance)
			samples_by_axis[label].append({"hilt":hilt,"tip":tip})
	var report: Array = []
	for label in DIRECTIONS:
		report.append({"axis":label,
			"min_distance_m":snapped(float(min_distance[label]),0.001),
			"intersects_0_57m":SWEEP.swept_samples_touch_target(samples_by_axis[label],center,0.45,0.12)})
	report.sort_custom(func(a,b):return a["min_distance_m"] < b["min_distance_m"])
	print("AOTL R39 BLADE AXIS REPORT ", JSON.stringify(report))
	if contact_samples < 4:
		push_error("BLADE ALIGNMENT PROBE FAIL: insufficient real animation contact frames")
		quit(1)
		return
	print("AOTL R39 BLADE ALIGNMENT PROBE PASS; samples=",contact_samples)
	quit(0)
