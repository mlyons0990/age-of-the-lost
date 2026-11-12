extends SceneTree
const Systems := preload("res://scripts/systems.gd")
const GD := preload("res://scripts/game_data.gd")
const Resolver := preload("res://scripts/effect_resolver.gd")
func _initialize() -> void:
	var file := FileAccess.open("res://data/implemented_spells.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"revision": "Mage Slice", "status": "implemented", "source": "scripts/game_data.gd", "abilities": GD.spells()}, "  ")); file.close()
	file = FileAccess.open("res://data/class_balance_snapshot.csv", FileAccess.WRITE)
	file.store_csv_line(["class", "level", "loadout", "life", "mana", "weapon_power", "spell_power", "armor", "crit_percent", "mana_regen", "representative_hit", "representative_ability", "revenant_hp", "raw_hits_to_kill"])
	for class_id in ["warrior", "mage"]:
		for level in [1, 10, 20, 40, 60]:
			for loadout in ["Ungeared", "Midpoint common weapon"]:
				var gear := {}
				if loadout != "Ungeared":
					gear.weapon = {"spell_power": 4 + 1.9 * level} if class_id == "mage" else {"dmg": 3 + 1.6 * level}
				var s := Systems.derive(level, gear, {}, class_id)
				var sk: Dictionary = GD.MAGE_BASE.cinder_thread if class_id == "mage" else GD.BASE.s1
				var packet := Resolver.snapshot(sk, s)
				var enemy_hp: float = round(46 * pow(1 + 0.3 * (level - 1), 1.35))
				file.store_csv_line([class_id, str(level), loadout, str(s.max_hp), str(s.max_mp), "%.3f" % s.dmg, "%.3f" % s.spell_power, str(s.armor), "%.3f" % (s.crit * 100), "%.3f" % s.mana_regen, "%.3f" % packet.direct, sk.id, str(enemy_hp), "%.3f" % (enemy_hp / packet.direct)])
	file.close()
	file = FileAccess.open("res://data/item_base_definitions.json", FileAccess.WRITE)
	var items := {}
	for base in Systems.NAMES:
		items[base] = {"name": Systems.NAMES[base], "footprint": [Systems.FOOTPRINTS[base].x, Systems.FOOTPRINTS[base].y], "equipment_destination": Systems.default_slot({"slot": base}), "two_handed": base == "staff", "warrior_allowed": Systems.drop_pool("warrior").has(base), "mage_allowed": Systems.drop_pool("mage").has(base)}
	file.store_string(JSON.stringify(items, "  ")); file.close()
	quit()
