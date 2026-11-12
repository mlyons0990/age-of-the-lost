extends SceneTree
func _initialize() -> void:
	var profile: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/selected_art_profile.json"))
	var library:=ProjectSettings.globalize_path("res://../../art/expansion02/2026-11-12")
	var args:=OS.get_cmdline_user_args()
	for i in maxi(0,args.size()-1):
		if args[i]=="--library": library=args[i+1]
	if not DirAccess.dir_exists_absolute(library):
		push_error("Supply the Expansion02 library with -- --library /path/to/library"); quit(1); return
	for entry in profile.selections:
		if entry.kind!="equipment": continue
		var source: String=library.path_join(String(entry.source_path))
		if FileAccess.get_sha256(source)!=String(entry.source_sha256):
			push_error("Missing or changed accepted source: "+source); quit(1); return
		var image:=Image.load_from_file(source)
		if image==null or image.is_empty():
			push_error("Could not decode portrait: "+source); quit(1); return
		image.resize(int(entry.cells[0])*64,int(entry.cells[1])*64,Image.INTERPOLATE_LANCZOS)
		var destination: String="res://"+String(entry.runtime_path)
		if image.save_png(destination)!=OK or FileAccess.get_sha256(destination)!=String(entry.runtime_sha256):
			push_error("Portrait output did not match accepted bytes: "+destination); quit(1); return
	print("Imported 12 selected portraits at 64 pixels per inventory cell; source/output hashes match")
	quit()
