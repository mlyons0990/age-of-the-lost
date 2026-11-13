extends SceneTree
## Standalone runtime-controller integration gate; runs in a minimal Godot QA project.
## The R39 model, original proxy and three supporting scripts must be copied in.

const CONTROLLER := preload("res://scripts/three_d/rig_controller.gd")

func _initialize() -> void:
	call_deferred("_verify_controller")

func _fail(reason: String) -> void:
	push_error("AOTL R39 runtime controller FAIL: " + reason)
	quit(1)

func _verify_controller() -> void:
	var player = CONTROLLER.new()
	if player == null:
		_fail("controller did not instantiate")
		return
	root.add_child(player)
	if player.active_model_source != "warrior_r39":
		_fail("expected warrior_r39, selected " + player.active_model_source)
		return
	if player.animation == null:
		_fail("AnimationPlayer missing")
		return
	for action in ["Idle", "Walk", "Run", "Dodge", "Slash", "Cast"]:
		if not player.clip_names.has(action):
			_fail("playable action missing: " + action)
			return
	if not player.terrain_ik_available:
		_fail("runtime terrain-foot IK was not initialized")
		return
	if not player.equipment_sockets_available:
		_fail("weapon and offhand skeleton equipment sockets unavailable")
		return
	player._play("Walk")
	if player.anim_state != "Walk":
		_fail("Walk failed to play")
		return
	player._play("Run")
	if player.anim_state != "Run":
		_fail("Run failed to play")
		return
	player._toggle_terrain_ik()
	if player.terrain_ik_enabled:
		_fail("F9 terrain IK toggle failed")
		return
	player._toggle_terrain_ik()
	if not player.terrain_ik_enabled:
		_fail("F9 terrain IK re-enable failed")
		return
	print("AOTL R39 RUNTIME CONTROLLER PASS — model: ",
		player.active_model_source,
		", clips: ", player.clip_names.size(),
		", terrain IK: ", player.terrain_ik_available,
		", equipment sockets: ", player.equipment_sockets_available)
	quit(0)
