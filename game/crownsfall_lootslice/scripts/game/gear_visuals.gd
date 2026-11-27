extends Node
## Shows the character's equipment on the 3D hero (owner 11-27): composition, not a hero subclass. Reads the
## ClassData's ItemVisual resources (by item rarity) and applies them to the hero's own meshes:
##   weapon  -> restyles the weapon meshes (tint + emissive glow by rarity)
##   offhand -> shows / restyles the shield (Knight) or tome (Mage); hidden when no off-hand is equipped
##   armor   -> recolours the body's cloth and metal (shaders/hero_armor.gdshader) by armour tier
const ARMOR_SHADER := preload("res://shaders/hero_armor.gdshader")
var body: Node3D
var class_data: Resource
var originals := {}              # mesh instance id -> [original material per surface]
var applied := {}                # slot -> visual id (for tests)

func setup(hero_body: Node3D, cd: Resource) -> void:
	body = hero_body
	class_data = cd
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var mats := []
		for i in m.mesh.get_surface_count(): mats.append(m.mesh.surface_get_material(i))
		originals[m.get_instance_id()] = mats

func _meshes(prefix: String) -> Array:
	var out := []
	if prefix == "": return out
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with(prefix): out.append(mi)
	return out

func _visual(list: Array, item) -> Resource:
	if item == null or list.is_empty(): return null
	return list[clampi(int(item.get("rarity", 0)), 0, list.size() - 1)]

## Apply the whole gear set (slot -> item dictionary, as in game_state.gd).
func apply(gear: Dictionary) -> void:
	if body == null or class_data == null: return
	_style(_visual(class_data.weapon_visuals, gear.get("weapon")), "weapon", class_data.weapon_visuals[0].mesh_prefix if not class_data.weapon_visuals.is_empty() else "")
	var off = gear.get("offhand")
	var off_prefix: String = class_data.offhand_visuals[0].mesh_prefix if not class_data.offhand_visuals.is_empty() else ""
	for m in _meshes(off_prefix): m.visible = off != null
	_style(_visual(class_data.offhand_visuals, off), "offhand", off_prefix)
	_armor(_visual(class_data.armor_visuals, gear.get("armor")))

func _style(v: Resource, slot: String, prefix: String) -> void:
	applied[slot] = v.id if v != null else ""
	for mi in _meshes(prefix):
		var m := mi as MeshInstance3D
		var mats: Array = originals.get(m.get_instance_id(), [])
		for i in mats.size():
			var src = mats[i]
			if v == null or (v.tint == Color.WHITE and v.glow.a <= 0.0) or not src is BaseMaterial3D:
				m.set_surface_override_material(i, null)
				continue
			var mat: BaseMaterial3D = src.duplicate()
			mat.albedo_color = mat.albedo_color * v.tint
			if v.glow.a > 0.0:
				mat.emission_enabled = true
				mat.emission = Color(v.glow.r, v.glow.g, v.glow.b)
				mat.emission_energy_multiplier = 0.04 + v.glow.a * 0.16     # a faint inner light; detail stays painted
				mat.rim_enabled = true
				mat.rim = 0.35 + v.glow.a * 0.4
				mat.rim_tint = 0.9
			m.set_surface_override_material(i, mat)

func _armor(v: Resource) -> void:
	applied["armor"] = v.id if v != null else ""
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if not String(m.name).begins_with("char"): continue
		var src = originals.get(m.get_instance_id(), [null])[0]
		if v == null or (v.cloth.a <= 0.0 and v.metal.a <= 0.0) or not src is BaseMaterial3D or src.albedo_texture == null:
			m.material_override = null
			continue
		var sm := ShaderMaterial.new()
		sm.shader = ARMOR_SHADER
		sm.set_shader_parameter("albedo_tex", src.albedo_texture)
		sm.set_shader_parameter("cloth", v.cloth)
		sm.set_shader_parameter("metal", v.metal)
		sm.set_shader_parameter("roughness_v", src.roughness)
		m.material_override = sm
