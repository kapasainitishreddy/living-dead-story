extends Node
func _ready():
	get_tree().root.content_scale_size = Vector2i(1280,720)
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	var game = load("res://main.gd").new()
	game.model.data.checkpoint_id = "conductor"
	game.save_path = "user://station_visual_preview_"+str(Time.get_ticks_usec())+".json"
	add_child(game)
	await get_tree().process_frame
	game.hud.close_all()
	game.resume_controls()
	var settings = game.model.snapshot().settings
	settings.graphics = "medium"
	game.change_settings(settings)
	game.player.position = Vector3(-1,0.1,5)
	game.player.pivot.rotation.y = -0.12
	game.player.arm.rotation.x = -0.22
