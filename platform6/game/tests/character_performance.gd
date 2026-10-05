extends SceneTree
# Replacing the GLB performer with factory.person(), removing the AnimationTree,
# disconnecting conversation gaze, or leaving motion on after a preference toggle
# must fail this production contract. Tests exercise the actual imported rig.
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func run():
	var controller_path = "res://characters/character_performer.gd"
	check(FileAccess.file_exists(controller_path),"production imported-rig character controller exists")
	if not FileAccess.file_exists(controller_path):
		print("Character performance checks: %d; failures: %d" % [checks,failures])
		quit(1)
		return
	var controller = load(controller_path)
	for character_id in ["protagonist","mira"]:
		var actor = controller.new()
		actor.configure(character_id)
		root.add_child(actor)
		await process_frame
		check(actor.model != null and actor.model.scene_file_path.ends_with(".glb"),character_id + " uses imported production GLB")
		check(actor.skeleton is Skeleton3D and actor.skeleton.get_bone_count() >= 20,character_id + " has a genuine articulated skeleton")
		var meshes = actor.model.find_children("*","MeshInstance3D",true,false) if actor.model else []
		var authored_meshes = meshes.size() > 0
		var skinned_surfaces = 0
		for mesh in meshes:
			authored_meshes = authored_meshes and mesh.mesh is ArrayMesh
			if mesh.skin != null: skinned_surfaces += 1
		check(authored_meshes,character_id + " uses authored mesh surfaces instead of primitive body parts")
		check(skinned_surfaces >= 10,character_id + " body and facial surfaces are actually skin-bound")
		check(actor.animation_tree is AnimationTree and actor.animation_tree.active,character_id + " has active AnimationTree blending")
		check(actor.animation_player != null and actor.animation_player.has_animation("idle") and actor.animation_player.has_animation("walk"),character_id + " imports authored idle and walk clips")
		if actor.animation_player:
			check(actor.animation_player.get_animation("idle").loop_mode == Animation.LOOP_LINEAR and actor.animation_player.get_animation("walk").loop_mode == Animation.LOOP_LINEAR,character_id + " locomotion clips repeat beyond first cycle")
		check(actor.prop_socket is BoneAttachment3D and actor.prop_socket.bone_idx >= 0,character_id + " right-hand prop socket follows a rig bone")
		check(actor.has_node("HeadSocket"),character_id + " head socket exposes stable attachment point")
		actor.set_process(false)
		if actor.animation_tree and actor.animation_player and actor.skeleton:
			var stance_bone = actor.skeleton.find_bone("FootLeft")
			actor.animation_tree.active = false
			actor.animation_player.play("walk")
			actor.animation_player.seek(0.0,true)
			var stance_start = actor.skeleton.get_bone_global_pose(stance_bone).origin
			actor.animation_player.seek(0.5,true)
			var stance_end = actor.skeleton.get_bone_global_pose(stance_bone).origin
			check(absf((stance_start.z-stance_end.z)/0.5 - actor.WALK_REFERENCE_SPEED) < 0.005,character_id + " imported stance stride agrees with cadence reference")
			check(absf(stance_start.y-stance_end.y) < 0.025,character_id + " authored flat-ground stance has bounded ankle drift")
			actor.animation_player.stop()
			actor.animation_tree.active = true
			actor.animation_tree.advance(0.0)
		actor.set_locomotion(1.2)
		for i in range(60): actor.advance_performance(1.0/60.0)
		var slow_cadence = actor.animation_tree.get("parameters/WalkTempo/scale") if actor.animation_tree else null
		check(actor.locomotion_blend > 0.9,character_id + " normal walking speed uses full stride before cadence scaling")
		actor.set_locomotion(4.2)
		for i in range(60): actor.advance_performance(1.0/60.0)
		var fast_cadence = actor.animation_tree.get("parameters/WalkTempo/scale") if actor.animation_tree else null
		check(slow_cadence != null and fast_cadence != null,character_id + " walk animation has a real TimeScale node")
		if slow_cadence != null and fast_cadence != null:
			check(fast_cadence > slow_cadence + 0.3 and fast_cadence <= 3.2,character_id + " cadence follows actual speed within a bounded range")
			check(absf(fast_cadence - 4.2/1.3165) < 0.03,character_id + " cadence uses authored reference speed rather than fixed multiplier")
		actor.set_locomotion(4.2,0.45)
		for i in range(30): actor.advance_performance(1.0/60.0)
		check(actor.locomotion_blend > 0.9,character_id + " walk blend follows actual speed")
		if actor.skeleton:
			var leg_index = actor.skeleton.find_bone("ThighLeft")
			if leg_index >= 0:
				var first_pose = actor.skeleton.get_bone_pose_rotation(leg_index)
				var largest_change := 0.0
				for i in range(60):
					actor.advance_performance(1.0/60.0)
					largest_change = maxf(largest_change,first_pose.angle_to(actor.skeleton.get_bone_pose_rotation(leg_index)))
				check(largest_change > 0.025,character_id + " walk blend produces real limb deformation")
		check(abs(actor.turn_amount) > 0.05,character_id + " turn weight is separate from walk")
		var listener = Node3D.new()
		listener.position = Vector3(1.4,0,3)
		root.add_child(listener)
		actor.set_conversation(true,listener)
		for i in range(30): actor.advance_performance(1.0/60.0)
		check(actor.conversation_blend > 0.9 and actor.gaze_target == listener,character_id + " conversation targets listener")
		check(abs(actor.gaze_yaw) > 0.03 and abs(actor.gaze_yaw) <= actor.MAX_HEAD_YAW,character_id + " bounded conversational gaze")
		check(actor.locomotion_blend < 0.1,character_id + " conversation settles locomotion")
		if actor.skeleton:
			var head_index = actor.skeleton.find_bone("Head")
			var eye_index = actor.skeleton.find_bone("EyeLeft")
			check(head_index >= 0 and eye_index >= 0 and actor.skeleton.find_bone("EyeRight") >= 0,character_id + " facial rig includes independent eyes and head")
			if head_index >= 0 and eye_index >= 0:
				for i in range(240): actor.advance_performance(1.0/60.0)
				check(actor.skeleton.get_bone_pose_rotation(head_index).get_angle() < 0.72,character_id + " repeated gaze does not accumulate bone rotation")
				check(actor.skeleton.get_bone_pose_rotation(eye_index).get_angle() < 0.27,character_id + " independent eye rotation remains restrained")
				actor.elapsed = 4.07 if character_id == "mira" else 0.07
				actor.advance_performance(0.0)
				check(actor.skeleton.get_bone_pose_scale(eye_index).y < 0.35,character_id + " eyelid blink deforms actual eye bone")
		actor.apply_preferences(true)
		actor.advance_performance(0.2)
		check(is_zero_approx(actor.secondary_motion_weight),character_id + " reduced motion stops idle secondary animation")
		if actor.skeleton and actor.skeleton.find_bone("EyeLeft") >= 0:
			var eye_index = actor.skeleton.find_bone("EyeLeft")
			check(actor.skeleton.get_bone_pose_scale(eye_index).is_equal_approx(Vector3.ONE),character_id + " reduced motion restores open eye from in-flight blink")
			actor.advance_performance(1.0)
			check(actor.skeleton.get_bone_pose_scale(eye_index).is_equal_approx(Vector3.ONE),character_id + " reduced motion keeps eye bone stable")
		actor.set_conversation(false)
		actor.set_locomotion(4.2,0.0)
		for i in range(30): actor.advance_performance(1.0/60.0)
		check(actor.locomotion_blend > 0.9,character_id + " reduced motion retains necessary walking animation")
		actor.apply_preferences(false)
		actor.advance_performance(0.2)
		check(actor.secondary_motion_weight > 0.0,character_id + " motion preference restores secondary animation")
		actor.queue_free()
		listener.queue_free()
		await process_frame
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://characters_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	check(game.player.visual.has_method("set_locomotion"),"player delegates presentation to production controller")
	check(game.player.visual.get_node_or_null("ArmLeft") == null,"player no longer requires primitive limb nodes")
	for action in ["leave_apartment","meet_stranger","read_board","board_train"]: game.model.apply(action)
	game.route()
	await process_frame
	var world = game.world_container.get_child(0)
	var mira = world.get_node_or_null("Mira")
	check(mira != null and mira.has_method("set_conversation"),"Mira production performer replaces passenger primitive")
	if mira:
		check(mira.get_attached_prop("camera") != null,"Mira camera uses right-hand prop socket")
		var marker = null
		for node in world.get_children():
			if node.get_meta("action_id","") == "meet_passenger": marker = node
		game.on_interact(marker)
		await process_frame
		check(mira.conversing and mira.gaze_target == game.player,"Mira dialogue engages player gaze")
		game.dispatch("dismiss")
		check(not mira.conversing,"dismissing dialogue restores exploration performance")
		var settings = game.model.snapshot().settings
		settings.reduced_motion = true
		game.change_settings(settings)
		check(is_zero_approx(mira.secondary_motion_weight),"NPC reduced motion follows live setting changes")
	game.queue_free()
	await process_frame
	print("Character performance checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
