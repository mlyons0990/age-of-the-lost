extends SceneTree
## 1080p captures of the pilot labs with the ARPG HUD (owner mockup layout): Mage mid-Judgment, knight idle.
var out := "/tmp"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	call_deferred("_run")
func _shot(scene: String, name: String, spell: String) -> void:
	var lab: Node3D = (load(scene) as PackedScene).instantiate()
	root.add_child(lab)
	for i in 12: await physics_frame
	var a = lab.player
	lab.kills = 1
	a.hp = a.max_hp * 0.82
	a.health_changed.emit(a.hp, a.max_hp)
	if spell != "":
		a.cast_spell("Bolt")
		while a.attack_t > 0.0 or a.attack_cd > 0.0: await physics_frame
		await create_timer(1.2).timeout
		a.cast_spell(spell)
		while not a.has_impacted and a.attack_t > 0.0: await physics_frame
		await create_timer(0.12).timeout
	else:
		a._attack("Cast", 1.4)
		await create_timer(1.6).timeout
	lab.hud.drink(0)
	a.hp = a.max_hp * 0.6
	a.health_changed.emit(a.hp, a.max_hp)
	var sk: Skeleton3D = a.body.find_children("*", "Skeleton3D", true, false)[0]
	var head_y: float = (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("head_end"))).origin.y
	var top: float = lab.camera.unproject_position(a.global_position + Vector3.UP * head_y).y
	var bot: float = lab.camera.unproject_position(a.global_position).y
	print("HERO on-screen height %.0f px (head_end %.2f m) at %s" % [bot - top, head_y, root.size])
	await process_frame; await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/hud_%s.png" % [out, name])
	if name == "mage":
		lab.hud.toggle_bind_menu()
		await process_frame; await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/hud_bind_menu.png" % out)
		lab.hud.toggle_bind_menu()
	print("captured ", name, " mana ", a.mana)
	lab.queue_free()
	await process_frame
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	await _shot("res://scenes/pilot_mage_combat_lab.tscn", "mage", "Judgment")
	await _shot("res://scenes/pilot_knight_combat_lab.tscn", "knight", "")
	quit(0)
