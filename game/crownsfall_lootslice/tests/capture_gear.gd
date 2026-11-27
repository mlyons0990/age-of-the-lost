extends SceneTree
## Gear on the hero: common vs rare armour + legendary weapon, both classes (captures for review).
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0].substr(6)
	root.size = Vector2i(1920, 1080)
	for cls in ["warrior", "mage"]:
		load("res://scripts/game/game_state.gd").new_character(cls)
		var boot = load("res://scripts/game/game_boot.gd"); boot.class_id = cls; boot.new_game = true
		var lab = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		root.add_child(lab)
		for i in 12: await physics_frame
		lab.hud.visible = false
		lab.game.ui.visible = false
		for tier in [0, 1, 2, 3]:
			var g: Dictionary = lab.game_state.gear
			for slot in ["weapon", "offhand", "armor"]:
				var it: Dictionary = g.get(slot, {"slot": slot}).duplicate()
				it["rarity"] = tier
				g[slot] = it
			lab.game.apply_stats()
			await create_timer(0.6).timeout
			await RenderingServer.frame_post_draw
			var sp: Vector2 = lab.camera.unproject_position(lab.player.global_position + Vector3.UP * 0.9)
			var img: Image = root.get_texture().get_image().get_region(Rect2i(int(sp.x) - 150, int(sp.y) - 170, 300, 300))
			img.save_png("%s/gear_%s_%d.png" % [out, cls, tier])
		lab.queue_free()
		await process_frame
	quit(0)
