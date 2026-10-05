extends SceneTree
const Model = preload("res://core/chapter_model.gd")
const Kitchen = preload("res://tests/kitchen_model.gd")
const Store = preload("res://core/save_store.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func reject(m, action: String, value: Variant = null):
	var before = m.snapshot()
	check(not m.apply(action,value) and m.snapshot() == before,"atomic rejection " + action)
func _initialize():
	var helper = Kitchen.new()
	var m = helper.completed_paper()
	for step in [["begin_kitchen",null],["kitchen_join","watch"],["kitchen_share","watch"],["kitchen_departure","listen"]]: check(m.apply(step[0],step[1]),"kitchen setup")
	helper.free()
	var prior = m.snapshot()
	check(prior.get("orchard_checkpoint") == "locked", "default locked")
	check(prior.get("orchard") == {"route":"unselected","beat":0,"completed":false},"neutral orchard")
	var old = prior.duplicate(true)
	old.erase("orchard")
	old.erase("orchard_checkpoint")
	check(Model.new().restore(old), "old schema2 migrates orchard neutrally")
	for route in ["cart","walk","bench"]:
		var branch = Model.new()
		check(branch.restore(prior),"prior restore")
		check(branch.apply("begin_orchard"),"begin orchard")
		reject(branch,"orchard_advance")
		reject(branch,"orchard_finish")
		for bad in [null, true, 4, {}, [], "unknown"]: reject(branch,"orchard_route",bad)
		check(branch.apply("orchard_route",route),"equal route " + route)
		reject(branch,"orchard_route",route)
		for beat in range(1,4):
			reject(branch,"orchard_advance",beat)
			check(branch.apply("orchard_advance"),"manual beat " + str(beat))
			check(branch.snapshot().orchard.beat == beat,"durable beat")
			var reopened = Model.new()
			check(reopened.restore(JSON.parse_string(JSON.stringify(branch.snapshot()))) and reopened.snapshot() == branch.snapshot(),"exact beat resume")
			var store = Store.new()
			var path = "user://orchard_" + route + "_" + str(beat) + "_" + str(Time.get_ticks_usec()) + ".json"
			check(store.save_snapshot(branch.snapshot(),path).ok,"native save beat")
			var loaded = store.load_snapshot(path)
			check(loaded.ok and loaded.data == branch.snapshot(),"native load exact beat")
			branch = reopened
			if beat < 3: reject(branch,"orchard_finish")
		reject(branch,"orchard_advance")
		check(branch.apply("orchard_finish"),"complete route " + route)
		check(branch.snapshot().orchard == {"route":route,"beat":3,"completed":true},"equal completion")
		for key in prior:
			if key not in ["campaign_chapter","orchard_checkpoint","orchard","choice_history"]: check(branch.snapshot()[key] == prior[key],"preserve " + key)
		for action in ["begin_orchard","orchard_route","orchard_advance","orchard_finish","begin_kitchen"]: reject(branch,action)
		var complete = branch.snapshot()
		for field in ["route","beat","completed"]:
			var forged = complete.duplicate(true)
			forged.orchard[field] = {"route":"unselected","beat":2,"completed":false}[field]
			check(not Model.new().restore(forged),"reject forged " + field)
		for field in ["orchard","orchard_checkpoint"]:
			var missing = complete.duplicate(true)
			missing.erase(field)
			check(not Model.new().restore(missing),"reject active missing " + field)
		var reordered = complete.duplicate(true)
		var index = reordered.choice_history.find("quiet_orchard.begin")
		var temp = reordered.choice_history[index]
		reordered.choice_history[index] = reordered.choice_history[index+1]
		reordered.choice_history[index+1] = temp
		check(not Model.new().restore(reordered),"chronology enforced")
		var crosschapter = complete.duplicate(true)
		crosschapter.choice_history.erase("quiet_orchard.begin")
		crosschapter.choice_history.push_front("quiet_orchard.begin")
		check(not Model.new().restore(crosschapter),"orchard trace follows completed prior chapters")
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/choices.json"))
	check(Model.new().validate_choice_catalog(catalog),"orchard catalog valid")
	var count := 0
	for authored in catalog.choices:
		if authored.campaign_chapter != "quiet_orchard": continue
		count += 1
		check(authored.consequences == {"dimensions":{},"npc":{}},"orchard consequence neutral")
		var bad_catalog = catalog.duplicate(true)
		for altered in bad_catalog.choices:
			if altered.choice_id == authored.choice_id: altered.consequences.dimensions.agency = 1
		check(not Model.new().validate_choice_catalog(bad_catalog),"reject orchard scoring")
	check(count == 8,"eight unique orchard traces")
	var locked = Model.new()
	for action in ["begin_orchard","orchard_route","orchard_advance","orchard_finish"]: reject(locked,action)
	print("Orchard model checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
