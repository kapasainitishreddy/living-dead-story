extends SceneTree
const Model = preload("res://core/chapter_model.gd")
const Store = preload("res://core/save_store.gd")
var checks := 0
var failures := 0
func check(condition: bool, label: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL ",label)
func step(model, action: String, value: Variant = null):
	check(model.apply(action,value),"matrix applies "+action)
	check(model.valid(model.snapshot()),"matrix state valid after "+action)
func _initialize():
	var count := 0
	var expected = {"left":{"triangle":"third","square":"third","folded":"circle"},"straight":{"triangle":"first","square":"second","folded":"circle"},"right":{"triangle":"second","square":"second","folded":"circle"}}
	for mode in ["operate","watch","cooperate"]:
		for rudder in ["left","straight","right"]:
			for sail in ["triangle","square","folded"]:
				var model = Model.new()
				for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]: step(model,action)
				step(model,"choose_camera",["take","lend","unused"][count%3])
				step(model,"resolve_action","completed" if count%2 == 0 else "skipped")
				for action in ["return_train","have_breakfast","finish","begin_fair"]: step(model,action)
				step(model,"fair_greeting",["ducks","watch","how"][count%3])
				step(model,"set_rudder",rudder)
				step(model,"set_sail",sail)
				step(model,"set_race_mode",mode)
				step(model,"release_boat")
				step(model,"inspect_fair",["boat","wedge","together","watch"][count%4])
				step(model,"level_pond","self" if count%2 == 0 else "ada")
				step(model,"release_boat")
				var outcome = "spectator" if mode == "watch" else ("second" if mode == "cooperate" else expected[rudder][sail])
				check(model.snapshot().fair.outcome == outcome,"matrix canonical outcome "+mode+"/"+rudder+"/"+sail)
				check(model.snapshot().fair.souvenir_ids == ["fair_button"],"matrix equal durable souvenir")
				var canonical = model.snapshot()
				step(model,"replay_race")
				check(model.snapshot().dimensions == canonical.dimensions and model.snapshot().npc_state == canonical.npc_state and model.snapshot().choice_history == canonical.choice_history,"matrix replay consequence idempotency")
				step(model,"fair_departure",["card","speak","wait"][count%3])
				check(model.snapshot().npc_state.mira.destination == "lower_mill","matrix independent destination")
				var reload = Model.new()
				check(reload.restore(JSON.parse_string(JSON.stringify(model.snapshot()))),"matrix JSON reload valid")
				check(reload.snapshot() == model.snapshot(),"matrix reload exact durable state")
				count += 1
	print("Fair branch matrix: %d routes; %d checks; failures: %d" % [count,checks,failures])
	quit(1 if failures else 0)
