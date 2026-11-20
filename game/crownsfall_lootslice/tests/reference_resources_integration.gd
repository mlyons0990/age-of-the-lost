extends SceneTree
## With --headless, checks six action hitboxes, XP geometry and potion use.
## A rendering display also checks the live HP/MP/XP pixels:
## godot --path game/crownsfall_lootslice --resolution 1280x720 --rendering-method gl_compatibility --script res://tests/reference_resources_integration.gd

const Data := preload("res://scripts/game_data.gd")
const Layout := preload("res://scripts/reference_hud_layout.gd")
const REFERENCE := Vector2(1672, 941)

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	if change_scene_to_file("res://main.tscn") != OK:
		quit(2)
		return
	await scene_changed
	var game = current_scene
	game.save_blocked = true
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for modal in [game.hud.start_panel, game.hud.choice_panel, game.hud.death_panel]:
		if is_instance_valid(modal):
			modal.hide()
	var size: Vector2 = game.hud.draw_ctl.size
	for view: Vector2 in [Vector2(1024,576), REFERENCE, Vector2(2560,1080)]:
		var scale := Layout.scale_for(view)
		var rail := Layout.xp_rect(view)
		_check(absf(rail.get_center().x - view.x * 0.5) < 8 * scale, "XP rail lost horizontal centering")
		_check(absf(rail.size.y - 32 * scale) < scale and absf(view.y - rail.end.y - 13 * scale) < scale, "XP rail thickness or bottom inset changed")
		var potion := Layout.action_rect(view, 5)
		var first_skill := Layout.action_rect(view, 0)
		_check(potion.end.x < rail.position.x and rail.end.x < first_skill.position.x, "XP overlaps an action bank")
		for i in 4:
			_check(Layout.action_rect(view,i).end.x < Layout.action_rect(view,i+1).position.x, "Skill slots overlap")
	_check(game.hud.overlay_buttons.size() == 6, "R55's five skills and one potion must remain clickable")
	for i in game.hud.overlay_buttons.size():
		var button: Button = game.hud.overlay_buttons[i]
		_check(button.get_rect().is_equal_approx(Layout.action_rect(size, i)), "Action %d hitbox differs from the painted bounds" % i)
	paused = false
	game.player.dead = false
	game.player.hp = 1
	game.player.potions = 3
	game.hud.overlay_buttons[5].pressed.emit()
	_check(game.player.potions == 2 and game.player.hp > 1, "Left Q action must consume one real potion and heal")
	if DisplayServer.get_name() != "headless":
		await _state(game, "empty", 0.0, 0.0, 0.0, false)
		await _state(game, "partial", 0.30, 0.70, 0.35, false)
		await _state(game, "full", 1.0, 1.0, 1.0, false)
		await _state(game, "level cap", 0.70, 0.30, 0.0, true)
	print("Reference resource HUD: %d checks, %d failures" % [checks, failures])
	await game.sound.drain()
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _state(game: Node, description: String, hp: float, mp: float, xp: float, capped: bool) -> void:
	var player = game.player
	player.level = Data.MAX_LEVEL if capped else 2
	var stats: Dictionary = player.stats()
	player.hp = stats.max_hp * hp
	player.mp = stats.max_mp * mp
	player.xp = roundi(Data.xp_need(player.level) * xp)
	game.hud.draw_ctl.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_check(false, "Viewport readback failed")
		return
	var frame := Vector2(image.get_size())
	var scale := minf(frame.x / REFERENCE.x, frame.y / REFERENCE.y)
	# Interior probes intentionally avoid the glass highlight, guardian, and rim.
	for mana in [false, true]:
		var amount: float = mp if mana else hp
		var x := frame.x - 104 * scale if mana else 105 * scale
		for depth: float in [0.16, 0.45, 0.58, 0.84]:
			var y := frame.y - (23 + 138 * depth) * scale
			var color := image.get_pixel(roundi(x), roundi(y))
			var filled := color.b > color.r + 0.15 if mana else color.r > color.b + 0.15
			_check(filled == (amount > depth), "%s %s liquid at %.2f: %s" % [description, "MP" if mana else "HP", depth, color])
	# Use independent reference coordinates, scaled about each screen edge.
	# Probe just above and below the intended 35% XP transition. Skip the badge.
	var left := 495 * scale
	var right := frame.x - 500 * scale
	for position: float in [0.04, 0.32, 0.38, 0.79, 0.96]:
		var color := image.get_pixel(roundi(lerpf(left, right, position)), roundi(frame.y - 28 * scale))
		var purple := color.b > color.g + 0.15 and color.r > color.g + 0.10
		_check(purple == (capped or xp > position), "%s XP at %.2f: %s" % [description, position, color])
