extends RefCounted
## Ground-unit geometry shared by drawing, live hits, and encounter checks.
const GD := preload("res://scripts/game_data.gd")
const ORDER := ["line", "seals", "ring"]
const NAMES := {"line":"Severing Line", "seals":"Falling Seals", "ring":"Unmaking Ring"}
const HINTS := {"line":"Step sideways out of the lane", "seals":"Leave the marked circles", "ring":"Move inside the small ring or beyond the outer edge"}
static func warning(kind: String, origin: Vector2, aim: Vector2, second_phase: bool) -> Dictionary:
	var dir := GD.ground(origin, aim).normalized()
	if dir.length_squared() < 0.01: dir = Vector2.DOWN
	var duration: float = {"line":1.25,"seals":1.5,"ring":1.65}[kind]
	if second_phase: duration -= 0.2
	var zones: Array = []
	if kind == "seals":
		for offset in [Vector2.ZERO,Vector2(-1.9,0),Vector2(1.9,0)]: zones.append(aim + GD.to_px(offset))
	return {"kind":kind,"origin":origin,"direction":dir,"centers":zones,"duration":duration,"left":duration,"length":7.0,"half_width":0.48,"radius":1.05,"inner":1.35,"outer":3.3}
static func contains(w: Dictionary, at: Vector2, actor_radius := 0.28) -> bool:
	var p := GD.ground(w.origin,at)
	match String(w.kind):
		"line":
			var along := p.dot(w.direction)
			var side := absf(p.cross(w.direction))
			return along >= -actor_radius and along <= float(w.length)+actor_radius and side <= float(w.half_width)+actor_radius
		"seals":
			for center in w.centers:
				if GD.gdist(center,at) <= float(w.radius)+actor_radius: return true
		"ring": return p.length()+actor_radius >= float(w.inner) and p.length()-actor_radius <= float(w.outer)
	return false
static func tuning(level: int) -> Dictionary:
	var n := clampi(level,1,60)-1
	return {"level":n+1,"boss_hp":roundf(360.0*pow(1.0+0.12*n,1.75)),"raw_hit":10.0+4.0*(n+1),"add_hp":roundf(24.0*pow(1.0+0.12*n,2.15)),"gold":120+8*(n+1)}
