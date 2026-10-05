extends SceneTree
func _initialize():
	var model = load("res://core/chapter_model.gd").new()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]: model.apply(action)
	model.apply("choose_camera","take")
	model.apply("resolve_action","skipped")
	for action in ["return_train","have_breakfast","finish","begin_fair"]: model.apply(action)
	for pair in [["fair_greeting","ducks"],["set_sail","folded"],["release_boat",null],["inspect_fair","wedge"],["level_pond","self"],["release_boat",null],["fair_departure","card"],["begin_paper",null],["paper_greeting","begin"],["set_paper_star","crooked"],["set_paper_layout","boat_leaf_star"],["set_paper_length","long"],["set_paper_mode","direct"],["set_paper_fold","wider"],["raise_paper",null],["finish_paper",null],["begin_kitchen",null]]: model.apply(pair[0],pair[1])
	var result = load("res://core/save_store.gd").new().save_snapshot(model.snapshot(),"user://still_here/save_v1.json")
	print("Manual kitchen arrival seed: ",result.ok," ",JSON.stringify(model.snapshot().paper))
	quit(0 if result.ok else 1)
