extends SceneTree
var samples: Array[float] = []
func _initialize(): call_deferred("run")
func run():
	if DisplayServer.get_name() == "headless": quit(2); return
	root.size = Vector2i(1280,720)
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://char_benchmark_"+str(Time.get_ticks_usec())+".json"
	game.model.data.checkpoint_id = "conductor"
	root.add_child(game)
	await process_frame
	game.hud.close_all()
	game.hud.hide()
	game.player.set_controls_enabled(false)
	game.player.position = Vector3(-1,0.05,2)
	var camera = Camera3D.new()
	game.world_container.get_child(0).add_child(camera)
	camera.global_position = Vector3(4.6,3.2,8)
	camera.look_at(Vector3(0,1.3,-2))
	camera.fov = 55
	camera.current = true
	await create_timer(5).timeout
	var duration := 60.0
	if OS.get_cmdline_user_args().size() > 1: duration = float(OS.get_cmdline_user_args()[1])
	var start = Time.get_ticks_usec()
	var previous = start
	while Time.get_ticks_usec()-start < int(duration*1000000.0):
		await process_frame
		var now = Time.get_ticks_usec()
		samples.append(float(now-previous)/1000.0)
		previous = now
	samples.sort()
	var data = {"samples":samples.size(),"median_ms":samples[samples.size()/2],"p95_ms":samples[int(samples.size()*0.95)],"renderer":RenderingServer.get_video_adapter_name(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"resolution":"1280x720","duration_seconds":duration,"graphics":"medium","msaa":"2x","local_shadows":false,"scope":"stationary fixed-camera only; no target GPU claim"}
	print("CHARACTER_BENCHMARK ",JSON.stringify(data))
	var file = FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t"))
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await process_frame
	game = null
	quit()
