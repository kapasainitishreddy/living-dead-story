extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func _initialize():
	var file = "res://../evidence/return/linux-keyboard-save.json"
	check(FileAccess.file_exists(file), "actual native desktop save was copied, not recreated")
	if failures: quit(1); return
	var snapshot = JSON.parse_string(FileAccess.get_file_as_string(file))
	var m = load("res://core/chapter_model.gd").new()
	check(m.restore(snapshot), "real exported save passes strict model restore")
	check(snapshot.return_checkpoint == "complete" and snapshot.return_state.completed, "actual keyboard run completed Chapter Six")
	check(snapshot.return_state.farewell == "thanks", "actual arrow-key farewell retained")
	check(snapshot.camera_choice == "lend", "borrowed camera continuity retained")
	check(snapshot.return_state.conductor_revealed, "actual E interaction read conductor")
	check(not snapshot.return_state.jo_met, "optional Jo was not required for native completion")
	check(snapshot.npc_state.mira.destination == "lower_mill" and snapshot.npc_state.mira.independent_decision, "actual exported run preserves Mira's own destination")
	for key in ["chapter_complete", "chapter_world_flag"]: check(snapshot[key], "earlier chapter flag retained " + key)
	for field in ["fair_checkpoint", "paper_checkpoint", "kitchen_checkpoint", "orchard_checkpoint"]: check(snapshot[field] == "complete", "earlier chapter retained " + field)
	var seed = JSON.parse_string(FileAccess.get_file_as_string("res://../evidence/return/keyboard-seed.json"))
	for key in ["dimensions", "npc_state", "souvenir_ids", "action_resolution", "settings"]: check(snapshot[key] == seed[key], "actual standalone does not grade or change prior " + key)
	check(snapshot.choice_history.slice(0, seed.choice_history.size()) == seed.choice_history, "actual standalone preserves all prior traces")
	print("RETURN NATIVE SAVE ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
