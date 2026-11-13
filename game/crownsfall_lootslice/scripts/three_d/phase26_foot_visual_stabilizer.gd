extends Node3D
## Lab-only visual stabilizer: adjusts a separate model pivot, never the CharacterBody3D.
## Phase25 descent also writes model.position.y. Own only our separate child pivot
## to avoid racing with Phase25 visual recovery.
const POLICY := preload("res://scripts/three_d/phase26_pelvis_policy.gd")
const TARGET_MARKER_NAME := "Phase26_PelvisVisualPivot"
var actor: CharacterBody3D
var pivot: Node3D
var avatar: Node3D
var current_offset_m := 0.0
var target_offset_m := 0.0
var valid_foot_samples := 0
var suspended_reason := "unbound"

func configure(character: CharacterBody3D) -> void:
    actor = character
    if actor == null:
        return
    avatar = actor.get("body") as Node3D
    if avatar == null or avatar.get_parent() == null:
        suspended_reason = "missing-avatar"
        return
    # Model pivot is a reversible parent wrapping the original GLB; no skeleton edits.
    pivot = Node3D.new()
    pivot.name = TARGET_MARKER_NAME
    var parent := avatar.get_parent()
    parent.add_child(pivot)
    pivot.transform = avatar.transform
    avatar.reparent(pivot, true)
    pivot.transform = Transform3D.IDENTITY
    suspended_reason = "ready"

func _process(dt: float) -> void:
    if pivot == null or actor == null or not is_instance_valid(actor):
        return
    var ik: Node3D = actor.get("foot_ik") as Node3D
    var enabled := ik != null and bool(actor.get("ik_available")) and bool(ik.get("active"))
    var combat := float(actor.get("attack_t")) > 0.0
    var dodge := float(actor.get("dodge_t")) > 0.0
    var grounded := actor.is_on_floor()
    var errors: Array = []
    if enabled and grounded and not combat and not dodge and is_instance_valid(ik.skeleton):
        for i in range(2):
            if not bool(ik.locked[i]):
                continue
            var skeleton: Skeleton3D = ik.skeleton
            var foot_id: int = ik.foot_bones[i]
            var world_foot: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(foot_id).origin
            var world_target: Vector3 = ik.stance_positions[i]
            # Error is target minus current ankle. Positive gap raises visual pelvis slightly.
            var gap := world_target.y - world_foot.y
            errors.append(gap)
    valid_foot_samples = errors.size()
    target_offset_m = POLICY.target_offset(errors, enabled, grounded, combat, dodge)
    current_offset_m = POLICY.update_offset(current_offset_m, target_offset_m, dt)
    pivot.position.y = current_offset_m
    suspended_reason = "off" if not enabled else ("airborne" if not grounded else ("combat" if combat or dodge else ("sampling" if valid_foot_samples > 0 else "no-planted-feet")))

func _exit_tree() -> void:
    # Return the original avatar to its parent if the lab component is removed.
    if is_instance_valid(pivot) and is_instance_valid(avatar) and is_instance_valid(actor):
        avatar.reparent(actor, true)
        pivot.queue_free()
