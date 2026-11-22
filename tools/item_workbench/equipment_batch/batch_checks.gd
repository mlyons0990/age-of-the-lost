extends SceneTree
const S = preload("res://scripts/systems.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
 checks+=1
 if not ok:failures.append(label)
func _initialize() -> void:
 var bases: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/item_base_definitions.json"))
 var blocker: Dictionary={"uid":"block","slot":"ring","x":4,"y":2}
 for id in bases:
  var item: Dictionary={"uid":"test","slot":id}
  var wh: Array=bases[id].footprint
  var w:=int(wh[0]);var h:=int(wh[1])
  check(S.footprint(item)==Vector2i(w,h),str(id)+" exported/runtime footprint")
  check(S.default_slot(item)==bases[id].equipment_destination,str(id)+" destination")
  for y in range(-1,7):
   for x in range(-1,11):
    var expected := true
    for cy in range(y,y+h):
     for cx in range(x,x+w):
      if cx<0 or cx>=10 or cy<0 or cy>=6 or (cx==4 and cy==2):expected=false
    check(S.fits([blocker],item,Vector2i(x,y))==expected,str(id)+" occupied/bounds "+str(Vector2i(x,y)))
  check(S.fits([blocker],item,Vector2i(4,2),"block"),str(id)+" ignore moved item")
 var full: Array=[]
 for y in 6:
  for x in 10:full.append({"uid":str(x)+"-"+str(y),"slot":"ring","x":x,"y":y})
 var snapshot:=JSON.stringify(full)
 var incoming: Dictionary={"uid":"new","slot":"amulet"}
 check(not S.insert(full,incoming),"full bag rejects insert")
 check(JSON.stringify(full)==snapshot and not incoming.has("x"),"failed insert preserves bag and incoming")
 var impossible: Array=full.duplicate(true);impossible.append({"uid":"extra","slot":"ring","x":0,"y":0})
 var before:=JSON.stringify(impossible)
 check(not S.sort_bag(impossible),"overcapacity sort fails")
 check(JSON.stringify(impossible)==before,"failed sort preserves original")
 var mixed: Array=[]
 for id in ["weapon","staff","ring","amulet","belt"]:check(S.insert(mixed,{"uid":id,"slot":id}),"insert "+id)
 var ids: Array=[]
 for item in mixed:ids.append(item.uid)
 check(S.sort_bag(mixed),"mixed sort succeeds")
 var after_ids: Array=[]
 for item in mixed:
  after_ids.append(item.uid)
  check(S.fits(mixed,item,Vector2i(item.x,item.y),item.uid),"sorted placement legal "+str(item.uid))
 ids.sort();after_ids.sort();check(ids==after_ids,"sort preserves ownership IDs")
 var output:=FileAccess.open("res://inventory_results.json",FileAccess.WRITE)
 output.store_string(JSON.stringify({"checks":checks,"failures":failures,"engine":Engine.get_version_info(),"scope":"Real Systems rules; independent cell occupancy oracle; no live GUI or persistence integration"},"  ")+"\n")
 # Seeded empirical item-generation baseline, not an approved rebalance.
 var rows: Array=[]
 for id in bases:
  for level in [1,10,20,40,60]:
   for rare in range(4):
    var values: Dictionary={}
    for sample in range(32):
     seed(hash(str(id)+":"+str(level)+":"+str(rare)+":"+str(sample)))
     var boosts: Array=[-2.0,0.56,0.84,2.0]
     # Negative/large boosts force common/legendary; middle boosts do not force tiers.
     var item: Dictionary=S.make_item(level,boosts[rare],id)
     for stat in ["dmg","armor","hp","crit","spell_power","value"]:
      if not values.has(stat):values[stat]=[]
      values[stat].append(float(item.get(stat,0)))
    var stats: Dictionary={}
    for stat in values:
     var sum:=0.0
     for v in values[stat]:sum+=v
     stats[stat]={"min":values[stat].min(),"max":values[stat].max(),"mean":sum/32.0}
    rows.append({"item":id,"level":level,"boost_scenario":boosts_label(rare),"samples":32,"stats":stats})
 var f:=FileAccess.open("res://balance_baseline.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"note":"Empirical seeded samples of existing generator, NOT proposed balance. Middle boost scenarios mix rarity tiers; do not interpret as rarity-specific curves.","rows":rows},"  ")+"\n")
 print("INVENTORY_RULES ",checks-failures.size(),"/",checks)
 quit(0 if failures.is_empty() else 1)
func boosts_label(i: int) -> String:
 return ["common_forced_minus2","boost_plus0.56_mixed","boost_plus0.84_mixed","top_tier_forced_plus2"][i]
