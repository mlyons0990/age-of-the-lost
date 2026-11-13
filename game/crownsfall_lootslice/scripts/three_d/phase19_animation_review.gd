extends Node3D
## Optional Phase 19 rig QA: never replaces the production actor or changes saves.
const MASTER_PATH := "res://models/AOTL_Master_Rig_R38_AllSix.glb"
const REQUIRED := ["Idle", "Walk", "Run", "Slash", "Dodge", "Cast"]
const GOLD := Color("e6c17c")
var model: Node3D
var animator: AnimationPlayer
var armature: Skeleton3D
var status_label: Label
var active_clip := "Idle"
var message := ""

func _ready() -> void:
	_build_stage()
	_build_hud()
	_load_optional_master()

func _build_stage() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("1b2433")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("dae1ff")
	settings.ambient_light_energy = 0.6
	env.environment = settings
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("ffe6c1")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.4
	mesh.bottom_radius = 2.65
	mesh.height = 0.22
	ground.mesh = mesh
	ground.position.y = -0.15
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("485066")
	ground.material_override = material
	add_child(ground)
	var cam := Camera3D.new()
	cam.position = Vector3(5.8, 4.9, 8.6)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 6.9
	cam.current = true
	add_child(cam)
	cam.look_at(Vector3(0, 1.12, 0), Vector3.UP)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var backdrop := PanelContainer.new()
	backdrop.position = Vector2(22, 22)
	backdrop.custom_minimum_size = Vector2(640, 0)
	layer.add_child(backdrop)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.07, 0.94)
	style.border_color = Color("b59b65")
	style.set_border_width_all(2)
	style.set_content_margin_all(14)
	backdrop.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	backdrop.add_child(column)
	var heading := Label.new()
	heading.text = "AOTL · MASTER RIG ANIMATION REVIEW"
	heading.add_theme_font_size_override("font_size", 23)
	heading.add_theme_color_override("font_color", GOLD)
	column.add_child(heading)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)
	var instructions := Label.new()
	instructions.text = "1 Idle   2 Walk   3 Run   4 Slash   5 Dodge   6 Cast     F7 return to IK lab"
	instructions.add_theme_color_override("font_color", GOLD)
	column.add_child(instructions)

func _load_optional_master() -> void:
	if not ResourceLoader.exists(MASTER_PATH):
		message = "Optional model missing. Extract the separate six-animation GLB into models/AOTL_Master_Rig_R38_AllSix.glb, then reopen this scene. The Phase 18 proxy is unchanged."
		_refresh_status()
		return
	var resource := load(MASTER_PATH) as PackedScene
	if resource == null:
		message = "Export is not a readable Godot scene. Keep the verified Phase 18 proxy."
		_refresh_status()
		return
	model = resource.instantiate() as Node3D
	if model == null:
		message = "Cannot instantiate master GLB."
		_refresh_status()
		return
	add_child(model)
	armature = model.find_child("Skeleton3D", true, false) as Skeleton3D
	animator = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animator == null or armature == null or armature.get_bone_count() < 58:
		message = "Rejected master rig: missing animated skeleton or required bone count."
		model.queue_free()
		model = null
		_refresh_status()
		return
	var missing: PackedStringArray = []
	for clip in REQUIRED:
		if _find_animation(clip) == "":
			missing.append(clip)
	if missing.size() > 0:
		message = "Rejected export: missing required animations: " + ", ".join(missing)
		model.queue_free()
		model = null
		_refresh_status()
		return
	message = "Export accepted: %d bones · six animation clips. Visual deformation quality still requires inspection." % armature.get_bone_count()
	play_clip("Idle")

func _find_animation(name: String) -> String:
	if animator == null:
		return ""
	for key in animator.get_animation_list():
		if String(key).get_file() == name:
			return String(key)
	return ""

func play_clip(name: String) -> void:
	if animator == null or model == null:
		return
	var key := _find_animation(name)
	if key == "":
		return
	active_clip = name
	var clip := animator.get_animation(key)
	if name in ["Idle", "Walk", "Run"]:
		clip.loop_mode = Animation.LOOP_LINEAR
	animator.play(key, 0.18)
	_refresh_status()

func _refresh_status() -> void:
	if status_label != null:
		status_label.text = message + ("\nPreview: " + active_clip if model != null else "")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F7 or event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/rig_lab_3d.tscn")
		return
	var n := -1
	match event.keycode:
		KEY_1: n = 0
		KEY_2: n = 1
		KEY_3: n = 2
		KEY_4: n = 3
		KEY_5: n = 4
		KEY_6: n = 5
	if n >= 0:
		play_clip(REQUIRED[n])
