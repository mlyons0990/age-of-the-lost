extends SceneTree
## Headless socket regression test:
## godot --headless --path game/crownsfall_lootslice --script res://tests/equipment_socket_integration.gd
const SOCKETS := preload("res://scripts/three_d/equipment_sockets3d.gd")

func _make_mock() -> Node3D:
	var model := Node3D.new()
	model.name = "MockWarrior"
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	model.add_child(skeleton)
	var hand_l := skeleton.add_bone("HandL")
	var shield := skeleton.add_bone("ShieldRoot")
	skeleton.set_bone_parent(shield, hand_l)
	var hand_r := skeleton.add_bone("HandR")
	var weapon := skeleton.add_bone("WeaponRoot")
	skeleton.set_bone_parent(weapon, hand_r)
	var sword := MeshInstance3D.new()
	sword.name = "V03_WEAPON_ForgedSwordBlade"
	model.add_child(sword)
	var shield_mesh := MeshInstance3D.new()
	shield_mesh.name = "SHIELD_Front"
	model.add_child(shield_mesh)
	return model

func _initialize() -> void:
	var checks := 0
	assert(SOCKETS.belongs_to_slot("V03_WEAPON_ForgedSwordBlade", "weapon"))
	checks += 1
	assert(SOCKETS.belongs_to_slot("SHIELD_Front", "offhand"))
	checks += 1
	assert(not SOCKETS.belongs_to_slot("V04_SKIN_ArticulatedArmR", "weapon"))
	checks += 1
	var no_model := Node3D.new()
	var missing := SOCKETS.new()
	assert(not missing.configure(no_model))
	checks += 1
	var model := _make_mock()
	var component := SOCKETS.new()
	assert(component.configure(model))
	checks += 1
	assert(component.has_slot("weapon") and component.has_slot("offhand"))
	checks += 1
	var sword_mesh := model.get_node("V03_WEAPON_ForgedSwordBlade") as MeshInstance3D
	assert(sword_mesh.visible)
	var preview := MeshInstance3D.new()
	assert(component.equip_node("weapon", preview))
	checks += 1
	assert(not sword_mesh.visible)
	checks += 1
	assert(component.status()["weapon"]["equipped"])
	checks += 1
	component.unequip("weapon")
	assert(sword_mesh.visible)
	checks += 1
	assert(not component.status()["weapon"]["equipped"])
	checks += 1
	var invalid := MeshInstance3D.new()
	assert(not component.equip_node("nonexistent", invalid))
	checks += 1
	invalid.free()
	component.free()
	missing.free()
	model.free()
	no_model.free()
	print("AOTL equipment socket checks passed: ", checks)
	quit(0)
