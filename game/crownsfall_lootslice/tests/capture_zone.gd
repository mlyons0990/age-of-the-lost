extends SceneTree
## Capture a kit zone in game at given painting-px spots: --zone=<id> --at=x,y[;x,y...] --out=<png prefix>
var zone := ""; var spots := []; var out := ""
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--zone="): zone = a.substr(7)
		elif a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--at="):
			for s in a.substr(5).split(";"):
				var xy := s.split(","); spots.append(Vector2(float(xy[0]), float(xy[1])))
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	lab.painted_zone = zone
	root.add_child(lab)
	for i in 10: await physics_frame
	if lab.hud != null and lab.hud.has_method("set_branding"): lab.hud.set_branding(false)
	var i := 0
	for p in spots:
		lab.player.global_position = lab.zone_px_to_world(p.x, p.y) + Vector3.UP * 0.05
		lab.zone_last_ok = lab.player.global_position
		await create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s_%d.png" % [out, i]); i += 1
	quit(0)
