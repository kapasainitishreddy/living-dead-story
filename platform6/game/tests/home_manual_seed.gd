extends SceneTree
const Previous = preload("res://tests/return_model.gd")
const Store = preload("res://core/save_store.gd")
func _initialize():
	var helper = Previous.new()
	var model = helper.completed_orchard("lend", "bench")
	if helper.failures != 0:
		printerr("Prior campaign setup failed")
		helper.free()
		quit(1)
		return
	helper.free()
	for step in [["begin_return",null],["return_arrival",null],["return_farewell","thanks"],["return_departure",null],["return_finish",null],["begin_home",null]]:
		if not model.apply(step[0],step[1]):
			printerr("Home manual seed rejected ",step)
			quit(1)
			return
	var settings = model.snapshot().settings
	settings.reduced_motion = false
	settings.text_scale = 1.0
	if not model.apply("settings",settings):
		quit(1)
		return
	var result = Store.new().save_snapshot(model.snapshot(),"user://still_here/save_v1.json")
	print("HOME MANUAL SEED ", "saved" if result.ok else result.error)
	quit(0 if result.ok else 1)
