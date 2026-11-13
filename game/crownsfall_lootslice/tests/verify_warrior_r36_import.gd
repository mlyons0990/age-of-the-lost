extends SceneTree
## Required model import gate (not the optional fallback test).
## godot --headless --path game/crownsfall_lootslice --script res://tests/verify_warrior_r36_import.gd

const R36 := "res://models/AOTL_Warrior_R36.glb"
const REQUIRED_BONES = [
	"Root", "Hips", "ThighL", "KneeL", "ShinL", "AnkleL", "FootL",
	"ThighR", "KneeR", "ShinR", "AnkleR", "FootR"
]
const REQUIRED_CLIPS = ["Idle", "Walk", "Run", "Dodge", "Slash"]

func _initialize() -> void:
	if not ResourceLoader.exists(R36):
		push_error("Missing R36 GLB: copy the exact exported model to " + R36)
		quit(1)
		return
	var packed := ResourceLoader.load(R36, "PackedScene") as PackedScene
	if packed == null:
		push_error("R36 GLB could not be imported as a PackedScene")
		quit(1)
		return
	var model := packed.instantiate()
	var rigs := model.find_children("*", "Skeleton3D", true, false)
	if rigs.is_empty():
		push_error("No imported Skeleton3D in R36")
		model.free()
		quit(1)
		return
	var skeleton := rigs[0] as Skeleton3D
	var missing: Array[String] = []
	for bone in REQUIRED_BONES:
		if skeleton.find_bone(bone) < 0:
			missing.append(bone)
	var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var clips: Array[String] = []
	if player != null:
		for item in player.get_animation_list():
			var raw := String(item).get_file()
			clips.append(raw.get_slice("|", raw.get_slice_count("|") - 1))
	var missing_clips: Array[String] = []
	for clip in REQUIRED_CLIPS:
		if not clips.has(clip):
			missing_clips.append(clip)
	print("R36 import audit: bones=", skeleton.get_bone_count(), " clips=", clips)
	print("Missing bones=", missing, " missing clips=", missing_clips)
	model.free()
	if missing.is_empty() and missing_clips.is_empty():
		print("AOTL R36 skeleton import gate PASSED")
		quit(0)
	else:
		push_error("AOTL R36 skeleton import gate FAILED")
		quit(1)
