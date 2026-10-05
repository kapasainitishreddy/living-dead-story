extends SceneTree
const Model = preload("res://core/chapter_model.gd")
const Store = preload("res://core/save_store.gd")
const KITCHEN_DEFAULTS = {"mode":"unselected","served":false,"exchange":"unselected","departure":"unselected","completed":false}
var checks := 0
var failures := 0
func check(condition: bool, label: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
func finish_checks():
	print("Kitchen model checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
func completed_paper(camera: String = "lend", resolution: String = "skipped", paper_mode: String = "watch"):
	var m = Model.new()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]:
		check(m.apply(action), "prior chapter setup " + action)
	check(m.apply("choose_camera", camera), "prior chapter camera " + camera)
	check(m.apply("resolve_action", resolution), "prior optional route " + resolution)
	for action in ["return_train","have_breakfast","finish","begin_fair"]:
		check(m.apply(action), "prior chapter setup " + action)
	for step in [["fair_greeting","watch"],["release_boat",null],["inspect_fair","watch"],["level_pond","ada"],["release_boat",null],["fair_departure","wait"],["begin_paper",null],["paper_greeting",null],["set_paper_star","empty"],["set_paper_layout","star_boat_leaf"],["set_paper_length","long"],["set_paper_mode",paper_mode],["set_paper_fold","enough"],["raise_paper",null],["finish_paper",null]]:
		check(m.apply(step[0], step[1]), "prior chapter setup " + step[0])
	return m
func reject_restore(candidate: Dictionary, label: String):
	var target = Model.new()
	var untouched = target.snapshot()
	check(not target.valid(candidate), "invalid snapshot rejected by validator " + label)
	check(not target.restore(candidate), "invalid snapshot rejected on restore " + label)
	check(target.snapshot() == untouched, "invalid restore atomic " + label)
func rejected_action(m, action: String, value: Variant, label: String):
	var before = m.snapshot()
	check(not m.apply(action,value), "invalid action rejected " + label)
	check(m.snapshot() == before, "invalid action atomic " + label)
func _initialize():
	var initial = Model.new().snapshot()
	check(initial.schema_version == 2, "kitchen retains existing save schema")
	check(initial.get("kitchen_checkpoint") == "locked", "kitchen defaults locked")
	check(initial.get("kitchen") == KITCHEN_DEFAULTS, "kitchen exact neutral defaults")
	for field in ["kitchen","kitchen_checkpoint"]:
		for bad in [null,true,[],15,"unknown"]:
			var invalid = initial.duplicate(true)
			invalid[field] = bad
			reject_restore(invalid, field + " " + str(bad))
	for field in KITCHEN_DEFAULTS:
		var missing = initial.duplicate(true)
		missing.kitchen.erase(field)
		reject_restore(missing, "missing kitchen " + field)
		var malformed = initial.duplicate(true)
		malformed.kitchen[field] = "unknown"
		reject_restore(malformed, "bad kitchen " + field)
	var extra = initial.duplicate(true)
	extra.kitchen["earned_place"] = true
	reject_restore(extra, "no extra kitchen score or earning field")
	var m = completed_paper()
	var prior = m.snapshot()
	var began = m.apply("begin_kitchen")
	check(began, "completed paper unlocks kitchen arrival")
	if not began:
		finish_checks()
		return
	check(m.snapshot().campaign_chapter == "night_kitchen" and m.snapshot().kitchen_checkpoint == "arrival", "arrival campaign and checkpoint durable")
	check(m.snapshot().kitchen == KITCHEN_DEFAULTS, "arrival place requires no task debt")
	rejected_action(m,"begin_kitchen",null,"begin cannot repeat")
	rejected_action(m,"kitchen_share","bread","share cannot bypass arrival")
	rejected_action(m,"kitchen_departure","ask","departure cannot bypass supper")
	for action in ["kitchen_join","kitchen_share","kitchen_departure"]:
		for bad in [null,true,[],{},15,"unknown"]:
			rejected_action(m,action,bad,action + " bad " + str(bad))
	check(m.apply("kitchen_join","watch"), "watch is a complete supper route")
	check(m.snapshot().kitchen == {"mode":"watch","served":true,"exchange":"unselected","departure":"unselected","completed":false}, "watch receives same served place")
	check(m.snapshot().kitchen_checkpoint == "supper", "join reaches supper")
	rejected_action(m,"kitchen_join","help","joined mode cannot repeat or change")
	check(m.apply("kitchen_share","watch"), "watching exchange reaches conversation")
	check(m.snapshot().kitchen_checkpoint == "conversation" and m.snapshot().kitchen.exchange == "watch", "conversation durable")
	rejected_action(m,"kitchen_share","bread","exchange cannot repeat or change")
	check(m.apply("kitchen_departure","listen"), "listening completes supper chapter")
	check(m.snapshot().kitchen_checkpoint == "complete" and m.snapshot().kitchen.completed, "completion durable")
	for action in ["begin_kitchen","kitchen_join","kitchen_share","kitchen_departure"]:
		rejected_action(m,action,{"kitchen_join":"sit","kitchen_share":"cup","kitchen_departure":"wish"}.get(action),"complete freezes " + action)
	for key in prior:
		if key not in ["campaign_chapter","kitchen_checkpoint","kitchen","choice_history"]:
			check(m.snapshot()[key] == prior[key], "kitchen leaves prior state unchanged " + key)
	check(m.snapshot().npc_state.mira.destination == "lower_mill" and m.snapshot().npc_state.mira.independent_decision, "Mira keeps independent Lower Mill plan")
	check(m.snapshot().choice_history.slice(prior.choice_history.size()) == ["night_kitchen.begin","night_kitchen.mode.watch","night_kitchen.exchange.watch","night_kitchen.departure.listen"], "unique ordered kitchen action trace")
	var checkpoints = {"locked":prior}
	var resumed = completed_paper()
	var store = Store.new()
	for step in [["begin_kitchen",null],["kitchen_join","sit"],["kitchen_share","pepper"],["kitchen_departure","wish"]]:
		check(resumed.apply(step[0],step[1]), "resumable kitchen " + step[0])
		var suspended = resumed.snapshot()
		checkpoints[suspended.kitchen_checkpoint] = suspended
		var path = "user://kitchen_checkpoint_" + suspended.kitchen_checkpoint + "_" + str(Time.get_ticks_usec()) + ".json"
		check(store.save_snapshot(suspended,path).ok, "save kitchen " + step[0])
		var loaded = store.load_snapshot(path)
		var reopened = Model.new()
		check(loaded.ok and reopened.restore(loaded.data) and reopened.snapshot() == suspended, "exact kitchen checkpoint reload " + step[0])
		resumed = reopened
	for checkpoint in checkpoints:
		var snapshot: Dictionary = checkpoints[checkpoint]
		for field in ["mode","exchange","departure","served","completed"]:
			var forged = snapshot.duplicate(true)
			forged.kitchen[field] = not forged.kitchen[field] if field in ["served","completed"] else "unselected" if forged.kitchen[field] != "unselected" else {"mode":"help","exchange":"cup","departure":"ask"}[field]
			reject_restore(forged, checkpoint + " inconsistent " + field)
		for key in ["kitchen","kitchen_checkpoint"]:
			if checkpoint == "locked": continue
			var absent = snapshot.duplicate(true)
			absent.erase(key)
			reject_restore(absent, "active " + checkpoint + " missing " + key)
		for id in ["night_kitchen.begin","night_kitchen.mode.sit","night_kitchen.mode.help","night_kitchen.mode.watch","night_kitchen.exchange.bread","night_kitchen.exchange.cup","night_kitchen.exchange.pepper","night_kitchen.exchange.watch","night_kitchen.departure.ask","night_kitchen.departure.wish","night_kitchen.departure.listen"]:
			var forged = snapshot.duplicate(true)
			if id in forged.choice_history:
				forged.choice_history.erase(id)
			else:
				forged.choice_history.append(id)
			reject_restore(forged, checkpoint + " inconsistent trace " + id)
	for checkpoint in ["supper","conversation","complete"]:
		var reordered: Dictionary = checkpoints[checkpoint].duplicate(true)
		var first = reordered.choice_history.find("night_kitchen.begin")
		var next = first + 1
		var temp = reordered.choice_history[first]
		reordered.choice_history[first] = reordered.choice_history[next]
		reordered.choice_history[next] = temp
		reject_restore(reordered,"kitchen action trace preserves chronology " + checkpoint)
	for checkpoint in ["arrival","supper","conversation","complete"]:
		var forged = initial.duplicate(true)
		forged.campaign_chapter = "night_kitchen"
		forged.kitchen_checkpoint = checkpoint
		reject_restore(forged,"kitchen cannot skip prior chapters " + checkpoint)
	var no_paper = resumed.snapshot()
	no_paper.paper_checkpoint = "raised"
	no_paper.paper.completed = false
	no_paper.choice_history.erase("paper_sky.finish")
	reject_restore(no_paper,"kitchen requires completed paper")
	for campaign in ["platform_six","the_small_fair","paper_sky"]:
		var retagged = resumed.snapshot()
		retagged.campaign_chapter = campaign
		reject_restore(retagged,"active kitchen cannot retag " + campaign)
	var detached = resumed.snapshot()
	detached.kitchen.mode = "help"
	check(resumed.snapshot().kitchen.mode == "sit", "kitchen snapshot deeply detached")
	var changed_prefs = resumed.snapshot().settings
	changed_prefs.reduced_motion = true
	check(resumed.apply("settings",changed_prefs), "settings valid during completed kitchen")
	check(resumed.snapshot().kitchen == checkpoints.complete.kitchen, "settings preserve exact kitchen choice")
	var old_candidates = [initial,prior]
	var old_early = initial.duplicate(true)
	old_early.erase("paper")
	old_early.erase("paper_checkpoint")
	old_candidates.append(old_early)
	for old_source in old_candidates:
		var old = old_source.duplicate(true)
		old.erase("kitchen")
		old.erase("kitchen_checkpoint")
		var saved_old = old.duplicate(true)
		check(Model.new().valid(old), "old schema 2 validates with absent optional kitchen")
		var restored = Model.new()
		check(restored.restore(old), "old schema 2 restores")
		check(restored.snapshot().kitchen == KITCHEN_DEFAULTS and restored.snapshot().kitchen_checkpoint == "locked", "old schema 2 receives neutral kitchen defaults")
		check(old == saved_old, "old schema 2 caller unchanged")
	for optional_field in ["kitchen","kitchen_checkpoint"]:
		var partial = prior.duplicate(true)
		partial.erase(optional_field)
		var compatible = Model.new()
		check(compatible.valid(partial) and compatible.restore(partial) and compatible.snapshot() == prior,"inactive optional field normalizes independently " + optional_field)
	var legacy = {}
	for key in Model.LEGACY_KEYS: legacy[key] = prior[key]
	legacy.schema_version = 1
	var migrated = Model.new()
	check(migrated.restore(legacy), "schema 1 still migrates")
	check(migrated.snapshot().kitchen == KITCHEN_DEFAULTS and migrated.snapshot().kitchen_checkpoint == "locked", "schema 1 neutral kitchen")
	var old_path = "user://kitchen_old_schema_" + str(Time.get_ticks_usec()) + ".json"
	var old_save = prior.duplicate(true)
	old_save.erase("kitchen")
	old_save.erase("kitchen_checkpoint")
	var old_file = FileAccess.open(old_path,FileAccess.WRITE)
	old_file.store_string(JSON.stringify(old_save))
	old_file.close()
	var old_loaded = store.load_snapshot(old_path)
	check(old_loaded.ok and old_loaded.data.kitchen == KITCHEN_DEFAULTS, "save store reads actual old schema 2 bytes")
	check(store.save_snapshot(old_loaded.data,old_path).ok, "save store writes normalized old schema 2")
	check(store.read_file(old_path + ".bak").ok and FileAccess.get_file_as_string(old_path + ".bak") == JSON.stringify(old_save), "old source retained in rotating backup")
	var backup_path = "user://kitchen_backup_" + str(Time.get_ticks_usec()) + ".json"
	check(store.save_snapshot(checkpoints.conversation,backup_path).ok, "kitchen conversation primary")
	check(store.save_snapshot(checkpoints.complete,backup_path).ok, "kitchen completion with backup")
	var damaged = FileAccess.open(backup_path,FileAccess.WRITE)
	damaged.store_string("{damaged")
	damaged.close()
	var recovered = store.load_snapshot(backup_path)
	check(recovered.ok and recovered.recovered and recovered.data == checkpoints.conversation, "damaged completed kitchen recovers exact conversation")
	var combinations := 0
	for mode in ["sit","help","watch"]:
		for exchange in ["bread","cup","pepper","watch"]:
			for departure in ["ask","wish","listen"]:
				var branch = Model.new()
				check(branch.restore(prior), "route prior restore")
				for step in [["begin_kitchen",null],["kitchen_join",mode],["kitchen_share",exchange],["kitchen_departure",departure]]:
					check(branch.apply(step[0],step[1]), "all routes complete " + step[0] + " " + str(step[1]))
					var roundtrip = Model.new()
					check(roundtrip.restore(JSON.parse_string(JSON.stringify(branch.snapshot()))) and roundtrip.snapshot() == branch.snapshot(), "all routes resume every checkpoint")
					branch = roundtrip
				check(branch.snapshot().kitchen == {"mode":mode,"served":true,"exchange":exchange,"departure":departure,"completed":true}, "all 36 exact route configurations")
				for key in ["dimensions","npc_state","souvenir_ids","fair","paper","action_resolution"]:
					check(branch.snapshot()[key] == prior[key], "all routes equal durable outcome " + key)
				combinations += 1
	check(combinations == 36, "all 36 kitchen route combinations")
	for camera in ["take","lend","unused"]:
		for resolution in ["completed","skipped"]:
			for paper_mode in ["assemble","direct","watch"]:
				var callback = completed_paper(camera,resolution,paper_mode)
				var before = callback.snapshot()
				for step in [["begin_kitchen",null],["kitchen_join","watch"],["kitchen_share","watch"],["kitchen_departure","listen"]]:
					check(callback.apply(step[0],step[1]), "all prior callbacks can complete supper")
				for key in ["camera_choice","action_resolution","npc_state","dimensions","fair","paper"]:
					check(callback.snapshot()[key] == before[key], "camera optional and paper callback preserved " + key)
	for route in [["begin_kitchen",null,"night_kitchen.begin"],["kitchen_join","help","night_kitchen.mode.help"],["kitchen_share","cup","night_kitchen.exchange.cup"],["kitchen_departure","wish","night_kitchen.departure.wish"]]:
		var absent_rule = Model.new()
		check(absent_rule.restore(checkpoints[{"begin_kitchen":"locked","kitchen_join":"arrival","kitchen_share":"supper","kitchen_departure":"conversation"}[route[0]]]), "missing rule restores valid checkpoint")
		absent_rule.rules.choices.erase(route[2])
		rejected_action(absent_rule,route[0],route[1],"missing authored rule " + route[2])
	for checkpoint in ["arrival","supper","conversation"]:
		var bad_target = Model.new()
		check(bad_target.restore(checkpoints[checkpoint]),"invalid value setup " + checkpoint)
		var action = {"arrival":"kitchen_join","supper":"kitchen_share","conversation":"kitchen_departure"}[checkpoint]
		for bad in [null,true,[],{},15,"unknown"]:
			rejected_action(bad_target,action,bad,"actual checkpoint bad choice " + checkpoint + " " + str(bad))
	for source in [initial,checkpoints.arrival,checkpoints.supper,checkpoints.conversation,checkpoints.complete]:
		var target = Model.new()
		check(target.restore(source), "action invariant restores source")
		for step in [["begin_paper",null],["paper_greeting",null],["set_paper_mode","assemble"],["raise_paper",null],["finish_paper",null],["begin_fair",null],["fair_departure","card"],["finish",null]]:
			if source == initial and step[0] == "begin_fair": continue
			rejected_action(target,step[0],step[1],"kitchen cannot replay prior action " + step[0])
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/choices.json"))
	check(Model.new().validate_choice_catalog(catalog), "extended kitchen catalog validates")
	var kitchen_choices := 0
	for choice in catalog.choices:
		if choice.campaign_chapter != "night_kitchen": continue
		kitchen_choices += 1
		check(choice.consequences == {"dimensions":{},"npc":{}}, "kitchen consequence neutral " + choice.choice_id)
		var weighted = catalog.duplicate(true)
		for bad_choice in weighted.choices:
			if bad_choice.choice_id == choice.choice_id:
				bad_choice.consequences.dimensions["agency"] = 1
		check(not Model.new().validate_choice_catalog(weighted), "kitchen catalog forbids scoring " + choice.choice_id)
	var npc_effect = catalog.duplicate(true)
	for choice in npc_effect.choices:
		if choice.campaign_chapter == "night_kitchen":
			choice.consequences.npc = {"mira":{"independent_decision":false}}
			break
	check(not Model.new().validate_choice_catalog(npc_effect),"kitchen catalog cannot overwrite NPC autonomy")
	check(kitchen_choices == 11, "eleven kitchen traces authored")
	finish_checks()
