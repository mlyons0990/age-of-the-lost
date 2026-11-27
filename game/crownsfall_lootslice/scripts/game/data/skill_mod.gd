@tool
class_name SkillMod
extends Resource
## One of a skill's two rank-3 upgrades. `overrides` replaces the skill's numbers (e.g. {"stun": 0.6, "knock": 1.6}).
@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var overrides: Dictionary = {}
