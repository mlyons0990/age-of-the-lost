extends Control
## Nearby ground ownership paired with the real backpack. Only explicit
## collection commits state; inspection is pure and old callbacks use drop UID.
const SYS := preload("res://scripts/systems.gd")
var ui: CanvasLayer
var shell: Control
var frame: Control
var notice: Label
var rows: VBoxContainer
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame=shell.make_frame(); frame.size=shell.BASE; add_child(frame)
	var title: Label=shell.label(frame,"NEARBY LOOT",Rect2(86,32,508,32),26,shell.GOLD,true); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	shell.button(frame,"×",Rect2(625,14,34,34),ui.close_page)
	shell.label(frame,"GROUND → BACKPACK",Rect2(76,112,528,28),18,shell.GOLD)
	shell.label(frame,"Within reach · Inspect before collecting",Rect2(76,152,528,28),16,shell.MUTED)
	var scroll:=ScrollContainer.new(); scroll.position=Vector2(76,200); scroll.size=Vector2(528,602); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; frame.add_child(scroll)
	rows=VBoxContainer.new(); rows.custom_minimum_size.x=506; rows.add_theme_constant_override("separation",8); scroll.add_child(rows)
	var found: Array=ui.main.nearby_loot()
	for drop in found:
		var uid: String=drop.uid
		var tile:=PanelContainer.new(); tile.add_theme_stylebox_override("panel",shell.style(Color("4a4135"),Color("151515"),8)); rows.add_child(tile)
		var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",8); tile.add_child(row)
		var inspect:=Button.new(); inspect.custom_minimum_size=Vector2(326,84); inspect.add_theme_font_size_override("font_size",15); inspect.clip_text=true
		inspect.text=drop.display_name()
		if drop.kind=="item":
			var item: Dictionary=drop.item; var span:=SYS.footprint(item)
			inspect.text+="\n%d × %d cells · level %d" % [span.x,span.y,item.level]
			inspect.icon=ui._item_icon(item); inspect.expand_icon=true; inspect.add_theme_constant_override("icon_max_width",48)
			inspect.add_theme_color_override("font_color",Color(String(ui.GD.RARITY[int(item.rarity)].color)))
			inspect.pressed.connect(func() -> void: shell.show_external_item(item,"ground:"+uid,true))
		else: inspect.disabled=true
		row.add_child(inspect)
		var collect:=Button.new(); collect.text="Collect"; collect.custom_minimum_size=Vector2(120,84); collect.add_theme_font_size_override("font_size",16)
		collect.set_meta("drop_uid",uid); collect.pressed.connect(func() -> void: ui.collect_loot(uid)); row.add_child(collect)
	if found.is_empty(): rows.add_child(ui._label("No drops within reach.\nClose this panel and move closer.",18,shell.MUTED))
	shell.label(frame,"%d nearby · %d drops in the plaza" % [found.size(),ui.main.loot.size()],Rect2(76,814,528,28),16,shell.GOLD)
	var band:=ColorRect.new(); band.color=Color(0.04,0.04,0.04,0.9); band.position=Vector2(70,854); band.size=Vector2(540,124); band.mouse_filter=Control.MOUSE_FILTER_IGNORE; frame.add_child(band)
	notice=shell.label(frame,ui.main.loot_notice if ui.main.loot_notice!="" else "Walk over drops to collect, or use these Collect buttons.\nF: nearest drop in the world · N: this panel\nUncollected drops remain through saves and scene changes.",Rect2(80,866,520,100),17,shell.MUTED)
	notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
func set_notice(value: String) -> void:
	if is_instance_valid(notice): notice.text=value
