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
}
static func make_variant(id: String, level: int = 1) -> Dictionary:
	if not VARIANTS.has(id): return {}
	var meta: Dictionary = VARIANTS[id]
	var item: Dictionary = SYS.make_item(level,0.0,String(meta.base),String(meta["class"]))
	item.name = String(meta.name)
	return item
