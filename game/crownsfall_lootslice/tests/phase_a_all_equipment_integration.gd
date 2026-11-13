extends SceneTree
const SYS := preload("res://scripts/systems.gd")
const ART := preload("res://scripts/art_library.gd")
const PHASE := preload("res://scripts/phase_a_equipment.gd")
const TOWN := preload("res://scripts/town_actions.gd")
const EXPECTED:Dictionary={
"crownfall_aegis": {"base":"offhand","dims":Vector2i(2,2),"path":"phase_a/crownfall_aegis"},
"chronicle_codex": {"base":"focus","dims":Vector2i(1,2),"path":"phase_a/chronicle_codex"},
"emberglass_focus": {"base":"focus","dims":Vector2i(1,2),"path":"phase_a/emberglass_focus"},
"oathkeeper_signet": {"base":"ring","dims":Vector2i(1,1),"path":"phase_a/oathkeeper_signet"},
"veilthorn_band": {"base":"ring","dims":Vector2i(1,1),"path":"phase_a/veilthorn_band"},
"wayfarers_locket": {"base":"amulet","dims":Vector2i(1,1),"path":"phase_a/wayfarers_locket"},
"crownwarden_cuirass": {"base":"armor","dims":Vector2i(2,3),"path":"phase_a_armor/crownwarden_cuirass"},
"epochweave_robe": {"base":"robe","dims":Vector2i(2,3),"path":"phase_a_armor/epochweave_robe"},
"bastion_sallet": {"base":"helm","dims":Vector2i(2,2),"path":"phase_a_armor/bastion_sallet"},
"veilbound_hood": {"base":"hood","dims":Vector2i(2,2),"path":"phase_a_armor/veilbound_hood"},
"dawnsteel_gauntlets": {"base":"gloves","dims":Vector2i(2,2),"path":"phase_a_armor/dawnsteel_gauntlets"},
"wayfarer_greaves": {"base":"boots","dims":Vector2i(2,2),"path":"phase_a_armor/wayfarer_greaves"}}
var n:=0
var failures:Array[String]=[]
func assert_ok(ok:bool,label:String)->void:
 n+=1
 if ok: print("PASS: ",label)
 else:failures.append(label);printerr("FAIL: ",label)
func _initialize()->void:
 assert_ok(PHASE.VARIANTS.size()==12,"12 original named variants registered")
 for id in EXPECTED:
  var spec:Dictionary=EXPECTED[id]
  var variant:Dictionary=PHASE.VARIANTS[id]
  var item:Dictionary=PHASE.make_variant(id,12)
  assert_ok(not item.is_empty(),id+" named factory")
  assert_ok(item.name==variant.name,id+" exact name")
  assert_ok(item.slot==spec.base,id+" existing canonical base")
  assert_ok(SYS.footprint(item)==spec.dims,id+" inventory grid")
  assert_ok(SYS.class_allows(item,String(variant["class"])),id+" class permission")
  assert_ok(SYS.legal_slot(item,SYS.default_slot(item)),id+" equipment slot")
  var tex:Texture2D=ART.inventory_portrait(spec.path)
  assert_ok(tex!=null,id+" texture imports")
  if tex!=null:assert_ok(tex.get_size()==Vector2(spec.dims*64),id+" exact 64px per cell")
  var cleaned:Dictionary=SYS.clean_item(item)
  assert_ok(cleaned.name==item.name and SYS.footprint(cleaned)==spec.dims,id+" save sanitization roundtrip")
  var gear:Dictionary={}
  for slot in SYS.SLOTS: gear[slot]=null
  gear[SYS.default_slot(item)]=item
  assert_ok(SYS.gear_valid(gear,String(variant["class"]),12),id+" class gear validation")
 for class_id in ["warrior","mage"]:
  var offerings:Array=PHASE.merchant_selection(class_id,1)
  assert_ok(offerings.size()==(8 if class_id=="warrior" else 7),class_id+" selected stock count")
  var seen:Dictionary={}
  for item in offerings:
   assert_ok(not seen.has(item.name),class_id+" no duplicate "+item.name)
   seen[item.name]=true
   assert_ok(SYS.class_allows(item,class_id),class_id+" can equip "+item.name)
   var s:Dictionary={"stock":[item.duplicate(true)],"inventory":[],"stash":[],"buyback":[],"gold":500,"potions":0}
   var buy:Dictionary=TOWN.plan(s,"buy",item.uid)
   assert_ok(buy.ok,class_id+" buy "+item.name)
   if not buy.ok: continue
   assert_ok(buy.state.inventory.size()==1 and buy.state.stock.is_empty(),class_id+" ownership "+item.name)
   var deposit:Dictionary=TOWN.plan(buy.state,"deposit",item.uid)
   assert_ok(deposit.ok,class_id+" stash "+item.name)
   if not deposit.ok: continue
   var withdraw:Dictionary=TOWN.plan(deposit.state,"withdraw",item.uid)
   assert_ok(withdraw.ok,class_id+" withdraw "+item.name)
   if not withdraw.ok: continue
   var sell:Dictionary=TOWN.plan(withdraw.state,"sell",item.uid)
   assert_ok(sell.ok,class_id+" sell "+item.name)
   if not sell.ok: continue
   var reacquire:Dictionary=TOWN.plan(sell.state,"buyback",item.uid)
   assert_ok(reacquire.ok,class_id+" buyback "+item.name)
   if reacquire.ok:
    var json:String=JSON.stringify({"schema":6,"inventory":reacquire.state.inventory})
    var read:Dictionary=JSON.parse_string(json)
    assert_ok(read.schema==6 and read.inventory.size()==1 and SYS.clean_item(read.inventory[0]).name==item.name,class_id+" persistence "+item.name)
 var report:Dictionary={"checks":n,"passed":n-failures.size(),"failures":failures,"godot":Engine.get_version_info().string,"scope":"isolated copy of production Systems, ArtLibrary and TownActions with new 12-item PhaseA factory; not full playable scene"}
 print("RESULT ",JSON.stringify(report))
 quit(0 if failures.is_empty() else 1)

