# Test/evidence harness: samples the actual Godot Master bus, never a PCM re-mix.
extends SceneTree
var recorder: AudioEffectRecord
var output_dir := ""
var mode := "after"
func _initialize(): call_deferred("run")
func save_recording(name: String):
	recorder.set_recording_active(false)
	var recording = recorder.get_recording()
	if recording == null or not recording.stereo or recording.get_length() < 7.5:
		printerr("FAIL actual engine capture is missing, mono or too short: " + name)
		quit(1)
		return
	var err = recording.save_to_wav(output_dir.path_join(name + ".wav"))
	if err != OK:
		printerr("FAIL engine WAV could not be written: " + name)
		quit(1)
		return
	print("ENGINE_AUDIO ", name, " stereo ", recording.mix_rate, " Hz ", recording.get_length(), " s")
func run():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0: mode = args[0]
	output_dir = ProjectSettings.globalize_path("res://../evidence/audio-refresh/engine")
	DirAccess.make_dir_recursive_absolute(output_dir)
	recorder = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	if mode == "before":
		var score = AudioStreamPlayer.new()
		var bed = AudioStreamPlayer.new()
		root.add_child(score); root.add_child(bed)
		var source = ProjectSettings.globalize_path("res://../evidence/audio-refresh/before")
		score.stream = AudioStreamWAV.load_from_file(source.path_join("night_train.wav"))
		bed.stream = AudioStreamWAV.load_from_file(source.path_join("rain_window.wav"))
		score.volume_db = linear_to_db(.8 * .65)
		bed.volume_db = linear_to_db(.8 * .6 * .65)
		recorder.set_recording_active(true)
		score.play(); bed.play()
		await create_timer(8.0).timeout
		save_recording("before_apartment_default")
		score.stop(); bed.stop(); score.stream = null; bed.stream = null
		score.queue_free(); bed.queue_free()
	else:
		var audio = load("res://audio/audio_director.gd").new()
		root.add_child(audio)
		await process_frame
		audio.apply_settings({"master":.8,"music":.65,"effects":.6})
		for location in ["apartment", "roof", "passenger", "overlook", "night_kitchen"]:
			audio.crossfade_location(location)
			await create_timer(2.5).timeout
			var score = [audio.music,audio.music_secondary][audio.active_music_slot]
			var bed = [audio.effects,audio.effects_secondary][audio.active_slot]
			recorder.set_recording_active(true)
			score.play(0.0); bed.play(0.0)
			await create_timer(8.0).timeout
			save_recording("after_" + location + "_default")
			score.stop(); bed.stop()
		audio.shutdown(); audio.queue_free()
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	await create_timer(.2).timeout
	await process_frame
	quit(0)
