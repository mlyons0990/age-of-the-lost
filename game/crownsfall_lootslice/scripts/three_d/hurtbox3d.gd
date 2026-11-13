extends Area3D
## Reusable collision-backed body hurtbox, intentionally not a cover obstacle.
## Collision layer 4 is damageable space; world cover remains physics layer 1.
## The owning actor decides damage, invulnerability and faction rules.

const DAMAGEABLE_LAYER := 4
@export var local_center_height_m := 1.20
@export var collision_radius_m := 0.45
var volume: CollisionShape3D

func _ready() -> void:
	name = "DamageableHurtbox3D"
	collision_layer = DAMAGEABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	position.y = local_center_height_m
	volume = CollisionShape3D.new()
	volume.name = "DamageVolume"
	var sphere := SphereShape3D.new()
	sphere.radius = collision_radius_m
	volume.shape = sphere
	add_child(volume)

func hit_center() -> Vector3:
	return global_position

func hit_radius() -> float:
	return collision_radius_m
