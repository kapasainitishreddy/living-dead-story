extends SceneTree
const Model = preload("res://core/chapter_model.gd")
const Kitchen = preload("res://tests/kitchen_model.gd")
const Store = preload("res://core/save_store.gd")
const RETURN_DEFAULTS = {"farewell":"unselected","conductor_revealed":false,"jo_met":false,"completed":false}
const FAREWELLS = ["luck","joke","thanks","wave","little"]
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
func completed_orchard(camera: String = "lend", route: String = "bench"):
	var helper = Kitchen.new()
	var m = helper.completed_paper(camera)
	check(helper.failures == 0,"prior chapters setup valid")
	helper.free()
	for step in [["begin_kitchen",null],["kitchen_join","watch"],["kitchen_share","watch"],["kitchen_departure","listen"],["begin_orchard",null],["orchard_route",route],["orchard_advance",null],["orchard_advance",null],["orchard_advance",null],["orchard_finish",null]]:
		check(m.apply(step[0],step[1]),"prior orchard setup " + step[0])
	return m
func roundtrip(m, label: String):
	var before = m.snapshot()
	var resumed = Model.new()
	check(resumed.restore(JSON.parse_string(JSON.stringify(before))) and resumed.snapshot() == before,"JSON interruption resume " + label)
	var store = Store.new()
	var path = "user://return_model_" + label + "_" + str(Time.get_ticks_usec()) + ".json"
	check(store.save_snapshot(before,path).ok,"native save " + label)
	var loaded = store.load_snapshot(path)
	check(loaded.ok and loaded.data == before,"native reload exact " + label)
	return resumed
func _initialize():
	var initial = Model.new().snapshot()
	check(initial.get("return_checkpoint") == "locked","return defaults locked")
	check(initial.get("return_state") == RETURN_DEFAULTS,"return defaults exact neutral")
	var early = Model.new()
	for action in ["begin_return","return_arrival","return_farewell","return_departure","return_finish","return_conductor","return_jo"]:
		reject(early,action,"luck" if action == "return_farewell" else null)
	var seed = completed_orchard()
	var prior = seed.snapshot()
	check(seed.apply("begin_return"),"completed orchard unlocks return arrival")
	if seed.snapshot().campaign_chapter != "return_platform":
		finish_checks()
		return
	check(seed.snapshot().return_checkpoint == "arrival" and seed.snapshot().return_state == RETURN_DEFAULTS,"arrival durable and neutral")
	var old = prior.duplicate(true)
	old.erase("return_checkpoint")
	old.erase("return_state")
	var old_model = Model.new()
	check(old_model.valid(old) and old_model.restore(old) and old_model.snapshot() == prior,"older schema2 receives neutral return defaults")
	for key in ["return_checkpoint","return_state"]:
		var partial = prior.duplicate(true)
		partial.erase(key)
		var compatible = Model.new()
		check(compatible.valid(partial) and compatible.restore(partial) and compatible.snapshot() == prior,"inactive return field normalizes independently " + key)
	for field in ["return_checkpoint","return_state"]:
		for bad in [null,true,15,[],"unknown"]:
			var malformed = initial.duplicate(true)
			malformed[field] = bad
			reject_restore(malformed,"malformed " + field)
	for field in RETURN_DEFAULTS:
		var missing = initial.duplicate(true)
		missing.return_state.erase(field)
		reject_restore(missing,"missing return " + field)
	var extra = initial.duplicate(true)
	extra.return_state.earned_departure = true
	reject_restore(extra,"unrequested earning field")
	var checkpoints = {"arrival":seed.snapshot()}
	var ready = Model.new()
	check(ready.restore(prior) and ready.apply("begin_return") and ready.apply("return_arrival"),"unselected farewell setup")
	ready = roundtrip(ready,"ready")
	checkpoints.ready = ready.snapshot()
	for camera in ["take","lend","unused"]:
		for route in ["cart","walk","bench"]:
			var base = completed_orchard(camera,route).snapshot()
			for farewell in FAREWELLS:
				for extras in [0,1,2,3]:
					var m = Model.new()
					check(m.restore(base),"prior branch restore")
					check(m.apply("begin_return"),"begin return branch")
					reject(m,"begin_return")
					reject(m,"return_farewell",farewell)
					reject(m,"return_departure")
					reject(m,"return_finish")
					if extras & 1:
						check(m.apply("return_conductor"),"optional conductor reveal arrival")
						reject(m,"return_conductor")
						m = roundtrip(m,camera + route + farewell + str(extras) + "conductor")
					check(m.apply("return_arrival"),"arrival reaches farewell")
					reject(m,"return_arrival")
					reject(m,"return_departure")
					for bad in [null,true,15,{},[],"unknown"]: reject(m,"return_farewell",bad)
					check(m.apply("return_farewell",farewell),"select farewell " + farewell)
					check(m.snapshot().return_checkpoint == "farewell" and m.snapshot().return_state.farewell == farewell,"selected farewell remains durable before departure")
					for alternative in FAREWELLS: reject(m,"return_farewell",alternative)
					m = roundtrip(m,camera + route + farewell + str(extras) + "selected")
					if extras & 2:
						check(m.apply("return_jo"),"optional Jo after farewell selection")
						reject(m,"return_jo")
						m = roundtrip(m,camera + route + farewell + str(extras) + "jo")
					if camera == "lend" and route == "bench" and farewell == "wave" and extras == 3: checkpoints.farewell = m.snapshot()
					check(m.apply("return_departure"),"Mira leaves on every farewell")
					check(m.snapshot().return_checkpoint == "departed" and not m.snapshot().return_state.completed,"departure checkpoint precedes completion")
					m = roundtrip(m,camera + route + farewell + str(extras) + "departed")
					if camera == "lend" and route == "bench" and farewell == "wave" and extras == 3: checkpoints.departed = m.snapshot()
					for action in ["return_departure","return_arrival","return_farewell"]: reject(m,action)
					check(m.apply("return_finish"),"deterministic finish after departure")
					m = roundtrip(m,camera + route + farewell + str(extras) + "complete")
					if camera == "lend" and route == "bench" and farewell == "wave" and extras == 3: checkpoints.complete = m.snapshot()
					check(m.snapshot().return_state == {"farewell":farewell,"conductor_revealed":bool(extras & 1),"jo_met":bool(extras & 2),"completed":true},"distinct farewell and optional visits persist")
					for key in base:
						if key not in ["campaign_chapter","return_checkpoint","return_state","choice_history"]: check(m.snapshot()[key] == base[key],"preserve prior " + key)
					check(m.snapshot().npc_state.mira.destination == "lower_mill" and m.snapshot().npc_state.mira.independent_decision,"Lower Mill autonomy stays independent")
					for action in ["begin_return","return_arrival","return_farewell","return_departure","return_finish","begin_orchard","orchard_finish"]: reject(m,action)
					if extras & 1: reject(m,"return_conductor")
					if extras & 2: reject(m,"return_jo")
	for checkpoint in checkpoints:
		var snapshot: Dictionary = checkpoints[checkpoint]
		for key in ["return_checkpoint","return_state","orchard_checkpoint","orchard","kitchen_checkpoint","kitchen","paper_checkpoint","paper"]:
			var missing = snapshot.duplicate(true)
			missing.erase(key)
			reject_restore(missing,"active " + checkpoint + " missing " + key)
		for field in RETURN_DEFAULTS:
			var forged = snapshot.duplicate(true)
			forged.return_state[field] = "luck" if field == "farewell" and forged.return_state[field] == "unselected" else "unselected" if field == "farewell" else not forged.return_state[field]
			reject_restore(forged,checkpoint + " inconsistent " + field)
		for id in ["return_platform.begin","return_platform.arrival","return_platform.farewell.wave","return_platform.farewell.luck","return_platform.conductor","return_platform.jo","return_platform.departure","return_platform.finish"]:
			var forged = snapshot.duplicate(true)
			if id in forged.choice_history: forged.choice_history.erase(id)
			else: forged.choice_history.append(id)
			reject_restore(forged,checkpoint + " forged trace " + id)
		var retagged = snapshot.duplicate(true)
		retagged.campaign_chapter = "quiet_orchard"
		reject_restore(retagged,"return cannot retag " + checkpoint)
		var crosschapter = snapshot.duplicate(true)
		crosschapter.choice_history.erase("return_platform.begin")
		crosschapter.choice_history.push_front("return_platform.begin")
		reject_restore(crosschapter,"return must follow prior trace " + checkpoint)
		var early_orchard = snapshot.duplicate(true)
		early_orchard.orchard_checkpoint = "rest"
		early_orchard.orchard.completed = false
		early_orchard.choice_history.erase("quiet_orchard.finish")
		reject_restore(early_orchard,"return needs complete orchard " + checkpoint)
	var reordered = checkpoints.complete.duplicate(true)
	var start = reordered.choice_history.find("return_platform.arrival")
	var selected = reordered.choice_history.find("return_platform.farewell.wave")
	var tmp = reordered.choice_history[start]
	reordered.choice_history[start] = reordered.choice_history[selected]
	reordered.choice_history[selected] = tmp
	reject_restore(reordered,"return selected farewell chronology")
	var moved_orchard = checkpoints.complete.duplicate(true)
	moved_orchard.choice_history.erase("quiet_orchard.finish")
	moved_orchard.choice_history.push_front("quiet_orchard.finish")
	reject_restore(moved_orchard,"earlier orchard chronology remains strict")
	for earlier in ["paper_sky.","night_kitchen."]:
		var moved = checkpoints.complete.duplicate(true)
		var chunk = []
		for id in moved.choice_history:
			if id.begins_with(earlier): chunk.append(id)
		for id in chunk: moved.choice_history.erase(id)
		moved.choice_history = chunk + moved.choice_history
		reject_restore(moved,"earlier chapter cannot precede its prerequisites " + earlier)
	for visit_order in [["return_conductor","return_jo"],["return_jo","return_conductor"]]:
		var late = Model.new()
		check(late.restore(prior),"late visits restore prior")
		for step in [["begin_return",null],["return_arrival",null],["return_farewell","little"],["return_departure",null]]: check(late.apply(step[0],step[1]),"late visit setup " + step[0])
		for action in visit_order:
			check(late.apply(action),"optional visit remains available after departure " + action)
			late = roundtrip(late,"late_" + action)
			reject(late,action)
		check(late.apply("return_finish"),"late visits allow finish")
	for visit_order in [["return_conductor","return_jo"],["return_jo","return_conductor"]]:
		var settled = Model.new()
		check(settled.restore(prior),"complete optional visit restore prior")
		for step in [["begin_return",null],["return_arrival",null],["return_farewell","wave"],["return_departure",null],["return_finish",null]]: check(settled.apply(step[0],step[1]),"complete optional visit setup " + step[0])
		var completion = settled.snapshot()
		check(completion.return_state.completed and not completion.return_state.conductor_revealed and not completion.return_state.jo_met,"completion valid with both optional conversations absent")
		settled = roundtrip(settled,"complete_unvisited")
		for action in visit_order:
			var field = "conductor_revealed" if action == "return_conductor" else "jo_met"
			var id = "return_platform." + action.trim_prefix("return_")
			var forged_flag = settled.snapshot()
			forged_flag.return_state[field] = true
			reject_restore(forged_flag,"complete optional flag requires trace " + action)
			var forged_trace = settled.snapshot()
			forged_trace.choice_history.append(id)
			reject_restore(forged_trace,"complete optional trace requires flag " + action)
			check(settled.apply(action),"first optional visit accepted at complete " + action)
			check(settled.snapshot().return_state[field],"complete optional visit durable " + action)
			check(settled.snapshot().return_checkpoint == "complete" and settled.snapshot().return_state.completed,"optional visit preserves terminal completion " + action)
			settled = roundtrip(settled,"complete_" + action)
			reject(settled,action)
			var duplicate = settled.snapshot()
			duplicate.choice_history.append(id)
			reject_restore(duplicate,"complete optional duplicate trace " + action)
			var premature = settled.snapshot()
			premature.choice_history.erase(id)
			premature.choice_history.push_front(id)
			reject_restore(premature,"complete optional visit cannot precede return " + action)
		for key in completion:
			if key not in ["return_state","choice_history"]: check(settled.snapshot()[key] == completion[key],"complete optional visits preserve " + key)
		for action in ["begin_return","return_arrival","return_farewell","return_departure","return_finish","return_conductor","return_jo"]: reject(settled,action)
	for rule in [["begin_return",null,"return_platform.begin",prior],["return_arrival",null,"return_platform.arrival",checkpoints.arrival],["return_farewell","thanks","return_platform.farewell.thanks",checkpoints.ready],["return_departure",null,"return_platform.departure",checkpoints.farewell],["return_finish",null,"return_platform.finish",checkpoints.departed],["return_conductor",null,"return_platform.conductor",checkpoints.arrival],["return_jo",null,"return_platform.jo",checkpoints.arrival]]:
		var missing_rule = Model.new()
		check(missing_rule.restore(rule[3]),"missing rule setup " + rule[2])
		missing_rule.rules.choices.erase(rule[2])
		reject(missing_rule,rule[0],rule[1])
	var store = Store.new()
	var backup_path = "user://return_backup_" + str(Time.get_ticks_usec()) + ".json"
	check(store.save_snapshot(checkpoints.departed,backup_path).ok,"save departed before completion backup")
	check(store.save_snapshot(checkpoints.complete,backup_path).ok,"save return completion with backup")
	var damaged = FileAccess.open(backup_path,FileAccess.WRITE)
	damaged.store_string("{damaged")
	damaged.close()
	var recovered = store.load_snapshot(backup_path)
	check(recovered.ok and recovered.recovered and recovered.data == checkpoints.departed,"damaged completion recovers exact departed state")
	var absence = checkpoints.complete.duplicate(true)
	absence.last_seen = -999999999
	var absent = Model.new()
	check(absent.restore(absence) and absent.snapshot() == checkpoints.complete,"absence never changes the saved farewell")
	for action in ["begin_return","return_arrival","return_departure","return_finish","return_conductor","return_jo"]:
		for value in [false,0,"anything",{},[]]: reject(seed,action,value)
	validate_authored()
	finish_checks()
func validate_authored():
	check(FileAccess.file_exists("res://data/return.json"),"return authored data exists")
	if not FileAccess.file_exists("res://data/return.json"): return
	var authored = JSON.parse_string(FileAccess.get_file_as_string("res://data/return.json"))
	check(authored.chapter_id == "return_platform","authored return identity")
	check(Model.new().validate_choice_catalog(authored),"return neutral catalog valid")
	check(authored.choices.size() == 11,"eleven distinct return traces")
	for choice in authored.choices:
		check(choice.consequences == {"dimensions":{},"npc":{}},"return neutral consequence " + choice.choice_id)
		var bad = authored.duplicate(true)
		bad.choices[0].consequences.dimensions.connection = 1
		check(not Model.new().validate_choice_catalog(bad),"return does not score connection")
	var callbacks = []
	for farewell in FAREWELLS:
		check(authored.farewell_callbacks.has(farewell) and not authored.farewell_callbacks[farewell].is_empty(),"authored farewell callback " + farewell)
		callbacks.append(authored.farewell_callbacks[farewell])
	var unique = {}
	for callback in callbacks: unique[callback] = true
	check(callbacks.size() == 5 and unique.size() == 5,"all five farewell responses distinct")
	for camera in ["take","lend","unused"]: check(authored.camera_callbacks.has(camera) and not authored.camera_callbacks[camera].is_empty(),"camera callback " + camera)
	check(authored.dialogues.return_conductor.text.contains("passenger"),"conductor was once a passenger")
func finish_checks():
	print("Return model checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
