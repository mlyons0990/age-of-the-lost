extends SceneTree
## Kit proof (owner 11-22): the composed Whisperwood kit screen and the approved W1 painting at the same game camera,
## for a side-by-side. usage: --zone=<name> --at=u,v[;u,v...] --out=<dir>
var out := "/tmp"
var zone_name := "whisperwood_proof"
var spots: Array = []
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		if a.begins_with("--zone="): zone_name = a.substr(7)
		if a.begins_with("--at="):
			for s in a.substr(5).split(";"):
				var q := s.split(","); spots.append(Vector2(float(q[0]), float(q[1])))
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	lab.painted_zone = zone_name
	root.add_child(lab)
	for i in 10: await physics_frame
	lab.hud.visible = false
	var i := 0
	for at in spots:
		lab.player.global_position = lab.zone_px_to_world(at.x, at.y) + Vector3.UP * 0.05
		lab.zone_last_ok = lab.player.global_position
		lab.zone_cam_focus = Vector3.INF
		await create_timer(1.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%s_%d.png" % [out, zone_name, i])
		i += 1
	quit(0)
