extends Node2D
## A drop on the ground: gold, a potion or an item. Picked up by walking over it.

const GD := preload("res://scripts/game_data.gd")

var kind := "gold"       # "gold", "potion" or "item"
var amount := 0
var item: Dictionary = {}
var age := 0.0
var uid := ""
var retry_at := 0.0
var notice := ""

func record() -> Dictionary:
	return {"uid":uid,"kind":kind,"amount":amount,"item":item.duplicate(true),"x":position.x,"y":position.y}

func display_name() -> String:
	return item.name if kind=="item" else ("%d gold" % amount if kind=="gold" else "%d health potion%s" % [amount,"s" if amount!=1 else ""])


func _process(delta: float) -> void:
	age += delta
	queue_redraw()


func _draw() -> void:
	var drop: float = maxf(0.0, 80.0 - age * 320.0)
	var bob: float = sin(age * 3.0) * 3.0
	draw_set_transform(Vector2(0, -drop), 0.0, Vector2.ONE)
	match kind:
		"gold":
			for p in [Vector2(-7, -3), Vector2(5, -5), Vector2(0, -9), Vector2(9, 0), Vector2(-10, 2)]:
				draw_set_transform(Vector2(p.x, p.y - drop), 0.0, Vector2(1.0, 0.55))
				draw_circle(Vector2.ZERO, 7.0, Color("a8801e"))
				draw_circle(Vector2.ZERO, 5.5, Color("ffd84a"))
		"potion":
			draw_rect(Rect2(-4, -34 + bob, 8, 8), Color("c9b38a"))
			draw_circle(Vector2(0, -14 + bob), 13.0, Color("a8121c"))
			draw_circle(Vector2(-2, -16 + bob), 9.0, Color("e0434a"))
			draw_circle(Vector2(-5, -19 + bob), 3.5, Color(1, 1, 1, 0.5))
		"item":
			var col := Color(String(GD.RARITY[int(item["rarity"])]["color"]))
			if int(item["rarity"]) >= 2:
				var top := Color(col.r, col.g, col.b, 0.0)
				var base := Color(col.r, col.g, col.b, 0.35 + 0.15 * sin(age * 4.0))
				draw_polygon(PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(8, -280), Vector2(-8, -280)]), PackedColorArray([base, base, top, top]))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -26 + bob), Vector2(12, -12 + bob), Vector2(0, 2 + bob), Vector2(-12, -12 + bob)]), col)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -20 + bob), Vector2(6, -12 + bob), Vector2(0, -4 + bob), Vector2(-6, -12 + bob)]), Color(1, 1, 1, 0.5))
			var font := ThemeDB.fallback_font
			var s: String = item["name"]
			var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
			draw_rect(Rect2(-w / 2 - 7, -62, w + 14, 24), Color(0, 0, 0, 0.72))
			draw_string(font, Vector2(-w / 2, -44), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, col)

	if kind!="item":
		draw_set_transform(Vector2.ZERO)
		var text:=display_name(); var font:=ThemeDB.fallback_font
		var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
		draw_rect(Rect2(-width/2-6,-60,width+12,24),Color(0,0,0,0.75))
		draw_string(font,Vector2(-width/2,-42),text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("e4d5b2"))
