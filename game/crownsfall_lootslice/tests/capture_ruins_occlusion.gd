extends SceneTree
## Capture: hero standing behind a shrine pillar in Whisperwood (pillar in front, gold silhouette through it).
var out := "/tmp"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	lab.painted_zone = "whisperwood"
	root.add_child(lab)
	for i in 10: await physics_frame
	var spots := {"behind_great_arch_pillar": Vector2(1662, 700), "behind_front_column": Vector2(1495, 840), "behind_arcade": Vector2(2135, 610)}
	for k in spots:
		var p: Vector2 = spots[k]
		lab.player.global_position = lab.zone_px_to_world(p.x, p.y) + Vector3.UP * 0.05
		lab.zone_last_ok = lab.player.global_position
		print(k, " walkable=", lab.zone_walkable(lab.player.global_position))
		await create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/ruins_%s.png" % [out, k])
	quit(0)
