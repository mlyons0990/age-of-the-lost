@tool
class_name ItemVisual
extends Resource
## How an equipped item shows on the hero. Weapons / off-hands restyle the hero's own weapon meshes
## (`mesh_prefix`); body armour recolours the hero's cloth and metal (armour tier). Optional `model` + `bone` attach
## a separate 3D piece (helms, pauldrons — art to come).
@export var id := ""
@export_enum("weapon", "offhand", "armor", "helm") var slot := "weapon"
@export var mesh_prefix := ""                  ## hero meshes this visual restyles ("WEAPON_", "SHIELD_", "MAGE_Staff")
@export var tint := Color.WHITE                ## multiplies the mesh colour
@export var glow := Color(0, 0, 0, 0)          ## emissive rim; alpha = strength
@export_group("Body armour tier")
@export var cloth := Color(0, 0, 0, 0)         ## recolours the cape / robe (alpha 0 = keep)
@export var metal := Color(0, 0, 0, 0)         ## tints the plate / trim (alpha 0 = keep)
@export_group("Attached model")
@export var model: PackedScene
@export var bone := ""
@export var offset := Transform3D.IDENTITY
