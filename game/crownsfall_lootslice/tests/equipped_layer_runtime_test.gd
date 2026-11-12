extends Node2D
const Systems := preload("res://scripts/systems.gd")
const GearLayer := preload("res://scripts/gear_visual_layer.gd")
var sprite: Sprite2D
var facing := 1
func visual_state() -> String:
	return "idle"
func _ready() -> void:
	sprite = Sprite2D.new()
	add_child(sprite)
	var layer := GearLayer.new()
	layer.actor = self
	add_child(layer)
	var chest := Systems.make_variant(1, "greyfen_hauberk")
	var polearm := Systems.make_variant(1, "crownspine_halberd")
	var gear := {"armor": chest, "weapon": polearm, "offhand": null, "helm": null, "gloves": null, "boots": null, "belt": null}
	layer.sync_gear("warrior", gear)
	assert(layer.layers["body"].visible)
	assert(layer.layers["weapon"].visible)
	assert(layer.layers["body"].texture != null)
	assert(layer.layers["weapon"].texture != null)
	assert(not layer.layers["offhand"].visible)
	assert(layer._state.armor_family == "mail")
	assert(layer._state.weapon_style == "glaive")
	# Switching to a one-handed weapon should attach the shield immediately.
	gear["weapon"] = Systems.make_variant(1, "ashensteel_short_spear")
	gear["offhand"] = Systems.make_variant(1, "greyfen_shield")
	layer.sync_gear("warrior", gear)
	assert(layer.layers["offhand"].visible)
	assert(layer.layers["offhand"].texture != null)
	assert(layer._state.weapon_style == "spear")
	assert(layer._state.offhand_style == "shield")
	# Switching back to 2H must hide the offhand, even if supplied by a stale view.
	gear["weapon"] = polearm
	layer.sync_gear("warrior", gear)
	assert(layer._state.two_handed and not layer.layers["offhand"].visible)
	gear["offhand"] = null
	gear["weapon"] = null
	layer.sync_gear("warrior", gear)
	assert(not layer.layers["weapon"].visible)
	assert(layer.layers["body"].visible)
	var mage_gear := {"armor": Systems.make_variant(1,"moonweave_robe"),"weapon":Systems.make_variant(1,"wayfarer_oak_quarterstaff"),"offhand":null,"helm":null,"gloves":null,"boots":null,"belt":null}
	layer.sync_gear("mage", mage_gear)
	assert(layer.layers["body"].visible)
	assert(layer.layers["weapon"].visible)
	assert(layer._state.armor_family == "cloth")
	assert(layer._state.two_handed)
	print("AOTL_GEAR_LAYER_RENDER_TEST_PASS")
	get_tree().quit(0)
