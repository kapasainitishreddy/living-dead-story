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
	var profile = audio.location_profile("quiet_orchard")
	check(profile.ambience == "orchard_hush", "Quiet Orchard has a distinct original leaves and distant station bed")
	check(profile.subtitle.to_lower().contains("leaves") and profile.subtitle.contains("station") and not profile.subtitle.to_lower().contains("wheels"), "orchard sound has a matching optional ambient caption")
	check(profile.gain <= 0.3, "orchard gain is subdued")
	audio.crossfade_location("quiet_orchard")
	check(audio.streams.has("orchard_hush"), "orchard bed is loaded locally")
	if audio.streams.has("orchard_hush"):
		var stream = audio.streams.orchard_hush
		check(stream is AudioStreamWAV and stream.get_length() >= 8.0, "original bed is a loopable WAV")
		check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "orchard ambience loops")
		audio.crossfade_location("quiet_orchard")
		await create_timer(1.6).timeout
		check(audio.current_location == "quiet_orchard", "orchard profile crossfade reaches requested location")
		audio.apply_settings({"master":0.0,"music":0.0,"effects":0.0})
		check(audio.effects.volume_db <= -80 and audio.effects_secondary.volume_db <= -80, "mute includes orchard audio")
		audio.shutdown()
		check(audio.streams.is_empty() and audio.effects.stream == null and audio.effects_secondary.stream == null, "orchard sound retires on shutdown")
	else: audio.shutdown()
	await create_timer(0.2).timeout
	audio.queue_free()
	await process_frame
	print("ORCHARD SOUND ",checks," checks ",failures," failures")
	call_deferred("quit",1 if failures else 0)
