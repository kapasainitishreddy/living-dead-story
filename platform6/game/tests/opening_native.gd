extends SceneTree
var game
func _initialize(): call_deferred("run")
func run():
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate()
	game.save_path = OS.get_environment("OPENING_NATIVE_PATH")
	if game.save_path.is_empty(): game.save_path = "res://../evidence/opening/native-save.json"
	root.add_child(game)
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		root.get_texture().get_image().save_png("res://../evidence/opening/native-current.png")
		print("NATIVE_OPENING_CAPTURE ",game.model.snapshot().checkpoint_id)
