extends Node2D
## A delayed blast on the ground: a warning circle fills in, then it detonates and
## hurts the knight if he is still inside. Used by Molten elites (and later bosses).

const GD := preload("res://scripts/game_data.gd")

var main: Node2D
var player: Node2D
var radius := 2.0        # ground units
var delay := 1.3         # seconds of warning
var dmg := 10.0
var level := 1
var col := Color("ff7a2e")
var t := 0.0
var done := false
var src := ""   # who caused it, for the death screen


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if done:
		if t > delay + 0.35:
			queue_free()
		return
	if t >= delay:
		done = true
		main.audio.play("boom", 0.05)
		main.shake = maxf(main.shake, 7.0)
		main.fx_parts.burst(position, 30, [col, Color("ffe2a0"), Color("5a2a10")], 5.0, 40.0, 8.0)
		if not player.dead and GD.gdist(position, player.position) <= radius:
			player.hurt(dmg, level, src)
			main.hazard_hits += 1


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, GD.SQ))
	var r := radius * GD.U
	if not done:
		var k := clampf(t / delay, 0.0, 1.0)
		draw_circle(Vector2.ZERO, r * k, Color(col.r, col.g, col.b, 0.12 + 0.22 * k))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.85), 4.0, true)
	else:
		var f := 1.0 - clampf((t - delay) / 0.35, 0.0, 1.0)
		draw_circle(Vector2.ZERO, r * (1.0 + 0.15 * (1.0 - f)), Color(1.0, 0.85, 0.5, 0.6 * f))
