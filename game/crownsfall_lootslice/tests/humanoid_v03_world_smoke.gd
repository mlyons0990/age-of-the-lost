extends SceneTree
## Native Godot integration gate: same PoE-wide world, original sprite, Higgsfield mesh,
## legacy proxy, actual 58-joint action tracks, blend, sockets and floor-contact IK.
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	_run.call_deferred()
func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
	print(("PASS " if ok else "FAIL ") + "V03 " + label)
func frames(n: int) -> void:
	for i in n:
		await process_frame
func finish() -> void:
	print("AOTL_V03_TEST_%s: %d checks, %d failures" % ["OK" if failures.is_empty() else "FAIL", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
func _run() -> void:
	verify(OS.get_cmdline_user_args().has("--aotl-v03"), "opt-in flag supplied")
	var scene := load("res://scenes/two_point_five_d/aotl_25d_lab.tscn") as PackedScene
	verify(scene != null, "original Phase02 scene preserved")
	if scene == null:
		finish()
		return
	var lab = scene.instantiate()
	root.add_child(lab)
	await frames(8)
	verify(lab.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "camera is orthographic")
	verify(is_equal_approx(lab.camera.size, 21.0), "PoE-wide default camera 21.0")
	verify(lab.camera.global_position.distance_to(lab.player.global_position + Vector3(12.8,16.4,12.8)) < 0.2, "Phase02 wide-camera offset preserved")
	verify(lab.player.visual_mode == "painted", "original painted Warrior remains default")
	verify(lab.player.visual.texture != null, "original approved image still displayed")
	verify(lab.player.humanoid_v03_opt_in, "V03 feature enabled without changing main")
	verify(lab.player.humanoid_visual != null, "V03 node created")
	var v = lab.player.humanoid_visual
	if v == null:
		finish()
		return
	verify(v.ready_to_compare, "Higgsfield humanoid complete and ready for comparison")
	verify(v.skeleton != null and v.skeleton.get_bone_count() == 58, "58-joint skeleton imported")
	verify(v.clip_count == 16, "16 actual split action clips")
	var action_names := ["Idle","Walk","Run","Slash","Dodge","Cast","HeavySlash","Thrust","HitReact","CastRelease","ShieldBlock","Cleave","DashStrike","Jump","Death","Parry"]
	for name in action_names:
		verify(v.clips.has(name), "real clip " + name + " exists")
		if v.clips.has(name):
			var anim: Animation = v.animation.get_animation(v.clips[name])
			verify(anim != null and anim.get_track_count() >= 20, name + " has sampled bone tracks")
	verify(v.locomotion != null and v.locomotion.active, "Idle Walk Run AnimationTree blends")
	verify(v.equipment.size() == 7, "seven equipment sockets built")
	for slot in ["weapon","shield","spell_left","spell_right","back","helmet","belt"]:
		verify(v.equipment.has(slot), "socket " + slot)
	verify(v.foot_ik.size() == 2, "left/right real leg IK solvers created")
	for side in ["L","R"]:
		if v.foot_ik.has(side):
			verify(v.foot_ik[side] is SkeletonIK3D, side + " foot IK using native solver")
			verify(v.foot_ik[side].is_running(), side + " IK solver runs")
		else:
			verify(false, side + " IK available")
	lab.player.change_visual_mode()
	verify(lab.player.visual_mode == "humanoid", "V cycles original painted to new rig")
	verify(v.visible and not lab.player.visual.visible, "no painted sprite rendered on humanoid")
	lab.player.move_to_ground(lab.player.global_position + Vector3(0,0,-1.5))
	await frames(16)
	verify(v.current_clip in ["Walk", "Run", "Idle"], "humanoid animation receives actual movement state")
	verify(v.get_foot_contact_count() >= 1, "foot ray intersects world floor")
	var example := MeshInstance3D.new()
	example.mesh = BoxMesh.new()
	verify(v.attach_equipment("weapon", example), "weapon mesh mounted to the character")
	verify(example.get_parent() == v.equipment["weapon"], "weapon follows hand-bone socket")
	verify(not v.attach_equipment("unknown", null), "invalid item slot rejected")
	lab.player.change_visual_mode()
	verify(lab.player.visual_mode == "proxy", "V cycles new humanoid to original proxy")
	lab.player.change_visual_mode()
	verify(lab.player.visual_mode == "painted" and lab.player.visual.visible, "V restores original painted mode")
	lab._set_camera_zoom(999.0)
	verify(is_equal_approx(lab.camera_size_for_test(), 28.0), "far zoom clamps 28")
	lab._set_camera_zoom(1.0)
	verify(is_equal_approx(lab.camera_size_for_test(), 14.0), "near zoom clamps 14")
	lab._set_camera_zoom(21.0)
	verify(is_equal_approx(lab.camera_size_for_test(), 21.0), "Home-camera baseline restored")
	verify(lab.world_environment != null and lab.dummies.size() == 3, "Courtyard and opponents retained")
	lab.queue_free()
	await frames(5)
	finish()
