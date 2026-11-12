extends RefCounted
## Pure ownership/currency plans. Commit only after all containers validate.
const SYS := preload("res://scripts/systems.gd")
const GOLD_CAP := 999999999
const BUYBACK_CAP := 12
static func find_uid(items: Array, uid: String) -> int:
	for i in items.size():
		if items[i].get("uid","")==uid: return i
	return -1
static func sale_price(item: Dictionary) -> int: return clampi(int(item.get("value",5)),1,100000)
static func matches(item: Dictionary, query: String, category := "all") -> bool:
	var slot := SYS.default_slot(item)
	if category=="weapons" and not slot in ["weapon","offhand"]: return false
	if category=="armour" and not slot in ["helm","armor","gloves","boots"]: return false
	if category=="jewellery" and not slot in ["ring1","ring2","amulet","belt"]: return false
	if category=="unique" and not item.has("unique_id"): return false
	var haystack := (String(item.get("name",""))+" "+String(item.get("slot",""))+" "+slot).to_lower()
	for word in query.to_lower().strip_edges().split(" ",false):
		if not haystack.contains(word): return false
	return true
static func plan(state: Dictionary, action: String, uid := "", at: Variant=null, query := "", category := "all") -> Dictionary:
	var next := state.duplicate(true)
	var from := ""; var to := ""; var price := 0
	match action:
		"deposit": from="inventory"; to="stash"
		"withdraw": from="stash"; to="inventory"
		"buy": from="stock"; to="inventory"
		"buyback": from="buyback"; to="inventory"
		"sell": from="inventory"; to="buyback"
		"deposit_matching":
			var moved := 0
			for item in state.inventory:
				if not matches(item,query,category): continue
				var index := find_uid(next.inventory,item.uid)
				var copy: Dictionary=next.inventory[index].duplicate(true)
				if not SYS.insert(next.stash,copy): return {"ok":false,"reason":"Stash cannot hold every matching item. Nothing moved."}
				next.inventory.remove_at(index); moved+=1
			if moved==0: return {"ok":false,"reason":"No matching backpack items to deposit."}
			return {"ok":true,"reason":"Deposited %d matching items." % moved,"state":next}
		"potion":
			if int(state.potions)>=5: return {"ok":false,"reason":"You already carry five potions."}
			if int(state.gold)<5: return {"ok":false,"reason":"A health potion costs 5 gold."}
			next.gold=int(state.gold)-5; next.potions=int(state.potions)+1
			return {"ok":true,"reason":"Bought one health potion for 5 gold.","state":next}
		_: return {"ok":false,"reason":"Unknown town action."}
	var index := find_uid(next[from],uid)
	if index<0: return {"ok":false,"reason":"This item is no longer in that container."}
	var item: Dictionary=next[from][index].duplicate(true)
	if action in ["buy","buyback"]:
		price=sale_price(item)*(3 if action=="buy" else 1)
		if int(state.gold)<price: return {"ok":false,"reason":"Not enough gold: need %d." % price}
	if action=="sell":
		price=sale_price(item)
		if int(state.gold)+price>GOLD_CAP: return {"ok":false,"reason":"Gold limit reached. Item kept in the backpack."}
		next[from].remove_at(index); next.buyback.append(item)
		while next.buyback.size()>BUYBACK_CAP: next.buyback.pop_front()
		next.gold=int(state.gold)+price
		return {"ok":true,"reason":"Sold %s for %d gold. Available in Buyback." % [item.name,price],"state":next}
	if at!=null:
		if not at is Vector2i or not SYS.fits(next[to],item,at): return {"ok":false,"reason":"The item does not fit those cells. Nothing moved."}
		item.x=at.x; item.y=at.y; next[to].append(item)
	elif not SYS.insert(next[to],item): return {"ok":false,"reason":"%s is full. Item and gold kept." % ("Stash" if to=="stash" else "Backpack")}
	next[from].remove_at(index)
	if action in ["buy","buyback"]: next.gold=int(state.gold)-price
	return {"ok":true,"reason":("Bought %s for %d gold." % [item.name,price]) if price>0 else ("Moved %s to %s." % [item.name,to]),"state":next}
