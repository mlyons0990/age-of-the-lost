extends SceneTree
## Free pilot route: the Meshy knight driven by our own Warrior clips, retargeted in Blender
## (tools/retarget_r55_to_meshy.py). Checks import, every clip plays on the one skinned knight,
## feet stay on the ground in Idle/Slash, the sword hand sweeps in Slash, and the Dodge travels low.
## --shots=<dir> renders 8 frames per clip from a 3/4 camera.
const MODEL := "res://models/higgsfield_pilot/knight_pilot_armed.glb"
const CLIPS := ["Idle", "Walk", "Run", "Slash", "Roll_Dodge", "Cast"]
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

## A rigidly skinned prop's location: its mesh centre, skinned by its single bone.
func blade_pos(mi: MeshInstance3D, sk: Skeleton3D) -> Vector3:
	var aabb := mi.mesh.get_aabb()
	var c := aabb.get_center()
	# all meshes share the knight's 24-joint skin: use the bind of the hand bone the prop is weighted to
	var hand := "LeftHand" if String(mi.name).begins_with("WEAPON") else "RightHand"
	for i in mi.skin.get_bind_count():
		var bone := mi.skin.get_bind_bone(i)
		var name := String(mi.skin.get_bind_name(i)) if bone < 0 else sk.get_bone_name(bone)
		if name == hand:
			var pose: Transform3D = sk.get_bone_global_pose(sk.find_bone(hand)) * mi.skin.get_bind_pose(i)
			return sk.global_transform * (pose * c)
	return Vector3.INF

func world(sk: Skeleton3D, bone: String) -> Vector3:
	return sk.global_transform * sk.get_bone_global_pose(sk.find_bone(bone)).origin

func _run() -> void:
	check(ResourceLoader.exists(MODEL), "Retargeted knight GLB exists")
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	root.add_child(model)
	var sk: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	check(sk.get_bone_count() == 24, "Meshy 24-bone skeleton intact (%d)" % sk.get_bone_count())
	var mi: MeshInstance3D = model.find_child("Mesh_0", true, false) as MeshInstance3D
	if mi == null:
		mi = model.find_children("*", "MeshInstance3D", true, false)[0]
	check(mi.skin != null, "Knight mesh skinned")
	var blade: MeshInstance3D = model.find_child("WEAPON_Blade*", true, false) as MeshInstance3D
	var shield: MeshInstance3D = model.find_child("SHIELD_Shell*", true, false) as MeshInstance3D
	check(blade != null and shield != null, "Sword and shield meshes present")
	var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	if blade != null and shield != null:
		ap.play("Slash", 0); ap.seek(0.0, true)
		var b0 := blade_pos(blade, sk)
		var hd0 := world(sk, "LeftHand").distance_to(b0)
		var path := 0.0
		var worst := 0.0
		var last := b0
		for k in range(1, 25):
			ap.seek(ap.get_animation("Slash").length * k / 24.0, true)
			var bp := blade_pos(blade, sk)
			path += bp.distance_to(last); last = bp
			worst = maxf(worst, absf(world(sk, "LeftHand").distance_to(bp) - hd0))
		print("ARMED sword: path %.2f m, hand-to-blade distance drift %.4f m (rigid grip)" % [path, worst])
		check(path > 1.0, "Sword travels with the Slash (%.2f m)" % path)
		check(worst < 0.005, "Sword stays rigidly in the sword hand (drift %.4f m)" % worst)
		check(world(sk, "RightHand").distance_to(blade_pos(shield, sk)) < 0.4, "Shield sits at the shield hand")
	var names := ap.get_animation_list()
	for c in CLIPS:
		check(names.has(c), "Clip present: " + c)
	for c in CLIPS:
		if not names.has(c):
			continue
		var L: float = ap.get_animation(c).length
		var travel := 0.0
		var foot_min := 9.0
		var foot_max := -9.0
		var hand_path := 0.0
		var hips_min := 9.0
		var p0 := {}
		var last_hand := Vector3.ZERO
		for k in 25:
			ap.play(c, 0); ap.seek(L * k / 24.0, true)
			for b in ["Head", "LeftHand", "RightHand", "LeftFoot", "RightFoot"]:
				var w := world(sk, b)
				if k == 0:
					p0[b] = w
				travel = maxf(travel, w.distance_to(p0[b]))
			for f in ["LeftToeBase", "RightToeBase"]:
				var y := world(sk, f).y
				foot_min = minf(foot_min, y); foot_max = maxf(foot_max, y)
			var h := world(sk, "LeftHand")
			if k > 0:
				hand_path += h.distance_to(last_hand)
			last_hand = h
			hips_min = minf(hips_min, world(sk, "Hips").y)
		print("RETARGET %s: %.2fs, max travel %.2f m, toes y %.3f..%.3f, sword-hand path %.2f m, lowest hips %.2f m" % [c, L, travel, foot_min, foot_max, hand_path, hips_min])
		check(travel > 0.03, c + " moves the knight")
		check(foot_min > -0.06, c + ": toes never sink below the floor (%.3f m)" % foot_min)
		if c in ["Idle", "Slash", "Cast"]:
			check(foot_min < 0.08, c + ": feet stay planted (lowest toe %.3f m)" % foot_min)
		if c == "Slash":
			check(hand_path > 0.8, "Slash: sword hand sweeps (%.2f m path)" % hand_path)
		if c == "Roll_Dodge":
			check(hips_min < 0.7, "Roll_Dodge: knight drops low into a ground roll (hips %.2f m)" % hips_min)
		if c == "Dodge":
			print("NOTE Dodge: source R52 Dodge is an in-place flip at fixed hip height (%.2f m); not a ground roll" % hips_min)
	if shots != "":
		DirAccess.make_dir_recursive_absolute(shots)
		root.size = Vector2i(640, 640)
		var e := Environment.new()
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(0.78, 0.78, 0.78)
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.75, 0.75, 0.78)
		var we := WorldEnvironment.new(); we.environment = e; root.add_child(we)
		var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 30, 0); root.add_child(sun)
		var floor_ := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(6, 6); floor_.mesh = pm; root.add_child(floor_)
		var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 34
		cam.look_at_from_position(Vector3(2.4, 2.0, 3.6), Vector3(0, 0.85, 0))
		for c in CLIPS:
			var L: float = ap.get_animation(c).length
			for k in 8:
				ap.play(c, 0); ap.seek(L * k / 7.0, true); ap.pause()
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("%s/%s_%d.png" % [shots, c, k])
	print("AOTL HIGGSFIELD PILOT ARMED KNIGHT RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
