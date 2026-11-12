extends RefCounted
const SYS := preload("res://scripts/systems.gd")
const GOLD_CAP := 999999999
const MAX_DROPS := 512
const WAVE_RESERVE := 40 # Ten enemies, at most four drops each.
static func integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and value>=low and value<=high
static func problem(record: Variant) -> String:
	if not record is Dictionary: return "Invalid ground record."
	if not record.get("uid") is String or record.uid.is_empty() or record.uid.length()>128: return "Invalid ground identity."
	if not record.get("kind") in ["gold","potion","item"]: return "Unknown drop type."
	for axis in ["x","y"]:
		if not record.get(axis) is float and not record.get(axis) is int: return "Invalid ground position."
		if not is_finite(float(record[axis])): return "Invalid ground position."
	if not record.get("item") is Dictionary: return "Invalid ground item."
	if record.kind=="item":
		if not integer(record.get("amount"),0,0): return "Invalid item count."
	else:
		if not record.item.is_empty() or not integer(record.get("amount"),1,GOLD_CAP if record.kind=="gold" else 5): return "Invalid ground quantity."
	return ""
static func collect(bag: Array, gold: int, potions: int, record: Dictionary) -> Dictionary:
	var reason:=problem(record)
	if reason!="": return {"ok":false,"reason":reason}
	var next:=bag.duplicate(true); var remainder:=0; var taken:=0
	match record.kind:
		"item":
			if not SYS.insert(next,record.item.duplicate(true)):
				var span:=SYS.footprint(record.item)
				return {"ok":false,"reason":"Need a free %d × %d space. The item stays on the ground." % [span.x,span.y]}
		"gold":
			taken=mini(int(record.amount),maxi(0,GOLD_CAP-gold))
			if taken==0: return {"ok":false,"reason":"Gold limit reached. The pile stays on the ground."}
			gold+=taken; remainder=int(record.amount)-taken
		"potion":
			taken=mini(int(record.amount),maxi(0,5-potions))
			if taken==0: return {"ok":false,"reason":"You already carry five potions. The drop stays on the ground."}
			potions+=taken; remainder=int(record.amount)-taken
	return {"ok":true,"inventory":next,"gold":gold,"potions":potions,"remainder":remainder,"taken":taken}
