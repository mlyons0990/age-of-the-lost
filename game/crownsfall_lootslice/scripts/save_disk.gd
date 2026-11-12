extends RefCounted
## Small disk boundary, replaceable by an in-memory fault adapter in tests.
func exists(path: String) -> bool: return FileAccess.file_exists(path)
func read(path: String) -> Dictionary:
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return {"ok":false,"text":""}
	var content:=file.get_as_text(); var error:=file.get_error(); file.close()
	return {"ok":error in [OK,ERR_FILE_EOF],"text":content}
func write(path: String, content: String) -> bool:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(content); file.flush()
	var ok:=file.get_error()==OK; file.close(); return ok
func copy(source: String, target: String) -> bool:
	return DirAccess.copy_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(target))==OK
func rename(source: String, target: String) -> bool:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(target))==OK
func remove(path: String) -> void:
	if exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
