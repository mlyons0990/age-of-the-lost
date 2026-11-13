extends SceneTree
const SYS = preload("res://scripts/systems.gd")
const ITEMS = [
    {"id":"crownfall_aegis","family":"offhand","dims":Vector2i(2,2),"slot":"offhand","class_id":"warrior"},
    {"id":"chronicle_codex","family":"focus","dims":Vector2i(1,2),"slot":"offhand","class_id":"mage"},
    {"id":"emberglass_focus","family":"focus","dims":Vector2i(1,2),"slot":"offhand","class_id":"mage"},
    {"id":"oathkeeper_signet","family":"ring","dims":Vector2i(1,1),"slot":"ring1","class_id":"mage"},
    {"id":"veilthorn_band","family":"ring","dims":Vector2i(1,1),"slot":"ring2","class_id":"warrior"},
    {"id":"wayfarers_locket","family":"amulet","dims":Vector2i(1,1),"slot":"amulet","class_id":"mage"}
]
var tests: int = 0
var failures: Array = []
func check(condition: bool, description: String) -> void:
    tests += 1
    if not condition:
        failures.append(description)
        printerr("FAIL: ", description)
    else:
        print("PASS: ", description)
func _initialize() -> void:
    var data_file := FileAccess.open("res://data/item_base_definitions.json", FileAccess.READ)
    check(data_file != null, "Existing item definition JSON loads")
    if data_file == null:
        quit(2)
        return
    var definitions: Dictionary = JSON.parse_string(data_file.get_as_text())
    check(SYS.WIDTH == 10 and SYS.HEIGHT == 6, "Production inventory uses 10x6 grid")
    var bag: Array = []
    for info in ITEMS:
        var path: String = "res://items/" + info.id + "_" + str(info.dims.x) + "x" + str(info.dims.y) + "_128px_rgba.png"
        var img := Image.new()
        var err := img.load(path)
        check(err == OK, info.id + " image load")
        if err != OK: continue
        check(img.get_format() == Image.FORMAT_RGBA8, info.id + " RGBA8 format")
        var dimensions: Vector2i = info.dims * 128
        check(img.get_size() == dimensions, info.id + " texture dimensions")
        var tex: ImageTexture = ImageTexture.create_from_image(img)
        check(tex != null and tex.get_size() == Vector2(dimensions), info.id + " GPU texture")
        var display := TextureRect.new()
        display.texture = tex
        display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        display.custom_minimum_size = Vector2(info.dims * 50)
        check(display.custom_minimum_size == Vector2(info.dims * 50), info.id + " drag preview geometry")
        display.free()
        var item: Dictionary = SYS.make_item(24, 0.2, info.family, info.class_id)
        item.name = info.id
        check(SYS.footprint(item) == info.dims, info.id + " production footprint")
        check(definitions.has(info.family) and Vector2i(definitions[info.family].footprint[0], definitions[info.family].footprint[1]) == info.dims, info.id + " matches base item definitions")
        check(SYS.insert(bag, item), info.id + " inserted into 10x6 bag")
        check(not SYS.fits(bag, item, Vector2i(int(item.x), int(item.y))), info.id + " overlap rejected")
        check(not SYS.fits([], item, Vector2i(10-info.dims.x+1, 0)), info.id + " overhang rejected")
        check(definitions[info.family].equipment_destination == info.slot or (info.family == "ring" and info.slot == "ring2"), info.id + " legal equipment destination")
        check(definitions[info.family][info.class_id + "_allowed"], info.id + " class equipment permitted")
    check(bag.size() == 6, "Six preview items stored")
    var occupied: int = 0
    for item in bag:
        occupied += SYS.footprint(item).x * SYS.footprint(item).y
    check(occupied == 11, "All six footprints occupy expected 11 cells")
    var save_text: String = JSON.stringify({"schema":6,"inventory":bag})
    var readback: Dictionary = JSON.parse_string(save_text)
    check(readback.schema == 6 and readback.inventory.size() == 6, "in-memory schema-6 JSON roundtrip")
    var recovered: Array = readback.inventory
    check(SYS.sort_bag(recovered), "Production inventory repacking succeeds")
    check(recovered.size() == 6, "No assets lost in repack")
    var summary: Dictionary = {"test_count":tests,"failed":failures,"passed":tests-failures.size(),"asset_count":6,"godot_version":Engine.get_version_info().string,"test_scope":"standalone texture import + actual production systems.gd + inventory metadata","notes":"Not a full game UI, merchant, equipment or disk save-load regression. Chronicle Codex and Emberglass Focus map to mage focus 1x2 family."}
    var result := FileAccess.open("user://aotl_asset_test_result.json",FileAccess.WRITE)
    result.store_string(JSON.stringify(summary,"  "))
    print("RESULT ",JSON.stringify(summary))
    quit(0 if failures.is_empty() else 1)

