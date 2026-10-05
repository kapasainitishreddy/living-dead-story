extends SceneTree
# Opening story contracts exercise the real runtime, save and physical props.
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func close(game):
	game.hud.close_all()
	game.resume_controls()
func world(game): return game.world_container.get_child(0)
func prop(game, id: String): return world(game).find_child(id, true, false)
func run():
	root.size = Vector2i(1280, 720)
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://opening_story_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	var objective = game.hud.root.get_node_or_null("StoryObjective")
	check(objective != null and objective.text.contains("roof"), "apartment supplies the immediate authored objective")
	game.dispatch("leave_apartment")
	close(game)
	var before = game.model.snapshot()
	game.dispatch("dialogue", "umbrella_question")
	check(game.conversation_actor == world(game).get_node_or_null("SupportingPerformer"), "umbrella branch resolves the actual Jo rig as its speaker")
	var history = game.model.snapshot().choice_history
	check("platform_six.dialogue.umbrella_question" in history, "actual umbrella selection remembers its authored choice")
	check(game.model.snapshot().checkpoint_id == before.checkpoint_id, "local choice never advances the scene")
	check(game.model.snapshot().dimensions.wonder == before.dimensions.wonder + 2, "existing authored fictional consequence applies once")
	var remembered = game.model.snapshot()
	close(game)
	game.dispatch("dialogue", "umbrella_question")
	check(game.model.snapshot() == remembered, "rereading a local answer is fully idempotent")
	close(game)
	var reloaded = game.store.load_snapshot(game.save_path)
	check(reloaded.ok and "platform_six.dialogue.umbrella_question" in reloaded.data.choice_history, "local reply survives a real save and reload")
	game.dispatch("meet_stranger")
	close(game)
	var ticket = prop(game, "Ticket")
	check(ticket != null and ticket.visible and ticket.get_child_count() > 0, "blank station ticket is an actual visible physical object")
	check(ticket != null and ticket.position.distance_to(Vector3(0, 0.681, -6)) < 0.1, "visible blank ticket sits beside the actual read-board interaction")
	game.player.position = Vector3(0.4, 0.1, -5.5)
	game.player.pivot.rotation.y = 0.42
	game.player.arm.rotation.x = 0.23
	var board_marker
	for candidate in world(game).get_children():
		if candidate.get_meta("action_id", "") == "read_board": board_marker = candidate
	game.on_interact(board_marker)
	await create_timer(0.55).timeout
	game.dispatch("read_board")
	check(game.player.position.is_equal_approx(Vector3(0.4, 0.1, -5.5)), "taking the ticket keeps player position in the same station")
	check(is_equal_approx(game.player.pivot.rotation.y, 0.42), "same-room advance keeps chosen camera yaw")
	check(is_equal_approx(game.player.arm.rotation.x, 0.23), "same-room advance restores exploration pitch after a real dialogue pan")
	ticket = prop(game, "Ticket")
	check(ticket != null and ticket.get_meta("held", false), "taken ticket physically leaves the bench")
	close(game)
	game.dispatch("board_train")
	close(game)
	var latch = prop(game, "WindowLatch")
	check(latch != null, "carriage latch described by the conductor exists physically")
	game.dispatch("dialogue", "train_window")
	latch = prop(game, "WindowLatch")
	check(latch != null and abs(latch.rotation.z) > 0.1, "window observation physically lifts the latch")
	var pane = prop(game, "SlidingWindow")
	check(pane != null and pane.position.z < 0.8, "window observation physically slides the pane")
	close(game)
	var roll = prop(game, "ToolRoll")
	var old_roll_position = roll.global_position if roll != null else Vector3.ZERO
	game.dispatch("dialogue", "passenger_quiet")
	check(roll != null and roll.global_position.distance_to(old_roll_position) > 0.20, "quiet-company reply physically clears Mira’s tool roll from the spare seat")
	close(game)
	game.route()
	roll = prop(game, "ToolRoll")
	check(roll != null and not roll.get_meta("on_spare_seat", true), "remembered quiet-company choice restores the cleared spare seat")
	game.player.position = Vector3(0.2, 0.1, -2.3)
	game.dispatch("meet_passenger")
	check(game.player.position.is_equal_approx(Vector3(0.2, 0.1, -2.3)), "accepting company retains carriage position")
	close(game)
	game.dispatch("arrive_shore")
	close(game)
	objective = game.hud.root.get_node_or_null("StoryObjective")
	check(objective != null and objective.text.contains("0 / 3"), "shore objective shows actual uninspected landmarks")
	for landmark in ["arch", "constellation", "lighthouse"]:
		var target
		for candidate in world(game).get_children():
			if candidate.get_meta("value", "") == landmark: target = candidate
		game.on_interact(target)
		close(game)
	objective = game.hud.root.get_node_or_null("StoryObjective")
	check(objective != null and objective.text.contains("3 / 3"), "shore objective follows order-independent physical discoveries")
	var puzzle
	for candidate in world(game).get_children():
		if candidate.get_meta("action_id", "") == "puzzle": puzzle = candidate
	game.on_interact(puzzle)
	var preview = world(game).get_node_or_null("OpeningStory/FramingCamera")
	check(preview != null and preview.current, "puzzle opens a real shore camera instead of an abstract answer list")
	game.dispatch("preview_alignment", 1)
	check(game.model.snapshot().checkpoint_id == "overlook" and not game.model.snapshot().puzzle_solved, "changing framing is reversible and never automatically solves")
	var arch_view = preview.global_transform if preview != null else Transform3D.IDENTITY
	game.dispatch("preview_alignment", 2)
	check(preview != null and preview.global_transform != arch_view, "framing buttons change the actual physical view")
	if preview != null:
		for point in [Vector3(-8, 6.5, -13), Vector3(0, 4.4, -15), Vector3(6.4, 7.9, -18)]:
			check(not preview.is_position_behind(point) and preview.unproject_position(point).x < 720 and preview.unproject_position(point).x > 24, "whole-shore camera keeps an actual landmark visible left of the choices")
	check(game.model.snapshot().checkpoint_id == "overlook", "whole-shore preview still waits for explicit Keep")
	game.dispatch("dismiss")
	check(preview != null and not preview.current and game.player.enabled, "Back restores exploration and the ordinary player camera")
	game.on_interact(puzzle)
	game.dispatch("align", 2)
	close(game)
	check(game.model.snapshot().checkpoint_id == "camera_choice", "keeping the observed whole-shore framing advances the authored beat")
	game.dispatch("choose_camera", "unused")
	close(game)
	var camera = prop(game, "CameraBox")
	check(camera != null and camera.get_meta("unopened", false), "unopened-camera route remains visibly unopened")
	game.dispatch("resolve_action", "skipped")
	close(game)
	var cups = prop(game, "BreakfastCups")
	check(cups != null and cups.find_children("*", "GeometryInstance3D", true, false).size() >= 4, "breakfast has two actual cups and saucers")
	check(prop(game, "FoldedTimetable") != null and prop(game, "Toast") != null and prop(game, "Jam") != null, "breakfast narration has real timetable, toast and jam staging")
	game.player.position = Vector3(0.3, 0.1, -2.0)
	game.dispatch("return_train")
	check(game.player.position.is_equal_approx(Vector3(0.3, 0.1, -2.0)), "sitting for breakfast does not teleport to the carriage entrance")
	close(game)
	game.dispatch("dialogue", "breakfast_postcard")
	var card = world(game).get_node_or_null("FairPostcard")
	check(card != null and abs(card.rotation.z) > 3.0, "turning the postcard physically shows its reverse")
	close(game)
	game.dispatch("have_breakfast")
	close(game)
	game.dispatch("finish")
	check(game.model.snapshot().souvenir_ids == ["platform_six_journey"], "story presentation preserves canonical Chapter One souvenir")
	var authored = game.hud.authored
	check(authored.get("objectives", {}).size() == load("res://core/chapter_model.gd").STATES.size(), "every opening checkpoint has an authored next step")
	# Prove the actual history selects the existing later Jo callback.
	var later = game.model.snapshot()
	later.campaign_chapter = "return_platform"
	later.return_checkpoint = "arrival"
	game.hud.show_return_dialogue(later, "return_jo")
	check(game.hud.content.get_child(1).text.contains("You asked where the train went"), "remembered umbrella question reaches the authored later Jo callback")
	game.queue_free()
	await process_frame
	print("Opening story flow: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
