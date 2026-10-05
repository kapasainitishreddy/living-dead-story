extends SceneTree
const Model = preload("res://core/chapter_model.gd")
const Store = preload("res://core/save_store.gd")
const PAPER_DEFAULTS = {"star":"crooked","layout":"leaf_boat_star","length":"medium","mode":"assemble","fold":"keep","completed":false}
var checks := 0
var failures := 0
func check(condition: bool, label: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
func finish_checks():
	print("Paper model checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
func completed_fair(camera: String = "lend", resolution: String = "skipped"):
	var m = Model.new()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]:
		check(m.apply(action), "paper setup " + action)
	check(m.apply("choose_camera", camera), "paper setup camera")
	check(m.apply("resolve_action", resolution), "paper setup optional resolution")
	for action in ["return_train","have_breakfast","finish","begin_fair"]:
		check(m.apply(action), "paper setup " + action)
	check(m.apply("fair_greeting", "watch"), "paper setup greeting")
	check(m.apply("release_boat"), "paper setup crooked race")
	check(m.apply("inspect_fair", "watch"), "paper setup inspection")
	check(m.apply("level_pond", "ada"), "paper setup levelling")
	check(m.apply("release_boat"), "paper setup canonical race")
	check(m.apply("fair_departure", "wait"), "paper setup fair completion")
	return m
func _initialize():
	var initial = Model.new().snapshot()
	check(initial.schema_version == 2, "paper retains existing save schema")
	check(initial.get("paper_checkpoint") == "locked", "paper defaults locked")
	check(initial.get("paper") == PAPER_DEFAULTS, "neutral exact sign defaults")
	var old = initial.duplicate(true)
	old.erase("paper_checkpoint")
	old.erase("paper")
	var restored = Model.new()
	check(restored.restore(old), "existing schema 2 snapshot remains readable")
	check(restored.snapshot().get("paper") == PAPER_DEFAULTS, "schema 2 restores optional paper defaults")
	check(restored.snapshot().get("paper_checkpoint") == "locked", "schema 2 restores optional paper checkpoint")
	check(not old.has("paper") and not old.has("paper_checkpoint"), "normalizing old save leaves caller unchanged")
	check(not Model.new().apply("begin_paper"), "paper cannot bypass existing chapters")
	var m = completed_fair()
	var prior = m.snapshot()
	check(m.apply("begin_paper"), "completed fair unlocks paper arrival")
	check(m.snapshot().campaign_chapter == "paper_sky" and m.snapshot().paper_checkpoint == "arrival", "paper campaign and arrival durable")
	check(not m.apply("begin_paper"), "begin paper idempotent")
	check(not m.apply("raise_paper"), "cannot raise before greeting")
	check(m.apply("paper_greeting"), "paper greeting reaches workshop")
	check(m.snapshot().paper_checkpoint == "workshop", "paper workshop durable")
	check(not m.apply("paper_greeting"), "paper greeting idempotent")
	for setting in [["set_paper_star","star","crooked","clean","empty"],["set_paper_layout","layout","leaf_boat_star","boat_star_leaf","star_leaf_boat"],["set_paper_length","length","medium","short","long"],["set_paper_mode","mode","assemble","direct","watch"],["set_paper_fold","fold","keep","wider","enough"]]:
		check(m.apply(setting[0], setting[2]), "explicit default paper choice " + setting[1])
		var selected = m.snapshot()
		check(not m.apply(setting[0], setting[2]) and m.snapshot() == selected, "same paper choice idempotent " + setting[1])
		check(m.apply(setting[0], setting[3]), "change paper choice " + setting[1])
		check(m.apply(setting[0], setting[4]), "third paper choice " + setting[1])
		var third = m.snapshot()
		check(m.apply(setting[0], setting[3]), "previously selected paper choice remains selectable " + setting[1])
		var reselected = m.snapshot()
		check(reselected.paper[setting[1]] == setting[3], "physical piece matches latest choice " + setting[1])
		for key in ["choice_history","dimensions","npc_state"]:
			check(reselected[key] == third[key], "reselect never farms " + setting[1] + " " + key)
		check(not m.apply(setting[0], "unknown") and m.snapshot() == reselected, "unknown paper option atomic " + setting[1])
	var configured = m.snapshot().paper.duplicate(true)
	check(m.apply("raise_paper"), "raise chosen sign")
	check(m.snapshot().paper_checkpoint == "raised" and m.snapshot().paper == configured, "raised sign retains exact arrangement")
	check(not m.apply("raise_paper"), "raising sign idempotent")
	check(not m.apply("set_paper_star", "crooked"), "raised sign configuration frozen for revisit")
	check(m.apply("finish_paper"), "finish sign joins every route")
	check(m.snapshot().paper_checkpoint == "complete" and m.snapshot().paper.completed, "sign completion durable")
	check(not m.apply("finish_paper"), "sign completion idempotent")
	for key in ["fair","fair_checkpoint","checkpoint_id","camera_choice","action_resolution","souvenir_ids","chapter_world_flag","chapter_complete"]:
		check(m.snapshot()[key] == prior[key], "paper preserves previous chapter " + key)
	check(m.snapshot().npc_state.mira == prior.npc_state.mira, "Mira retains explicit memory and independent destination")
	var store = Store.new()
	var resumed = completed_fair()
	for step in [["begin_paper",null],["paper_greeting",null],["set_paper_star","empty"],["set_paper_layout","star_leaf_boat"],["set_paper_length","long"],["set_paper_mode","watch"],["set_paper_fold","enough"],["raise_paper",null],["finish_paper",null]]:
		check(resumed.apply(step[0], step[1]), "resumable paper step " + step[0])
		var suspended = resumed.snapshot()
		var path = "user://paper_checkpoint_" + suspended.paper_checkpoint + "_" + str(Time.get_ticks_usec()) + ".json"
		check(store.save_snapshot(suspended, path).ok, "save exact sign at " + step[0])
		var loaded = store.load_snapshot(path)
		var reopened = Model.new()
		check(loaded.ok and reopened.restore(loaded.data) and reopened.snapshot() == suspended, "reopen exact sign at " + step[0])
		resumed = reopened
	for field in ["paper","paper_checkpoint"]:
		for bad in [null,true,[],15,"unknown"]:
			var invalid = resumed.snapshot()
			invalid[field] = bad
			var target = Model.new()
			var untouched = target.snapshot()
			check(not target.restore(invalid), "malformed paper field rejected " + field + " " + str(bad))
			check(target.snapshot() == untouched, "malformed restore leaves model untouched " + field)
	for field in PAPER_DEFAULTS:
		var missing = resumed.snapshot()
		missing.paper.erase(field)
		check(not Model.new().restore(missing), "present paper requires every field " + field)
		var malformed = resumed.snapshot()
		malformed.paper[field] = "unknown"
		check(not Model.new().restore(malformed), "invalid paper option rejected " + field)
	var extra = resumed.snapshot()
	extra.paper["artistic_rating"] = 100
	check(not Model.new().restore(extra), "unknown paper keys rejected")
	for checkpoint in ["arrival","workshop","raised","complete"]:
		var forged = initial.duplicate(true)
		forged.paper_checkpoint = checkpoint
		forged.paper.completed = checkpoint == "complete"
		check(not Model.new().restore(forged), "paper checkpoint cannot bypass chapters " + checkpoint)
	var premature_paper = completed_fair().snapshot()
	premature_paper.campaign_chapter = "paper_sky"
	premature_paper.paper_checkpoint = "arrival"
	check(not Model.new().restore(premature_paper), "arrival requires authored begin history")
	var arrival = completed_fair()
	check(arrival.apply("begin_paper"), "history validation setup arrival")
	var arrival_snapshot = arrival.snapshot()
	for id in ["paper_sky.greeting","paper_sky.star.clean","paper_sky.mode.watch","paper_sky.raise","paper_sky.finish"]:
		var forged = arrival_snapshot.duplicate(true)
		forged.choice_history.append(id)
		check(not Model.new().restore(forged), "arrival rejects premature paper history " + id)
	var forged_star = arrival_snapshot.duplicate(true)
	forged_star.paper.star = "clean"
	check(not Model.new().restore(forged_star), "arrival cannot carry premature configuration")
	check(arrival.apply("paper_greeting"), "history validation setup workshop")
	var workshop_snapshot = arrival.snapshot()
	var unrecorded = workshop_snapshot.duplicate(true)
	unrecorded.paper.star = "clean"
	check(not Model.new().restore(unrecorded), "nondefault piece needs explicit authored choice")
	for checkpoint in ["workshop","raised","complete"]:
		var forged = resumed.snapshot()
		forged.paper_checkpoint = checkpoint
		forged.paper.completed = checkpoint == "complete"
		forged.choice_history.erase({"workshop":"paper_sky.greeting","raised":"paper_sky.raise","complete":"paper_sky.finish"}[checkpoint])
		if checkpoint == "workshop":
			forged.choice_history.erase("paper_sky.raise")
			forged.choice_history.erase("paper_sky.finish")
		if checkpoint == "raised": forged.choice_history.erase("paper_sky.finish")
		check(not Model.new().restore(forged), "checkpoint requires its transition history " + checkpoint)
	for field in ["paper","paper_checkpoint"]:
		var missing = resumed.snapshot()
		missing.erase(field)
		check(not Model.new().restore(missing), "active paper cannot omit durable state " + field)
	var wrong_completion = resumed.snapshot()
	wrong_completion.paper.completed = false
	check(not Model.new().restore(wrong_completion), "complete checkpoint requires sign completion")
	var fair_retagged = resumed.snapshot()
	fair_retagged.campaign_chapter = "the_small_fair"
	check(not Model.new().restore(fair_retagged), "active paper cannot be retagged as fair")
	var no_fair_departure = resumed.snapshot()
	no_fair_departure.fair_checkpoint = "result"
	no_fair_departure.fair.departure = "unselected"
	no_fair_departure.npc_state.mira.destination = "unselected"
	no_fair_departure.npc_state.mira.independent_decision = false
	no_fair_departure.choice_history.erase("the_small_fair.departure.wait")
	check(not Model.new().restore(no_fair_departure), "paper requires completed fair departure")
	var missing_rule = completed_fair()
	var before_missing = missing_rule.snapshot()
	missing_rule.rules.choices.erase("paper_sky.begin")
	check(not missing_rule.apply("begin_paper") and missing_rule.snapshot() == before_missing, "missing begin consequence rolls back campaign and state")
	var missing_config = completed_fair()
	check(missing_config.apply("begin_paper") and missing_config.apply("paper_greeting"), "missing choice setup")
	before_missing = missing_config.snapshot()
	missing_config.rules.choices.erase("paper_sky.star.clean")
	check(not missing_config.apply("set_paper_star", "clean") and missing_config.snapshot() == before_missing, "missing config consequence rolls back full state")
	var branch_source = completed_fair().snapshot()
	var combinations := 0
	for star in ["crooked","clean","empty"]:
		for layout in ["leaf_boat_star","boat_star_leaf","star_leaf_boat","leaf_star_boat","boat_leaf_star","star_boat_leaf"]:
			for length in ["short","medium","long"]:
				for mode in ["assemble","direct","watch"]:
					for fold in ["keep","wider","enough"]:
						var branch = Model.new()
						check(branch.restore(branch_source), "matrix prior fair restore")
						check(branch.apply("begin_paper") and branch.apply("paper_greeting"), "matrix paper arrival and greeting")
						for field in {"star":star,"layout":layout,"length":length,"mode":mode,"fold":fold}:
							check(branch.apply("set_paper_" + field, {"star":star,"layout":layout,"length":length,"mode":mode,"fold":fold}[field]), "matrix explicit " + field)
						check(branch.apply("raise_paper") and branch.apply("finish_paper"), "every configuration completes")
						var expected_paper = {"star":star,"layout":layout,"length":length,"mode":mode,"fold":fold,"completed":true}
						check(branch.snapshot().paper == expected_paper, "matrix exact final sign config")
						for key in ["dimensions","npc_state","souvenir_ids","fair"]:
							check(branch.snapshot()[key] == branch_source[key], "every mode and piece has equal durable " + key)
						var roundtrip = Model.new()
						check(roundtrip.restore(JSON.parse_string(JSON.stringify(branch.snapshot()))) and roundtrip.snapshot() == branch.snapshot(), "matrix JSON sign roundtrip")
						combinations += 1
	check(combinations == 486, "all 486 distinct hanging sign configurations tested")
	var default_route = completed_fair()
	for action in ["begin_paper","paper_greeting","raise_paper","finish_paper"]:
		check(default_route.apply(action), "default configuration requires no task debt " + action)
	var default_sign = PAPER_DEFAULTS.duplicate(true)
	default_sign.completed = true
	check(default_route.snapshot().paper == default_sign, "default route keeps exact sign")
	for transition in ["paper_greeting","raise_paper","finish_paper"]:
		var absent_rule = completed_fair()
		check(absent_rule.apply("begin_paper"), "missing transition setup begin")
		if transition != "paper_greeting": check(absent_rule.apply("paper_greeting"), "missing transition setup greeting")
		if transition == "finish_paper": check(absent_rule.apply("raise_paper"), "missing transition setup raise")
		var rollback = absent_rule.snapshot()
		absent_rule.rules.choices.erase({"paper_greeting":"paper_sky.greeting","raise_paper":"paper_sky.raise","finish_paper":"paper_sky.finish"}[transition])
		check(not absent_rule.apply(transition) and absent_rule.snapshot() == rollback, "missing transition consequence atomic " + transition)
	var old_completed_fair = branch_source.duplicate(true)
	old_completed_fair.erase("paper")
	old_completed_fair.erase("paper_checkpoint")
	check(Model.new().valid(old_completed_fair), "older complete fair schema 2 validates without paper fields")
	var resumed_old_fair = Model.new()
	check(resumed_old_fair.restore(old_completed_fair) and resumed_old_fair.snapshot() == branch_source, "old completed fair gains only neutral paper defaults")
	check(resumed_old_fair.apply("begin_paper"), "old completed fair can enter new chapter")
	var legacy = {}
	for key in Model.LEGACY_KEYS: legacy[key] = branch_source[key]
	legacy.schema_version = 1
	var migrated = Model.new()
	check(migrated.restore(legacy) and migrated.snapshot().paper == PAPER_DEFAULTS and migrated.snapshot().paper_checkpoint == "locked", "schema 1 still migrates with neutral locked paper")
	var detached = resumed.snapshot()
	detached.paper.star = "crooked"
	check(resumed.snapshot().paper.star == "empty", "sign snapshot is deeply detached")
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/choices.json"))
	check(Model.new().validate_choice_catalog(catalog), "extended authored catalog validates")
	var paper_choices := 0
	for choice in catalog.choices:
		if choice.campaign_chapter == "paper_sky":
			paper_choices += 1
			check(choice.consequences == {"dimensions":{},"npc":{}}, "paper choices preserve equal local consequences " + choice.choice_id)
	check(paper_choices == 22, "all chapter three action traces are authored")
	finish_checks()
