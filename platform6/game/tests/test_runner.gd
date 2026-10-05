extends SceneTree
var failures := 0
var checks := 0
func check(condition: bool, label: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
func _initialize():
	var model = load("res://core/chapter_model.gd").new()
	check(not model.apply("unknown"), "reject unknown action")
	check(model.apply("leave_apartment"), "leave apartment must advance")
	check(model.snapshot().checkpoint_id == "roof", "roof checkpoint")
	check(not model.apply("leave_apartment"), "duplicate cannot advance")
	for camera in ["take", "lend", "unused"]:
		for resolution in ["completed", "skipped"]:
			var m = load("res://core/chapter_model.gd").new()
			for action in ["leave_apartment", "meet_stranger", "read_board", "board_train", "meet_passenger", "arrive_shore"]:
				check(m.apply(action), action)
			check(not m.apply("inspect_landmark", "wrong"), "invalid landmark")
			for landmark in ["arch", "constellation", "lighthouse"]:
				check(m.apply("inspect_landmark", landmark), "unordered inspection")
			check(m.apply("align", 2), "solve alignment")
			check(not m.apply("assist"), "duplicate puzzle completion")
			check(m.apply("choose_camera", camera), "camera response")
			check(m.apply("resolve_action", resolution), "optional response")
			check(m.apply("return_train"), "return")
			check(m.apply("have_breakfast"), "breakfast")
			check(m.apply("finish"), "complete")
			var state = m.snapshot()
			check(state.chapter_complete and state.chapter_world_flag and state.souvenir_ids == ["platform_six_journey"], "equal permanent outcomes")
			state["last_seen"] = -999999999
			var resumed = load("res://core/chapter_model.gd").new()
			check(resumed.restore(state) and resumed.snapshot().chapter_complete, "absence no decay")
	var store = load("res://core/save_store.gd").new()
	var save_path = "user://test_snapshot_" + str(Time.get_ticks_usec()) + ".json"
	check(store.save_snapshot(model.snapshot(), save_path).ok, "save roundtrip writes")
	check(store.load_snapshot(save_path).ok, "save roundtrip reads")
	check(not store.load_snapshot("user://missing_987.json").ok, "missing save")
	var valid = model.snapshot()
	check(store.save_snapshot(valid, save_path).ok, "repeat save backup")
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string("{truncated")
	file.close()
	check(store.load_snapshot(save_path).recovered, "truncated primary recovered")
	var future = valid.duplicate(true)
	future.schema_version = 999
	file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(future))
	file.close()
	var bytes = FileAccess.get_file_as_string(save_path)
	check(not store.load_snapshot(save_path).ok, "future version rejected")
	check(not store.save_snapshot(valid, save_path).ok, "future version never overwritten")
	check(FileAccess.get_file_as_string(save_path) == bytes, "future bytes preserved")
	for bad in ["checkpoint_id","camera_choice","overlook_alignment","settings","puzzle_solved"]:
		var malformed = valid.duplicate(true)
		malformed[bad] = "wrong"
		check(not store.save_snapshot(malformed, "user://bad.json").ok, "invalid field " + bad)
	check(not store.save_snapshot(valid, "/proc/platform6/save.json").ok, "unwritable nonfatal")
	var puzzle = load("res://core/chapter_model.gd").new()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore"]: puzzle.apply(action)
	check(puzzle.apply("align",0) and not puzzle.snapshot().puzzle_solved,"wrong framing reversible")
	check(puzzle.apply("align",1) and not puzzle.snapshot().puzzle_solved,"second wrong framing reversible")
	check(puzzle.apply("align",2) and not puzzle.snapshot().puzzle_solved,"inspection required")
	check(puzzle.apply("assist") and puzzle.snapshot().puzzle_solved,"assist untouched landmarks")
	check(not puzzle.apply("assist"),"assist duplicate safe")
	var inconsistent = load("res://core/chapter_model.gd").new().snapshot()
	inconsistent.chapter_complete = true
	check(not model.restore(inconsistent),"inconsistent completion rejected")
	for state in load("res://core/chapter_model.gd").STATES:
		var checkpoint_model = load("res://core/chapter_model.gd").new()
		while checkpoint_model.snapshot().checkpoint_id != state:
			var at = checkpoint_model.snapshot().checkpoint_id
			var action = {"apartment":"leave_apartment","roof":"meet_stranger","platform":"read_board","conductor":"board_train","passenger":"meet_passenger","shoreline":"arrive_shore","overlook":"assist","camera_choice":"choose_camera","optional_action":"resolve_action","return_train":"return_train","breakfast":"have_breakfast"}[at]
			checkpoint_model.apply(action,"take" if action == "choose_camera" else ("skipped" if action == "resolve_action" else null))
		var path = "user://checkpoint_" + state + "_" + str(Time.get_ticks_usec()) + ".json"
		check(store.save_snapshot(checkpoint_model.snapshot(),path).ok and store.load_snapshot(path).data.checkpoint_id == state,"checkpoint roundtrip " + state)
	var authored = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter.json"))
	for id in authored.dialogues:
		var dialogue = authored.dialogues[id]
		check(dialogue.choices.size() > 0 and not dialogue.text.is_empty(),"authored dialogue " + id)
		for option in dialogue.choices:
			check(option.action in load("res://core/chapter_model.gd").STEPS or option.action in ["dismiss","dialogue"],"authored legal choice")
	check(authored.dialogues.optional.choices[0].label == "Done" and authored.dialogues.optional.choices[1].label == "Not tonight","equal optional controls")
	check(store.has_method("reset_snapshot"),"reset retains durable backup")
	for version in ["garbled",null,[],true]:
		var invalid_version = load("res://core/chapter_model.gd").new().snapshot()
		invalid_version.schema_version = version
		var version_path = "user://invalid_version_" + str(Time.get_ticks_usec()) + ".json"
		var invalid_file = FileAccess.open(version_path,FileAccess.WRITE)
		invalid_file.store_string(JSON.stringify(invalid_version))
		invalid_file.close()
		check(not store.load_snapshot(version_path).ok,"malformed version nonfatal")
	var reset_path = "user://reset_" + str(Time.get_ticks_usec()) + ".json"
	var completed = load("res://core/chapter_model.gd").new()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]: completed.apply(action)
	completed.apply("choose_camera","lend")
	completed.apply("resolve_action","completed")
	for action in ["return_train","have_breakfast","finish"]: completed.apply(action)
	store.save_snapshot(completed.snapshot(),reset_path)
	check(store.reset_snapshot(reset_path).ok and store.load_snapshot(reset_path).data.checkpoint_id == "apartment","reset starts fresh")
	var reset_backup_found = false
	for filename in DirAccess.get_files_at("user://"):
		if filename.begins_with(reset_path.get_file()+".reset."):
			reset_backup_found = store.load_snapshot("user://"+filename).data.chapter_complete
	check(reset_backup_found,"reset completion retained in separate backup")
	check(not store.reset_snapshot(save_path).ok and FileAccess.get_file_as_string(save_path) == bytes,"reset future schema blocked")
	print("Checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
