extends SceneTree
func _initialize():
	var model = load("res://core/chapter_model.gd").new()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]: model.apply(action)
	model.apply("choose_camera","take")
	model.apply("resolve_action","skipped")
	for action in ["return_train","have_breakfast","finish"]: model.apply(action)
	model.apply("begin_fair")
	var result = load("res://core/save_store.gd").new().save_snapshot(model.snapshot(),"user://still_here/save_v1.json")
	print("Manual source seed prepared: ",result.ok," · fair arrival; production UI is unchanged")
	quit(0 if result.ok else 1)
