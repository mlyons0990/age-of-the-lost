extends SceneTree
## Capture the zone-exit portals on their painted thresholds (Crownsfall grand stairs, Whisperwood shrine stairs).
var out := "/tmp"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	call_deferred("_run")
func _shot(zone: String, at: Vector2, name: String) -> void:
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	lab.painted_zone = zone
	root.add_child(lab)
	for i in 10: await physics_frame
	lab.player.global_position = lab.zone_px_to_world(at.x, at.y) + Vector3.UP * 0.05
	lab.zone_last_ok = lab.player.global_position
	await create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/portal_%s.png" % [out, name])
	lab.queue_free()
	await process_frame
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	await _shot("crownsfall", Vector2(1000, 700), "crownsfall_stairs")
	await _shot("whisperwood", Vector2(640, 560), "whisperwood_stairs")
	quit(0)
