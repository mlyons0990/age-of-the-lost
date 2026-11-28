extends Node3D
## Non-destructive telemetry for the actual GLB skeleton. Does not set bone poses.
const METRICS := preload("res://scripts/three_d/phase27_knee_metrics.gd")
const LEGS := [
    {"hip":"HipL", "knee":"KneeL", "ankle":"AnkleL", "foot":"FootL", "label":"L"},
    {"hip":"HipR", "knee":"KneeR", "ankle":"AnkleR", "foot":"FootR", "label":"R"},
]
var actor: CharacterBody3D
var skeleton: Skeleton3D
var chain: Array[Dictionary] = []
var report: Array[Dictionary] = []
var frames := 0
var invalid_frames := 0
var contact_drift_frames := 0
var near_extension_frames := 0
var ambiguous_pole_frames := 0
var ready_to_sample := false
var note := "unbound"

func configure(character: CharacterBody3D) -> bool:
    actor = character
    if actor == null:
        note = "missing-actor"
        return false
    var model := actor.get("body") as Node3D
    if model == null:
        note = "missing-model"
        return false
    skeleton = model.find_child("Skeleton3D", true, false) as Skeleton3D
    if skeleton == null:
        note = "missing-skeleton"
        return false
    for spec in LEGS:
        var ids := {}
        for key in ["hip", "knee", "ankle", "foot"]:
            var idx := skeleton.find_bone(String(spec[key]))
            if idx < 0:
                note = "missing-%s" % String(spec[key])
                return false
            ids[key] = idx
        if not _is_ancestor(ids["hip"], ids["knee"]) or not _is_ancestor(ids["knee"], ids["ankle"]) or not _is_ancestor(ids["ankle"], ids["foot"]):
            note = "disconnected-%s" % String(spec["label"])
            return false
        ids["label"] = spec["label"]
        chain.append(ids)
    ready_to_sample = true
    note = "monitoring"
    return true

func _is_ancestor(parent_id: int, child_id: int) -> bool:
    var cursor := child_id
    while cursor >= 0:
        if cursor == parent_id:
            return true
        cursor = skeleton.get_bone_parent(cursor)
    return false

func _bone_world(id: int) -> Vector3:
    return skeleton.global_transform * skeleton.get_bone_global_pose(id).origin

func _process(_dt: float) -> void:
    if not ready_to_sample or not is_instance_valid(actor) or not is_instance_valid(skeleton):
        return
    var ik := actor.get("foot_ik") as Node3D
    var enabled := ik != null and bool(actor.get("ik_available")) and bool(ik.get("active"))
    var plant_states: Array = ik.get("locked") as Array if enabled else []
    var anchors: Array = ik.get("stance_positions") as Array if enabled else []
    report.clear()
    var model := actor.get("body") as Node3D
    var facing := -model.global_basis.z if model != null else Vector3.FORWARD
    for i in range(chain.size()):
        var leg: Dictionary = chain[i]
        var planted := enabled and plant_states.size() > i and bool(plant_states[i])
        var foot := _bone_world(int(leg["foot"]))
        var anchor := anchors[i] as Vector3 if planted and anchors.size() > i else foot
        var measured := METRICS.evaluate(_bone_world(int(leg["hip"])),
            _bone_world(int(leg["knee"])), _bone_world(int(leg["ankle"])),
            foot, anchor, planted, facing)
        measured["leg"] = leg["label"]
        measured["planted"] = planted
        report.append(measured)
        if not bool(measured["valid"]): invalid_frames += 1
        if bool(measured["foot_drift"]): contact_drift_frames += 1
        if bool(measured["near_full_extension"]): near_extension_frames += 1
        if bool(measured["ambiguous_pole"]): ambiguous_pole_frames += 1
    frames += 1

func summary() -> String:
    if not ready_to_sample:
        return "Phase27 rig audit: %s" % note
    var result := "P27 READ-ONLY KNEE QA  frames %d  drift %d  extension %d  pole %d" % [
        frames, contact_drift_frames, near_extension_frames, ambiguous_pole_frames]
    for item in report:
        result += "\n%s knee %.1f°  pole %.3fm  foot error %.3fm  plant %s" % [
            item["leg"], item["angle_deg"], item["pole_offset_m"],
            item["foot_error_m"], str(item["planted"])]
    return result
