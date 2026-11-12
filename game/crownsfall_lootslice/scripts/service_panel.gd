extends Control
## Left service slab paired with the right inventory. No alternate item state.
const Actions := preload("res://scripts/town_actions.gd")
const SYS := preload("res://scripts/systems.gd")
var ui: CanvasLayer
var shell: Control
var kind := "stash"
var frame: Control
var grid: Control
var rows: VBoxContainer
var notice: Label
var search: LineEdit
var mode_tabs: Array[Button]=[]
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame=shell.make_frame(); frame.size=shell.BASE; add_child(frame)
	var title: Label=shell.label(frame,"STASH" if kind=="stash" else "QUARTERMASTER",Rect2(86,32,508,32),26,shell.GOLD,true)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	shell.button(frame,"×",Rect2(625,14,34,34),ui.close_page)
	shell.label(frame,"WAYFARER'S STORAGE" if kind=="stash" else "EQUIPMENT & SUPPLIES",Rect2(76,112,528,28),18,shell.GOLD)
	if kind=="stash": build_stash()
	else: build_merchant()
	var band:=ColorRect.new(); band.color=Color(0.04,0.04,0.04,0.9); band.position=Vector2(70,854); band.size=Vector2(540,124); band.mouse_filter=Control.MOUSE_FILTER_IGNORE; frame.add_child(band)
	notice=shell.label(frame,ui.service_notice if ui.service_notice!="" else ("Ctrl-click to transfer. Drag to choose exact cells.\nSearch dims non-matching items; their cells stay occupied." if kind=="stash" else "Click to compare. Buy buttons charge the displayed price.\nCtrl-click a backpack item to sell; Buyback holds the last 12 sales."),Rect2(80,866,520,100),17,shell.MUTED)
	notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
func set_notice(value: String) -> void:
	if is_instance_valid(notice): notice.text=value
func line_edit(at: Vector2, width: float, hint: String, value: String) -> LineEdit:
	var edit:=LineEdit.new(); edit.position=at; edit.size=Vector2(width,34); edit.placeholder_text=hint; edit.text=value; edit.clear_button_enabled=true
	edit.add_theme_font_size_override("font_size",17); frame.add_child(edit); return edit
func build_stash() -> void:
	shell.label(frame,"60 CELLS · persistent item storage",Rect2(76,151,528,26),16,shell.MUTED)
	search=line_edit(Vector2(90,190),340,"Search stash",ui.stash_query)
	var filter:=OptionButton.new(); filter.position=Vector2(442,190); filter.size=Vector2(148,34); frame.add_child(filter)
	var categories: Array[String]=["all","weapons","armour","jewellery","unique"]
	for id in categories: filter.add_item(id.capitalize())
	filter.select(maxi(0,categories.find(ui.stash_category)))
	grid=ui._bag(frame,ui.player.stash,func(index: int) -> void: shell.show_external_item(ui.player.stash[index],"stash",true))
	grid.container_id="stash"; grid.cell_size=50; grid.position=Vector2(90,242); grid.custom_minimum_size=Vector2(500,300); grid.size=Vector2(500,300)
	grid.query=ui.stash_query; grid.category=ui.stash_category
	search.text_changed.connect(func(value: String) -> void: ui.stash_query=value; grid.query=value; shell.unpin(); grid.queue_redraw())
	filter.item_selected.connect(func(index: int) -> void: ui.stash_category=categories[index]; grid.category=categories[index]; shell.unpin(); grid.queue_redraw())
	var cells:=0
	for item in ui.player.stash:
		var footprint:=SYS.footprint(item); cells+=footprint.x*footprint.y
	shell.label(frame,"%d / 60 cells · %d items" % [cells,ui.player.stash.size()],Rect2(90,558,500,26),17,shell.GOLD)
	shell.button(frame,"Deposit matching backpack items →",Rect2(90,612,500,42),func() -> void: ui.town_action("deposit_matching"))
	shell.label(frame,"Batch deposit is all-or-nothing.\nIf the stash cannot hold every matching item,\nall items remain in their original cells.",Rect2(90,676,500,90),17,shell.MUTED)
func build_merchant() -> void:
	for i in 2:
		var mode: String=["stock","buyback"][i]
		var b: Button=shell.button(frame,"FOR SALE" if i==0 else "BUYBACK · %d / 12" % ui.main.buyback_stock.size(),Rect2(76+i*270,151,258,34),func() -> void: ui.shop_mode=mode; shell.unpin(); refresh_rows())
		mode_tabs.append(b)
	search=line_edit(Vector2(76,198),528,"Search equipment",ui.shop_query)
	search.text_changed.connect(func(value: String) -> void: ui.shop_query=value; shell.unpin(); refresh_rows())
	var scroll:=ScrollContainer.new(); scroll.position=Vector2(76,246); scroll.size=Vector2(528,475); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; frame.add_child(scroll)
	rows=VBoxContainer.new(); rows.custom_minimum_size.x=506; rows.add_theme_constant_override("separation",8); scroll.add_child(rows)
	refresh_rows()
	shell.button(frame,"Buy health potion · 5 gold",Rect2(76,742,258,42),func() -> void: ui.town_action("potion"))
	shell.button(frame,"Sell selected backpack item",Rect2(346,742,258,42),func() -> void:
		if ui.selected<0 or ui.selected>=ui.player.inventory.size(): ui._status("Select a backpack item first."); return
		ui.town_action("sell",ui.player.inventory[ui.selected].uid))
	if not ui.main.buyback_stock.is_empty():
		var last: Dictionary=ui.main.buyback_stock[-1]
		shell.button(frame,"Undo last sale · %d gold" % Actions.sale_price(last),Rect2(76,799,528,36),func() -> void: ui.town_action("buyback",last.uid))
func refresh_rows() -> void:
	if not is_instance_valid(rows): return
	for child in rows.get_children(): rows.remove_child(child); child.queue_free()
	for i in mode_tabs.size(): mode_tabs[i].modulate=Color.WHITE if i==(["stock","buyback"].find(ui.shop_mode)) else Color("8b8880")
	var items: Array=ui.main.merchant_stock if ui.shop_mode=="stock" else ui.main.buyback_stock.duplicate()
	if ui.shop_mode=="buyback": items.reverse()
	var count:=0
	for item in items:
		if not Actions.matches(item,ui.shop_query): continue
		count+=1
		var tile:=PanelContainer.new(); tile.add_theme_stylebox_override("panel",shell.style(Color("4a4135"),Color("151515"),8)); rows.add_child(tile)
		var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",8); tile.add_child(row)
		var inspect:=Button.new(); inspect.custom_minimum_size=Vector2(326,66); inspect.text=item.name+"\nRequires level %d" % int(item.level)
		inspect.icon=ui._item_icon(item); inspect.expand_icon=true; inspect.add_theme_constant_override("icon_max_width",52); inspect.add_theme_font_size_override("font_size",15)
		inspect.add_theme_color_override("font_color",Color(String(ui.GD.RARITY[int(item.rarity)].color))); inspect.clip_text=true
		inspect.pressed.connect(func() -> void: shell.show_external_item(item,ui.shop_mode,true))
		inspect.mouse_entered.connect(func() -> void: shell.show_external_item(item,ui.shop_mode,false))
		inspect.mouse_exited.connect(func() -> void:
			if not shell.pinned: shell.card.hide(); shell.shown_key="")
		row.add_child(inspect)
		var price:=Actions.sale_price(item)*(3 if ui.shop_mode=="stock" else 1)
		var buy:=Button.new(); buy.text="Buy\n%d gold" % price; buy.custom_minimum_size=Vector2(120,66); buy.add_theme_font_size_override("font_size",16)
		buy.set_meta("item_uid",item.uid); buy.set_meta("service_action","buy" if ui.shop_mode=="stock" else "buyback")
		buy.disabled=ui.player.gold<price
		buy.pressed.connect(func() -> void: ui.town_action("buy" if ui.shop_mode=="stock" else "buyback",item.uid)); row.add_child(buy)
	if count==0: rows.add_child(ui._label("No matching items." if not items.is_empty() else ("Nothing sold yet." if ui.shop_mode=="buyback" else "All equipment sold."),18,shell.MUTED))
func _process(_delta: float) -> void:
	if kind!="stash" or not is_instance_valid(grid) or shell.pinned or ui.inventory_shell!=shell: return
	if get_viewport().gui_is_dragging(): grid.queue_redraw(); return
	var at:=grid.get_local_mouse_position()
	if Rect2(Vector2.ZERO,grid.size).has_point(at):
		var index: int=grid.index_at(at)
		if index>=0: shell.show_external_item(ui.player.stash[index],"stash",false)
		elif shell.shown_key.begins_with("stash:"): shell.card.hide(); shell.shown_key=""

	elif shell.shown_key.begins_with("stash:"):
		shell.card.hide(); shell.shown_key=""
