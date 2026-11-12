extends SceneTree
const MD := preload("res://scripts/mastery_data.gd")
const SYS := preload("res://scripts/systems.gd")
const DATA := preload("res://scripts/game_data.gd")
const RESOLVER := preload("res://scripts/effect_resolver.gd")
func write_json(path: String, value: Variant) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(value,"  ")); file.close()
func _initialize() -> void:
	write_json("res://data/mastery_nodes.json",{"status":"implemented","point_rule":"Mage: one point every five levels, 20 through 60","nodes":MD.NODES})
	write_json("res://data/runtime_unique_definitions.json",{"emberwake_circlet":{"base":"hood","destination":"helm","class":"mage","required_level":40,"armor":60,"intelligence":12,"attunement_gold":250,"sell_gold":125,"once_per_character":true,"pulse_interval_multiplier":0.8,"pulse_damage_multiplier":0.8,"pulse_cost_multiplier":0.8,"burn_extension_seconds":0.15,"burn_duration_cap_seconds":4}})
	var ranks:={"ward_temper":1,"ember_aura":1,"cinder_bloom":1}
	write_json("res://data/implemented_ability_variants.json",{"base_ability_id":"ashen_ward","saved_hotbar_id":"ashen_ward","variant":MD.definition(DATA.spells().ashen_ward,ranks),"siphon_healing_fraction":0.02,"siphon_rolling_one_second_max_hp_fraction":0.03,"cinder_patch_duration":1.0,"cinder_patch_coefficient_per_second":0.15,"cinder_patch_cap":8,"secondary_proc_depth":1})
	var csv:="level,loadout,earned_mastery_points,spent_mastery_points,spell_power,variant,ward_capacity,aura_noncrit_dps,pulse_seconds,mana_per_pulse,upkeep_per_second,natural_regen,active_regen,net_mana_per_second,cinder_hits_per_second_to_sustain,seconds_from_full_after_activation\n"
	var count:=0
	for level in [1,10,20,40,45,50,55,60]:
		for loadout in ["ungeared","midpoint_common_staff","staff_and_emberwake","staff_emberwake_full_mastery"]:
			var circlet:bool=loadout in ["staff_and_emberwake","staff_emberwake_full_mastery"]
			if circlet and level<40: continue
			var gear:={}
			if loadout!="ungeared":gear.weapon={"spell_power":round(4+1.9*level)}
			if circlet:gear.helm={"armor":60,"intelligence":12}
			var stats:=SYS.derive(level,gear,{"spell_dmg":0.2 if level>=40 else 0.0},"mage")
			var nodes:={}
			if level>=20:nodes.ward_temper=1
			if level>=40:nodes.ember_aura=1
			if loadout=="staff_emberwake_full_mastery":
				nodes.cinder_bloom=1
				if level>=45:nodes.steady_flame=mini(2,int((level-40)/5))
				if level>=55:nodes.ward_temper=mini(3,1+int((level-50)/5))
			var skill:=MD.definition(DATA.spells().ashen_ward,nodes,circlet)
			assert(MD.problem(nodes,"mage",level,["first_echo"])=="")
			var aura:bool=skill.type=="aura"
			var upkeep:float=skill.pulse_cost/skill.pulse_interval if aura else 0.0
			var regen:float=stats.mana_regen*float(skill.get("regen_multiplier",1))
			var deficit:float=maxf(0,upkeep-regen)
			csv+="%d,%s,%d,%d,%.3f,%s,%.1f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%s\n" % [level,loadout,MD.earned("mage",level),MD.spent(nodes),stats.spell_power,skill.get("variant","ashen_ward"),RESOLVER.ward_capacity(skill,stats) if not aura else 0.0,stats.spell_power*skill.dmg/skill.pulse_interval if aura else 0.0,skill.get("pulse_interval",0),skill.get("pulse_cost",0),upkeep,stats.mana_regen,regen,regen-upkeep,deficit/3.0,("%.1f" % ((stats.max_mp-10)/deficit)) if aura and deficit>0 else "n/a"]
			count+=1
	var f:=FileAccess.open("res://data/mastery_balance_snapshot.csv",FileAccess.WRITE);f.store_string(csv);f.close()
	print("Exported mastery nodes, runtime unique, variant and %d tuning checkpoints." % count)
	quit()
