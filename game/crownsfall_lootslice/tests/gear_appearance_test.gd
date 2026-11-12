extends Node
const Visuals := preload("res://scripts/equipment_appearance.gd")
const Systems := preload("res://scripts/systems.gd")
func _ready() -> void:
	var no_gear := {"armor": null, "weapon": null, "offhand": null}
	assert(Visuals.snapshot("warrior", no_gear).armor_family == "unarmored")
	var mail := Systems.make_variant(1, "greyfen_hauberk")
	assert(mail.art_id == "greyfen_hauberk")
	var glaive := Systems.make_variant(1, "crownspine_halberd")
	assert(Systems.two_handed(glaive))
	var ring := Systems.make_item(1, 0.0, "ring", "warrior")
	assert(Systems.footprint(ring) == Vector2i(1,1))
	var loadout := {"armor": mail, "weapon": glaive, "offhand": null}
	var state := Visuals.snapshot("warrior", loadout)
	assert(state.armor_family == "mail")
	assert(state.weapon_style == "glaive")
	assert(state.two_handed)
	assert(state.offhand_art == "")
	assert(Systems.footprint(glaive) == Vector2i(2,4))
	print("AOTL_EQUIPPED_VISUAL_QA_PASS")
	get_tree().quit(0)
