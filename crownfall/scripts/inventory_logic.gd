extends RefCounted
## Pure inventory rules: item footprints, grid packing, sorting, equipment slots.
## No nodes and no drawing, so it can be tested on its own (see dev_test.gd).
##
## A grid is an Array of entries: {"item": Dictionary, "x": int, "y": int}.
## An item's "slot" is its type: weapon, offhand, helm, armor, gloves, belt,
## boots, ring or amulet. Its footprint comes from the type, so old saves work.

const BAG_COLS := 10
const BAG_ROWS := 6
const STASH_COLS := 10
const STASH_ROWS := 8

## Footprint in cells (width, height) per item type.
const FOOTPRINT := {
	"weapon": Vector2i(1, 3), "offhand": Vector2i(2, 2), "helm": Vector2i(2, 2), "armor": Vector2i(2, 3),
	"gloves": Vector2i(2, 2), "belt": Vector2i(2, 1), "boots": Vector2i(2, 2), "ring": Vector2i(1, 1), "amulet": Vector2i(1, 1),
}

## Equipment slots on the paper doll, in display order, and the item types each accepts.
## The off hand takes a shield or a second weapon (dual wielding at half damage).
const EQUIP_SLOTS := ["helm", "amulet", "weapon", "armor", "offhand", "gloves", "belt", "boots", "ring1", "ring2"]
const ACCEPTS := {
	"helm": ["helm"], "amulet": ["amulet"], "weapon": ["weapon"], "armor": ["armor"], "offhand": ["offhand", "weapon"],
	"gloves": ["gloves"], "belt": ["belt"], "boots": ["boots"], "ring1": ["ring"], "ring2": ["ring"],
}
const SLOT_LABEL := {
	"helm": "Helm", "amulet": "Amulet", "weapon": "Main hand", "armor": "Chest", "offhand": "Off hand",
	"gloves": "Gloves", "belt": "Belt", "boots": "Boots", "ring1": "Ring", "ring2": "Ring",
}
const TYPE_LABEL := {
	"weapon": "Weapon", "offhand": "Shield", "helm": "Helm", "armor": "Chest armor", "gloves": "Gloves",
	"belt": "Belt", "boots": "Boots", "ring": "Ring", "amulet": "Amulet",
}
const OFFHAND_WEAPON_MULT := 0.5


static func size_of(item: Dictionary) -> Vector2i:
	return FOOTPRINT.get(String(item.get("slot", "")), Vector2i(1, 1))


static func accepts(slot: String, item: Dictionary) -> bool:
	return ACCEPTS.has(slot) and (ACCEPTS[slot] as Array).has(String(item.get("slot", "")))


## Indexes of entries that an item placed at (x, y) would overlap.
static func overlapping(entries: Array, item: Dictionary, x: int, y: int) -> Array:
	var s := size_of(item)
	var out: Array = []
	for i in entries.size():
		var e: Dictionary = entries[i]
		var es := size_of(e["item"])
		if x < int(e["x"]) + es.x and int(e["x"]) < x + s.x and y < int(e["y"]) + es.y and int(e["y"]) < y + s.y:
			out.append(i)
	return out


static func in_bounds(item: Dictionary, x: int, y: int, cols: int, rows: int) -> bool:
	var s := size_of(item)
	return x >= 0 and y >= 0 and x + s.x <= cols and y + s.y <= rows


static func can_place(entries: Array, cols: int, rows: int, item: Dictionary, x: int, y: int) -> bool:
	return in_bounds(item, x, y, cols, rows) and overlapping(entries, item, x, y).is_empty()


## First free position scanning rows top to bottom, or (-1, -1).
static func find_space(entries: Array, cols: int, rows: int, item: Dictionary) -> Vector2i:
	for y in rows:
		for x in cols:
			if can_place(entries, cols, rows, item, x, y):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


static func add(entries: Array, cols: int, rows: int, item: Dictionary) -> bool:
	var p := find_space(entries, cols, rows, item)
	if p.x < 0:
		return false
	entries.append({"item": item, "x": p.x, "y": p.y})
	return true


## Index of the entry covering a cell, or -1.
static func entry_at(entries: Array, cx: int, cy: int) -> int:
	for i in entries.size():
		var e: Dictionary = entries[i]
		var s := size_of(e["item"])
		if cx >= int(e["x"]) and cx < int(e["x"]) + s.x and cy >= int(e["y"]) and cy < int(e["y"]) + s.y:
			return i
	return -1


## Repacks a grid: biggest items first, then by type, rarity and level.
## Returns the new entries, or the original list untouched if anything would not fit.
static func sorted(entries: Array, cols: int, rows: int) -> Array:
	var items: Array = []
	for e in entries:
		items.append(e["item"])
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa := size_of(a)
		var sb := size_of(b)
		if sa.y != sb.y:
			return sa.y > sb.y
		if sa.x != sb.x:
			return sa.x > sb.x
		if String(a["slot"]) != String(b["slot"]):
			return String(a["slot"]) < String(b["slot"])
		if int(a["rarity"]) != int(b["rarity"]):
			return int(a["rarity"]) > int(b["rarity"])
		return int(a["level"]) > int(b["level"]))
	var out: Array = []
	for it in items:
		if not add(out, cols, rows, it):
			return entries
	return out


## True if no entry is out of bounds or overlaps another. Used when loading saves and in tests.
static func is_valid(entries: Array, cols: int, rows: int) -> bool:
	for i in entries.size():
		var e: Dictionary = entries[i]
		if not in_bounds(e["item"], int(e["x"]), int(e["y"]), cols, rows):
			return false
		var hits := overlapping(entries, e["item"], int(e["x"]), int(e["y"]))
		if hits.size() != 1:
			return false
	return true


## Which equipment slot a right-click should send an item to.
static func best_slot(gear: Dictionary, item: Dictionary) -> String:
	match String(item.get("slot", "")):
		"ring":
			if gear.get("ring1") == null:
				return "ring1"
			if gear.get("ring2") == null:
				return "ring2"
			return "ring1"
		"weapon":
			return "weapon"
	var t := String(item.get("slot", ""))
	return t if ACCEPTS.has(t) else ""


## Total bonuses from equipped gear. A weapon in the off hand counts for half its damage.
static func gear_totals(gear: Dictionary) -> Dictionary:
	var g := {"dmg": 0.0, "armor": 0.0, "hp": 0.0, "crit": 0.0, "str": 0.0, "dex": 0.0, "vit": 0.0, "int": 0.0, "wis": 0.0,
		"crit_dmg": 0.0, "atk_speed": 0.0, "life_hit": 0.0, "cdr": 0.0, "move": 0.0}
	for slot in gear:
		var it = gear[slot]
		if it == null:
			continue
		for k in g:
			var v := float(it.get(k, 0.0))
			if k == "dmg" and slot == "offhand" and String(it.get("slot", "")) == "weapon":
				v *= OFFHAND_WEAPON_MULT
			g[k] = float(g[k]) + v
	return g
