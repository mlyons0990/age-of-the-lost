extends RefCounted
## Original named Phase A equipment variants. Existing base slots and stats remain authoritative.
const SYS := preload("res://scripts/systems.gd")
const VARIANTS := {
	"crownfall_aegis": {"name":"Crownfall Aegis","base":"offhand","class":"warrior"},
	"chronicle_codex": {"name":"Chronicle Codex","base":"focus","class":"mage"},
	"emberglass_focus": {"name":"Emberglass Focus","base":"focus","class":"mage"},
	"oathkeeper_signet": {"name":"Oathkeeper Signet","base":"ring","class":"warrior"},
	"veilthorn_band": {"name":"Veilthorn Band","base":"ring","class":"mage"},
	"wayfarers_locket": {"name":"Wayfarer's Locket","base":"amulet","class":"mage"},
	"crownwarden_cuirass": {"name":"Crownwarden Cuirass","base":"armor","class":"warrior"},
	"epochweave_robe": {"name":"Epochweave Robe","base":"robe","class":"mage"},
	"bastion_sallet": {"name":"Bastion Sallet","base":"helm","class":"warrior"},
	"veilbound_hood": {"name":"Veilbound Hood","base":"hood","class":"mage"},
	"dawnsteel_gauntlets": {"name":"Dawnsteel Gauntlets","base":"gloves","class":"warrior"},
	"wayfarer_greaves": {"name":"Wayfarer's Greaves","base":"boots","class":"warrior"},
}
static func make_variant(id: String, level: int = 1) -> Dictionary:
	if not VARIANTS.has(id): return {}
	var meta: Dictionary = VARIANTS[id]
	var item: Dictionary = SYS.make_item(level,0.0,String(meta.base),String(meta["class"]))
	item.name = String(meta.name)
	return item

static func merchant_selection(class_id: String, level: int = 1) -> Array:
	# New-character showcase stock only; no mutation of saved merchants or drop rates.
	var result: Array = []
	for id in VARIANTS:
		var meta: Dictionary = VARIANTS[id]
		var base: String = String(meta.base)
		if not SYS.drop_pool(class_id).has(base): continue
		var item: Dictionary = SYS.make_item(level,0.0,base,class_id)
		item.name = String(meta.name)
		result.append(item)
	return result
