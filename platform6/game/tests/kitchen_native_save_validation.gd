extends SceneTree
var failures := 0
var checks := 0
func check(ok,label):
	checks += 1
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func _initialize():
	var file = "res://../evidence/kitchen/native-completed-save.json"
	if not OS.get_cmdline_user_args().is_empty(): file = OS.get_cmdline_user_args()[0]
	check(FileAccess.file_exists(file),"actual native saved bytes are readable")
	if not FileAccess.file_exists(file): quit(1); return
	var saved = JSON.parse_string(FileAccess.get_file_as_string(file))
	var model = load("res://core/chapter_model.gd").new()
	check(saved is Dictionary and model.restore(saved),"actual native release save validates against production model")
	if not saved is Dictionary: quit(1); return
	check(saved.schema_version == 2,"native save keeps schema 2")
	check(saved.campaign_chapter == "night_kitchen" and saved.kitchen_checkpoint == "complete", "native dinner completed")
	check(saved.kitchen.mode == "help" and saved.kitchen.served,"ordinary native help served supper")
	check(saved.kitchen.exchange == "bread", "ordinary nearest-target bread interaction saved")
	check(saved.kitchen.departure == "ask" and saved.kitchen.completed,"native Mira response and completion saved")
	check(saved.paper.star == "crooked" and saved.paper.layout == "boat_leaf_star" and saved.paper.length == "long", "exact native carried sign remains")
	check(saved.paper.fold == "wider" and saved.paper.mode == "direct" and saved.paper.completed,"native paper completion remains")
	check(saved.camera_choice == "take" and saved.npc_state.mira.camera_memory == "take","native camera callback remains")
	check(saved.npc_state.mira.destination == "lower_mill" and saved.npc_state.mira.independent_decision,"native Mira autonomy unchanged")
	check(saved.action_resolution == "skipped" and saved.souvenir_ids == ["platform_six_journey"] and saved.fair.souvenir_ids == ["fair_button"],"native prior optional response and equal rewards remain")
	print("KITCHEN NATIVE SAVE ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
