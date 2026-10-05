extends Node
func _ready():
	var game = load("res://main.gd").new()
	game.save_path = "user://qa_chapter_playtest_"+str(Time.get_unix_time_from_system())+".json"
	add_child(game)
