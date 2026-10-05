extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://paper_reset_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await process_frame
	game.persist()
	game.paper_courtyard = true
	game.dispatch("reset")
	await process_frame
	var ok = not game.paper_courtyard
	print("PASS " if ok else "FAIL ", "reset clears courtyard route")
	game.queue_free()
	await process_frame
	quit(0 if ok else 1)
