extends SceneTree
# Real game controller/input, real station world and imported character animation.
var game
func _initialize(): call_deferred("run")
func wait_frames(count: int):
	for i in range(count): await process_frame
func run():
	if DisplayServer.get_name() == "headless": quit(2); return
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://character_movie_"+str(Time.get_ticks_usec())+".json"
	game.model.data.checkpoint_id = "conductor"
	root.add_child(game)
	await process_frame
	game.hud.close_all()
	game.hud.hide()
	game.player.position = Vector3(-1,0.05,1)
	game.player.visual.rotation.y = 0
	var camera = Camera3D.new()
	game.world_container.get_child(0).add_child(camera)
	camera.global_position = Vector3(4.6,2.8,13)
	camera.look_at(Vector3(-1,1.0,4.0))
	camera.fov = 42
	camera.current = true
	game.player.set_controls_enabled(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await wait_frames(96)
	Input.action_press("move_back")
	await wait_frames(36)
	Input.action_release("move_back")
	await wait_frames(36)
	Input.action_press("move_forward")
	await wait_frames(36)
	Input.action_release("move_forward")
	await wait_frames(36)
	game.player.set_controls_enabled(false)
	var listener = Node3D.new()
	game.world_container.get_child(0).add_child(listener)
	listener.position = Vector3(2,0,2)
	game.player.visual.set_conversation(true,listener)
	await wait_frames(72)
	var settings = game.model.snapshot().settings
	settings.reduced_motion = true
	game.change_settings(settings)
	await wait_frames(48)
	game.model.data.checkpoint_id = "passenger"
	game.route()
	game.hud.close_all()
	game.hud.hide()
	game.player.position = Vector3(-0.7,0.05,-1.7)
	game.player.set_controls_enabled(false)
	camera = Camera3D.new()
	game.world_container.get_child(0).add_child(camera)
	camera.global_position = Vector3(2.2,1.65,-1.45)
	camera.look_at(Vector3(1.8,1.37,-4))
	camera.fov = 32
	camera.current = true
	settings.reduced_motion = false
	game.change_settings(settings)
	var mira = game.world_container.get_child(0).get_node("Mira")
	mira.set_conversation(true,game.player)
	await wait_frames(360)
	print("CHARACTER_ANIMATION_PROOF_DONE 720+ frames: protagonist idle walk stop turn conversation reduced-motion, Mira gaze/gesture/prop; renderer=",RenderingServer.get_video_adapter_name())
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await process_frame
	game = null
	quit()
