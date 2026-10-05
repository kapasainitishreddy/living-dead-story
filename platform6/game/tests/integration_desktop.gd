extends "res://tests/integration.gd"
# Desktop window managers may resize the outer window; keep logical viewport exact.
func _initialize():
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	super()
