extends "res://scripts/enemy.gd"
## Existing painted Revenant body; the new portrait is briefing art, not a rig.
## Rooted caster: status effects still tick; stun delays new casts only.
func _process(delta: float) -> void:
	if dead_t >= 0:
		super._process(delta)
		return
	flash = maxf(0,flash-delta); struck = maxf(0,struck-delta)
	stun = maxf(0,stun-delta); slow_time = maxf(0,slow_time-delta)
	if slow_time <= 0: slow_factor = 1.0
	phase += delta
	kb = Vector2.ZERO; moving = false; state = "chase"
	if _advance_burn(delta): return
	queue_redraw()
func take_hit(amount: int, crit: bool, from: Vector2, opt: Dictionary) -> float:
	var actual := super.take_hit(amount,crit,from,opt)
	kb = Vector2.ZERO
	return actual
func _draw() -> void:
	super._draw()
	if dead_t >= 0: return
	var pts := PackedVector2Array()
	for i in 65: pts.append(GD.to_px(Vector2(cos(TAU*i/64.0),sin(TAU*i/64.0))*0.82))
	draw_polyline(pts,Color("dcb16c"),2.5,true)
