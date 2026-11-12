extends Node2D
## An enemy projectile: a glowing orb that flies in a straight line along the
## ground. It can be dodged by stepping out of its path. Hurts the knight on contact.

const GD := preload("res://scripts/game_data.gd")
const HEIGHT := 58.0     # pixels above the ground the orb flies at
const HIT_RADIUS := 0.5  # ground units

var main: Node2D
var player: Node2D
var dir := Vector2.RIGHT # ground-unit direction, normalized
var speed := 7.0         # ground units per second
var life := 1.0          # seconds left
var dmg := 1.0
var level := 1
var col := Color("7dffc8")
var trail: Array = []    # recent positions, for the tail
var done := false
var src := ""   # who fired it, for the death screen


func _process(delta: float) -> void:
	if done:
		return
	life -= delta
	trail.push_front(position)
	if trail.size() > 7:
		trail.pop_back()
	position += GD.to_px(dir * speed * delta)
	if randf() < 0.5:
		main.fx_parts.spark(position + Vector2(0, -HEIGHT), Vector2.ZERO, randf_range(10, 50), 40.0, 0.0, 0.35, col, 4.0)
	if not player.dead and GD.gdist(position, player.position) < HIT_RADIUS:
		player.hurt(dmg, level, src)
		main.bolt_hits += 1
		_burst()
		return
	if life <= 0.0:
		_burst()
		return
	queue_redraw()


func _burst() -> void:
	done = true
	main.fx_parts.burst(position + Vector2(0, -HEIGHT), 12, [col, Color("e8fff4")], 3.0, 50.0)
	main.audio.play("bolt_hit", 0.1)
	queue_free()


func _draw() -> void:
	# ground shadow so the path is readable
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, GD.SQ))
	draw_circle(Vector2.ZERO, 24.0, Color(0.05, 0.2, 0.15, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in trail.size():
		var p: Vector2 = trail[i] - position + Vector2(0, -HEIGHT)
		draw_circle(p, 17.0 - i * 2.0, Color(col.r, col.g, col.b, 0.35 - i * 0.04))
	var c := Vector2(0, -HEIGHT)
	draw_circle(c, 28.0, Color(col.r, col.g, col.b, 0.22))
	draw_circle(c, 16.0, col)
	draw_circle(c, 8.0, Color("f2fff9"))
