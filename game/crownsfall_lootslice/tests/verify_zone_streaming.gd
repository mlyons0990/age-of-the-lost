extends SceneTree
## Large zones: a 15360 px-wide canvas of 8 tiles. Only tiles near the camera are loaded; walking the length of the zone
## streams tiles in ahead and drops them behind, with no zone change and never a blank tile under the hero.
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + why)
func _initialize() -> void:
	call_deferred("_run")
func _tile_at(lab, px: Vector2) -> Dictionary:
	for t in lab.zone_tiles:
		if (t["rect"] as Rect2).has_point(px): return t
	return {}
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab: Node3D = (load("res://scenes/pilot_knight_combat_lab.tscn") as PackedScene).instantiate()
	lab.painted_zone = "res://tests/fixtures/zones/stream_test.json"
	root.add_child(lab)
	for i in 10: await physics_frame
	var total: int = lab.zone_tiles.size()
	check(total == 8, "Zone has 8 tiles")
	var shown0: int = lab.zone_tiles_shown()
	check(shown0 >= 2 and shown0 < total, "Only nearby tiles loaded at spawn (%d of %d)" % [shown0, total])
	check(_tile_at(lab, lab.zone_world_to_px(lab.player.global_position)).get("state", 0) == 2, "Tile under the hero is loaded at spawn")
	var a = lab.player
	var blank := 0
	var max_shown := 0
	var x := 600.0
	while x < 14800.0:
		x += 120.0
		a.global_position = lab.zone_px_to_world(x, 1150) + Vector3.UP * 0.05
		lab.zone_last_ok = a.global_position
		await physics_frame
		await physics_frame
		await process_frame
		var t := _tile_at(lab, Vector2(x, 1150))
		if t.get("state", 0) != 2: blank += 1
		max_shown = maxi(max_shown, lab.zone_tiles_shown())
	await create_timer(0.5).timeout
	check(blank == 0, "Tile under the hero always loaded while running the whole zone (%d misses)" % blank)
	check(max_shown < total, "Never more than the nearby tiles in memory (peak %d of %d)" % [max_shown, total])
	check(_tile_at(lab, Vector2(600, 1150)).get("state", 0) == 0, "Tiles left far behind are unloaded")
	check(lab.painted_zone.ends_with("stream_test.json"), "Still the same zone - no load screen")
	print("AOTL ZONE STREAMING RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
