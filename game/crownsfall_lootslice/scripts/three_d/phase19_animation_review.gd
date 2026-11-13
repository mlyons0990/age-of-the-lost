extends Node3D
## Independent animation review. The master GLB is an optional Higgsfield export.
## No save files or production gameplay are touched by this scene.
const MASTER_PATH := "res://models/AOTL_Master_Rig_R38_AllSix.glb"
const REQUIRED := ["Idle", "Walk", "Run", "Slash", "Dodge", "Cast"]
const GOLD := Color("e6c17c")
const METRICS := preload("res://scripts/three_d/phase20_motion_metrics.gd")
var model: Node3D
var animator: AnimationPlayer
var armature: Skeleton3D
var status_label: Label
var active_clip := "Idle"
var message := ""
var motion_report: Dictionary = {}
var audit_label: Label
var speed_label: Label
var slow_motion := false
var show_foot_markers := true
var markers: Array[MeshInstance3D] = []
var marker_labels: Array[Label3D] = []


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
	instructions.text = "1–6: clips   7: foot markers   8: slow motion   9: motion audit   0: reset   F7: IK lab"
	instructions.add_theme_color_override("font_color", GOLD)
	column.add_child(instructions)
	audit_label = Label.new()
	audit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	audit_label.add_theme_font_size_override("font_size", 14)
	column.add_child(audit_label)
	speed_label = Label.new()
	speed_label.add_theme_font_size_override("font_size", 14)
	speed_label.add_theme_color_override("font_color", GOLD)
	column.add_child(speed_label)

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
	_create_foot_markers()
	_refresh_status()

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

func run_motion_audit(clip_name: String = "") -> Dictionary:
	if model == null or animator == null or armature == null:
		return {"ok": false, "error": "optional master GLB not loaded"}
	var selected := clip_name if clip_name != "" else active_clip
	var key := _find_animation(selected)
	motion_report = METRICS.inspect_clip(animator, armature, key, 29)
	_refresh_status()
	return motion_report

func _create_foot_markers() -> void:
	if armature == null:
		return
	for index in range(2):
		var marker := MeshInstance3D.new()
		marker.name = "MotionAudit_%s" % ("Left" if index == 0 else "Right")
		var sphere := SphereMesh.new()
		sphere.radius = 0.045
		sphere.height = 0.09
		marker.mesh = sphere
		var surface := StandardMaterial3D.new()
		surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		surface.albedo_color = Color("50d5ff") if index == 0 else Color("ffb763")
		marker.material_override = surface
		add_child(marker)
		markers.append(marker)
		var label := Label3D.new()
		label.text = "L" if index == 0 else "R"
		label.font_size = 80
		label.pixel_size = 0.003
		label.position.y = 0.12
		marker.add_child(label)
		marker_labels.append(label)

func _process(delta: float) -> void:
	if model == null or markers.size() != 2:
		return
	for index in range(2):
		var bone := armature.find_bone("FootL" if index == 0 else "FootR")
		if bone >= 0:
			markers[index].global_position = METRICS.foot_world_position(armature, bone)
		markers[index].visible = show_foot_markers

func _refresh_status() -> void:
	if status_label != null:
		status_label.text = message + ("\nPreview: " + active_clip if model != null else "")
	if speed_label != null:
		speed_label.text = "Playback: 0.35× (slow inspection)" if slow_motion else "Playback: 1.00×"
	if audit_label != null:
		if motion_report.get("ok", false):
			var left: Dictionary = motion_report["left"]
			var right: Dictionary = motion_report["right"]
			audit_label.text = "Audited %s (%d samples): vertical range L %.3fm / R %.3fm; low-foot travel L %.3fm / R %.3fm.\nThese are trajectory indicators, NOT a verdict on visual sliding." % [motion_report["clip"], motion_report["samples"], left["vertical_range_m"], right["vertical_range_m"], left["low_foot_path_m"], right["low_foot_path_m"]]
		else:
			audit_label.text = "Press 9 to sample each foot's trajectory without altering the game."

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
		return
	match event.keycode:
		KEY_7:
			show_foot_markers = not show_foot_markers
		KEY_8:
			slow_motion = not slow_motion
			if animator != null:
				animator.speed_scale = 0.35 if slow_motion else 1.0
			_refresh_status()
		KEY_9:
			run_motion_audit()
		KEY_0:
			if animator != null:
				animator.speed_scale = 1.0
			slow_motion = false
			motion_report = {}
			play_clip("Idle")