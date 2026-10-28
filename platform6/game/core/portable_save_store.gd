extends RefCounted
## Explicit, offline transfer for the two state files owned by the game.
## Imports are validated completely before either local store is changed.
const CampaignModel = preload("res://core/chapter_model.gd")
const JourneyModel = preload("res://core/journey_model.gd")
const JourneyStore = preload("res://core/journey_store.gd")
const MAX_ARCHIVE_BYTES := 2097152
const FORMAT_ID := "still_here.platform6"
const FORMAT_VERSION := 1

func result(ok: bool, data: Dictionary = {}, error: String = "") -> Dictionary:
	return {"ok":ok,"data":data,"error":error}

func _safe_path(path: String) -> bool:
	if path.is_empty() or path.begins_with("res://") or path.begins_with("uid://"):
		return false
	var absolute = ProjectSettings.globalize_path(path).simplify_path()
	if absolute.begins_with("/proc/") or absolute.begins_with("/sys/") or absolute.begins_with("/dev/"):
		return false
	if not path.get_extension().to_lower() in ["syrava", "json"]:
		return false
	return true

func build_archive(campaign: Dictionary, journey: Dictionary) -> Dictionary:
	var campaign_model = CampaignModel.new()
	if not campaign_model.restore(campaign): return result(false, {}, "Campaign save is invalid")
	var journey_model = JourneyModel.new()
	if not journey_model.restore(journey): return result(false, {}, "Journey save is invalid")
	var archive = {"format":FORMAT_ID,"format_version":FORMAT_VERSION,"campaign":campaign_model.snapshot(),"journey":journey_model.snapshot()}
	var encoded = JSON.stringify(archive)
	if encoded.to_utf8_buffer().size() > MAX_ARCHIVE_BYTES: return result(false, {}, "Save archive is too large")
	return result(true, archive)

func validate_archive(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY: return result(false, {}, "This file is not a Platform 6 save archive")
	var archive: Dictionary = value
	var required = ["format", "format_version", "campaign", "journey"]
	if archive.size() != required.size(): return result(false, {}, "This file has an unsupported or foreign save format")
	for key in required:
		if not archive.has(key): return result(false, {}, "This save archive is incomplete")
	if typeof(archive.format) != TYPE_STRING or archive.format != FORMAT_ID:
		return result(false, {}, "This file belongs to a different game or save format")
	if typeof(archive.format_version) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(archive.format_version) or archive.format_version != FORMAT_VERSION:
		return result(false, {}, "This save archive version is not supported")
	return build_archive(archive.campaign, archive.journey)

func read_archive(path: String) -> Dictionary:
	if not _safe_path(path): return result(false, {}, "Choose a regular save archive file")
	if not FileAccess.file_exists(path): return result(false, {}, "Save archive not found")
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null: return result(false, {}, "Cannot read this save archive")
	if file.get_length() <= 0 or file.get_length() > MAX_ARCHIVE_BYTES:
		file.close()
		return result(false, {}, "Save archive is empty or too large")
	var parser = JSON.new()
	var parse_error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK: return result(false, {}, "Save archive is damaged or truncated")
	return validate_archive(parser.data)

func export_archive(path: String, campaign: Dictionary, journey: Dictionary) -> Dictionary:
	if not _safe_path(path): return result(false, {}, "Choose a writable .syrava or .json file")
	var archive = build_archive(campaign, journey)
	if not archive.ok: return archive
	var directory = path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK:
		return result(false, {}, "Cannot create the selected save folder")
	var temporary = path + ".tmp.syrava"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return result(false, {}, "Cannot write the selected save file")
	file.store_string(JSON.stringify(archive.data))
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return result(false, {}, "Save archive could not be written completely")
	var verified = read_archive(temporary)
	if not verified.ok:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return result(false, {}, "Written save archive did not pass validation")
	var previous = path + ".previous." + str(Time.get_ticks_usec()) + ".syrava"
	var had_previous = FileAccess.file_exists(path)
	if had_previous:
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(previous)) != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
			return result(false, {}, "Cannot preserve the previous selected save file")
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) != OK:
		if had_previous: DirAccess.rename_absolute(ProjectSettings.globalize_path(previous), ProjectSettings.globalize_path(path))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return result(false, {}, "Cannot finish writing the selected save file")
	if had_previous: DirAccess.remove_absolute(ProjectSettings.globalize_path(previous))
	return result(true, {"path":path})

func _file_state(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false,"bytes":PackedByteArray()}
	return {"exists":true,"bytes":FileAccess.get_file_as_bytes(path)}

func _restore_file_state(path: String, state: Dictionary) -> bool:
	if not state.exists:
		if FileAccess.file_exists(path): return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
		return true
	var temporary = path + ".rollback.tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return false
	file.store_buffer(state.bytes)
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK: return false
	if FileAccess.file_exists(path) and DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK: return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK

func _restore_records(states: Dictionary) -> bool:
	var success = true
	for path in states:
		if not _restore_file_state(path, states[path]): success = false
	return success

func _collect_transaction_paths(campaign_path: String, journey_path: String) -> Array:
	var paths = [campaign_path, campaign_path + ".bak", campaign_path + ".v1.bak", campaign_path + ".tmp", campaign_path + ".rollback.tmp", journey_path, journey_path + ".bak", journey_path + ".tmp", journey_path + ".rollback.tmp"]
	for save_path in [campaign_path, journey_path]:
		var directory = ProjectSettings.globalize_path(save_path.get_base_dir())
		var prefix = save_path.get_file()
		for filename in DirAccess.get_files_at(directory):
			if filename.begins_with(prefix + ".damaged.") or filename.begins_with(prefix + ".reset."):
				paths.append(directory.path_join(filename))
	return paths

func _remove_new_sidecars(campaign_path: String, journey_path: String, prior_paths: Dictionary) -> bool:
	var success = true
	for save_path in [campaign_path, journey_path]:
		var directory = ProjectSettings.globalize_path(save_path.get_base_dir())
		var prefix = save_path.get_file()
		for filename in DirAccess.get_files_at(directory):
			if (filename.begins_with(prefix + ".damaged.") or filename.begins_with(prefix + ".reset.")):
				var path = directory.path_join(filename)
				if not prior_paths.has(path) and DirAccess.remove_absolute(path) != OK: success = false
	return success

## Stores are injectable for deterministic rollback tests. Production callers use
## the actual campaign and Journey stores and pass snapshots already validated above.
func restore_validated(archive: Dictionary, campaign_store: Object, journey_store: Object, campaign_path: String, journey_path: String, confirmation_received: bool) -> Dictionary:
	if not confirmation_received: return result(false, {}, "Explicit restore confirmation is required")
	var validation = validate_archive(archive)
	if not validation.ok: return validation
	if not _safe_path(campaign_path) or not _safe_path(journey_path):
		return result(false, {}, "Local save path is unavailable")
	var paths = _collect_transaction_paths(campaign_path, journey_path)
	var before = {}
	for path in paths: before[path] = _file_state(path)
	var campaign_result = campaign_store.save_snapshot(validation.data.campaign, campaign_path)
	if not campaign_result.ok:
		var campaign_rolled_back = _restore_records(before)
		var campaign_sidecars_clean = _remove_new_sidecars(campaign_path, journey_path, before) if campaign_rolled_back else false
		if campaign_rolled_back and campaign_sidecars_clean: return result(false, {}, "Campaign restore failed; original saves were restored: " + str(campaign_result.error))
		return result(false, {}, "Campaign restore failed and automatic rollback was incomplete. Keep this window open and do not reset: " + str(campaign_result.error))
	var journey_result = journey_store.save_snapshot(validation.data.journey, journey_path)
	if not journey_result.ok:
		var journey_rolled_back = _restore_records(before)
		var journey_sidecars_clean = _remove_new_sidecars(campaign_path, journey_path, before) if journey_rolled_back else false
		if journey_rolled_back and journey_sidecars_clean: return result(false, {}, "Journey restore failed; both original saves were restored: " + str(journey_result.error))
		return result(false, {}, "Journey restore failed and automatic rollback was incomplete. Keep this window open and do not reset: " + str(journey_result.error))
	return result(true, validation.data)
