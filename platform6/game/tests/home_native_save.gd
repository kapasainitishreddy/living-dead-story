extends SceneTree
const Model = preload("res://core/chapter_model.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	print("NATIVE ","PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func _initialize():
	var branches = []
	for branch in [["train","kettle","tea"],["sleep","drawer","window"]]:
		var path = "res://../evidence/home/native-" + branch[0] + "-save.json"
		check(FileAccess.file_exists(path),"actual native save exists " + branch[0])
		if not FileAccess.file_exists(path): continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		var model = Model.new()
		check(model.restore(data),"strict native save restores " + branch[0])
		if not model.valid(data): continue
		var s = model.snapshot()
		branches.append(s)
		check(s.campaign_chapter == "still_here" and s.home_checkpoint == "complete","home complete " + branch[0])
		check(s.campaign_complete and s.home.completed,"equal campaign completion " + branch[0])
		check(s.home.ending == branch[0] and s.home.ticket == branch[1] and s.home.ritual == branch[2],"actual keyboard choices retained " + branch[0])
		check(s.chapter_complete and s.fair_checkpoint == "complete" and s.paper.completed and s.kitchen.completed and s.orchard.completed and s.return_state.completed,"all earlier chapters retained " + branch[0])
		check(s.camera_choice == "lend" and s.action_resolution == "skipped","noncoercive prior camera/action retained " + branch[0])
		check(s.npc_state.mira.destination == "lower_mill" and s.npc_state.mira.independent_decision,"Mira retains independent life " + branch[0])
		check(s.return_state.farewell == "thanks","actual earlier farewell retained " + branch[0])
		check(s.souvenir_ids == ["platform_six_journey"] and s.fair.souvenir_ids == ["fair_button"],"no extra ending reward " + branch[0])
		check(not s.settings.reduced_motion,"native normal motion tested " + branch[0])
		check(s.choice_history.has("still_here.finish."+branch[0]),"distinct final trace " + branch[0])
	if branches.size() == 2:
		for key in ["souvenir_ids","fair","paper","kitchen","orchard","return_state","dimensions","npc_state","settings","history_compatibility"]:
			check(branches[0][key] == branches[1][key],"both actual endings preserve equal prior state " + key)
	print("HOME NATIVE SAVE ",checks," checks ",failures," failures")
	quit(0 if failures == 0 else 1)
