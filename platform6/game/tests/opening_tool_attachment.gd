extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://opening_tool_attachment_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	for action in ["leave_apartment", "meet_stranger", "read_board", "board_train", "meet_passenger", "arrive_shore"]: game.model.apply(action)
	game.route()
	await process_frame
	await process_frame
	var world = game.world_container.get_child(0)
	var mira = world.get_node("Mira")
	var roll = world.find_child("ToolRoll", true, false)
	var attachment = roll.get_parent() if roll != null else null
	check(attachment is BoneAttachment3D, "carried tool roll is actually parented to a physical bone attachment")
	if attachment is BoneAttachment3D:
		var hand = mira._bone_index("HandLeft")
		check(attachment.bone_idx == hand and attachment.get_parent() == mira.skeleton, "tool ownership uses Mira’s original HandLeft bone")
		var hand_position = mira.skeleton.global_transform * mira.skeleton.get_bone_global_pose(hand).origin
		check(roll.global_position.distance_to(hand_position) < 0.24, "rolled tools hang within a hand-sized carrying distance")
		check(roll.global_position.y < hand_position.y, "rolled tools hang below the hand rather than crossing the waist")
		var bind = attachment.global_transform.affine_inverse() * roll.global_transform
		var before = roll.global_position
		# This is a real skeletal pose change, not an owner-position metadata check.
		var pose = mira.skeleton.get_bone_pose_position(hand)
		mira.set_process(false)
		mira.animation_tree.active = false
		mira.skeleton.set_bone_pose_position(hand, pose + Vector3(0.07, 0.11, 0.02))
		mira.skeleton.force_update_all_bone_transforms()
		await process_frame
		await process_frame
		check(roll.global_position.distance_to(before) > 0.06, "tool roll follows an actual changed hand-bone pose")
		check((attachment.global_transform.affine_inverse() * roll.global_transform).is_equal_approx(bind), "skeletal motion preserves the physical grip transform")
	check(roll != null and roll.find_children("*", "GeometryInstance3D", true, false).size() >= 3, "hand-owned tool roll contains actual rolled cloth, straps and tools")
	for choice in ["unselected", "take", "lend", "unused"]:
		game.model = load("res://core/chapter_model.gd").new()
		for action in ["leave_apartment", "meet_stranger", "read_board", "board_train", "meet_passenger", "arrive_shore"]: game.model.apply(action)
		if choice != "unselected": game.model.apply("assist"); game.model.apply("choose_camera", choice)
		game.route()
		await process_frame
		await process_frame
		world = game.world_container.get_child(0)
		mira = world.get_node("Mira")
		var real_cameras = []
		for node in world.find_children("*", "Node3D", true, false):
			if node.scene_file_path == "res://assets/characters/mira/camera.glb" and node.is_visible_in_tree(): real_cameras.append(node)
		check(real_cameras.size() == (1 if choice in ["take", "lend"] else 0), "exact visible original camera count for " + choice)
		check(world.find_child("DisposableCamera", true, false) == null, "no duplicate primitive camera on " + choice + " route")
		if choice == "unused":
			var box = world.find_child("CameraBox", true, false)
			check(box != null and not box.is_visible_in_tree(), "unused route puts the unopened box away as authored")
		if choice == "take" and real_cameras.size() == 1:
			check(real_cameras[0].get_parent() == game.player.visual.prop_socket and real_cameras[0].get_parent() is BoneAttachment3D, "take gives the actual original camera to the protagonist’s hand")
		if choice == "lend" and real_cameras.size() == 1:
			check(real_cameras[0] == mira.get_attached_prop("camera") and real_cameras[0].get_parent() == mira.prop_socket, "lend uses Mira’s existing original camera hand attachment")
	game.queue_free(); await process_frame
	print("Opening tool attachment: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
