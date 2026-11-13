extends SceneTree
const LOOT:=preload("res://scripts/phase_a_loot_prototype.gd")
const SYS:=preload("res://scripts/systems.gd")
var checks:=0
var bad:Array[String]=[]
func verify(ok:bool,msg:String)->void:
 checks+=1
 if ok:print("PASS ",msg)
 else:bad.append(msg);printerr("FAIL ",msg)
func _initialize()->void:
 verify(LOOT.DEFINITIONS.size()==6,"six prototype definitions")
 for id in LOOT.DEFINITIONS:
  var d:Dictionary=LOOT.DEFINITIONS[id]
  var item:Dictionary=LOOT.proposed_item(id,1)
  verify(LOOT.valid(item),id+" valid item")
  verify(LOOT.footprint(item)==d.grid,id+" explicit proposed footprint")
  verify(LOOT.proposed_item(id,int(d.cap)+1).is_empty(),id+" rejects stack overflow")
  verify(LOOT.fits([],item,Vector2i(0,0)),id+" fits empty inventory")
  verify(not LOOT.fits([],item,Vector2i(SYS.WIDTH,0)),id+" rejects out of bounds")
  verify(not LOOT.fits([],item,Vector2i(0,SYS.HEIGHT)),id+" rejects bottom out of bounds")
  var packed:Dictionary=LOOT.plan_add([],id,1)
  verify(packed.ok and packed.inventory.size()==1,id+" insert planned")
  if packed.ok:
   var saved:String=JSON.stringify({"kind":"experimental_v7_draft","items":packed.inventory})
   var raw:Dictionary=JSON.parse_string(saved)
   var restored:Dictionary=raw.items[0]
   verify(LOOT.valid(restored),id+" JSON roundtrip")
 var base:Array=[]
 var potion:Dictionary=LOOT.plan_add(base,"embermend_phial",7)
 verify(potion.ok and potion.inventory.size()==1 and potion.inventory[0].count==7,"potion stacks to seven")
 var potion_more:Dictionary=LOOT.plan_add(potion.inventory,"embermend_phial",8)
 verify(potion_more.ok and potion_more.inventory.size()==2,"potion creates second stack over ten")
 if potion_more.ok:
  verify(potion_more.inventory[0].count==10 and potion_more.inventory[1].count==5,"potion split 10+5")
 var ore:Dictionary=LOOT.plan_add([],"epoch_iron_ore",231)
 verify(ore.ok and ore.inventory.size()==3,"material splits into three stacks")
 if ore.ok:verify(ore.inventory[0].count==99 and ore.inventory[1].count==99 and ore.inventory[2].count==33,"material splits 99+99+33")
 var relics:Dictionary=LOOT.plan_add([],"chronicle_heart",3)
 verify(relics.ok and relics.inventory.size()==3,"relics never stack")
 var legacy:Dictionary=SYS.make_item(4,0,"armor","warrior");legacy.x=0;legacy.y=0
 verify(LOOT.footprint(legacy)==Vector2i(2,3),"legacy gear footprint maintained")
 verify(not LOOT.fits([legacy],LOOT.proposed_item("embermend_phial"),Vector2i(0,0)),"cannot overlap old armor")
 var with_legacy:Dictionary=LOOT.plan_add([legacy],"moonglass_tonic",1)
 verify(with_legacy.ok and with_legacy.inventory.size()==2,"new potion placed beside legacy gear")
 var blocked:Array=[]
 for y in SYS.HEIGHT:
  for x in SYS.WIDTH:
   blocked.append({"kind":"non_equipment","catalog_id":"epoch_iron_ore","name":"Epoch Iron Ore","count":1,"x":x,"y":y,"uid":str(x)+str(y)})
 var failed:Dictionary=LOOT.plan_add(blocked,"embermend_phial",1)
 verify(not failed.ok and failed.inventory.size()==blocked.size(),"full inventory add fails atomically")
 verify(not LOOT.plan_add([],"nonexistent",1).ok,"unknown catalog ID rejected")
 verify(not LOOT.plan_add([],"embermend_phial",0).ok,"non-positive count rejected")
 var report:Dictionary={"checks":checks,"passed":checks-bad.size(),"failures":bad,"scope":"experimental non-equipment stack/placement planner, not integrated into live game"}
 print("RESULT ",JSON.stringify(report))
 quit(0 if bad.is_empty() else 1)

