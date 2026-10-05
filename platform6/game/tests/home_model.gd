extends SceneTree
const Model = preload("res://core/chapter_model.gd")
const ReturnModel = preload("res://tests/return_model.gd")
const Store = preload("res://core/save_store.gd")
const HOME_DEFAULTS = {"ticket":"unselected","ritual":"unselected","ending":"unselected","completed":false}
const TICKETS = ["kettle","drawer","pocket"]
const RITUALS = ["tea","window","neither"]
const ENDINGS = ["train","sleep"]
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func reject(m, action: String, value: Variant = null):
	var before = m.snapshot()
	check(not m.apply(action,value) and m.snapshot() == before,"atomic rejection " + action + " " + str(value))
func reject_restore(snapshot: Dictionary, label: String):
	var m = Model.new()
	var before = m.snapshot()
	check(not m.valid(snapshot),"validator rejects " + label)
	check(not m.restore(snapshot) and m.snapshot() == before,"restore rejects atomically " + label)
func completed_return(camera: String = "lend", route: String = "bench", farewell: String = "thanks", extras: bool = true):
	var helper = ReturnModel.new()
	var m = helper.completed_orchard(camera,route)
	check(helper.failures == 0,"prior chapters setup valid")
	helper.free()
	for step in [["begin_return",null],["return_arrival",null],["return_farewell",farewell],["return_departure",null],["return_finish",null]]:
		check(m.apply(step[0],step[1]),"prior return setup " + step[0])
	if extras:
		check(m.apply("return_conductor") and m.apply("return_jo"),"optional prior conversations remain valid")
	return m
func roundtrip(m, label: String):
	var before = m.snapshot()
	var resumed = Model.new()
	check(resumed.restore(JSON.parse_string(JSON.stringify(before))) and resumed.snapshot() == before,"JSON interruption resume " + label)
	var store = Store.new()
	var path = "user://home_model_" + label + "_" + str(Time.get_ticks_usec()) + ".json"
	check(store.save_snapshot(before,path).ok,"native save " + label)
	var loaded = store.load_snapshot(path)
	check(loaded.ok and loaded.data == before,"native reload exact " + label)
	return resumed
func _initialize():
	var initial = Model.new().snapshot()
	check(initial.schema_version == 2,"home retains save schema2")
	check(initial.get("home_checkpoint") == "locked" and initial.get("home") == HOME_DEFAULTS,"home neutral defaults")
	check(initial.get("campaign_complete") == false,"campaign incomplete until final home choice")
	check(initial.get("history_compatibility") == [],"new journey has no grandfathered absent traces")
	for field in ["schema_version","chapter_id","campaign_chapter"]:
		for bad in [null,true,{},[],"unknown"]:
			var hostile = initial.duplicate(true)
			hostile[field] = bad
			reject_restore(hostile,"hostile entry " + field + " " + str(bad))
	var early = Model.new()
	for action in ["begin_home","home_ticket","home_ritual","home_finish"]:
		reject(early,action,{"home_ticket":"pocket","home_ritual":"neither","home_finish":"sleep"}.get(action))
	var seed = completed_return()
	var prior = seed.snapshot()
	check(seed.apply("begin_home"),"complete return unlocks home")
	if seed.snapshot().campaign_chapter != "still_here":
		finish_checks()
		return
	var arrival = seed.snapshot()
	check(arrival.home_checkpoint == "arrival" and arrival.home == HOME_DEFAULTS and not arrival.campaign_complete,"arrival durable and neutral")
	for fields in [["home_checkpoint"],["home"],["campaign_complete"],["home_checkpoint","home","campaign_complete"]]:
		var old = prior.duplicate(true)
		for field in fields: old.erase(field)
		var compatible = Model.new()
		check(compatible.valid(old) and compatible.restore(old) and compatible.snapshot() == prior,"older schema2 neutral defaults " + str(fields))
	var legacy = initial.duplicate(true)
	for field in legacy.keys():
		if field not in Model.LEGACY_KEYS: legacy.erase(field)
	legacy.schema_version = 1
	var migrated = Model.new()
	check(migrated.restore(legacy) and migrated.snapshot().home == HOME_DEFAULTS and not migrated.snapshot().campaign_complete,"schema1 receives neutral home defaults")
	for field in ["home","home_checkpoint","campaign_complete","history_compatibility"]:
		for bad in [null,true,15,[],"unknown"]:
			if field == "history_compatibility" and typeof(bad) == TYPE_ARRAY: continue
			var malformed = initial.duplicate(true)
			malformed[field] = bad
			reject_restore(malformed,"malformed " + field + " " + str(bad))
	for field in HOME_DEFAULTS:
		var missing = initial.duplicate(true)
		missing.home.erase(field)
		reject_restore(missing,"missing home " + field)
		var malformed = initial.duplicate(true)
		malformed.home[field] = "unknown"
		reject_restore(malformed,"invalid home " + field)
	for field in ["ticket","ritual","ending"]:
		for bad in [null,true,0,[],{}]:
			var malformed = initial.duplicate(true)
			malformed.home[field] = bad
			reject_restore(malformed,"typed home option " + field + " " + str(bad))
	var extra = initial.duplicate(true)
	extra.home.best_ending = true
	reject_restore(extra,"no ranked home ending field")
	var checkpoints = {"arrival":arrival}
	for prior_options in [["take","cart","luck",true],["lend","walk","little",false],["unused","bench","wave",true]]:
		var base = completed_return(prior_options[0],prior_options[1],prior_options[2],prior_options[3]).snapshot()
		for ticket in TICKETS:
			for ritual in RITUALS:
				var endings = []
				for ending in ENDINGS:
					var m = Model.new()
					check(m.restore(base) and m.apply("begin_home"),"begin every home branch")
					m = roundtrip(m,ticket + ritual + ending + "arrival")
					reject(m,"begin_home")
					reject(m,"home_ritual",ritual)
					reject(m,"home_finish",ending)
					for action in ["home_ticket","home_ritual","home_finish"]:
						for bad in [null,true,15,{},[],"unknown"]: reject(m,action,bad)
					check(m.apply("home_ticket",ticket),"remember ticket " + ticket)
					check(m.snapshot().home_checkpoint == "arrival" and m.snapshot().home.ticket == ticket,"ticket placement remembered before ritual")
					m = roundtrip(m,ticket + ritual + ending + "ticket")
					for alternative in TICKETS: reject(m,"home_ticket",alternative)
					reject(m,"home_finish",ending)
					check(m.apply("home_ritual",ritual),"choose ordinary ritual " + ritual)
					check(m.snapshot().home_checkpoint == "settled" and m.snapshot().home.ritual == ritual,"ritual durable")
					m = roundtrip(m,ticket + ritual + ending + "settled")
					for alternative in RITUALS: reject(m,"home_ritual",alternative)
					if prior_options[0] == "lend" and ticket == "drawer" and ritual == "neither" and ending == "sleep":
						checkpoints.settled = m.snapshot()
					check(m.apply("home_finish",ending),"both final choices complete " + ending)
					check(m.snapshot().home_checkpoint == "complete" and m.snapshot().home.completed and m.snapshot().campaign_complete and m.snapshot().home.ending == ending,"final choice is distinct and equally complete")
					m = roundtrip(m,ticket + ritual + ending + "complete")
					endings.append(m.snapshot())
					if prior_options[0] == "lend" and ticket == "drawer" and ritual == "neither" and ending == "sleep": checkpoints.complete = m.snapshot()
					for key in base:
						if key not in ["campaign_chapter","home_checkpoint","home","campaign_complete","choice_history"]: check(m.snapshot()[key] == base[key],"home preserves prior " + key)
					check(m.snapshot().choice_history.slice(0,base.choice_history.size()) == base.choice_history,"prior trace unchanged")
					for action in ["begin_home","home_ticket","home_ritual","home_finish","begin_return","return_conductor","return_jo","return_finish","orchard_finish","fair_departure"]: reject(m,action)
				var train = endings[0].duplicate(true)
				var sleep = endings[1].duplicate(true)
				train.home.ending = "sleep"
				train.choice_history[-1] = "still_here.finish.sleep"
				check(train == sleep,"train and sleep have equal entire save apart from remembered final choice")
	# Capture ticket-only checkpoint separately, before ritual.
	var ticket_only = Model.new()
	check(ticket_only.restore(arrival) and ticket_only.apply("home_ticket","drawer"),"ticket-only checkpoint setup")
	checkpoints.ticket = ticket_only.snapshot()
	for checkpoint in checkpoints:
		var snapshot: Dictionary = checkpoints[checkpoint]
		for key in ["home_checkpoint","home","campaign_complete","history_compatibility","return_checkpoint","return_state","orchard_checkpoint","orchard","kitchen_checkpoint","kitchen","paper_checkpoint","paper"]:
			var missing = snapshot.duplicate(true)
			missing.erase(key)
			reject_restore(missing,"active " + checkpoint + " missing " + key)
		for field in HOME_DEFAULTS:
			var forged = snapshot.duplicate(true)
			forged.home[field] = not forged.home[field] if field == "completed" else "pocket" if field == "ticket" else "tea" if field == "ritual" else "train"
			reject_restore(forged,checkpoint + " inconsistent " + field)
		var forged_completion = snapshot.duplicate(true)
		forged_completion.campaign_complete = not forged_completion.campaign_complete
		reject_restore(forged_completion,checkpoint + " forged campaign completion")
		for id in ["still_here.begin","still_here.ticket.drawer","still_here.ticket.kettle","still_here.ritual.neither","still_here.ritual.tea","still_here.finish.sleep","still_here.finish.train"]:
			var forged = snapshot.duplicate(true)
			if id in forged.choice_history: forged.choice_history.erase(id)
			else: forged.choice_history.append(id)
			reject_restore(forged,checkpoint + " forged trace " + id)
		for chapter in ["return_platform","quiet_orchard","platform_six"]:
			var retagged = snapshot.duplicate(true)
			retagged.campaign_chapter = chapter
			reject_restore(retagged,"home cannot retag " + chapter)
		var crosschapter = snapshot.duplicate(true)
		crosschapter.choice_history.erase("still_here.begin")
		crosschapter.choice_history.push_front("still_here.begin")
		reject_restore(crosschapter,"home must follow return " + checkpoint)
		var incomplete = snapshot.duplicate(true)
		incomplete.return_checkpoint = "departed"
		incomplete.return_state.completed = false
		incomplete.choice_history.erase("return_platform.finish")
		reject_restore(incomplete,"home requires complete return " + checkpoint)
	for previous in ["paper_sky.begin","night_kitchen.begin","quiet_orchard.finish","return_platform.finish"]:
		var reordered = checkpoints.complete.duplicate(true)
		reordered.choice_history.erase(previous)
		reordered.choice_history.push_front(previous)
		reject_restore(reordered,"previous chronology stays valid " + previous)
	for pair in [["paper_sky.begin","paper_sky.finish"],["the_small_fair.begin","the_small_fair.departure.wait"],["platform_six.camera.lend","platform_six.finish"],["platform_six.optional.continue","platform_six.camera.lend"]]:
		var reordered_prior = checkpoints.complete.duplicate(true)
		var a = reordered_prior.choice_history.find(pair[0])
		var b = reordered_prior.choice_history.find(pair[1])
		var old_id = reordered_prior.choice_history[a]
		reordered_prior.choice_history[a] = reordered_prior.choice_history[b]
		reordered_prior.choice_history[b] = old_id
		reject_restore(reordered_prior,"earlier transition chronology " + str(pair))
	for id in ["platform_six.camera.lend","platform_six.optional.continue","platform_six.finish","the_small_fair.begin","the_small_fair.greeting.watch","the_small_fair.race.crooked","the_small_fair.inspect.watch","the_small_fair.level.ada","the_small_fair.race.canonical","the_small_fair.departure.wait"]:
		var missing_prior = checkpoints.complete.duplicate(true)
		missing_prior.choice_history.erase(id)
		reject_restore(missing_prior,"canonical home requires earlier prerequisite " + id)
	for entries in [["paper_sky.begin"],["platform_six.camera.take"],["the_small_fair.begin"],["platform_six.finish","platform_six.finish"]]:
		var false_provenance = checkpoints.complete.duplicate(true)
		false_provenance.history_compatibility = entries
		reject_restore(false_provenance,"forged compatibility trace " + str(entries))
	validate_legacy_history(prior)
	for earlier_id in ["return_platform.jo","return_platform.conductor"]:
		var crossed = checkpoints.complete.duplicate(true)
		crossed.choice_history.append(earlier_id)
		crossed.return_state["jo_met" if earlier_id.ends_with("jo") else "conductor_revealed"] = true
		reject_restore(crossed,"cannot visit previous chapter after entering home " + earlier_id)
	var reordered = checkpoints.complete.duplicate(true)
	var ticket_index = reordered.choice_history.find("still_here.ticket.drawer")
	var ritual_index = reordered.choice_history.find("still_here.ritual.neither")
	var tmp = reordered.choice_history[ticket_index]
	reordered.choice_history[ticket_index] = reordered.choice_history[ritual_index]
	reordered.choice_history[ritual_index] = tmp
	reject_restore(reordered,"ritual cannot precede ticket")
	for rule in [["begin_home",null,"still_here.begin",prior],["home_ticket","drawer","still_here.ticket.drawer",arrival],["home_ritual","neither","still_here.ritual.neither",checkpoints.ticket],["home_finish","sleep","still_here.finish.sleep",checkpoints.settled]]:
		var missing_rule = Model.new()
		check(missing_rule.restore(rule[3]),"missing rule setup " + rule[2])
		missing_rule.rules.choices.erase(rule[2])
		reject(missing_rule,rule[0],rule[1])
	var store = Store.new()
	var backup_path = "user://home_backup_" + str(Time.get_ticks_usec()) + ".json"
	check(store.save_snapshot(checkpoints.settled,backup_path).ok and store.save_snapshot(checkpoints.complete,backup_path).ok,"save final choice with prior settled backup")
	var damaged = FileAccess.open(backup_path,FileAccess.WRITE)
	damaged.store_string("{damaged")
	damaged.close()
	var recovered = store.load_snapshot(backup_path)
	check(recovered.ok and recovered.recovered and recovered.data == checkpoints.settled,"damaged home completion recovers settled checkpoint")
	var absent = checkpoints.complete.duplicate(true)
	absent.last_seen = -999999999
	var unchanged = Model.new()
	check(unchanged.restore(absent) and unchanged.snapshot() == checkpoints.complete,"absence never changes final choice")
	for bad in [false,0,"anything",{},[]]: reject(seed,"begin_home",bad)
	validate_catalog()
	finish_checks()
func finish_campaign_from_platform(m):
	for step in [["begin_fair",null],["fair_greeting","watch"],["release_boat",null],["inspect_fair","watch"],["level_pond","ada"],["release_boat",null],["fair_departure","wait"]]:
		check(m.apply(step[0],step[1]),"legacy fair continuation " + step[0])
	return finish_campaign_from_fair(m)
func finish_campaign_from_fair(m):
	for step in [["begin_paper",null],["paper_greeting",null],["raise_paper",null],["finish_paper",null],["begin_kitchen",null],["kitchen_join","watch"],["kitchen_share","watch"],["kitchen_departure","listen"],["begin_orchard",null],["orchard_route","bench"],["orchard_advance",null],["orchard_advance",null],["orchard_advance",null],["orchard_finish",null],["begin_return",null],["return_arrival",null],["return_farewell","little"],["return_departure",null],["return_finish",null],["begin_home",null],["home_ticket","pocket"],["home_ritual","neither"],["home_finish","sleep"]]:
		check(m.apply(step[0],step[1]),"legacy campaign continuation " + step[0])
	return m
func validate_legacy_history(prior: Dictionary):
	for finished in [false,true]:
		var legacy = {}
		for key in Model.LEGACY_KEYS: legacy[key] = prior[key]
		legacy.schema_version = 1
		if not finished:
			legacy.checkpoint_id = "breakfast"
			legacy.chapter_complete = false
			legacy.chapter_world_flag = false
			legacy.souvenir_ids = []
		var migrated = Model.new()
		check(migrated.restore(legacy),"legacy sparse platform restore " + str(finished))
		if not finished:
			check(migrated.apply("have_breakfast") and migrated.apply("finish"),"legacy sparse optional then new finish")
		migrated = finish_campaign_from_platform(migrated)
		check(migrated.snapshot().campaign_complete,"legacy sparse history can finish campaign")
		migrated = roundtrip(migrated,"legacy_platform_" + str(finished))
		check("platform_six.optional.continue" in migrated.snapshot().get("history_compatibility",[]),"legacy omitted optional remains explicitly grandfathered")
		check(("platform_six.finish" in migrated.snapshot().get("history_compatibility",[])) == finished,"legacy completion provenance accurate")
	var sparse = Model.new().defaults()
	for key in Model.LEGACY_KEYS + ["fair_checkpoint","fair","dimensions","npc_state"]: sparse[key] = prior[key]
	sparse.campaign_chapter = "the_small_fair"
	sparse.choice_history = []
	for id in prior.choice_history:
		if id.begins_with("platform_six.") or id.begins_with("the_small_fair."): sparse.choice_history.append(id)
	for id in ["platform_six.optional.continue","platform_six.finish","the_small_fair.begin"]: sparse.choice_history.erase(id)
	sparse.erase("history_compatibility")
	var compatible = Model.new()
	check(compatible.restore(sparse),"older sparse schema2 fair restores")
	compatible = finish_campaign_from_fair(compatible)
	check(compatible.snapshot().campaign_complete,"older sparse schema2 fair finishes home")
	compatible = roundtrip(compatible,"legacy_fair")
	for id in ["platform_six.optional.continue","platform_six.finish","the_small_fair.begin"]:
		check(id in compatible.snapshot().get("history_compatibility",[]),"older sparse fair provenance " + id)
	var missing_provenance = compatible.snapshot()
	missing_provenance.erase("history_compatibility")
	reject_restore(missing_provenance,"active home cannot invent legacy provenance")
func validate_catalog():
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/home_choices.json"))
	check(Model.new().validate_choice_catalog(catalog),"home catalog valid")
	check(catalog.choices.size() == 9,"nine home traces")
	for choice in catalog.choices:
		check(choice.consequences == {"dimensions":{},"npc":{}},"home consequence neutral " + choice.choice_id)
	var scored = catalog.duplicate(true)
	scored.choices[-1].consequences.dimensions.future_pull = 1
	check(not Model.new().validate_choice_catalog(scored),"final choice cannot gain future pull")
	var npc_score = catalog.duplicate(true)
	npc_score.choices[-1].consequences.npc.mira = {"connection":1}
	check(not Model.new().validate_choice_catalog(npc_score),"final choice cannot gain NPC ranking")
func finish_checks():
	print("Home model checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
