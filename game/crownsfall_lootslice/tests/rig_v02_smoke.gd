extends SceneTree
## Isolated native Godot verification of Higgsfield Master Humanoid V02.
var checks := 0
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)
func frames(count := 4) -> void:
	for i in count:
		await process_frame
func finish() -> void:
	print("RIG_V02_TEST_%s: %d checks; %d failures" % ["OK" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)
func _run() -> void:
	check(OS.get_cmdline_user_args().has("--aotl-rig-v02"), "V02 mode flag passed")
	check(ResourceLoader.exists("res://models/AOTL_Humanoid_Master_V02.glb"), "decoded and imported GLB exists")
	change_scene_to_file("res://scenes/rig_lab_3d.tscn")
	await frames(10)
	var lab: Node3D = current_scene as Node3D
	check(lab != null, "Lab scene enters")
	if lab == null:
		finish()
		return
	check(lab.rig_v02_enabled, "Lab selects V02 controller")
	var hero: CharacterBody3D = lab.player
	check(hero != null, "V02 player instantiated")
	if hero == null:
		finish()
		return
	check(hero.body != null and hero.body.name == "AOTL_Humanoid_Master_V02", "V02 model instead of legacy proxy")
	check(hero.master_skeleton != null and hero.master_skeleton.get_bone_count() == 58, "58-joint GLB skeleton")
	check(hero.split_clip_count == 16, "One export reel split into sixteen named clips")
	check(hero.clip_names.size() == 16, "16 action keys accessible by controller")
	var expected := ["Idle", "Walk", "Run", "Slash", "Dodge", "Cast", "HeavySlash", "Thrust", "HitReact", "CastRelease", "ShieldBlock", "Cleave", "DashStrike", "Jump", "Death", "Parry"]
	for name in expected:
		var exists: bool = hero.clip_names.has(name) and hero.animation.has_animation(hero.clip_names[name])
		check(exists, "Resolved " + name)
		if exists:
			var clip: Animation = hero.animation.get_animation(hero.clip_names[name])
			check(clip.get_track_count() >= 100, "Clip has reconstructed bone tracks: " + name)
			check(clip.track_get_key_count(0) >= 2, "Clip has endpoint keys: " + name)
	check(hero.equipment_sockets.size() == 7, "Seven runtime BoneAttachment sockets")
	for slot in ["weapon", "shield", "vfx_right", "vfx_left", "back", "head", "waist"]:
		check(hero.equipment_sockets.has(slot), "Mounted " + slot)
	check(hero.movement_tree != null and hero.movement_tree.active, "Locomotion AnimationTree activated")
	check(hero.rig_release_ready, "Rig self-report ready for runtime smoke (not art approval)")
	if hero.movement_tree != null:
		hero.movement_tree.active = false
	hero.set_physics_process(false)
	hero.animation.play(hero.clip_names["Walk"], 0)
	hero.animation.advance(0.08)
	var poses: Array[Transform3D] = []
	for b in hero.master_skeleton.get_bone_count():
		poses.append(hero.master_skeleton.get_bone_pose(b))
	hero.animation.advance(0.24)
	var changes := 0
	for b in poses.size():
		if not poses[b].is_equal_approx(hero.master_skeleton.get_bone_pose(b)):
			changes += 1
	check(changes > 0, "Walk changes evaluated bone poses")
	var demo := MeshInstance3D.new()
	demo.mesh = BoxMesh.new()
	check(hero.set_equipment_visual("weapon", demo), "Runtime weapon attachment accepted")
	check(demo.get_parent() == hero.equipment_sockets["weapon"], "Weapon parented under animated hand socket")
	check(hero.clear_equipment_visual("weapon"), "Weapon visual reset safely")
	var rejected_visual := MeshInstance3D.new()
	check(not hero.set_equipment_visual("invalid_slot", rejected_visual), "Unknown slot rejected")
	rejected_visual.free()
	hero.animation.play(hero.clip_names["ShieldBlock"], 0)
	hero.animation.advance(0.2)
	check(hero.animation.is_playing(), "ShieldBlock runs as actual imported bone animation")
	hero.animation.play(hero.clip_names["Death"], 0)
	hero.animation.advance(0.3)
	check(hero.animation.is_playing(), "Death clip runs in Godot")
	await frames(4) # Allow queued demo weapon to be released before quitting.
	finish()
