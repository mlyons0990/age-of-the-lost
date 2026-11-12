extends SceneTree
## Optional graphical QA. Run with Xvfb/llvmpipe in Godot 4.6.3, not --headless.
## Captures original painted vs new Higgsfield rig at identical 21m PoE camera.
const OUT := "/tmp/aotl_v03_frames"
var frames_written := 0
func _initialize() -> void:
	_capture.call_deferred()
func wait_frames(count: int) -> void:
	for i in count:
		await process_frame
func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var texture := root.get_viewport().get_texture()
	var img := texture.get_image()
	if img == null or img.get_width() < 640 or img.get_height() < 360:
		push_error("Invalid capture framebuffer: " + name)
		return
	if img.save_png(OUT + "/" + name + ".png") != OK:
		push_error("Unable to save framebuffer image " + name)
		return
	frames_written += 1
	print("V03_CAPTURE " + name + " " + str(img.get_size()))
func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	if not OS.get_cmdline_user_args().has("--aotl-v03"):
		push_error("Specify --aotl-v03 to enable new character")
		quit(1)
		return
	var scene := load("res://scenes/two_point_five_d/aotl_25d_lab.tscn") as PackedScene
	if scene == null:
		push_error("Cannot load wide-camera courtyard")
		quit(1)
		return
	var lab = scene.instantiate()
	root.add_child(lab)
	await wait_frames(35)
	lab._set_camera_zoom(21.0)
	await wait_frames(5)
	await snap("01_painted_Warrior_21m")
	var actor = lab.player
	actor.change_visual_mode()
	if actor.visual_mode != "humanoid":
		push_error("Higgsfield driver failed; refusing misleading art capture")
		quit(1)
		return
	actor.set_physics_process(false)
	var rig = actor.humanoid_visual
	rig.sync_actor("idle", Vector3(0,0,-1), 0.2)
	await wait_frames(15)
	await snap("02_humanoid_idle_21m")
	for i in range(9):
		rig.sync_actor("walk", Vector3(-0.55,0,-0.84).normalized(), 0.12)
		await wait_frames(7)
		await snap("walk_%02d" % i)
	rig.sync_actor("slash", Vector3(0,0,-1), 0.10)
	await wait_frames(12)
	await snap("03_humanoid_slash_21m")
	lab._set_camera_zoom(14.0)
	await wait_frames(15)
	rig.sync_actor("idle", Vector3(0,0,-1), 0.2)
	await wait_frames(9)
	await snap("04_humanoid_idle_14m")
	actor.change_visual_mode()
	await wait_frames(12)
	await snap("05_legacy_proxy_14m")
	print("AOTL_V03_CAPTURE_OK: %d screenshots at 1440x810 (including nine motion frames)" % frames_written)
	lab.queue_free()
	await wait_frames(3)
	quit(0 if frames_written == 14 else 1)
