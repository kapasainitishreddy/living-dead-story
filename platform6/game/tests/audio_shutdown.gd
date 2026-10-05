extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, label: String):
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func _initialize(): call_deferred("run")

func stream_refs(audio) -> Array:
	var refs = [weakref(audio.music.stream)]
	for stream in audio.music_streams.values(): refs.append(weakref(stream))
	for stream in audio.streams.values(): refs.append(weakref(stream))
	return refs

func playback_refs(audio) -> Array:
	var refs = []
	for player in [audio.music, audio.music_secondary, audio.effects, audio.effects_secondary]:
		if player.get_stream_playback() != null:
			refs.append(weakref(player.get_stream_playback()))
	return refs

func run():
	var audio = load("res://audio/audio_director.gd").new()
	check(audio.has_method("shutdown"), "audio exposes explicit shutdown before SceneTree quit")
	if not audio.has_method("shutdown"):
		audio.free()
		quit(1)
		return
	# It is safe to shut down before _ready has created the players.
	audio.shutdown()
	audio.shutdown()
	root.add_child(audio)
	await process_frame
	check(audio.music.stream is AudioStreamWAV and audio.streams.size() == 5, "original music and five ambience loops are loaded")
	var streams = stream_refs(audio)
	audio.crossfade_location("apartment")
	audio.crossfade_location("roof")
	var running_fade = audio.fade
	check(running_fade != null and running_fade.is_running(), "location changes still create a crossfade")
	audio.set_mix(Vector2(0.45, 0.55))
	audio.apply_settings({"master": 0.25, "music": 0.3, "effects": 0.4})
	check(audio.fade == running_fade and running_fade.is_running(), "volume settings preserve the active crossfade")
	check(is_equal_approx(audio.music.volume_db, linear_to_db(0.25 * 0.3 * audio.music_gains[0])), "music settings preserve master, music and crossfade gains")
	check(is_equal_approx(audio.effects.volume_db, linear_to_db(0.25 * 0.4 * 0.45)), "ambience settings preserve master effects and crossfade gains")
	# Exercise actual playback even under headless Godot's Dummy audio driver.
	# Both music slots need actual streams to exercise retiring playback objects.
	audio.music_secondary.stream = audio.load_score("music_umbrella")
	for player in [audio.music, audio.music_secondary, audio.effects, audio.effects_secondary]: player.play()
	await process_frame
	var playbacks = playback_refs(audio)
	check(playbacks.size() == 4, "both music and both ambience slots have real playback objects")
	audio.shutdown()
	check(audio.fade == null and not running_fade.is_running(), "shutdown cancels and releases the active crossfade")
	check(audio.streams.is_empty() and audio.music_streams.is_empty(), "shutdown releases original ambience and score caches")
	for player in [audio.music, audio.music_secondary, audio.effects, audio.effects_secondary]:
		check(not player.playing and player.stream == null, "shutdown stops a player and releases its stream")
	# AudioServer retires stopped playback on a subsequent mix, before nodes exit.
	await create_timer(0.2).timeout
	check(streams.all(func(ref): return ref.get_ref() == null), "all original WAV resources retire after shutdown")
	check(playbacks.all(func(ref): return ref.get_ref() == null), "all mixer playback references retire after shutdown")
	audio.shutdown()
	check(audio.streams.is_empty() and audio.fade == null, "shutdown is idempotent after playback retirement")
	audio.queue_free()
	await process_frame
	print("AUDIO SHUTDOWN ", checks, " checks ", failures, " failures")
	quit(1 if failures else 0)
