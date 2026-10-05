extends SceneTree
func _initialize():
	var helper = load("res://tests/kitchen_model.gd").new()
	var m = helper.completed_paper()
	helper.free()
	for pair in [["begin_kitchen",null],["kitchen_join","watch"],["kitchen_share","watch"],["kitchen_departure","listen"],["begin_orchard",null]]: assert(m.apply(pair[0],pair[1]))
	if "bench" in OS.get_cmdline_user_args(): assert(m.apply("orchard_route","bench"))
	var result = load("res://core/save_store.gd").new().save_snapshot(m.snapshot(),"user://still_here/save_v1.json")
	print("NATIVE ORCHARD SEED ",result)
	quit(0 if result.ok else 1)
