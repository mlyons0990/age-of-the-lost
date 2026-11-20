extends SceneTree
## Renders the four paid Mage cast clips (armed) at six phases each, 3/4 front view.
var out := "/tmp"
const CLIPS := ["Cast_Sweep", "Cast_Bolt", "Cast_Lunge", "Cast_Nova"]
const PHASES := [0.0, 0.18, 0.30, 0.40, 0.68, 0.85]
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(420, 520)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.80, 0.80, 0.82)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.74)
	var we := WorldEnvironment.new(); we.environment = e; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 30, 0); root.add_child(sun)
	var floor := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(8, 8); floor.mesh = pm; root.add_child(floor)
	var m: Node3D = (load("res://models/higgsfield_mage/mage_pilot_armed.glb") as PackedScene).instantiate()
	root.add_child(m)
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 38
	cam.look_at_from_position(Vector3(2.2, 1.7, 3.6), Vector3(0, 0.95, 0.3))
	for c in CLIPS:
		var name := ""
		for n in ap.get_animation_list():
			if String(n).ends_with(c): name = n
		print("CLIP %s -> %s len %.2f" % [c, name, ap.get_animation(name).length])
		ap.play(name); ap.pause()
		for i in PHASES.size():
			ap.seek(ap.get_animation(name).length * PHASES[i], true)
			await process_frame; await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s_%d.png" % [out, c, i])
	quit(0)
