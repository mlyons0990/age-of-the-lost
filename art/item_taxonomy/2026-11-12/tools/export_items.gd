extends SceneTree
## Technical atlas extraction/normalization only. Original generated pixels remain
## in generated_sources; no repainting, matting or semantic repair is performed.
func _initialize() -> void:
	var root:=ProjectSettings.globalize_path("res://")
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(root+"catalog.json"))
	var mappings: Array=JSON.parse_string(FileAccess.get_file_as_string(root+"asset_sources.json"))
	var report: Array=[]
	for mapping in mappings:
		var entry: Dictionary=catalog.entries[int(mapping.index)-1]
		var image:=Image.load_from_file(root+mapping.path)
		if image==null: continue
		image.convert(Image.FORMAT_RGBA8)
		var region:=Rect2i(0,0,image.get_width(),image.get_height())
		if mapping.has("tile"):
			var col:=int(mapping.tile)%3
			var row:=int(mapping.tile)/3
			var start:=Vector2i(col*image.get_width()/3,row*image.get_height()/2)
			var finish:=Vector2i((col+1)*image.get_width()/3,(row+1)*image.get_height()/2)
			region=Rect2i(start,finish-start)
		if mapping.has("region"):
			var r: Array=mapping.region
			region=Rect2i(int(r[0]),int(r[1]),int(r[2]),int(r[3]))
		var source:=image.get_region(region)
		var used:=visible_bounds(source)
		if used.size.x<8 or used.size.y<8: continue
		var cropped:=source.get_region(used)
		var target:=Vector2i(int(entry.cells[0])*128,int(entry.cells[1])*128)
		var available:=Vector2(target)-Vector2(16,16)
		var factor:=minf(available.x/cropped.get_width(),available.y/cropped.get_height())
		cropped.resize(maxi(1,roundi(cropped.get_width()*factor)),maxi(1,roundi(cropped.get_height()*factor)),Image.INTERPOLATE_LANCZOS)
		var result:=Image.create(target.x,target.y,false,Image.FORMAT_RGBA8); result.fill(Color.TRANSPARENT)
		result.blit_rect(cropped,Rect2i(Vector2i.ZERO,cropped.get_size()),(target-cropped.get_size())/2)
		var output: String="runtime_items/"+String(entry.asset_id)+".png"
		result.save_png(root+output)
		report.append({"index":entry.index,"asset_id":entry.asset_id,"cells":entry.cells,"pixels":[target.x,target.y],"source":mapping.path,"source_region":[region.position.x,region.position.y,region.size.x,region.size.y],"used_region":[used.position.x,used.position.y,used.size.x,used.size.y],"output":output,"review_status":mapping.get("review_status","pending_visual_review")})
	var file:=FileAccess.open(root+"EXPORT_REPORT.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"  ")); file.close()
	print("Exported ",report.size()," footprint-normalized image candidates")
	quit()

# Ignore near-invisible encoder alpha noise only when measuring bounds.
# Source and exported pixel alpha are never thresholded or repainted.
func visible_bounds(image: Image) -> Rect2i:
	var lo:=Vector2i(image.get_width(),image.get_height())
	var hi:=Vector2i(-1,-1)
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x,y).a>=8.0/255.0:
				lo=Vector2i(mini(lo.x,x),mini(lo.y,y))
				hi=Vector2i(maxi(hi.x,x),maxi(hi.y,y))
	if hi.x<0: return Rect2i()
	lo=Vector2i(maxi(0,lo.x-2),maxi(0,lo.y-2))
	hi=Vector2i(mini(image.get_width()-1,hi.x+2),mini(image.get_height()-1,hi.y+2))
	return Rect2i(lo,hi-lo+Vector2i.ONE)
