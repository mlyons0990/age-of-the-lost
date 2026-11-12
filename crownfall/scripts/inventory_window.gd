extends Control
## Docked side panels, in the style of Path of Exile with some Diablo flavour.
##
##   Left panel  (one at a time): Character (C), Stash (K), Merchant (talk to Maren),
##                                Spellbook (P)
##   Right panel: Inventory (I): gear slots on top, backpack grid below.
##
## The game keeps running while panels are open, and clicks between them still
## reach the world. Items can be dragged (press, move, release) or moved
## Diablo-style (click to lift, click to put down). A drag released where the
## item can't go snaps it back; clicking the ground while holding an item drops
## it on the floor next to you.

const GD := preload("res://scripts/game_data.gd")
const Inv := preload("res://scripts/inventory_logic.gd")
const Icons := preload("res://scripts/icons.gd")
const TITLE_FONT := preload("res://assets/fonts/LiberationSerif-Bold.ttf")
const PORTRAIT := preload("res://assets/portrait.webp")

const CELL := 54.0
const PANEL_W := 640.0
const HUD_H := 175.0          # space kept free at the bottom for the orbs and skill bar
const GOLD := Color("e8c77a")
const GOLD_DIM := Color("9c7a3c")
const IRON := Color("2a241c")
const TEXT := Color("efe6d2")
const MUTED := Color("a99f8a")
const CELL_BG := Color(0.07, 0.075, 0.1)
const CELL_LINE := Color(0.17, 0.17, 0.22)
const GOOD := Color("7ee07e")
const BAD := Color("e06060")

## Gear slots, relative to the gear area's top-left (Path of Exile layout).
const DOLL := {
	"weapon": Rect2(0, 0, 108, 216),
	"helm": Rect2(216, 0, 108, 108),
	"amulet": Rect2(342, 54, 54, 54),
	"offhand": Rect2(432, 0, 108, 216),
	"ring1": Rect2(144, 162, 54, 54),
	"armor": Rect2(216, 122, 108, 162),
	"ring2": Rect2(342, 162, 54, 54),
	"gloves": Rect2(0, 232, 108, 108),
	"belt": Rect2(216, 298, 108, 54),
	"boots": Rect2(432, 232, 108, 108),
}

## Explanations shown when hovering a stat on the character panel.
const STAT_HELP := {
	"Damage per hit": "Weapon damage including Strength, gear and talents. Skills multiply this.",
	"Critical strike chance": "Chance for a hit to be a critical strike. Raised by Dexterity and gear.",
	"Critical strike multiplier": "How much harder critical strikes hit. Base 175%, more from gear.",
	"Attack speed": "Shortens the time between basic attacks and speeds up the swing.",
	"Basic attacks per second": "How often Slash can be used with your current attack speed.",
	"Specialization skill damage": "Bonus to your specialization skill. Raised by Intelligence.",
	"Armour": "Reduces damage from hits. Raised by gear and Strength.",
	"Damage reduction": "Estimated reduction against a hit from a monster of your level.",
	"Dodge chance": "Chance to avoid a hit entirely. Raised by Dexterity, capped at 30%.",
	"Maximum life": "Raised by Vitality, gear and level.",
	"Life regeneration": "Life recovered per second out of combat (much less while fighting).",
	"Life per hit": "Life restored each time you hit an enemy. From gear.",
	"Healing received": "Increases all healing you receive. Raised by Wisdom.",
	"Maximum mana": "Raised by Intelligence and level.",
	"Mana regeneration": "Mana recovered per second. Raised by Wisdom.",
	"Cooldown reduction": "Shortens skill cooldowns. From gear and talents, capped at 50%.",
	"Movement speed": "Bonus running speed from gear, capped at 40%.",
}

var main: Node2D
var player: Node2D
var hud: CanvasLayer
var mode := "inventory"   # what the left panel shows: "character", "stash", "merchant", "spellbook", or "inventory" (none)
var inv_open := false     # whether the right (inventory) panel is shown
var held = null           # item on the cursor, or null
var held_from := {}       # where the held item was picked up, to put it back after a failed drag
var press_pos := Vector2.ZERO
var dragging := false     # true between a press that picked an item up and its release
const DRAG_MIN := 8.0     # pixels the mouse must move for a release to count as a drop

const POTION_PRICE := 25
const SHOP_MARKUP := 4   # the merchant sells for four times what she pays
const BUYBACK_MAX := 8
var note := ""
var note_t := 0.0
var scroll := 0.0         # scroll offset of the left panel's long lists
var scroll_max := 0.0
var confirm_reset := false
var noise_tex: ImageTexture
var hotspots: Array = []  # clickable areas drawn this frame: [Rect2, Callable]
var stat_rows: Array = [] # [Rect2, label] for stat tooltips
var plus_rects := {}      # attribute -> Rect2 of its + button, this frame


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Input is read in _input so clicks outside the panels still reach the world.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in 128:
		for x in 128:
			var v := rng.randf()
			img.set_pixel(x, y, Color(1, 1, 1, 0.06 * v * v))
	noise_tex = ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	note_t = maxf(0.0, note_t - delta)
	# Walking away from Maren closes her panel, as in Path of Exile.
	if mode == "merchant" and not main.near_merchant() and GD.gdist(player.position, main.MERCHANT_POS) > main.MERCHANT_RANGE + 1.5:
		set_mode("inventory")
		if not inv_open:
			hud.close_inventory()
	queue_redraw()


func _say(s: String) -> void:
	note = s
	note_t = 2.5


# ---------------------------------------------------------------- layout
func left_open() -> bool:
	return mode != "inventory"


func _left_rect() -> Rect2:
	return Rect2(0, 0, PANEL_W, size.y - HUD_H)


func _right_rect() -> Rect2:
	return Rect2(size.x - PANEL_W, 0, PANEL_W, size.y - HUD_H)


## Origin of the left panel's main content (stash grid, merchant).
func _left() -> Vector2:
	return _left_rect().position + Vector2(50, 96)


func _gear_origin() -> Vector2:
	return _right_rect().position + Vector2(50, 86)


func _doll_rect(slot: String) -> Rect2:
	var r: Rect2 = DOLL[slot]
	r.position += _gear_origin()
	return r


func _potion_rect() -> Rect2:
	return Rect2(_gear_origin() + Vector2(162, 362), Vector2(216, 54))


func _bag_origin() -> Vector2:
	return _right_rect().position + Vector2(50, 512)


func _close_rect(panel: Rect2) -> Rect2:
	return Rect2(panel.end.x - 46, panel.position.y + 14, 30, 30)


func _button_rects() -> Dictionary:
	var bo := _bag_origin()
	var by := bo.y + Inv.BAG_ROWS * CELL + 14
	var d := {
		"sort_bag": Rect2(bo.x, by, 150, 36),
		"close": _close_rect(_right_rect()),
	}
	var l := _left()
	if mode == "stash":
		d["sort_stash"] = Rect2(l.x, l.y + Inv.STASH_ROWS * CELL + 14, 150, 36)
	if mode == "merchant":
		d["buy_potion"] = Rect2(l.x, l.y + 252, 262, 40)
		d["sell_commons"] = Rect2(l.x + 278, l.y + 252, 262, 40)
	return d


## Merchant layout: the drop zone for selling, the buyback row and the shop.
func _sell_zone() -> Rect2:
	return Rect2(_left() + Vector2(0, 50), Vector2(540, 186))


func _buyback_rect(i: int) -> Rect2:
	return Rect2(_left() + Vector2(i * 67, 344), Vector2(60, 60))


func _shop_rect(i: int) -> Rect2:
	return Rect2(_left() + Vector2(i * 90, 452), Vector2(80, 80))


func shop_price(it: Dictionary) -> int:
	return sell_value(it) * SHOP_MARKUP


func sell_value(it: Dictionary) -> int:
	var r: int = int(it["rarity"])
	return roundi((5.0 + float(it["level"]) * 2.0) * float(GD.RARITY[r]["mult"]) * (1 + r))


# ---------------------------------------------------------------- actions
func set_mode(m: String) -> void:
	if m != mode:
		scroll = 0.0
		confirm_reset = false
	mode = m


## Called by the HUD before the panels close: never lose the item on the cursor.
func release_held() -> void:
	if held == null:
		return
	if _return_held():
		return
	var it: Dictionary = held
	held = null
	if Inv.add(player.bag, Inv.BAG_COLS, Inv.BAG_ROWS, it):
		return
	if Inv.add(player.stash, Inv.STASH_COLS, Inv.STASH_ROWS, it):
		return
	main._drop(player.position, "item", 0, it)


func buy_from_shop(i: int) -> bool:
	if i < 0 or i >= main.shop.size():
		return false
	var it: Dictionary = main.shop[i]
	var price := shop_price(it)
	if player.gold < price:
		_say("%s costs %d gold" % [it["name"], price])
		return false
	if not Inv.add(player.bag, Inv.BAG_COLS, Inv.BAG_ROWS, it):
		_say("Backpack is full")
		return false
	player.gold -= price
	main.audio.play("gold")
	main.shop.remove_at(i)
	_say("Bought %s for %d gold" % [it["name"], price])
	return true


func _sell(it: Dictionary) -> void:
	var v := sell_value(it)
	player.gold += v
	main.audio.play("sell")
	player.buyback.push_front(it)
	while player.buyback.size() > BUYBACK_MAX:
		player.buyback.pop_back()
	_say("Sold %s for %d gold" % [it["name"], v])


func buy_back(i: int) -> bool:
	if i < 0 or i >= player.buyback.size():
		return false
	var it: Dictionary = player.buyback[i]
	var v := sell_value(it)
	if player.gold < v:
		_say("Not enough gold to buy that back")
		return false
	if not Inv.add(player.bag, Inv.BAG_COLS, Inv.BAG_ROWS, it):
		_say("Backpack is full")
		return false
	player.gold -= v
	main.audio.play("gold")
	player.buyback.remove_at(i)
	_say("Bought back %s" % it["name"])
	return true


func buy_potion() -> bool:
	if player.potions >= 5:
		_say("You can carry at most 5 potions")
		return false
	if player.gold < POTION_PRICE:
		_say("A potion costs %d gold" % POTION_PRICE)
		return false
	player.gold -= POTION_PRICE
	main.audio.play("potion")
	player.potions += 1
	_say("Bought a Health Potion")
	return true


## Sells every common (white) item in the backpack. Returns how many were sold.
func sell_commons() -> int:
	var n := 0
	var total := 0
	for i in range(player.bag.size() - 1, -1, -1):
		var it: Dictionary = player.bag[i]["item"]
		if int(it["rarity"]) == 0:
			total += sell_value(it)
			_sell(it)
			player.bag.remove_at(i)
			n += 1
	_say("Sold %d common items for %d gold" % [n, total] if n > 0 else "No common items to sell")
	return n


## Puts the held item back where it was picked up. Returns false if that spot is gone.
func _return_held() -> bool:
	if held == null:
		return true
	var f := held_from
	var ok := false
	match String(f.get("kind", "")):
		"bag":
			ok = Inv.can_place(player.bag, Inv.BAG_COLS, Inv.BAG_ROWS, held, int(f["x"]), int(f["y"]))
			if ok:
				player.bag.append({"item": held, "x": int(f["x"]), "y": int(f["y"])})
		"stash":
			ok = Inv.can_place(player.stash, Inv.STASH_COLS, Inv.STASH_ROWS, held, int(f["x"]), int(f["y"]))
			if ok:
				player.stash.append({"item": held, "x": int(f["x"]), "y": int(f["y"])})
		"gear":
			ok = player.gear[f["slot"]] == null and Inv.accepts(f["slot"], held)
			if ok:
				player.gear[f["slot"]] = held
				_after_gear_change()
	if ok:
		held = null
		held_from = {}
	return ok


## Equips a backpack entry, sending whatever was worn back to the backpack.
func equip_from_bag(index: int) -> bool:
	var e: Dictionary = player.bag[index]
	var it: Dictionary = e["item"]
	var slot := Inv.best_slot(player.gear, it)
	if slot == "":
		return false
	var old = player.gear[slot]
	player.bag.remove_at(index)
	if old != null:
		var placed := false
		if Inv.can_place(player.bag, Inv.BAG_COLS, Inv.BAG_ROWS, old, int(e["x"]), int(e["y"])):
			player.bag.append({"item": old, "x": int(e["x"]), "y": int(e["y"])})
			placed = true
		elif Inv.add(player.bag, Inv.BAG_COLS, Inv.BAG_ROWS, old):
			placed = true
		if not placed:
			player.bag.insert(index, e)
			_say("No room in the backpack to swap")
			return false
	player.gear[slot] = it
	_after_gear_change()
	return true


func unequip(slot: String) -> bool:
	var it = player.gear[slot]
	if it == null:
		return false
	if not Inv.add(player.bag, Inv.BAG_COLS, Inv.BAG_ROWS, it):
		_say("Backpack is full")
		return false
	player.gear[slot] = null
	_after_gear_change()
	return true


## Moves an entry between backpack and stash. Returns false if the other side is full.
func transfer(from: Array, index: int, to: Array, cols: int, rows: int) -> bool:
	var e: Dictionary = from[index]
	if not Inv.add(to, cols, rows, e["item"]):
		_say("No room there")
		return false
	from.remove_at(index)
	return true


func _after_gear_change() -> void:
	main.audio.play("equip")
	var s: Dictionary = player.stats()
	player.hp = minf(player.hp, float(s["max_hp"]))
	player.mp = minf(player.mp, float(s["max_mp"]))


## Stats as they would be with an item worn in its slot (for comparisons).
func stats_if_equipped(it: Dictionary) -> Dictionary:
	var slot := Inv.best_slot(player.gear, it)
	if slot == "":
		return player.stats()
	var old = player.gear[slot]
	player.gear[slot] = it
	var s: Dictionary = player.stats()
	player.gear[slot] = old
	return s


# ---------------------------------------------------------------- input
func _grid_cell(origin: Vector2, cols: int, rows: int, at: Vector2) -> Vector2i:
	var c := ((at - origin) / CELL).floor()
	if c.x < 0 or c.y < 0 or c.x >= cols or c.y >= rows:
		return Vector2i(-1, -1)
	return Vector2i(int(c.x), int(c.y))


## Top-left cell for putting the held item down with the cursor at its centre.
func _drop_cell(origin: Vector2, at: Vector2) -> Vector2i:
	var s := Inv.size_of(held)
	var c := ((at - origin - Vector2(s) * CELL / 2.0) / CELL).round()
	return Vector2i(int(c.x), int(c.y))


## Index of the grid entry under the mouse, or -1.
func _entry_under(entries: Array, origin: Vector2, cols: int, rows: int, at: Vector2) -> int:
	var cell := _grid_cell(origin, cols, rows, at)
	if cell.x < 0:
		return -1
	return Inv.entry_at(entries, cell.x, cell.y)


func _doll_slot_at(at: Vector2) -> String:
	if not inv_open:
		return ""
	for slot in DOLL:
		if _doll_rect(slot).has_point(at):
			return slot
	return ""


func _over_panel(at: Vector2) -> bool:
	return (left_open() and _left_rect().has_point(at)) or (inv_open and _right_rect().has_point(at))


## Lifts the item under the mouse onto the cursor. Returns true if one was picked up.
func _pick_up(at: Vector2) -> bool:
	if inv_open:
		var i := _entry_under(player.bag, _bag_origin(), Inv.BAG_COLS, Inv.BAG_ROWS, at)
		if i >= 0:
			var e: Dictionary = player.bag[i]
			held = e["item"]
			held_from = {"kind": "bag", "x": e["x"], "y": e["y"]}
			player.bag.remove_at(i)
			return true
	if mode == "stash":
		var i2 := _entry_under(player.stash, _left(), Inv.STASH_COLS, Inv.STASH_ROWS, at)
		if i2 >= 0:
			var e2: Dictionary = player.stash[i2]
			held = e2["item"]
			held_from = {"kind": "stash", "x": e2["x"], "y": e2["y"]}
			player.stash.remove_at(i2)
			return true
	if mode == "merchant":
		for k in player.buyback.size():
			if _buyback_rect(k).has_point(at):
				buy_back(k)
				return false
		for k in main.shop.size():
			if _shop_rect(k).has_point(at):
				buy_from_shop(k)
				return false
	var slot := _doll_slot_at(at)
	if slot != "" and player.gear[slot] != null:
		held = player.gear[slot]
		held_from = {"kind": "gear", "slot": slot}
		player.gear[slot] = null
		_after_gear_change()
		return true
	return false


## Tries to put the held item down in a grid. Swaps with a single item underneath.
func _place_in_grid(entries: Array, origin: Vector2, cols: int, rows: int, at: Vector2, kind: String) -> int:
	# returns 0 = not over this grid, 1 = placed or swapped, 2 = over the grid but no room
	if _grid_cell(origin, cols, rows, at).x < 0:
		return 0
	var p := _drop_cell(origin, at)
	p.x = clampi(p.x, 0, cols - Inv.size_of(held).x)
	p.y = clampi(p.y, 0, rows - Inv.size_of(held).y)
	var hits := Inv.overlapping(entries, held, p.x, p.y)
	if hits.is_empty():
		entries.append({"item": held, "x": p.x, "y": p.y})
		held = null
		held_from = {}
		return 1
	if hits.size() == 1:
		var other: Dictionary = entries[hits[0]]
		entries.remove_at(hits[0])
		entries.append({"item": held, "x": p.x, "y": p.y})
		held = other["item"]
		held_from = {"kind": kind, "x": other["x"], "y": other["y"]}
		return 1
	_say("Not enough room there")
	return 2


## Puts the held item down wherever the mouse is. Returns true if it went somewhere.
func _place_held(at: Vector2) -> bool:
	if held == null:
		return false
	var before = held
	var ok := _place_held_inner(at)
	if ok and held != before:
		main.audio.play("ui_drop")
	elif not ok:
		main.audio.play("error")
	return ok


func _place_held_inner(at: Vector2) -> bool:
	if inv_open:
		var r := _place_in_grid(player.bag, _bag_origin(), Inv.BAG_COLS, Inv.BAG_ROWS, at, "bag")
		if r > 0:
			return r == 1
	if mode == "stash":
		var r2 := _place_in_grid(player.stash, _left(), Inv.STASH_COLS, Inv.STASH_ROWS, at, "stash")
		if r2 > 0:
			return r2 == 1
	if mode == "merchant" and _sell_zone().has_point(at):
		_sell(held)
		held = null
		held_from = {}
		return true
	var slot := _doll_slot_at(at)
	if slot != "":
		if not Inv.accepts(slot, held):
			_say("That does not go in the %s slot" % String(Inv.SLOT_LABEL[slot]).to_lower())
			return false
		var old = player.gear[slot]
		player.gear[slot] = held
		held = old
		held_from = {"kind": "gear", "slot": slot} if old != null else {}
		_after_gear_change()
		return true
	return false


## Clicking the ground while holding an item drops it next to you, as in Path of Exile.
func _drop_on_ground() -> void:
	var it: Dictionary = held
	held = null
	held_from = {}
	main._drop(player.position, "item", 0, it)
	main.loot[main.loot.size() - 1].wait_leave = true   # don't pick it straight back up
	main.audio.play("ui_drop")
	_say("Dropped %s" % it["name"])


## Right click: the quick action for the thing under the mouse.
func _quick_action(at: Vector2) -> void:
	if held != null:
		return
	if inv_open:
		var i := _entry_under(player.bag, _bag_origin(), Inv.BAG_COLS, Inv.BAG_ROWS, at)
		if i >= 0:
			match mode:
				"stash":
					transfer(player.bag, i, player.stash, Inv.STASH_COLS, Inv.STASH_ROWS)
				"merchant":
					_sell(player.bag[i]["item"])
					player.bag.remove_at(i)
				_:
					equip_from_bag(i)
			return
	if mode == "stash":
		var i2 := _entry_under(player.stash, _left(), Inv.STASH_COLS, Inv.STASH_ROWS, at)
		if i2 >= 0:
			transfer(player.stash, i2, player.bag, Inv.BAG_COLS, Inv.BAG_ROWS)
		return
	var slot := _doll_slot_at(at)
	if slot != "":
		unequip(slot)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var at := get_local_mouse_position() if mb.position == Vector2.ZERO else mb.position
		var over := _over_panel(at)
		# Wheel scrolls the left panel's lists.
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			if left_open() and _left_rect().has_point(at):
				scroll = clampf(scroll + (60.0 if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -60.0), 0.0, scroll_max)
				get_viewport().set_input_as_handled()
			return
		if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
			return
		if not over and not (held != null or dragging):
			return   # a click on the world: let the game handle it
		get_viewport().set_input_as_handled()
		_handle_click(mb, at, over)


func _handle_click(mb: InputEventMouseButton, at: Vector2, over: bool) -> void:
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		if mb.pressed:
			_quick_action(at)
		return
	if not mb.pressed:
		# Release: finish a drag. A release close to the press keeps the item on the cursor (click mode).
		if dragging and held != null and at.distance_to(press_pos) >= DRAG_MIN:
			if not over:
				_drop_on_ground()
			elif not _place_held(at):
				if not _return_held():
					release_held()
		dragging = false
		return
	# Press
	if not over and held != null:
		_drop_on_ground()
		return
	for h in hotspots:
		if (h[0] as Rect2).has_point(at):
			var cb: Callable = h[1]
			cb.call()
			return
	var b := _button_rects()
	if inv_open and b["close"].has_point(at):
		hud.close_inventory()
		return
	if inv_open and b["sort_bag"].has_point(at):
		player.bag = Inv.sorted(player.bag, Inv.BAG_COLS, Inv.BAG_ROWS)
		return
	if b.has("sort_stash") and b["sort_stash"].has_point(at):
		player.stash = Inv.sorted(player.stash, Inv.STASH_COLS, Inv.STASH_ROWS)
		return
	if b.has("buy_potion") and b["buy_potion"].has_point(at):
		buy_potion()
		return
	if b.has("sell_commons") and b["sell_commons"].has_point(at):
		sell_commons()
		return
	if inv_open and _potion_rect().has_point(at):
		player.drink_potion()
		return
	if held != null:
		_place_held(at)
		return
	if mode == "merchant" and mb.ctrl_pressed:
		var i2 := _entry_under(player.bag, _bag_origin(), Inv.BAG_COLS, Inv.BAG_ROWS, at)
		if i2 >= 0:
			_sell(player.bag[i2]["item"])
			player.bag.remove_at(i2)
		return
	if _pick_up(at):
		main.audio.play("ui_pick")
		dragging = true
		press_pos = at


# ---------------------------------------------------------------- drawing helpers
func _rarity_color(it: Dictionary) -> Color:
	return Color(String(GD.RARITY[int(it["rarity"])]["color"]))


func _text(at: Vector2, s: String, size_px: int, col: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, col)


func _text_r(right_x: float, y: float, s: String, size_px: int, col: Color) -> void:
	var w := ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	_text(Vector2(right_x - w, y), s, size_px, col)


func _text_c(center: Vector2, s: String, size_px: int, col: Color) -> void:
	var w := ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	_text(center - Vector2(w / 2.0, -size_px * 0.35), s, size_px, col)


func _title_c(center: Vector2, s: String, size_px: int, col: Color) -> void:
	var w: float = TITLE_FONT.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	draw_string_outline(TITLE_FONT, center - Vector2(w / 2.0, -size_px * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, 4, Color(0, 0, 0, 0.8))
	draw_string(TITLE_FONT, center - Vector2(w / 2.0, -size_px * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, col)


func _title(at: Vector2, s: String, size_px: int, col: Color) -> void:
	draw_string(TITLE_FONT, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, col)


func _button(r: Rect2, label: String, mouse: Vector2, cb: Callable, col := GOLD, enabled := true) -> void:
	var hot := enabled and r.has_point(mouse)
	draw_rect(r, Color(0.16, 0.12, 0.08) if hot else Color(0.09, 0.075, 0.055))
	draw_rect(r, (col if hot else GOLD_DIM.darkened(0.2)) if enabled else Color(0.3, 0.3, 0.3), false, 2.0)
	_text_c(r.get_center(), label, 16, col if enabled else Color(0.45, 0.45, 0.45))
	if enabled:
		hotspots.append([r, cb])


## A dark stone panel with an iron and gold frame and a gold title plate.
func _panel(r: Rect2, title: String, mouse: Vector2, on_close: Callable) -> void:
	draw_rect(r, Color(0.05, 0.045, 0.06, 0.97))
	var top := Color(0.11, 0.095, 0.1)
	var bot := Color(0.045, 0.04, 0.05)
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bot, bot]))
	draw_texture_rect(noise_tex, r, true)
	# frame: thick iron, gold inlay, thin inner line
	draw_rect(r.grow(-3), IRON, false, 6.0)
	draw_rect(r.grow(-7), GOLD_DIM, false, 2.0)
	draw_rect(r.grow(-12), Color(0.25, 0.2, 0.13, 0.8), false, 1.0)
	for c in [r.position + Vector2(7, 7), Vector2(r.end.x - 7, r.position.y + 7), Vector2(r.position.x + 7, r.end.y - 7), r.end - Vector2(7, 7)]:
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -9), c + Vector2(9, 0), c + Vector2(0, 9), c + Vector2(-9, 0)]), GOLD)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -4), c + Vector2(4, 0), c + Vector2(0, 4), c + Vector2(-4, 0)]), IRON)
	# title plate
	var cx := r.get_center().x
	var plate := PackedVector2Array([Vector2(cx - 150, r.position.y + 12), Vector2(cx + 150, r.position.y + 12),
		Vector2(cx + 128, r.position.y + 58), Vector2(cx - 128, r.position.y + 58)])
	draw_colored_polygon(plate, Color(0.16, 0.12, 0.07))
	var inner := PackedVector2Array([Vector2(cx - 140, r.position.y + 17), Vector2(cx + 140, r.position.y + 17),
		Vector2(cx + 122, r.position.y + 53), Vector2(cx - 122, r.position.y + 53)])
	draw_colored_polygon(inner, Color(0.24, 0.18, 0.1))
	plate.append(plate[0])
	draw_polyline(plate, GOLD, 2.0, true)
	for sx in [-1.0, 1.0]:
		var p := Vector2(cx + sx * 162, r.position.y + 35)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(6 * sx, 0), p + Vector2(0, 6), p + Vector2(-6 * sx, 0)]), GOLD)
	_title_c(Vector2(cx, r.position.y + 35), title.to_upper(), 24, GOLD)
	# close button
	var cr := _close_rect(r)
	var hot := cr.has_point(mouse)
	draw_circle(cr.get_center(), 15, IRON)
	draw_circle(cr.get_center(), 12, Color(0.55, 0.1, 0.08) if hot else Color(0.38, 0.07, 0.06))
	draw_arc(cr.get_center(), 13, 0, TAU, 24, GOLD, 1.5, true)
	var c2 := cr.get_center()
	draw_line(c2 + Vector2(-5, -5), c2 + Vector2(5, 5), Color("f2d0c0"), 2.5, true)
	draw_line(c2 + Vector2(5, -5), c2 + Vector2(-5, 5), Color("f2d0c0"), 2.5, true)
	hotspots.append([cr, on_close])


func _section(x: float, y: float, w: float, title: String) -> void:
	_title(Vector2(x, y), title, 22, GOLD)
	draw_line(Vector2(x, y + 8), Vector2(x + w, y + 8), Color(GOLD_DIM, 0.6), 1.0)


func _row(x: float, y: float, w: float, label: String, value: String, mouse: Vector2, odd: bool, value_col := TEXT) -> void:
	var r := Rect2(x - 6, y - 19, w + 12, 26)
	if odd:
		draw_rect(r, Color(1, 1, 1, 0.025))
	if r.has_point(mouse) and STAT_HELP.has(label):
		draw_rect(r, Color(1, 0.9, 0.6, 0.06))
	_text(Vector2(x, y), label, 16, Color("cfc6b2"))
	_text_r(x + w, y, value, 16, value_col)
	if STAT_HELP.has(label):
		stat_rows.append([r, label])


## Icon art per item type, made by tools/make_item_icons.py (replace with painted portraits
## of the same aspect to upgrade). Missing files fall back to the shapes drawn below.
const ICON_SLOTS := ["weapon", "offhand", "helm", "armor", "gloves", "belt", "boots", "ring", "amulet"]
static var _icons := {}


## The picture for an item: its painted portrait if there is one, else the slot's drawn icon.
static func icon_for(it: Dictionary) -> Texture2D:
	var art := GD.item_art(it)
	if art != "":
		var key := "painted/" + art
		if not _icons.has(key):
			var path := "res://assets/items/painted/%s.png" % art
			_icons[key] = load(path) if ResourceLoader.exists(path) else null
		if _icons[key] != null:
			return _icons[key]
	var slot := String(it.get("slot", ""))
	if not _icons.has(slot):
		var p2 := "res://assets/items/%s.png" % slot
		_icons[slot] = load(p2) if ResourceLoader.exists(p2) else null
	return _icons[slot]


func _draw_item(r: Rect2, it: Dictionary, alpha := 1.0) -> void:
	var col := _rarity_color(it)
	draw_rect(r.grow(-2), Color(col.r * 0.2 + 0.04, col.g * 0.2 + 0.04, col.b * 0.2 + 0.06, 0.96 * alpha))
	# a soft rarity glow behind the icon, stronger for better items
	var glow_a: float = [0.0, 0.10, 0.16, 0.24][int(it.get("rarity", 0))]
	if glow_a > 0.0:
		draw_circle(r.get_center(), minf(r.size.x, r.size.y) * 0.42, Color(col.r, col.g, col.b, glow_a * alpha))
	draw_rect(r.grow(-2), Color(col.r, col.g, col.b, alpha), false, 2.0)
	var tex := icon_for(it)
	if tex != null:
		# fit the icon inside the rect, keeping its shape
		var inner := r.grow(-5)
		var k: float = minf(inner.size.x / tex.get_width(), inner.size.y / tex.get_height())
		var sz := Vector2(tex.get_width(), tex.get_height()) * k
		draw_texture_rect(tex, Rect2(inner.get_center() - sz / 2.0, sz), false, Color(1, 1, 1, alpha))
		return
	var c := r.get_center()
	var u: float = minf(r.size.x, r.size.y) * 0.36
	var hgt: float = r.size.y * 0.5 - 8.0
	var ink := Color(0.92, 0.88, 0.78, alpha)
	var dim := Color(col.r, col.g, col.b, alpha)
	match String(it.get("slot", "")):
		"weapon":
			draw_line(c + Vector2(0, -hgt), c + Vector2(0, hgt * 0.45), ink, 6.0, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -hgt), c + Vector2(4, -hgt), c + Vector2(0, -hgt - 6)]), ink)
			draw_line(c + Vector2(-13, hgt * 0.45), c + Vector2(13, hgt * 0.45), dim, 5.0, true)
			draw_line(c + Vector2(0, hgt * 0.45), c + Vector2(0, hgt * 0.9), Color(0.5, 0.33, 0.2, alpha), 5.0, true)
			draw_circle(c + Vector2(0, hgt * 0.92), 4.0, dim)
		"offhand":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-u, -u), c + Vector2(u, -u), c + Vector2(u, u * 0.2), c + Vector2(0, u * 1.2), c + Vector2(-u, u * 0.2)]), ink)
			draw_line(c + Vector2(0, -u * 0.8), c + Vector2(0, u * 0.9), dim, 4.0)
			draw_line(c + Vector2(-u * 0.75, -u * 0.25), c + Vector2(u * 0.75, -u * 0.25), dim, 4.0)
		"helm":
			var pts := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				pts.append(c + Vector2(cos(a) * u, sin(a) * u * 1.1 + u * 0.1))
			pts.append(c + Vector2(u, u * 0.8))
			pts.append(c + Vector2(u * 0.45, u * 0.8))
			pts.append(c + Vector2(u * 0.3, u * 0.1))
			pts.append(c + Vector2(-u * 0.3, u * 0.1))
			pts.append(c + Vector2(-u * 0.45, u * 0.8))
			pts.append(c + Vector2(-u, u * 0.8))
			draw_colored_polygon(pts, ink)
			draw_line(c + Vector2(0, -u), c + Vector2(0, u * 0.1), dim, 3.0)
		"armor":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-u * 1.1, -u * 1.3), c + Vector2(-u * 0.4, -u * 1.5), c + Vector2(0, -u * 1.15), c + Vector2(u * 0.4, -u * 1.5), c + Vector2(u * 1.1, -u * 1.3), c + Vector2(u * 0.85, -u * 0.3), c + Vector2(u * 0.8, u * 1.5), c + Vector2(-u * 0.8, u * 1.5), c + Vector2(-u * 0.85, -u * 0.3)]), ink)
			draw_line(c + Vector2(0, -u * 1.1), c + Vector2(0, u * 1.4), dim, 3.0)
			draw_line(c + Vector2(-u * 0.8, u * 0.5), c + Vector2(u * 0.8, u * 0.5), dim, 3.0)
		"gloves":
			draw_rect(Rect2(c + Vector2(-u * 0.7, -u * 0.2), Vector2(u * 1.4, u * 1.2)), ink)
			for i in 4:
				draw_rect(Rect2(c + Vector2(-u * 0.7 + i * u * 0.37, -u), Vector2(u * 0.28, u * 0.9)), ink)
			draw_rect(Rect2(c + Vector2(-u * 0.8, u * 0.7), Vector2(u * 1.6, u * 0.35)), dim)
		"belt":
			draw_rect(Rect2(c + Vector2(-r.size.x * 0.4, -7), Vector2(r.size.x * 0.8, 14)), Color(0.5, 0.33, 0.2, alpha))
			draw_rect(Rect2(c + Vector2(-10, -11), Vector2(20, 22)), dim, false, 4.0)
		"boots":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-u * 0.7, -u), c + Vector2(u * 0.1, -u), c + Vector2(u * 0.1, u * 0.2), c + Vector2(u, u * 0.5), c + Vector2(u, u), c + Vector2(-u * 0.7, u)]), ink)
			draw_rect(Rect2(c + Vector2(-u * 0.7, u * 0.8), Vector2(u * 1.7, u * 0.25)), dim)
		"ring":
			draw_arc(c + Vector2(0, 4), 11.0, 0.0, TAU, 24, ink, 4.0, true)
			draw_circle(c + Vector2(0, -9), 5.0, dim)
		"amulet":
			draw_line(c + Vector2(-13, -16), c + Vector2(0, 4), ink, 2.5, true)
			draw_line(c + Vector2(13, -16), c + Vector2(0, 4), ink, 2.5, true)
			draw_circle(c + Vector2(0, 9), 7.0, dim)
			draw_circle(c + Vector2(-2, 7), 2.5, Color(1, 1, 1, 0.6 * alpha))


func _draw_grid(origin: Vector2, cols: int, rows: int, entries: Array, mouse: Vector2) -> Variant:
	var hover = null
	draw_rect(Rect2(origin, Vector2(cols, rows) * CELL), CELL_BG)
	for x in cols + 1:
		draw_line(origin + Vector2(x * CELL, 0), origin + Vector2(x * CELL, rows * CELL), CELL_LINE, 1.0)
	for y in rows + 1:
		draw_line(origin + Vector2(0, y * CELL), origin + Vector2(cols * CELL, y * CELL), CELL_LINE, 1.0)
	draw_rect(Rect2(origin, Vector2(cols, rows) * CELL).grow(2), GOLD_DIM.darkened(0.3), false, 2.0)
	for e in entries:
		var s := Inv.size_of(e["item"])
		var r := Rect2(origin + Vector2(int(e["x"]), int(e["y"])) * CELL, Vector2(s) * CELL)
		_draw_item(r, e["item"])
		if held == null and r.has_point(mouse):
			hover = e["item"]
			draw_rect(r.grow(-2), Color(1, 1, 1, 0.1))
	# placement preview for the held item
	if held != null and Rect2(origin, Vector2(cols, rows) * CELL).has_point(mouse):
		var s2 := Inv.size_of(held)
		var p := _drop_cell(origin, mouse)
		p.x = clampi(p.x, 0, cols - s2.x)
		p.y = clampi(p.y, 0, rows - s2.y)
		var n := Inv.overlapping(entries, held, p.x, p.y).size()
		draw_rect(Rect2(origin + Vector2(p) * CELL, Vector2(s2) * CELL), Color(0.3, 0.9, 0.4, 0.22) if n == 0 else (Color(0.95, 0.8, 0.3, 0.25) if n == 1 else Color(0.95, 0.25, 0.2, 0.28)))
	return hover


# ---------------------------------------------------------------- drawing
func _draw() -> void:
	if player == null:
		return
	hotspots.clear()
	stat_rows.clear()
	plus_rects.clear()
	var mouse := get_local_mouse_position()
	var hover = null
	var hover_equipped := false
	if left_open():
		var h1 = _draw_left(mouse)
		if h1 != null:
			hover = h1
	if inv_open:
		var h2 = _draw_inventory(mouse)
		if h2 != null:
			hover = h2[0]
			hover_equipped = h2[1]
	if note_t > 0.0:
		# shown above the skill bar, between the panels
		var na := minf(1.0, note_t)
		var nw := ThemeDB.fallback_font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		draw_rect(Rect2(size.x / 2.0 - nw / 2.0 - 14, size.y - HUD_H - 34, nw + 28, 32), Color(0, 0, 0, 0.6 * na))
		_text_c(Vector2(size.x / 2.0, size.y - HUD_H - 18), note, 18, Color(1.0, 0.86, 0.5, na))
	if held != null:
		var hs := Vector2(Inv.size_of(held)) * CELL
		_draw_item(Rect2(mouse - hs / 2.0, hs), held, 0.85)
	elif hover != null:
		_draw_item_tooltip(hover, mouse, hover_equipped)
	else:
		for sr in stat_rows:
			if (sr[0] as Rect2).has_point(mouse):
				_draw_text_tooltip(sr[1], STAT_HELP.get(sr[1], ""), mouse)
				break


func _draw_left(mouse: Vector2) -> Variant:
	var r := _left_rect()
	var titles := {"character": "Character", "stash": "Stash", "merchant": "Maren's Wares", "spellbook": "Spellbook"}
	_panel(r, titles.get(mode, mode), mouse, func() -> void: hud.close_left())
	match mode:
		"character":
			_draw_character(r, mouse)
		"stash":
			_text(_left() + Vector2(0, -14), "Right click moves items to and from your backpack", 15, MUTED)
			var h = _draw_grid(_left(), Inv.STASH_COLS, Inv.STASH_ROWS, player.stash, mouse)
			var b := _button_rects()
			_button(b["sort_stash"], "Sort stash", mouse, func() -> void: player.stash = Inv.sorted(player.stash, Inv.STASH_COLS, Inv.STASH_ROWS))
			return h
		"merchant":
			return _draw_merchant(mouse)
		"spellbook":
			_draw_spellbook(r, mouse)
	return null


# ---- character panel
func _draw_character(r: Rect2, mouse: Vector2) -> void:
	var p := player
	var s: Dictionary = p.stats()
	var x := r.position.x + 34
	var w := r.size.x - 68
	# header: portrait, name, level, class; attributes on the right with + buttons
	var hb := Rect2(x, r.position.y + 74, w, 168)
	draw_rect(hb, Color(0, 0, 0, 0.35))
	draw_rect(hb, GOLD_DIM.darkened(0.35), false, 1.0)
	var pc := hb.position + Vector2(64, 64)
	draw_circle(pc, 50, IRON)
	draw_texture_rect(PORTRAIT, Rect2(pc - Vector2(44, 44), Vector2(88, 88)), false)
	draw_arc(pc, 47, 0, TAU, 48, GOLD, 3.0, true)
	draw_circle(pc + Vector2(36, 36), 16, IRON)
	draw_arc(pc + Vector2(36, 36), 16, 0, TAU, 24, GOLD, 2.0, true)
	_text_c(pc + Vector2(36, 35), str(p.level), 16, GOLD)
	_title(hb.position + Vector2(14, 148), p.hero_name, 22, TEXT)
	_text(hb.position + Vector2(130, 34), "Level %d %s" % [p.level, p.title()], 16, Color("e6dcc6"))
	_text(hb.position + Vector2(130, 58), "Crownsfall", 15, MUTED)
	var free: int = p.points_free()
	_text(hb.position + Vector2(130, 92), "Stat points: %d" % free, 16, Color("ffe9a8") if free > 0 else MUTED)
	if p.points_free() < p.points_earned():
		_button(Rect2(hb.position + Vector2(130, 104), Vector2(150, 28)), "Reset (%d gold)" % p.respec_cost(), mouse, func() -> void:
			if p.respec():
				main.audio.play("click")
				_say("Stat points returned")
			else:
				_say("Not enough gold to reset"), GOLD)
	var at: Dictionary = s["attr"]
	var base_at: Dictionary = p.attributes({"str": 0.0, "dex": 0.0, "vit": 0.0, "int": 0.0, "wis": 0.0})
	var ay := hb.position.y + 26
	var ax := hb.end.x - 200
	for a in GD.ATTRS:
		var label := String(GD.ATTR_NAME[a])
		var rr := Rect2(ax - 6, ay - 19, 196, 26)
		if rr.has_point(mouse):
			draw_rect(rr, Color(1, 0.9, 0.6, 0.06))
			stat_rows.append([rr, "__attr_" + a])
		_text(Vector2(ax, ay), label, 16, GOLD if a == GD.CLASS_ATTRS["knight"]["main"] else Color("d8cdb3"))
		var bonus := int(at[a]) - int(base_at[a])
		_text_r(ax + 150, ay, str(int(at[a])), 16, GOOD if bonus > 0 else TEXT)
		if free > 0:
			var pr := Rect2(ax + 158, ay - 17, 24, 22)
			var hot := pr.has_point(mouse)
			draw_rect(pr, Color(0.25, 0.2, 0.08) if hot else Color(0.14, 0.11, 0.06))
			draw_rect(pr, GOLD, false, 1.5)
			_text_c(pr.get_center() + Vector2(0, -1), "+", 18, GOLD)
			var stat := String(a)
			plus_rects[stat] = pr
			hotspots.append([pr, func() -> void:
				if p.allocate(stat, 5 if Input.is_key_pressed(KEY_SHIFT) else 1) > 0:
					main.audio.play("click")])
		ay += 29
	# big boxes: Life, Mana, Damage / Armour, Dodge, Crit
	var bw := (w - 20) / 3.0
	var by := hb.end.y + 12
	var boxes := [["Life", "%d" % int(s["max_hp"]), Color("e05050")], ["Mana", "%d" % int(s["max_mp"]), Color("6a9cff")], ["Damage", "%d" % roundi(float(s["dmg"])), Color("e8c77a")],
		["Armour", "%d" % roundi(float(s["armor"])), Color("c8c0b0")], ["Dodge", "%.1f%%" % (float(s["dodge"]) * 100.0), Color("9fe0b0")], ["Critical", "%.1f%%" % (float(s["crit"]) * 100.0), Color("ffb070")]]
	for i in boxes.size():
		var bx := Rect2(x + (i % 3) * (bw + 10), by + (i / 3) * 70, bw, 62)
		draw_rect(bx, Color(0, 0, 0, 0.4))
		draw_rect(bx, GOLD_DIM.darkened(0.25), false, 1.0)
		draw_rect(Rect2(bx.position, Vector2(bx.size.x, 3)), Color(boxes[i][2], 0.8))
		_text_c(bx.get_center() + Vector2(0, -12), boxes[i][0].to_upper(), 13, MUTED)
		_title_c(bx.get_center() + Vector2(0, 12), boxes[i][1], 22, boxes[i][2])
	# scrolling detail list
	var list := Rect2(x - 6, by + 150, w + 12, r.end.y - (by + 150) - 22)
	var lvl: int = p.level
	var red: float = float(s["armor"]) / (float(s["armor"]) + 40.0 + 12.0 * lvl)
	var aspd: float = 1.0 + float(s["atk_speed"])
	var rows := [
		["#", "Offence"],
		["Damage per hit", "%d" % roundi(float(s["dmg"]))],
		["Critical strike chance", "%.1f%%" % (float(s["crit"]) * 100.0)],
		["Critical strike multiplier", "%d%%" % roundi(float(s["crit_mult"]) * 100.0)],
		["Attack speed", "+%d%%" % roundi(float(s["atk_speed"]) * 100.0)],
		["Basic attacks per second", "%.2f" % (aspd / float(GD.BASE["basic"]["cd"]))],
		["Specialization skill damage", "+%d%%" % roundi(float(s["spell"]) * 100.0)],
		["#", "Defence"],
		["Armour", "%d" % roundi(float(s["armor"]))],
		["Damage reduction", "%d%%" % roundi(red * 100.0)],
		["Dodge chance", "%.1f%% (max 30%%)" % (float(s["dodge"]) * 100.0)],
		["#", "Life"],
		["Maximum life", "%d" % int(s["max_hp"])],
		["Life regeneration", "%.1f per second" % (float(s["max_hp"]) * 0.012)],
		["Life per hit", "%d" % int(s["life_hit"])],
		["Healing received", "+%d%%" % roundi((float(s["healing"]) - 1.0) * 100.0)],
		["#", "Mana"],
		["Maximum mana", "%d" % int(s["max_mp"])],
		["Mana regeneration", "%.1f per second" % float(s["mana_regen"])],
		["#", "Utility"],
		["Cooldown reduction", "%d%%" % roundi(float(s["cdr"]) * 100.0)],
		["Movement speed", "+%d%%" % roundi(float(s["move"]) * 100.0)],
		["Gold", "%d" % p.gold],
		["Monsters slain", "%d" % p.kills],
		["Wardens defeated", "%d" % p.bosses_killed],
		["Deaths", "%d" % p.deaths],
		["Memories found", "%d of %d" % [p.lore.size(), GD.LORE.size()]],
		["#", "Path"],
		["Level 1", "Knight"],
		["Level %d" % GD.SPEC_LEVEL, GD.SPECS[p.spec]["name"] if p.spec != "" else "Specialization (locked)"],
		["Level %d" % GD.ADVANCED_LEVEL, p.title() if p.adv != "" else "Advanced path (locked)"],
		["Level %d" % GD.MAX_LEVEL, _heroic_name() if p.heroic != "" else "Heroic Talent (locked)"],
	]
	var y := list.position.y + 26 - scroll
	var odd := false
	var content_h := 0.0
	for row in rows:
		var hgt := 40.0 if row[0] == "#" else 27.0
		if y > list.position.y + 4 and y < list.end.y:
			if row[0] == "#":
				_section(x, y + 6, w, row[1])
			else:
				_row(x, y, w, row[0], row[1], mouse, odd)
		odd = not odd if row[0] != "#" else false
		y += hgt
		content_h += hgt
	# reset progress (with confirmation) at the very end of the list
	y += 14
	content_h += 60
	if y > list.position.y and y + 32 < list.end.y:
		_button(Rect2(x, y, 220, 32), "Click again to confirm" if confirm_reset else "Reset all progress", mouse, func() -> void:
			if confirm_reset:
				main.reset_save()
			else:
				confirm_reset = true, BAD)
	scroll_max = maxf(0.0, content_h - list.size.y + 20)
	if scroll_max > 0.0:
		var track := Rect2(list.end.x - 6, list.position.y + 4, 4, list.size.y - 8)
		draw_rect(track, Color(1, 1, 1, 0.05))
		var k := list.size.y / (content_h + 20)
		draw_rect(Rect2(track.position + Vector2(0, (track.size.y - track.size.y * k) * scroll / scroll_max), Vector2(4, track.size.y * k)), Color(GOLD_DIM, 0.8))
	# fade the list edges into the panel
	draw_rect(Rect2(list.position.x, list.position.y - 6, list.size.x, 10), Color(0.07, 0.06, 0.07))


func _heroic_name() -> String:
	for h in GD.HEROIC:
		if h["id"] == player.heroic:
			return h["name"]
	return ""


# ---- spellbook
func _skill_numbers(sk: Dictionary, s: Dictionary, slot: String) -> String:
	var dmg: float = float(s["dmg"])
	var mult: float = 1.0
	if slot == "s4":
		mult = (1.0 + float(s["m"]["spec_dmg"])) * (1.0 + float(s["spell"]))
	match String(sk["type"]):
		"melee", "arc", "dash", "nova", "cone", "ground":
			var hit := roundi(dmg * float(sk["dmg"]) * mult)
			var txt := "%d damage (%d%% of weapon damage)" % [hit, roundi(float(sk["dmg"]) * mult * 100.0)]
			if sk.has("burn"):
				txt += ", burns"
			return txt
		"buff":
			return "Heals %d life, +%d%% damage for %ds" % [roundi(float(s["max_hp"]) * (float(sk["heal"]) + float(s["m"]["rally_heal"])) * float(s["healing"])), roundi(float(sk["dmg_buff"]) * 100.0), int(sk["duration"])]
	return ""


func _draw_skill_row(x: float, y: float, w: float, sk: Dictionary, key: String, slot: String, s: Dictionary, locked: bool, col: Color) -> void:
	var ir := Rect2(x, y, 58, 58)
	draw_rect(ir, Color(0.08, 0.08, 0.12))
	draw_rect(ir, GOLD_DIM if not locked else Color(0.3, 0.3, 0.3), false, 2.0)
	Icons.draw_icon(self, sk["id"], ir, col if not locked else Color(0.45, 0.45, 0.45))
	_title(Vector2(x + 72, y + 18), sk["name"], 19, GOLD if not locked else MUTED)
	if key != "":
		_text_r(x + w, y + 18, key, 14, MUTED)
	var cd: float = float(sk["cd"])
	cd = cd / (1.0 + float(s["atk_speed"])) if slot == "basic" else cd * (1.0 - float(s["cdr"]))
	var cost := "Restores %d mana" % int(-float(sk["mana"])) if float(sk["mana"]) < 0.0 else "%d mana" % int(sk["mana"])
	_text(Vector2(x + 72, y + 38), "%s  ·  %.1fs cooldown" % [cost, cd], 14, Color("8fb0ff"))
	_text(Vector2(x + 72, y + 57), _skill_numbers(sk, s, slot), 14, TEXT if not locked else MUTED)
	_text(Vector2(x + 72, y + 76), sk["desc"], 13, MUTED)


func _draw_spellbook(r: Rect2, mouse: Vector2) -> void:
	var p := player
	var s: Dictionary = p.stats()
	var x := r.position.x + 34
	var w := r.size.x - 68
	var top := r.position.y + 72
	var bottom := r.end.y - 20
	var y := top + 10 - scroll
	var content := 0.0
	var items: Array = []
	items.append(["#", "Knight skills"])
	for sl in [["basic", "Left click"], ["s1", "1 / right click"], ["s2", "2"], ["s3", "3"]]:
		items.append(["skill", GD.BASE[sl[0]], sl[1], sl[0], false, Color("e6eeff")])
	items.append(["#", "Specializations  ·  level %d" % GD.SPEC_LEVEL])
	for id in GD.SPECS:
		var sp: Dictionary = GD.SPECS[id]
		var chosen: bool = p.spec == id
		var status := "Chosen" if chosen else ("Locked until level %d" % GD.SPEC_LEVEL if p.level < GD.SPEC_LEVEL else ("Not chosen" if p.spec != "" else "Available"))
		items.append(["spec", sp, status, chosen])
		items.append(["skill", sp["skill"], "4" if chosen else "", "s4", not chosen, Color(String(sp["fx"][1]))])
		for a in sp["advanced"]:
			items.append(["adv", a, sp, p.adv == a["id"]])
	items.append(["#", "Heroic Talents  ·  level %d" % GD.MAX_LEVEL])
	for h in GD.HEROIC:
		items.append(["hero", h, p.heroic == h["id"]])
	for it in items:
		var hgt := 0.0
		match String(it[0]):
			"#":
				hgt = 46.0
				if y > top and y < bottom:
					_section(x, y + 24, w, it[1])
			"skill":
				hgt = 92.0
				if y > top - 10 and y + 80 < bottom:
					_draw_skill_row(x, y, w, it[1], it[2], it[3], s, it[4], it[5])
			"spec":
				hgt = 52.0
				if y > top and y + 40 < bottom:
					var sp2: Dictionary = it[1]
					_title(Vector2(x, y + 22), sp2["name"], 21, Color(String(sp2["color"])))
					_text_r(x + w, y + 22, it[2], 14, GOOD if it[3] else MUTED)
					_text(Vector2(x, y + 42), "%s  —  %s" % [sp2["passive"]["name"], sp2["passive"]["desc"]], 13, Color("cfc6b2"))
			"adv":
				hgt = 26.0
				if y > top and y + 10 < bottom:
					var a2: Dictionary = it[1]
					_text(Vector2(x + 24, y + 16), "Level %d:  %s  —  %s" % [GD.ADVANCED_LEVEL, a2["name"], a2["desc"]], 13, GOOD if it[3] else MUTED)
			"hero":
				hgt = 28.0
				if y > top and y + 10 < bottom:
					var h2: Dictionary = it[1]
					_text(Vector2(x, y + 18), "%s  —  %s" % [h2["name"], h2["desc"]], 14, GOOD if it[2] else Color("cfc6b2"))
		y += hgt
		content += hgt
	scroll_max = maxf(0.0, content - (bottom - top) + 20)
	draw_rect(Rect2(r.position.x + 20, top - 8, r.size.x - 40, 12), Color(0.1, 0.09, 0.1))


# ---- merchant
func _draw_merchant(mouse: Vector2) -> Variant:
	var hover = null
	var left := _left()
	_text(left + Vector2(0, 14), "\"Fair coin for anything the Scar spits out.\"", 16, MUTED)
	var z := _sell_zone()
	var over: bool = held != null and z.has_point(mouse)
	draw_rect(z, Color(0.12, 0.1, 0.06) if over else Color(0, 0, 0, 0.35))
	draw_rect(z, Color("ffd84a") if over else GOLD_DIM.darkened(0.2), false, 3.0 if over else 2.0)
	if held != null:
		_text_c(z.get_center() + Vector2(0, -14), "Drop here to sell", 22, Color("ffd84a"))
		_text_c(z.get_center() + Vector2(0, 20), "%s  ·  %d gold" % [held["name"], sell_value(held)], 18, _rarity_color(held))
	else:
		_text_c(z.get_center() + Vector2(0, -14), "Drag an item here to sell it", 21, Color("cfc6b2"))
		_text_c(z.get_center() + Vector2(0, 18), "or right click it in your backpack", 16, Color("8f8878"))
	var b := _button_rects()
	_button(b["buy_potion"], "Buy Health Potion  (%d gold)" % POTION_PRICE, mouse, func() -> void: buy_potion(), Color("ff9a9a"))
	_button(b["sell_commons"], "Sell all common items", mouse, func() -> void: sell_commons(), Color("ffd84a"))
	_section(left.x, left.y + 324, 540, "Buy back")
	for i in BUYBACK_MAX:
		var r := _buyback_rect(i)
		draw_rect(r, CELL_BG)
		draw_rect(r, GOLD_DIM.darkened(0.45), false, 1.0)
		if i < player.buyback.size():
			_draw_item(r, player.buyback[i])
			if held == null and r.has_point(mouse):
				hover = player.buyback[i]
				draw_rect(r.grow(-2), Color(1, 1, 1, 0.12))
	_section(left.x, left.y + 432, 540, "For sale")
	for i in main.SHOP_SIZE:
		var r2 := _shop_rect(i)
		draw_rect(r2, CELL_BG)
		draw_rect(r2, GOLD_DIM.darkened(0.45), false, 1.0)
		if i < main.shop.size():
			var it: Dictionary = main.shop[i]
			_draw_item(r2, it)
			var price := shop_price(it)
			_text_c(r2.get_center() + Vector2(0, 54), "%d g" % price, 15, Color("ffd84a") if player.gold >= price else Color("c05050"))
			if held == null and r2.has_point(mouse):
				hover = it
				draw_rect(r2.grow(-2), Color(1, 1, 1, 0.12))
	_text(left + Vector2(0, 600), "Click to buy · restocks as you level and fight", 14, MUTED)
	return hover


# ---- inventory panel
func _draw_inventory(mouse: Vector2) -> Variant:
	var r := _right_rect()
	_panel(r, "Inventory", mouse, func() -> void: hud.close_inventory())
	var hover = null
	var equipped := false
	var g := _gear_origin()
	# faint silhouette behind the gear, like the statue frames in Path of Exile
	draw_circle(g + Vector2(270, 170), 150, Color(1, 0.9, 0.6, 0.025))
	for slot in Inv.EQUIP_SLOTS:
		var sr := _doll_rect(slot)
		draw_rect(sr, Color(0.05, 0.05, 0.08, 0.95))
		var fits: bool = held != null and Inv.accepts(slot, held)
		draw_rect(sr, Color(0.35, 0.9, 0.45) if fits else GOLD_DIM.darkened(0.25), false, 3.0 if fits else 2.0)
		var it = player.gear[slot]
		if it == null:
			_text_c(sr.get_center(), Inv.SLOT_LABEL[slot], 12, Color(0.4, 0.38, 0.36))
		else:
			_draw_item(sr, it)
			if held == null and sr.has_point(mouse):
				hover = it
				equipped = true
	# potion "flask" slot
	var pr := _potion_rect()
	draw_rect(pr, Color(0.05, 0.05, 0.08, 0.95))
	draw_rect(pr, GOLD_DIM.darkened(0.25), false, 2.0)
	for i in 5:
		var fr := Rect2(pr.position + Vector2(4 + i * 42, 4), Vector2(38, 46))
		if i < player.potions:
			Icons.draw_icon(self, "potion", fr, Color.WHITE)
		else:
			draw_arc(fr.get_center() + Vector2(0, 6), 12, 0, TAU, 20, Color(0.3, 0.3, 0.32), 1.5, true)
	_text(pr.position + Vector2(-26, 34), "Q", 15, MUTED)
	# backpack
	var bo := _bag_origin()
	var h2 = _draw_grid(bo, Inv.BAG_COLS, Inv.BAG_ROWS, player.bag, mouse)
	if h2 != null:
		hover = h2
		equipped = false
	var b := _button_rects()
	_button(b["sort_bag"], "Sort", mouse, func() -> void: player.bag = Inv.sorted(player.bag, Inv.BAG_COLS, Inv.BAG_ROWS))
	_text_r(bo.x + Inv.BAG_COLS * CELL, b["sort_bag"].position.y + 24, "%d gold" % player.gold, 19, Color("ffd84a"))
	if hover == null:
		return null
	return [hover, equipped]


# ---------------------------------------------------------------- tooltips and item comparison
## Lines for an item: [text, size, colour]. With `against`, each stat shows its difference in green or red.
func _item_lines(it: Dictionary, against) -> Array:
	var lines: Array = []
	lines.append([String(it["name"]), 20, _rarity_color(it)])
	lines.append(["%s %s  ·  item level %d" % [GD.RARITY[int(it["rarity"])]["name"], String(Inv.TYPE_LABEL.get(String(it["slot"]), "Item")).to_lower(), int(it["level"])], 14, MUTED])
	var keys: Array = []
	for a in GD.ATTRS:
		keys.append(a)
	keys.append_array(["dmg", "armor", "hp", "crit"])
	for k in GD.SECONDARY:
		keys.append(k)
	for k in keys:
		var v := float(it.get(k, 0.0))
		var cur := float(against.get(k, 0.0)) if against != null else 0.0
		if v <= 0.0 and (against == null or cur <= 0.0):
			continue
		var line := _stat_text(k, v) if v > 0.0 else "(none)  " + _stat_text(k, cur).trim_prefix("+")
		var col := TEXT
		if against != null:
			var d := v - cur
			if absf(d) > 0.0001:
				line += "   (%s)" % _delta_text(k, d)
				col = GOOD if d > 0.0 else BAD
		lines.append([line, 16, col])
	return lines


func _stat_text(k: String, v: float) -> String:
	if GD.ATTR_NAME.has(k):
		return "+%d %s" % [int(v), GD.ATTR_NAME[k]]
	match k:
		"dmg":
			return "+%d damage" % int(v)
		"armor":
			return "+%d armour" % int(v)
		"hp":
			return "+%d life" % int(v)
		"crit":
			return "+%.1f%% critical strike chance" % (v * 100.0)
	if GD.SECONDARY.has(k):
		return ("+%d%% " % roundi(v * 100.0) if GD.SECONDARY[k]["pct"] else "+%d " % int(v)) + String(GD.SECONDARY[k]["name"])
	return "+%s %s" % [str(v), k]


func _delta_text(k: String, d: float) -> String:
	var sign := "+" if d > 0.0 else "-"
	if k == "crit":
		return "%s%.1f%%" % [sign, absf(d) * 100.0]
	if GD.SECONDARY.has(k) and GD.SECONDARY[k]["pct"]:
		return "%s%d%%" % [sign, roundi(absf(d) * 100.0)]
	return "%s%d" % [sign, roundi(absf(d))]


func _box(at: Vector2, lines: Array, border: Color, header := "") -> Vector2:
	var font := ThemeDB.fallback_font
	var w := 0.0
	var h := 16.0
	if header != "":
		h += 22.0
		w = font.get_string_size(header, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	for l in lines:
		w = maxf(w, font.get_string_size(l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, int(l[1])).x)
		h += float(l[1]) + 7.0
	return Vector2(w + 30.0, h)


func _paint_box(at: Vector2, sz: Vector2, lines: Array, border: Color, header := "") -> void:
	draw_rect(Rect2(at, sz), Color(0.035, 0.03, 0.045, 0.97))
	draw_rect(Rect2(at, sz), border, false, 2.0)
	draw_rect(Rect2(at, Vector2(sz.x, 3)), border)
	var y := at.y + 8.0
	if header != "":
		y += 18.0
		_text(Vector2(at.x + 15, y - 3.0), header, 13, MUTED)
	for l in lines:
		y += float(l[1]) + 7.0
		if l[1] == 20:
			_title(Vector2(at.x + 15, y - 5.0), l[0], 20, l[2])
		else:
			_text(Vector2(at.x + 15, y - 5.0), l[0], int(l[1]), l[2])


func _draw_item_tooltip(it: Dictionary, mouse: Vector2, equipped: bool) -> void:
	var slot := Inv.best_slot(player.gear, it)
	var cur = null if equipped or slot == "" else player.gear.get(slot)
	var lines := _item_lines(it, cur)
	if String(it["slot"]) == "weapon":
		lines.append(["Half damage in the off hand", 13, MUTED])
	if not equipped and slot != "":
		# what equipping it would do to the character, Diablo-style
		var now: Dictionary = player.stats()
		var then := stats_if_equipped(it)
		var parts: Array = []
		for pair in [["dmg", "damage"], ["max_hp", "life"], ["armor", "armour"], ["max_mp", "mana"]]:
			var d := float(then[pair[0]]) - float(now[pair[0]])
			if absf(d) >= 0.5:
				parts.append(["%s%d %s" % ["+" if d > 0 else "-", roundi(absf(d)), pair[1]], GOOD if d > 0 else BAD])
		var dc := (float(then["crit"]) - float(now["crit"])) * 100.0
		if absf(dc) >= 0.05:
			parts.append(["%s%.1f%% crit" % ["+" if dc > 0 else "-", absf(dc)], GOOD if dc > 0 else BAD])
		if not parts.is_empty():
			lines.append(["If equipped:", 14, Color("cfc6b2")])
			for pt in parts:
				lines.append(["   " + pt[0], 15, pt[1]])
	if main.shop.has(it):
		lines.append(["Costs %d gold" % shop_price(it), 15, Color("ffd84a") if player.gold >= shop_price(it) else BAD])
	else:
		lines.append(["Sells for %d gold" % sell_value(it), 14, Color("ffd84a")])
	if equipped:
		lines.append(["Equipped", 14, GOOD])
	var sz := _box(mouse, lines, _rarity_color(it))
	var at := mouse + Vector2(24, 18)
	at.x = clampf(at.x, 8.0, size.x - sz.x - 8.0)
	at.y = clampf(at.y, 8.0, size.y - sz.y - 8.0)
	# the worn item, side by side, as in Path of Exile's comparison
	if cur != null:
		var cl := _item_lines(cur, null)
		var csz := _box(at, cl, _rarity_color(cur), "Currently equipped")
		var cat := Vector2(at.x - csz.x - 10.0, at.y)
		if cat.x < 8.0:
			cat.x = at.x + sz.x + 10.0
			if cat.x + csz.x > size.x - 8.0:
				cat = Vector2(clampf(at.x, 8.0, size.x - csz.x - 8.0), clampf(at.y + sz.y + 8.0, 8.0, size.y - csz.y - 8.0))
		_paint_box(cat, csz, cl, _rarity_color(cur), "Currently equipped")
	_paint_box(at, sz, lines, _rarity_color(it))


func _draw_text_tooltip(key: String, text: String, mouse: Vector2) -> void:
	var title := key
	if key.begins_with("__attr_"):
		var a := key.substr(7)
		title = GD.ATTR_NAME[a]
		text = GD.ATTR_HELP[a]
	var lines := [[title, 20, GOLD], [text, 15, TEXT]]
	var sz := _box(mouse, lines, GOLD_DIM)
	var at := Vector2(clampf(mouse.x + 22, 8.0, size.x - sz.x - 8.0), clampf(mouse.y + 16, 8.0, size.y - sz.y - 8.0))
	_paint_box(at, sz, lines, GOLD_DIM)
