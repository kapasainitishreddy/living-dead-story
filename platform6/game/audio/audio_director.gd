extends Node
var music: AudioStreamPlayer
var music_secondary: AudioStreamPlayer
var music_fade: Tween
var music_gains := [1.0, 0.0]
var active_music_slot := 0
var current_score := "music_apartment"
var music_streams := {}
var score_clock := 0.0
const SCORE_SECONDS := 48.0
var effects: AudioStreamPlayer
var effects_secondary: AudioStreamPlayer
var current_location := ""
var levels = {"master":0.8,"music":0.65,"effects":0.6}
var fade: Tween
var active_slot := 0
var gains := [0.0,0.0]
var streams := {}
const PROFILES = {
	"home_rain":{"ambience":"rain_window","gain":0.30,"subtitle":"[Quiet rain against the apartment window; the room settles]"},
	"orchard_hush":{"ambience":"orchard_hush","gain":0.26,"subtitle":"[Leaves softly rustling, far station hum, a distant wooden crate settling]"},
	"kitchen_simmer":{"ambience":"kitchen_simmer","gain":0.55,"subtitle":"[Soup softly simmering, cups against the table, rain outside]"},
	"rain_window":{"ambience":"rain_window","gain":0.65,"subtitle":"[Rain softly tapping the window]"},
	"rain_roof":{"ambience":"rain_roof","gain":0.65,"subtitle":"[Rain on the umbrella, distant city hush]"},
	"station":{"ambience":"rails","gain":0.18,"subtitle":"[Distant rails humming beneath the canopy]"},
	"rails":{"ambience":"rails","gain":0.62,"subtitle":"[Wheels over rail joints, warm musical refrain]"},
	"fair_clockwork":{"ambience":"fair_clockwork","gain":0.5,"subtitle":"[Quiet clockwork turns and a distant market hush]"},
	"surf":{"ambience":"surf","gain":0.8,"subtitle":"[Slow surf folding through the stone arch]"}
}
func location_profile(location: String) -> Dictionary:
	var kind = "rails"
	if location == "still_here": kind = "home_rain"
	elif location == "quiet_orchard": kind = "orchard_hush"
	elif location == "night_kitchen": kind = "kitchen_simmer"
	elif location == "the_small_fair": kind = "fair_clockwork"
	elif location == "paper_sky": kind = "rain_window"
	elif location == "apartment": kind = "rain_window"
	elif location == "roof": kind = "rain_roof"
	elif location in ["platform","conductor","return_platform"]: kind = "station"
	elif location in ["overlook","camera_choice","optional_action"]: kind = "surf"
	var profile = PROFILES[kind].duplicate(true)
	profile["score"] = "night_train"
	if location in ["apartment", "paper_sky", "quiet_orchard"]: profile.score = "music_apartment"
	elif location in ["roof", "the_small_fair"]: profile.score = "music_umbrella"
	elif location in ["overlook", "camera_choice", "optional_action"]: profile.score = "music_shore"
	elif location in ["night_kitchen", "return_train", "breakfast", "complete", "return_platform", "still_here"]: profile.score = "music_return"
	return profile
func _ready():
	music = AudioStreamPlayer.new()
	add_child(music)
	music_secondary = AudioStreamPlayer.new()
	add_child(music_secondary)
	effects = AudioStreamPlayer.new()
	add_child(effects)
	effects_secondary = AudioStreamPlayer.new()
	add_child(effects_secondary)
	music.stream = load_score(current_score)
	for id in ["rain_window","rain_roof","rails","surf","fair_clockwork"]:
		streams[id] = load("res://assets/original/"+id+".wav")
		configure_loop(streams[id])
	if DisplayServer.get_name() != "headless": music.play()
	update_levels()
func _process(delta: float):
	score_clock = fmod(score_clock + delta, SCORE_SECONDS)
func load_score(id: String) -> AudioStreamWAV:
	if not music_streams.has(id):
		var stream = load("res://assets/original/" + id + ".wav") as AudioStreamWAV
		configure_loop(stream)
		music_streams[id] = stream
	return music_streams[id]
func configure_loop(stream: AudioStreamWAV):
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length()*stream.mix_rate)
func apply_settings(settings: Dictionary):
	levels = settings.duplicate(true)
	update_levels() # Changing a slider must not cancel an active location fade.
func update_levels():
	if not is_instance_valid(music): return
	var score_players = [music,music_secondary]
	for i in range(2):
		var score_volume = levels.master * levels.music * music_gains[i]
		score_players[i].volume_db = linear_to_db(score_volume) if score_volume > 0 and current_location not in ["return_platform","still_here"] else -80.0
	var players = [effects,effects_secondary]
	for i in range(2):
		var volume = levels.master*levels.effects*gains[i]
		players[i].volume_db = linear_to_db(volume) if volume > 0 else -80.0
func set_mix(value: Vector2):
	gains = [value.x,value.y]
	update_levels()
func set_music_mix(value: Vector2):
	music_gains = [value.x, value.y]
	update_levels()
func crossfade_score(score: String):
	if score == current_score: return
	if music_fade and music_fade.is_running(): music_fade.kill()
	var players = [music,music_secondary]
	# A quick new location replaces the quieter slot, preserving the audible tail.
	var next_slot = 0 if music_gains[0] <= music_gains[1] else 1
	players[next_slot].stop()
	players[next_slot].stream = load_score(score)
	players[next_slot].pitch_scale = 1.0
	music_gains[next_slot] = 0.0
	update_levels()
	# All arrangements share the same harmonic clock, including interrupted fades.
	if DisplayServer.get_name() != "headless": players[next_slot].play(score_clock)
	var target = Vector2.ZERO
	target[next_slot] = 1.0
	music_fade = create_tween()
	music_fade.tween_method(set_music_mix, Vector2(music_gains[0], music_gains[1]), target, 2.4)
	var old_slot = 1 - next_slot
	music_fade.tween_callback(func(): players[old_slot].stop())
	active_music_slot = next_slot
	current_score = score
func set_location(location: String): crossfade_location(location)
func crossfade_location(location: String):
	if location == current_location: return
	var profile = location_profile(location)
	# Optional later chapters load their local bed when first reached.
	if not streams.has(profile.ambience):
		streams[profile.ambience] = load("res://assets/original/" + profile.ambience + ".wav")
		configure_loop(streams[profile.ambience])
	var previous = location_profile(current_location) if not current_location.is_empty() else {}
	current_location = location
	crossfade_score(profile.score)
	update_levels()
	if not previous.is_empty() and previous.ambience == profile.ambience:
		if fade and fade.is_running(): fade.kill()
		var target_mix = Vector2.ZERO
		target_mix[active_slot] = profile.gain
		fade = create_tween()
		fade.tween_method(set_mix,Vector2(gains[0],gains[1]),target_mix,1.0)
		var inactive = effects_secondary if active_slot == 0 else effects
		fade.tween_callback(inactive.stop)
		return
	if fade and fade.is_running(): fade.kill()
	var players = [effects,effects_secondary]
	var next_slot = 1-active_slot
	players[next_slot].stop()
	players[next_slot].stream = streams[profile.ambience]
	gains[next_slot] = 0.0
	if DisplayServer.get_name() != "headless": players[next_slot].play()
	var target = Vector2.ZERO
	target[next_slot] = profile.gain
	fade = create_tween().set_parallel(true)
	fade.tween_method(set_mix,Vector2(gains[0],gains[1]),target,1.5)
	var old_slot = active_slot
	fade.chain().tween_callback(func(): players[old_slot].stop())
	active_slot = next_slot
func shutdown():
	# Call before quitting so AudioServer can retire stopped playback next mix.
	if fade:
		fade.kill()
		fade = null
	if music_fade:
		music_fade.kill()
		music_fade = null
	for player in [music,music_secondary,effects,effects_secondary]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	streams.clear()
	music_streams.clear()
func _exit_tree():
	shutdown()

func set_return_phase(phase: String):
	if current_location != "return_platform": return
	if fade and fade.is_running(): fade.kill()
	var gain := 0.18
	if phase in ["approach", "doors_open", "boarding", "turn_back", "camera_slip", "camera_catch", "doors_close"]: gain = 0.48
	elif phase == "train_leaves": gain = 0.30
	var target := Vector2.ZERO
	target[active_slot] = gain
	fade = create_tween()
	fade.tween_method(set_mix, Vector2(gains[0],gains[1]), target, 0.4)
