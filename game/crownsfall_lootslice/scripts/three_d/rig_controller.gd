extends CharacterBody3D
## Playable articulated GLB rig. Movement and attacks are controlled in 3D.
## Animation clips are real glTF skeleton keyframes imported by Godot.

signal impact(at: Vector3, kind: String, direction: Vector3)
signal health_changed(current: float, maximum: float)

const LEGACY_MODEL := preload("res://models/AOTL_Wayfarer_Articulated_Proxy.glb")
const WARRIOR_R40 := "res://models/AOTL_Warrior_R40.glb"
const WARRIOR_R50_SLASH_CANDIDATE := "res://models/AOTL_Warrior_R50_SevenClip_Candidate.glb"
const WARRIOR_R52_RIGID_ARMOR_CANDIDATE := "res://models/AOTL_Warrior_R52_RigidArmor_SevenClip.glb"
## R53: R52 plus rebuilt arm skin weights (tools/r53_arm_reweight.py); opt-in only.
const WARRIOR_R53_ARM_SKIN_CANDIDATE := "res://models/AOTL_Warrior_R53_ArmSkin_SevenClip.glb"
## R54: R53 plus the half-swing Elbow helper joint (tools/r54_elbow_helper.py); opt-in only.
const WARRIOR_R54_ELBOW_HELPER_CANDIDATE := "res://models/AOTL_Warrior_R54_ElbowHelper_SevenClip.glb"
## R55: R54 with clip-safe elbow skin and inner-elbow scalloped forearm guards (tools/r55_clip_safe_elbow.py); opt-in.
const WARRIOR_R55_CLIP_SAFE_ELBOW_CANDIDATE := "res://models/AOTL_Warrior_R55_ClipSafeElbow_SevenClip.glb"
## Higgsfield pilot knight: Meshy 7 mesh + 24-bone auto-rig, our clips retargeted, library Roll_Dodge/Dead,
## R52 sword and shield skinned to the hands. Opt-in only (art/higgsfield-pilot-knight branch).
const PILOT_KNIGHT := "res://models/higgsfield_pilot/knight_pilot_armed.glb"
## Higgsfield Phase 1 Mage: same Meshy 24-bone rig family; clips shared with the knight (opt-in).
const PILOT_MAGE := "res://models/higgsfield_mage/mage_pilot_armed.glb"
## Every Meshy-rigged hero uses the same controller path ("pilot heroes").
const PILOT_SOURCES := ["pilot_knight_opt_in", "pilot_mage_opt_in"]
const PILOT_KNIGHT_BONES := ["Hips", "Spine", "Head", "LeftUpLeg", "LeftLeg", "LeftFoot", "RightUpLeg", "RightLeg", "RightFoot", "LeftHand", "RightHand"]
## Knight locomotion (measured in Godot 2026-11-20, foot speed at ground contact). Each controller mode uses
## the clip whose natural stride fits it, with playback scaled so the planted foot matches the body speed:
##   Walk (default 4.3 m/s) -> our retargeted Run (a jog, 3.80 m/s)       x1.13, ~3.6 steps/s
##   Run  (Shift, 6.7 m/s)  -> library RunFast #16 (sprint, 9.41 m/s)    x0.71, ~2.8 steps/s
##   Stroll (Ctrl, 1.0 m/s) -> library Casual_Walk #30 (0.72 m/s)        x1.39, ~3.0 steps/s
const PILOT_STRIDE_SPEED := {"Walk": 3.80, "Run": 9.41, "Stroll": 0.72}
const PILOT_STROLL_SPEED := 1.0
## Arms carry sword and shield steady while moving (library locomotion clips are unarmed motions).
const ARM_CARRY := preload("res://scripts/three_d/arm_carry_modifier.gd")
const PILOT_ARM_BONES := ["RightShoulder", "RightArm", "RightForeArm", "RightHand", "LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand"]
const PILOT_CARRY_WEIGHT := {"Walk": 0.8, "Run": 0.9, "Stroll": 0.75}
var arm_carry: SkeletonModifier3D = null
var arm_carry_target := 0.0
const PILOT_ROLL_TIME := 0.9
## Library Left_Slash (#97): the knight's right-hand sword attack. The first 1.42 s (wind-up through the
## main cut) is used; the blade crosses the front at 0.81 s = 57 % of that, the shared contact phase.
const PILOT_SLASH_END := 1.42
const PILOT_SLASH_TIME := 0.9
## Pilot Mage spell set (paid library casts, approved 2026-11-20). Each spell plays its own clip, trimmed to
## [t0, t1] s and time-scaled to `time`; `phase` is the measured release (hand-speed peak / arm extension) in
## the trimmed clip, where the controller emits `impact`. LMB / Q / E / R on the Mage (1 / 2 / 3 too in legacy labs).
const MAGE_SPELLS := {
	"Bolt":     {"clip": "Cast_Bolt",  "t0": 0.17, "t1": 2.42, "time": 1.25, "phase": 0.33, "cd": 0.0, "reach": 6.0, "cost": 6.0},
	"Lance":    {"clip": "Cast_Lunge", "t0": 0.0,  "t1": 3.38, "time": 2.0,  "phase": 0.31, "cd": 3.0, "reach": 4.5, "cost": 18.0},
	"Nova":     {"clip": "Cast_Nova",  "t0": 0.0,  "t1": 2.71, "time": 1.8,  "phase": 0.69, "cd": 5.0, "reach": 0.0, "cost": 30.0},
	"Judgment": {"clip": "Cast_Sweep", "t0": 0.12, "t1": 2.12, "time": 1.5,  "phase": 0.34, "cd": 3.5, "reach": 3.2, "cost": 24.0},
}
const PILOT_SWORD_HAND := "RightHand"   # the 1.83 s library roll is played at ~2x to fit the dodge window
const WARRIOR_R39 := "res://models/AOTL_Warrior_R39.glb"
const WARRIOR_R37 := "res://models/AOTL_Warrior_R37.glb"
const WARRIOR_R36 := "res://models/AOTL_Warrior_R36.glb"
const TERRAIN_IK := preload("res://scripts/three_d/terrain_foot_ik.gd")
const EQUIPMENT_SOCKETS := preload("res://scripts/three_d/equipment_sockets3d.gd")
const WEAPON_SWEEP := preload("res://scripts/three_d/weapon_sweep3d.gd")
const WALK_SPEED := 4.3
const RUN_SPEED := 6.7
const DODGE_SPEED := 10.5
const GRAVITY := 24.0

var animation: AnimationPlayer = null
var body: Node3D
var camera: Camera3D
var max_hp := 130.0
var hp := 130.0
var attack_t := 0.0
var attack_duration := 0.72
var attack_serial := 0
var attack_type := "Slash"
var has_impacted := false
var dodge_t := 0.0
var spell_cd := 0.0
## Mana (ARPG HUD globe). Mage spells cost MAGE_SPELLS[..]["cost"]; the Warrior's Cast costs WARRIOR_CAST_COST.
var max_mana := 120.0
var mana := 120.0
const MANA_REGEN := 6.0
const WARRIOR_CAST_COST := 20.0
## Number keys 1/2/3 trigger skills (legacy labs). The ARPG HUD turns this off: 1-5 are potions, skills are Q E R.
var number_keys_for_skills := true
## Click-to-move (Diablo / PoE / Last Epoch style), enabled by the ARPG HUD labs: LMB on the ground moves (hold to
## follow the cursor), LMB on an enemy walks into range and attacks, Shift+LMB attacks in place, Q W E R T cast
## toward the cursor, Space dodges toward the cursor. WASD is ignored in this mode.
var click_to_move := false
var move_target := Vector3.INF          # ground point to walk to (INF = none)
var attack_target: Node3D = null        # enemy to approach and attack
var aim_point := Vector3.INF            # cursor on the ground, updated by the lab every frame
const ARRIVE_RADIUS := 0.18
const MELEE_RANGE := 1.6
## Current Mage spell ("" for the generic Cast); cooldowns per spell.
var spell_variant := ""
var spell_cds := {}
var attack_cd := 0.0
var dodge_cd := 0.0
var invulnerable := 0.0
var last_face := Vector3(0, 0, -1)
var anim_state := ""
var clip_names: Dictionary = {}
var terrain_foot_ik: Node3D = null
var terrain_ik_available := false
var active_model_source := "legacy_proxy"
var terrain_ik_enabled := true
var terrain_ik_debug := false
var equipment_sockets: Node = null
var equipment_sockets_available := false
var equipment_debug_equipped := false
# Opt-in only; preserve the existing validated R39/R40 model by default.
@export var enable_r50_fullbody_slash_candidate := false
@export var enable_r52_rigid_armor_candidate := false
@export var enable_r53_arm_skin_candidate := false
@export var enable_r54_elbow_helper_candidate := false
@export var enable_r55_clip_safe_elbow_candidate := false
@export var enable_pilot_knight_candidate := false
@export var enable_pilot_mage_candidate := false

func is_pilot_hero() -> bool:
	return active_model_source in PILOT_SOURCES

## The pilot knight uses Meshy's humanoid bone names and a library roll in place of Dodge.
func _pilot_knight_is_valid(candidate: Node3D) -> bool:
	var rigs := candidate.find_children("*", "Skeleton3D", true, false)
	if rigs.is_empty():
		return false
	var sk := rigs[0] as Skeleton3D
	for bone_name in PILOT_KNIGHT_BONES:
		if sk.find_bone(bone_name) < 0:
			return false
	var player := candidate.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player == null:
		return false
	for required_clip in ["Idle", "Walk", "Run", "Roll_Dodge", "Slash", "Cast"]:
		if not player.has_animation(required_clip):
			return false
	return true

func _production_model_is_valid(candidate: Node3D) -> bool:
	# Do not switch the playable actor solely because an R36 file exists.
	var rigs := candidate.find_children("*", "Skeleton3D", true, false)
	if rigs.is_empty():
		return false
	var sk := rigs[0] as Skeleton3D
	if sk == null:
		return false
	for bone_name in ["Root", "Hips", "ThighL", "KneeL", "ShinL", "AnkleL", "ThighR", "KneeR", "ShinR", "AnkleR"]:
		if sk.find_bone(bone_name) < 0:
			return false
	var player := candidate.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player == null:
		return false
	var available: Dictionary = {}
	for anim_name in player.get_animation_list():
		var short_name := String(anim_name).get_file()
		short_name = short_name.get_slice("|", short_name.get_slice_count("|") - 1)
		available[short_name] = true
	for required_clip in ["Idle", "Walk", "Run", "Dodge", "Slash", "Cast"]:
		if not available.has(required_clip):
			return false
	return true

func _ready() -> void:
	# R40 is the full-pose six-clip candidate. Retain every earlier export as fallback.
	body = LEGACY_MODEL.instantiate()
	var model_candidates: Array = [
		{"path": WARRIOR_R40, "source": "warrior_r40"},
		{"path": WARRIOR_R39, "source": "warrior_r39"},
		{"path": WARRIOR_R37, "source": "warrior_r37"},
		{"path": WARRIOR_R36, "source": "warrior_r36"}
	]
	if enable_r50_fullbody_slash_candidate:
		model_candidates.push_front({"path": WARRIOR_R50_SLASH_CANDIDATE, "source": "warrior_r50_opt_in"})
	if enable_r52_rigid_armor_candidate:
		model_candidates.push_front({"path": WARRIOR_R52_RIGID_ARMOR_CANDIDATE, "source": "warrior_r52_opt_in"})
	if enable_r53_arm_skin_candidate:
		model_candidates.push_front({"path": WARRIOR_R53_ARM_SKIN_CANDIDATE, "source": "warrior_r53_opt_in"})
	if enable_r54_elbow_helper_candidate:
		model_candidates.push_front({"path": WARRIOR_R54_ELBOW_HELPER_CANDIDATE, "source": "warrior_r54_opt_in"})
	if enable_r55_clip_safe_elbow_candidate:
		model_candidates.push_front({"path": WARRIOR_R55_CLIP_SAFE_ELBOW_CANDIDATE, "source": "warrior_r55_opt_in"})
	if enable_pilot_knight_candidate:
		model_candidates.push_front({"path": PILOT_KNIGHT, "source": "pilot_knight_opt_in"})
	if enable_pilot_mage_candidate:
		model_candidates.push_front({"path": PILOT_MAGE, "source": "pilot_mage_opt_in"})
	for option in model_candidates:
		var path: String = option["path"]
		if not ResourceLoader.exists(path):
			continue
		var packed := ResourceLoader.load(path, "PackedScene") as PackedScene
		if packed == null:
			continue
		var candidate := packed.instantiate() as Node3D
		var valid := candidate != null and (_pilot_knight_is_valid(candidate) if option["source"] in PILOT_SOURCES else _production_model_is_valid(candidate))
		if valid:
			body.free()
			body = candidate
			active_model_source = option["source"]
			break
		if candidate != null:
			candidate.free()
		push_warning("AOTL asset rejected at runtime: " + path + " (missing required skeleton or clips).")

	add_child(body)
	animation = body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation != null:
		for name in animation.get_animation_list():
			var logical := String(name).get_file().get_slice("|", String(name).get_file().get_slice_count("|") - 1)
			clip_names[logical] = name
			if logical in ["Idle", "Walk", "Run", "V33_KneeStable_IK_Comparison"]:
				if logical == "V33_KneeStable_IK_Comparison":
					clip_names["WalkIK_Test"] = name
				animation.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	# Remap only the opt-in R50's Slash. The original Slash remains in the
	# GLB and the older models' animation mappings are never altered.
	if active_model_source in ["warrior_r50_opt_in", "warrior_r52_opt_in", "warrior_r53_opt_in", "warrior_r54_opt_in", "warrior_r55_opt_in"] and clip_names.has("Slash_FullBody_R50"):
		clip_names["Slash"] = clip_names["Slash_FullBody_R50"]
	if is_pilot_hero():
		_prepare_pilot_knight_clips()
		_prepare_pilot_blade()
		model_yaw_offset = PI
		body.rotation.y = PI
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.26
	capsule.height = 1.95
	var col := CollisionShape3D.new()
	col.shape = capsule
	col.position = Vector3(0, 1, 0)
	add_child(col)
	_play("Idle")
	# Optional: older proxy skeletons continue running without terrain IK.
	terrain_foot_ik = TERRAIN_IK.new()
	terrain_foot_ik.name = "TerrainFootIK"
	add_child(terrain_foot_ik)
	terrain_ik_available = terrain_foot_ik.configure(body, self, animation)
	# Optional equipment sockets. Old proxies without attachment bones remain playable.
	equipment_sockets = EQUIPMENT_SOCKETS.new()
	equipment_sockets.name = "WarriorEquipmentSockets"
	add_child(equipment_sockets)
	equipment_sockets_available = equipment_sockets.configure(body)


func _toggle_terrain_ik() -> void:
	if not terrain_ik_available:
		return
	terrain_ik_enabled = not terrain_ik_enabled
	terrain_foot_ik.enabled = terrain_ik_enabled
	terrain_foot_ik.reset_contact_state()


func _toggle_terrain_ik_debug() -> void:
	if not terrain_ik_available:
		return
	terrain_ik_debug = not terrain_ik_debug
	terrain_foot_ik.set_debug_visible(terrain_ik_debug)


func equip_weapon_scene(scene: PackedScene, local_offset: Transform3D = Transform3D.IDENTITY) -> bool:
	if not equipment_sockets_available:
		return false
	return equipment_sockets.equip_scene("weapon", scene, local_offset)

func equip_offhand_scene(scene: PackedScene, local_offset: Transform3D = Transform3D.IDENTITY) -> bool:
	if not equipment_sockets_available:
		return false
	return equipment_sockets.equip_scene("offhand", scene, local_offset)

func unequip_slot(slot: String) -> void:
	if equipment_sockets_available:
		equipment_sockets.unequip(slot)

func _debug_equipment_item(slot: String) -> MeshInstance3D:
	var debug := MeshInstance3D.new()
	debug.name = "Debug_" + slot
	var mesh := BoxMesh.new()
	if slot == "weapon":
		mesh.size = Vector3(0.075, 0.075, 0.8)
	else:
		mesh.size = Vector3(0.42, 0.6, 0.08)
	debug.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("e9bf70") if slot == "weapon" else Color("6fa4df")
	debug.material_override = mat
	debug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return debug

func _toggle_equipment_socket_preview() -> void:
	if not equipment_sockets_available:
		return
	equipment_debug_equipped = not equipment_debug_equipped
	if not equipment_debug_equipped:
		equipment_sockets.unequip_all()
		return
	for slot in ["weapon", "offhand"]:
		if equipment_sockets.has_slot(slot):
			var offset := Transform3D.IDENTITY
			if slot == "weapon":
				offset.origin = Vector3(0, 0.0, -0.38)
			else:
				offset.origin = Vector3(0, -0.08, 0)
			equipment_sockets.equip_node(slot, _debug_equipment_item(slot), offset)


## Pilot knight: blade hilt/tip in the sword-hand bone's space, from the real crossguard and tip meshes.
var pilot_blade := {}
## The hand-built rigs face −Z; the Meshy knight faces +Z (glTF forward), so it turns an extra half circle.
var model_yaw_offset := 0.0

func _prepare_pilot_blade() -> void:
	var sk := body.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var points := {}
	for part in [["hilt", "WEAPON_Crossguard"], ["tip", "WEAPON_Tip"]]:
		var mi := body.find_child(part[1] + "*", true, false) as MeshInstance3D
		if mi == null or mi.skin == null:
			return
		for i in mi.skin.get_bind_count():
			var b := mi.skin.get_bind_bone(i)
			var name := sk.get_bone_name(b) if b >= 0 else String(mi.skin.get_bind_name(i))
			if name == PILOT_SWORD_HAND:
				points[part[0]] = mi.skin.get_bind_pose(i) * mi.mesh.get_aabb().get_center()
	if points.size() == 2:
		pilot_blade = {"skeleton": sk, "bone": sk.find_bone(PILOT_SWORD_HAND), "hilt": points["hilt"], "tip": points["tip"]}

## World-space blade segment for swept hit tests, or {} when this model has none.
func blade_segment() -> Dictionary:
	if pilot_blade.is_empty():
		return {}
	var sk: Skeleton3D = pilot_blade["skeleton"]
	var pose: Transform3D = sk.global_transform * sk.get_bone_global_pose(int(pilot_blade["bone"]))
	return {"hilt": pose * (pilot_blade["hilt"] as Vector3), "tip": pose * (pilot_blade["tip"] as Vector3)}

## Pilot knight: Dodge plays the library roll in place (the controller moves the body), Death plays Dead.
func _prepare_pilot_knight_clips() -> void:
	clip_names["Dodge"] = clip_names["Roll_Dodge"]
	if clip_names.has("RunFast") and clip_names.has("Casual_Walk"):
		clip_names["Walk"] = clip_names["Run"]          # retargeted jog for default movement
		clip_names["Run"] = clip_names["RunFast"]
		clip_names["Stroll"] = clip_names["Casual_Walk"]
		for c in ["RunFast", "Casual_Walk"]:
			animation.get_animation(clip_names[c]).loop_mode = Animation.LOOP_LINEAR
	_setup_arm_carry()
	if clip_names.has("Left_Slash"):
		var trimmed := _trimmed(animation.get_animation(clip_names["Left_Slash"]), 0.0, PILOT_SLASH_END)
		animation.get_animation_library("").add_animation("Pilot_Slash", trimmed)
		clip_names["Slash"] = "Pilot_Slash"
	if clip_names.has("Dead"):
		clip_names["Death"] = clip_names["Dead"]
	# Mage spells: trimmed copies named Mage_<Spell> (the paid source clips stay untouched in the GLB).
	for spell in MAGE_SPELLS:
		var spec: Dictionary = MAGE_SPELLS[spell]
		if clip_names.has(spec["clip"]):
			var src := animation.get_animation(clip_names[spec["clip"]])
			var cut := _trimmed(src, spec["t0"], minf(spec["t1"], src.length))
			animation.get_animation_library("").add_animation("Mage_" + spell, cut)
			clip_names["Mage_" + spell] = "Mage_" + spell
	var roll := animation.get_animation(clip_names["Roll_Dodge"])
	var sk := body.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	for t in roll.get_track_count():
		if roll.track_get_type(t) != Animation.TYPE_POSITION_3D or not String(roll.track_get_path(t)).ends_with(":Hips"):
			continue
		# keep the height (the tuck), drop the forward travel (root motion handled by the controller)
		var first: Vector3 = roll.track_get_key_value(t, 0)
		for k in roll.track_get_key_count(t):
			var v: Vector3 = roll.track_get_key_value(t, k)
			roll.track_set_key_value(t, k, Vector3(first.x, v.y, first.z))

## Carry pose = the arms of the Idle's first frame (sword raised ready in the right hand, shield on the left).
func _setup_arm_carry() -> void:
	var sk := body.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animation.play(clip_names["Idle"], 0)
	animation.seek(0.0, true)
	var rots := []
	for n in PILOT_ARM_BONES:
		rots.append(sk.get_bone_pose_rotation(sk.find_bone(n)))
	arm_carry = ARM_CARRY.new()
	arm_carry.name = "ArmCarryModifier"
	sk.add_child(arm_carry)
	arm_carry.setup(sk, PILOT_ARM_BONES, rots)
	arm_carry.influence = 0.0

## Copy of `src` keeping only keys in [t0, t1], shifted to start at 0.
static func _trimmed(src: Animation, t0: float, t1: float) -> Animation:
	var out := Animation.new()
	out.length = t1 - t0
	for t in src.get_track_count():
		var nt := out.add_track(src.track_get_type(t))
		out.track_set_path(nt, src.track_get_path(t))
		out.track_set_interpolation_type(nt, src.track_get_interpolation_type(t))
		for k in src.track_get_key_count(t):
			var time := src.track_get_key_time(t, k)
			if time >= t0 - 0.0001 and time <= t1 + 0.0001:
				out.track_insert_key(nt, time - t0, src.track_get_key_value(t, k))
	return out

func _play(clip: String) -> void:
	if animation == null or not clip_names.has(clip):
		return
	if anim_state != clip:
		var speed := 1.0
		if is_pilot_hero() and clip == "Dodge":
			speed = animation.get_animation(clip_names[clip]).length / PILOT_ROLL_TIME
		elif clip == "Cast" and spell_variant != "" and String(clip_names[clip]).begins_with("Mage_"):
			var spec: Dictionary = MAGE_SPELLS[spell_variant]
			speed = (float(spec["t1"]) - float(spec["t0"])) / float(spec["time"])
		elif is_pilot_hero() and clip == "Slash" and clip_names[clip] == "Pilot_Slash":
			speed = PILOT_SLASH_END / PILOT_SLASH_TIME
		elif is_pilot_hero() and PILOT_STRIDE_SPEED.has(clip):
			var body_speed: float = {"Walk": WALK_SPEED, "Run": RUN_SPEED, "Stroll": PILOT_STROLL_SPEED}[clip]
			speed = body_speed / float(PILOT_STRIDE_SPEED[clip])
		animation.play(clip_names[clip], 0.16, speed)
		anim_state = clip
		arm_carry_target = float(PILOT_CARRY_WEIGHT.get(clip, 0.0))

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if click_to_move and not (event is InputEventKey and event.keycode in [KEY_F9, KEY_F10, KEY_F11]):
		return   # ARPG HUD mode: every action comes through the rebindable key map (arpg_hud.gd / keybinds.gd)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_mage_or("Bolt", "Slash", 0.72)
	elif event is InputEventKey:
		match event.keycode:
			KEY_F9: _toggle_terrain_ik()
			KEY_F10: _toggle_terrain_ik_debug()
			KEY_F11: _toggle_equipment_socket_preview()
			KEY_SPACE:
				if click_to_move: _face_aim()
				_dodge()
			# Click-to-move: skills on Q W E (R T reserved), cast toward the cursor.
			# Legacy WASD labs: W is movement, so the skill row is Q / E / R.
			KEY_Q: _skill(0)
			KEY_W:
				if click_to_move: _skill(1)
			KEY_E: _skill(1 if not click_to_move else 2)
			KEY_R:
				if not click_to_move: _skill(2)
			KEY_1:
				if number_keys_for_skills: _mage_or("Lance", "Cleave", 0.76)
			KEY_2:
				if number_keys_for_skills: _mage_or("Nova", "Dash", 0.68)
			KEY_3:
				if number_keys_for_skills: _mage_or("Judgment", "Cast", 1.4)

func _skill(i: int) -> void:
	if click_to_move:
		_face_aim()
		stop_moving()
	match i:
		0: _mage_or("Lance", "Cleave", 0.76)
		1: _mage_or("Nova", "Dash", 0.68)
		2: _mage_or("Judgment", "Cast", 1.4)

## Use a skill by name (from a skill-bar slot), toward the cursor in click-to-move mode.
const WARRIOR_SKILLS := {"Slash": 0.72, "Cleave": 0.76, "Dash": 0.68, "Cast": 1.4}
func use_skill(skill_name: String) -> void:
	if click_to_move:
		_face_aim()
		stop_moving()
	if MAGE_SPELLS.has(skill_name) and is_pilot_mage():
		cast_spell(skill_name)
	elif WARRIOR_SKILLS.has(skill_name):
		_attack(skill_name, WARRIOR_SKILLS[skill_name])

func dodge_toward_aim() -> void:
	_face_aim()
	stop_moving()
	_dodge()

func is_pilot_mage() -> bool:
	return active_model_source == "pilot_mage_opt_in" and clip_names.has("Mage_Judgment")

func _mage_or(spell: String, kind: String, duration: float) -> void:
	if is_pilot_mage():
		cast_spell(spell)
	else:
		_attack(kind, duration)

## Mage spell: all are "Cast" attacks for combat, with their own clip, timing, release phase and cooldown.
func cast_spell(spell: String) -> bool:
	if not MAGE_SPELLS.has(spell) or attack_t > 0.0 or dodge_t > 0.0 or attack_cd > 0.0:
		return false
	if float(spell_cds.get(spell, 0.0)) > 0.0:
		return false
	var spec: Dictionary = MAGE_SPELLS[spell]
	if mana < float(spec.get("cost", 0.0)):
		return false
	mana -= float(spec.get("cost", 0.0))
	spell_variant = spell
	spell_cds[spell] = spec["cd"]
	clip_names["Cast"] = clip_names["Mage_" + spell]
	anim_state = ""
	attack_serial += 1
	attack_t = spec["time"]
	attack_duration = spec["time"]
	attack_type = "Cast"
	has_impacted = false
	attack_cd = 0.30
	_play("Cast")
	return true

func spell_reach() -> float:
	return float(MAGE_SPELLS[spell_variant]["reach"]) if spell_variant != "" else 2.2

func _attack(kind: String, duration: float) -> void:
	if attack_t > 0.0 or dodge_t > 0.0 or attack_cd > 0.0:
		return
	if kind == "Cast" and (spell_cd > 0.0 or mana < WARRIOR_CAST_COST):
		return
	if kind == "Cast":
		mana -= WARRIOR_CAST_COST
	if is_pilot_hero() and kind != "Cast" and clip_names.get("Slash", "") == "Pilot_Slash":
		duration = PILOT_SLASH_TIME
	attack_serial += 1
	attack_t = duration
	attack_duration = duration
	attack_type = kind
	has_impacted = false
	attack_cd = 0.30
	if kind == "Cast": spell_cd = 3.5
	_play("Cast" if kind == "Cast" else "Slash")

## Click-to-move steering: walk to the clicked point, or into range of the attack target and then attack.
func _click_steer() -> Vector3:
	if attack_t > 0.0 or dodge_t > 0.0:
		return Vector3.ZERO
	if attack_target != null:
		if not is_instance_valid(attack_target) or float(attack_target.get("inactive_t")) > 0.0:
			attack_target = null
			return Vector3.ZERO
		var d := Vector3(attack_target.global_position.x - global_position.x, 0.0, attack_target.global_position.z - global_position.z)
		if d.length() <= primary_range():
			primary_attack()
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				attack_target = null      # one attack per click; holding LMB keeps attacking
			return Vector3.ZERO
		return d.normalized()
	if move_target.is_finite():
		var d := Vector3(move_target.x - global_position.x, 0.0, move_target.z - global_position.z)
		if d.length() <= ARRIVE_RADIUS:
			move_target = Vector3.INF
			return Vector3.ZERO
		return d.normalized()
	return Vector3.ZERO

func _dodge() -> void:
	if dodge_t > 0.0 or dodge_cd > 0.0 or attack_t > 0.0:
		return
	dodge_t = PILOT_ROLL_TIME if is_pilot_hero() else 0.65
	dodge_cd = 1.1
	invulnerable = 0.50
	_play("Dodge")

func _physics_process(delta: float) -> void:
	if arm_carry != null:   # ease the arm layer in/out over ~0.2 s so clip changes don't pop
		arm_carry.influence = move_toward(arm_carry.influence, arm_carry_target, delta * 5.0)
	attack_cd = maxf(0.0, attack_cd - delta)
	mana = minf(max_mana, mana + MANA_REGEN * delta)
	for k in spell_cds.keys():
		spell_cds[k] = maxf(0.0, spell_cds[k] - delta)
	spell_cd = maxf(0.0, spell_cd - delta)
	dodge_cd = maxf(0.0, dodge_cd - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_A): input.x -= 1.0
	if Input.is_key_pressed(KEY_D): input.x += 1.0
	if Input.is_key_pressed(KEY_W): input.y -= 1.0
	if Input.is_key_pressed(KEY_S): input.y += 1.0
	input = input.normalized()
	if click_to_move:
		input = Vector2.ZERO
	var cam_right := Vector3.RIGHT
	var cam_forward := Vector3.FORWARD
	if camera != null:
		cam_right = camera.global_basis.x
		cam_forward = -camera.global_basis.z
	cam_right.y = 0
	cam_forward.y = 0
	cam_right = cam_right.normalized()
	cam_forward = cam_forward.normalized()
	var moving := (cam_right * input.x + cam_forward * -input.y).normalized()
	var sprint := Input.is_key_pressed(KEY_SHIFT)
	var stroll := is_pilot_hero() and Input.is_key_pressed(KEY_CTRL) and not sprint
	if click_to_move:
		sprint = false   # Shift is "attack in place" in click-to-move games
		stroll = false
		moving = _click_steer()
	if dodge_t > 0.0:
		dodge_t = maxf(0.0, dodge_t - delta)
		if moving.length() > 0.1:
			last_face = moving
		velocity.x = last_face.x * DODGE_SPEED
		velocity.z = last_face.z * DODGE_SPEED
		if dodge_t <= 0.0: anim_state = ""
	elif attack_t > 0.0:
		var elapsed := attack_duration - attack_t
		attack_t = maxf(0.0, attack_t - delta)
		velocity.x = move_toward(velocity.x, 0.0, 28.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 28.0 * delta)
		if attack_type == "Dash":
			velocity.x = last_face.x * 8.0
			velocity.z = last_face.z * 8.0
		# Prefer the real imported animation playhead over a fixed 0.25 s
		# shortcut. The R39/R47 WeaponRoot trajectory places slash contact
		# near 57% of the Slash clip, after the windup.
		var expected_animation := "Cast" if attack_type == "Cast" else "Slash"
		var clip_phase := -1.0
		if animation != null and anim_state == expected_animation and animation.current_animation_length > 0.0:
			clip_phase = animation.current_animation_position / animation.current_animation_length
		# A missing/unloaded animation never makes combat permanently inert.
		# Fallback at 85% of the requested attack duration only.
		var contact_phase := WEAPON_SWEEP.attack_contact_phase(attack_type)
		if attack_type == "Cast" and spell_variant != "":
			contact_phase = float(MAGE_SPELLS[spell_variant]["phase"])
		var contact_due := (clip_phase >= contact_phase if clip_phase >= 0.0 else elapsed >= attack_duration * 0.85)
		if not has_impacted and contact_due:
			has_impacted = true
			impact.emit(global_position + last_face * (spell_reach() if attack_type == "Cast" else 1.4), attack_type, last_face)
		if attack_t <= 0.0: anim_state = ""
	else:
		var move_speed := PILOT_STROLL_SPEED if stroll else (RUN_SPEED if sprint else WALK_SPEED)
		velocity.x = moving.x * move_speed
		velocity.z = moving.z * move_speed
		if moving.length() > 0.1:
			_play("Stroll" if stroll else ("Run" if sprint else "Walk"))
		else:
			_play("Idle")
	if moving.length() > 0.1 and dodge_t <= 0.0 and attack_t <= 0.0:
		last_face = moving
	if last_face.length() > 0.0:
		var desired_yaw := atan2(-last_face.x, -last_face.z) + model_yaw_offset
		body.rotation.y = lerp_angle(body.rotation.y, desired_yaw, minf(1.0, delta * 13.0))
	velocity.y = -GRAVITY if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	if terrain_ik_available and animation != null:
		var cycle_phase := 0.0
		if animation.current_animation_length > 0.0:
			cycle_phase = fposmod(animation.current_animation_position / animation.current_animation_length, 1.0)
		terrain_foot_ik.update_foot_ik(delta, anim_state, cycle_phase)

func receive_damage(damage: float) -> void:
	if invulnerable > 0.0: return
	hp = maxf(0.0, hp - damage)
	health_changed.emit(hp, max_hp)
	if hp <= 0.0:
		hp = max_hp
		global_position = Vector3(0, 0.08, 0)
		health_changed.emit(hp, max_hp)

func command_move(point: Vector3) -> void:
	attack_target = null
	move_target = Vector3(point.x, global_position.y, point.z)

func command_attack(target: Node3D) -> void:
	attack_target = target
	move_target = Vector3.INF

func stop_moving() -> void:
	move_target = Vector3.INF
	attack_target = null

func primary_range() -> float:
	return float(MAGE_SPELLS["Bolt"]["reach"]) * 0.9 if is_pilot_mage() else MELEE_RANGE

## Primary attack (LMB on an enemy / Shift+LMB): Mage Bolt, Warrior Slash.
var primary_skill_provider: Callable   # ARPG HUD: the skill in the LMB well

func primary_attack() -> void:
	_face_aim()
	var sk: String = primary_skill_provider.call() if primary_skill_provider.is_valid() else ""
	if sk != "":
		if MAGE_SPELLS.has(sk) and is_pilot_mage(): cast_spell(sk)
		elif WARRIOR_SKILLS.has(sk): _attack(sk, WARRIOR_SKILLS[sk])
	elif is_pilot_mage():
		cast_spell("Bolt")
	else:
		_attack("Slash", 0.72)

func _face_aim() -> void:
	var at := aim_point
	if attack_target != null and is_instance_valid(attack_target):
		at = attack_target.global_position
	if at.is_finite():
		var d := Vector3(at.x - global_position.x, 0.0, at.z - global_position.z)
		if d.length() > 0.05:
			last_face = d.normalized()
			if body != null:
				body.rotation.y = atan2(-last_face.x, -last_face.z) + model_yaw_offset

## Potions (ARPG HUD belt). Returns true if anything was restored.
func restore(hp_amount: float, mana_amount: float) -> bool:
	var before_hp := hp
	var before_mana := mana
	hp = minf(max_hp, hp + hp_amount)
	mana = minf(max_mana, mana + mana_amount)
	if hp != before_hp:
		health_changed.emit(hp, max_hp)
	return hp != before_hp or mana != before_mana
