extends SceneTree
const Model = preload("res://core/chapter_model.gd")
const Store = preload("res://core/save_store.gd")
const LEGACY_KEYS = ["schema_version","chapter_id","checkpoint_id","inspected_landmark_ids","overlook_alignment","puzzle_solved","camera_choice","action_resolution","souvenir_ids","chapter_world_flag","chapter_complete","settings"]
const DIMENSIONS = ["joy","calm","connection","wonder","agency","energy","future_pull","meaning"]
var checks := 0
var failures := 0
func check(condition: bool, label: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
func complete_chapter(camera: String = "take", resolution: String = "skipped"):
	var m = Model.new()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]: check(m.apply(action), "chapter setup " + action)
	check(m.apply("choose_camera", camera), "chapter camera " + camera)
	check(m.apply("resolve_action", resolution), "chapter optional " + resolution)
	for action in ["return_train","have_breakfast","finish"]: check(m.apply(action), "chapter ending " + action)
	return m
func legacy_snapshot(source: Dictionary) -> Dictionary:
	var old = {}
	for key in LEGACY_KEYS: old[key] = source[key]
	old.schema_version = 1
	return old.duplicate(true)
func fair_to_result(mode: String = "operate", rudder: String = "straight", sail: String = "triangle"):
	var m = complete_chapter()
	check(m.apply("begin_fair"), "fair unlock")
	check(m.apply("fair_greeting", "ducks"), "fair greeting")
	check(m.apply("set_race_mode", mode), "explicit race mode")
	check(m.apply("set_rudder", rudder), "explicit rudder")
	check(m.apply("set_sail", sail), "explicit sail")
	check(m.apply("release_boat"), "first crooked race")
	check(m.apply("inspect_fair", "watch"), "NPC reveals wedge to watcher")
	check(m.apply("level_pond", "ada"), "Ada can level pond")
	check(m.apply("release_boat"), "canonical second race")
	return m
func _initialize():
	var initial = Model.new().snapshot()
	check(initial.schema_version == 2, "new saves use schema 2")
	check(initial.has("fair") and initial.has("dimensions") and initial.has("npc_state") and initial.has("choice_history"), "new saves carry neutral consequence and fair state")
	check(not Model.new().apply("begin_fair"), "fair cannot bypass chapter one")
	if not initial.has("fair"):
		print("Fair model checks: %d; failures: %d" % [checks, failures])
		quit(1)
		return
	check(Model.STATES.size() == 12, "all twelve legacy checkpoints retained")
	for dimension in DIMENSIONS: check(initial.dimensions[dimension] == 0, "neutral fictional " + dimension)
	check(initial.fair_checkpoint == "locked" and initial.campaign_chapter == "platform_six", "fair begins locked")
	check(initial.fair.rudder == "straight" and initial.fair.sail == "triangle", "safe configuration defaults")
	check(initial.fair.get("souvenir_ids", ["missing"]) == [], "no fair souvenir before canonical race")
	for premature in ["platform_six.camera.lend","platform_six.optional.continue","platform_six.finish","the_small_fair.begin","the_small_fair.greeting.watch","the_small_fair.race.canonical","the_small_fair.departure.wait"]:
		var forged = initial.duplicate(true); forged.choice_history.append(premature)
		check(not Model.new().restore(forged), "reject premature action history " + premature)
	var local = Model.new(); local.apply("leave_apartment")
	check(local.record_choice("platform_six.dialogue.umbrella_question"), "authored local narrative choice persists")
	var local_recorded = local.snapshot()
	check(not local.record_choice("platform_six.dialogue.umbrella_question"), "local narrative choice idempotent")
	check(local.snapshot() == local_recorded and local.valid(local.snapshot()), "local narrative record keeps valid detached state")
	var done = complete_chapter("lend", "completed").snapshot()
	var skipped = complete_chapter("lend", "skipped").snapshot()
	for key in ["dimensions","npc_state","choice_history","souvenir_ids","chapter_complete","chapter_world_flag","fair"]: check(done[key] == skipped[key], "Done and Not tonight equivalent durable " + key)
	for checkpoint in Model.STATES:
		var old_model = Model.new()
		while old_model.snapshot().checkpoint_id != checkpoint:
			var at = old_model.snapshot().checkpoint_id
			var action = {"apartment":"leave_apartment","roof":"meet_stranger","platform":"read_board","conductor":"board_train","passenger":"meet_passenger","shoreline":"arrive_shore","overlook":"assist","camera_choice":"choose_camera","optional_action":"resolve_action","return_train":"return_train","breakfast":"have_breakfast"}[at]
			old_model.apply(action,"lend" if action == "choose_camera" else ("completed" if action == "resolve_action" else null))
		var old = legacy_snapshot(old_model.snapshot())
		old.settings.text_scale = 2.0
		old.settings.reduced_motion = true
		var migrated = Model.new()
		check(migrated.restore(old), "migrate legacy " + checkpoint)
		var state = migrated.snapshot()
		check(state.schema_version == 2 and state.checkpoint_id == checkpoint, "migration retains checkpoint " + checkpoint)
		for key in LEGACY_KEYS:
			if key != "schema_version": check(state[key] == old[key], "migration preserves " + checkpoint + " " + key)
		for dimension in DIMENSIONS: check(state.dimensions[dimension] == 0, "migration never invents past " + dimension)
		check(state.npc_state.mira.connection == 0 and not state.npc_state.mira.independent_decision, "migration leaves unknown relationship neutral")
		check(state.npc_state.mira.camera_memory == old.camera_choice, "migration only remembers explicit camera callback")
		check(state.choice_history.size() == (0 if old.camera_choice == "unselected" else 1), "migration only records known camera choice")
	var stage = complete_chapter()
	var legacy_before = legacy_snapshot(stage.snapshot())
	check(stage.apply("begin_fair"), "begin fair")
	check(not stage.apply("begin_fair"), "begin duplicate safe")
	check(stage.snapshot().fair_checkpoint == "arrival", "arrival checkpoint")
	check(not stage.apply("release_boat"), "cannot race before greeting")
	check(not stage.apply("fair_greeting", "wrong"), "invalid greeting safe")
	check(stage.apply("fair_greeting", "how"), "greeting reaches workshop")
	check(stage.snapshot().fair_checkpoint == "workshop", "workshop checkpoint")
	check(not stage.apply("level_pond", "self"), "cannot level before observing race")
	var before_unknown = stage.snapshot()
	check(not stage.record_choice("unknown.choice"), "unknown persistent choice rejected")
	check(stage.snapshot() == before_unknown, "unknown choice has no mutation")
	check(not stage.record_choice("platform_six.camera.take"), "wrong-checkpoint persistent choice rejected")
	check(stage.snapshot() == before_unknown, "wrong-context choice has no mutation")
	check(stage.apply("set_rudder", "straight"), "explicit default rudder accepted once")
	check(not stage.apply("set_rudder", "sideways"), "invalid rudder rejected")
	check(not stage.apply("set_rudder", "straight"), "repeated configuration idempotent")
	check(stage.apply("set_rudder", "left"), "physical configuration reversible first choice")
	check(stage.apply("set_rudder", "right"), "physical configuration reversible second choice")
	var before_reselect = stage.snapshot()
	check(stage.apply("set_rudder", "left"), "previously chosen configuration remains selectable")
	check(stage.snapshot().choice_history == before_reselect.choice_history and stage.snapshot().dimensions == before_reselect.dimensions, "reselection never farms consequences")
	check(stage.apply("set_rudder", "straight"), "default configuration reselected")
	check(stage.apply("release_boat"), "first race release")
	check(stage.snapshot().fair_checkpoint == "crooked_race" and stage.snapshot().fair.race_count == 1, "crooked race persisted")
	check(not stage.apply("release_boat"), "repeated first release safe")
	check(stage.apply("inspect_fair", "boat"), "boat inspected")
	check(stage.apply("inspect_fair", "watch"), "watch inspection")
	check(stage.snapshot().fair.inspected.has("wedge"), "watcher gets autonomous NPC wedge reveal")
	check(not stage.apply("inspect_fair", "watch"), "duplicate inspection safe")
	check(stage.apply("level_pond", "self"), "self levels pond")
	check(stage.snapshot().fair_checkpoint == "race_ready" and stage.snapshot().fair.levelled, "levelled persisted")
	check(not stage.apply("level_pond", "self"), "level duplicate safe")
	check(stage.apply("release_boat"), "second release")
	check(stage.snapshot().fair.outcome == "first", "straight triangle first deterministic")
	check(stage.snapshot().fair.get("souvenir_ids", []) == ["fair_button"], "canonical race keeps durable fair button")
	var canonical = stage.snapshot()
	var forged_departure = canonical.duplicate(true); forged_departure.choice_history.append("the_small_fair.departure.wait")
	check(not Model.new().restore(forged_departure), "result cannot pre-record departure history")
	var forged_camera = canonical.duplicate(true); forged_camera.choice_history.append("platform_six.camera.lend")
	check(not Model.new().restore(forged_camera), "history cannot contradict explicit camera choice")
	check(not stage.record_choice("the_small_fair.departure.wait"), "action-owned consequence cannot be recorded standalone")
	check(stage.snapshot() == canonical, "standalone action choice cannot corrupt checkpoint consistency")
	check(stage.apply("replay_race"), "optional replay accepted")
	var replayed = stage.snapshot()
	check(replayed.fair.outcome == canonical.fair.outcome and replayed.fair.race_count == 2, "replay preserves canonical race")
	check(replayed.fair.get("souvenir_ids", []) == ["fair_button"], "replay never removes or duplicates keepsake")
	check(replayed.choice_history == canonical.choice_history and replayed.dimensions == canonical.dimensions and replayed.npc_state == canonical.npc_state, "replay has no farmable narrative effects")
	check(stage.apply("fair_departure", "wait"), "wait departure valid")
	check(stage.snapshot().fair_checkpoint == "complete", "fair complete")
	check(stage.snapshot().npc_state.mira.destination == "lower_mill" and stage.snapshot().npc_state.mira.independent_decision, "Mira chooses own destination")
	check(not stage.apply("fair_departure", "card"), "departure duplicate safe")
	check(stage.apply("replay_race"), "completed fair remains replayable")
	check(stage.snapshot().fair_checkpoint == "complete" and stage.snapshot().fair.outcome == "first", "completed replay preserves ending")
	check(legacy_snapshot(stage.snapshot()) == legacy_before, "fair preserves all legacy durable fields")
	for route in [["watch","straight","triangle","spectator"],["cooperate","left","folded","second"],["operate","right","triangle","second"],["operate","left","square","third"],["operate","straight","folded","circle"],["operate","straight","square","second"]]:
		var route_model = fair_to_result(route[0],route[1],route[2])
		check(route_model.snapshot().fair.outcome == route[3], "deterministic race " + route[3])
		check(route_model.snapshot().fair.get("souvenir_ids", []) == ["fair_button"], "every outcome keeps same durable fair button")
		check(route_model.apply("fair_departure", "card"), "all outcomes can complete")
		check(route_model.snapshot().npc_state.mira.destination == "lower_mill", "all routes preserve NPC autonomy")
	var missing_rule = fair_to_result()
	var before_missing = missing_rule.snapshot()
	missing_rule.rules.choices.erase("the_small_fair.departure.wait")
	check(not missing_rule.apply("fair_departure", "wait"), "missing consequence never reports transition success")
	check(missing_rule.snapshot() == before_missing, "missing consequence leaves full prior snapshot unchanged")
	var store = Store.new()
	var resumable = complete_chapter("lend")
	var fair_steps = [["begin_fair",null],["fair_greeting","watch"],["release_boat",null],["inspect_fair","wedge"],["level_pond","self"],["release_boat",null],["fair_departure","speak"]]
	for step in fair_steps:
		check(resumable.apply(step[0],step[1]), "resumable fair step " + step[0])
		var suspended = resumable.snapshot()
		var resume_path = "user://fair_checkpoint_" + suspended.fair_checkpoint + "_" + str(Time.get_ticks_usec()) + ".json"
		check(store.save_snapshot(suspended,resume_path).ok, "save fair checkpoint " + suspended.fair_checkpoint)
		var reopened = Model.new()
		check(reopened.restore(store.load_snapshot(resume_path).data) and reopened.snapshot() == suspended, "restore fair checkpoint " + suspended.fair_checkpoint)
		resumable = reopened
	var path = "user://fair_model_" + str(Time.get_ticks_usec()) + ".json"
	check(store.save_snapshot(stage.snapshot(),path).ok, "v2 save writes")
	var loaded = store.load_snapshot(path)
	check(loaded.ok and loaded.data == stage.snapshot(), "v2 complete state roundtrip")
	var old = legacy_snapshot(complete_chapter("unused").snapshot())
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old)); file.close()
	var bytes = FileAccess.get_file_as_string(path)
	var old_loaded = store.load_snapshot(path)
	check(old_loaded.ok and old_loaded.data.schema_version == 2, "store migrates v1 read")
	check(FileAccess.get_file_as_string(path) == bytes, "migration read leaves source bytes untouched")
	check(store.save_snapshot(old_loaded.data,path).ok, "migrated v2 atomically saved")
	check(FileAccess.get_file_as_string(path + ".bak") == bytes, "migration first write preserves exact rotating v1 backup")
	check(FileAccess.get_file_as_string(path + ".v1.bak") == bytes, "migration preserves stable versioned v1 backup")
	check(store.save_snapshot(old_loaded.data,path).ok, "second v2 save succeeds")
	check(FileAccess.get_file_as_string(path + ".v1.bak") == bytes, "second write never overwrites versioned original")
	file = FileAccess.open(path,FileAccess.WRITE); file.store_string("{truncated"); file.close()
	var recovered = store.load_snapshot(path)
	check(recovered.ok and recovered.recovered and recovered.data.schema_version == 2, "corrupt v2 primary recovers verified rotating backup")
	check(store.save_snapshot(recovered.data,path).ok, "save after recovery keeps damaged original")
	var future = stage.snapshot(); future.schema_version = 3
	file = FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(future)); file.close()
	var future_bytes = FileAccess.get_file_as_string(path)
	check(not store.load_snapshot(path).ok, "future schema does not fall back")
	check(not store.save_snapshot(stage.snapshot(),path).ok and not store.reset_snapshot(path).ok, "future schema rejects save and reset")
	check(FileAccess.get_file_as_string(path) == future_bytes, "future schema exact bytes untouched")
	var recovery_path = "user://fair_recovered_v1_" + str(Time.get_ticks_usec()) + ".json"
	file = FileAccess.open(recovery_path,FileAccess.WRITE); file.store_string("{damaged"); file.close()
	file = FileAccess.open(recovery_path + ".bak",FileAccess.WRITE); file.store_string(bytes); file.close()
	var recovered_v1 = store.load_snapshot(recovery_path)
	check(recovered_v1.ok and recovered_v1.recovered and recovered_v1.migrated, "damaged primary recovers migrated v1 source")
	check(store.save_snapshot(recovered_v1.data,recovery_path).ok, "recovered v1 first save succeeds")
	check(FileAccess.get_file_as_string(recovery_path + ".v1.bak") == bytes, "recovered v1 gets stable source backup")
	check(store.save_snapshot(recovered_v1.data,recovery_path).ok, "recovered v1 second save succeeds")
	check(FileAccess.get_file_as_string(recovery_path + ".v1.bak") == bytes, "recovered v1 stable source survives rotation")
	var backup_path = "user://fair_future_backup_" + str(Time.get_ticks_usec()) + ".json"
	check(store.save_snapshot(stage.snapshot(),backup_path).ok, "future backup setup")
	file = FileAccess.open(backup_path + ".bak",FileAccess.WRITE); file.store_string(JSON.stringify(future)); file.close()
	var future_backup_bytes = FileAccess.get_file_as_string(backup_path + ".bak")
	check(not store.save_snapshot(stage.snapshot(),backup_path).ok and not store.reset_snapshot(backup_path).ok, "future backup protected from save and reset")
	check(FileAccess.get_file_as_string(backup_path + ".bak") == future_backup_bytes, "future backup exact bytes untouched")
	file = FileAccess.open(backup_path,FileAccess.WRITE); file.store_string("{truncated"); file.close()
	check(store.load_snapshot(backup_path).error == "future schema", "future backup reported when primary damaged")
	for key in ["fair","dimensions","npc_state","choice_history","fair_checkpoint","campaign_chapter"]:
		var invalid = stage.snapshot(); invalid[key] = "wrong"
		check(not Model.new().restore(invalid), "invalid v2 field " + key)
	var invalid = stage.snapshot(); invalid.dimensions.joy = 101
	check(not Model.new().restore(invalid), "out-of-bounds fictional dimension rejected")
	invalid = stage.snapshot(); invalid.npc_state.mira.destination = "user_diagnosis"
	check(not Model.new().restore(invalid), "invalid NPC destination rejected")
	invalid = stage.snapshot(); invalid.choice_history.append("unknown.choice")
	check(not Model.new().restore(invalid), "unknown history rejected without corruption")
	invalid = stage.snapshot(); invalid.fair["malicious_config"] = "external_target"
	check(not Model.new().restore(invalid), "unknown config keys rejected")
	invalid = stage.snapshot(); invalid.fair.rudder = {"left":true}
	check(not Model.new().restore(invalid), "malformed config rejected")
	invalid = stage.snapshot(); invalid.fair.race_count = 1
	check(not Model.new().restore(invalid), "inconsistent fair checkpoint rejected")
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/choices.json"))
	check(Model.new().validate_choice_catalog(catalog), "authored consequence catalog validates")
	var bad_catalog = catalog.duplicate(true); bad_catalog.choices[0].consequences.dimensions["clinical_score"] = 1
	check(not Model.new().validate_choice_catalog(bad_catalog), "catalog refuses non-fictional dimensions")
	bad_catalog = catalog.duplicate(true); bad_catalog.choices.append(bad_catalog.choices[0].duplicate(true))
	check(not Model.new().validate_choice_catalog(bad_catalog), "catalog refuses duplicate IDs")
	bad_catalog = catalog.duplicate(true); bad_catalog.choices[0].consequences.npc["unapproved_person"] = {"connection":1}
	check(not Model.new().validate_choice_catalog(bad_catalog), "catalog refuses unknown NPC")
	var bounded = complete_chapter(); bounded.apply("begin_fair"); bounded.apply("fair_greeting", "ducks")
	var bounded_state = bounded.snapshot(); bounded_state.dimensions.agency = 100; bounded_state.npc_state.ada.connection = 100
	check(bounded.restore(bounded_state), "bounded prior state valid")
	check(bounded.apply("set_rudder", "left"), "bounded consequence applies")
	check(bounded.snapshot().dimensions.agency == 100, "dimension consequence clamps to upper bound")
	check(bounded.apply("set_race_mode", "cooperate"), "bounded NPC consequence applies")
	check(bounded.snapshot().npc_state.ada.connection == 100, "NPC consequence clamps to upper bound")
	var detached = stage.snapshot(); detached.fair.inspected.clear(); detached.dimensions.joy = 99
	check(stage.snapshot().fair.inspected.size() > 0 and stage.snapshot().dimensions.joy != 99, "snapshots deeply detached")
	print("Fair model checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
