extends SceneTree
const SYS := preload("res://scripts/systems.gd")
const ART := preload("res://scripts/art_library.gd")
const PHASE := preload("res://scripts/phase_a_equipment.gd")
const TOWN := preload("res://scripts/town_actions.gd")
var n: int = 0
var fail: Array[String] = []
func verify(ok: bool, why: String) -> void:
 n += 1
 if not ok: fail.append(why); printerr("FAIL: ",why)
 else: print("PASS: ",why)
func _initialize() -> void:
 var mage: Array=PHASE.merchant_selection("mage",1)
 var warrior: Array=PHASE.merchant_selection("warrior",1)
 verify(mage.size()==5,"mage sees five compatible named variants")
 verify(warrior.size()==4,"warrior sees four compatible named variants")
 var all: Dictionary={}
 for k in ["mage","warrior"]:
  var entries: Array=mage if k=="mage" else warrior
  var unique: Dictionary={}
  for item in entries:
   verify(SYS.class_allows(item,k),k+" "+item.name+" class restriction")
   verify(not unique.has(item.name),k+" "+item.name+" is not duplicated")
   unique[item.name]=true
   verify(ART.inventory_portrait("phase_a/"+find_id(item.name))!=null,k+" "+item.name+" has imported texture")
   var state: Dictionary={"stock":[item.duplicate(true)],"inventory":[],"stash":[],"buyback":[],"gold":500,"potions":0}
   var purchase: Dictionary=TOWN.plan(state,"buy",item.uid)
   verify(purchase.ok,k+" "+item.name+" merchant purchase")
   if not purchase.ok:continue
   verify(purchase.state.inventory.size()==1 and purchase.state.stock.is_empty(),k+" "+item.name+" transferred")
   verify(purchase.state.gold<500,k+" "+item.name+" purchase deducted gold")
   var save: String=JSON.stringify({"schema":6,"inventory":purchase.state.inventory})
   var reload: Dictionary=JSON.parse_string(save)
   var restored: Dictionary=SYS.clean_item(reload.inventory[0])
   verify(restored.name==item.name,k+" "+item.name+" save/reload retains variant identity")
   var deposit: Dictionary=TOWN.plan(purchase.state,"deposit",item.uid)
   verify(deposit.ok,k+" "+item.name+" stash deposit")
   if deposit.ok:
    var withdraw: Dictionary=TOWN.plan(deposit.state,"withdraw",item.uid)
    verify(withdraw.ok,k+" "+item.name+" stash withdrawal")
    var sell: Dictionary=TOWN.plan(withdraw.state,"sell",item.uid) if withdraw.ok else {}
    verify(sell.get("ok",false),k+" "+item.name+" can be sold")
    if sell.get("ok",false):
     var buyback: Dictionary=TOWN.plan(sell.state,"buyback",item.uid)
     verify(buyback.ok,k+" "+item.name+" can be repurchased")
 for source in warrior:
  if source.name=="Crownfall Aegis":verify(not SYS.class_allows(source,"mage"),"shield correctly rejects mage")
 for source in mage:
  if source.slot=="focus":verify(not SYS.class_allows(source,"warrior"),source.name+" correctly rejects warrior")
 var out: Dictionary={"checks":n,"passed":n-fail.size(),"failures":fail,"scope":"production merchant transfer rules, source equipment, artwork import, class restrictions, stash, buyback, JSON roundtrip"}
 print("RESULT ",JSON.stringify(out))
 quit(0 if fail.is_empty() else 1)
func find_id(nm:String)->String:
 for id in PHASE.VARIANTS:
  if PHASE.VARIANTS[id].name==nm:return id
 return ""

