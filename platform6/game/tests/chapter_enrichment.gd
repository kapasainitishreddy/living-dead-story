extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func run():
	var authored = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter.json"))
	check(authored.has("local_dialogues"),"local branches authored separately from durable steps")
	if authored.has("local_dialogues"):
		for id in ["umbrella_question","umbrella_quiet","passenger_boats","passenger_quiet","shore_lighthouse","shore_arch","shore_constellation","train_window","breakfast_postcard"]:
			check(authored.local_dialogues.has(id),"original branch " + id)
	if authored.has("local_dialogues"):
		check(not authored.local_dialogues.shore_constellation.text.contains("You have found three parts"),"constellation discovery wording is order independent")
	check(authored.dialogues.meet_passenger.choices.size() >= 3,"passenger offers company, curiosity and quiet")
	check(authored.dialogues.have_breakfast.text.contains("fair"),"breakfast reveals concrete next curiosity")
	var scene = load("res://main.tscn").instantiate()
	scene.save_path = "user://enrichment_"+str(Time.get_ticks_usec())+".json"
	root.add_child(scene)
	await process_frame
	var before = scene.model.snapshot()
	scene.dispatch("dialogue","passenger_boats")
	check(scene.model.snapshot() == before and not scene.hud.modal_visible(),"unavailable local branch rejected without mutation")
	scene.dispatch("leave_apartment")
	scene.hud.close_all()
	scene.resume_controls()
	before = scene.model.snapshot()
	scene.dispatch("dialogue","umbrella_question")
	check(scene.hud.modal_visible(),"local question opens authored branch")
	check(scene.model.snapshot().checkpoint_id == before.checkpoint_id,"local reply leaves save checkpoint unchanged")
	check("platform_six.dialogue.umbrella_question" in scene.model.snapshot().choice_history,"local reply durably records its existing authored trace")
	scene.dispatch("dismiss")
	check(scene.player.enabled,"back from local branch restores walking")
	for action in ["meet_stranger","read_board","board_train"]:
		scene.dispatch(action)
		scene.hud.close_all()
		scene.resume_controls()
	var found_window = false
	for node in scene.world_container.get_child(0).get_children():
		if node.get_meta("value","") == "train_window": found_window = true
	check(found_window,"train has optional playable window observation")
	before = scene.model.snapshot()
	scene.dispatch("dialogue","passenger_boats")
	check(scene.hud.modal_visible() and scene.model.snapshot().checkpoint_id == before.checkpoint_id,"passenger personality choice never gates or ranks progression")
	check("platform_six.dialogue.passenger_boats" in scene.model.snapshot().choice_history,"passenger personality choice remembers its authored callback")
	scene.queue_free()
	await process_frame
	print("Chapter enrichment checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
