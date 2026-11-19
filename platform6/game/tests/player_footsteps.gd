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
	# Collision-resolved displacement, not held controls, drives all walking feedback.
	check(is_equal_approx(player.grounded_locomotion_speed(0.07,0.025,true),2.8),"ground travel translates to real rig speed")
	check(player.grounded_locomotion_speed(0.0,0.025,true) == 0.0,"pushing a wall leaves walk speed zero")
	check(player.grounded_locomotion_speed(0.07,0.025,false) == 0.0,"airborne motion cannot fake grounded stride")
	check(player.grounded_locomotion_speed(0.07,0.0,true) == 0.0,"zero physics step remains finite and still")
	check(is_equal_approx(player.grounded_locomotion_speed(2.0,0.025,true),4.2),"warp or external displacement cannot overspeed gait")
	check(player.grounded_locomotion_speed(-0.2,0.025,true) == 0.0,"invalid negative contact travel is ignored")
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
	# Real rig should settle instead of walking against an immovable prop.
	player.visual.set_process(false)
	player.visual.set_locomotion(2.8)
	for frame in range(16): player.visual.advance_performance(1.0/60.0)
	check(player.visual.locomotion_blend > 0.9,"measured walking travels through imported gait")
	player.visual.set_locomotion(player.grounded_locomotion_speed(0.0,1.0/60.0,true))
	for frame in range(15): player.visual.advance_performance(1.0/60.0)
	check(player.visual.locomotion_blend < 0.04,"blocked movement releases leg swing promptly")
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
	# Hard tile, hollow deck and soft orchard have distinctly authored local PCM.
	var orchard = StaticBody3D.new()
	orchard.name = "OrchardFloor"
	var deck = StaticBody3D.new()
	deck.name = "AccessibleDeck"
	var kitchen = StaticBody3D.new()
	kitchen.name = "KitchenFloor"
	check(player.footstep_surface_from(orchard) == "soft", "actual orchard floor selects softer shoe contact")
	check(player.footstep_surface_from(deck) == "wood", "fairground wooden deck selects hollow contact")
	check(player.footstep_surface_from(kitchen) == "stone", "kitchen tile retains original close shoe contact")
	check(player.footstep_surface_from(null) == "stone", "missing contact safely falls back to neutral")
	kitchen.set_meta("footstep_surface","wood")
	check(player.footstep_surface_from(kitchen) == "wood", "authored collider material overrides chapter name")
	kitchen.set_meta("footstep_surface","unrecognized")
	check(player.footstep_surface_from(kitchen) == "stone", "unrecognized material cannot break fallback")
	var rock = player._original_footstep(0,"stone")
	var timber = player._original_footstep(0,"wood")
	var soil = player._original_footstep(0,"soft")
	check(rock.data.size() == 4410 and timber.data.size() == 4410 and soil.data.size() == 4410, "all three surfaces keep a bounded 100ms mono sample")
	check(rock.data != timber.data and rock.data != soil.data and timber.data != soil.data, "three surfaces have distinct original PCM timbres")
	player.set_preferences({"sensitivity":1.0,"reduced_motion":true,"master":0.8,"effects":0.6})
	var contacts_before := heard.size()
	player.step_surface = "wood"
	player._reset_footsteps()
	for i in range(15): player.advance_footstep(0.12,4.2,0.04,true)
	check(heard.size() == contacts_before+1 and foley.stream.data == player.step_samples["wood:" + str(1-player.step_side)].data, "a wood contact still uses grounded cadence")
	check(player.step_samples.has("wood:0") or player.step_samples.has("wood:1"), "wood contact caches its own shoe sample")
	player.step_surface = "soft"
	player._reset_footsteps()
	for i in range(15): player.advance_footstep(0.12,4.2,0.04,true)
	check(player.step_samples.has("soft:0") or player.step_samples.has("soft:1"), "orchard sample survives a change of supporting floor")
	check(foley.stream.data != rock.data and foley.stream.data != timber.data, "the latest soft contact never reuses hard/wood audio")
	player.step_surface = "stone"
	player._reset_footsteps()
	for i in range(15): player.advance_footstep(0.12,4.2,0.04,true)
	check(player.step_samples.size() <= 6, "only two shoe samples per surface may be cached")
	player.queue_free()
	await process_frame
	print("Grounded footstep Godot checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
