extends SceneTree
## Hand-speed profile of an animation clip (for choosing a weapon move's trim window and contact phase):
##   godot --headless --path . -s tools/measure_clip.gd -- --glb=res://models/x.glb --clip=Name [--step=0.05]
## Prints time, right-hand and left-hand speed (m/s) and hand height per step; peaks are where a swing lands.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var glb := ""; var clip := ""; var step := 0.05
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--glb="): glb = a.substr(6)
		if a.begins_with("--clip="): clip = a.substr(7)
		if a.begins_with("--step="): step = float(a.substr(7))
	var m: Node3D = (load(glb) as PackedScene).instantiate()
	root.add_child(m)
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	var sk: Skeleton3D = m.find_children("*", "Skeleton3D", true, false)[0]
	if clip == "":
		for n in ap.get_animation_list():
			if n != "RESET": clip = n; break
	var anim := ap.get_animation(clip)
	print("clip ", clip, " length %.2f s" % anim.length)
	ap.play(clip)
	var prev := {}
	var t := 0.0
	while t <= anim.length + 0.0001:
		ap.seek(t, true)
		await process_frame
		var line := "t=%.2f" % t
		for b in ["RightHand", "LeftHand"]:
			var p: Vector3 = (sk.global_transform * sk.get_bone_global_pose(sk.find_bone(b))).origin
			var v := 0.0
			if prev.has(b): v = (p - prev[b]).length() / step
			prev[b] = p
			line += "  %s %.2f m/s (y %.2f)" % [b.left(1), v, p.y]
		print(line)
		t += step
	quit(0)
