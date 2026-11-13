extends SceneTree
const FIT := preload("res://scripts/three_d/phase21_stride_fit.gd")
var passed := 0
func _initialize() -> void:
	var pts: Array[Vector3] = [Vector3(0,0,0.4),Vector3(0,0,0.25),Vector3(0,0,0.1),Vector3(0,0,-0.05),Vector3(0,0,-0.2)]
	var path: Dictionary = {"points": pts, "min_y": 0.0}
	var fit: Dictionary = FIT.estimate_stride(path,path,0.4,Vector3.BACK)
	assert(fit["ok"])
	passed += 1
	assert(is_equal_approx(float(fit["estimated_speed_mps"]), 1.5))
	passed += 1
	assert(is_equal_approx(float(fit["estimated_distance_per_cycle_m"]), 0.6))
	passed += 1
	assert(fit["segments"] == 8 and fit["stance_candidates"] == 8)
	passed += 1
	assert(fit["forward_alignment"] > 0.99)
	passed += 1
	assert(fit["fit_residual_mps"] < 0.0001)
	passed += 1
	var backwards: Dictionary = FIT.estimate_stride(path,path,0.4,Vector3.FORWARD)
	assert(not backwards["ok"])
	passed += 1
	var stationary: Array[Vector3] = [Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
	assert(not FIT.estimate_stride({"points": stationary,"min_y": 0.0},{"points": stationary,"min_y":0.0},1.0)["ok"])
	passed += 1
	assert(not FIT.estimate_stride({}, {}, 0.8)["ok"])
	passed += 1
	var clip_report: Dictionary = {"ok":true,"clip":"Walk","duration_s":0.4,"left":path,"right":path,"samples":5}
	var result: Dictionary = FIT.analyze_report(clip_report,Vector3.BACK)
	assert(is_equal_approx(float(result["suggested_playback_multiplier"]),4.3/1.5))
	passed += 1
	assert(String(FIT.diagnostic_line(result)).contains("Stride fit"))
	passed += 1
	print("PHASE21_STRIDE_FIT_CHECKS ",passed,"/11")
	quit(0)