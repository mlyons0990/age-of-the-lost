extends Node2D
## Ground-space swept collision, visual height only. The packet snapshots at cast.
const GD := preload("res://scripts/game_data.gd")
var caster: Node2D
var packet: Dictionary
var definition: Dictionary
var direction := Vector2.RIGHT
var remaining := 0.0
var speed := 12.0
var hits_left := 1
var hit_ids: Array[int] = []
var trail: Array[Vector2] = []
var color := Color("ffad64")

func setup(owner_actor: Node2D, skill: Dictionary, hit_packet: Dictionary, aim: Vector2) -> void:
	caster = owner_actor
	definition = skill
	packet = hit_packet
	direction = GD.ground(caster.position, aim).normalized()
	position = caster.position
	remaining = float(skill.get("range", 7.0))
	speed = float(skill.get("speed", 12.0))
	hits_left = int(skill.get("pierce", 1))
	color = Color(String(skill.get("color", "ffad64")))
	z_index = 90

func _physics_process(delta: float) -> void:
	if not is_instance_valid(caster) or caster.dead or int(packet.get("epoch", -1)) != caster.combat_epoch:
		queue_free(); return
	var distance := minf(remaining, speed * delta)
	var next := position + GD.to_px(direction * distance)
	# Projectiles cannot fly through the painted area's navigation boundaries.
	var cp := NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, next)
	if cp.distance_to(next) > 7.0: queue_free(); return
	var candidates: Array = []
	var segment := direction * distance
	for enemy in caster.main.enemies:
		if not is_instance_valid(enemy) or enemy.dead_t >= 0.0 or hit_ids.has(enemy.get_instance_id()): continue
		var offset := GD.ground(position, enemy.position)
		var t := clampf(offset.dot(segment) / maxf(segment.length_squared(), 0.00001), 0, 1)
		if (offset - segment * t).length() <= 0.22 + enemy.rad:
			candidates.append({"enemy": enemy, "t": t})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.t < b.t)
	for candidate in candidates:
		var enemy: Node2D = candidate.enemy
		hit_ids.append(enemy.get_instance_id())
		caster.apply_packet(enemy, packet, {"colors": [color, Color.WHITE]})
		hits_left -= 1
		if hits_left <= 0: queue_free(); return
	trail.push_front(position)
	if trail.size() > 9: trail.pop_back()
	position = next
	remaining -= distance
	if remaining <= 0.0: queue_free()
	queue_redraw()

func _draw() -> void:
	var height := Vector2(0, -88)
	for i in trail.size():
		var k := 1.0 - float(i) / 9.0
		draw_circle(trail[i] - position + height, 10 * k, Color(color, 0.45 * k))
	draw_circle(height, 20, Color(color, 0.14))
	draw_circle(height, 9, color)
	draw_circle(height, 4, Color.WHITE)
	if definition.get("school") == "frost":
		draw_line(height - direction * 20, height + direction * 20, Color.WHITE, 3, true)
