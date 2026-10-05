extends RefCounted
# This store owns only the Journey file. Campaign data is never read or written.
const Model = preload("res://core/journey_model.gd")
const DEFAULT_PATH := "user://still_here/journey_v1.json"
const CAMPAIGN_PATH := "user://still_here/save_v1.json"
const MAX_FILE_BYTES := 1048576
var pack_path: String
func _init(content_path: String = Model.DEFAULT_PACK_PATH):
	pack_path = content_path
func result(ok: bool, data: Dictionary = {}, error: String = "", recovered: bool = false) -> Dictionary:
	return {"ok":ok,"data":data,"error":error,"recovered":recovered}
func _campaign_path(path: String) -> bool:
	var absolute = ProjectSettings.globalize_path(path).simplify_path()
	var campaign = ProjectSettings.globalize_path(CAMPAIGN_PATH).simplify_path()
	return absolute == campaign or absolute.begins_with(campaign + ".")
func read_file(path: String = DEFAULT_PATH) -> Dictionary:
	if _campaign_path(path): return result(false,{},"Campaign path reserved")
	if not FileAccess.file_exists(path): return result(false,{},"missing")
	var file = FileAccess.open(path,FileAccess.READ)
	if file == null: return result(false,{},"unreadable")
	if file.get_length() > MAX_FILE_BYTES: return result(false,{},"oversized")
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK or typeof(parser.data) != TYPE_DICTIONARY: return result(false,{},"damaged")
	var parsed: Dictionary = parser.data
	var version: Variant = parsed.get("schema_version")
	if typeof(version) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(version) or version != floor(version): return result(false,{},"invalid schema type")
	if version > Model.SCHEMA_VERSION: return result(false,{},"future schema")
	var model = Model.new(pack_path)
	if not model.restore(parsed): return result(false,{},"invalid snapshot")
	return result(true,model.snapshot())
func load_snapshot(path: String = DEFAULT_PATH) -> Dictionary:
	var primary = read_file(path)
	if primary.ok or primary.error == "future schema": return primary
	var backup = read_file(path + ".bak")
	if backup.ok: return result(true,backup.data,"Recovered backup; damaged primary retained",true)
	if backup.error == "future schema": return backup
	return primary
func save_snapshot(value: Variant, path: String = DEFAULT_PATH) -> Dictionary:
	if _campaign_path(path): return result(false,{},"Campaign path reserved")
	var model = Model.new(pack_path)
	if not model.restore(value): return result(false,{},"invalid snapshot")
	var normalized = model.snapshot()
	var old = read_file(path)
	if old.error == "future schema": return result(false,{},"future schema preserved")
	if old.error == "oversized": return result(false,{},"Oversized Journey primary preserved")
	var old_backup = read_file(path + ".bak")
	if old_backup.error == "future schema": return result(false,{},"future backup schema preserved")
	if old_backup.error == "oversized": return result(false,{},"Oversized Journey backup preserved")
	var directory = path.get_base_dir()
	if directory.begins_with("/proc/"): return result(false,{},"Cannot write Journey save")
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return result(false,{},"Cannot create Journey save directory")
	var temporary = path + ".tmp"
	var file = FileAccess.open(temporary,FileAccess.WRITE)
	if file == null: return result(false,{},"Cannot write Journey save")
	file.store_string(JSON.stringify(normalized))
	file.flush()
	file.close()
	var verification = read_file(temporary)
	if not verification.ok or verification.data != normalized: return result(false,{},"Journey snapshot verification failed")
	if FileAccess.file_exists(path):
		var preserved = path + (".bak" if old.ok else ".damaged." + str(Time.get_ticks_usec()))
		if DirAccess.copy_absolute(path,preserved) != OK: return result(false,{},"Cannot preserve previous Journey save")
		if FileAccess.get_file_as_bytes(preserved) != FileAccess.get_file_as_bytes(path): return result(false,{},"Journey backup verification failed")
	if DirAccess.rename_absolute(temporary,path) != OK: return result(false,{},"Cannot replace Journey save")
	return result(true,normalized)
func reset_snapshot(path: String = DEFAULT_PATH) -> Dictionary:
	if _campaign_path(path): return result(false,{},"Campaign path reserved")
	var old = read_file(path)
	var old_backup = read_file(path + ".bak")
	if old.error == "future schema": return result(false,{},"Future schema preserved; choose a different Journey save location")
	if old_backup.error == "future schema": return result(false,{},"Future backup schema preserved; choose a different Journey save location")
	if old.error == "oversized" or old_backup.error == "oversized": return result(false,{},"Oversized Journey save preserved")
	if FileAccess.file_exists(path):
		var backup = path + ".reset." + str(Time.get_ticks_usec()) + ".json"
		if DirAccess.copy_absolute(path,backup) != OK: return result(false,{},"Cannot retain Journey reset backup")
		if FileAccess.get_file_as_bytes(backup) != FileAccess.get_file_as_bytes(path): return result(false,{},"Journey reset backup verification failed")
	return save_snapshot(Model.new(pack_path).snapshot(),path)
