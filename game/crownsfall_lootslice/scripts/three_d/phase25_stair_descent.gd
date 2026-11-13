extends Node3D
## Isolated downhill contact assist. No unchecked Y teleport.
const POLICY := preload("res://scripts/three_d/phase25_descent_policy.gd")
const RAY_FROM_M := 0.28
const RAY_DOWN_M := 0.44
const FLOOR_OFFSET_M := 0.025
const CONTACT_MARGIN_M := 0.025
const COOLDOWN_S := 0.10
var actor: CharacterBody3D
var cooldown_s := 0.0
var recently_floor_s := 0.0
var accepted_steps := 0
var blocked_steps := 0
var ignored_untagged := 0
var last_drop_m := 0.0
var visual_recoveries := 0
const VISUAL_BLEND_SPEED := 10.0

func _process(dt: float) -> void:
    if actor == null or dt <= 0.0:
        return
    var model := actor.get("body") as Node3D
    if model != null:
        model.position = model.position.lerp(Vector3.ZERO, minf(1.0, dt * VISUAL_BLEND_SPEED))

func configure(character: CharacterBody3D) -> void:
    actor = character
    process_physics_priority = 11

func _physics_process(dt: float) -> void:
    if actor == null or dt <= 0.0:
        return
    cooldown_s = maxf(0.0, cooldown_s - dt)
    recently_floor_s = POLICY.GRACE_S if actor.is_on_floor() else maxf(0.0, recently_floor_s - dt)
    if cooldown_s > 0.0 or recently_floor_s <= 0.0:
        return
    if actor.get("attack_t") > 0.0 or actor.get("dodge_t") > 0.0:
        return
    var planar := Vector3(actor.velocity.x, 0.0, actor.velocity.z)
    var speed := planar.length()
    if speed < 0.3 or speed > POLICY.MAX_SPEED_MPS:
        return
    var space := get_world_3d().direct_space_state
    var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * RAY_FROM_M,
        actor.global_position - Vector3.UP * RAY_DOWN_M)
    ray.exclude = [actor.get_rid()]
    var hit := space.intersect_ray(ray)
    if hit.is_empty():
        return
    var surface: Object = hit.get("collider")
    var tagged := surface is StaticBody3D and surface.is_in_group("phase24_steps")
    if not tagged:
        ignored_untagged += 1
        return
    var drop_m := actor.global_position.y + FLOOR_OFFSET_M - float(hit["position"].y)
    if not POLICY.accepted(drop_m, hit["normal"], speed, recently_floor_s > 0.0,
            tagged, true, false, false):
        return
    var start_y := actor.global_position.y
    var collision := actor.move_and_collide(Vector3.DOWN * (drop_m + CONTACT_MARGIN_M))
    var displacement := start_y - actor.global_position.y
    if collision == null or displacement < POLICY.MIN_DROP_M:
        blocked_steps += 1
        return
    # Count only collisions against a tagged step, not unrelated floor objects.
    var contacted: Object = collision.get_collider()
    if not (contacted is StaticBody3D and contacted.is_in_group("phase24_steps")):
        ignored_untagged += 1
        return
    var model := actor.get("body") as Node3D
    if model != null:
        model.position.y += minf(displacement, POLICY.MAX_DROP_M)
        visual_recoveries += 1
    last_drop_m = displacement
    accepted_steps += 1
    cooldown_s = COOLDOWN_S
    var ik := actor.get("foot_ik") as Node3D
    if ik != null and bool(actor.get("ik_available")):
        ik.set_active(ik.active)
