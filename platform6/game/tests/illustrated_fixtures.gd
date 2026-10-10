extends RefCounted
# Canonical authored model transitions, shared by coverage and actual rendering.
var entries: Array = []
var completed: Dictionary = {}
func _init():
	var model = load("res://core/chapter_model.gd").new()
	remember(model,"01-apartment")
	var sequence = [["leave_apartment",null],["meet_stranger",null],["read_board",null],["board_train",null],["meet_passenger",null],["arrive_shore",null],["assist",null],["choose_camera","lend"],["resolve_action","skipped"],["return_train",null],["have_breakfast",null],["finish",null],["begin_fair",null],["fair_greeting","watch"],["set_race_mode","watch"],["release_boat",null],["inspect_fair","watch"],["level_pond","ada"],["release_boat",null],["fair_departure","wait"],["begin_paper",null],["paper_greeting","begin"],["set_paper_star","empty"],["set_paper_layout","star_boat_leaf"],["set_paper_length","long"],["set_paper_mode","watch"],["set_paper_fold","enough"],["raise_paper",null],["finish_paper",null],["begin_kitchen",null],["kitchen_join","watch"],["kitchen_share","watch"],["kitchen_departure","listen"],["begin_orchard",null],["orchard_route","bench"],["orchard_advance",null],["orchard_advance",null],["orchard_advance",null],["orchard_finish",null],["begin_return",null],["return_arrival",null],["return_farewell","wave"],["return_departure",null],["return_finish",null],["begin_home",null],["home_ticket","drawer"],["home_ritual","neither"],["home_finish","sleep"]]
	var names = {"leave_apartment":"02-roof","meet_stranger":"03-platform","board_train":"04-carriage","arrive_shore":"05-overlook","return_train":"06-breakfast","begin_fair":"07-fair","begin_paper":"08-paper-sky","begin_kitchen":"09-night-kitchen","begin_orchard":"10-quiet-orchard","begin_return":"11-return-platform","begin_home":"12-home"}
	for pair in sequence:
		if not model.apply(pair[0],pair[1]): push_error("Invalid illustrated fixture transition " + pair[0])
		if names.has(pair[0]): remember(model,names[pair[0]])
	completed = model.snapshot()

func remember(model, id: String):
	entries.append({"id":id,"snapshot":model.snapshot()})
