extends "res://tests/paper_rendered_qa.gd"
func run():
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://paper_metadata_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	seed_fair()
	game.on_interact(game.world_container.get_child(0).get_node("Interactions/replay_race"))
	while game.racing: await process_frame
	check(game.model.snapshot().fair.replay_count == 1, "valueless fair replay still works")
	game.hud.close_all()
	game.resume_controls()
	await act("begin_paper")
	game.hud.close_all()
	game.resume_controls()
	game.on_interact(game.world_container.get_child(0).get_node("Interactions/paper_greeting"))
	check(game.hud.modal_visible(), "valueless greeting target opens arrival")
	await act("paper_greeting", "begin")
	game.hud.close_all()
	game.resume_controls()
	game.on_interact(game.world_container.get_child(0).get_node("Interactions/paper_worktable"))
	check(game.hud.modal_visible(), "valueless worktable target opens arrangement")
	game.queue_free()
	await process_frame
	game = null
	print("Paper metadata interaction checks: ", checks, "; failures: ", failures)
	call_deferred("quit", 1 if failures else 0)
