extends SceneTree
## Master GLB optional integration: do not change world saves or production actor.
const VIEWER := preload("res://scripts/three_d/phase19_animation_review.gd")
var passed := 0
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var scene := VIEWER.new()
	root.add_child(scene)
	await process_frame
	assert(scene.stride_label != null)
	passed += 1
	if scene.model != null:
		assert(scene.animator != null)
		passed += 1
		for clip in ["Walk", "Run"]:
			var result: Dictionary = scene.run_stride_fit(clip)
			assert(result.get("ok", false))
			passed += 1
			assert(result["stance_candidates"] >= 3)
			passed += 1
			assert(result["estimated_speed_mps"] > 0.2)
			passed += 1
			assert(result["forward_alignment"] > 0.0)
			passed += 1
			assert(result["ambiguous_contact"])
			passed += 1
		assert(scene.stride_label.text.contains("Stride fit"))
		passed += 1
	else:
		assert(not scene.run_stride_fit().get("ok", true))
		passed += 1
		scene._refresh_status()
		assert(scene.stride_label.text.contains("optional") or scene.stride_label.text.contains("F9"))
		passed += 1
	scene.queue_free()
	await process_frame
	print("PHASE21_MASTER_FIT_SMOKE ", passed, " checks")
	quit(0)