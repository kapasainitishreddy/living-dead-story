extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, label: String):
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var audio = load("res://audio/audio_director.gd").new()
	root.add_child(audio)
	await process_frame
	var profile = audio.location_profile("night_kitchen")
	check(profile.ambience == "kitchen_simmer", "Night Kitchen has a distinct original simmer bed")
	check(profile.subtitle.to_lower().contains("soup") and profile.subtitle.contains("cups"), "kitchen sound has a matching optional ambient caption")
	audio.crossfade_location("night_kitchen")
	check(audio.streams.has("kitchen_simmer"), "kitchen bed is loaded locally")
	if audio.streams.has("kitchen_simmer"):
		var stream = audio.streams.kitchen_simmer
		check(stream is AudioStreamWAV and stream.get_length() >= 8.0, "original bed is a loopable WAV")
		check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "kitchen ambience loops")
		audio.crossfade_location("night_kitchen")
		await create_timer(1.6).timeout
		check(audio.current_location == "night_kitchen", "kitchen profile crossfade reaches requested location")
		audio.apply_settings({"master":0.0,"music":0.0,"effects":0.0})
		check(audio.effects.volume_db <= -80 and audio.effects_secondary.volume_db <= -80, "mute includes kitchen audio")
		audio.shutdown()
		check(audio.streams.is_empty() and audio.effects.stream == null and audio.effects_secondary.stream == null, "kitchen sound retires on shutdown")
	else: audio.shutdown()
	await create_timer(0.2).timeout
	audio.queue_free()
	await process_frame
	print("KITCHEN SOUND ",checks," checks ",failures," failures")
	call_deferred("quit",1 if failures else 0)
