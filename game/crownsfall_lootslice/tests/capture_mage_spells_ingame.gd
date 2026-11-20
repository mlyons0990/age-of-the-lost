extends SceneTree
## Live rig lab (Mage + radiant FX): casts each spell and captures the 1080p gameplay view just after release.
const LAB := preload("res://scripts/three_d/rig_lab.gd")
var out := "/tmp"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var lab = LAB.new(); lab.use_pilot_mage_candidate = true; lab.radiant_spell_fx = true
	root.add_child(lab)
	for i in 10: await physics_frame
	var a = lab.player
	for t in lab.targets: t.hp = 1000000.0
	lab.targets[0].global_position = a.global_position + a.last_face * 3.0
	# warm the shaders once
	a.cast_spell("Bolt")
	while a.attack_t > 0.0 or a.attack_cd > 0.0: await physics_frame
	await root.get_tree().create_timer(1.5).timeout
	for spell in ["Bolt", "Lance", "Nova", "Judgment"]:
		a.spell_cds.clear()
		while a.attack_t > 0.0 or a.attack_cd > 0.0: await physics_frame
		a.cast_spell(spell)
		while not a.has_impacted and a.attack_t > 0.0: await physics_frame
		await root.get_tree().create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/spell_%s.png" % [out, spell])
		print("captured ", spell)
		await root.get_tree().create_timer(1.6).timeout
	quit(0)
