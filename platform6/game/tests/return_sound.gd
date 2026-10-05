extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool,label: String):
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var audio = load("res://audio/audio_director.gd").new()
	root.add_child(audio)
	await process_frame
	var profile = audio.location_profile("return_platform")
	check(profile.ambience == "rails" and profile.gain <= 0.25, "return platform keeps subdued station ambience")
	audio.crossfade_location("return_platform")
	audio.apply_settings({"master":1.0,"music":1.0,"effects":1.0})
	check(audio.music.volume_db <= -80 and audio.music_secondary.volume_db <= -80, "departure stays music-free even at full user volume")
	check(not profile.subtitle.contains("musical"), "captions do not claim music during farewell")
	check(audio.has_method("set_return_phase"), "train passage has an actual approach and receding sound envelope")
	if audio.has_method("set_return_phase"):
		audio.set_return_phase("approach")
		await create_timer(0.6).timeout
		check(audio.gains[audio.active_slot] > 0.18, "approaching train rises under the canopy")
		audio.set_return_phase("hold")
		await create_timer(0.6).timeout
		check(is_equal_approx(audio.gains[audio.active_slot], 0.18), "receding train returns to quiet platform hum")
	audio.crossfade_location("apartment")
	check(maxf(audio.music.volume_db,audio.music_secondary.volume_db) > -80, "return mute does not remove earlier chapter music")
	audio.shutdown()
	await create_timer(0.2).timeout
	audio.queue_free()
	await process_frame
	print("RETURN SOUND ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
