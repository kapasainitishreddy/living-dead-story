extends SceneTree
func _initialize():
	var helper = load("res://tests/return_runtime.gd").new()
	var snapshot = helper.orchard_seed("lend")
	helper.free()
	var model = load("res://core/chapter_model.gd").new()
	if not model.restore(snapshot) or not model.apply("begin_return"):
		quit(1)
		return
	var settings = model.snapshot().settings
	settings.reduced_motion = false
	settings.text_scale = 1.0
	model.apply("settings", settings)
	var path = ProjectSettings.globalize_path("res://../evidence/return/keyboard-seed.json")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(model.snapshot()))
	file.close()
	print("KEYBOARD SEED: valid Chapter Six arrival with borrowed camera")
	quit()
