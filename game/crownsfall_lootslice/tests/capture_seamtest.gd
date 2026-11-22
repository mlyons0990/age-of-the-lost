extends SceneTree
var out := "/tmp"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	lab.painted_zone = "ww_seamtest"
	root.add_child(lab)
	for i in 10: await physics_frame
	if OS.get_cmdline_user_args().has("--nocatcher"): lab.get_node("ZoneShadowCatcher").visible = false
	for spot in [["seam", Vector2(4736, 900)], ["shrine", Vector2(2400, 1300)], ["stele", Vector2(7300, 1100)]]:
		lab.player.global_position = lab.zone_px_to_world(spot[1].x, spot[1].y) + Vector3.UP * 0.05
		lab.zone_last_ok = lab.player.global_position
		await create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/seamtest_%s.png" % [out, spot[0]])
	quit(0)
