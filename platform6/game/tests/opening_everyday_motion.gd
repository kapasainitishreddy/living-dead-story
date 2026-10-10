extends SceneTree
var checks := 0
var failures := 0
var game
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func close():
	game.hud.close_all()
	game.resume_controls()
func run():
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://everyday_motion_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	for action in ["leave_apartment", "meet_stranger", "read_board", "board_train"]: game.model.apply(action)
	game.route()
	close()
	var story = game.opening_story
	var latch = story.props.get_node("WindowLatch")
	var pane = story.props.get_node("SlidingWindow")
	game.player.pivot.rotation.y = 0.37
	game.dispatch("dialogue", "train_window")
	var saved = game.store.load_snapshot(game.save_path)
	check(saved.ok and "platform_six.dialogue.train_window" in saved.data.choice_history, "window choice is durable before its presentation")
	check(is_zero_approx(latch.rotation.z) and is_equal_approx(pane.position.z, 1.0), "window starts closed and moves over time")
	check(story.local_camera != null and story.local_camera.current, "window interaction shows its actual prop with a stationary camera")
	story.gesture.custom_step(0.15)
	check(latch.rotation.z < -0.01 and latch.rotation.z > -0.85 and is_equal_approx(pane.position.z, 1.0), "latch lifts before pane starts sliding")
	game.show_pause()
	var held_latch: float = latch.rotation.z
	var held_pane: float = pane.position.z
	await create_timer(0.30).timeout
	check(is_equal_approx(latch.rotation.z, held_latch) and is_equal_approx(pane.position.z, held_pane), "Pause holds the current physical gesture")
	game.hud.resume_pause()
	await create_timer(0.40).timeout
	check(is_equal_approx(latch.rotation.z,-0.85) and pane.position.z < 1.0, "resume continues the same staged gesture")
	game.dispatch("dismiss")
	check(story.gesture == null and is_equal_approx(pane.position.z,0.20), "Back immediately settles the window without waiting")
	check(not story.local_camera.current and game.player.enabled and is_equal_approx(game.player.pivot.rotation.y,0.37), "Back restores walking and the player's saved orbit")
	game.dispatch("dialogue", "train_window")
	check(story.gesture == null, "rereading the remembered window does not replay motion")
	close()
	game.model.restore(saved.data)
	game.route()
	check(is_equal_approx(game.opening_story.props.get_node("SlidingWindow").position.z,0.20) and game.opening_story.local_camera == null, "reload restores the settled window and ordinary exploration")
	for item in [["meet_passenger",null],["arrive_shore",null],["assist",null],["choose_camera","unused"],["resolve_action","skipped"],["return_train",null]]: game.model.apply(item[0],item[1])
	game.route()
	close()
	story = game.opening_story
	var card = game.world_container.get_child(0).get_node("FairPostcard")
	var resting_height: float = card.position.y
	var writable_path: String = game.save_path
	game.save_path = "/proc/platform6_everyday_failure/save.json"
	game.dispatch("dialogue", "breakfast_postcard")
	check(game.hud.notice.text.contains("Unsaved") and story.gesture != null, "failed save remains visible during accepted postcard motion")
	story.gesture.custom_step(0.20)
	check(card.position.y > resting_height + 0.10 and card.rotation.z < 0.01, "postcard lifts clear of the table before turning")
	var preferences = game.model.snapshot().settings
	preferences.reduced_motion = true
	game.change_settings(preferences)
	check(story.gesture == null and is_equal_approx(card.rotation.z,PI) and is_equal_approx(card.position.y,resting_height), "live reduced motion immediately settles the postcard")
	check(not story.local_camera.current and game.player.arm.get_child(0).current, "live reduced motion restores the exploration camera")
	check(card.get_node("HandwrittenOpeningHours").text.contains("KETTLE"), "turned postcard contains original physical handwritten hours")
	check(game.hud.notice.text.contains("Unsaved"), "reduced motion never clears a failed-save warning")
	game.save_path = writable_path
	check(game.persist(), "successful retry writes the accepted ordinary moment")
	close()
	game.route()
	card = game.world_container.get_child(0).get_node("FairPostcard")
	check(is_equal_approx(card.rotation.z,PI) and game.model.snapshot().checkpoint_id == "breakfast", "reopen retains the reversed postcard without advancing the chapter")
	game.dispatch("dialogue", "breakfast_postcard")
	check(game.opening_story.gesture == null and game.opening_story.local_camera == null, "reduced-motion rereading keeps the player's camera and avoids replay")
	game.audio.shutdown()
	game.queue_free()
	await process_frame
	await process_frame
	print("EVERYDAY MOTION ",checks," checks; failures: ",failures)
	quit(1 if failures else 0)
