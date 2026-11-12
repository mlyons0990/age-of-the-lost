extends Control
## Right-docked equipment/bag, with a character tab and a separate item card.
## Layout study: Path of Exile 1/2; all art and rules belong to Crownsfall.
const SYS := preload("res://scripts/systems.gd")
const DATA := preload("res://scripts/game_data.gd")
const INK := Color("111213")
const METAL := Color("877052")
const GOLD := Color("d5c09a")
const MUTED := Color("918c80")
const BASE := Vector2(680,1020)
const SLOTS := {"helm":Rect2(292,8,88,88),"weapon":Rect2(76,45,92,204),"offhand":Rect2(512,45,92,204),"armor":Rect2(284,108,104,140),"amulet":Rect2(409,92,48,56),"ring1":Rect2(213,196,48,48),"ring2":Rect2(411,196,48,48),"gloves":Rect2(180,260,80,76),"belt":Rect2(284,272,104,44),"boots":Rect2(411,260,80,76)}
var service: Control
var search: LineEdit
var ui: CanvasLayer
var dock: Control
var stage: Control
var stats_area: ScrollContainer
var card: PanelContainer
var card_scroll: ScrollContainer
var pinned := false
var hover_index := -1
var shown_key := ""
var tab := "equipment"
var equipment_tab: Button
var character_tab: Button
var bag: Control
var scale_factor := 1.0
var keyboard_mode := false
var focus_cell := Vector2i(0, 0)
var font: SystemFont

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_STOP
	# A transparent input shield leaves the town visible while modal rules pause it.
	gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton: unpin(); accept_event())
	font = SystemFont.new(); font.font_names = PackedStringArray(["Georgia","DejaVu Serif"])
	dock = Frame.new(); dock.custom_minimum_size = BASE; dock.size = BASE; add_child(dock)
	var title_label:=label(dock,"INVENTORY",Rect2(100,32,480,32),27,GOLD,true)
	title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	button(dock,"×",Rect2(625,14,34,34),ui.close_page)
	equipment_tab = button(dock,"EQUIPMENT  [I]",Rect2(24,67,310,34),func() -> void: set_tab("equipment"))
	character_tab = button(dock,"CHARACTER  [C]",Rect2(346,67,310,34),func() -> void: set_tab("character"))
	ui.action_art(equipment_tab,"inventory"); ui.action_art(character_tab,"character")
	label(dock,ui.player.hero_name+"  ·  Level %d %s" % [ui.player.level,ui.player.title()],Rect2(76,111,528,28),18,GOLD)
	stage = Control.new(); stage.position = Vector2(0,142); stage.size = Vector2(680,340); dock.add_child(stage)
	ui.gear_buttons.clear()
	for slot in SLOTS:
		var b := EquipmentSlot.new(); b.ui = ui; b.shell = self; b.slot = slot
		b.position = SLOTS[slot].position; b.size = SLOTS[slot].size; stage.add_child(b); ui.gear_buttons.append(b)
	stats_area = ScrollContainer.new(); stats_area.position = Vector2(76,148); stats_area.size = Vector2(528,328)
	stats_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; dock.add_child(stats_area)
	build_stats()
	var st: Dictionary = ui.player.stats()
	label(dock,"LIFE  %d / %d" % [ceili(ui.player.hp),st.max_hp],Rect2(76,491,252,28),18,Color("d98882"))
	label(dock,"MANA  %d / %d" % [floori(ui.player.mp),st.max_mp],Rect2(350,491,290,28),18,Color("8faacb"))
	var life_bar := ResourceMeter.new(); life_bar.ui=ui; life_bar.kind="life"
	life_bar.position=Vector2(76,522); life_bar.size=Vector2(252,8); dock.add_child(life_bar)
	var mana_bar := ResourceMeter.new(); mana_bar.ui=ui; mana_bar.kind="mana"
	mana_bar.position=Vector2(350,522); mana_bar.size=Vector2(254,8); dock.add_child(mana_bar)
	# One real potion resource, rather than decorative non-functional flask slots.
	var potion := button(dock,"HEALTH POTIONS   %d / 5   ·   Q in the world" % ui.player.potions,Rect2(118,532,444,34),func() -> void: ui._status("Close the panel and press Q to drink a health potion."))
	potion.add_theme_color_override("font_color",Color("c8958a"))
	label(dock,"BACKPACK · %d / 60" % occupied(),Rect2(76,579,280,26),18,GOLD,true)
	search=LineEdit.new(); search.position=Vector2(370,577); search.size=Vector2(220,30); search.placeholder_text="Search backpack"; search.text=ui.inventory_query; search.clear_button_enabled=true; dock.add_child(search)
	bag = ui._bag(dock,ui.player.inventory,ui._inspect); ui.bag_view = bag; bag.cell_size = 50.0
	bag.query=ui.inventory_query
	search.text_changed.connect(func(value: String) -> void: ui.inventory_query=value; bag.query=value; unpin(); bag.queue_redraw())
	bag.position = Vector2(90,614); bag.custom_minimum_size = Vector2(500,300); bag.size = Vector2(500,300)
	label(dock,"GOLD  %s" % str(ui.player.gold),Rect2(76,931,272,30),21,GOLD,true)
	button(dock,"Arrange bag",Rect2(426,929,216,34),func() -> void:
		var next: Array=ui.player.inventory.duplicate(true)
		if SYS.sort_bag(next) and ui.main.persist_changes({"inventory":next}): ui.player.inventory=next; ui.refresh_inventory()
		else: ui._status("Could not arrange this bag; placements preserved."))
	var hint_band:=ColorRect.new(); hint_band.color=Color(0.05,0.05,0.05,0.85)
	hint_band.position=Vector2(70,967); hint_band.size=Vector2(540,40); hint_band.mouse_filter=Control.MOUSE_FILTER_IGNORE; dock.add_child(hint_band)
	ui.status_label = label(dock,("Ctrl-click: transfer · Drag between grids · Click: inspect" if ui.page=="stash" else ("Ctrl-click bag: sell · Buyback restores sold items" if ui.page=="merchant" else "Arrows / D-pad: select  ·  Enter / A: inspect  ·  Shift+Enter / X: equip")),Rect2(76,969,528,38),14,MUTED)
	ui.status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card = PanelContainer.new(); card.add_theme_stylebox_override("panel",style(Color("8b7356"),Color("111112"),16)); add_child(card)
	card_scroll = ScrollContainer.new(); card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; card.add_child(card_scroll)
	ui.inspector = VBoxContainer.new(); ui.inspector.custom_minimum_size.x = 314; ui.inspector.add_theme_constant_override("separation",10); card_scroll.add_child(ui.inspector)
	card.hide()
	if ui.page=="loot":
		service=load("res://scripts/loot_panel.gd").new(); service.ui=ui; service.shell=self; add_child(service)
	elif ui.page in ["stash","merchant"]:
		service=load("res://scripts/service_panel.gd").new(); service.ui=ui; service.shell=self; service.kind=ui.page; add_child(service)
	get_viewport().size_changed.connect(layout); set_tab("equipment"); layout()

func style(border: Color, fill: Color, margin := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color=fill; s.border_color=border; s.set_border_width_all(1); s.set_content_margin_all(margin)
	return s
func label(parent: Control, text: String, rect: Rect2, size: int, color: Color, serif := false) -> Label:
	var l:=Label.new(); l.text=text; l.position=rect.position; l.size=rect.size; l.add_theme_font_size_override("font_size",size); l.add_theme_color_override("font_color",color)
	if serif: l.add_theme_font_override("font",font)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(l); return l
func button(parent: Control, text: String, rect: Rect2, action: Callable) -> Button:
	var b:=Button.new(); b.text=text; b.position=rect.position; b.size=rect.size; b.focus_mode=Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size",16); b.add_theme_color_override("font_color",GOLD)
	b.add_theme_stylebox_override("normal",style(Color("605441"),Color("202020")))
	b.add_theme_stylebox_override("hover",style(GOLD,Color("32302a")))
	b.add_theme_stylebox_override("pressed",style(GOLD,Color("121210")))
	b.pressed.connect(action); parent.add_child(b); return b
func focus_step(dx: int, dy: int) -> void:
	if pinned: unpin()
	keyboard_mode = true
	focus_cell = Vector2i(clampi(focus_cell.x + dx, 0, SYS.WIDTH - 1), clampi(focus_cell.y + dy, 0, SYS.HEIGHT - 1))
	if is_instance_valid(bag): bag.queue_redraw()

func focus_inspect(quick_equip := false) -> void:
	keyboard_mode = true
	if not is_instance_valid(bag): return
	var center: Vector2 = (Vector2(focus_cell) + Vector2(0.5,0.5)) * bag.cell_size
	var index: int = bag.index_at(center)
	if index < 0:
		ui._status("Empty backpack cell. Use the arrows to select an item.")
		return
	if quick_equip:
		ui.selected = index
		ui._equip(SYS.default_slot(ui.player.inventory[index]))
	else:
		show_bag_item(index,true)
	if is_instance_valid(bag): bag.queue_redraw()

func switch_tab() -> void:
	set_tab("character" if tab=="equipment" else "equipment")

func occupied() -> int:
	var cells:=0
	for item in ui.player.inventory:
		var fp:=SYS.footprint(item); cells+=fp.x*fp.y
	return cells
func layout() -> void:
	var viewport:=get_viewport_rect().size
	scale_factor=minf(1.0,minf((viewport.y-24)/BASE.y,viewport.x*0.45/BASE.x))
	dock.scale=Vector2.ONE*scale_factor; dock.position=Vector2(viewport.x-BASE.x*scale_factor-12,(viewport.y-BASE.y*scale_factor)/2)
	if is_instance_valid(service): service.frame.scale=Vector2.ONE*scale_factor; service.frame.position=Vector2(12,dock.position.y)
	card.scale=Vector2.ONE*scale_factor; card.size=Vector2(350,minf(690,(viewport.y-40)/scale_factor))
	card_scroll.custom_minimum_size=Vector2(314,minf(650,(viewport.y-80)/scale_factor))
	card.position=Vector2(maxf(10,dock.position.x-366*scale_factor),maxf(16,(viewport.y-card.size.y*scale_factor)/2))
func set_tab(value: String) -> void:
	tab=value; stage.visible=value=="equipment"; stats_area.visible=value=="character"
	equipment_tab.modulate=Color.WHITE if value=="equipment" else Color("8b8880")
	character_tab.modulate=Color.WHITE if value=="character" else Color("8b8880")
	unpin()
func _stat_line(body: VBoxContainer, caption: String, value: String, help: String = "") -> void:
	var line:=HBoxContainer.new(); line.add_theme_constant_override("separation",8); body.add_child(line)
	var name: Label=ui._label(caption,16,Color("b9b5aa")); name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if help != "": name.tooltip_text=help; name.mouse_filter=Control.MOUSE_FILTER_PASS
	line.add_child(name)
	line.add_child(ui._label(value,16,Color("e1d8c6")))

func build_stats() -> void:
	var body:=VBoxContainer.new(); body.custom_minimum_size.x=512
	body.add_theme_constant_override("separation",7); stats_area.add_child(body)
	var current: Dictionary=ui.player.stats()
	var without_gear: Dictionary=SYS.derive(ui.player.level,{},ui.player.mods(),ui.player.class_id)
	body.add_child(ui._label("PRIMARY ATTRIBUTES  ·  BASE + EQUIPMENT",16,GOLD))
	var attributes:=GridContainer.new(); attributes.columns=2
	attributes.add_theme_constant_override("h_separation",7)
	attributes.add_theme_constant_override("v_separation",5); body.add_child(attributes)
	for pair in [["Strength","strength"],["Dexterity","dexterity"],["Vitality","vitality"],["Intelligence","intelligence"],["Wisdom","wisdom"],["Charisma","charisma"]]:
		var title: String=pair[0]; var id: String=pair[1]
		var base_value: float=float(without_gear.attributes[id])
		var total_value: float=float(current.attributes[id])
		var bonus: float=total_value-base_value
		var cell:=PanelContainer.new(); cell.custom_minimum_size.x=249
		cell.add_theme_stylebox_override("panel",style(Color("443a2c"),Color("121619"),4))
		attributes.add_child(cell)
		var content:=VBoxContainer.new(); content.add_theme_constant_override("separation",0); cell.add_child(content)
		content.add_child(ui._label("%s   %s" % [title,str(snappedf(total_value,0.1))],15,Color("e1d8c6")))
		var suffix: String = " (no gear)" if is_zero_approx(bonus) else " (%s gear)" % ("%+.1f" % bonus)
		content.add_child(ui._label("Base %s%s" % [str(snappedf(base_value,0.1)),suffix],13,Color("a5c993") if bonus>0 else MUTED))
	body.add_child(HSeparator.new())
	body.add_child(ui._label("OFFENSE",16,GOLD))
	_stat_line(body,"Spell power" if ui.player.class_id=="mage" else "Weapon power", "%.1f" % (current.spell_power if ui.player.class_id=="mage" else current.dmg),"Derived from actual equipment, attributes and chosen talents")
	_stat_line(body,"Critical strike chance","%.2f%%" % (current.crit*100.0),"Total current chance, including gear")
	_stat_line(body,"Cooldown reduction","%.0f%%" % (float(current.m.cdr)*100.0),"Chosen abilities and progression modifiers")
	body.add_child(HSeparator.new())
	body.add_child(ui._label("DEFENSE AND RESOURCES",16,GOLD))
	_stat_line(body,"Armour",str(int(current.armor)),"Armor rating; damage reduction depends on the attacker's level")
	_stat_line(body,"Maximum life",str(int(current.max_hp)))
	_stat_line(body,"Maximum mana",str(int(current.max_mp)))
	_stat_line(body,"Mana regeneration","%.2f / second" % float(current.mana_regen))
	body.add_child(HSeparator.new())
	var note: Label=ui._label("Resistances, evasion and energy shield are not implemented in this build.",14,MUTED)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(note)

func unpin() -> void:
	pinned=false; shown_key=""; ui.selected=-1
	if is_instance_valid(card): card.hide()
	if is_instance_valid(bag): bag.queue_redraw()
func show_bag_item(index: int, pin := false) -> void:
	if index<0 or index>=ui.player.inventory.size(): return
	if pinned and not pin: return
	var item: Dictionary=ui.player.inventory[index]; var key:="inventory:"+String(item.uid)
	if pin: pinned=true; ui.selected=index; bag.queue_redraw()
	if shown_key==key and card.visible: return
	shown_key=key; ui.fill_inventory_details(item,SYS.default_slot(item),index)
	card.show()
func release_keyboard_cursor() -> void:
	keyboard_mode=false
	if is_instance_valid(bag): bag.queue_redraw()

func show_equipped(slot: String) -> void:
	var item: Variant=ui.player.gear.get(slot)
	if not item is Dictionary: return
	pinned=true; ui.selected=-1; shown_key="equipped:"+slot
	ui.fill_inventory_details(item,slot,-1); card.show()
func _process(_delta: float) -> void:
	if not ui.inventory_active() or ui.inventory_shell!=self or not is_instance_valid(bag): return
	if card.visible: fit_card()
	if get_viewport().gui_is_dragging(): card.hide(); bag.queue_redraw(); return
	var at:=bag.get_local_mouse_position(); var i: int=bag.index_at(at) if Rect2(Vector2.ZERO,bag.size).has_point(at) else -1
	if hover_index!=i:
		hover_index=i; bag.queue_redraw()
		if i>=0: show_bag_item(i)
		elif not pinned and (not is_instance_valid(service) or shown_key.begins_with("inventory:")): card.hide(); shown_key=""

class ResourceMeter extends Control:
	var ui: CanvasLayer
	var kind := "life"
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _process(_delta: float) -> void:
		queue_redraw()
	func _draw() -> void:
		if not is_instance_valid(ui) or not is_instance_valid(ui.player): return
		var stats: Dictionary=ui.player.stats()
		var maximum: float=maxf(1.0,float(stats.max_hp if kind=="life" else stats.max_mp))
		var current: float=clampf(float(ui.player.hp if kind=="life" else ui.player.mp),0.0,maximum)
		var tint: Color=Color("ac5148") if kind=="life" else Color("4a7eb5")
		draw_rect(Rect2(Vector2.ZERO,size),Color("070b11"))
		draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*current/maximum,size.y)),tint)
		draw_rect(Rect2(Vector2.ZERO,size),Color("a38a62"),false,1.0)

class Frame extends Control:
	var backplate: Texture2D
	func _ready() -> void:
		if ResourceLoader.exists("res://assets/ui/inventory_backplate.jpg"): backplate=load("res://assets/ui/inventory_backplate.jpg")
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("171818"))
		if backplate!=null: draw_texture_rect(backplate,Rect2(Vector2.ZERO,size),false)
		# Shallow stone courses and narrow metal frame are original vector artwork.
		for y in range(8,int(size.y)-8,36):
			draw_line(Vector2(8,y),Vector2(size.x-8,y),Color(1,1,1,0.018),1)
			for x in range(12,int(size.x)-8,76): draw_line(Vector2(x+(36 if y%72 else 0),y),Vector2(x+(36 if y%72 else 0),y+35),Color(0,0,0,0.13),1)
		for inset in [1,5,10]: draw_rect(Rect2(Vector2.ONE*inset,size-Vector2.ONE*inset*2),Color("877052") if inset==5 else Color("39342c"),false,2)
		if backplate==null: draw_rect(Rect2(14,12,size.x-28,48),Color("27251f"))
		for y in [59,104,478,574,922,971]:
			draw_line(Vector2(28,y),Vector2(size.x-28,y),Color("534735"),1.0)
		for x in [22,size.x-22]:
			for y in [22,106,size.y-22]:
				var pts:=PackedVector2Array([Vector2(x,y-7),Vector2(x+5,y),Vector2(x,y+7),Vector2(x-5,y)])
				draw_colored_polygon(pts,Color("b19a70"))
		# Faint body-shaped tracery behind the equipment, kept out of hit testing.
		var c:=Vector2(336,318)
		for r in [115.0,133.0]: draw_arc(c,r,0,TAU,64,Color(0.7,0.62,0.45,0.075),1.0,true)
		for d in [-1,1]:
			draw_polyline(PackedVector2Array([c+Vector2(0,-165),c+Vector2(d*74,-58),c+Vector2(d*58,96),c+Vector2(0,153)]),Color(0.7,0.62,0.45,0.09),2.0,true)

class EquipmentSlot extends Button:
	var ui: CanvasLayer
	var shell: Control
	var slot: String
	func _ready() -> void:
		flat=true; clip_contents=true; focus_mode=Control.FOCUS_NONE
		pressed.connect(func() -> void:
			if ui.selected>=0: ui._equip(slot)
			elif Input.is_key_pressed(KEY_CTRL): unequip()
			else: shell.show_equipped(slot))
		mouse_entered.connect(queue_redraw); mouse_exited.connect(queue_redraw)
	func unequip() -> void:
		if ui.player.unequip_item(slot): ui.refresh_inventory()
		else: ui._status("No room in the backpack, or the slot is empty.")
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT: unequip(); accept_event()
	func _draw() -> void:
		var r:=Rect2(Vector2.ZERO,size); draw_rect(r,Color("090c10")); draw_rect(r.grow(-3),Color("171a20"))
		var item: Variant=ui.player.gear.get(slot)
		var edge:=Color("756046")
		if item is Dictionary:
			edge=Color(String(ui.GD.RARITY[int(item.rarity)].color)).lerp(Color("86714f"),0.5)
			var image: Texture2D=ui._item_icon(item)
			draw_texture_rect(image,art_rect(item),false)
		else:
			var icon_id: String={"weapon":"staff" if ui.player.class_id=="mage" else "weapon","offhand":"focus" if ui.player.class_id=="mage" else "offhand","armor":"robe" if ui.player.class_id=="mage" else "armor","ring1":"ring","ring2":"ring"}.get(slot,slot)
			var extent:=minf(size.x-14,size.y-24)
			draw_texture_rect(ui._icon(icon_id),Rect2((size-Vector2.ONE*extent)/2-Vector2(0,5),Vector2.ONE*extent),false,Color(0.8,0.75,0.65,0.14))
		var caption: String={"weapon":"MAIN HAND","offhand":"OFF HAND","armor":"BODY","ring1":"RING","ring2":"RING"}.get(slot,slot.to_upper())
		var f:=ThemeDB.fallback_font
		draw_string(f,Vector2(3,size.y-4),caption,HORIZONTAL_ALIGNMENT_CENTER,size.x-6,10,Color("928b7e"))
		if slot=="offhand" and ui.player.gear.weapon is Dictionary and ui.player.gear.weapon.slot=="staff":
			for y in range(6,int(size.y)-8,17): draw_line(Vector2(5,y),Vector2(size.x-5,minf(y+30,size.y-7)),Color(0.6,0.5,0.35,0.17),1)
		if is_hovered(): edge=Color("d5c09a")
		draw_rect(r,edge,false,2); draw_rect(r.grow(-4),Color("39332a"),false,1)
	func art_rect(item: Dictionary) -> Rect2:
		return ui.item_art_rect(item,Rect2(Vector2(4,4),size-Vector2(8,24)))
	func _get_tooltip(_at: Vector2) -> String:
		var item: Variant=ui.player.gear.get(slot)
		if item is Dictionary: return "%s\nClick: inspect · Right-click: unequip · Drag to bag" % item.name
		if slot=="offhand" and ui.player.gear.weapon is Dictionary and ui.player.gear.weapon.slot=="staff": return "Your staff occupies both hands. Equip a wand before adding a focus."
		return "Empty "+slot+" slot · Drop compatible equipment here"
	func _get_drag_data(_at: Vector2) -> Variant:
		var item: Variant=ui.player.gear.get(slot)
		if not item is Dictionary: return null
		shell.card.hide(); set_drag_preview(ui.item_drag_preview(item,shell.bag))
		return {"source":"equipment","slot":slot,"uid":item.uid,"grab":Vector2i.ZERO}
	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		if not data is Dictionary or data.get("source","")=="equipment" or not data.has("index") or not data.index is int or not data.has("uid"): return false
		var i:=int(data.index)
		return i>=0 and i<ui.player.inventory.size() and ui.player.inventory[i].uid==data.uid and ui.player.plan_equip(i,slot).ok
	func _drop_data(at: Vector2, data: Variant) -> void:
		if not _can_drop_data(at,data): return
		ui.selected=int(data.index); ui._equip(slot)

func fit_card() -> void:
	if not is_instance_valid(card): return
	var height := clampf(ui.inspector.get_combined_minimum_size().y+32,180,minf(690,(get_viewport_rect().size.y-40)/scale_factor))
	card_scroll.custom_minimum_size = Vector2(314,0)
	card.size=Vector2(350,height)
	card.position=Vector2(maxf(10,dock.position.x-366*scale_factor),maxf(16,(get_viewport_rect().size.y-height*scale_factor)/2))
func _notification(what: int) -> void:
	if what==NOTIFICATION_DRAG_END and is_instance_valid(bag):
		unpin(); hover_index=-2

func make_frame() -> Control: return Frame.new()
func show_external_item(item: Dictionary, source_id: String, pin := false) -> void:
	if pinned and not pin: return
	if pin: pinned=true; ui.selected=-1; bag.queue_redraw()
	var key:=source_id+":"+String(item.uid)
	if shown_key==key and card.visible: return
	shown_key=key; ui.fill_inventory_details(item,SYS.default_slot(item),-1,source_id); card.show()
