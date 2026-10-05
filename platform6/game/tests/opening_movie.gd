extends SceneTree
# Actual renderer, staged viewpoints + real locomotion. Fixed 24fps evidence
# does not measure delivered frame rate or physical controller acceptance.
var game
func _initialize(): call_deferred("run")
func frames(count: int):
	for i in range(count): await process_frame
func camera(pos: Vector3, look: Vector3, fov := 52.0):
	var cam = Camera3D.new()
	game.world_container.get_child(0).add_child(cam)
	cam.position = pos
	cam.look_at(look)
	cam.fov = fov
	cam.current = true
func run():
	if DisplayServer.get_name() == "headless": quit(2); return
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://opening_movie_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await frames(48)
	Input.action_press("move_forward")
	await frames(72)
	Input.action_release("move_forward")
	await frames(24)
	game.player.set_controls_enabled(false)
	game.hud.hide()
	camera(Vector3(7.8,3.6,6.5),Vector3(-2,1.4,-5.5))
	await frames(72)
	camera(Vector3(-2.2,2.3,-6.5),Vector3(-5,2.4,-10.75),47.0)
	await frames(72)
	var helper = load("res://tests/full_campaign.gd").new()
	var saved = helper.completed_return("lend","skipped")
	helper.free()
	game.model.restore(saved)
	game.route()
	game.dispatch("begin_home")
	game.dispatch("home_ticket","kettle")
	game.dispatch("home_ritual","window")
	game.hud.close_all()
	game.dispatch("home_view")
	game.hud.hide()
	await frames(96)
	game.audio.shutdown()
	await frames(8)
	game.queue_free()
	await process_frame
	await process_frame
	game = null
	print("OPENING_MOVIE_COMPLETE")
	quit()
