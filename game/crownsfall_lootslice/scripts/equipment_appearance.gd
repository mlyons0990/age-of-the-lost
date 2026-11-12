extends RefCounted
## Deterministic, display-only appearance resolved from the equipped item data.
## Shared between the 2D actor overlay and future 3D mesh/socket layers.
const Systems := preload("res://scripts/systems.gd")

static func item_art_id(item: Variant) -> String:
	if not item is Dictionary:
		return ""
	var id := String(item.get("art_id", ""))
	if Systems.VARIANT_SPECS.has(id) and Systems.VARIANT_SPECS[id].slot == item.get("slot"):
		return id
	return String(item.get("unique_id", item.get("slot", "")))

static func armor_family(item: Variant, class_id: String) -> String:
	if not item is Dictionary:
		return "cloth" if class_id == "mage" else "unarmored"
	var id := String(item.get("art_id", ""))
	if Systems.VARIANT_SPECS.has(id):
		var family := String(Systems.VARIANT_SPECS[id].get("armor_family", ""))
		if family in ["cloth", "leather", "mail", "plate"]:
			return family
	var slot := String(item.get("slot", ""))
	if slot == "robe":
		return "cloth"
	return "plate" if slot == "armor" else ("cloth" if class_id == "mage" else "unarmored")

static func weapon_style(item: Variant) -> String:
	if not item is Dictionary:
		return ""
	var id := String(item.get("art_id", ""))
	if Systems.VARIANT_SPECS.has(id):
		return String(Systems.VARIANT_SPECS[id].get("weapon_style", item.get("slot", "")))
	var slot := String(item.get("slot", ""))
	match slot:
		"weapon": return "sword"
		"offhand": return "shield"
		_: return slot

static func snapshot(class_id: String, gear: Dictionary) -> Dictionary:
	var body: Variant = gear.get("armor")
	var weapon: Variant = gear.get("weapon")
	var offhand: Variant = gear.get("offhand")
	var two_handed := weapon is Dictionary and Systems.two_handed(weapon)
	return {
		"class_id": class_id,
		"armor_family": armor_family(body, class_id),
		"head_art": item_art_id(gear.get("helm")),
		"body_art": item_art_id(body),
		"gloves_art": item_art_id(gear.get("gloves")),
		"boots_art": item_art_id(gear.get("boots")),
		"belt_art": item_art_id(gear.get("belt")),
		"weapon_art": item_art_id(weapon),
		"weapon_style": weapon_style(weapon),
		"two_handed": two_handed,
		"offhand_art": "" if two_handed else item_art_id(offhand),
		"offhand_style": "" if two_handed else weapon_style(offhand),
		"mainhand_name": String(weapon.get("name", "")) if weapon is Dictionary else "",
		"offhand_name": "" if two_handed else (String(offhand.get("name", "")) if offhand is Dictionary else ""),
	}

static func signature(class_id: String, gear: Dictionary) -> String:
	var state := snapshot(class_id, gear)
	return JSON.stringify(state)
