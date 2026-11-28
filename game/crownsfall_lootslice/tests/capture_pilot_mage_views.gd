extends SceneTree
## Real renders of the armed Mage (idle, jog, sprint, cast) with the controller's arm-carry layer (same modifier code,
## carry pose and weights as rig_controller.gd), in place, from the side. --out=<dir>
const ARM_CARRY := preload("res://scripts/three_d/arm_carry_modifier.gd")
const CTRL := preload("res://scripts/three_d/rig_controller.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var out := "/tmp"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	root.size = Vector2i(560, 640)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.78, 0.78, 0.78)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.78)
	var we := WorldEnvironment.new(); we.environment = e; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 30, 0); root.add_child(sun)
	var fl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(6, 6); fl.mesh = pm; root.add_child(fl)
	var m: Node3D = (load("res://models/higgsfield_mage/mage_pilot_armed.glb") as PackedScene).instantiate()
	root.add_child(m)
	var sk: Skeleton3D = m.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	ap.play("Idle", 0); ap.seek(0.0, true)
	var rots := []
	for n in CTRL.PILOT_ARM_BONES:
		rots.append(sk.get_bone_pose_rotation(sk.find_bone(n)))
	var carry = ARM_CARRY.new(); sk.add_child(carry); carry.setup(sk, CTRL.PILOT_ARM_BONES, rots)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 36
	cam.look_at_from_position(Vector3(3.2, 1.6, 1.8), Vector3(0, 0.9, 0))
	for c in [["Idle", "Idle"], ["Walk", "Run"], ["Run", "RunFast"], ["Cast", "Cast"]]:
		carry.influence = float(CTRL.PILOT_CARRY_WEIGHT.get(c[0], 0.0))
		var L: float = ap.get_animation(c[1]).length
		var span: float = L / 4.0 if c[1] == "Casual_Walk" else L
		for k in 8:
			ap.play(c[1], 0); ap.seek(span * k / 8.0, true); ap.pause()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s_%d.png" % [out, c[0], k])
	quit(0)
