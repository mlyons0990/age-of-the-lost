extends SceneTree
## Phase 1 Mage acceptance (Godot 4.6.3): the Meshy multi-view Mage with the knight's shared clips, staff and tome.
## Model checks + live rig-lab checks. --shots=<dir> renders evidence frames.
const MODEL := "res://models/higgsfield_mage/mage_pilot_armed.glb"
const LAB := preload("res://scripts/three_d/rig_lab.gd")
const CLIPS := ["Idle", "Walk", "Run", "RunFast", "Casual_Walk", "Cast", "Roll_Dodge", "Dead"]
var checks := 0
var failures := 0
var shots := ""

func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + why)

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			shots = a.substr(8)
	call_deferred("_run")

func world(sk: Skeleton3D, bone: String) -> Vector3:
	return sk.global_transform * sk.get_bone_global_pose(sk.find_bone(bone)).origin

## Centre of a prop rigidly skinned to `bone`, in world space.
func prop_point(mi: MeshInstance3D, sk: Skeleton3D, bone: String, local: Vector3) -> Vector3:
	for i in mi.skin.get_bind_count():
		var b := mi.skin.get_bind_bone(i)
		var n := sk.get_bone_name(b) if b >= 0 else String(mi.skin.get_bind_name(i))
		if n == bone:
			return sk.global_transform * (sk.get_bone_global_pose(sk.find_bone(bone)) * mi.skin.get_bind_pose(i) * local)
	return Vector3.INF

func _run() -> void:
	check(ResourceLoader.exists(MODEL), "Mage GLB exists")
	if not ResourceLoader.exists(MODEL):
		quit(1)
		return
	var m: Node3D = (load(MODEL) as PackedScene).instantiate()
	root.add_child(m)
	var sk: Skeleton3D = m.find_children("*", "Skeleton3D", true, false)[0]
	check(sk.get_bone_count() == 24, "Meshy 24-bone rig (%d)" % sk.get_bone_count())
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	for c in CLIPS:
		check(ap.has_animation(c), "Clip present: " + c)
	var staff: MeshInstance3D = m.find_child("MAGE_Staff*", true, false) as MeshInstance3D
	var tome: MeshInstance3D = m.find_child("MAGE_Tome*", true, false) as MeshInstance3D
	check(staff != null and tome != null, "Staff and tome attached")
	for c in CLIPS:
		if not ap.has_animation(c):
			continue
		var L: float = ap.get_animation(c).length
		var toe_min := 9.0
		var hips_min := 9.0
		var staff_drift := 0.0
		var up_min := 1.0
		var hd0 := -1.0
		for k in 25:
			ap.play(c, 0); ap.seek(L * k / 24.0, true)
			for f in ["LeftToeBase", "RightToeBase"]:
				toe_min = minf(toe_min, world(sk, f).y)
			hips_min = minf(hips_min, world(sk, "Hips").y)
			if staff != null:
				var aabb := staff.mesh.get_aabb()
				# glTF is Y-up: the shaft runs along the mesh's Y axis (foot -> crystal)
				var lo := prop_point(staff, sk, "RightHand", Vector3(aabb.get_center().x, aabb.position.y, aabb.get_center().z))
				var hi := prop_point(staff, sk, "RightHand", Vector3(aabb.get_center().x, aabb.end.y, aabb.get_center().z))
				var d := world(sk, "RightHand").distance_to(lo)
				if hd0 < 0.0: hd0 = d
				staff_drift = maxf(staff_drift, absf(d - hd0))
				if c in ["Idle", "Walk", "Casual_Walk"]:
					up_min = minf(up_min, (hi - lo).normalized().dot(Vector3.UP))
		print("MAGE %s: %.2fs toes >= %.3f m, hips >= %.2f m, staff grip drift %.4f m, staff uprightness %.2f" % [c, L, toe_min, hips_min, staff_drift, up_min])
		check(toe_min > -0.06, c + ": feet never below the floor")
		check(staff_drift < 0.005, c + ": staff rigid in the right hand")
		if c in ["Idle", "Casual_Walk"]:
			check(up_min > 0.5, c + ": staff carried roughly upright (%.2f)" % up_min)
		if c == "Roll_Dodge":
			check(hips_min < 0.7, "Roll_Dodge tucks low (hips %.2f m)" % hips_min)
		if c == "Dead":
			ap.play(c, 0); ap.seek(L, true)
			check(world(sk, "Hips").y < 0.4, "Dead ends lying down (hips %.2f m)" % world(sk, "Hips").y)
	m.queue_free()
	await process_frame
	# live lab
	root.size = Vector2i(1920, 1080)
	var lab = LAB.new(); lab.use_pilot_mage_candidate = true
	root.add_child(lab)
	await physics_frame; await physics_frame
	var a = lab.player
	check(a.active_model_source == "pilot_mage_opt_in", "Rig lab selected the Mage (%s)" % a.active_model_source)
	var lsk: Skeleton3D = a.body.find_children("*", "Skeleton3D", true, false)[0]
	var hf := world(lsk, "headfront") - world(lsk, "Head")
	check(hf.normalized().dot(a.last_face) > 0.9, "Mage faces the controller direction")
	check(a.terrain_ik_available, "Foot IK runs on the Mage")
	for clip in ["Walk", "Run", "Stroll"]:
		a.anim_state = ""
		a._play(clip)
		var sp: float = a.animation.get_playing_speed()
		var tgt: float = {"Walk": a.WALK_SPEED, "Run": a.RUN_SPEED, "Stroll": a.PILOT_STROLL_SPEED}[clip]
		check(absf(float(a.PILOT_STRIDE_SPEED[clip]) * sp - tgt) / tgt < 0.1, "%s: feet match body speed" % clip)
	a.anim_state = ""
	var dummy = lab.targets[0]
	dummy.global_position = a.global_position + a.last_face * 2.0
	dummy.hp = 100.0
	await physics_frame
	a._attack("Cast", 1.4)
	await root.get_tree().create_timer(1.6).timeout
	print("MAGE LAB cast: dummy hp %.0f" % dummy.hp)
	check(dummy.hp < 100.0, "Cast hits the training dummy")
	if shots != "":
		DirAccess.make_dir_recursive_absolute(shots)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(shots + "/mage_lab_1080p.png")
	print("AOTL PILOT MAGE RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
