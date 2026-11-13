extends SceneTree
const SYS := preload("res://scripts/systems.gd")
const ART := preload("res://scripts/art_library.gd")
const Factory := preload("res://scripts/phase_a_equipment.gd")
const ENTRIES := [
 {"id":"crownfall_aegis","class_id":"warrior","grid":Vector2i(2,2)},
 {"id":"chronicle_codex","class_id":"mage","grid":Vector2i(1,2)},
 {"id":"emberglass_focus","class_id":"mage","grid":Vector2i(1,2)},
 {"id":"oathkeeper_signet","class_id":"warrior","grid":Vector2i(1,1)},
 {"id":"veilthorn_band","class_id":"mage","grid":Vector2i(1,1)},
 {"id":"wayfarers_locket","class_id":"mage","grid":Vector2i(1,1)}
]
var failures: Array[String] = []
var count := 0
func check(ok: bool, reason: String) -> void:
 count += 1
 if not ok: failures.append(reason); printerr("FAIL: ",reason)
 else: print("PASS: ",reason)
func _initialize() -> void:
 var bag: Array = []
 for ent in ENTRIES:
  var id: String = ent.id
  var item: Dictionary = Factory.make_variant(id, 12)
  check(not item.is_empty(),id+" factory")
  check(item.name == String(Factory.VARIANTS[id].name),id+" name matches")
  check(SYS.footprint(item) == ent.grid,id+" authoritative footprint")
  check(SYS.class_allows(item,ent.class_id),id+" class permitted")
  check(SYS.legal_slot(item,SYS.default_slot(item)),id+" legal equipment slot")
  var tex: Texture2D = ART.inventory_portrait("phase_a/"+id)
  check(tex != null,id+" actual ART inventory portrait loaded")
  if tex != null: check(tex.get_size() == Vector2(ent.grid*64),id+" inventory portrait renders at 64px/cell")
  var clean: Dictionary = SYS.clean_item(item)
  check(clean.name == item.name and SYS.footprint(clean)==ent.grid,id+" name/footprint preserved through save cleanup")
  check(SYS.insert(bag,item),id+" valid bag placement")
  check(not SYS.fits(bag,item,Vector2i(item.x,item.y)),id+" collision protection")
 check(bag.size()==6,"six named items in bag")
 var serialized=JSON.stringify({"schema":6,"inventory":bag})
 var decoded: Dictionary=JSON.parse_string(serialized)
 check(decoded.schema==6 and decoded.inventory.size()==6,"schema 6 JSON roundtrip")
 for raw in decoded.inventory:
  var item=SYS.clean_item(raw)
  var portrait=ART.inventory_portrait("phase_a/"+Factory.VARIANTS.keys()[0]) if false else ART.inventory_portrait("phase_a/"+find_id(item.name))
  check(portrait!=null, "restored item "+item.name+" retains portrait")
 var warrior_gear:Dictionary={"weapon":null,"offhand":Factory.make_variant("crownfall_aegis"),"helm":null,"armor":null,"gloves":null,"belt":null,"boots":null,"ring1":Factory.make_variant("oathkeeper_signet"),"ring2":null,"amulet":null}
 check(SYS.gear_valid(warrior_gear,"warrior",12),"warrior shield/ring equipment valid")
 var mage_gear:Dictionary={"weapon":null,"offhand":Factory.make_variant("chronicle_codex"),"helm":null,"armor":null,"gloves":null,"belt":null,"boots":null,"ring1":Factory.make_variant("veilthorn_band"),"ring2":null,"amulet":Factory.make_variant("wayfarers_locket")}
 check(SYS.gear_valid(mage_gear,"mage",12),"mage codex/ring/amulet equipment valid")
 check(not SYS.gear_valid(warrior_gear,"mage",12),"shield rejected for mage")
 check(not SYS.gear_valid(mage_gear,"warrior",12),"focus rejected for warrior")
 var report={"passed":count-failures.size(),"failed":failures,"tests":count,"scope":"Actual production art_library, systems, named-item factory, image import, save cleanup, class equip, inventory positioning"}
 print("RESULT ",JSON.stringify(report))
 quit(0 if failures.is_empty() else 1)
func find_id(name:String)->String:
 for id in Factory.VARIANTS:
  if Factory.VARIANTS[id].name==name: return id
 return ""

