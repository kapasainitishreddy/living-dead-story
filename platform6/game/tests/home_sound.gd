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
	var profile = audio.location_profile("still_here")
	check(profile.ambience == "rain_window" and profile.gain <= 0.35, "home keeps subdued original window rain")
	check(profile.subtitle.contains("window") and not profile.subtitle.contains("musical"), "home rain caption is honest and music-free")
	audio.crossfade_location("still_here")
	audio.apply_settings({"master":1.0,"music":1.0,"effects":1.0})
	check(audio.music.volume_db <= -80 and audio.music_secondary.volume_db <= -80, "home ending stays music-free even at full volume")
	await create_timer(1.7).timeout
	check(is_equal_approx(audio.gains[audio.active_slot], profile.gain), "home original rain bed settles to quiet gain")
	audio.apply_settings({"master":1.0,"music":1.0,"effects":0.0})
	check(audio.effects.volume_db <= -80 and audio.effects_secondary.volume_db <= -80, "effects control mutes both home rain slots")
	audio.apply_settings({"master":0.0,"music":1.0,"effects":1.0})
	check(audio.music.volume_db <= -80 and audio.effects.volume_db <= -80 and audio.effects_secondary.volume_db <= -80, "master control mutes the complete home mix")
	audio.crossfade_location("apartment")
	audio.apply_settings({"master":1.0,"music":1.0,"effects":1.0})
	check(maxf(audio.music.volume_db,audio.music_secondary.volume_db) > -80, "home mute does not remove opening chapter music")
	audio.shutdown()
	await create_timer(0.2).timeout
	audio.queue_free()
	await process_frame
	print("HOME SOUND ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
