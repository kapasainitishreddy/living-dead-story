extends SceneTree
var checks := 0
var failures := 0
var Model: Script
var Store: Script
const IDS = ["rain_town", "unsent_letters_library", "arcade", "beach_before_sunrise", "winter_orchard", "rest_room", "failed_things_festival", "sunrise_cafe", "no_destination_road", "fireflies"]
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func reject(m, action: String, value: Variant = null):
	var before = m.snapshot()
	check(not m.apply(action, value) and m.snapshot() == before, "atomic action rejection " + action + " " + str(value))
func reject_restore(m, value: Variant, label: String):
	var before = m.snapshot()
	check(not m.valid(value), "validator rejects " + label)
	check(not m.restore(value) and m.snapshot() == before, "restore rejects atomically " + label)
func write_json(path: String, value: Variant):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()
func _initialize():
	check(FileAccess.file_exists("res://core/journey_model.gd"), "Journey model exists")
	check(FileAccess.file_exists("res://core/journey_store.gd"), "Separate journey store exists")
	if failures:
		finish_checks()
		return
	Model = load("res://core/journey_model.gd")
	Store = load("res://core/journey_store.gd")
	var fixture_path = "user://journey_fixture.json"
	var fixture = {"schema_version":1,"destinations":[]}
	for id in IDS:
		fixture.destinations.append({"journey_id":id,"npc":"Mira" if id == "rain_town" else "Ada", "possible_cast":["Mira","Ada"],"story_nodes":["Arrival","Visit","Return"],"local_scene_states":{"as_found":"A place.","choice_a":"A changed place.","choice_b":"A quiet place."},"choice_nodes":[{"choice_id":id + ".leave_light","label":"Leave a light","response":"The light stays.","state_id":"choice_a"}]})
	write_json(fixture_path, fixture)
	var m = Model.new(fixture_path)
	var initial = m.snapshot()
	check(initial.get("schema_version") == 1 and initial.get("mode") == "train", "neutral standalone train schema1")
	check(not initial.has("settings") and not initial.has("dimensions") and not initial.has("npc_state"), "campaign preferences and fictional weights stay separate")
	check(m.valid(initial) and m.restore(JSON.parse_string(JSON.stringify(initial))), "default exact JSON roundtrip")
	check(m.destinations().size() == 10 and m.current_destination().is_empty(), "ten authored destinations with no active arrival")
	var leaked = m.destinations()
	leaked[0].journey_id = "changed"
	check(m.destinations()[0].journey_id == "rain_town", "authored catalog defensive copy")
	for id in IDS:
		check(m.apply("board", id), "board " + id)
		check(m.snapshot().mode == "destination" and m.current_destination().journey_id == id, "active authored destination " + id)
		check(m.snapshot().stage == 0, "new destination starts stage0 " + id)
		check(m.apply("choose", id + ".leave_light") and m.snapshot().location_states[id] == "choice_a", "authored place choice remembered " + id)
		reject(m, "choose", "foreign.choice")
		check(m.apply("activity", {"step":2,"selection":7,"progress":400,"done":true}), "live activity persists " + id)
		var activity = m.snapshot()
		var resumed = Model.new(fixture_path)
		check(resumed.restore(JSON.parse_string(JSON.stringify(activity))) and resumed.snapshot() == activity, "activity exact interruption resume " + id)
		check(m.apply("advance") and m.snapshot().stage == 1, "first authored node " + id)
		check(m.apply("return_train") and m.snapshot().mode == "train", "train always accessible " + id)
		check(m.apply("board", id) and m.snapshot().stage == 1 and m.snapshot().activity == activity.activity, "board resumes partial authored visit " + id)
		check(m.apply("advance") and m.apply("advance") and m.snapshot().stage == 3, "all authored nodes reachable " + id)
		reject(m, "advance")
		check(m.apply("finish") and m.snapshot().mode == "train" and m.snapshot().visits[id] == 1, "complete visit returns to train " + id)
		reject(m, "finish")
		check(m.apply("board", id) and m.snapshot().stage == 0, "revisit begins new story " + id)
		check(m.apply("finish") and m.snapshot().visits[id] == 2, "leaving early is equal completed visit " + id)
	check(m.snapshot().npc_visits.get("Mira") == 2 and m.snapshot().npc_visits.get("Ada") == 18, "recurring fictional cast visit counts")
	check(m.snapshot().train_details.size() == 10, "train holds bounded unique place details")
	check(m.apply("board", "rain_town") and m.apply("advance") and m.apply("activity", {"selection":5}), "pause first destination")
	check(m.apply("return_train") and m.apply("board", "arcade") and m.apply("advance"), "switch destination without losing first")
	check(m.apply("home") and m.snapshot().mode == "home" and m.apply("return_train"), "home is reachable without campaign mutation")
	check(m.apply("board", "rain_town") and m.snapshot().stage == 1 and m.snapshot().activity == {"selection":5}, "per-place checkpoint survives travel and home")
	var active = m.snapshot()
	check(m.restore(active), "valid resumed active snapshot")
	for bad in [null,true,[],"bad",999]: reject_restore(m,bad,"wrong snapshot type")
	for key in initial:
		var hostile = active.duplicate(true)
		hostile[key] = null
		reject_restore(m, hostile, "null " + key)
		var missing = active.duplicate(true)
		missing.erase(key)
		reject_restore(m, missing, "missing " + key)
	for field in ["schema_version", "stage"]:
		for bad in [true, "1", 1.5, -1, 999999999]:
			var hostile = active.duplicate(true)
			hostile[field] = bad
			reject_restore(m,hostile,"strict number " + field)
	for key in ["settings", "wellbeing", "last_seen", "reward"]:
		var extra = active.duplicate(true)
		extra[key] = 999
		reject_restore(m, extra, "unknown profiling or campaign field " + key)
	for bad in [null, true, {}, [], "unknown"]: reject(m, "board", bad)
	for bad in [null, true, [], {"step":-1}, {"selection":32}, {"progress":1.5}, {"done":1}, {"text":"derived"}, {"step":1000000000}]: reject(m, "activity", bad)
	for action in ["advance", "finish", "return_train", "home"]: reject(m, action, false)
	check(m.apply("return_train"), "return after hostile input remains possible")
	reject(m, "activity", {"step":1})
	reject(m, "advance")
	verify_writing(m)
	verify_nested_hostility(m)
	var generated = Model.new(fixture_path)
	check(generated.apply("tiny_create",{"text":"First actual words"}),"Tiny Tomorrow can generate local deterministic ID")
	check(generated.apply("tiny_create",{"text":"Second actual words"}),"second generated Tiny Tomorrow ID")
	if generated.snapshot().tiny_tomorrows.size() == 2:
		check(generated.snapshot().tiny_tomorrows[0].id == "tiny_1" and generated.snapshot().tiny_tomorrows[1].id == "tiny_2","stable unique Tiny Tomorrow IDs")
	check(generated.apply("echo_create",{"text":"Later actual words","due_local":"2026-10-04 08:00","created_local":"2026-10-03 22:00"}),"Echo can generate local deterministic ID")
	if not generated.snapshot().future_echoes.is_empty(): check(generated.snapshot().future_echoes[0].id == "echo_1","stable local echo ID")
	verify_store(m, fixture_path)
	var campaign = {"camera_choice":"lend", "fair":{"rudder":"left","sail":"folded","mode":"watch"}, "paper":{"layout":"leaf_star_boat","fold":"enough"}, "home":{"ending":"sleep"},"npc_state":{"mira":{"destination":"lower_mill"}},"return_state":{"farewell":"thanks"}}
	var campaign_before = campaign.duplicate(true)
	var journey_before = m.snapshot()
	var lines = m.callback(campaign)
	check(typeof(lines) == TYPE_ARRAY and lines.size() > 0, "authored campaign callbacks available")
	check("Lower Mill" in " ".join(lines) and "thank" in " ".join(lines),"callback remembers Mira independent plan and farewell")
	check(lines.any(func(line): return line.begins_with("Mira") and "thank" in line) and not "conductor" in " ".join(lines),"farewell callback belongs to Mira")
	var unused = campaign.duplicate(true)
	unused.camera_choice = "unused"
	check("unopened camera" in " ".join(m.callback(unused)),"unused camera continuity keeps actual unopened prop")
	var completed_optional = campaign.duplicate(true)
	completed_optional["action_resolution"] = "completed"
	var skipped_optional = campaign.duplicate(true)
	skipped_optional["action_resolution"] = "skipped"
	check(m.callback(completed_optional) == m.callback(skipped_optional),"NPC callbacks never expose optional actual-world completion")
	check(not "New actual words" in " ".join(lines) and not "You'll know" in " ".join(lines),"private Tiny Tomorrow and Echo words never enter NPC callbacks")
	check(campaign == campaign_before and m.snapshot() == journey_before, "callbacks never mutate either save")
	check(m.callback({}).is_empty() and m.callback(null).is_empty(), "hostile or absent campaign callback stays neutral")
	var authored = Model.new()
	check(authored.destinations().size() == 10,"actual authored pack loads into standalone model")
	for destination in authored.destinations():
		check(authored.apply("board",destination.journey_id),"actual pack boards " + destination.journey_id)
		for choice in destination.choice_nodes:
			check(authored.apply("choose",choice.choice_id) and authored.snapshot().location_states[destination.journey_id] == choice.state_id,"actual authored choice " + choice.choice_id)
		check(authored.apply("return_train"),"actual pack returns without completing " + destination.journey_id)
		check(authored.restore(JSON.parse_string(JSON.stringify(authored.snapshot()))),"actual content state JSON roundtrip " + destination.journey_id)
	var empty_pack_path = "user://journey_pack_bad.json"
	write_json(empty_pack_path, {"destinations":[{"journey_id":"../../oops"}]})
	var bad_pack = Model.new(empty_pack_path)
	check(bad_pack.destinations().is_empty() and bad_pack.valid(bad_pack.snapshot()), "bad content catalog fails closed with usable train defaults")
	reject(bad_pack,"board", "../../oops")
	finish_checks()
func verify_nested_hostility(m):
	var original = m.snapshot()
	var variants = []
	for field in ["visits","npc_visits","location_states","resumable"]:
		for bad in [true, 1, "bad", [], null]:
			var corrupt = original.duplicate(true)
			corrupt[field] = bad
			variants.append([corrupt,field + " wrong map type"])
	for bad in [true, "2", 1.5, -1, 1000001, INF, NAN, {}]:
		var corrupt = original.duplicate(true)
		corrupt.visits["rain_town"] = bad
		variants.append([corrupt,"strict visit counter"])
	for field in ["visits","location_states","resumable"]:
		var corrupt = original.duplicate(true)
		corrupt[field]["foreign_place"] = 1
		variants.append([corrupt,field + " foreign place"])
	var npc = original.duplicate(true)
	npc.npc_visits["Real player diagnosis"] = 1
	variants.append([npc,"unrecognized fictional NPC"])
	for invalid in [{"stage":4,"activity":{}},{"stage":0,"activity":{"selection":32}},{"stage":0},{"stage":0,"activity":{},"reward":5}]:
		var corrupt = original.duplicate(true)
		corrupt.resumable["rain_town"] = invalid
		variants.append([corrupt,"malformed per-place checkpoint"])
	for field in ["tiny_tomorrows","future_echoes"]:
		for bad in [true, {}, "bad", null]:
			var corrupt = original.duplicate(true)
			corrupt[field] = bad
			variants.append([corrupt,field + " wrong list type"])
		var duplicate = original.duplicate(true)
		duplicate[field].append(duplicate[field][0].duplicate(true))
		variants.append([duplicate,field + " duplicate or overflow"])
		for key in duplicate[field][0]:
			var corrupt = original.duplicate(true)
			corrupt[field][0][key] = null
			variants.append([corrupt,field + " null record " + key])
		var extra = original.duplicate(true)
		extra[field][0]["inferred_mood"] = "good"
		variants.append([extra,field + " extra inference field"])
	for invalid in [["rain_town","rain_town"], ["foreign_place"], [true]]:
		var corrupt = original.duplicate(true)
		corrupt.train_details = invalid
		variants.append([corrupt,"unrecognized or duplicate train detail"])
	for pair in variants: reject_restore(m,pair[0],pair[1])
	var leaked = m.snapshot()
	leaked.tiny_tomorrows[0].text = "changed outside model"
	check(m.snapshot() == original,"snapshot defensive copy protects private writing")
	var echoes = m.due_echoes("2030-01-01 00:00")
	if not echoes.is_empty(): echoes[0].text = "changed outside model"
	check(m.snapshot() == original,"due echo read-only results protect private writing")
func verify_writing(m):
	var words = "  The kettle,\nwhen there's time.  "
	check(m.apply("tiny_create", {"id":"tomorrow_1","text":words}), "create optional Tiny Tomorrow")
	check(m.snapshot().tiny_tomorrows[0] == {"id":"tomorrow_1","text":words,"state":"SOMEDAY"}, "Tiny Tomorrow preserves actual unmodified words")
	for state in ["HAPPENED", "NOT ANYMORE", "SOMEDAY"]:
		check(m.apply("tiny_change", {"id":"tomorrow_1","state":state}), "all Tiny Tomorrow states equally reachable " + state)
		check(m.snapshot().tiny_tomorrows[0].text == words, "state changes preserve actual words")
	for value in [null,{}, {"id":"tomorrow_1","text":"duplicate"}, {"id":"bad","text":" "}, {"id":"bad","text":"x".repeat(1001)}, {"id":"bad","text":42}, {"id":"bad","text":"a","score":9}]: reject(m,"tiny_create",value)
	for value in [{"id":"absent","state":"HAPPENED"}, {"id":"tomorrow_1","state":"FAILED"}, {"id":"tomorrow_1","state":1}, {"id":"tomorrow_1","text":"edit without state"}]: reject(m,"tiny_change",value)
	reject(m,"tiny_change", {"id":"tomorrow_1","state":"SOMEDAY","text":"Rewritten words"})
	check(m.snapshot().tiny_tomorrows[0].text == words,"Tiny Tomorrow words immutable through state changes")
	for n in range(1,32): check(m.apply("tiny_create", {"id":"tiny_" + str(n),"text":"Words"}), "bounded Tiny Tomorrow record " + str(n))
	reject(m, "tiny_create", {"id":"overflow","text":"Words"})
	var echo_words = "  You'll know what this meant.\nNo need to prove it.  "
	check(m.apply("echo_create", {"id":"echo_1","text":echo_words,"due_local":"2026-10-04 08:00","created_local":"2026-10-03 22:00"}), "create optional local echo")
	check(m.snapshot().future_echoes[0].text == echo_words and not m.snapshot().future_echoes[0].delivered, "echo preserves unmodified words without automatic delivery")
	check(m.due_echoes("2026-10-04 07:59").is_empty() and m.due_echoes("2026-10-04 08:00").size() == 1, "due echo uses explicit local datetime only")
	var before = m.snapshot()
	check(m.apply("home") and m.apply("return_train"), "returning after absence needs no real clock")
	check(m.snapshot().future_echoes == before.future_echoes and m.snapshot().tiny_tomorrows == before.tiny_tomorrows, "absence causes no decay or penalties")
	check(m.due_echoes("2027-12-31 23:59").size() == 1 and m.apply("resolve_echoes","2027-12-31 23:59"), "past due echo available on explicit return resolution")
	check(m.snapshot().future_echoes[0].delivered and m.due_echoes("2027-12-31 23:59").is_empty(), "local delivered marker suppresses repeats")
	check(m.snapshot().future_echoes[0].text == echo_words, "delivery does not rewrite words")
	for date in ["2026-02-29 10:00", "2026-04-31 10:00", "2026-10-04 24:00", "2026-10-04 08:60", "2026-1-04 08:00", "2026-10-04T08:00Z", "bad"]:
		reject(m,"echo_create",{"id":"bad_echo","text":"Words","due_local":date,"created_local":"2026-10-03 22:00"})
		reject(m,"resolve_echoes",date)
		check(m.due_echoes(date).is_empty(),"bad datetime never resolves echoes")
	for value in [null, {}, {"id":"echo_1","text":"duplicate","due_local":"2026-10-04 08:00","created_local":"2026-10-03 22:00"}, {"id":"bad_echo","text":"Words","due_local":"2026-10-04 08:00","created_local":"2026-10-03 22:00","delivered":true}]: reject(m,"echo_create",value)
	check(m.apply("echo_create",{"id":"leap","text":"Leap day","due_local":"2028-02-29 10:00","created_local":"2026-10-03 22:00"}),"Gregorian leap day valid")
	for n in range(2,32): check(m.apply("echo_create",{"id":"echo_" + str(n),"text":"Words","due_local":"2026-10-04 08:00","created_local":"2026-10-03 22:00"}),"bounded echo record " + str(n))
	reject(m,"echo_create",{"id":"overflow_echo","text":"Words","due_local":"2026-10-04 08:00","created_local":"2026-10-03 22:00"})
func verify_store(m, fixture_path: String):
	var store = Store.new(fixture_path)
	check(Store.DEFAULT_PATH == "user://still_here/journey_v1.json", "separate default journey path")
	var path = "user://journey_save_" + str(Time.get_ticks_usec()) + ".json"
	var before = m.snapshot()
	check(store.save_snapshot(before,path).ok, "durable Journey write")
	var loaded = store.load_snapshot(path)
	check(loaded.ok and loaded.data == before, "Journey exact native roundtrip")
	check(m.apply("board","arcade") and store.save_snapshot(m.snapshot(),path).ok, "rotating recoverable backup write")
	var latest = m.snapshot()
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_string("{damaged")
	file.close()
	loaded = store.load_snapshot(path)
	check(loaded.ok and loaded.recovered and loaded.data == before, "damaged primary recovers exact prior writing")
	check(store.save_snapshot(latest,path).ok and store.load_snapshot(path).data == latest, "recovered save can be durably replaced")
	var retained_damage = false
	for filename in DirAccess.get_files_at("user://"):
		if filename.begins_with(path.get_file() + ".damaged."): retained_damage = true
	check(retained_damage, "damaged bytes retained for recovery")
	var future = latest.duplicate(true)
	future.schema_version = 99
	write_json(path,future)
	var future_bytes = FileAccess.get_file_as_bytes(path)
	check(store.load_snapshot(path).error == "future schema", "future primary refused without older fallback")
	check(not store.save_snapshot(latest,path).ok and not store.reset_snapshot(path).ok and FileAccess.get_file_as_bytes(path) == future_bytes, "future primary never overwritten")
	var other = "user://journey_future_backup_" + str(Time.get_ticks_usec()) + ".json"
	write_json(other,latest)
	write_json(other + ".bak", future)
	check(not store.save_snapshot(latest,other).ok and not store.reset_snapshot(other).ok, "future backup preserved too")
	var oversized = "user://journey_oversized_" + str(Time.get_ticks_usec()) + ".json"
	var large_file = FileAccess.open(oversized,FileAccess.WRITE)
	large_file.store_string(JSON.stringify(future).rpad(Store.MAX_FILE_BYTES + 1," "))
	large_file.close()
	check(not store.save_snapshot(latest,oversized).ok and not store.reset_snapshot(oversized).ok,"uninspectable oversized primary never overwritten")
	write_json(oversized,latest)
	large_file = FileAccess.open(oversized + ".bak",FileAccess.WRITE)
	large_file.store_string(JSON.stringify(future).rpad(Store.MAX_FILE_BYTES + 1," "))
	large_file.close()
	check(not store.save_snapshot(latest,oversized).ok and not store.reset_snapshot(oversized).ok,"uninspectable oversized backup never overwritten")
	var campaign_path = "user://still_here/save_v1.json"
	check(not store.save_snapshot(latest,campaign_path).ok and not store.reset_snapshot(campaign_path).ok,"canonical campaign path cannot be written or reset by Journey store")
	check(not store.save_snapshot(latest,ProjectSettings.globalize_path(campaign_path) + ".bak").ok,"campaign backup refused through equivalent absolute path")
	check(not store.save_snapshot(latest,"/proc/journey/save.json").ok, "unwritable destination nonfatal")
	check(not store.save_snapshot({"schema_version":1},"user://invalid_journey.json").ok, "invalid snapshot never written")
	var reset_path = "user://journey_reset_" + str(Time.get_ticks_usec()) + ".json"
	check(store.save_snapshot(latest,reset_path).ok and store.reset_snapshot(reset_path).ok, "Journey reset retains recoverable previous writing")
	check(store.load_snapshot(reset_path).data.mode == "train" and store.load_snapshot(reset_path).data.tiny_tomorrows.is_empty(), "Journey reset returns neutral local state")
	var retained = false
	for filename in DirAccess.get_files_at("user://"):
		if filename.begins_with(reset_path.get_file() + ".reset."):
			retained = store.load_snapshot("user://" + filename).data == latest
	check(retained, "reset snapshot remains available as native backup")
func finish_checks():
	print("JOURNEY MODEL ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
