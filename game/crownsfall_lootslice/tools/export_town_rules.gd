extends SceneTree
const Actions := preload("res://scripts/town_actions.gd")
const SYS := preload("res://scripts/systems.gd")
func _initialize() -> void:
	var data: Dictionary={"schema":5,"legacy_save_filename":"crownsfall_encounter_v4.json","gold_cap":Actions.GOLD_CAP,"buyback_capacity":Actions.BUYBACK_CAP,"bag":[SYS.WIDTH,SYS.HEIGHT],"purchase_multiplier":3,"sale_and_buyback_multiplier":1,"potion_price":5,"potion_stack_cap":5,"actions":["deposit","withdraw","deposit_matching","buy","sell","buyback","potion"],"filters":["all","weapons","armour","jewellery","unique"],"one_time_upgrade_suffix":".pre-v5","service_left_inventory_right":true}
	var f:=FileAccess.open("res://data/town_ui_rules.json",FileAccess.WRITE);f.store_string(JSON.stringify(data,"  "));f.close();quit()
