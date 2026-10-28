extends SceneTree
const CampaignStore = preload("res://core/save_store.gd")
const JourneyModel = preload("res://core/journey_model.gd")
const JourneyStore = preload("res://core/journey_store.gd")
const PortableStore = preload("res://core/portable_save_store.gd")
var failures := 0
func _initialize(): call_deferred("run")
func run():
	var portable = PortableStore.new()
	var profile_suffix = str(Time.get_ticks_usec())
	var campaign_path = "user://portable_cold_campaign_" + profile_suffix + ".json"
	var journey_path = "user://portable_cold_journey_" + profile_suffix + ".json"
	var archive_path = "user://portable_cold_checkpoint.syrava"
	var campaign_store = CampaignStore.new()
	var journey_store = JourneyStore.new()
	var loaded_archive = portable.read_archive(archive_path)
	check(loaded_archive.ok, "fresh process reads complete exported archive")
	var fresh_campaign = load("res://core/chapter_model.gd").new()
	var fresh_journey = load("res://core/journey_model.gd").new()
	check(campaign_store.save_snapshot(fresh_campaign.snapshot(), campaign_path).ok, "fresh profile starts with a separate campaign file")
	check(journey_store.save_snapshot(fresh_journey.snapshot(), journey_path).ok, "fresh profile starts with a separate Journey file")
	if loaded_archive.ok:
		var imported = portable.restore_validated(loaded_archive.data, campaign_store, journey_store, campaign_path, journey_path, true)
		check(imported.ok, "validated archive writes both stores in fresh process")
		var campaign_after = campaign_store.load_snapshot(campaign_path)
		var journey_after = journey_store.load_snapshot(journey_path)
		check(campaign_after.ok and campaign_after.data == loaded_archive.data.campaign, "campaign checkpoint, choices, puzzle and settings match byte-independent snapshot")
		check(journey_after.ok and journey_after.data == loaded_archive.data.journey, "Journey progress and authored records match exactly")
		var saved_campaign = load("res://core/chapter_model.gd").new()
		var saved_journey = load("res://core/journey_model.gd").new()
		check(saved_campaign.restore(campaign_after.data) and saved_campaign.snapshot().campaign_chapter == "still_here" and saved_campaign.snapshot().home_checkpoint == "complete", "cold-start campaign resumes its saved chapter")
		check(campaign_after.data.chapter_complete and campaign_after.data.puzzle_solved and campaign_after.data.camera_choice == "lend" and campaign_after.data.action_resolution == "skipped" and campaign_after.data.settings.reduced_motion, "cold-start campaign keeps puzzle, player choices, optional decline and settings exactly")
		check(saved_journey.restore(journey_after.data) and saved_journey.snapshot().mode == "destination" and saved_journey.snapshot().journey_id == "rain_town" and saved_journey.snapshot().stage == 2, "cold-start Journey resumes its exact place and stage")
		var time_advanced = JourneyModel.new()
		check(time_advanced.restore(journey_after.data), "fresh state accepts the saved Journey before simulated absence")
		var before_absence = time_advanced.snapshot()
		check(time_advanced.apply("resolve_echoes","2026-11-27 10:00"), "advance the local simulated date by thirty days")
		var after_absence = time_advanced.snapshot()
		check(after_absence.visits == before_absence.visits and after_absence.location_states == before_absence.location_states and after_absence.resumable == before_absence.resumable and after_absence.stage == before_absence.stage and after_absence.tiny_tomorrows == before_absence.tiny_tomorrows and after_absence.future_echoes == before_absence.future_echoes, "thirty-day absence leaves story and optional notes unchanged before their chosen future date")
		check(not loaded_archive.data.campaign.has("last_seen") and not loaded_archive.data.journey.has("last_seen"), "portable archive stores no absence clock or decay timestamp")
	finish()
func check(ok: bool, label: String):
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func finish():
	print("Portable cold restore: %d failures" % failures)
	quit(1 if failures else 0)
