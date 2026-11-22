extends SceneTree
const Art = preload("res://scripts/art_library.gd")
var checks := 0
var failures: Array[String] = []
func verify(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures.append(message)
func _initialize() -> void:
 var bases: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/item_base_definitions.json"))
 var records: Array = []
 for id in bases:
  var tex: Texture2D = Art.inventory_portrait(id)
  verify(tex != null, str(id)+": load")
  if tex == null: continue
  var cells: Array = bases[id].footprint
  verify(tex.get_width()*int(cells[1]) == tex.get_height()*int(cells[0]), str(id)+": footprint aspect")
  verify(Art.inventory_portrait(id) == tex, str(id)+": cache identity")
  var pixels := tex.get_image()
  verify(pixels != null and not pixels.is_empty(), str(id)+": decoded pixels")
  records.append({"id":id,"width":tex.get_width(),"height":tex.get_height(),"path":tex.resource_path})
 # Exercise selected-path failure against a real existing fallback.
 Art.portraits.clear()
 Art.selected_profile = {"portraits":{"amulet":"res://does_not_exist.png"}}
 var fallback: Texture2D = Art.inventory_portrait("amulet")
 verify(fallback != null and fallback.resource_path == "res://assets/item_portraits/amulet.png", "missing selected path falls back")
 Art.portraits.clear()
 Art.selected_profile = {"portraits":{"amulet":123}}
 fallback = Art.inventory_portrait("amulet")
 verify(fallback != null, "invalid selected mapping falls back")
 Art.portraits.clear()
 Art.selected_profile = {}
 verify(Art.inventory_portrait("weapon") != null, "profile reload after cache reset")
 var report := {"checks":checks,"failures":failures,"records":records,"engine":Engine.get_version_info(),"scope":"Headless import and real Art.inventory_portrait calls; no visual approval or full game input tests"}
 var f := FileAccess.open("res://engine_results.json", FileAccess.WRITE)
 f.store_string(JSON.stringify(report,"  ")+"\n")
 print("PORTRAIT_QA ",checks-failures.size(),"/",checks)
 for error in failures:push_error(error)
 quit(0 if failures.is_empty() else 1)
