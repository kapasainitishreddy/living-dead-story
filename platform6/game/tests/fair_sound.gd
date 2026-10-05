extends SceneTree
func _initialize():
	var audio = load("res://audio/audio_director.gd").new()
	var profile = audio.location_profile("the_small_fair")
	if profile.ambience != "fair_clockwork":
		printerr("FAIL fair has a matching original clockwork ambience")
		quit(1)
	else:
		print("Fair sound checks: 1; failures: 0")
		quit(0)
	audio.free()
