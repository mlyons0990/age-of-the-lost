extends SceneTree
## Renders any GLB from the front, left, back and right (no animation, rest pose), for model QA.
##   godot --path . -s tests/capture_glb_views.gd -- --glb=res://models/x.glb --out=/tmp/dir --name=x
var out := "/tmp"
var glb := ""
var nm := "model"
var anim := ""
var at := 0.0
var views := "front,left,back,right"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		if a.begins_with("--glb="): glb = a.substr(6)
		if a.begins_with("--name="): nm = a.substr(7)
		if a.begins_with("--anim="): anim = a.substr(7)
		if a.begins_with("--t="): at = float(a.substr(4))
		if a.begins_with("--views="): views = a.substr(8)
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(700, 900)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.5, 0.52, 0.5)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.82)
	var we := WorldEnvironment.new(); we.environment = e; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 25, 0); root.add_child(sun)
	var m: Node3D = (load(glb) as PackedScene).instantiate()
	root.add_child(m)
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	if ap:
		ap.stop()
		if anim != "":
			ap.play(anim); ap.seek(at, true); ap.pause()
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = 2.0
	var all := {"front": Vector3(0, 0.9, 4), "left": Vector3(4, 0.9, 0), "back": Vector3(0, 0.9, -4), "right": Vector3(-4, 0.9, 0), "three": Vector3(2.6, 1.6, 3.0)}
	for k in views.split(","):
		var v := [k, all[k]]
		cam.look_at_from_position(v[1], Vector3(0, 0.9, 0))
		await process_frame; await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%s_%s%s.png" % [out, nm, v[0], ("_" + anim) if anim != "" else ""])
	quit(0)
