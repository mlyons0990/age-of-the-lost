extends SceneTree
## Required model import gate (not the optional fallback test).
## godot --headless --path game/crownsfall_lootslice --script res://tests/verify_warrior_r36_import.gd

const DEFAULT_MODEL := "res://models/AOTL_Warrior_R40.glb"
const REQUIRED_BONES = [
	"Root", "Hips", "ThighL", "KneeL", "ShinL", "AnkleL", "FootL",
	"ThighR", "KneeR", "ShinR", "AnkleR", "FootR"
]
const REQUIRED_CLIPS = ["Idle", "Walk", "Run", "Dodge", "Slash", "Cast"]

func _initialize() -> void:
	var selected := DEFAULT_MODEL
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--model="):
			var requested := arg.trim_prefix("--model=")
			if requested in ["AOTL_Warrior_R36.glb", "AOTL_Warrior_R37.glb", "AOTL_Warrior_R39.glb", "AOTL_Warrior_R40.glb"]:
				selected = "res://models/" + requested
			else:
				push_error("Invalid Warrior model name: " + requested)
				quit(1)
				return
	if not ResourceLoader.exists(selected):
		push_error("Missing Warrior GLB: copy the exact exported model to " + selected)
		quit(1)
		return
	var packed := ResourceLoader.load(selected, "PackedScene") as PackedScene
	if packed == null:
		push_error("Warrior GLB could not be imported as a PackedScene")
		quit(1)
		return
	var model := packed.instantiate()
	var rigs := model.find_children("*", "Skeleton3D", true, false)
	if rigs.is_empty():
		push_error("No imported Skeleton3D in Warrior GLB")
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
	print("Warrior ", selected, " import audit: bones=", skeleton.get_bone_count(), " clips=", clips)
	print("Missing bones=", missing, " missing clips=", missing_clips)
	model.free()
	if missing.is_empty() and missing_clips.is_empty():
		print("AOTL Warrior skeleton import gate PASSED")
		quit(0)
	else:
		push_error("AOTL Warrior skeleton import gate FAILED")
		quit(1)
