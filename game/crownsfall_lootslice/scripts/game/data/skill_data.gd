@tool
class_name SkillData
extends Resource
## A hero skill, edited in the Inspector (owner rule: data in Resources, art assigned in the editor).
## The game director resolves `shape`; numbers it does not use are ignored.
@export var id := ""
@export var display_name := ""
@export var icon: Texture2D
@export_multiline var description := ""
@export_range(1, 60) var unlock_level := 1
@export var basic := false                     ## the class's primary attack (LMB by default)
@export_enum("Slash", "Cleave", "Dash", "Cast", "Bolt", "Lance", "Nova", "Judgment", "None") var animation := "Slash"   ## "None": instant (Arcane Fold)
@export_enum("arc", "line", "dash", "nova", "ground", "blink", "buff", "ward") var shape := "arc"
@export var sound := ""                        ## res://assets/audio/<sound>.wav ("" = none)
@export_group("Cost")
@export var mana_cost := 0.0
@export var cooldown := 0.0
@export_group("Numbers")
## Every other number the shape uses: dmg, range, arc, width, pierce, radius, delay, reach, gain, heal, buff_dmg,
## buff_def, duration, ward, slow, slow_t, stun, burn, knock, heal_hit, end_radius, burst.
@export var numbers: Dictionary = {}
@export_group("Upgrades")
@export var upgrades: Array[SkillMod] = []

## The flat dictionary the game director uses (same keys as before the move to resources).
func to_dict() -> Dictionary:
	var d: Dictionary = numbers.duplicate(true)
	d["id"] = id; d["name"] = display_name; d["desc"] = description; d["unlock"] = unlock_level
	d["anim"] = "" if animation == "None" else animation; d["shape"] = shape; d["cost"] = mana_cost; d["cd"] = cooldown
	d["icon"] = icon.resource_path.get_file().get_basename() if icon != null else ""
	d["icon_texture"] = icon
	if basic: d["basic"] = true
	var mods := []
	for m in upgrades:
		var md: Dictionary = m.overrides.duplicate(true)
		md["id"] = m.id; md["name"] = m.display_name; md["desc"] = m.description
		mods.append(md)
	d["mods"] = mods
	return d
