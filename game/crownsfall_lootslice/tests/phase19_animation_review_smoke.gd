extends SceneTree
const REVIEW := preload("res://scripts/three_d/phase19_animation_review.gd")
const MASTER := "res://models/AOTL_Master_Rig_R38_AllSix.glb"
var checks := 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var app: Node3D = REVIEW.new()
	root.add_child(app)
	await process_frame
	assert(app.REQUIRED.size() == 6)
	checks += 1
	assert(app.status_label != null)
	checks += 1
	assert(app.get_child_count() >= 3)
	checks += 1
	if ResourceLoader.exists(MASTER):
		assert(app.animator != null and app.armature != null)
		checks += 1
		assert(app.armature.get_bone_count() >= 58)
		checks += 1
		for clip in app.REQUIRED:
			assert(app._find_animation(clip) != "")
			app.play_clip(clip)
			assert(app.active_clip == clip)
			checks += 2
	else:
		assert(app.model == null)
		checks += 1
		assert(app.status_label.text.contains("Optional model missing"))
		checks += 1
	app.queue_free()
	await process_frame
	print("PHASE19 REVIEW SMOKE: %d checks passed" % checks)
	quit(0)
