extends Node
const Systems := preload("res://scripts/systems.gd")
const Player := preload("res://scripts/player.gd")
class FakeAudio:
	extends RefCounted
	var calls := 0
	func play_cue(_id: String) -> void:
		calls += 1
class FakeAura:
	extends RefCounted
	func stop(_why: String) -> void:
		pass
class FakeMain:
	extends Node2D
	var save_ok := true
	var save_calls := 0
	var sound = FakeAudio.new()
	var save_error := ""
	func persist_changes(_changes: Dictionary) -> bool:
		save_calls += 1
		return save_ok
func _ready() -> void:
	var actor = Player.new()
	var mock := FakeMain.new()
	actor.main = mock
	actor.aura = FakeAura.new()
	actor.level = 1
	actor.class_id = "warrior"
	actor.inventory = [Systems.make_variant(1,"greyfen_hauberk"),Systems.make_variant(1,"crownspine_halberd")]
	assert(actor.equip_item(0,"armor"))
	assert(actor.gear.armor.art_id == "greyfen_hauberk")
	assert(actor.inventory.size() == 1)
	assert(actor.equip_item(0,"weapon"))
	assert(actor.gear.weapon.art_id == "crownspine_halberd")
	assert(Systems.two_handed(actor.gear.weapon))
	assert(actor.inventory.is_empty())
	# A 2H weapon cannot coexist with an offhand; rejected without mutations.
	assert(not actor.preview_equipment(Systems.make_item(1,0.0,"offhand"),"offhand").ok)
	assert(actor.unequip_item("weapon"))
	assert(actor.inventory.size() == 1)
	assert(actor.inventory[0].art_id == "crownspine_halberd")
	# Failed save must not modify equipped gear or inventory.
	mock.save_ok = false
	assert(not actor.unequip_item("armor"))
	assert(actor.gear.armor.art_id == "greyfen_hauberk")
	assert(actor.inventory.size() == 1)
	# Item-art identity survives the existing clean/save schema.
	var raw: Dictionary = actor.inventory[0].duplicate(true)
	var restored := Systems.clean_item(raw)
	assert(restored.art_id == raw.art_id)
	assert(Systems.footprint(restored) == Vector2i(2,4))
	# The same optional art ID survives JSON serialization and existing clean_item.
	var json_item: Variant = JSON.parse_string(JSON.stringify(restored))
	assert(json_item is Dictionary)
	assert(Systems.clean_item(json_item).art_id == "crownspine_halberd")
	# Mages must never equip mail-tagged Warrior variants, even if the slot fits.
	assert(not Systems.class_allows(Systems.make_variant(1,"greyfen_belt"),"mage"))
	# Legacy generic plate/sword/shield still produce a correct appearance signature.
	var appearance = load("res://scripts/equipment_appearance.gd")
	var base_gear = {"armor":Systems.make_item(1,0.0,"armor"),"weapon":Systems.make_item(1,0.0,"weapon"),"offhand":Systems.make_item(1,0.0,"offhand")}
	var base_state: Dictionary = appearance.snapshot("warrior",base_gear)
	assert(base_state.armor_family == "plate")
	assert(base_state.weapon_style == "sword")
	assert(base_state.offhand_style == "shield")
	print("AOTL_EQUIP_TRANSACTIONS_PASS ",mock.save_calls)
	actor.free()
	mock.free()
	get_tree().quit(0)
