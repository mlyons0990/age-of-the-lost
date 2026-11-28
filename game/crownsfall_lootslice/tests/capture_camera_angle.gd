extends SceneTree
## Camera-angle study: the same Whisperwood spot with the hero viewed at the current 52-degree pitch and at ~31 degrees
## (the angle the paintings' ground is drawn at: painted circles are 0.51 as tall as wide = sin 31). Painting shown at
## the same on-screen size and the hero at the same 110 px in both; only the viewing angle differs.
var out := "/tmp"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	call_deferred("_run")
func _shot(pitch: float, name: String) -> void:
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	lab.painted_zone = "whisperwood"
	lab.pitch_override = pitch
	# keep the painting at the same screen scale (1.158 px per painting px) with the hero at 110 px
	lab.ppm_override = 110.0 / 1.158 / (1.75 * cos(deg_to_rad(pitch)))
	root.add_child(lab)
	for i in 10: await physics_frame
	lab.player.global_position = lab.zone_px_to_world(1880, 1000) + Vector3.UP * 0.05
	lab.zone_last_ok = lab.player.global_position
	lab.player.aim_point = lab.zone_px_to_world(2300, 1150)
	await create_timer(2.0).timeout
	var a = lab.player
	var top: float = lab.camera.unproject_position(a.global_position + Vector3.UP * 1.75).y
	var bot: float = lab.camera.unproject_position(a.global_position).y
	print("%s pitch %.0f hero %.0f px ppm %.1f" % [name, pitch, bot - top, lab.ZONE_PPM])
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/angle_%s.png" % [out, name])
	lab.queue_free()
	await process_frame
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	await _shot(52.0, "52")
	await _shot(31.0, "31")
	quit(0)
