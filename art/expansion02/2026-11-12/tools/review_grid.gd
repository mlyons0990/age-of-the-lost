extends Control
var entries: Array=[]
var catalog: Dictionary
var page:=0
var selected:=-1
var textures: Dictionary={}
var small_textures: Dictionary={}
func _ready() -> void:
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://catalog.json"))
	entries=JSON.parse_string(FileAccess.get_file_as_string("res://EXPORT_REPORT.json"))
	for record in entries:
		textures[record.asset_id]=ImageTexture.create_from_image(Image.load_from_file("res://"+String(record.output)))
		var entry: Dictionary=catalog.entries[int(record.index)-1]
		if entry.kind=="ui_icon":
			for edge in [32,64,128]:
				small_textures[String(record.asset_id)+str(edge)]=ImageTexture.create_from_image(Image.load_from_file("res://runtime_sizes/%d/" % edge+String(record.asset_id)+".png"))
	queue_redraw()
	if "--capture" in OS.get_cmdline_user_args(): call_deferred("capture_pages")
func capture_pages() -> void:
	for n in ceili(entries.size()/12.0):
		page=n; queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://previews/grid_%02d.png" % (n+1))
	for kind in ["sword","ring"]:
		for i in entries.size():
			var candidate: Dictionary=catalog.entries[int(entries[i].index)-1]
			if candidate.type!=kind: continue
			page=floori(i/12.0); selected=-1
			var slot:=i%12
			var click:=InputEventMouseButton.new()
			click.button_index=MOUSE_BUTTON_LEFT; click.pressed=true
			click.position=Vector2(22+(slot%4)*394+190,88+floori(slot/4.0)*326+156)
			_input(click)
			assert(selected==i,"Art inspection click did not select expected item")
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://previews/detail_%s.png" % kind)
			var escape:=InputEventKey.new(); escape.keycode=KEY_ESCAPE; escape.pressed=true
			_input(escape); assert(selected==-1,"Art inspection Escape did not close")
			break
	await capture_icon_scale()
	print("Art pages, equipment inspection and32/64/128px icon review captured")
	get_tree().quit()
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if selected>=0: selected=-1; queue_redraw(); return
		for slot in mini(12,entries.size()-page*12):
			var origin:=Vector2(22+(slot%4)*394,88+floori(slot/4.0)*326)
			if Rect2(origin,Vector2(380,312)).has_point(event.position): selected=page*12+slot; queue_redraw(); return
	if not event is InputEventKey or not event.pressed: return
	if event.keycode==KEY_ESCAPE: selected=-1; queue_redraw(); return
	if event.keycode==KEY_RIGHT: selected=-1; page=mini(page+1,maxi(0,ceili(entries.size()/12.0)-1)); queue_redraw()
	if event.keycode==KEY_LEFT: selected=-1; page=maxi(0,page-1); queue_redraw()
func _draw() -> void:
	if icon_mode: draw_icon_scale(); return
	var font:=ThemeDB.fallback_font
	draw_string(font,Vector2(28,36),"AGE OF THE LOST · ART EXPANSION 02",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("e9d3a2"))
	draw_string(font,Vector2(28,65),"Gear variants · skill / service icons · click item to enlarge · ← / → pages",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("a5afc1"))
	draw_string(font,Vector2(1380,65),"Page %d / %d" % [page+1,ceili(entries.size()/12.0)],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("a5afc1"))
	for slot in mini(12,entries.size()-page*12):
		var record: Dictionary=entries[page*12+slot]; var entry: Dictionary=catalog.entries[int(record.index)-1]
		var status: String=String(record.review_status).replace("_"," ")
		var footer: String=("%d × %d inventory cells" % [int(entry.cells[0]),int(entry.cells[1])]) if entry.kind=="equipment" else "512 px master · UI icon"
		var origin:=Vector2(22+(slot%4)*394,88+floori(slot/4.0)*326)
		draw_rect(Rect2(origin,Vector2(380,312)),Color("151c25")); draw_rect(Rect2(origin,Vector2(380,312)),Color("675a43"),false,1)
		draw_string(font,origin+Vector2(12,26),entry.name,HORIZONTAL_ALIGNMENT_LEFT,356,18,Color("e3ce9e"))
		draw_string(font,origin+Vector2(12,50),"%s · %s" % [entry.group,entry.type],HORIZONTAL_ALIGNMENT_LEFT,356,14,Color("9faabb"))
		var span:=Vector2(float(entry.cells[0]),float(entry.cells[1])); var size:=span*49; var at:=origin+Vector2((380-size.x)/2,66)
		for y in int(span.y):
			for x in int(span.x):
				var rect:=Rect2(at+Vector2(x,y)*49,Vector2(49,49))
				draw_rect(rect,Color("070c12")); draw_rect(rect,Color("5e5749"),false,1)
		draw_texture_rect(textures[record.asset_id],Rect2(at,size),false)
		draw_string(font,origin+Vector2(12,289),footer,HORIZONTAL_ALIGNMENT_LEFT,356,14,Color("a8c39d"))

	if selected>=0: draw_detail()
func draw_detail() -> void:
	var record: Dictionary=entries[selected]
	var entry: Dictionary=catalog.entries[int(record.index)-1]
	var font:=ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO,get_viewport_rect().size),Color(0.02,0.03,0.045,0.97))
	draw_rect(Rect2(220,90,1160,920),Color("151c25"))
	draw_rect(Rect2(220,90,1160,920),Color("a28b5e"),false,2)
	draw_string(font,Vector2(260,140),entry.name,HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("e9d3a2"))
	draw_string(font,Vector2(260,176),("%d × %d inventory cells · art candidate" % [entry.cells[0],entry.cells[1]]) if entry.kind=="equipment" else "512 px UI icon master · art candidate",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("b8c6d6"))
	var span:=Vector2(entry.cells[0],entry.cells[1]); var unit:=160 if entry.kind=="equipment" else 384; var dimensions:=span*unit
	var at:=Vector2((1600-dimensions.x)/2,220+(650-dimensions.y)/2)
	for y in int(span.y):
		for x in int(span.x):
			var rect:=Rect2(at+Vector2(x,y)*unit,Vector2(unit,unit))
			draw_rect(rect,Color("070c12")); draw_rect(rect,Color("5e5749"),false,1)
	draw_texture_rect(textures[record.asset_id],Rect2(at,dimensions),false)
	draw_string(font,Vector2(260,938),entry.asset_id,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("9faabb"))
	draw_string(font,Vector2(260,975),"Click anywhere or press Esc to return",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("b8c6d6"))

var icon_mode:=false
func capture_icon_scale() -> void:
	selected=-1; icon_mode=true; queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://previews/icon_scale.png")
	icon_mode=false
func draw_icon_scale() -> void:
	var font:=ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO,get_viewport_rect().size),Color("0b1018"))
	draw_string(font,Vector2(30,40),"AOTL · ICON READABILITY REVIEW",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("e9d3a2"))
	draw_string(font,Vector2(30,72),"Actual rendered 32 / 64 / 128 pixel versions · skill/service symbols do not occupy inventory cells",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("a5afc1"))
	var icons: Array=[]
	for record in entries:
		var entry: Dictionary=catalog.entries[int(record.index)-1]
		if entry.kind=="ui_icon": icons.append(record)
	for i in mini(30,icons.size()):
		var record: Dictionary=icons[i]; var entry: Dictionary=catalog.entries[int(record.index)-1]
		var origin:=Vector2(20+(i%6)*264,100+floori(i/6.0)*196)
		draw_rect(Rect2(origin,Vector2(252,184)),Color("151c25"))
		draw_string(font,origin+Vector2(8,22),entry.name,HORIZONTAL_ALIGNMENT_LEFT,240,15,Color("e3ce9e"))
		var x:=8.0
		for edge in [32,64,128]:
			var texture: Texture2D=small_textures[String(entry.asset_id)+str(edge)]
			draw_texture_rect(texture,Rect2(origin+Vector2(x,36+(128-edge)/2.0),Vector2(edge,edge)),false)
			x+=edge+6
