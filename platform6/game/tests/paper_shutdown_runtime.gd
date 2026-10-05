extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://shutdown_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	var passed = game.has_method("quit_to_desktop") and game.hud.has_signal("quit_requested")
	print("PASS " if passed else "FAIL ", "normal desktop quit routes through audio shutdown")
	game.queue_free()
	await process_frame
	quit(0 if passed else 1)
