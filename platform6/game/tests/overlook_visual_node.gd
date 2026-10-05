extends Node
func _ready():
	var game = load("res://main.gd").new()
	game.save_path = "user://qa_overlook_visual_"+str(Time.get_unix_time_from_system())+".json"
	game.model.data.checkpoint_id = "overlook"
	game.model.data.inspected_landmark_ids = ["lighthouse","arch","constellation"]
	add_child(game)
	await get_tree().process_frame
	game.player.position = Vector3(0,0.1,-5.3)
	await get_tree().create_timer(3).timeout
	get_viewport().get_texture().get_image().save_png("res://../evidence/screenshots/near-marker-fixed.png")
