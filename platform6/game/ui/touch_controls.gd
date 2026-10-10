extends CanvasLayer
# Local touch presentation uses the same player controller and interactions.
# Each finger owns one gesture; no global Input actions can become stuck.
signal movement_changed(value: Vector2)
signal look_dragged(value: Vector2)
signal interact_pressed
signal pause_pressed
signal reset_pressed
signal mode_changed(value: bool)

class Thumbstick extends Control:
	var displacement := Vector2.ZERO
	func _draw():
		draw_circle(Vector2(76,76), 68, Color(0.05,0.09,0.13,0.72))
		draw_arc(Vector2(76,76), 68, 0, TAU, 64, Color(0.80,0.72,0.51,0.85), 2, true)
		draw_circle(Vector2(76,76) + displacement * 54, 24, Color(0.85,0.77,0.56,0.85))

var touch_mode := OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
var walking := false
var move_finger := -1
var look_finger := -1
var button_fingers: Dictionary = {}
var axis := Vector2.ZERO
var root: Control
var stick: Thumbstick
var interact_button: Button
var pause_button: Button
var reset_button: Button
var look_hint: Label
var bottom_inset := 72.0
var modal_open: Callable

func _ready():
	layer = 3
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	stick = Thumbstick.new()
	stick.size = Vector2(152,152)
	stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stick)
	interact_button = make_button("Interact", Vector2(138,72))
	pause_button = make_button("Pause", Vector2(108,64))
	reset_button = make_button("Reset view", Vector2(138,64))
	look_hint = Label.new()
	look_hint.text = "Drag here to look"
	look_hint.add_theme_font_size_override("font_size",18)
	look_hint.add_theme_color_override("font_outline_color",Color("182534"))
	look_hint.add_theme_constant_override("outline_size",4)
	look_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(look_hint)
	root.visible = touch_mode
	layout()

func make_button(label: String, dimensions: Vector2) -> Button:
	var button = Button.new()
	button.text = label
	button.size = dimensions
	button.custom_minimum_size = dimensions
	button.add_theme_font_size_override("font_size",19)
	# Multi-touch is handled below; emulated mouse events must not double-fire.
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(button)
	return button

func set_touch_mode(value: bool):
	if touch_mode == value: return
	touch_mode = value
	root.visible = value
	cancel_input()
	mode_changed.emit(value)

func layout():
	var viewport_size = get_viewport().get_visible_rect().size
	stick.position = Vector2(32,viewport_size.y - bottom_inset - 164)
	reset_button.position = Vector2(viewport_size.x - reset_button.size.x - 38,viewport_size.y - bottom_inset - reset_button.size.y - 12)
	interact_button.position = Vector2(viewport_size.x - interact_button.size.x - 38,reset_button.position.y - interact_button.size.y - 14)
	pause_button.position = Vector2(viewport_size.x - pause_button.size.x - 38,20)
	look_hint.position = Vector2(viewport_size.x * 0.51,viewport_size.y - bottom_inset - 38)

func apply_settings(settings: Dictionary):
	var scale_: float = settings.get("text_scale",1.0)
	for button in [interact_button,pause_button,reset_button]:
		button.add_theme_font_size_override("font_size",int(19 * scale_))
		button.custom_minimum_size = Vector2(108 if button == pause_button else 138,64 if button != interact_button else 72)
		button.reset_size()
	look_hint.add_theme_font_size_override("font_size",int(18 * scale_))
	layout()

func set_available(can_walk: bool, can_interact: bool, can_pause: bool = true):
	if walking and not can_walk: cancel_input()
	walking = can_walk
	stick.visible = can_walk
	reset_button.visible = can_walk
	look_hint.visible = can_walk
	interact_button.visible = can_walk or can_interact
	interact_button.disabled = not can_interact
	pause_button.disabled = not can_pause

func cancel_input():
	move_finger = -1
	look_finger = -1
	button_fingers.clear()
	axis = Vector2.ZERO
	movement_changed.emit(axis)
	if stick != null:
		stick.displacement = Vector2.ZERO
		stick.queue_redraw()
	if root != null:
		for button in [interact_button,pause_button,reset_button]:
			if button != null: button.modulate = Color.WHITE

func update_stick(position_: Vector2):
	var raw = ((position_ - stick.position - Vector2(76,76)) / 54).limit_length()
	var magnitude = raw.length()
	axis = Vector2.ZERO if magnitude <= 0.14 else raw.normalized() * ((magnitude - 0.14) / 0.86)
	stick.displacement = raw
	stick.queue_redraw()
	movement_changed.emit(axis)

func _input(event):
	# A modal can open in the same OS input batch as another finger arrives.
	# Consult the controller immediately rather than waiting for _process.
	if walking and modal_open.is_valid() and modal_open.call(): set_available(false,false)
	if event is InputEventScreenTouch and event.pressed and not touch_mode:
		set_touch_mode(true)
	if not touch_mode: return
	if event is InputEventScreenTouch:
		if event.pressed:
			for button in [pause_button,interact_button,reset_button]:
				if button.visible and not button.disabled and button.get_global_rect().has_point(event.position):
					button_fingers[event.index] = button
					button.modulate = Color("e5c58c")
					get_viewport().set_input_as_handled()
					return
			if not walking: return
			if move_finger < 0 and stick.get_global_rect().grow(12).has_point(event.position):
				move_finger = event.index
				update_stick(event.position)
			elif look_finger < 0 and event.position.x > get_viewport().get_visible_rect().size.x * 0.45:
				look_finger = event.index
			else: return
		else:
			if button_fingers.has(event.index):
				var button: Button = button_fingers[event.index]
				button_fingers.erase(event.index)
				button.modulate = Color.WHITE
				if not event.canceled and button.visible and not button.disabled and button.get_global_rect().has_point(event.position):
					if button == pause_button: pause_pressed.emit()
					elif button == interact_button: interact_pressed.emit()
					else: reset_pressed.emit()
			elif event.index == move_finger:
				move_finger = -1
				update_stick(stick.position + Vector2(76,76))
			elif event.index == look_finger: look_finger = -1
			else: return
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == move_finger: update_stick(event.position)
		elif event.index == look_finger and walking: look_dragged.emit(event.relative)
		else: return
		get_viewport().set_input_as_handled()

func _process(_delta): layout()
func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: cancel_input()
