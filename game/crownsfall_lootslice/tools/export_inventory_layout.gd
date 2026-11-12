extends SceneTree
const InventoryLayout := preload("res://scripts/inventory_panel.gd")
const Systems := preload("res://scripts/systems.gd")
func _initialize() -> void:
	var slots: Dictionary={}
	for id in InventoryLayout.SLOTS:
		var r: Rect2=InventoryLayout.SLOTS[id]
		slots[id]={"x":r.position.x,"y":r.position.y,"width":r.size.x,"height":r.size.y}
	var data: Dictionary={"panel_logical_size":[InventoryLayout.BASE.x,InventoryLayout.BASE.y],"dock":"right","tabs":["equipment","character"],"backpack_columns":Systems.WIDTH,"backpack_rows":Systems.HEIGHT,"inventory_cell_pixels":50,"equipment_stage_offset":[0,142],"equipment_slots":slots,"backpack_offset":[90,614],"save_namespace":ProjectSettings.get_setting("application/config/custom_user_dir_name"),"save_schema":5,"compatible_encounter_geometry":true}
	var f:=FileAccess.open("res://data/inventory_ui_layout.json",FileAccess.WRITE);f.store_string(JSON.stringify(data,"  "));f.close();quit()
