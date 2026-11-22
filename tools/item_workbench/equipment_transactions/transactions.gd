extends SceneTree
const Player = preload("res://scripts/player.gd")
const S = preload("res://scripts/systems.gd")
const Store = preload("res://scripts/save_store.gd")
const Disk = preload("res://scripts/save_disk.gd")
const Aura = preload("res://scripts/aura_controller.gd")
class QuietSound extends RefCounted:
 var cues:=0
 func play_cue(_id:String)->void:cues+=1
class FaultDisk extends Disk:
 var fail_write:=false
 var fail_primary:=false
 var fail_backup:=false
 func write(path:String,content:String)->bool:
  return false if fail_write else super.write(path,content)
 func rename(source:String,target:String)->bool:
  if fail_primary and source.ends_with('.tmp'):return false
  if fail_backup and target.ends_with('.bak'):return false
  return super.rename(source,target)
class Host extends Node2D:
 var actor
 var sound=QuietSound.new()
 var store=Store.new()
 var last_result:Dictionary={}
 var path:="user://equipment_test.json"
 func valid(d:Dictionary)->bool:
  return d.get('schema')==6 and d.get('inventory') is Array and d.get('gear') is Dictionary
 func persist_changes(changes:Dictionary)->bool:
  var state:Dictionary={'schema':6,'inventory':actor.inventory.duplicate(true),'gear':actor.gear.duplicate(true)}
  state.merge(changes,true)
  last_result=store.commit(path,state,valid,6)
  return last_result.ok
var checks:=0
var failures:Array[String]=[]
func verify(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func state(p)->String:return JSON.stringify({'bag':p.inventory,'gear':p.gear})
func item(kind:String,id:String)->Dictionary:
 var x:=S.make_item(1,-2,kind,'mage');x.uid=id;return x
func _initialize()->void:
 var p=Player.new();var host=Host.new();p.main=host;host.actor=p;p.class_id='mage';p.level=60;p.aura=Aura.new();p.aura.actor=p
 var disk=FaultDisk.new();host.store.disk=disk
 for suffix in ['', '.tmp','.bak','.bak.pending']:disk.remove(host.path+suffix)
 var wand:=item('wand','wand');var focus:=item('focus','focus');var staff:=item('staff','staff')
 p.gear.weapon=wand;p.gear.offhand=focus;S.insert(p.inventory,staff)
 var original:=state(p);var plan:Dictionary=p.plan_equip(0,'weapon')
 verify(plan.ok,'staff swap plan succeeds');verify(state(p)==original,'planning does not mutate')
 verify(plan.gear.offhand==null,'two-handed clears offhand in plan')
 var ids:Array=[]
 for x in plan.inventory:ids.append(x.uid)
 verify(ids.has('wand') and ids.has('focus') and ids.size()==2,'both displaced items retained')
 disk.fail_write=true
 verify(not p.equip_item(0,'weapon'),'write failure rejects equipment transaction')
 verify(state(p)==original and host.sound.cues==0,'write failure preserves live state and feedback')
 disk.fail_write=false
 verify(p.equip_item(0,'weapon'),'equip commits')
 verify(p.gear.weapon.uid=='staff' and p.gear.offhand==null,'staff and offhand state applied')
 var saved:Dictionary=JSON.parse_string(disk.read(host.path).text)
 verify(saved.gear.weapon.uid=='staff' and saved.inventory.size()==2,'disk roundtrip retains ownership')
 var focus_index:=-1
 for i in p.inventory.size():
  if p.inventory[i].uid=='focus':focus_index=i
 verify(not p.plan_equip(focus_index,'offhand').ok,'focus rejected while staff equipped')
 original=state(p);disk.fail_primary=true
 verify(not p.unequip_item('weapon'),'primary rename failure rejects unequip')
 verify(state(p)==original,'rename failure preserves live gear')
 verify(JSON.parse_string(disk.read(host.path).text).gear.weapon.uid=='staff','rename failure preserves durable gear')
 disk.fail_primary=false;disk.fail_backup=true
 verify(p.unequip_item('weapon'),'backup warning after primary commit remains success')
 verify(p.gear.weapon==null and host.last_result.warning!='','committed state applied despite backup warning')
 saved=JSON.parse_string(disk.read(host.path).text)
 verify(saved.gear.weapon==null and saved.inventory.size()==3,'warning commit durable and items preserved')
 disk.fail_backup=false
 p.inventory=[]
 for y in 6:
  for x in 10:
   var ring:=item('ring',str(x)+'-'+str(y));ring.x=x;ring.y=y;p.inventory.append(ring)
 p.gear.amulet=item('amulet','equipped-amulet');original=state(p)
 verify(not p.unequip_item('amulet'),'full bag rejects unequip')
 verify(state(p)==original,'full bag leaves ownership unchanged')
 var invalid:=item('weapon','wrong-class');p.inventory=[invalid]
 verify(not p.plan_equip(0,'weapon').ok,'mage rejects warrior sword')
 var high:=item('wand','high');high.level=60;p.inventory=[high];p.level=1
 verify(not p.plan_equip(0,'weapon').ok,'level requirement enforced')
 # External save edits must protect both durable and live equipment.
 p.level=60;p.inventory=[];S.insert(p.inventory,item('wand','replacement'));p.gear.weapon=null
 var durable:String=disk.read(host.path).text
 var newer:Dictionary=JSON.parse_string(durable);newer.schema=7;disk.write(host.path,JSON.stringify(newer))
 original=state(p)
 verify(not p.equip_item(0,'weapon') and host.last_result.protected,'newer schema blocks overwrite')
 verify(state(p)==original and JSON.parse_string(disk.read(host.path).text).schema==7,'newer save and live state preserved')
 disk.write(host.path,'{broken-json')
 verify(not p.equip_item(0,'weapon') and host.last_result.protected,'corrupted primary blocks transaction')
 verify(state(p)==original and disk.read(host.path).text=='{broken-json','corrupt bytes retained for recovery')
 disk.write(host.path,durable)
 verify(not p.plan_equip(-1,'weapon').ok and not p.plan_equip(999,'weapon').ok,'invalid bag indices rejected')
 verify(not p.plan_equip(0,'unknown_slot').ok,'unknown equipment destination rejected')
 # Only a 1x2 opening is freed by the wand; an equipped 2x4 staff cannot fit.
 p.inventory=[];p.gear.weapon=item('staff','large-equipped')
 var wand_item:=item('wand','bag-wand');wand_item.x=0;wand_item.y=0;p.inventory.append(wand_item)
 for y in 6:
  for x in 10:
   if x==0 and y<2:continue
   var ring:=item('ring','packed-'+str(x)+'-'+str(y));ring.x=x;ring.y=y;p.inventory.append(ring)
 original=state(p)
 verify(not p.plan_equip(0,'weapon').ok,'full bag blocks displaced larger weapon')
 verify(state(p)==original,'blocked swap preserves all items')
 # Restore a fresh actor from actual JSON, not the live dictionaries.
 var reloaded=Player.new();reloaded.inventory=saved.inventory;reloaded.gear=saved.gear
 verify(reloaded.inventory.size()==3 and reloaded.gear.weapon==null,'fresh actor receives persisted equipment state')
 var unique:Dictionary={}
 for x in reloaded.inventory:unique[x.uid]=true
 verify(unique.size()==3,'no duplicate ownership after reload')
 var f:=FileAccess.open('res://results.json',FileAccess.WRITE)
 f.store_string(JSON.stringify({'checks':checks,'failures':failures,'scope':'Actual Player equipment methods and SaveStore disk commits; minimal host adapter and structural validator, not full Main save validator or UI'},'  ')+'\n')
 print('EQUIPMENT_TRANSACTIONS ',checks-failures.size(),'/',checks)
 reloaded.free();p.free();host.free()
 quit(0 if failures.is_empty() else 1)
