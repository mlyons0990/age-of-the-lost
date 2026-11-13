extends Node3D
const HURTBOX := preload("res://scripts/three_d/hurtbox3d.gd")
const HURT_RADIUS_M := 0.45
## Resettable sword target for testing attack timing and 3D FX.
var hp := 100.0
var max_hp := 100.0
var time := 0.0
var inactive_t := 0.0
var mesh: MeshInstance3D
var title: Label3D
var hurtbox: Area3D

func _ready() -> void:
	hurtbox = HURTBOX.new()
	add_child(hurtbox)
	var body := CylinderMesh.new()
	body.top_radius = 0.33
	body.bottom_radius = 0.47
	body.height = 1.35
	mesh = MeshInstance3D.new()
	mesh.mesh = body
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("454662")
	mat.metallic = 0.45
	mat.roughness = 0.42
	mesh.material_override = mat
	mesh.position.y = 1.1
	add_child(mesh)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.32
	hm.height = 0.60
	head.mesh = hm
	head.material_override = mat
	head.position.y = 1.9
	add_child(head)
	var ring := MeshInstance3D.new()
	var m := TorusMesh.new()
	m.inner_radius = 0.41
	m.outer_radius = 0.48
	ring.mesh = m
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("dab66d")
	gold.metallic = 0.55
	ring.material_override = gold
	ring.position.y = 0.5
	add_child(ring)
	title = Label3D.new()
	title.text = "TRAINING CONSTRUCT · 100"
	title.position = Vector3(0, 2.55, 0)
	title.font_size = 36
	title.pixel_size = 0.0045
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(title)

func damage_center() -> Vector3:
	return hurtbox.global_position if is_instance_valid(hurtbox) else global_position + Vector3.UP * 1.2

func damage_radius() -> float:
	return HURT_RADIUS_M

func _process(delta: float) -> void:
	time += delta
	if inactive_t > 0.0:
		inactive_t -= delta
		visible = false
		if inactive_t <= 0.0:
			visible = true
			hp = max_hp
		return
	mesh.rotation.z = sin(time * 1.3) * 0.015

func hit(amount: float) -> bool:
	if inactive_t > 0.0: return false
	hp = maxf(0.0, hp - amount)
	title.text = "TRAINING CONSTRUCT · %d" % int(hp)
	if hp <= 0.0:
		inactive_t = 3.5
		return true
	return false
