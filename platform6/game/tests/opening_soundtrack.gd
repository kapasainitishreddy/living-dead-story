extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var audio = load("res://audio/audio_director.gd").new()
	root.add_child(audio)
	await process_frame
	var expected = {"apartment":"music_apartment", "roof":"music_umbrella", "platform":"night_train", "passenger":"night_train", "overlook":"music_shore", "night_kitchen":"music_return", "return_train":"music_return", "breakfast":"music_return", "complete":"music_return", "return_platform":"music_return", "still_here":"music_return"}
	for location in expected:
		var profile = audio.location_profile(location)
		check(profile.get("score", "") == expected[location], location + " has its authored motif arrangement")
	check(audio.get("music_secondary") is AudioStreamPlayer, "music has a second slot for smooth changes")
	if not audio.get("music_secondary") is AudioStreamPlayer:
		audio.shutdown(); audio.queue_free(); await process_frame; quit(1); return
	audio.crossfade_location("apartment")
	await create_timer(2.6).timeout
	audio.crossfade_location("roof")
	await create_timer(0.15).timeout
	var running = audio.music_fade
	audio.apply_settings({"master":0.4,"music":0.3,"effects":0.2})
	check(audio.music_fade == running and running.is_running(), "slider adjustment preserves music fade")
	await create_timer(2.6).timeout
	var players = [audio.music, audio.music_secondary]
	var active = players[audio.active_music_slot]
	check(active.stream.resource_path.ends_with("music_umbrella.wav"), "roof fade selects the real umbrella score")
	check(is_equal_approx(active.volume_db, linear_to_db(0.4 * 0.3)), "active music follows separate master and music sliders")
	check(is_equal_approx(active.pitch_scale, 1.0), "scene score retains natural composed pitch")
	# Interrupted transitions must settle to the newest location rather than stop it.
	audio.crossfade_location("overlook")
	await create_timer(0.08).timeout
	var dominant_slot = 0 if audio.music_gains[0] >= audio.music_gains[1] else 1
	var dominant_stream = players[dominant_slot].stream
	audio.crossfade_location("return_platform")
	check(players[dominant_slot].stream == dominant_stream, "interrupted fade preserves the louder sounding arrangement")
	audio.crossfade_location("still_here")
	await create_timer(2.6).timeout
	active = players[audio.active_music_slot]
	check(active.stream.resource_path.ends_with("music_return.wav"), "rapid return changes settle on the warm reprise")
	audio.apply_settings({"master":1.0,"music":0.0,"effects":1.0})
	check(players.all(func(player): return player.volume_db <= -80), "music zero mutes both score slots")
	check(maxf(audio.effects.volume_db, audio.effects_secondary.volume_db) > -80, "music mute preserves environmental effects")
	audio.apply_settings({"master":0.0,"music":1.0,"effects":1.0})
	check([audio.music,audio.music_secondary,audio.effects,audio.effects_secondary].all(func(player): return player.volume_db <= -80), "master zero mutes every player")
	audio.shutdown()
	check(audio.music_fade == null and audio.music_streams.is_empty(), "shutdown retires score fade and cache")
	check(players.all(func(player): return player.stream == null and not player.playing), "both music slots release playback on shutdown")
	audio.queue_free()
	await process_frame
	print("OPENING SOUNDTRACK ", checks, " checks ", failures, " failures")
	quit(1 if failures else 0)
