extends RefCounted
## Primary rename is the commit point. A backup publication warning after that
## point is success: callers must apply the already-durable transaction once.
var disk=preload("res://scripts/save_disk.gd").new()
func failure(reason: String, protected := false) -> Dictionary:
	return {"ok":false,"reason":reason,"protected":protected,"warning":""}
func commit(path: String, data: Dictionary, validate: Callable, schema: int) -> Dictionary:
	var temp:=path+".tmp"; var backup:=path+".bak.pending"
	disk.remove(temp); disk.remove(backup)
	for version in range(5,schema+1): disk.remove(path+".pre-v%d.pending" % version)
	if not validate.call(data): return failure("Progress could not be saved. The proposed state is invalid.")
	var had_primary: bool=disk.exists(path)
	if had_primary:
		var current: Dictionary=disk.read(path)
		if not current.ok: return failure("Progress could not be read. Check storage and retry.")
		var parser:=JSON.new()
		var prior: Variant=parser.data if parser.parse(current.text)==OK else null
		if prior is Dictionary and (prior.get("schema") is float or prior.get("schema") is int) and prior.schema>schema:
			return failure("A newer save was found. Reopen with the compatible version; this session cannot overwrite it.",true)
		if not prior is Dictionary or not validate.call(prior):
			return failure("The saved record changed or is unreadable. Reopen to recover it; this session cannot overwrite it.",true)
		for version in range(5,schema+1):
			var preserved:=path+".pre-v%d" % version
			if int(prior.schema)>=version or disk.exists(preserved): continue
			var staged:=preserved+".pending"
			if not disk.copy(path,staged) or not _same(staged,current.text) or not disk.rename(staged,preserved):
				disk.remove(staged); return failure("The previous version could not be preserved. Check storage and retry.")

	var content:=JSON.stringify(data,"  ")
	if not disk.write(temp,content) or not _same(temp,content):
		disk.remove(temp); return failure("Progress could not be written and verified. Check storage and retry.")
	if had_primary:
		var current: Dictionary=disk.read(path)
		if not current.ok or not disk.copy(path,backup) or not _same(backup,current.text):
			disk.remove(temp); disk.remove(backup); return failure("The recovery copy could not be prepared. Check storage and retry.")
	if not disk.rename(temp,path):
		disk.remove(temp); disk.remove(backup); return failure("Progress could not be committed. Check storage and retry.")
	var warning:=""
	if had_primary and not disk.rename(backup,path+".bak"):
		warning="Progress saved. The recovery copy could not be refreshed; check storage."
		disk.remove(backup)
	return {"ok":true,"reason":"Progress saved.","protected":false,"warning":warning}
func _same(path: String, content: String) -> bool:
	var result: Dictionary=disk.read(path)
	return result.ok and result.text==content
