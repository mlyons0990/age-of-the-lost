extends SceneTree
## Painted-zone foreground: a hero standing behind a painted lamp post is hidden by it; beside it the hero is visible.
var checks := 0
var failures := 0
var out := ""
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + why)
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	call_deferred("_run")
func _grab() -> Image:
	await process_frame; await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func _diff(a: Image, b: Image, r: Rect2i) -> float:
	var n := 0
	var hit := 0
	for y in range(r.position.y, r.end.y, 2):
		for x in range(r.position.x, r.end.x, 2):
			if x < 0 or y < 0 or x >= a.get_width() or y >= a.get_height(): continue
			n += 1
			var ca := a.get_pixel(x, y); var cb := b.get_pixel(x, y)
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.12: hit += 1
	return float(hit) / maxf(1.0, float(n))
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 10: await physics_frame
	check(lab.zone.has("depth"), "Zone has a baked foreground depth map")
	lab.hud.visible = false
	for n in lab.get_children():
		if n is CanvasLayer: n.visible = false
	var a = lab.player
	# lamp post on the south-west railing: column x 730..815 px, head ~955..1060 px; floor behind it at row ~1150
	a.global_position = lab.zone_px_to_world(772, 1150)
	a.velocity = Vector3.ZERO
	await create_timer(2.5).timeout          # camera eases onto the hero; let it settle
	var with_hero := await _grab()
	if out != "": with_hero.save_png(out + "/occlusion_behind_lamp.png")
	var feet: Vector2 = lab.camera.unproject_position(a.global_position)
	var head: Vector2 = lab.camera.unproject_position(a.global_position + Vector3.UP * 1.6)
	a.visible = false
	var without := await _grab()
	if out != "": without.save_png(out + "/occlusion_without.png")
	a.visible = true
	# the lamp column in screen space: painting x 744..800 projected
	var l0: Vector2 = lab.camera.unproject_position(lab.zone_px_to_world(748, 1000))
	var l1: Vector2 = lab.camera.unproject_position(lab.zone_px_to_world(796, 1060))
	var lamp := Rect2i(Vector2i(l0), Vector2i(l1 - l0))
	var body := Rect2i(Vector2i(int(feet.x) - 40, int(head.y)), Vector2i(80, int(feet.y - head.y)))
	var in_lamp := _diff(with_hero, without, lamp)
	var beside := _diff(with_hero, without, Rect2i(body.position + Vector2i(0, 0), Vector2i(body.size.x, int(body.size.y * 0.5))))
	print("lamp rect %s changed %.3f; hero upper body changed %.3f" % [lamp, in_lamp, beside])
	check(in_lamp < 0.05, "Painted lamp head stays in front of the hero standing behind it (%.3f)" % in_lamp)
	check(beside > 0.15, "The rest of the hero is still drawn over the floor (%.3f)" % beside)
	# open floor: nothing in front
	a.global_position = lab.zone_px_to_world(1920, 900)
	await create_timer(2.5).timeout          # camera eases onto the hero; let it settle
	var open_a := await _grab()
	feet = lab.camera.unproject_position(a.global_position)
	head = lab.camera.unproject_position(a.global_position + Vector3.UP * 1.6)
	a.visible = false
	var open_b := await _grab()
	var open_d := _diff(open_a, open_b, Rect2i(int(feet.x) - 30, int(head.y), 60, int(feet.y - head.y)))
	check(open_d > 0.25, "On open floor the hero is fully drawn (%.3f)" % open_d)
	print("AOTL ZONE OCCLUSION RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
