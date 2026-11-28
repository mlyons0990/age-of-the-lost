@tool
class_name ClassData
extends Resource
## A playable class, edited in the Inspector. The one hero controller (scripts/three_d/rig_controller.gd) plays every
## class from this data; there are no class-specific subclasses.
@export var id := "warrior"                    ## save id ("warrior" = the Knight, "mage")
@export var display_name := "Knight"
@export var hero_name := "Sir Aldric"
@export_multiline var description := ""
@export_group("Art")
@export var hero_model: PackedScene            ## rigged 3D hero (existing GLB, kept where it is)
@export var portrait: Texture2D                ## title-screen card art (existing painted sprite)
@export var idle_sprite: Texture2D             ## 2D painted pose (existing), e.g. for NPC / UI use
@export var radiant_spells := false            ## spell VFX layer (Mage)
## Class weapon attacks: attack kind ("Slash", "Cleave", "Dash") -> {"clip": GLB animation, "t0", "t1": trim (s),
## "time": played length (s), "phase": measured contact point in the trimmed clip}. Kinds not listed play the
## shared library swing.
@export var weapon_moves: Dictionary = {}
@export_group("Start")
@export_enum("weapon", "staff") var starter_weapon := "weapon"
@export var skills: Array[SkillData] = []
@export var weapon_visuals: Array[ItemVisual] = []   ## by rarity 0-3
@export var offhand_visuals: Array[ItemVisual] = []  ## by rarity 0-3
@export var armor_visuals: Array[ItemVisual] = []    ## by rarity 0-3 (armour tier)

func skill(id_: String) -> SkillData:
	for s in skills:
		if s.id == id_: return s
	return null
