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
# Original local one-shot foley, never a downloaded sample.
var kitchen_cue_player: AudioStreamPlayer
var kitchen_cue_cache := {}
const KITCHEN_CUE_SPECS = {
	"stir": Vector2(0.20,390.0), "herbs": Vector2(0.18,470.0),
	"serve": Vector2(0.26,580.0), "bread": Vector2(0.20,270.0),
	"cup": Vector2(0.23,950.0), "pepper": Vector2(0.16,650.0)
}
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
	kitchen_cue_player = AudioStreamPlayer.new()
	kitchen_cue_player.name = "KitchenFoley"
	add_child(kitchen_cue_player)
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
	if is_instance_valid(kitchen_cue_player):
		var cue_volume: float = float(levels.get("master",0.0))*float(levels.get("effects",0.0))*0.58
		kitchen_cue_player.volume_db = linear_to_db(cue_volume) if cue_volume > 0.0 else -80.0
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
func _make_kitchen_foley(kind: String) -> AudioStreamWAV:
	# Original deterministic 16-bit mono PCM; ceramic rings, herbs and bread rustle.
	# Soft start/end envelopes avoid an abrupt speaker pop.
	var spec: Vector2 = KITCHEN_CUE_SPECS[kind]
	var rate := 22050
	var count := maxi(1,int(float(rate)*spec.x))
	var samples := PackedByteArray()
	samples.resize(count*2)
	var papery: bool = kind in ["stir","herbs","bread","pepper"]
	for i in range(count):
		var t := float(i)/float(rate)
		var tail := pow(maxf(0.0,1.0-float(i)/float(count)),2.2)
		var attack := minf(1.0,float(i)/90.0)
		var grain := sin(float(i)*18.31)*sin(float(i)*3.271)
		var tone := sin(TAU*spec.y*t)*0.62+sin(TAU*spec.y*1.47*t)*0.24
		var wave := (grain*0.75+tone*0.25) if papery else (tone*0.86+grain*0.14)
		var pcm := clampi(roundi(wave*tail*attack*0.30*32767.0),-32768,32767)
		samples[2*i] = pcm & 255
		samples[2*i+1] = (pcm >> 8) & 255
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.stereo = false
	sound.loop_mode = AudioStreamWAV.LOOP_DISABLED
	sound.data = samples
	return sound

func play_kitchen_cue(kind: String) -> bool:
	if not KITCHEN_CUE_SPECS.has(kind) or current_location != "night_kitchen" or not is_instance_valid(kitchen_cue_player):
		return false
	if not kitchen_cue_cache.has(kind):
		kitchen_cue_cache[kind] = _make_kitchen_foley(kind)
	kitchen_cue_player.stop()
	kitchen_cue_player.stream = kitchen_cue_cache[kind]
	update_levels()
	if DisplayServer.get_name() != "headless" and float(levels.get("master",0.0))*float(levels.get("effects",0.0)) > 0.0:
		kitchen_cue_player.play()
	return true

func shutdown():
	# Call before quitting so AudioServer can retire stopped playback next mix.
	if fade:
		fade.kill()
		fade = null
	if music_fade:
		music_fade.kill()
		music_fade = null
	for player in [music,music_secondary,effects,effects_secondary,kitchen_cue_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	streams.clear()
	music_streams.clear()
	kitchen_cue_cache.clear()
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
