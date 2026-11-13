extends SceneTree
## Runs independently of production saves, items, inventory and Crownsfall scenes.
const REVIEW := preload("res://scripts/three_d/phase19_animation_review.gd")
const METRICS := preload("res://scripts/three_d/phase20_motion_metrics.gd")
const REQUIRED := ["Idle", "Walk", "Run", "Slash", "Dodge", "Cast"]
var checks := 0

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var points: Array[Vector3] = [Vector3(0, 0.03, 0), Vector3(0.1, 0.02, 0), Vector3(0.2, 0.18, 0)]
	var sample: Dictionary = METRICS.summarize_path(points, 0.1)
	assert(sample["samples"] == 3)
	checks += 1
	assert(is_equal_approx(sample["vertical_range_m"], 0.16))
	checks += 1
	assert(is_equal_approx(sample["horizontal_path_m"], 0.2))
	checks += 1
	assert(sample["near_lowest_samples"] == 2)
	checks += 1
	var app := REVIEW.new()
	root.add_child(app)
	await process_frame
	assert(app.status_label != null and app.audit_label != null)
	checks += 1
	if app.model != null:
		assert(app.armature.get_bone_count() >= 58)
		checks += 1
		for clip in REQUIRED:
			app.play_clip(clip)
			var result: Dictionary = app.run_motion_audit(clip)
			assert(result.get("ok", false))
			checks += 1
			assert(result["left"]["samples"] == 29 and result["right"]["samples"] == 29)
			checks += 1
			assert(result["left"]["horizontal_path_m"] >= 0.0 and result["right"]["horizontal_path_m"] >= 0.0)
			checks += 1
			assert(app.active_clip == clip)
			checks += 1
		assert(app.markers.size() == 2)
		checks += 1
		app.show_foot_markers = false
		app._process(0.016)
		assert(not app.markers[0].visible and not app.markers[1].visible)
		checks += 1
	else:
		assert(not app.run_motion_audit().get("ok", true))
		checks += 1
		assert(app.markers.size() == 0)
		checks += 1
	app.queue_free()
	await process_frame
	print("PHASE20 MOTION AUDIT: %d checks passed" % checks)
	quit(0)