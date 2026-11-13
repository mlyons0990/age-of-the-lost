extends "res://scripts/legacy_hud.gd"
## Systems UI: inventory, spellbook, town services and pause. World simulation
## pauses behind every modal; no HUD click is allowed to steer the character.
const Town := preload("res://scripts/town_actions.gd")
var inventory_query := ""
var stash_query := ""
var stash_category := "all"
var shop_query := ""
var shop_mode := "stock"
var service_notice := ""
var loot_hint: Label
var save_strip: PanelContainer
var save_message: Label
var save_retry: Button

const Resolver := preload("res://scripts/effect_resolver.gd")
const Systems := preload("res://scripts/systems.gd")
const Mastery := preload("res://scripts/mastery_data.gd")
var inventory_shell: Control
var creation_class := "warrior"
var creation_buttons := {}
var creation_details: VBoxContainer
var icon_cache := {}
var page := ""
var selected := -1
var selected_spell := "cleave"
var inspector: VBoxContainer
var status_label: Label
var bag_view: Control
var gear_buttons: Array = []
var overlay_buttons: Array = []

func _exit_tree() -> void:
	ART.icons.clear()
	ART.portraits.clear()
	ART.tiles.clear()

func _ready() -> void:
	super._ready()
	draw_ctl.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	var row: HBoxContainer
	for child in get_children():
		if child is HBoxContainer: row = child; break
	row.add_child(_button("Spellbook [K]", func() -> void: open_page("spells")))
	row.add_child(_button("Pause [Esc]", func() -> void: open_page("pause")))
	row.add_child(_button("Mastery [M]", func() -> void: open_page("mastery")))
	row.add_child(_button("Cantor Trial [T]", func() -> void: open_page("trial")))
	row.add_child(_button("Nearby loot [N]",func() -> void: open_page("loot")))
	loot_hint=_label("",17,Color("edce91")); loot_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(loot_hint)
	# Transparent buttons intercept clicks over the drawn action bar.
	for i in 6:
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		b.pressed.connect(func() -> void:
			if get_tree().paused: return
			if i == 5: player.drink_potion()
			else: player.use_skill(["basic", "s1", "s2", "s3", "s4"][i], player.last_world_aim))
		add_child(b)
		overlay_buttons.append(b)
	get_viewport().size_changed.connect(_layout_bar)
	_layout_bar()
	save_strip=PanelContainer.new(); save_strip.z_index=100
	save_strip.add_theme_stylebox_override("panel",_style(Color("e8b578"),Color("291d20")))
	add_child(save_strip)
	var save_row:=HBoxContainer.new(); save_strip.add_child(save_row)
	save_message=_label("",16,Color("ffe4b7")); save_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	save_message.size_flags_horizontal=Control.SIZE_EXPAND_FILL; save_row.add_child(save_message)
	save_retry=_button("Retry save [F5]",func() -> void: main.save_game()); save_retry.focus_mode=Control.FOCUS_ALL; save_row.add_child(save_retry)
	save_strip.hide()

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(loot_hint):
		var count: int=main.nearby_loot(false).size()
		loot_hint.visible=count>0 and char_panel==null and start_panel==null and choice_panel==null and death_panel==null
		loot_hint.text="%d nearby drops · F collect nearest · N inspect" % count
		loot_hint.position=Vector2(24,get_viewport().get_visible_rect().size.y-165)
	if not is_instance_valid(save_strip): return
	var message: String=main.save_error if not main.save_error.is_empty() else (main.save_notice if main.save_blocked else main.save_warning)
	save_strip.visible=not message.is_empty()
	if save_strip.visible:
		save_strip.position=Vector2(24,82); save_strip.size=Vector2(minf(760,get_viewport().get_visible_rect().size.x-48),0)
		save_message.text=message; save_retry.disabled=main.save_blocked

func _layout_bar() -> void:
	var sz := get_viewport().get_visible_rect().size
	var x0 := (sz.x - 460.0) / 2.0
	for i in overlay_buttons.size():
		overlay_buttons[i].position = Vector2(x0 + i * 76 + (12 if i == 5 else 0), sz.y - 118)
		overlay_buttons[i].size = Vector2(68, 68)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if start_panel!=null or choice_panel!=null or death_panel!=null or not inventory_active(): return
		var shell: Control=inventory_shell
		if not is_instance_valid(shell): return
		if get_viewport().gui_get_focus_owner() is LineEdit and event.button_index!=JOY_BUTTON_B: return
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT: shell.focus_step(-1,0)
			JOY_BUTTON_DPAD_RIGHT: shell.focus_step(1,0)
			JOY_BUTTON_DPAD_UP: shell.focus_step(0,-1)
			JOY_BUTTON_DPAD_DOWN: shell.focus_step(0,1)
			JOY_BUTTON_A: shell.focus_inspect()
			JOY_BUTTON_X: shell.focus_inspect(true)
			JOY_BUTTON_LEFT_SHOULDER: shell.set_tab("equipment")
			JOY_BUTTON_RIGHT_SHOULDER: shell.set_tab("character")
			JOY_BUTTON_B:
				var current_focus: Control=get_viewport().gui_get_focus_owner()
				if current_focus is LineEdit: current_focus.release_focus()
				else: close_page()
			_: return
		get_viewport().set_input_as_handled(); return
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_F5:
		main.save_game(); get_viewport().set_input_as_handled(); return
	if start_panel != null or choice_panel != null or death_panel != null: return
	var focus:=get_viewport().gui_get_focus_owner()
	if focus==save_retry and event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
		main.save_game(); get_viewport().set_input_as_handled(); return
	if focus is LineEdit:
		if event.keycode==KEY_ESCAPE: focus.release_focus(); get_viewport().set_input_as_handled()
		return
	if inventory_active() and event.ctrl_pressed and event.keycode==KEY_F:
		inventory_shell.search.grab_focus(); inventory_shell.search.select_all(); get_viewport().set_input_as_handled(); return
	if inventory_active() and is_instance_valid(inventory_shell):
		var shell: Control=inventory_shell
		match event.keycode:
			KEY_LEFT: shell.focus_step(-1,0)
			KEY_RIGHT: shell.focus_step(1,0)
			KEY_UP: shell.focus_step(0,-1)
			KEY_DOWN: shell.focus_step(0,1)
			KEY_ENTER, KEY_KP_ENTER: shell.focus_inspect(event.shift_pressed)
			KEY_TAB: shell.switch_tab()
			_: pass
		if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_ENTER,KEY_KP_ENTER,KEY_TAB]:
			get_viewport().set_input_as_handled(); return
	match event.keycode:
		KEY_ESCAPE:
			if char_panel != null: close_page()
			else: open_page("pause")
		KEY_I:
			if inventory_active() and is_instance_valid(inventory_shell) and inventory_shell.tab=="character": inventory_shell.set_tab("equipment")
			else: toggle_character()
		KEY_C:
			if inventory_active() and is_instance_valid(inventory_shell) and inventory_shell.tab=="character": close_page()
			else:
				if not inventory_active(): open_page("inventory")
				if is_instance_valid(inventory_shell): inventory_shell.set_tab("character")
		KEY_N:
			if page=="loot": close_page()
			else: open_page("loot")
		KEY_K, KEY_B:
			if page == "spells": close_page()
			else: open_page("spells")
		KEY_T:
			if page == "trial": close_page()
			else: open_page("trial")
		KEY_M:
			if page == "mastery": close_page()
			else: open_page("mastery")
		_ : return
	get_viewport().set_input_as_handled()

func _unhandled_input(_event: InputEvent) -> void:
	pass # All modal shortcuts are handled before world input.

func toggle_character() -> void:
	if inventory_active(): close_page()
	else: open_page("inventory")

func close_page() -> void:
	if main.dialogue != null: main.dialogue.stop("merchant")
	inventory_shell = null
	if char_panel != null:
		char_panel.queue_free()
		char_panel = null
	page = ""
	main.check_choice.call_deferred()
	player.mouse_held = false
	_refresh_pause()

func open_page(kind: String) -> void:
	if main.combat_active() and kind in ["stash","merchant","lore","loot"]:
		toast("Finish combat before opening nearby loot. F can collect within reach." if kind=="loot" else "Town services wait until combat ends.",Color("ffc28e"),true)
		return
	if start_panel != null or choice_panel != null or death_panel != null: return
	close_page()
	page = kind
	selected = -1
	if kind in ["inventory","stash","merchant","loot"]:
		inventory_shell = load("res://scripts/inventory_panel.gd").new()
		inventory_shell.ui = self; char_panel = inventory_shell; add_child(inventory_shell)
		player.path = PackedVector2Array(); player.target = null; player.mouse_held = false
		_refresh_pause()
		if kind == "merchant": main.dialogue.play_line("quartermaster_greeting")
		return
	var m := _modal()
	char_panel = m[0]
	var box: VBoxContainer = m[1]
	box.custom_minimum_size = Vector2(1100, 0)
	box.add_child(_label({"inventory": "EQUIPMENT & INVENTORY", "spells": "THE GRIMOIRE", "stash": "WAYFARER'S STASH", "merchant": "PLAZA QUARTERMASTER", "lore": "A MEMORY IN THE STONE", "board": "CROWNSFALL NOTICEBOARD", "pause": "AGE OF THE LOST", "mastery":"ABILITY MASTERY", "trial":"THE UNWRITTEN CANTOR"}.get(kind, kind), 32, GOLD))
	box.add_child(_label("%s  /  LEVEL %d %s  /  %d GOLD" % [player.hero_name, player.level, player.title().to_upper(), player.gold], 16, Color("9eabc1")))
	match kind:
		"spells": _spells_page(box)
		"lore": _lore_page(box)
		"mastery": _mastery_page(box)
		"trial": _trial_page(box)
		"board":
			box.add_child(_label(main.quest_title(), 28, GOLD))
			box.add_child(_label(main.quest_text(), 20))
			box.add_child(_label("Explore the plaza, recover a stone memory, equip your discoveries,\nthen open the Scar when you are ready.", 18))
			box.add_child(_button("Read the Cantor trial briefing [T]",func() -> void: open_page("trial")))
		"pause":
			box.add_child(_button("Dialogue voices: " + ("On" if main.dialogue.voice_enabled else "Off"), func() -> void:
				main.dialogue.set_voice_enabled(not main.dialogue.voice_enabled); open_page("pause"), Vector2(0,42)))
			var volume_row := HBoxContainer.new(); box.add_child(volume_row)
			var volume_label := _label("Voice volume: %d%%" % roundi(main.dialogue.voice_volume*100),18)
			volume_label.custom_minimum_size.x = 190; volume_row.add_child(volume_label)
			var voice_slider := HSlider.new(); voice_slider.name = "VoiceVolume"
			voice_slider.min_value = 0; voice_slider.max_value = 100; voice_slider.step = 5
			voice_slider.value = main.dialogue.voice_volume*100; voice_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			voice_slider.value_changed.connect(func(value: float) -> void:
				main.dialogue.set_voice_volume(value/100); volume_label.text = "Voice volume: %d%%" % roundi(value))
			volume_row.add_child(voice_slider)
			box.add_child(_button("Dialogue subtitles: " + ("On" if main.dialogue.subtitles_enabled else "Off"), func() -> void:
				main.dialogue.set_subtitles(not main.dialogue.subtitles_enabled); open_page("pause"), Vector2(0,42)))
			box.add_child(_button("Sound effects: " + ("Off" if main.sound.muted else "On"), func() -> void:
				main.sound.set_muted(not main.sound.muted)
				open_page("pause"), Vector2(0, 42)))
			box.add_child(_label("Crownsfall / Systems expansion\n\nLMB: move or attack · Shift+LMB: first equipped skill\nRMB / 1 / 2 / 3 / 4: skills · Q: potion\nE: nearby service · I: equipment · C: character · K/B: spellbook\nR: training Scar · F11: fullscreen · F3: navigation outline\nF6: gain a level (development shortcut)", 20))
			box.add_child(_button("Save and quit", func() -> void:
				main.request_exit(), Vector2(0, 42)))
			if not main.save_error.is_empty() or main.save_blocked:
				box.add_child(_label("Your current session could not be saved. Retry with F5, or leave and lose unsaved progress.",17,Color("ffd3a1")))
				box.add_child(_button("Leave without saving",func() -> void: main.quit_game(),Vector2(0,42)))
	status_label = _label("", 16, Color("aabbd2"))
	box.add_child(status_label)
	box.add_child(_button("Return to Crownsfall [Esc]", close_page, Vector2(0, 42)))
	player.path = PackedVector2Array()
	player.target = null
	player.mouse_held = false
	_refresh_pause()

func _row(box: VBoxContainer) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	return row

func _icon(id: String) -> Texture2D:
	return ART.action_icon(id)

func _item_icon(item: Dictionary) -> Texture2D:
	return _item_portrait(item)

const PHASE_A_VARIANTS := {
	"Crownfall Aegis": {"slot":"offhand", "id":"phase_a/crownfall_aegis"},
	"Chronicle Codex": {"slot":"focus", "id":"phase_a/chronicle_codex"},
	"Emberglass Focus": {"slot":"focus", "id":"phase_a/emberglass_focus"},
	"Oathkeeper Signet": {"slot":"ring", "id":"phase_a/oathkeeper_signet"},
	"Veilthorn Band": {"slot":"ring", "id":"phase_a/veilthorn_band"},
	"Wayfarer's Locket": {"slot":"amulet", "id":"phase_a/wayfarers_locket"},
	"Crownwarden Cuirass": {"slot":"armor","id":"phase_a_armor/crownwarden_cuirass"},
	"Epochweave Robe": {"slot":"robe","id":"phase_a_armor/epochweave_robe"},
	"Bastion Sallet": {"slot":"helm","id":"phase_a_armor/bastion_sallet"},
	"Veilbound Hood": {"slot":"hood","id":"phase_a_armor/veilbound_hood"},
	"Dawnsteel Gauntlets": {"slot":"gloves","id":"phase_a_armor/dawnsteel_gauntlets"},
	"Wayfarer's Greaves": {"slot":"boots","id":"phase_a_armor/wayfarer_greaves"},
}
func _item_portrait(item: Dictionary) -> Texture2D:
	# Named variant illustrations do not modify the authoritative equipment IDs,
	# footprint, class rules or save schema. Ordinary gear keeps its existing art.
	if not item.has("unique_id"):
		var selected: Variant = PHASE_A_VARIANTS.get(String(item.get("name", "")), {})
		if selected is Dictionary and String(item.get("slot", "")) == String(selected.get("slot", "")):
			return ART.inventory_portrait(String(selected.id))
	return ART.inventory_portrait(String(item.get("unique_id",item.get("slot","ring"))))

func action_art(button: Button, id: String) -> Button:
	button.icon=_icon("ui_"+id)
	button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",24)
	button.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	return button

func icon_label(text: String, id: String, font_size: int, color: Color) -> HBoxContainer:
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",8)
	var art:=TextureRect.new(); art.texture=_icon("ui_"+id)
	art.custom_minimum_size=Vector2(24,24); art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE; row.add_child(art)
	var caption:=_label(text,font_size,color); caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(caption)
	return row

func _bag(parent: Control, source: Array, callback: Callable) -> Control:
	var grid := BagGrid.new()
	grid.ui = self
	grid.source = source
	grid.chosen = callback
	grid.custom_minimum_size = Vector2(440, 264)
	parent.add_child(grid)
	return grid

func inventory_active() -> bool: return page in ["inventory","stash","merchant","loot"] and is_instance_valid(inventory_shell)

func refresh_inventory() -> void:
	var kind:=page if page in ["inventory","stash","merchant","loot"] else "inventory"
	var tab: String=inventory_shell.tab if is_instance_valid(inventory_shell) else "equipment"
	var selected_cell: Vector2i=inventory_shell.focus_cell if is_instance_valid(inventory_shell) else Vector2i.ZERO
	var keyboard_was_active: bool=inventory_shell.keyboard_mode if is_instance_valid(inventory_shell) else false
	open_page(kind)
	if is_instance_valid(inventory_shell):
		inventory_shell.set_tab(tab)
		inventory_shell.focus_cell=selected_cell
		inventory_shell.keyboard_mode=keyboard_was_active
		inventory_shell.bag.queue_redraw()

func town_state() -> Dictionary:
	return {"inventory":player.inventory,"stash":player.stash,"stock":main.merchant_stock,"buyback":main.buyback_stock,"gold":player.gold,"potions":player.potions}

func town_action(action: String, uid := "", cell: Variant=null) -> bool:
	if player.dead or main.combat_active() or main.save_blocked:
		_status("Town transactions require a living Wayfarer outside combat and a writable save."); return false
	if (action in ["deposit","withdraw","deposit_matching"] and page!="stash") or (action in ["buy","sell","buyback","potion"] and page!="merchant"):
		_status("Open the appropriate town service first."); return false
	var result:=Town.plan(town_state(),action,uid,cell,inventory_query)
	if not result.ok: _status(result.reason); return false
	if not main.persist_changes({"inventory":result.state.inventory,"stash":result.state.stash,"merchant_stock":result.state.stock,"buyback_stock":result.state.buyback,"gold":result.state.gold,"potions":result.state.potions}):
		_status(main.save_error); return false
	player.inventory=result.state.inventory; player.stash=result.state.stash
	main.merchant_stock=result.state.stock; main.buyback_stock=result.state.buyback
	player.gold=int(result.state.gold); player.potions=int(result.state.potions)
	service_notice=result.reason; main.sound.play_cue("pickup"); refresh_inventory(); _status(service_notice)
	return true

func collect_loot(uid: String) -> bool:
	if page!="loot" or main.combat_active(): _status("Open nearby loot outside combat first."); return false
	var success: bool=main.collect_drop(uid)
	refresh_inventory(); _status(main.loot_notice)
	return success

func quick_bag_action(index: int) -> void:
	if index<0 or index>=player.inventory.size(): return
	if page=="stash": town_action("deposit",player.inventory[index].uid)
	elif page=="merchant": town_action("sell",player.inventory[index].uid)

func _status(message: String) -> void:
	if is_instance_valid(status_label): status_label.text = message
	if inventory_active() and is_instance_valid(inventory_shell.service): inventory_shell.service.set_notice(message)

func _inspect(index: int) -> void:
	if is_instance_valid(inventory_shell): inventory_shell.show_bag_item(index,true)

func item_art_rect(item: Dictionary, bounds: Rect2) -> Rect2:
	# Fit the footprint-shaped illustration without stretching its silhouette.
	var texture_size:=_item_portrait(item).get_size()
	var available:=bounds.grow(-3)
	var factor:=minf(available.size.x/texture_size.x,available.size.y/texture_size.y)
	var extent:=texture_size*maxf(0,factor)
	return Rect2(bounds.get_center()-extent/2,extent)

func item_drag_preview(item: Dictionary, grid: Control=null, grab_pixels:=Vector2.ZERO) -> Control:
	# Drag previews live at viewport level, outside the scaled inventory panel.
	# Use the source grid's effective cell size and retain the picked pixel.
	var scale_pixels:=grid.get_global_transform_with_canvas().get_scale().abs() if grid!=null else Vector2.ONE
	var cell_pixels: Vector2=scale_pixels*(grid.cell_size if grid!=null else 50.0)
	var preview:=Control.new(); preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	preview.size=Vector2(Systems.footprint(item))*cell_pixels
	preview.custom_minimum_size=preview.size; preview.modulate.a=0.88
	var sprite:=ItemDragSprite.new(); sprite.ui=self; sprite.item=item.duplicate(true)
	sprite.position=-grab_pixels*scale_pixels; sprite.size=preview.size; preview.add_child(sprite)
	return preview

class ItemDragSprite extends Control:
	var ui: CanvasLayer
	var item: Dictionary
	func _ready() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var rect:=Rect2(Vector2.ZERO,size).grow(-1)
		var color:=Color(String(ui.GD.RARITY[int(item.rarity)].color))
		draw_rect(rect,Color("131b26").lerp(color,0.11))
		draw_texture_rect(ui._item_portrait(item),ui.item_art_rect(item,rect),false)
		draw_rect(rect,color,false,2.0)

func fill_inventory_details(item: Dictionary, slot: String, index: int, source_id := "inventory") -> void:
	for child in inspector.get_children(): inspector.remove_child(child); child.queue_free()
	var col := Color(String(GD.RARITY[int(item.rarity)].color))
	var title := icon_label(item.name,"inspect",23,col); inspector.add_child(title)
	inspector.add_child(_label(("UNIQUE" if item.has("unique_id") else GD.RARITY[int(item.rarity)].name.to_upper())+" · "+str(item.slot).capitalize(),16,col))
	inspector.add_child(HSeparator.new())
	inspector.add_child(_label("Requires level %d · %s" % [item.level,player.class_id.capitalize() if Systems.class_allows(item,player.class_id) else "Cannot equip on this class"],16,Color("b7afa0")))
	var dimensions: Vector2i = Systems.footprint(item)
	var footprint_label:=_label("Inventory footprint: %d × %d cells (width × height)" % [dimensions.x,dimensions.y],15,Color("bdac91"))
	footprint_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; inspector.add_child(footprint_label)
	var line := GD.item_line(item)
	for stat in line.split(", "):
		if stat != "": inspector.add_child(_label(stat,18,Color("a7b9d6")))
	if item.has("unique_id"):
		var unique_text := _label("Emberwake: 0.4s aura pulses; damage and cost ×0.8. Actual pulse hits extend an existing burn by 0.15s, up to 4s. Requires invested Ember Aura.",16,Color("d7a469"))
		unique_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; inspector.add_child(unique_text)
	inspector.add_child(HSeparator.new())
	if index>=0:
		var targets: Array = [slot,"ring2"] if item.slot=="ring" else [slot]
		for target in targets:
			var plan: Dictionary=player.plan_equip(index,target)
			if plan.ok:
				var before: Dictionary=player.stats(); var after:=Systems.derive(player.level,plan.gear,player.mods(),player.class_id)
				inspector.add_child(icon_label("IF EQUIPPED · "+String(target).to_upper(),"compare",15,GOLD))
				var replacements: String=""
				for old_slot in player.gear:
					var old_item: Variant=player.gear.get(old_slot)
					var new_item: Variant=plan.gear.get(old_slot)
					if old_item is Dictionary and (not new_item is Dictionary or String(old_item.uid)!=String(new_item.uid)):
						replacements += (", " if replacements!="" else "")+String(old_item.name)
				if replacements!="":
					var warning:=_label("Moves to backpack: "+replacements,14,Color("d3b68b"))
					warning.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; inspector.add_child(warning)
				for row in [["Power",after.spell_power-before.spell_power if player.class_id=="mage" else after.dmg-before.dmg],["Life",after.max_hp-before.max_hp],["Mana",after.max_mp-before.max_mp],["Armour",after.armor-before.armor],["Crit %",(after.crit-before.crit)*100]]:
					inspector.add_child(_label("%s   %+.2f" % [row[0],row[1]],17,Color("a5c993") if row[1]>0 else (Color("d48c84") if row[1]<0 else Color("97938b"))))
			var action := _button("Equip → "+String(target).capitalize(),func() -> void: selected=index; _equip(target),Vector2(0,36))
			action_art(action,"equip"); action.disabled=not plan.ok; action.tooltip_text=plan.reason; inspector.add_child(action)
			if not plan.ok:
				var reason:=_label(plan.reason,16,Color("d48c84")); reason.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; inspector.add_child(reason)
		if page=="stash": inspector.add_child(action_art(_button("Deposit in stash",func() -> void: town_action("deposit",item.uid),Vector2(0,36)),"stash"))
		elif page=="merchant": inspector.add_child(action_art(_button("Sell for %d gold" % Town.sale_price(item),func() -> void: town_action("sell",item.uid),Vector2(0,36)),"merchant"))
	elif source_id!="inventory":
		var plan: Dictionary=player.preview_equipment(item,slot)
		if plan.ok:
			var before: Dictionary=player.stats(); var after:=Systems.derive(player.level,plan.gear,player.mods(),player.class_id)
			inspector.add_child(icon_label("IF EQUIPPED · "+slot.to_upper(),"compare",15,GOLD))
			for row in [["Power",after.spell_power-before.spell_power if player.class_id=="mage" else after.dmg-before.dmg],["Life",after.max_hp-before.max_hp],["Mana",after.max_mp-before.max_mp],["Armour",after.armor-before.armor]]:
				inspector.add_child(_label("%s   %+.2f" % [row[0],row[1]],17,Color("a5c993") if row[1]>0 else (Color("d48c84") if row[1]<0 else Color("97938b"))))
		else:
			var reason:=_label(plan.reason,16,Color("d48c84")); reason.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; inspector.add_child(reason)
		if source_id.begins_with("ground:"): inspector.add_child(action_art(_button("Collect to backpack",func() -> void: collect_loot(source_id.trim_prefix("ground:")),Vector2(0,36)),"pickup"))
		elif source_id=="stash": inspector.add_child(action_art(_button("Withdraw to backpack",func() -> void: town_action("withdraw",item.uid),Vector2(0,36)),"transfer"))
		else:
			var price:=Town.sale_price(item)*(3 if source_id=="stock" else 1)
			var buy:=_button(("Buy" if source_id=="stock" else "Buy back")+" for %d gold" % price,func() -> void: town_action("buy" if source_id=="stock" else "buyback",item.uid),Vector2(0,36))
			action_art(buy,"merchant"); buy.disabled=player.gold<price; inspector.add_child(buy)
	else:
		inspector.add_child(_label("CURRENTLY EQUIPPED · "+slot.to_upper(),15,GOLD))
		inspector.add_child(action_art(_button("Unequip to backpack",func() -> void:
			if player.unequip_item(slot): refresh_inventory()
			else: _status("No room in the backpack."),Vector2(0,38)),"inventory"))
	inspector.add_child(_label("Value: %d gold" % int(item.get("value",5)),16,Color("b7a37b")))
	if is_instance_valid(inventory_shell): inventory_shell.fit_card.call_deferred()

func _equip(slot: String) -> void:
	if player.equip_item(selected, slot): refresh_inventory()
	else: _status("Cannot equip: check class, slot, two-hand rules, level and backpack room.")

func _spells_page(box: VBoxContainer) -> void:
	box.add_child(_label("Exactly five equipped abilities. Reassigning an ability keeps its remaining cooldown.", 17, Color("b3c4dc")))
	var row := _row(box)
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size = Vector2(490, 610); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; row.add_child(scroll)
	var list := VBoxContainer.new(); list.custom_minimum_size.x = 470; scroll.add_child(list)
	var spells := GD.visible_spells(player.class_id)
	for id in spells:
		var sk: Dictionary = player.known_definition(id)
		var available := GD.unlocked(player, id)
		var b := _button(sk.name + ("" if available else "  /  LOCKED"), func() -> void:
			selected_spell = id
			open_page("spells"), Vector2(460, 40))
		b.icon = _icon(String(sk.get("variant",id))); b.expand_icon = true; b.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		b.add_theme_constant_override("icon_max_width", 32)
		b.add_theme_color_override("font_color", GOLD if available else Color("8793a5"))
		list.add_child(b)
	var detail_scroll := ScrollContainer.new(); detail_scroll.custom_minimum_size = Vector2(580,610); detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; row.add_child(detail_scroll)
	var details := VBoxContainer.new(); details.custom_minimum_size.x = 560; detail_scroll.add_child(details)
	if not spells.has(selected_spell): selected_spell = String(GD.CLASSES[player.class_id].starting[0])
	var sk: Dictionary = player.known_definition(selected_spell)
	var art := TextureRect.new(); art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR; art.texture = _icon(String(sk.get("variant",sk.id))); art.custom_minimum_size = Vector2(128, 128); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	details.add_child(art)
	details.add_child(_label(sk.name, 28, GOLD))
	var desc := _label(sk.desc, 18); desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; desc.custom_minimum_size.x = 530; details.add_child(desc)
	var timing := "%d mana / %.2fs cooldown / %.2fs cast" % [sk.mana, sk.cd * (1 - clampf(player.mods().cdr, 0, 0.6)), float(sk.get("cast_time", 0))]
	details.add_child(_label(timing, 17, Color("b8c9e2")))
	var effect_text := _label(Resolver.summary(sk, player.stats(), player.damage_multiplier(sk)), 17)
	effect_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; effect_text.custom_minimum_size.x = 520; details.add_child(effect_text)
	details.add_child(_label("Required level: %d" % int(sk.get("level", 1)), 16))
	for spec_id in GD.SPECS:
		if GD.SPECS[spec_id].skill.id == sk.id: details.add_child(_label("Requires specialization: " + String(GD.SPECS[spec_id].name), 17, Color("a9b7e8")))
	if sk.has("discovery"): details.add_child(_label("Requires: recover the plaza stone memory [E].", 17, Color("a9b7e8")))
	var allowed := GD.unlocked(player, sk.id)
	for i in 5:
		var equipped: Dictionary = spells.get(player.hotbar[i], {})
		var b := _button("Equip → %s  [%s]" % [["LMB", "1 / RMB", "2", "3", "4"][i], equipped.get("name", "Empty")], func() -> void:
			player.assign_skill(i, sk.id)
			open_page("spells"), Vector2(0, 38))
		b.disabled = not allowed
		details.add_child(b)
	details.add_child(_label("Recovered techniques recall forgotten eras.\nInspect future abilities and discover their requirements.", 15, Color("9eabc1")))

func _lore_page(box: VBoxContainer) -> void:
	box.add_child(_label("A different crest lies beneath the familiar stone.\nFor a moment, you hear footsteps that have no owner.\n\nThe city remembers a street that is no longer here.", 24, Color("cad6f4")))
	if not player.discoveries.has("first_echo"):
		box.add_child(action_art(_button("Lorecast: recover Echo Strike", func() -> void:
			if not player.discoveries.has("first_echo"):
				player.discoveries.append("first_echo")
				main.save_game()
			open_page("lore")),"interact"))
	else: box.add_child(_label("DISCOVERY RECORDED\nEcho Strike is now available in the Grimoire. Equip it to a slot [K].", 20, GOLD))
	if player.class_id == "mage" and player.discoveries.has("first_echo"):
		box.add_child(_label("The recovered memory reveals Ember Aura mastery at level 40 [M].",17,GOLD))
		var craft := _button("Attune Emberwake Circlet · 250 gold · Mage level 40", func() -> void:
			var result: Dictionary = player.craft_circlet()
			open_page("lore"); _status(result.reason),Vector2(0,42))
		craft.disabled = player.crafted_uniques.has(Systems.UNIQUE_ID)
		action_art(craft,"blacksmith"); box.add_child(craft)
	box.add_child(_label("Some histories survive only in stone.", 16, Color("9eabc1")))

func _mastery_page(box: VBoxContainer) -> void:
	box.add_child(_label("ASHEN WARD / MASTERY",28,GOLD))
	if player.class_id != "mage":
		box.add_child(_label("This revision's mastery graph belongs to Mage. Warrior mastery remains future content.",18)); return
	var total := Mastery.earned(player.class_id,player.level)
	box.add_child(_label("%d AVAILABLE / %d EARNED · one point every five levels from 20 through 60" % [total-Mastery.spent(player.mastery),total],17,GOLD))
	box.add_child(_label("Recover the stone memory to unlock Ember Aura. Choose one branch.\nTown refunds are free and remove dependent nodes together; changing mastery stops active effects.",16,Color("a9bdd8")))
	if main.combat_active(): box.add_child(_label("Finish or retreat from combat before changing mastery.",17,Color("ffc28e")))
	var graph := MasteryGraph.new(); graph.ui = self; graph.custom_minimum_size = Vector2(1000,510); box.add_child(graph)
	graph.build()

class MasteryGraph extends Control:
	var ui: CanvasLayer
	const POS := {"ward_temper":Vector2(0,110),"ember_aura":Vector2(340,110),"cinder_bloom":Vector2(680,0),"siphon_embers":Vector2(680,230),"steady_flame":Vector2(340,330)}
	func build() -> void:
		for key in POS:
			var id: String = key
			var node: Dictionary = Mastery.NODES[id]
			var rank := int(ui.player.mastery.get(id,0))
			var panel := PanelContainer.new(); panel.position = POS[id]; panel.custom_minimum_size = Vector2(300,180)
			panel.add_theme_stylebox_override("panel",ui._style(GOLD if rank>0 else BRONZE,Color("101d32")))
			add_child(panel)
			var body := VBoxContainer.new(); panel.add_child(body)
			var heading := HBoxContainer.new(); heading.alignment = BoxContainer.ALIGNMENT_CENTER; body.add_child(heading)
			var art := TextureRect.new(); art.texture = ui._icon(id); art.custom_minimum_size = Vector2(32,32); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; heading.add_child(art)
			heading.add_child(ui._label(node.name,20,GOLD))
			body.add_child(ui._label("Rank %d/%d · %d points · Lv %d" % [rank,node.max_rank,node.cost,node.level],14))
			var description: Label = ui._label(node.desc,14,Color("b9cbe0")); description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; description.custom_minimum_size.x = 270; body.add_child(description)
			var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; body.add_child(row)
			var plan: Dictionary = Mastery.invest(ui.player.mastery,id,ui.player.class_id,ui.player.level,ui.player.discoveries)
			var buy: Button = ui._button("Invest",func() -> void: update_node(id,false),Vector2(122,32))
			buy.disabled = not plan.ok or ui.main.combat_active(); buy.tooltip_text = plan.reason; row.add_child(buy)
			var refund: Button = ui._button("Refund",func() -> void: update_node(id,true),Vector2(122,32))
			refund.disabled = rank<=0 or ui.main.combat_active(); refund.tooltip_text = "Refund one rank and any dependent nodes atomically."; row.add_child(refund)
	func update_node(id: String, refund: bool) -> void:
		var result: Dictionary = ui.player.change_mastery(id,refund)
		ui.open_page("mastery"); ui._status(result.reason)
	func _draw() -> void:
		for id in POS:
			for prerequisite in Mastery.NODES[id].requires:
				var a: Vector2 = POS[prerequisite]+Vector2(150,90)
				var b: Vector2 = POS[id]+Vector2(150,90)
				draw_line(a,b,Color("d7b66c") if ui.player.mastery.has(prerequisite) else Color("45526b"),3,true)

func _open_start() -> void:
	var modal := _modal()
	start_panel = modal[0]
	var box: VBoxContainer = modal[1]
	box.custom_minimum_size = Vector2(1080, 0)
	box.add_child(_label("AGE OF THE LOST", 40, GOLD))
	box.add_child(_label("Choose your path through Crownsfall", 21, Color("b6c8e4")))
	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Name your Wayfarer"
	name_edit.max_length = 16
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.custom_minimum_size = Vector2(420, 44)
	name_edit.add_theme_font_size_override("font_size", 21)
	box.add_child(name_edit)
	var row := _row(box)
	creation_buttons.clear()
	creation_class = "warrior"
	for id in GD.CLASSES:
		var data: Dictionary = GD.CLASSES[id]
		var card := VBoxContainer.new(); card.custom_minimum_size.x = 520; row.add_child(card)
		var b := _button(data.name + "  /  " + data.armor, func() -> void:
			creation_class = id
			_refresh_creation_details(), Vector2(500, 52))
		if id == "mage" and ResourceLoader.exists("res://assets/ui/mage_portrait.png"):
			b.icon = load("res://assets/ui/mage_portrait.png")
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 40)
		card.add_child(b); creation_buttons[id] = b
		var desc := _label(data.desc, 18, Color("c9d7e9")); desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(500, 70); card.add_child(desc)
		var paths := _label("Level 20 → Level 40\n" + String(data.paths).replace(" / ", "\n"), 17, Color("9eabc8"))
		paths.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; paths.custom_minimum_size.x = 500; card.add_child(paths)
	creation_details = VBoxContainer.new(); box.add_child(creation_details)
	_refresh_creation_details()
	box.add_child(_label("LMB: move or use primary skill  ·  1 / 2 / 3 / 4: active abilities  ·  Q: potion\nI: inventory  ·  K: Grimoire  ·  E: nearby services  ·  R: training Scar  ·  Esc: pause", 17, Color("9daec5")))
	var begin := func() -> void:
		if start_panel == null: return
		if not main.create_character(creation_class, name_edit.text): return
		start_panel.queue_free(); start_panel = null
		main.had_save = true
		_refresh_pause()
		main.save_game()
	box.add_child(_button("Enter Crownsfall", begin, Vector2(0, 48)))
	name_edit.text_submitted.connect(func(_text: String) -> void: begin.call())
	_refresh_pause()

func _refresh_creation_details() -> void:
	for id in creation_buttons:
		creation_buttons[id].add_theme_stylebox_override("normal", _style(GOLD if id == creation_class else BRONZE, Color("17243c") if id == creation_class else DARK))
	for child in creation_details.get_children(): child.queue_free()
	creation_details.add_child(_label("STARTING TECHNIQUES / " + String(GD.CLASSES[creation_class].name).to_upper(), 19, GOLD))
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 18)
	creation_details.add_child(row)
	for id in GD.CLASSES[creation_class].starting:
		if id == "": continue
		var col := VBoxContainer.new(); col.custom_minimum_size.x = 180; row.add_child(col)
		var art := TextureRect.new(); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.texture = _icon(id)
		art.custom_minimum_size = Vector2(96, 96); art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; col.add_child(art)
		col.add_child(_label(GD.spells()[id].name, 16))


class BagGrid extends Control:
	var ui: CanvasLayer
	var source: Array
	var chosen: Callable
	var cell_size:=44.0
	var container_id:="inventory"
	var query:=""
	var category:="all"
	func _ready() -> void:
		add_to_group("inventory_grid"); mouse_filter=Control.MOUSE_FILTER_STOP
	func matching(item: Dictionary) -> bool: return Town.matches(item,query,category)
	func index_at(at: Vector2) -> int:
		if at.x<0 or at.y<0: return -1
		for i in source.size():
			var it: Dictionary=source[i]
			if matching(it) and Rect2(Vector2(it.x,it.y)*cell_size,Vector2(Systems.footprint(it))*cell_size).has_point(at): return i
		return -1
	func item_for(data: Variant) -> Dictionary:
		if not data is Dictionary or not data.has("uid") or not data.uid is String: return {}
		var origin: String=String(data.get("source","inventory"))
		if origin=="equipment":
			var item: Variant=ui.player.gear.get(String(data.get("slot","")))
			return item if item is Dictionary and item.uid==data.uid else {}
		if not origin in ["inventory","stash"]: return {}
		var items: Array=ui.player.inventory if origin=="inventory" else ui.player.stash
		if not data.has("index") or not data.index is int or data.index<0 or data.index>=items.size(): return {}
		return items[data.index] if items[data.index].uid==data.uid else {}
	func _draw() -> void:
		for y in Systems.HEIGHT:
			for x in Systems.WIDTH:
				var r:=Rect2(x*cell_size,y*cell_size,cell_size,cell_size)
				draw_rect(r.grow(-1),Color("090c10")); draw_rect(r.grow(-1),Color("494335"),false,1)
		for i in source.size():
			var item: Dictionary=source[i]; var visible_match:=matching(item)
			var r:=Rect2(Vector2(item.x,item.y)*cell_size,Vector2(Systems.footprint(item))*cell_size).grow(-2)
			var col:=Color(String(ui.GD.RARITY[int(item.rarity)].color))
			draw_rect(r,Color("141a22").lerp(col,0.10))
			# Portraits are already shaped to the item's authoritative W×H cells.
			# A 1×3 sword now draws through all three vertical cells; a ring only
			# draws in its own 1×1 cell. Never render the old square icon here.
			draw_texture_rect(ui._item_portrait(item),ui.item_art_rect(item,r),false,Color.WHITE if visible_match else Color(1,1,1,0.18))
			draw_rect(r,col.darkened(0.25) if visible_match else Color("39382f"),false,1.5)
			if ui.inventory_active() and visible_match and ((container_id=="inventory" and ui.selected==i) or ui.inventory_shell.shown_key==container_id+":"+String(item.uid)): draw_rect(r.grow(-1),Color("e4c995"),false,2)
		if ui.inventory_active() and container_id=="inventory" and is_instance_valid(ui.inventory_shell) and ui.inventory_shell.keyboard_mode:
			var pos: Vector2=Vector2(ui.inventory_shell.focus_cell)*cell_size
			draw_rect(Rect2(pos,Vector2.ONE*cell_size).grow(-1),Color("f3d793"),false,3)
		if ui.inventory_active() and get_viewport().gui_is_dragging():
			var data: Variant=get_viewport().gui_get_drag_data(); var item:=item_for(data)
			if not item.is_empty():
				var at:=get_local_mouse_position()
				if not Rect2(Vector2.ZERO,Vector2(Systems.WIDTH,Systems.HEIGHT)*cell_size).has_point(at): return
				var cell:=drop_cell(at,data)
				var r:=Rect2(Vector2(cell)*cell_size,Vector2(Systems.footprint(item))*cell_size)
				var color:=Color("8fbf83") if _can_drop_data(at,data) else Color("c16d68")
				draw_rect(r,Color(color,0.24)); draw_rect(r,color,false,2)
	func _process(_delta: float) -> void:
		if get_viewport().gui_is_dragging(): queue_redraw()
	func _gui_input(event: InputEvent) -> void:
		if not event is InputEventMouseButton or not event.pressed: return
		var index:=index_at(event.position)
		if event.button_index==MOUSE_BUTTON_LEFT:
			if container_id=="inventory" and ui.inventory_active(): ui.inventory_shell.release_keyboard_cursor()
			if index>=0:
				if event.ctrl_pressed and ui.page in ["stash","merchant"]:
					if container_id=="stash": ui.town_action("withdraw",source[index].uid)
					else: ui.quick_bag_action(index)
				elif container_id=="inventory" and event.double_click and ui.inventory_active(): ui.selected=index; ui._equip(Systems.default_slot(source[index]))
				else: chosen.call(index)
			elif ui.inventory_active(): ui.inventory_shell.unpin()
			accept_event()
		elif event.button_index==MOUSE_BUTTON_RIGHT and index>=0 and ui.inventory_active():
			if container_id=="stash": ui.town_action("withdraw",source[index].uid)
			else: ui.selected=index; ui._equip(Systems.default_slot(source[index]))
			accept_event()
	func _get_tooltip(at: Vector2) -> String:
		if ui.inventory_active(): return ""
		var i:=index_at(at)
		return "Empty inventory cell" if i<0 else "%s\n%s\nLevel %d" % [source[i].name,ui.GD.item_line(source[i]),source[i].level]
	func _get_drag_data(at: Vector2) -> Variant:
		if not ui.inventory_active(): return null
		var i:=index_at(at)
		if i<0: return null
		set_drag_preview(ui.item_drag_preview(source[i],self,at-Vector2(source[i].x,source[i].y)*cell_size))
		return {"source":container_id,"index":i,"uid":source[i].uid,"grab":Vector2i(at/cell_size)-Vector2i(source[i].x,source[i].y)}
	func drop_cell(at: Vector2, data: Dictionary) -> Vector2i:
		return Vector2i(floori(at.x/cell_size),floori(at.y/cell_size))-Vector2i(data.get("grab",Vector2i.ZERO))
	func _can_drop_data(at: Vector2, data: Variant) -> bool:
		if not ui.inventory_active() or not data is Dictionary: return false
		if data.has("grab") and not data.grab is Vector2i: return false
		var item:=item_for(data)
		if item.is_empty(): return false
		var origin:=String(data.get("source","inventory")); var cell:=drop_cell(at,data)
		if origin=="equipment": return container_id=="inventory" and Systems.fits(source,item,cell)
		if origin==container_id: return Systems.fits(source,item,cell,item.uid)
		if ui.page!="stash": return false
		return Systems.fits(source,item,cell)
	func _drop_data(at: Vector2, data: Variant) -> void:
		if not _can_drop_data(at,data): return
		var cell:=drop_cell(at,data); var origin:=String(data.get("source","inventory"))
		if origin=="equipment":
			if ui.player.unequip_item(String(data.slot),cell): ui.refresh_inventory()
		elif origin!=container_id: ui.town_action("deposit" if container_id=="stash" else "withdraw",data.uid,cell)
		else:
			var next:=source.duplicate(true); next[data.index].x=cell.x; next[data.index].y=cell.y
			if ui.main.persist_changes({container_id:next}):
				source[data.index].x=cell.x; source[data.index].y=cell.y; queue_redraw()

func _trial_page(box: VBoxContainer) -> void:
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation",24); box.add_child(row)
	if ResourceLoader.exists("res://assets/encounter/cantor_portrait.png"):
		var portrait := TextureRect.new(); portrait.texture = load("res://assets/encounter/cantor_portrait.png")
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(190,190); row.add_child(portrait)
	var copy := VBoxContainer.new(); row.add_child(copy)
	copy.add_child(_label("A voice beneath the ruined crown",25,GOLD))
	copy.add_child(_label("A replayable, level-scaled plaza trial. Your current health, mana, gear and cooldowns carry in.\nThe Cantor remains rooted. Two fragments join each verse; the second begins at half health.",17))
	copy.add_child(_label("Severing Line: step sideways. Falling Seals: leave the three circles.\nUnmaking Ring: stand inside the small ring or beyond the outer edge.\nWarnings lock their positions when drawn. A committed seal survives stun.",17,Color("ffd5b0")))
	var t: Dictionary = preload("res://scripts/encounter_rules.gd").tuning(player.level)
	box.add_child(_label("Level %d · %d boss health · %d gold + 20%% level XP + one gear drop per victory" % [player.level,int(t.boss_hp),int(t.gold)],18))
	box.add_child(_label("Gear stays on the floor if you cannot collect it. Loot on the floor is not saved.\nR retreats with no reward. Leaving the marked arena or a long frame ends the run.\nPause and inventory freeze the encounter. Town services, mastery changes and F7 wait until it ends.",16,Color("b9c4d7")))
	box.add_child(_label("Recorded victories: %d · %s" % [main.encounter_wins,main.encounter.last_result],16,Color("d9c2ff")))
	if main.encounter.active:
		box.add_child(_button("Retreat from the trial",func() -> void:
			close_page(); main.encounter.finish(false,"Retreated from briefing")))
	else:
		var problem: String = main.encounter.start_problem()
		var begin := _button("Enter the Cantor trial",func() -> void:
			close_page(); main.encounter.start())
		begin.disabled = problem != ""; begin.tooltip_text = problem; box.add_child(begin)
