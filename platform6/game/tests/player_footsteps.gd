extends SceneTree
# Real player/PCM regression: audible shoes require actual grounded displacement.
var checks := 0
var failures := 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _initialize(): call_deferred("run")
func run():
	var player = load("res://player/player.gd").new()
	root.add_child(player)
	await process_frame
	player.set_physics_process(false)
	var heard: Array[int] = []
	player.footstep_contact.connect(func(side: int): heard.append(side))
	player.set_preferences({"sensitivity":1.0,"reduced_motion":false,"master":0.8,"effects":0.6})
	var foley = player.get_node("FootContactAudio")
	check(foley is AudioStreamPlayer3D and foley.position.y < 0.15,"original shoe sounds emit near the feet")
	for i in range(15): player.advance_footstep(0.12,4.2,0.04,true)
	check(heard == [0],"first grounded contact follows actual travel")
	check(foley.stream is AudioStreamWAV,"first step uses procedural local PCM")
	var first_stream = foley.stream
	check(first_stream.mix_rate == 22050 and first_stream.format == AudioStreamWAV.FORMAT_16_BITS and first_stream.data.size() == 4410,"100 ms quiet mono sample is bounded")
	for i in range(14): player.advance_footstep(0.12,4.2,0.04,true)
	check(heard == [0,1],"next step alternates foot rather than looping the first")
	check(foley.stream != first_stream and player.step_samples.size() == 2,"second contact has a separately cached original timbre")
	var stable = heard.size()
	for i in range(15): player.advance_footstep(0.0,4.2,0.04,true)
	check(heard.size() == stable,"held input against wall makes no contact")
	for i in range(10): player.advance_footstep(0.25,4.2,0.04,false)
	check(heard.size() == stable and player.step_distance == 0.0,"airborne travel creates no footsteps or hidden backlog")
	player.set_controls_enabled(false)
	for i in range(15): player.advance_footstep(0.20,4.2,0.04,true)
	check(heard.size() == stable and player.step_distance == 0.0,"dialogue and pause block step cadence")
	player.set_controls_enabled(true)
	for i in range(15): player.advance_footstep(0.12,4.2,0.04,true)
	check(heard.size() == stable+1,"exploration resumes with a fresh grounded cadence")
	player.set_preferences({"sensitivity":1.0,"reduced_motion":true,"master":0.8,"effects":0.0})
	check(foley.volume_db <= -79.0,"Effects mute silences footsteps")
	stable = heard.size()
	for i in range(15): player.advance_footstep(0.12,4.2,0.04,true)
	check(heard.size() == stable+1,"Effects mute and reduced motion never stop gameplay")
	player.queue_free()
	await process_frame
	print("Grounded footstep Godot checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
