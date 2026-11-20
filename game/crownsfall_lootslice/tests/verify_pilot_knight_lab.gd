extends SceneTree
## The Higgsfield pilot knight driven by the real rig-lab controller: loads, idles, walks, slashes the
## training dummy, rolls (in place, controller-driven travel, i-frames) and still fights by default rules.
const LAB := preload("res://scripts/three_d/rig_lab.gd")
const WEAPON_SWEEP := preload("res://scripts/three_d/weapon_sweep3d.gd")
var checks := 0
var failures := 0

func verify(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + why)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab = LAB.new()
	lab.use_pilot_knight_candidate = true
	root.add_child(lab)
	await physics_frame
	await physics_frame
	var actor = lab.player
	verify(actor.active_model_source == "pilot_knight_opt_in", "Rig lab selected the pilot knight (%s)" % actor.active_model_source)
	verify(actor.clip_names.get("Dodge", "") == actor.clip_names.get("Roll_Dodge", "x"), "Dodge plays the library roll")
	verify(actor.clip_names.get("Slash", "") == "Pilot_Slash", "Slash plays the library right-hand Left_Slash (trimmed)")
	verify(actor.anim_state == "Idle", "Knight starts idle")
	var sk: Skeleton3D = actor.body.find_children("*", "Skeleton3D", true, false)[0]
	var hd := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head")).origin
	var hf := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("headfront")).origin
	verify((hf - hd).normalized().dot(actor.last_face) > 0.9, "Knight faces the controller's facing direction")
	verify(actor.terrain_ik_available, "Terrain foot IK runs on the knight's legs")
	verify(actor.equipment_sockets_available, "Weapon/offhand sockets resolve on the knight's hands")
	verify(not actor.blade_segment().is_empty(), "Blade segment comes from the real sword mesh")
	var seg: Dictionary = actor.blade_segment()
	if not seg.is_empty():
		var blen: float = (seg["hilt"] as Vector3).distance_to(seg["tip"])
		print("PILOT LAB blade length %.2f m" % blen)
		verify(blen > 0.4 and blen < 1.0, "Blade segment has a sword's length (%.2f m)" % blen)
	# camera: ~100 px knight at 1080p
	for i in 30:
		await process_frame
	var cam: Camera3D = lab.camera
	var top := cam.unproject_position(actor.global_position + Vector3.UP * 1.75).y
	var bottom := cam.unproject_position(actor.global_position).y
	print("PILOT LAB camera: knight %.0f px tall at 1080p (fov %.0f, perspective %s)" % [bottom - top, cam.fov, str(cam.projection == Camera3D.PROJECTION_PERSPECTIVE)])
	verify(cam.projection == Camera3D.PROJECTION_PERSPECTIVE and absf((bottom - top) - 100.0) < 12.0, "Gameplay camera shows the knight ~100 px tall (%.0f px)" % (bottom - top))
	var hips := sk.find_bone("Hips")
	# locomotion: planted feet should move at the controller's ground speed (no skating)
	verify(actor.clip_names.get("Run", "") == actor.clip_names.get("RunFast", "x"), "Sprint plays the library RunFast")
	verify(actor.clip_names.get("Stroll", "") == actor.clip_names.get("Casual_Walk", "x"), "Ctrl-stroll plays the library Casual_Walk")
	for clip in ["Walk", "Run", "Stroll"]:
		actor.anim_state = ""
		actor._play(clip)
		var speed: float = actor.animation.get_playing_speed()
		var ground: float = float(actor.PILOT_STRIDE_SPEED[clip]) * speed
		var target: float = {"Walk": actor.WALK_SPEED, "Run": actor.RUN_SPEED, "Stroll": actor.PILOT_STROLL_SPEED}[clip]
		var steps: float = speed * {"Walk": 2.0 / 0.63, "Run": 2.0 / 0.5, "Stroll": 9.0 / 4.17}[clip]
		print("PILOT LAB %s cadence %.1f steps/s" % [clip, steps])
		verify(steps > 1.5 and steps < 4.0, "%s cadence looks natural (%.1f steps/s)" % [clip, steps])
		print("PILOT LAB %s: playback x%.2f -> planted foot %.2f m/s vs controller %.2f m/s" % [clip, speed, ground, target])
		verify(absf(ground - target) / target < 0.1, "%s feet don't skate (foot %.2f vs body %.2f m/s)" % [clip, ground, target])
	actor.anim_state = ""
	actor._play("Idle")
	# slash the front dummy
	var dummy = lab.targets[0]
	dummy.global_position = actor.global_position + Vector3(0, 0, -1.3)
	dummy.hp = 100.0
	await physics_frame
	actor._attack("Slash", 0.72)
	verify(actor.anim_state == "Slash", "Slash animation plays on attack")
	await root.get_tree().create_timer(0.8).timeout
	verify(dummy.hp < 100.0, "Slash damages the training dummy (hp %.0f)" % dummy.hp)
	await root.get_tree().create_timer(0.3).timeout
	# roll: in place animation, controller travel, invulnerability
	var start: Vector3 = actor.global_position
	var low := 9.0
	var drift := 0.0
	actor._dodge()
	verify(actor.anim_state == "Dodge" and actor.invulnerable > 0.0, "Space-roll starts with i-frames")
	for i in 40:
		await physics_frame
		var hp: Vector3 = sk.global_transform * sk.get_bone_global_pose(hips).origin
		low = minf(low, hp.y - actor.global_position.y)
		drift = maxf(drift, Vector2(hp.x - actor.global_position.x, hp.z - actor.global_position.z).length())
	var moved: float = actor.global_position.distance_to(start)
	print("PILOT LAB roll: controller travel %.2f m, lowest hips %.2f m above feet, hips off the body %.2f m" % [moved, low, drift])
	verify(low < 0.6, "Knight tucks into the roll (hips %.2f m)" % low)
	verify(absf(moved - 10.5 * 0.65) < 0.5, "Roll travel is the controller's standard dodge (%.2f m)" % moved)
	verify(drift < 0.45, "Roll animation adds no root-motion drift (hips stay over the body, %.2f m)" % drift)
	await root.get_tree().create_timer(0.4).timeout
	verify(actor.dodge_t <= 0.0, "Roll finishes and control returns")
	# strict swept-blade mode with the knight's real sword
	lab.strict_weapon_sweep = true
	dummy.global_position = actor.global_position + actor.last_face * 0.65   # same placement as the R52 strict test
	dummy.hp = 100.0
	lab.sweep_hit_instances.clear()
	await physics_frame
	actor._attack("Slash", 0.72)
	var most := 0
	var nearest := 99.0
	for i in 55:
		await physics_frame
		most = maxi(most, lab.contact_samples.size())
		var sg: Dictionary = actor.blade_segment()
		if not sg.is_empty():
			nearest = minf(nearest, sqrt(WEAPON_SWEEP.point_segment_distance_squared(dummy.damage_center(), sg["hilt"], sg["tip"])))
	print("PILOT LAB strict sweep: dummy hp %.0f, max samples %d, nearest blade-to-dummy %.2f m (dummy radius %.2f), face %s" % [dummy.hp, most, nearest, dummy.damage_radius(), str(actor.last_face)])
	verify(most >= 10, "Strict swept-blade mode samples the knight's real sword through the swing (%d samples)" % most)
	verify(nearest < dummy.damage_radius(), "Real sword passes through a dummy 0.65 m ahead (nearest %.2f m)" % nearest)
	verify(dummy.hp < 100.0, "Strict swept-blade mode hits with the real sword (hp %.0f)" % dummy.hp)
	await root.get_tree().create_timer(0.3).timeout
	var hp_after: float = dummy.hp
	actor._attack("Slash", 0.72)
	await root.get_tree().create_timer(1.0).timeout
	verify(dummy.hp < hp_after, "A second strict swing hits again (one hit per swing, %.0f -> %.0f)" % [hp_after, dummy.hp])
	lab.strict_weapon_sweep = false
	print("AOTL PILOT KNIGHT LAB RESULT %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
