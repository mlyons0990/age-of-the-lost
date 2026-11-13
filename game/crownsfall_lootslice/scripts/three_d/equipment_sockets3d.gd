extends Node
## Non-destructive 3D equipment sockets for AOTL's articulated Warrior.
## Actual inventory systems can call equip_scene()/unequip() without modifying
## any baked animation, imported GLB, or skinned mesh. Runtime-only attachment.

const SLOT_BONES := {
	"weapon": ["WeaponRoot", "HandR"],
	"offhand": ["ShieldRoot", "HandL"]
}

var skeleton: Skeleton3D
var model_root: Node3D
var sockets: Dictionary = {}
var equipped: Dictionary = {}
var built_in: Dictionary = {}
var original_visibility: Dictionary = {}
var available: bool = false

static func belongs_to_slot(mesh_name: String, slot: String) -> bool:
	var s := mesh_name.to_lower()
	if slot == "weapon":
		return s.contains("weapon_")
	if slot == "offhand":
		return s.contains("shield_")
	return false

func configure(imported_model: Node3D) -> bool:
	model_root = imported_model
	var candidates := model_root.find_children("*", "Skeleton3D", true, false)
	if candidates.is_empty():
		return false
	skeleton = candidates[0] as Skeleton3D
	if skeleton == null:
		return false
	for slot in ["weapon", "offhand"]:
		var bone_name := ""
		for option in SLOT_BONES[slot]:
			if skeleton.find_bone(option) >= 0:
				bone_name = option
				break
		if bone_name.is_empty():
			continue
		var socket := BoneAttachment3D.new()
		socket.name = "EquipmentSocket_" + slot
		socket.bone_name = bone_name
		socket.override_pose = false
		skeleton.add_child(socket)
		sockets[slot] = socket
		equipped[slot] = null
		built_in[slot] = []
	for candidate in model_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := candidate as MeshInstance3D
		for slot in sockets:
			if belongs_to_slot(mesh.name, slot):
				built_in[slot].append(mesh)
				original_visibility[mesh.get_instance_id()] = mesh.visible
	available = not sockets.is_empty()
	return available

func has_slot(slot: String) -> bool:
	return sockets.has(slot)

func get_socket(slot: String) -> BoneAttachment3D:
	return sockets.get(slot) as BoneAttachment3D

func equip_scene(slot: String, scene: PackedScene, local_offset: Transform3D = Transform3D.IDENTITY) -> bool:
	if not has_slot(slot) or scene == null:
		return false
	var instance := scene.instantiate()
	var item := instance as Node3D
	if item == null:
		instance.free()
		return false
	if not equip_node(slot, item, local_offset):
		item.free()
		return false
	return true

func equip_node(slot: String, item: Node3D, local_offset: Transform3D = Transform3D.IDENTITY) -> bool:
	if not has_slot(slot) or item == null or item.get_parent() != null:
		return false
	unequip(slot)
	var socket := get_socket(slot)
	socket.add_child(item)
	item.transform = local_offset
	equipped[slot] = item
	_set_builtin_visibility(slot, false)
	return true

func unequip(slot: String) -> void:
	if not has_slot(slot):
		return
	var item: Node3D = equipped.get(slot) as Node3D
	if is_instance_valid(item):
		item.queue_free()
	equipped[slot] = null
	_set_builtin_visibility(slot, true)

func unequip_all() -> void:
	for slot in sockets:
		unequip(slot)

func _set_builtin_visibility(slot: String, restore: bool) -> void:
	for mesh in built_in.get(slot, []):
		if not is_instance_valid(mesh):
			continue
		var original := bool(original_visibility.get(mesh.get_instance_id(), true))
		mesh.visible = original if restore else false

func status() -> Dictionary:
	var out := {}
	for slot in ["weapon", "offhand"]:
		out[slot] = {
			"socket": get_socket(slot).bone_name if has_slot(slot) else "",
			"equipped": is_instance_valid(equipped.get(slot)),
			"builtin_mesh_count": (built_in[slot] as Array).size() if has_slot(slot) else 0
		}
	return out
