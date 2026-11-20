extends SceneTree
## Launch the actual editor-openable Godot R53 combat lab scene.
const SCENE := "res://scenes/r53_arm_skin_combat_lab.tscn"
var checks := 0
var failures := 0

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + reason)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	check(ResourceLoader.exists(SCENE), "Standalone R53 combat scene is packaged")
	var scene: PackedScene = ResourceLoader.load(SCENE) as PackedScene
	check(scene != null, "R53 scene can be opened in Godot editor")
	if scene == null:
		quit(1)
		return
	var lab: Node3D = scene.instantiate()
	check(lab.use_r53_arm_skin_candidate, "R53 combat scene opts into R53 arm skin")
	check(not lab.strict_weapon_sweep, "Physical sword QA mode is not silently forced on")
	root.add_child(lab)
	await physics_frame
	await physics_frame
	check(lab.player != null, "Scene constructed playable CharacterBody3D")
	check(lab.player.active_model_source == "warrior_r53_opt_in", "Live actor uses R53 rigid armor model")
	check(lab.player.equipment_sockets_available and lab.player.terrain_ik_available, "Equipment and terrain IK active")
	check(lab.camera != null and lab.camera.current, "Playable isometric camera active")
	check(lab.targets.size() == 4, "Scene preserves four training enemies")
	check(lab.player.clip_names["Slash"] == lab.player.clip_names["Slash_FullBody_R50"], "Actual animation uses grounded Slash")
	print("AOTL R53 PLAYABLE SCENE RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
