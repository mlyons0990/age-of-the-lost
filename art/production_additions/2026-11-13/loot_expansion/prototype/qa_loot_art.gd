extends SceneTree
const ART := preload("res://scripts/art_library.gd")
const SPECS:Dictionary = {
 "chronicle_heart":{"category":"relic","dims":Vector2i(2,2)},
 "unwritten_seal":{"category":"relic","dims":Vector2i(1,2)},
 "embermend_phial":{"category":"consumable","dims":Vector2i(1,1)},
 "moonglass_tonic":{"category":"consumable","dims":Vector2i(1,1)},
 "epoch_iron_ore":{"category":"material","dims":Vector2i(1,1)},
 "riftglass_shards":{"category":"material","dims":Vector2i(1,1)}
}
var passed:=0
var failures:Array[String]=[]
func check(ok:bool, label:String)->void:
 if ok: passed+=1;print("PASS ",label)
 else:failures.append(label);printerr("FAIL ",label)
func _initialize()->void:
 check(SPECS.size()==6,"Six new art IDs are specified")
 for k in SPECS:
  var info:Dictionary=SPECS[k]
  var path:String="res://assets/item_portraits/phase_a_loot/"+k+".png"
  check(ResourceLoader.exists(path),k+" resource exists")
  var tex:Texture2D=ART.inventory_portrait("phase_a_loot/"+k)
  check(tex!=null,k+" production art loader resolves texture")
  if tex!=null: check(tex.get_size()==Vector2(info.dims*64),k+" exact 64px per cell dimensions")
  var img:Image=Image.new()
  var err:=img.load(path)
  check(err==OK,k+" image file loads")
  if err==OK:
   check(img.get_format()==Image.FORMAT_RGBA8,k+" RGBA8")
   check(img.get_pixel(0,0).a<0.05,k+" transparent outer gutter")
   var t:ImageTexture=ImageTexture.create_from_image(img)
   check(t!=null,k+" Godot texture object created")
 var report:Dictionary={"passed":passed,"failed":failures,"total":passed+failures.size(),"scope":"Isolated Godot 4.4.1 asset import; new categories are NOT registered with equipment Systems and cannot yet be placed/saved/used in live game"}
 print("RESULT ",JSON.stringify(report))
 quit(0 if failures.is_empty() else 1)

