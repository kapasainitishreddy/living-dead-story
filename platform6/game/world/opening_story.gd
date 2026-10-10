extends Node3D
# Physical staging for the existing Chapter One beats, rebuilt from saved state.
# This layer owns no collision, navigation, progression, rewards or save schema.
const Factory = preload("res://world/world_factory.gd")
const CARRIAGE = ["passenger", "shoreline", "return_train", "breakfast", "complete"]
const SHORE = ["overlook", "camera_choice", "optional_action"]
var factory = Factory.new()
var props: Node3D
var world: Node3D
var player: Node3D
var state: Dictionary
var framing_camera: Camera3D
var previewing := false
var reduced := false
var paused := false
var gesture: Tween
var gesture_finish: Callable
var local_camera: Camera3D
var played_beats: Array = []
var held: Array = []
var tool_roll: Node3D
func group(parent: Node3D, id: String, position_: Vector3 = Vector3.ZERO) -> Node3D:
	var node = Node3D.new()
	node.name = id
	node.position = position_
	parent.add_child(node)
	return node
func cube(parent: Node3D, id: String, position_: Vector3, size_: Vector3, color_: Color) -> Node3D:
	return factory.box(parent, id, position_, size_, color_, false)
func configure(snapshot: Dictionary, protagonist: Node3D):
	state = snapshot.duplicate(true)
	played_beats = state.choice_history.duplicate()
	player = protagonist
	world = get_parent()
	props = group(self, "Props")
	reduced = bool(state.settings.reduced_motion)
	var checkpoint: String = state.checkpoint_id
	if checkpoint == "roof":
		var star = group(props, "UmbrellaPaperStar", Vector3(0.14, 1.66, -4))
		for i in range(5):
			var point = cube(star, "Point", Vector3.ZERO, Vector3(0.038, 0.23, 0.012), Color("d8b877"))
			point.rotation.z = i * TAU / 5 + 0.23
		cube(star, "Thread", Vector3(0, 0.18, 0), Vector3(0.008, 0.22, 0.008), Color("ac966f"))
	if checkpoint in ["platform", "conductor"]:
		var ticket = ticket_prop()
		if checkpoint == "platform":
			var bench = group(props, "TicketBench", Vector3(0, 0, -6))
			cube(bench, "Seat", Vector3(0, 0.62, 0), Vector3(1.25, 0.095, 0.52), Color("947157"))
			for x in [-0.48, 0.48]: cube(bench, "Leg", Vector3(x, 0.31, 0), Vector3(0.08, 0.62, 0.42), Color("35435b"))
			ticket.position = Vector3(0.06, 0.681, -6)
		else:
			ticket.set_meta("held", true)
			hold(ticket, player, Vector3(-0.25, 1.00, -0.27))
	if checkpoint in CARRIAGE + SHORE:
		# Mira remains on the same shore while the private optional invitation is open.
		if checkpoint == "optional_action" and not world.has_node("Mira"):
			var companion = factory.production_character(world, Vector3(1, 0, -3), "mira")
			companion.apply_preferences(reduced)
			companion.set_attention_target(player)
		camera_props()
		tools_prop()
	if checkpoint in CARRIAGE:
		window_props()
		# A real unlatched door stands at the carriage end the player boarded.
		var door = group(props, "CarriageDoor", Vector3(0, 0, -10.90))
		cube(door, "Panel", Vector3(0.60 if checkpoint == "shoreline" else 0, 1.5, 0), Vector3(1.15, 2.80, 0.08), Color("657f79"))
		cube(door, "Handle", Vector3(0.28, 1.22, 0.09), Vector3(0.07, 0.17, 0.08), Color("c5a56f"))
	if checkpoint in ["return_train", "breakfast", "complete"]: breakfast_props()
	if checkpoint in SHORE:
		var stand = group(props, "ViewingFrame", Vector3(0, 0.0, -1))
		for x in [-0.60, 0.60]: cube(stand, "Upright", Vector3(x, 1.10, 0), Vector3(0.045, 0.62, 0.045), Color("bfa36f"))
		for y in [0.80, 1.40]: cube(stand, "Crossbar", Vector3(0, y, 0), Vector3(1.245, 0.045, 0.045), Color("bfa36f"))
		framing_camera = Camera3D.new()
		framing_camera.name = "FramingCamera"
		framing_camera.near = 0.1
		framing_camera.far = 150.0
		add_child(framing_camera)
		set_alignment(int(state.overlook_alignment))
	set_process(not held.is_empty())
func ticket_prop() -> Node3D:
	var ticket = group(props, "Ticket")
	cube(ticket, "Paper", Vector3.ZERO, Vector3(0.31, 0.008, 0.20), Color("eee1bd"))
	for x in [-0.115, 0.115]: cube(ticket, "Edge", Vector3(x, 0.005, 0), Vector3(0.012, 0.001, 0.17), Color("c7a970"))
	if state.chapter_complete:
		for i in range(3): cube(ticket, "Stamp", Vector3(-0.04 + i * 0.03, 0.006, 0), Vector3(0.012, 0.002, 0.10), Color("597882"))
	return ticket
func hold(node: Node3D, owner: Node3D, offset: Vector3):
	held.append({"node": node, "owner": owner, "offset": offset})
	update_held()
func update_held():
	for item in held:
		if is_instance_valid(item.node) and is_instance_valid(item.owner):
			item.node.global_position = item.owner.global_position + item.offset
func attach_to_hand(node: Node3D, actor: Node3D, hand_name: String, offset: Vector3) -> BoneAttachment3D:
	var index: int = actor._bone_index(hand_name)
	if index < 0: return null
	var socket = BoneAttachment3D.new()
	socket.name = "Opening" + str(node.name) + "Socket"
	socket.bone_name = actor.skeleton.get_bone_name(index)
	socket.bone_idx = index
	actor.skeleton.add_child(socket)
	# Establish the real bone transform now; future animated poses drive it.
	socket.transform = actor.skeleton.get_bone_global_pose(index)
	node.reparent(socket, false)
	node.transform = Transform3D(socket.global_basis.inverse(), socket.global_basis.inverse() * offset)
	return socket
func camera_props():
	var mira = world.get_node_or_null("Mira")
	if not is_instance_valid(mira): return
	var camera = mira.get_attached_prop("camera")
	if is_instance_valid(camera):
		camera.visible = state.camera_choice in ["take", "lend"]
		if state.camera_choice == "take":
			# Transfer the one authored camera GLB to the existing protagonist socket.
			mira.props.erase("camera")
			camera.reparent(player.visual.prop_socket, false)
			player.visual.props["camera"] = camera
	var camera_box = group(props, "CameraBox")
	camera_box.set_meta("unopened", state.camera_choice in ["unselected", "unused"])
	cube(camera_box, "Cardboard", Vector3.ZERO, Vector3(0.31, 0.22, 0.20), Color("c09864"))
	cube(camera_box, "Lid", Vector3(0, 0.118, 0), Vector3(0.325, 0.020, 0.215), Color("ddc79c"))
	cube(camera_box, "PaperBand", Vector3(0, 0.006, 0.105), Vector3(0.11, 0.18, 0.007), Color("eee1bd"))
	if state.camera_choice in ["take", "lend"]:
		# The packaging is put away after opening; only the original camera remains.
		camera_box.hide()
	else:
		attach_to_hand(camera_box, mira, "HandRight", Vector3(0, -0.12, 0.045))
		if state.camera_choice == "unused": camera_box.hide() # Put away unopened, as authored.
func tools_prop():
	var mira = world.get_node_or_null("Mira")
	tool_roll = group(props, "ToolRoll")
	tool_roll.set_meta("on_spare_seat", state.checkpoint_id == "passenger" and "platform_six.dialogue.passenger_quiet" not in state.choice_history)
	# Compact rolled canvas with two straps, rather than a flat waist-wide plank.
	factory.rounded(tool_roll, "RolledCloth", Vector3.ZERO, 0.072, 0.072, 0.29, Color("856c56"))
	for y in [-0.073, 0.073]: factory.rounded(tool_roll, "LeatherStrap", Vector3(0, y, 0), 0.077, 0.077, 0.023, Color("bba074"))
	for x in [-0.032, 0.0, 0.032]:
		cube(tool_roll, "ScrewdriverHandle", Vector3(x, 0.155, 0.012), Vector3(0.022, 0.050, 0.025), Color("bca67b"))
	var bent = group(tool_roll, "BentPropeller", Vector3(0.052, -0.04, 0.056))
	for side in [-1.0, 1.0]:
		var blade = cube(bent, "Blade", Vector3(side * 0.035, 0, 0), Vector3(0.07, 0.012, 0.026), Color("c3a068"))
		blade.rotation.z = side * 0.28
	if tool_roll.get_meta("on_spare_seat"):
		tool_roll.position = Vector3(2.45, 1.06, -3.48)
		tool_roll.rotation.z = PI / 2
	elif is_instance_valid(mira): attach_to_hand(tool_roll, mira, "HandLeft", Vector3(0, -0.16, 0.025))
func window_props():
	# The finished carriage sill is at 2.02 m. Keep the handle and paper boat
	# above its seat back, rather than staging them behind the upholstery.
	var latch = group(props, "WindowLatch", Vector3(-3.59, 2.43, 1.0))
	cube(latch, "LiftHandle", Vector3(0, 0.07, 0), Vector3(0.045, 0.19, 0.050), Color("c4a374"))
	var pane = group(props, "SlidingWindow", Vector3(-3.67, 2.80, 1.0))
	for y in [-0.61, 0.61]: cube(pane, "HorizontalRail", Vector3(0, y, 0), Vector3(0.06, 0.055, 1.35), Color("b79968"))
	for z in [-0.64, 0.64]: cube(pane, "VerticalRail", Vector3(0, 0, z), Vector3(0.06, 1.26, 0.055), Color("b79968"))
	var boat = world.get_node_or_null("PaperBoat")
	var sail = world.get_node_or_null("PaperSail")
	if boat != null: boat.position = Vector3(-3.76,2.125,1.08)
	if sail != null: sail.position = Vector3(-3.76,2.265,1.08)
	if "platform_six.dialogue.train_window" in state.choice_history or state.checkpoint_id in ["return_train", "breakfast", "complete"]:
		open_window()
func open_window():
	var latch = props.get_node_or_null("WindowLatch")
	var pane = props.get_node_or_null("SlidingWindow")
	if latch != null: latch.rotation.z = -0.85
	if pane != null: pane.position.z = 0.20
func breakfast_props():
	# The two authored cups replace the original prototype's glowing sphere.
	for child in world.get_children():
		if child is MeshInstance3D and child.mesh is SphereMesh and child.position.is_equal_approx(Vector3(0.5,0.9,-4)):
			child.hide()
	var cups = group(props, "BreakfastCups")
	for x in [-0.38, 0.42]:
		factory.rounded(cups, "Saucer", Vector3(x, 0.801, -4.04), 0.175, 0.175, 0.018, Color("dfd4b8"))
		factory.rounded(cups, "Cup", Vector3(x, 0.899, -4.04), 0.117, 0.10, 0.18, Color("abc0ba"))
		factory.rounded(cups, "Tea", Vector3(x, 0.99, -4.04), 0.104, 0.104, 0.004, Color("71533a"))
		var handle = factory.orb(cups, Vector3(x + 0.125, 0.90, -4.04), 0.065, Color("abc0ba"))
		handle.scale = Vector3(0.4, 1, 0.30)
	var paper = group(props, "FoldedTimetable", Vector3(0.47, 0.798, -4.04))
	var fold = cube(paper, "Fold", Vector3.ZERO, Vector3(0.19, 0.015, 0.11), Color("eee1bd"))
	fold.rotation.z = 0.045
	var toast = group(props, "Toast", Vector3(0.03, 0.80, -3.75))
	for side in [-1.0, 1.0]:
		var slice = cube(toast, "Slice", Vector3(side * 0.15, 0.022, 0), Vector3(0.22, 0.04, 0.22), Color("b98a54"))
		slice.rotation.y = side * 0.12
		cube(slice, "Crumb", Vector3(0, 0.024, 0), Vector3(0.185, 0.007, 0.18), Color("e8c995"))
	var jam = group(props, "Jam", Vector3(-0.01, 0.86, -4.36))
	factory.rounded(jam, "PlumJar", Vector3.ZERO, 0.095, 0.095, 0.13, Color("73546a"))
	factory.rounded(jam, "Lid", Vector3(0, 0.073, 0), 0.102, 0.102, 0.025, Color("c2ad83"))
	var card = world.get_node_or_null("FairPostcard")
	if card != null:
		# Keep the card in a clear place setting rather than beneath a saucer.
		card.position = Vector3(-0.79,0.79,-3.72)
		cube(card, "ReverseArrow", Vector3(0, -0.010, 0.10), Vector3(0.22, 0.003, 0.01), Color("66837d"))
		for side in [-1.0, 1.0]:
			var head = cube(card, "ArrowHead", Vector3(0.08, -0.010, 0.10 + side * 0.03), Vector3(0.09, 0.003, 0.01), Color("66837d"))
			head.rotation.y = side * 0.65
		var opening_hours = Label3D.new()
		opening_hours.name = "HandwrittenOpeningHours"
		opening_hours.text = "OPEN WHEN\nTHE KETTLE BOILS"
		opening_hours.font_size = 32
		opening_hours.pixel_size = 0.0012
		opening_hours.modulate = Color("425f66")
		opening_hours.outline_size = 0
		opening_hours.position = Vector3(0, -0.013, -0.04)
		opening_hours.basis = Basis(Vector3.RIGHT, PI / 2) * Basis(Vector3.BACK, PI)
		card.add_child(opening_hours)
		if "platform_six.dialogue.breakfast_postcard" in state.choice_history: card.rotation.z = PI
	if state.checkpoint_id == "complete": ticket_prop().position = Vector3(0.38, 0.80, -3.75)
func local_beat(id: String):
	finish_gesture()
	var remembered = "platform_six.dialogue." + id
	if remembered not in played_beats:
		played_beats.append(remembered)
		if id == "train_window": animate_window()
		if id == "breakfast_postcard": animate_postcard()
	if id == "passenger_quiet":
		var roll = tool_roll
		var mira = world.get_node_or_null("Mira")
		if roll != null and is_instance_valid(mira):
			roll.rotation.z = -0.16
			if roll.get_meta("on_spare_seat", false):
				roll.set_meta("on_spare_seat", false)
				attach_to_hand(roll, mira, "HandLeft", Vector3(0, -0.16, 0.025))

func animate_window():
	var latch = props.get_node_or_null("WindowLatch")
	var pane = props.get_node_or_null("SlidingWindow")
	if latch == null or pane == null: return
	gesture_finish = open_window
	if reduced:
		finish_gesture()
		return
	gesture = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	gesture.tween_property(latch, "rotation:z", -0.85, 0.28)
	gesture.tween_interval(0.08)
	gesture.tween_property(pane, "position:z", 0.20, 0.62)
	gesture.tween_callback(finish_gesture)

func animate_postcard():
	var card = world.get_node_or_null("FairPostcard")
	if card == null: return
	var resting_height: float = card.position.y
	gesture_finish = func():
		if is_instance_valid(card):
			card.rotation.z = PI
			card.position.y = resting_height
	if reduced:
		finish_gesture()
		return
	# Lift before turning so the original card never passes through the table.
	gesture = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	gesture.tween_property(card, "position:y", resting_height + 0.29, 0.24)
	gesture.tween_property(card, "rotation:z", PI, 0.62)
	gesture.tween_property(card, "position:y", resting_height, 0.25)
	gesture.tween_callback(finish_gesture)

func finish_gesture():
	if gesture != null and gesture.is_valid(): gesture.kill()
	gesture = null
	if gesture_finish.is_valid(): gesture_finish.call()
	gesture_finish = Callable()

func begin_local_view(id: String):
	if id not in ["train_window", "breakfast_postcard"] or reduced: return
	if local_camera == null:
		local_camera = Camera3D.new()
		local_camera.name = "EverydayCamera"
		add_child(local_camera)
	# Explicit object interactions use stationary cuts. The player's orbit is
	# retained, and reduced motion leaves the exploration camera untouched.
	if id == "train_window":
		local_camera.position = Vector3(-1.95,3.02,2.2)
		local_camera.look_at(Vector3(-3.64,2.36,1.0), Vector3.UP)
		local_camera.fov = 43.0
		local_camera.h_offset = 0.66
	else:
		local_camera.position = Vector3(-0.70,1.78,-2.65)
		local_camera.look_at(Vector3(-0.74,0.87,-3.82), Vector3.UP)
		local_camera.fov = 43.0
		local_camera.h_offset = 0.52
	local_camera.current = true
func set_alignment(value: int):
	if framing_camera == null: return
	# All viewpoints observe the real, authored landmark geometry. The first
	# two crop out a discovered shape; stepping back keeps all three together.
	var locations = [Vector3(-5.8, 2.3, -4.7), Vector3(3.0, 2.3, -5.0), Vector3(-0.3, 2.8, 1.0)]
	var looks = [Vector3(-8, 4.4, -13), Vector3(1.6, 4.3, -16), Vector3(-0.1, 4.7, -16)]
	framing_camera.position = locations[value]
	framing_camera.fov = 37.0 if value < 2 else 76.0
	framing_camera.look_at(looks[value], Vector3.UP)
	# The choice panel uses the right third. Move the physical viewing camera
	# sideways so the three shapes occupy the unobscured part of the screen.
	framing_camera.h_offset = 5.0 if value == 2 else 0.0
func begin_preview(value: int):
	set_alignment(value)
	previewing = true
	framing_camera.current = true
func end_preview():
	finish_gesture()
	if local_camera != null: local_camera.current = false
	if not previewing: return
	previewing = false
	if framing_camera != null: framing_camera.current = false
	if is_instance_valid(player):
		var camera = player.find_child("Camera3D", true, false)
		if camera != null: camera.current = true
func apply_preferences(value: bool):
	reduced = value
	if reduced:
		finish_gesture()
		if local_camera != null and local_camera.current:
			local_camera.current = false
			if is_instance_valid(player):
				player.arm.get_child(0).current = true
				player.visual.visible = player.dialogue_visual_was_visible
func set_paused(value: bool):
	paused = value
	if gesture != null and gesture.is_valid():
		if paused: gesture.pause()
		else: gesture.play()
func _process(_delta):
	if not paused: update_held()
