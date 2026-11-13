extends RefCounted
## Collision-aware Warrior attack selection for Crownsfall's playable 3D rig lab.
##
## Pure geometric tests are deterministic; the optional physics test rejects
## targets behind solid world geometry. No change to the 2D battle/saves.
##
## A target's collision is currently visual-only (training dummy Node3D), so a
## successful world raycast hit is an intervening obstruction, not target contact.

const COLLISION_MASK_WORLD := 1
const HIT_HEIGHT_M := 1.20
const MIN_DIRECTION_SQUARED := 0.0001

static func profile_for(kind: String) -> Dictionary:
	match kind:
		"Cast":
			return {"range": 3.30, "min_dot": -1.0, "damage": 53.0}
		"Cleave":
			return {"range": 3.30, "min_dot": -0.25, "damage": 43.0}
		"Dash":
			return {"range": 2.15, "min_dot": 0.25, "damage": 32.0}
		_:
			return {"range": 2.15, "min_dot": 0.20, "damage": 32.0}

static func within_attack_arc(origin: Vector3, forward: Vector3, target: Vector3, max_distance: float, minimum_dot: float) -> bool:
	if not origin.is_finite() or not forward.is_finite() or not target.is_finite():
		return false
	if max_distance <= 0.0:
		return false
	# Melee/area attack reach is horizontal. Height filtering occurs in the
	# obstacle ray and is controlled by the deliberately defined impact point.
	var offset := Vector2(target.x - origin.x, target.z - origin.z)
	var distance_squared := offset.length_squared()
	if distance_squared > max_distance * max_distance:
		return false
	if distance_squared <= MIN_DIRECTION_SQUARED:
		return true
	if minimum_dot <= -1.0:
		return true
	var direction := Vector2(forward.x, forward.z)
	if direction.length_squared() <= MIN_DIRECTION_SQUARED:
		return false
	return direction.normalized().dot(offset.normalized()) >= clampf(minimum_dot, -1.0, 1.0)

static func world_line_of_sight(world: World3D, origin: Vector3, target: Vector3, excluded_actor: RID, collision_mask: int = COLLISION_MASK_WORLD) -> bool:
	if world == null or not origin.is_finite() or not target.is_finite():
		return false
	var from := origin + Vector3.UP * HIT_HEIGHT_M
	var to := target + Vector3.UP * HIT_HEIGHT_M
	if from.distance_squared_to(to) <= MIN_DIRECTION_SQUARED:
		return true
	var query := PhysicsRayQueryParameters3D.create(from, to, collision_mask)
	if excluded_actor.is_valid():
		query.exclude = [excluded_actor]
	return world.direct_space_state.intersect_ray(query).is_empty()

static func can_hit(world: World3D, actor: CollisionObject3D, origin: Vector3, forward: Vector3, target: Vector3, kind: String) -> bool:
	var settings := profile_for(kind)
	if not within_attack_arc(origin, forward, target, float(settings["range"]), float(settings["min_dot"])):
		return false
	if actor == null:
		return false
	return world_line_of_sight(world, origin, target, actor.get_rid())

static func damage_for(kind: String) -> float:
	return float(profile_for(kind)["damage"])
