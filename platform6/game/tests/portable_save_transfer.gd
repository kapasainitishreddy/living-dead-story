extends SceneTree
const CampaignModel = preload("res://core/chapter_model.gd")
const CampaignStore = preload("res://core/save_store.gd")
const JourneyModel = preload("res://core/journey_model.gd")
const JourneyStore = preload("res://core/journey_store.gd")
const PortableStore = preload("res://core/portable_save_store.gd")
class ForcedRollbackFailure:
	extends "res://core/portable_save_store.gd"
	func _restore_records(_states: Dictionary) -> bool: return false
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func write(path: String, value: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return
	file.store_string(value)
	file.flush()
	file.close()
func campaign_profile() -> Dictionary:
	var model = CampaignModel.new()
	var actions = ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore"]
	for action in actions: check(model.apply(action), "campaign checkpoint transition " + action)
	for landmark in ["lighthouse","arch","constellation"]: check(model.apply("inspect_landmark",landmark), "puzzle clue " + landmark)
	check(model.apply("align",2), "solve the discovered puzzle")
	check(model.apply("choose_camera","lend"), "retain camera choice")
	check(model.apply("resolve_action","skipped"), "real-world action can be declined")
	for action in ["return_train","have_breakfast","finish","begin_fair"]: check(model.apply(action), "campaign progression " + action)
	for pair in [["fair_greeting","watch"],["set_race_mode","watch"],["release_boat",null],["inspect_fair","watch"],["level_pond","ada"],["release_boat",null],["fair_departure","wait"],["begin_paper",null],["paper_greeting","begin"],["set_paper_star","empty"],["set_paper_layout","star_boat_leaf"],["set_paper_length","long"],["set_paper_mode","watch"],["set_paper_fold","enough"],["raise_paper",null],["finish_paper",null],["begin_kitchen",null],["kitchen_join","watch"],["kitchen_share","watch"],["kitchen_departure","listen"],["begin_orchard",null],["orchard_route","bench"],["orchard_advance",null],["orchard_advance",null],["orchard_advance",null],["orchard_finish",null],["begin_return",null],["return_arrival",null],["return_farewell","wave"],["return_departure",null],["return_finish",null],["begin_home",null],["home_ticket","drawer"],["home_ritual","neither"],["home_finish","sleep"]]:
		check(model.apply(pair[0],pair[1]), "campaign progression " + pair[0])
	var settings = model.snapshot().settings
	settings.text_scale = 1.5
	settings.reduced_motion = true
	check(model.apply("settings",settings), "owned accessibility settings persist")
	return model.snapshot()
func journey_profile() -> Dictionary:
	var model = JourneyModel.new()
	check(model.apply("board","rain_town"), "board an authored Journey destination")
	check(model.apply("advance") and model.apply("advance"), "Journey scene advances to checkpoint stage two")
	var choices: Array = model.current_destination().get("choice_nodes",[])
	if not choices.is_empty(): check(model.apply("choose",str(choices[0].choice_id)), "authored Journey place choice persists")
	check(model.apply("activity",{"step":2,"selection":4,"progress":240,"done":false}), "Journey activity checkpoint persists")
	check(model.apply("tiny_create",{"id":"portable_note","text":"A sentence I chose to keep","state":"SOMEDAY"}), "optional player-authored local entry persists")
	check(model.apply("echo_create",{"id":"portable_echo","text":"A note for later","due_local":"2026-11-30 10:00","created_local":"2026-10-28 10:00"}), "optional future note persists as authored")
	return model.snapshot()
func raw(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
func run():
	var portable = PortableStore.new()
	var campaign_store = CampaignStore.new()
	var journey_store = JourneyStore.new()
	var archive_path = "user://portable_cold_checkpoint.syrava"
	var profile_suffix = str(Time.get_ticks_usec())
	var campaign_path = "user://portable_atomic_campaign_" + profile_suffix + ".json"
	var journey_path = "user://portable_atomic_journey_" + profile_suffix + ".json"
	var source_campaign = campaign_profile()
	var source_journey = journey_profile()
	check(source_campaign.campaign_complete and source_campaign.home_checkpoint == "complete", "archive has only model-validated earned completion")
	var exported = portable.export_archive(archive_path,source_campaign,source_journey)
	check(exported.ok, "user-invoked archive export writes a bounded validated file")
	var archive = portable.read_archive(archive_path)
	check(archive.ok and archive.data.campaign == source_campaign and archive.data.journey == source_journey, "exported archive roundtrips exact owned data")
	check(not portable.export_archive("/proc/platform6-transfer/fail.syrava",source_campaign,source_journey).ok, "unavailable export path fails cleanly")
	var foreign = archive.data.duplicate(true); foreign.format = "another.game"
	check(not portable.validate_archive(foreign).ok, "foreign application archive rejected")
	var future = archive.data.duplicate(true); future.format_version = 99
	check(not portable.validate_archive(future).ok, "future archive schema rejected")
	var extra = archive.data.duplicate(true); extra["untrusted_reward"] = true
	check(not portable.validate_archive(extra).ok, "unknown archive fields rejected rather than merged")
	var invalid_nested = archive.data.duplicate(true); invalid_nested.campaign.home.ending = "fabricated"
	check(not portable.validate_archive(invalid_nested).ok, "model validation rejects fabricated or inconsistent campaign state")
	var truncated_path = "user://portable_truncated.syrava"
	write(truncated_path,"{\"format\":\"still_here.platform6\",\"format_version\":1,\"campaign\":")
	check(not portable.read_archive(truncated_path).ok, "truncated archive rejected")
	var corrupt_path = "user://portable_corrupt.syrava"
	write(corrupt_path,"not json")
	check(not portable.read_archive(corrupt_path).ok, "corrupt archive rejected")
	var oversized_path = "user://portable_oversized.syrava"
	write(oversized_path,"x".repeat(PortableStore.MAX_ARCHIVE_BYTES + 1))
	check(not portable.read_archive(oversized_path).ok, "oversized archive rejected before parsing")

	# Put a valid existing profile in place, then let a future Journey schema
	# force the second write to fail after campaign replacement has started.
	var old_campaign = CampaignModel.new().snapshot()
	var old_journey = JourneyModel.new().snapshot()
	check(campaign_store.save_snapshot(old_campaign,campaign_path).ok, "write rollback campaign baseline")
	var journey_baseline = journey_store.save_snapshot(old_journey,journey_path)
	check(journey_baseline.ok, "write rollback Journey baseline: " + str(journey_baseline.error))
	var campaign_before = raw(campaign_path)
	var campaign_backup_before = raw(campaign_path + ".bak")
	var journey_before = raw(journey_path)
	var journey_backup_before = raw(journey_path + ".bak")
	var unconfirmed = portable.restore_validated(archive.data,campaign_store,journey_store,campaign_path,journey_path,false)
	check(not unconfirmed.ok and unconfirmed.error.contains("confirmation is required"), "restore API requires the explicit confirmation decision")
	check(raw(campaign_path) == campaign_before and raw(journey_path) == journey_before, "unconfirmed restore leaves both stores byte-for-byte unchanged")
	var future_journey = old_journey.duplicate(true); future_journey.schema_version = JourneyModel.SCHEMA_VERSION + 1
	var future_bytes = JSON.stringify(future_journey)
	write(journey_path,future_bytes)
	var failure = portable.restore_validated(archive.data,campaign_store,journey_store,campaign_path,journey_path,true)
	check(not failure.ok and failure.error.contains("both original saves were restored"), "second-store write failure reports rollback")
	check(raw(campaign_path) == campaign_before and raw(campaign_path + ".bak") == campaign_backup_before, "failed paired restore rolls campaign primary and backup back byte for byte")
	check(raw(journey_path) == future_bytes.to_utf8_buffer() and raw(journey_path + ".bak") == journey_backup_before, "future Journey save is preserved byte for byte")
	write(campaign_path,"{damaged original campaign")
	var damaged_campaign_before = raw(campaign_path)
	var existing_campaign_sidecars = []
	for filename in DirAccess.get_files_at(ProjectSettings.globalize_path(campaign_path.get_base_dir())):
		if filename.begins_with(campaign_path.get_file() + ".damaged."): existing_campaign_sidecars.append(filename)
	var damaged_failure = portable.restore_validated(archive.data,campaign_store,journey_store,campaign_path,journey_path,true)
	check(not damaged_failure.ok and damaged_failure.error.contains("both original saves were restored"), "damaged current save can be restored only transactionally")
	check(raw(campaign_path) == damaged_campaign_before, "failed import restores the exact preexisting damaged campaign bytes")
	var sidecars_after_failure = []
	for filename in DirAccess.get_files_at(ProjectSettings.globalize_path(campaign_path.get_base_dir())):
		if filename.begins_with(campaign_path.get_file() + ".damaged."): sidecars_after_failure.append(filename)
	check(sidecars_after_failure == existing_campaign_sidecars, "failed transaction removes only its newly-created damaged-save sidecar")
	write(campaign_path,"{damaged bytes retained if rollback itself fails")
	var damaged_for_failed_rollback = raw(campaign_path)
	var forced = ForcedRollbackFailure.new()
	var incomplete = forced.restore_validated(archive.data,campaign_store,journey_store,campaign_path,journey_path,true)
	check(not incomplete.ok and incomplete.error.contains("rollback was incomplete"), "failed rollback surfaces explicit recovery status")
	var preserved_sidecar = false
	for filename in DirAccess.get_files_at(ProjectSettings.globalize_path(campaign_path.get_base_dir())):
		if filename.begins_with(campaign_path.get_file() + ".damaged."):
			preserved_sidecar = preserved_sidecar or raw(ProjectSettings.globalize_path(campaign_path.get_base_dir()).path_join(filename)) == damaged_for_failed_rollback
	check(preserved_sidecar, "incomplete rollback retains the only preserved original damaged-save sidecar")
	for filename in DirAccess.get_files_at(ProjectSettings.globalize_path(campaign_path.get_base_dir())):
		if filename.begins_with(campaign_path.get_file() + ".damaged."):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(campaign_path.get_base_dir()).path_join(filename))

	# Build fresh profiles, stage an import in the ordinary UI and cancel it.
	var fresh_campaign_path = "user://portable_ui_campaign.json"
	var fresh_journey_path = "user://portable_ui_journey.json"
	check(campaign_store.save_snapshot(old_campaign,fresh_campaign_path).ok, "seed UI profile campaign")
	check(journey_store.save_snapshot(old_journey,fresh_journey_path).ok, "seed UI profile Journey")
	var campaign_ui_before = raw(fresh_campaign_path)
	var journey_ui_before = raw(fresh_journey_path)
	var game = load("res://main.gd").new()
	game.save_path = fresh_campaign_path
	game.journey_save_path = fresh_journey_path
	root.size = Vector2i(1280,720)
	root.add_child(game)
	await process_frame
	game.handle_portable_file_selected(archive_path)
	check(game.hud.content.get_child_count() > 0 and game.hud.content.get_child(0).text == "Restore this local save?", "valid archive enters an explicit accessible confirmation view")
	check(raw(fresh_campaign_path) == campaign_ui_before and raw(fresh_journey_path) == journey_ui_before, "validation and confirmation do not change either current save")
	game.handle_portable_request("cancel")
	check(raw(fresh_campaign_path) == campaign_ui_before and raw(fresh_journey_path) == journey_ui_before, "cancel leaves both current saves unchanged")
	check(game.hud.content.find_child("PortableSaveStatus",true,false).text.contains("cancelled"), "cancel gives visible status")
	# The pause/reset UI requires an explicit second choice and preserves the archive.
	var reset_before = game.model.snapshot()
	var archive_before = raw(archive_path)
	game.show_pause()
	game.handle_portable_request("reset_prompt")
	check(game.hud.content.get_child(0).text == "Start a new journey?", "new journey opens a separate confirmation")
	game.handle_portable_request("reset_cancel")
	check(game.model.snapshot() == reset_before and raw(archive_path) == archive_before, "cancelled reset preserves current state and exported archive")
	game.show_pause()
	game.handle_portable_request("reset_prompt")
	game.handle_portable_request("reset_confirm")
	check(game.model.snapshot().checkpoint_id == "apartment" and game.model.snapshot().campaign_chapter == "platform_six", "confirmed reset begins at a clean opening checkpoint")
	check(raw(archive_path) == archive_before, "confirmed reset does not delete portable archives")
	var reset_backup_found = false
	for filename in DirAccess.get_files_at(ProjectSettings.globalize_path("user://")):
		if filename.begins_with("portable_ui_campaign.json.reset."): reset_backup_found = true
	check(reset_backup_found, "confirmed reset retains the replaced profile backup")
	game.audio.shutdown()
	game.queue_free()
	await process_frame

	var output: Array = []
	var project_path = ProjectSettings.globalize_path("res://")
	var exit_code = OS.execute(OS.get_executable_path(),["--headless","--path",project_path,"--script","res://tests/portable_cold_restore.gd"],output,true,false)
	check(exit_code == 0 and str(output).contains("Portable cold restore: 0 failures"), "separate cold process restores and resumes exact campaign and Journey state: " + str(output))
	print("Portable save transfer: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
