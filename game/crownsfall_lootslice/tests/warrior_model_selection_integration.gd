extends SceneTree
## Structural acceptance test for the R36 model gate without requiring the R36 binary.
## Run: godot --headless --path game/crownsfall_lootslice --script res://tests/warrior_model_selection_integration.gd
const CONTROLLER := preload("res://scripts/three_d/rig_controller.gd")

const REQUIRED_BONES = [
	"Root", "Hips", "ThighL", "KneeL", "ShinL", "AnkleL",
	"ThighR", "KneeR", "ShinR", "AnkleR"
]
const REQUIRED_ANIMATIONS = ["Idle", "Walk", "Run", "Dodge", "Slash", "Cast"]

func _mock_model(missing_bone: String = "", missing_clip: String = "") -> Node3D:
	var candidate := Node3D.new()
	var sk := Skeleton3D.new()
	sk.name = "TestSkeleton"
	candidate.add_child(sk)
	for bone_name in REQUIRED_BONES:
		if bone_name != missing_bone:
			sk.add_bone(bone_name)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	candidate.add_child(player)
	var lib := AnimationLibrary.new()
	for clip in REQUIRED_ANIMATIONS:
		if clip != missing_clip:
			var anim := Animation.new()
			anim.length = 1.0
			lib.add_animation(clip, anim)
	player.add_animation_library("", lib)
	return candidate

func _initialize() -> void:
	var controller := CONTROLLER.new()
	var complete := _mock_model()
	assert(controller._production_model_is_valid(complete))
	var missing_knee := _mock_model("ShinL")
	assert(not controller._production_model_is_valid(missing_knee))
	var missing_dodge := _mock_model("", "Dodge")
	assert(not controller._production_model_is_valid(missing_dodge))
	var empty := Node3D.new()
	assert(not controller._production_model_is_valid(empty))
	complete.free()
	missing_knee.free()
	missing_dodge.free()
	empty.free()
	controller.free()
	print("AOTL Warrior model-gate regressions passed: 4")
	quit(0)
