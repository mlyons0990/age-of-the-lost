extends SceneTree
## Optional presentation QA: do not write saves, do not change the main suite.
## Run with isolated XDG dirs to keep real user progress completely protected.
const Layout := preload("res://scripts/poe_hud_layout.gd")
var checks := 0
var fails := 0

func _initialize() -> void:
	call_deferred("_run")

func verify(pass_condition: bool, label: String) -> void:
	checks += 1
	if not pass_condition:
		fails += 1
		printerr("FAIL: ", label)
	else:
		print("PASS: ", label)

func _run() -> void:
	for vp in [Vector2(1920,1080),Vector2(1536,864),Vector2(1440,810),Vector2(1280,720),Vector2(1024,576)]:
		var layout: Dictionary = Layout.compute(vp)
		verify(Layout.check_geometry(vp), "Layout stays separated at %dx%d" % [vp.x, vp.y])
		verify(layout["flasks"].size() == 5 and layout["skills"].size() == 5, "Five flask + five skill frames at %dx%d" % [vp.x, vp.y])
		verify(layout["left_orb"].x < layout["flasks"][0].position.x and layout["right_orb"].x > layout["skills"][4].end.x, "Globes outside icon banks at %dx%d" % [vp.x, vp.y])
		verify(layout["xp_rect"].position.x > layout["left_panel"].end.x and layout["xp_rect"].end.x < layout["right_panel"].position.x, "Centre XP not under icons at %dx%d" % [vp.x,vp.y])
	verify(is_equal_approx(Layout.DEFAULT_ZOOM,0.84),"Playable camera defaults to wider ARPG zoom")
	change_scene_to_file("res://main.tscn")
	for i in 5:
		await process_frame
	var game = current_scene
	verify(game != null, "Main saved game scene still instantiates")
	if game == null:
		print("AOTL POE HUD QA: %d checks | FAIL %d" % [checks,fails])
		quit(1)
		return
	var ui = game.hud
	verify(ui != null and ui.overlay_buttons.size() == 10, "Ten interactive slots prevent world click-through")
	verify(is_equal_approx(game.cam.zoom.x, Layout.DEFAULT_ZOOM), "Main camera starts at PoE-wide framing")
	verify(not ui.action_menu_row.visible and ui.action_menu_button.visible, "Toolbar starts collapsed; Menu still reachable")
	var viewport: Vector2 = root.get_visible_rect().size
	ui._layout_bar()
	for i in 10:
		var want: Rect2 = Layout.clickable_rect(viewport,i)
		var btn: Button = ui.overlay_buttons[i]
		verify(btn.position.is_equal_approx(want.position) and btn.size.is_equal_approx(want.size), "HUD input slot %d matches painted bounds" % i)
	var before: String = JSON.stringify(game.capture_save())
	game._set_gameplay_zoom(0.66)
	verify(is_equal_approx(game.cam.zoom.x,Layout.ZOOM_MIN), "Camera enforces maximum zoom-out")
	game._set_gameplay_zoom(1.3)
	verify(is_equal_approx(game.cam.zoom.x,Layout.ZOOM_MAX), "Camera enforces maximum zoom-in")
	game._set_gameplay_zoom(Layout.DEFAULT_ZOOM)
	ui._toggle_action_menu()
	verify(ui.action_menu_row.visible, "Menu opens and preserves old controls")
	ui._toggle_action_menu()
	verify(not ui.action_menu_row.visible, "Menu closes")
	verify(JSON.stringify(game.capture_save()) == before, "Camera and menu do not alter schema-six game save")
	# Do not touch an existing user save; in this test the isolated XDG dir
	# may show an initial onboarding panel, which is removed without invoking Save.
	if ui.start_panel != null:
		ui.start_panel.queue_free()
		ui.start_panel = null
		ui._refresh_pause()
	await process_frame
	var p = game.player
	p.potions = 2
	var maxhp: float = p.stats()["max_hp"]
	p.hp = maxhp * 0.3
	var hp_before: float = p.hp
	ui.overlay_buttons[9].pressed.emit()
	verify(p.potions == 2 and is_equal_approx(p.hp,hp_before), "Unassigned flask button spends nothing")
	ui.overlay_buttons[5].pressed.emit()
	verify(p.potions == 1 and p.hp > hp_before, "Q flask button consumes exactly one actual health potion")
	verify(p.hotbar.size() == 5, "Five actual ability bindings remain unchanged")
	print("AOTL POE HUD QA: %d checks | %s" % [checks, "PASS" if fails == 0 else "%d FAIL" % fails])
	quit(0 if fails == 0 else 1)