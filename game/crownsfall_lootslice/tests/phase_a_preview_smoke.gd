extends SceneTree
## Run with Godot after editor import:
## godot --headless --path . --script res://tests/phase_a_preview_smoke.gd
const Art := preload("res://scripts/art_library.gd")
const IDS := ["weapon", "offhand", "helm", "armor", "gloves", "boots", "belt", "wand", "focus", "robe", "hood", "ring", "amulet", "staff", "slippers", "wraps"]

func _initialize() -> void:
	call_deferred("_validate")

func _validate() -> void:
	var checks := 0
	if Art.phase_a_preview_enabled:
		push_error("Phase A must start disabled")
		quit(1)
		return
	var baseline: Dictionary = {}
	for id in IDS:
		var tex: Texture2D = Art.inventory_portrait(id)
		if tex == null:
			push_error("Missing current inventory art: " + id)
			quit(2)
			return
		baseline[id] = tex.get_size()
		checks += 1
	if not Art.phase_a_preview_missing().is_empty() or not Art.set_phase_a_preview_enabled(true):
		push_error("Phase A art is missing or failed to enable")
		quit(3)
		return
	checks += 1
	for id in IDS:
		var target: String = String(Art.preview_profile().get("portraits", {}).get(id, ""))
		var tex: Texture2D = Art.inventory_portrait(id)
		if tex == null or target.is_empty() or tex.get_size() == Vector2.ZERO:
			push_error("Missing new item texture: " + id)
			quit(4)
			return
		checks += 1
	if not Art.set_phase_a_preview_enabled(false):
		push_error("Cannot revert art profile")
		quit(5)
		return
	checks += 1
	for id in IDS:
		if Art.inventory_portrait(id).get_size() != baseline[id]:
			push_error("Revert mismatch for " + id)
			quit(6)
			return
		checks += 1
	print("PHASE_A_ART_TEST_OK: %d portrait toggling checks" % checks)
	quit(0)