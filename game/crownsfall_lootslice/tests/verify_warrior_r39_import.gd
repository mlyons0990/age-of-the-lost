extends SceneTree
## Production acceptance: real R39 GLB import, six action clips, skinned geometry.
## godot --headless --path game/crownsfall_lootslice --script res://tests/verify_warrior_r39_import.gd

const MODEL_PATH := "res://models/AOTL_Warrior_R39_Gameplay6.glb"
const CORE = ["Idle", "Walk", "Run", "Dodge", "Slash", "Cast"]
const REQUIRED_BONES = [
	"Root", "Hips", "ThighL", "KneeL", "ShinL", "AnkleL", "FootL",
	"ThighR", "KneeR", "ShinR", "AnkleR", "FootR"
]

func _initialize() -> void:
	call_deferred("_run_import_gate")

func _fail(message: String) -> void:
	push_error("R39 GAMEPLAY6 IMPORT FAILED: " + message)
	quit(1)

func _run_import_gate() -> void:
	if not ResourceLoader.exists(MODEL_PATH):
		_fail("GLB asset is missing: " + MODEL_PATH)
		return
	var packed := ResourceLoader.load(MODEL_PATH, "PackedScene") as PackedScene
	if packed == null:
		_fail("GLB failed PackedScene import")
		return
	var model := packed.instantiate() as Node3D
	if model == null:
		_fail("Imported GLB did not instantiate as a Node3D")
		return
	root.add_child(model)
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		_fail("Imported scene has no Skeleton3D")
		return
	var skeleton := skeletons[0] as Skeleton3D
	if skeleton == null or skeleton.get_bone_count() < 58:
		_fail("Imported skeleton has fewer than 58 bones")
		return
	for required in REQUIRED_BONES:
		if skeleton.find_bone(required) < 0:
			_fail("Missing bone: " + required)
			return
	var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player == null:
		_fail("No AnimationPlayer imported")
		return
	var clips: Array[String] = []
	for item in player.get_animation_list():
		var logical := String(item).get_file()
		clips.append(logical.get_slice("|", logical.get_slice_count("|") - 1))
	for core in CORE:
		if not clips.has(core):
			_fail("Missing independent animation: " + core + " from " + str(clips))
			return
	var skinned_meshes := 0
	for item in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := item as MeshInstance3D
		if mesh_instance != null and mesh_instance.skin != null:
			skinned_meshes += 1
	if skinned_meshes < 75:
		_fail("Insufficient skinned meshes: " + str(skinned_meshes))
		return
	for core in CORE:
		var animation: Animation = player.get_animation(core)
		if animation == null or animation.length < 0.4:
			_fail("Animation missing or too short: " + core)
			return
		player.play(core)
		player.seek(animation.length * 0.5, true)
	print("AOTL Warrior R39 Gameplay6 IMPORT PASS — bones: ",
		skeleton.get_bone_count(), ", skinned meshes: ", skinned_meshes,
		", clips: ", clips)
	model.queue_free()
	quit(0)
