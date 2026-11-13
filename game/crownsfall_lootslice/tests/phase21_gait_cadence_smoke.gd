extends SceneTree
## Headless opt-in gait-control regression. Run only in rig-lab test project.
## Synthetic key events take one rendered frame to update Input.is_key_pressed().
const HERO := preload("res://scripts/three_d/rig_controller.gd")
var assertions := 0

func inject_key(code: Key, held: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = held
	Input.parse_input_event(e)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var hero := HERO.new()
	root.add_child(hero)
	await process_frame
	assert(hero.animation != null)
	assertions += 1
	assert(not hero.stride_rate_mode)
	assertions += 1
	hero.adjust_stride_rate(1.2)
	inject_key(KEY_W, true)
	await process_frame
	await physics_frame
	await physics_frame
	assert(hero.anim_state == "Walk")
	assertions += 1
	assert(is_equal_approx(hero.animation.speed_scale, hero.stride_rate))
	assertions += 1
	inject_key(KEY_SHIFT, true)
	await process_frame
	await physics_frame
	await physics_frame
	assert(hero.anim_state == "Run")
	assertions += 1
	assert(is_equal_approx(hero.animation.speed_scale, hero.stride_rate))
	assertions += 1
	inject_key(KEY_SHIFT, false)
	inject_key(KEY_W, false)
	await process_frame
	await physics_frame
	await physics_frame
	assert(hero.anim_state == "Idle")
	assertions += 1
	assert(is_equal_approx(hero.animation.speed_scale, 1.0))
	assertions += 1
	hero._attack("Cast", 1.4)
	await physics_frame
	await physics_frame
	assert(hero.anim_state == "Cast")
	assertions += 1
	assert(is_equal_approx(hero.animation.speed_scale, 1.0))
	assertions += 1
	hero.attack_t = 0.0
	hero.anim_state = ""
	hero._dodge()
	await physics_frame
	await physics_frame
	assert(hero.anim_state == "Dodge")
	assertions += 1
	assert(is_equal_approx(hero.animation.speed_scale, 1.0))
	assertions += 1
	hero.reset_stride_rate()
	assert(not hero.stride_rate_mode and is_equal_approx(hero.stride_rate, 1.0))
	assertions += 1
	assert(is_equal_approx(hero.animation.speed_scale, 1.0))
	assertions += 1
	hero.queue_free()
	await process_frame
	print("PHASE21_GAIT_CADENCE ", assertions, "/14")
	quit(0)