extends SceneTree
const Rules := preload("res://scripts/encounter_rules.gd")
func _initialize() -> void:
	var checkpoints: Array = []
	for level in [1,10,20,40,60]: checkpoints.append(Rules.tuning(level))
	var patterns: Array = []
	for kind in Rules.ORDER:
		var w := Rules.warning(kind,Vector2.ZERO,Vector2(100,0),false)
		patterns.append({"kind":kind,"name":Rules.NAMES[kind],"hint":Rules.HINTS[kind],"warning_verse1":w.duration,"warning_verse2":Rules.warning(kind,Vector2.ZERO,Vector2(100,0),true).duration,"length":w.length,"half_width":w.half_width,"circle_radius":w.radius,"ring_inner":w.inner,"ring_outer":w.outer})
	var f := FileAccess.open("res://data/encounter_rules.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checkpoints":checkpoints,"patterns":patterns,"actor_radius":0.28,"seals_ground_offsets_x":[0,-1.9,1.9],"arena_radius":7.0,"initial_delay":2.0,"spacing_verse1":3.7,"spacing_verse2":3.0,"long_frame_cutoff":0.5,"phase2_health_fraction":0.5,"fragments_per_verse":2,"xp_fraction":0.2,"gear_drops_per_victory":1},"  "));f.close()
	quit()
