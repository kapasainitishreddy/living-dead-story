extends RefCounted
const Model = preload("res://core/chapter_model.gd")
func result(ok: bool, data: Dictionary = {}, error: String = "", recovered: bool = false, migrated: bool = false) -> Dictionary:
	return {"ok":ok,"data":data,"error":error,"recovered":recovered,"migrated":migrated}
func read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return result(false, {}, "missing")
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null: return result(false, {}, "unreadable")
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK: return result(false, {}, "damaged")
	var parsed = parser.data
	if typeof(parsed) != TYPE_DICTIONARY: return result(false, {}, "damaged")
	if typeof(parsed.get("schema_version")) not in [TYPE_INT,TYPE_FLOAT]: return result(false, {}, "invalid schema type")
	if parsed.get("schema_version",0) > Model.SCHEMA_VERSION: return result(false, {}, "future schema")
	var model = Model.new()
	if not model.restore(parsed): return result(false, {}, "invalid snapshot")
	return result(true, model.snapshot(), "", false, parsed.schema_version == 1)
func load_snapshot(path: String) -> Dictionary:
	var primary = read_file(path)
	if primary.ok or primary.error == "future schema": return primary
	var backup = read_file(path + ".bak")
	if backup.ok: return result(true, backup.data, "Recovered backup; damaged primary retained", true, backup.migrated)
	if backup.error == "future schema": return backup
	return primary
func save_snapshot(data: Dictionary, path: String) -> Dictionary:
	var model = Model.new()
	if not model.restore(data): return result(false, {}, "invalid snapshot")
	var normalized = model.snapshot()
	var old = read_file(path)
	if old.error == "future schema": return result(false, {}, "future schema preserved")
	var old_backup = read_file(path + ".bak")
	if old_backup.error == "future schema": return result(false, {}, "future backup schema preserved")
	var directory = path.get_base_dir()
	if directory.begins_with("/proc/"): return result(false, {}, "Cannot write save")
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return result(false, {}, "Cannot create save directory")
	var temporary = path + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return result(false, {}, "Cannot write save")
	file.store_string(JSON.stringify(normalized))
	file.flush()
	file.close()
	if not read_file(temporary).ok: return result(false, {}, "Snapshot verification failed")
	var legacy_source = path if old.ok and old.migrated else (path + ".bak" if old_backup.ok and old_backup.migrated else "")
	if not legacy_source.is_empty() and not FileAccess.file_exists(path + ".v1.bak"):
		# Preserve the actual v1 source, including a recovered rotating backup.
		var versioned_backup = path + ".v1.bak"
		if DirAccess.copy_absolute(legacy_source, versioned_backup) != OK: return result(false, {}, "Cannot preserve version 1 save")
		if FileAccess.get_file_as_bytes(versioned_backup) != FileAccess.get_file_as_bytes(legacy_source) or not read_file(versioned_backup).ok: return result(false, {}, "Version 1 backup verification failed")
	if FileAccess.file_exists(path):
		var preserved = path + (".bak" if old.ok else ".damaged." + str(Time.get_ticks_usec()))
		if DirAccess.copy_absolute(path, preserved) != OK: return result(false, {}, "Cannot preserve previous save")
	if DirAccess.rename_absolute(temporary, path) != OK: return result(false, {}, "Cannot replace save")
	return result(true, normalized)
func reset_snapshot(path: String) -> Dictionary:
	var old = read_file(path)
	if old.error == "future schema": return result(false, {}, "Future schema preserved; choose a different save location")
	if read_file(path + ".bak").error == "future schema": return result(false, {}, "Future backup schema preserved; choose a different save location")
	if FileAccess.file_exists(path):
		var backup = path + ".reset." + str(Time.get_unix_time_from_system()) + ".json"
		if DirAccess.copy_absolute(path,backup) != OK: return result(false, {}, "Cannot retain reset backup")
	return save_snapshot(Model.new().snapshot(),path)
