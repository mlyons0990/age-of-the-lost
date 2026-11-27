extends SceneTree
## Screenshots of every game screen built from the painted UI kit, for each class (visual QA):
## hero window (Equipment with the live 3D hero, Character), skill tree, pause, Options tabs, shop, dialogue,
## death, key bindings, item tooltip; and the title + class pick.
##   xvfb-run godot --path . --rendering-driver opengl3 -s tests/capture_ui.gd -- --out=/tmp/ui [--classes=warrior,rogue]
var out := "/tmp"
var classes := ["warrior", "rogue", "mage", "cleric"]
var lab
var g
const SYS := preload("res://scripts/systems.gd")
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		if a.begins_with("--classes="): classes = Array(a.substr(10).split(","))
	call_deferred("_run")
func _wait(s: float) -> void:
	await create_timer(s, true).timeout
func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/ui_%s.png" % [out, name])
	print("shot ", name)
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	# title + class pick
	var title = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await _wait(0.5)
	await _shot("title")
	title._show_pick()
	title.name_edit.text = "Aldric"
	await _wait(0.3)
	await _shot("title_pick")
	title.queue_free()
	await process_frame
	for cls in classes:
		if lab != null: lab.queue_free(); await process_frame
		load("res://scripts/game/game_state.gd").new_character(cls, "Aldric")
		var boot = load("res://scripts/game/game_boot.gd")
		boot.class_id = cls; boot.new_game = true
		lab = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		root.add_child(lab)
		for i in 12: await physics_frame
		g = lab.game
		var st = lab.game_state
		st.add_xp(40000); st.unlock_skills(); st.gold = 1234
		for i in 9: st.add_item(SYS.make_item(st.level, 0.6, "", cls))
		g.apply_stats()
		await _wait(1.0)
		g.ui.toggle_inventory()
		await _wait(0.6)
		await _shot(cls + "_equipment")
		# hover the first bag item for the tooltip
		if not st.bag.is_empty():
			var r: Rect2 = g.ui._bag_rect(st.bag[0])
			g.ui._show_tip(st.bag[0], "Click to equip")
			await _shot(cls + "_tooltip")
			g.ui.tip.visible = false
		g.ui.toggle_character()
		await _wait(0.3)
		await _shot(cls + "_character")
		g.ui.toggle_character()
		g.ui.toggle_skills()
		await _wait(0.3)
		await _shot(cls + "_skills")
		g.ui.toggle_skills()
		if cls == classes[0]:
			g.ui.toggle_pause(); await _wait(0.3); await _shot("pause")
			for t in ["game", "display", "controls", "profile"]:
				g.ui.open_options(t); await _wait(0.3); await _shot("options_" + t)
			g.ui.close_panel()
			g.ui.open_vendor(); await _wait(0.4); await _shot("shop")
			g.ui.close_panel(); g.ui.inv.visible = false
			g.ui.dialogue("Captain Ralden", ["The Whisperwood has grown restless. Three pages of the old chronicle were scattered by the thornwood beasts.", "Bring them back and Crownsfall will owe you."], [["I will find them", Callable()], ["Not now", Callable()]])
			await _wait(0.3); await _shot("dialogue")
			g.ui.close_panel()
			g.ui.show_death(); await _wait(0.3); await _shot("death")
			g.ui.close_panel()
			lab.hud.toggle_bind_menu(); await _wait(0.3); await _shot("keybinds")
			lab.hud.toggle_bind_menu()
	quit(0)
