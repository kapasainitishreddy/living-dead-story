extends Node3D
# Reproducible visual/performance harness. Run on a real display, not --headless.
# /usr/local/bin/godot --path <game> --rendering-method gl_compatibility \
#   --resolution 1280x720 tests/station_paired_benchmark.tscn -- \
#   --label baseline --output /absolute/evidence/baseline
# All captures are outside measured windows; presentation-cadence wall times.
const WARMUP_SECONDS := 12.0
const SAMPLE_SECONDS := 60.0
const ROUTE := [
	{"seconds":0.0, "position":Vector3(-1.0,0.1,5.0), "yaw":-0.12, "pitch":-0.22},
	{"seconds":10.0,"position":Vector3(-1.0,0.1,-4.7),"yaw":-0.45,"pitch":-0.16},
	{"seconds":20.0,"position":Vector3(-5.0,0.1,-4.7),"yaw":-0.20,"pitch":-0.16},
	{"seconds":30.0,"position":Vector3(-5.0,0.1,5.0), "yaw":1.20, "pitch":-0.22},
	{"seconds":40.0,"position":Vector3(2.0,0.1,5.0),  "yaw":0.20, "pitch":-0.22},
	{"seconds":50.0,"position":Vector3(2.0,0.1,-3.0), "yaw":0.0,  "pitch":-0.10},
	{"seconds":60.0,"position":Vector3(-1.0,0.1,5.0),"yaw":-0.12,"pitch":-0.22},
]
var player: CharacterBody3D
var camera: Camera3D
var output_dir := "/tmp/platform6-paired"
var run_label := "baseline"
var preview_only := false
var measured_phase := ""
var phase_start_usec := 0
var last_frame_usec := 0
var samples: Dictionary = {"stationary": [], "moving": []}
var phase_durations: Dictionary = {}
var result: Dictionary = {}
func _ready():
	var args = OS.get_cmdline_user_args()
	preview_only = args.has("--preview-only")
	for i in range(args.size()-1):
		if args[i] == "--output": output_dir = args[i+1]
		if args[i] == "--label": run_label = args[i+1]
	DirAccess.make_dir_recursive_absolute(output_dir)
	get_tree().root.content_scale_size = Vector2i(1280,720)
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	DisplayServer.window_set_size(Vector2i(1280,720))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var viewport = get_viewport()
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.scaling_3d_scale = 1.0
	var bindings = load("res://main.gd").new()
	for pair in [["move_left",KEY_A],["move_right",KEY_D],["move_forward",KEY_W],["move_back",KEY_S],["look_left",0],["look_right",0],["look_up",0],["look_down",0],["interact",KEY_E],["reset_camera",KEY_R]]:
		bindings.bind_action(pair[0],[pair[1]] if pair[1] else [])
	bindings.free()
	var world = load("res://world/world_factory.gd").new().build("conductor")
	add_child(world)
	for light in world.find_children("*","Light3D",true,false): light.shadow_enabled = false
	player = load("res://player/player.gd").new()
	world.add_child(player)
	player.enabled = false
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	for existing in player.find_children("*","Camera3D",true,false): existing.current = false
	camera = Camera3D.new()
	camera.name = "PairedFixedCamera"
	camera.fov = 65
	camera.current = true
	world.add_child(camera)
	apply_route(0.0)
	print("PAIRED_BENCH_START ",run_label," ",output_dir)
	if DisplayServer.get_name() == "headless":
		push_error("Paired benchmark requires a real rendering display; headless results are invalid")
		get_tree().quit(2)
		return
	await get_tree().create_timer(WARMUP_SECONDS).timeout
	await capture("fixed-start")
	if preview_only:
		print("PAIRED_PREVIEW_COMPLETE ",run_label)
		get_tree().quit()
		return
	await get_tree().create_timer(1.0).timeout
	await measure("stationary")
	apply_route(0.0)
	await get_tree().create_timer(3.0).timeout
	await measure("moving")
	# Replay exact camera poses for visual QA after timings have stopped.
	for mark in [0,10,20,30,40,50,60]:
		apply_route(float(mark))
		await get_tree().create_timer(0.75).timeout
		await capture("route-%02d" % mark)
	result = {
		"label":run_label,
		"godot":Engine.get_version_info(),
		"display":DisplayServer.get_name(),
		"rendering_method":RenderingServer.get_current_rendering_method(),
		"rendering_driver":RenderingServer.get_current_rendering_driver_name(),
		"video_adapter":RenderingServer.get_video_adapter_name(),
		"resolution":get_viewport().get_visible_rect().size,
		"preset":"medium: Compatibility OpenGL, MSAA2x, shadows disabled, 3D scale1.0, vsync disabled",
		"warmup_seconds":WARMUP_SECONDS,
		"sampling_seconds_per_window":SAMPLE_SECONDS,
		"measurement":"Monotonic wall-clock interval between consecutive _process callbacks; uncapped rendered frames on desktop. Not GPU-only timings or target-device benchmark.",
		"scope":"conductor station world plus protagonist; no HUD/audio. Explicit camera follows gameplay 65-degree FOV, 1.5m pivot, 5.5m arm transform, without obstruction shortening so paired views are exact.",
		"route":ROUTE,
		"stationary":summary("stationary"),
		"moving":summary("moving"),
	}
	var f = FileAccess.open(output_dir+"/metrics.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "))
	f.close()
	var csv = FileAccess.open(output_dir+"/frames.csv",FileAccess.WRITE)
	csv.store_line("phase,elapsed_seconds,frame_wall_ms,process_cpu_ms,draw_calls,primitives,objects")
	for key in ["stationary","moving"]:
		for frame in samples[key]:
			csv.store_line("%s,%.6f,%.6f,%.6f,%d,%d,%d" % [key,frame[0],frame[1],frame[2],frame[3],frame[4],frame[5]])
	csv.close()
	print("PAIRED_BENCH_COMPLETE ",JSON.stringify(result))
	get_tree().quit()
func measure(phase: String):
	measured_phase = phase
	phase_start_usec = Time.get_ticks_usec()
	last_frame_usec = 0
	await get_tree().create_timer(SAMPLE_SECONDS).timeout
	phase_durations[phase] = (Time.get_ticks_usec()-phase_start_usec)/1000000.0
	measured_phase = ""
	print("PAIRED_PHASE_COMPLETE ",phase," ",JSON.stringify(summary(phase)))
func _process(_delta):
	if measured_phase.is_empty(): return
	var now = Time.get_ticks_usec()
	var elapsed = (now-phase_start_usec)/1000000.0
	if last_frame_usec > 0 and elapsed <= SAMPLE_SECONDS:
		samples[measured_phase].append([
			elapsed,(now-last_frame_usec)/1000.0,
			Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		])
	last_frame_usec = now
	if measured_phase == "moving": apply_route(min(elapsed,SAMPLE_SECONDS))
func apply_route(seconds: float):
	var idx = clampi(int(seconds/10.0),0,ROUTE.size()-2)
	var a = ROUTE[idx]
	var b = ROUTE[idx+1]
	var weight = clampf((seconds-a.seconds)/(b.seconds-a.seconds),0.0,1.0)
	var pos: Vector3 = a.position.lerp(b.position,weight)
	var yaw = lerp_angle(a.yaw,b.yaw,weight)
	var pitch = lerpf(a.pitch,b.pitch,weight)
	player.position = pos
	player.visual.rotation.y = PI + yaw
	var view_basis = Basis(Vector3.UP,yaw)*Basis(Vector3.RIGHT,pitch)
	camera.global_transform = Transform3D(view_basis,pos+Vector3(0,1.5,0)+view_basis*Vector3(0,0,5.5))
func capture(name_: String):
	await RenderingServer.frame_post_draw
	var image_ = get_viewport().get_texture().get_image()
	var err = image_.save_png(output_dir+"/"+name_+".png")
	if err != OK: push_error("Could not save screenshot: "+str(err))
func percentile(values: Array, fraction: float) -> float:
	if values.is_empty(): return 0.0
	values.sort()
	var index = (values.size()-1)*fraction
	return lerpf(values[int(floor(index))],values[int(ceil(index))],index-floor(index))
func summary(phase: String) -> Dictionary:
	var frames: Array = []
	var draws: Array = []
	var primitives: Array = []
	var cpu: Array = []
	var total := 0.0
	for row in samples[phase]:
		frames.append(row[1]); cpu.append(row[2]); draws.append(row[3]); primitives.append(row[4]); total += row[1]
	return {"frame_samples":frames.size(),"actual_window_seconds":phase_durations.get(phase,0.0),"mean_frame_ms":total/max(frames.size(),1),"average_fps":1000.0/(total/max(frames.size(),1)) if total>0 else 0.0,"median_frame_ms":percentile(frames,0.5),"p95_frame_ms":percentile(frames,0.95),"median_process_cpu_ms":percentile(cpu,0.5),"p95_process_cpu_ms":percentile(cpu,0.95),"median_draw_calls":percentile(draws,0.5),"p95_draw_calls":percentile(draws,0.95),"median_primitives":percentile(primitives,0.5),"p95_primitives":percentile(primitives,0.95)}
