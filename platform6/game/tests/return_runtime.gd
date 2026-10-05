extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://return_runtime_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	check(game.has_method("dispatch_return"), "return has a playable adapter")
	check(game.hud.has_method("show_return_dialogue"), "all return responses have accessible controls")
	if game.has_method("dispatch_return") and game.model.has_method("apply_return"):
		await verify_branches(game)
		verify_interrupted_selection(game)
		verify_live_interruptions(game)
		verify_paused_motion_setting(game)
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("RETURN RUNTIME ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
func orchard_seed(camera_choice := "take"):
	var helper = load("res://tests/kitchen_model.gd").new()
	var m = helper.completed_paper(camera_choice)
	helper.free()
	for step in [["begin_kitchen",null],["kitchen_join","watch"],["kitchen_share","watch"],["kitchen_departure","listen"]]: m.apply(step[0],step[1])
	var settings = m.snapshot().settings
	settings.reduced_motion = true
	settings.text_scale = 2.0
	m.apply("settings", settings)
	m.apply("begin_orchard")
	m.apply("orchard_route", "bench")
	for i in range(3): m.apply("orchard_advance")
	m.apply("orchard_finish")
	# Camera is canonical in the seed; explicit base helper covers all camera branches elsewhere.
	return m.snapshot()
func verify_branches(game):
	var seed = orchard_seed()
	for farewell in ["luck", "joke", "thanks", "wave", "little"]:
		check(game.model.restore(seed), "restore prior full journey " + farewell)
		game.route()
		game.show_orchard_state()
		check(game.hud.footer.get_children().any(func(b): return b.text.contains("Return Platform")), "explicit Chapter Six continuation")
		game.dispatch("begin_return")
		await process_frame
		check(game.model.snapshot().return_checkpoint == "arrival", "return arrival " + farewell)
		game.show_pause()
		game.hud.resume_pause()
		check(game.hud.content.get_child(0).text == "The Return Platform", "arrival pause restores focus/context")
		game.dispatch("return_arrival")
		await process_frame
		check(game.model.snapshot().return_checkpoint == "farewell", "preparation saved before presentation")
		check(game.hud.footer.get_child_count() >= 5, "five equally available farewells at 2x text")
		game.hud.footer.get_child(["luck", "joke", "thanks", "wave", "little"].find(farewell)).pressed.emit()
		await process_frame
		var snapshot = game.model.snapshot()
		check(snapshot.return_state.farewell == farewell, "real farewell callback " + farewell)
		check(snapshot.return_checkpoint == "departed", "Mira leaves for every response")
		check(not game.hud.modal_visible(), "departure leaves room for platform ambience")
		check(game.store.load_snapshot(game.save_path).data == snapshot, "departure durable before animation")
		check(snapshot.npc_state == seed.npc_state and snapshot.dimensions == seed.dimensions and snapshot.souvenir_ids == seed.souvenir_ids, "farewell does not grade or override Mira")
		game.show_pause()
		check(game.world_container.get_child(0).paused, "whole departure pauses")
		game.hud.resume_pause()
		check(not game.world_container.get_child(0).paused, "whole departure resumes")
		check(game.model.restore(snapshot), "exact interruption snapshot reload")
		game.route()
		check(game.player.enabled and not game.return_cinematic, "departed reload restores exploration without replay gate")
		game.dispatch("return_state")
		check(game.hud.content.get_child(1).text.length() > 0, "persistent callback visible later")
		game.dispatch("return_finish")
		check(game.model.snapshot().return_state.completed, "equal Chapter Six completion " + farewell)
		game.dispatch("return_state")
		check(game.hud.footer.get_children().any(func(b): return b.text.contains("Save and leave")), "completion permits durable leave")

func verify_interrupted_selection(game):
	var m = load("res://core/chapter_model.gd").new()
	m.restore(orchard_seed("lend"))
	m.apply("begin_return")
	m.apply("return_arrival")
	m.apply("return_farewell", "thanks")
	var chosen = m.snapshot()
	check(game.model.restore(chosen), "restore selected response before departure commit")
	game.route()
	game.dispatch("return_state")
	check(game.hud.footer.get_child(0).text.contains("train"), "selected interruption exposes continuation, not five dead choices")
	game.hud.footer.get_child(0).pressed.emit()
	check(game.model.snapshot().return_checkpoint == "departed", "selected interruption continues autonomous departure")
	check(game.model.snapshot().return_state.farewell == "thanks", "continuation preserves exact accepted farewell")
	check(game.store.load_snapshot(game.save_path).data == game.model.snapshot(), "resumed accepted departure durable")
	for optional in ["return_conductor", "return_jo"]:
		game.dispatch(optional)
		var after = game.model.snapshot()
		game.dispatch("dismiss")
		game.dispatch(optional)
		check(game.hud.modal_visible(), "optional story remains readable " + optional)
		check(game.model.snapshot() == after, "reread never duplicates fictional consequences " + optional)
		game.dispatch("dismiss")

func verify_live_interruptions(game):
	for camera in ["take", "lend", "unused"]:
		game.model.restore(orchard_seed(camera))
		game.route()
		game.dispatch("begin_return")
		var settings = game.model.snapshot().settings
		settings.reduced_motion = false
		game.change_settings(settings)
		game.dispatch("return_arrival")
		var world = game.world_container.get_child(0)
		world.set_process(false)
		check(game.return_cinematic, "normal preparation enters camera " + camera)
		world._process(2.1)
		game.show_pause()
		var before = world.preparation_elapsed
		var arm_index = world.mira._bone_index("UpperArmLeft")
		var frozen_arm = world.mira.skeleton.get_bone_pose_rotation(arm_index)
		var paused_settings = game.model.snapshot().settings
		paused_settings.text_scale = 1.0
		game.change_settings(paused_settings)
		check(world.mira.skeleton.get_bone_pose_rotation(arm_index) == frozen_arm, "text setting preserves world-owned paused acting " + camera)
		world._process(100.0)
		check(world.preparation_elapsed == before, "pause blocks preparation clock " + camera)
		game.hud.resume_pause()
		var back = InputEventAction.new()
		back.action = "ui_cancel"
		back.pressed = true
		game._unhandled_input(back)
		check(not game.return_cinematic and game.hud.modal_visible(), "Back skips preparation but preserves farewells " + camera)
		game.dispatch("return_farewell", "little")
		var durable = game.model.snapshot()
		check(game.return_cinematic, "normal departure enters camera " + camera)
		game.dispatch("return_finish")
		game.dispatch("return_farewell", "luck")
		check(game.model.snapshot() == durable, "rapid inputs cannot overwrite farewell or skip completion " + camera)
		for seconds in [1.0, 4.0, 3.0, 3.0, 2.0]:
			world._process(seconds)
			if not game.return_cinematic: break
			game.show_pause()
			var cinematic_before = world.cinematic_state()
			world._process(10.0)
			check(world.cinematic_state() == cinematic_before, "pause freezes train, doors, props and camera " + camera)
			game.hud.resume_pause()
			check(game.model.snapshot() == durable, "paused choreography never changes durable save " + camera)
		game._unhandled_input(back)
		check(not game.return_cinematic and not game.hud.modal_visible() and game.player.enabled, "Back settles departure and restores walking " + camera)
		check(game.model.snapshot() == durable, "skipping cannot change saved branch " + camera)
		var action_ids: Array = []
		for target in world.get_node("Interactions").get_children(): action_ids.append(target.get_meta("action_id", ""))
		check("return_conductor" in action_ids and "return_jo" in action_ids and "return_finish" in action_ids, "settled platform offers actual optional people and exit " + camera)

func verify_paused_motion_setting(game):
	for camera in ["take", "lend", "unused"]:
		game.model.restore(orchard_seed(camera))
		game.route()
		game.dispatch("begin_return")
		var settings = game.model.snapshot().settings
		settings.reduced_motion = false
		game.change_settings(settings)
		game.dispatch("return_arrival")
		var world = game.world_container.get_child(0)
		world.set_process(false)
		world._process(2.3)
		game.show_pause()
		var arm_index = world.mira._bone_index("UpperArmLeft")
		var frozen = world.mira.skeleton.get_bone_pose_rotation(arm_index)
		settings.reduced_motion = true
		game.change_settings(settings)
		check(world.preparation_active and world.paused, "motion setting does not resolve an open pause " + camera)
		check(world.mira.skeleton.get_bone_pose_rotation(arm_index) == frozen, "motion setting preserves actual paused skeletal pose " + camera)
		check(game.store.load_snapshot(game.save_path).data.settings.reduced_motion, "paused motion preference is saved " + camera)
		game.hud.resume_pause()
		check(not game.return_cinematic and not world.preparation_active and game.hud.modal_visible(), "resume settles new reduced preparation and restores farewell " + camera)
		check(game.model.snapshot().return_checkpoint == "farewell" and game.model.snapshot().return_state.farewell == "unselected", "motion preference cannot choose a farewell " + camera)
