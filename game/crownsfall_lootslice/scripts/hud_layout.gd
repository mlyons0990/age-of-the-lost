extends RefCounted
## One source of geometry for painted HUD and actual click targets.
static func for_viewport(view: Vector2) -> Dictionary:
	var scale := minf(1.0, minf(view.x/1920.0, view.y/1080.0))
	var side := 64.0*scale
	var skills: Array[Rect2] = []
	var x0 := view.x-640*scale
	for i in 5: skills.append(Rect2(x0+i*72*scale,view.y-116*scale,side,side))
	return {"scale":scale,"skills":skills,"potion":Rect2(280*scale,view.y-116*scale,238*scale,side),
		"life":Vector2(158*scale,view.y-112*scale),"mana":Vector2(view.x-158*scale,view.y-112*scale),
		"radius":82*scale,"xp":Rect2(280*scale,view.y-17*scale,view.x-560*scale,9*scale)}
