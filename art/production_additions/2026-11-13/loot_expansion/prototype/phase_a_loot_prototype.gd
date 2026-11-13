extends RefCounted
## Experimental schema-safe non-equipment inventory planner.
## Not wired into Crownsfall gameplay or serialization.
const SYS := preload("res://scripts/systems.gd")
const DEFINITIONS := {
 "chronicle_heart":{"name":"Chronicle Heart","category":"relic","grid":Vector2i(2,2),"cap":1},
 "unwritten_seal":{"name":"Unwritten Seal","category":"relic","grid":Vector2i(1,2),"cap":1},
 "embermend_phial":{"name":"Embermend Phial","category":"consumable","grid":Vector2i(1,1),"cap":10},
 "moonglass_tonic":{"name":"Moonglass Tonic","category":"consumable","grid":Vector2i(1,1),"cap":10},
 "epoch_iron_ore":{"name":"Epoch Iron Ore","category":"material","grid":Vector2i(1,1),"cap":99},
 "riftglass_shards":{"name":"Riftglass Shards","category":"material","grid":Vector2i(1,1),"cap":99}
}
static func proposed_item(id:String, amount:int=1)->Dictionary:
 if not DEFINITIONS.has(id):return {}
 var def:Dictionary=DEFINITIONS[id]
 if amount<1 or amount>int(def.cap):return {}
 return {"uid":SYS.uid(),"kind":"non_equipment","catalog_id":id,"name":String(def.name),"count":amount,"x":-1,"y":-1}
static func footprint(item:Dictionary)->Vector2i:
 if String(item.get("kind",""))=="non_equipment":
  var def:Dictionary=DEFINITIONS.get(String(item.get("catalog_id","")),{})
  return def.get("grid",Vector2i.ZERO)
 return SYS.footprint(item)
static func valid(item:Dictionary)->bool:
 if String(item.get("kind",""))!="non_equipment":return false
 var id:String=String(item.get("catalog_id",""))
 if not DEFINITIONS.has(id):return false
 var def:Dictionary=DEFINITIONS[id]
 return item.get("name")==def.name and int(item.get("count",0))>=1 and int(item.get("count",0))<=int(def.cap) and footprint(item).x>0 and footprint(item).y>0
static func fits(bag:Array,item:Dictionary,at:Vector2i)->bool:
 var dim:=footprint(item)
 if dim.x<=0 or dim.y<=0 or at.x<0 or at.y<0 or at.x+dim.x>SYS.WIDTH or at.y+dim.y>SYS.HEIGHT:return false
 var target:=Rect2i(at,dim)
 for other in bag:
  var od:=footprint(other)
  if target.intersects(Rect2i(Vector2i(int(other.get("x",0)),int(other.get("y",0))),od)):return false
 return true
static func plan_add(bag:Array,id:String,amount:int)->Dictionary:
 if not DEFINITIONS.has(id) or amount<=0:return {"ok":false,"reason":"invalid input","inventory":bag.duplicate(true)}
 var candidate:Array=bag.duplicate(true)
 var remaining:=amount
 var cap:int=DEFINITIONS[id].cap
 for entry in candidate:
  if String(entry.get("kind",""))=="non_equipment" and entry.get("catalog_id")==id:
   var space:int=cap-int(entry.get("count",0))
   if space>0:
    var take:int=mini(space,remaining)
    entry.count=int(entry.count)+take;remaining-=take
    if remaining==0:break
 while remaining>0:
  var count:int=mini(cap,remaining)
  var new_item:Dictionary=proposed_item(id,count)
  var placed:=false
  for y in SYS.HEIGHT:
   for x in SYS.WIDTH:
    var at:=Vector2i(x,y)
    if fits(candidate,new_item,at):
     new_item.x=x;new_item.y=y;candidate.append(new_item);placed=true;break
   if placed:break
  if not placed:return {"ok":false,"reason":"inventory full; original untouched","inventory":bag.duplicate(true)}
  remaining-=count
 return {"ok":true,"reason":"planned","inventory":candidate}

