extends SceneTree
func _initialize():
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://../evidence/paper/manual/native-completed-save.json"))
	var model = load("res://core/chapter_model.gd").new()
	var ok = parsed is Dictionary and model.restore(parsed)
	if ok:
		var expected = {"star":"clean","layout":"boat_leaf_star","length":"long","mode":"direct","fold":"enough","completed":true}
		ok = model.snapshot().paper_checkpoint == "complete" and model.snapshot().paper == expected
	print("Native completed save valid and exact: ", ok)
	quit(0 if ok else 1)
