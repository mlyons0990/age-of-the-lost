extends SceneTree
## Phase 0 Higgsfield pilot gate (handoff 2026-11-19 §2):
##  - the Meshy rigged knight imports;
##  - every 3d_rigging clip GLB carries the same skeleton, and its animation merges into one library;
##  - all clips play on the single rigged model (bones actually move);
##  - at the PoE-style camera (perspective, ~32° FOV, ~52° pitch) the knight is ~100 px tall at 1080p.
## Renders evidence frames with --shots=<dir>.
const DIR := "res://models/higgsfield_pilot/"
const MODEL := DIR + "knight_rig.glb"
const CLIPS := {"Roll_Dodge": DIR + "clip_roll_dodge.glb", "Left_Slash": DIR + "clip_left_slash.glb", "Dead": DIR + "clip_dead.glb"}
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

func skeleton_of(n: Node) -> Skeleton3D:
	var found := n.find_children("*", "Skeleton3D", true, false)
	return null if found.is_empty() else found[0] as Skeleton3D

func _run() -> void:
	check(ResourceLoader.exists(MODEL), "Pilot rigged knight GLB exists")
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	root.add_child(model)
	var sk := skeleton_of(model)
	check(sk != null and sk.get_bone_count() >= 20, "Rigged knight has a humanoid skeleton (%d bones)" % (sk.get_bone_count() if sk else 0))
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	check(not meshes.is_empty() and (meshes[0] as MeshInstance3D).skin != null, "Knight mesh is skinned")
	var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		ap = AnimationPlayer.new()
		model.add_child(ap)
	var lib := AnimationLibrary.new()
	for clip in CLIPS:
		check(ResourceLoader.exists(CLIPS[clip]), "Clip GLB exists: " + clip)
		var src: Node3D = (load(CLIPS[clip]) as PackedScene).instantiate()
		var ssk := skeleton_of(src)
		var same := ssk != null and ssk.get_bone_count() == sk.get_bone_count()
		if same:
			for b in sk.get_bone_count():
				if sk.get_bone_name(b) != ssk.get_bone_name(b):
					same = false
		check(same, clip + ": same skeleton as the rigged knight")
		var sap: AnimationPlayer = src.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var names: PackedStringArray = sap.get_animation_list() if sap else PackedStringArray()
		check(names.size() >= 1, clip + ": carries an animation (%s)" % ", ".join(names))
		if names.size() >= 1:
			var anim: Animation = sap.get_animation(names[names.size() - 1]).duplicate(true)
			# retarget track paths from the clip scene to the model scene (same rig: map by skeleton path)
			var from := String(src.get_path_to(ssk)) if ssk else ""
			var to := String(model.get_path_to(sk))
			var ap_root: Node = ap.get_node(ap.root_node) if ap.root_node != NodePath("") else ap.get_parent()
			to = String(ap_root.get_path_to(sk))
			var sap_root: Node = sap.get_node(sap.root_node) if sap.root_node != NodePath("") else sap.get_parent()
			from = String(sap_root.get_path_to(ssk))
			for t in anim.get_track_count():
				var p := String(anim.track_get_path(t))
				if p.begins_with(from):
					anim.track_set_path(t, NodePath(to + p.substr(from.length())))
			lib.add_animation(clip, anim)
		src.free()
	ap.add_animation_library("pilot", lib)
	# play each clip on the one model and measure bone motion
	for clip in CLIPS:
		if not lib.has_animation(clip):
			continue
		var anim := lib.get_animation(clip)
		ap.play("pilot/" + clip)
		ap.seek(0.0, true)
		var p0: Array = []
		for b in sk.get_bone_count():
			p0.append(sk.get_bone_global_pose(b).origin)
		ap.seek(anim.length * 0.5, true)
		var moved := 0.0
		for b in sk.get_bone_count():
			moved = maxf(moved, (sk.get_bone_global_pose(b).origin as Vector3).distance_to(p0[b]))
		print("PILOT %s: length %.2fs, max bone travel to mid-clip %.3f m" % [clip, anim.length, moved])
		check(anim.length > 0.3 and moved > 0.05, clip + " plays on the single rigged knight")
	# PoE camera: perspective, 32° vertical FOV, 52° pitch; distance chosen for ~27 m of visible ground
	root.size = Vector2i(1920, 1080)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.6, 0.55)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.62)
	env.environment = e
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	root.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 32.0
	root.add_child(cam)
	var pitch := deg_to_rad(52.0)
	var dist := 27.0 * 0.5 / tan(deg_to_rad(16.0)) * sin(pitch)   # ~27 m ground span vertically
	cam.look_at_from_position(Vector3(0, sin(pitch) * dist, cos(pitch) * dist), Vector3(0, 0.9, 0))
	cam.current = true
	ap.play("pilot/Left_Slash")
	ap.seek(0.0, true)
	ap.pause()
	await process_frame
	await process_frame
	# on-screen height from the skeleton's head/foot bones
	var top := 1e9
	var bottom := -1e9
	for b in sk.get_bone_count():
		var wp: Vector3 = sk.global_transform * sk.get_bone_global_pose(b).origin
		var sp := cam.unproject_position(wp)
		top = minf(top, sp.y)
		bottom = maxf(bottom, sp.y)
	var px := (bottom - top) * 1.12   # bones stop short of the crown and soles
	print("PILOT on-screen height ~%.0f px at 1080p (camera distance %.1f m)" % [px, dist])
	check(px > 70.0 and px < 140.0, "Knight is roughly 100 px tall at the PoE camera (%.0f px)" % px)
	if shots != "":
		DirAccess.make_dir_recursive_absolute(shots)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(shots + "/pilot_game_camera.png")
		# close camera sheets for each clip
		cam.fov = 35.0
		cam.look_at_from_position(Vector3(2.2, 2.0, 3.6), Vector3(0, 0.9, 0))
		root.size = Vector2i(720, 720)
		for clip in CLIPS:
			if not lib.has_animation(clip):
				continue
			var L := lib.get_animation(clip).length
			for k in 6:
				ap.play("pilot/" + clip)
				ap.seek(L * k / 5.0, true)
				ap.pause()
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("%s/pilot_%s_%d.png" % [shots, clip, k])
	print("AOTL HIGGSFIELD PILOT RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
