extends SceneTree
# These tests sample real imported bone transforms. Replacing irregular blinks
# with a metronome, tying eyes to the head, or restoring the slow stop blend fails.
var checks := 0
var failures := 0

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _initialize(): call_deferred("run")

func eye_scale_at(actor, time: float) -> float:
	actor.elapsed = time
	actor.advance_performance(0.0)
	return actor.skeleton.get_bone_pose_scale(actor._bone_index("EyeLeft")).y

func run():
	var controller = load("res://characters/character_performer.gd")
	for character_id in ["protagonist", "mira"]:
		var actor = controller.new()
		actor.configure(character_id)
		root.add_child(actor)
		actor.set_process(false)
		await process_frame
		check(actor.skeleton.get_bone_count() == 25, character_id + " keeps the production 25-bone rig")
		var first_blink := 4.0 if character_id == "mira" else 0.0
		var closing = eye_scale_at(actor, first_blink + 0.03)
		var opening = eye_scale_at(actor, first_blink + 0.11)
		check(closing > opening + 0.18, character_id + " blink closes faster than it reopens")
		check(eye_scale_at(actor, first_blink + 0.07) < 0.25, character_id + " blink reaches a readable closed pose")
		check(is_equal_approx(eye_scale_at(actor, first_blink + 0.24), 1.0), character_id + " blink returns fully open")
		var blink_starts: Array[float] = []
		var previously_closed := false
		var closed_frames := 0
		for frame in range(1800):
			var time := first_blink + 0.25 + float(frame) / 60.0
			var closed := eye_scale_at(actor, time) < 0.8
			if closed and not previously_closed: blink_starts.append(time)
			if closed: closed_frames += 1
			previously_closed = closed
		var shortest := 100.0
		var longest := 0.0
		for index in range(1, blink_starts.size()):
			var interval = blink_starts[index] - blink_starts[index - 1]
			shortest = minf(shortest, interval)
			longest = maxf(longest, interval)
		check(blink_starts.size() >= 5 and longest - shortest > 1.0, character_id + " blink intervals have an authored non-metronomic rhythm")
		check(shortest >= 2.5 and longest <= 6.5 and closed_frames < 95, character_id + " blink rhythm leaves sustained readable open-eye holds")

		actor.elapsed = 1.0
		actor.gaze_yaw = 0.0
		actor.gaze_pitch = 0.0
		var listener = Node3D.new()
		listener.position = Vector3(2.0, 0, 3.0)
		root.add_child(listener)
		actor.set_conversation(true, listener)
		actor.advance_performance(0.06)
		var head = actor.skeleton.get_bone_pose_rotation(actor._bone_index("Head"))
		var eye = actor.skeleton.get_bone_pose_rotation(actor._bone_index("EyeLeft"))
		var acquisition_head = head.get_angle()
		var acquisition_eye = eye.get_angle()
		check(acquisition_eye > acquisition_head + 0.02, character_id + " eyes acquire a new listener before the head catches up")
		for frame in range(180): actor.advance_performance(1.0 / 60.0)
		var eye_min := 100.0
		var eye_max := 0.0
		var head_max := 0.0
		var first_head = actor.skeleton.get_bone_pose_rotation(actor._bone_index("Head"))
		for frame in range(600):
			actor.advance_performance(1.0 / 60.0)
			var current_eye = actor.skeleton.get_bone_pose_rotation(actor._bone_index("EyeLeft"))
			eye_min = minf(eye_min, current_eye.get_angle())
			eye_max = maxf(eye_max, current_eye.get_angle())
			head_max = maxf(head_max, first_head.angle_to(actor.skeleton.get_bone_pose_rotation(actor._bone_index("Head"))))
		check(eye_max - eye_min > 0.025 and eye_max < 0.22, character_id + " sustained listening includes restrained independent eye darts")
		check(head_max > 0.045 and head_max < 0.14, character_id + " sustained listening includes a small tilt or acknowledgement")
		check(actor.position.is_zero_approx(), character_id + " micro-acting never translates the gameplay actor")
		actor.elapsed = 5.55 if character_id == "protagonist" else 2.85
		actor.advance_performance(0.25)
		actor.apply_preferences(true)
		check(actor.skeleton.get_bone_pose_rotation(actor._bone_index("EyeLeft")).get_angle() < 0.003, character_id + " live reduced-motion toggle immediately clears an in-flight eye dart")
		listener.queue_free()
		actor.set_attention_target(null)
		actor.set_conversation(false)
		actor.apply_preferences(true)
		for frame in range(180): actor.advance_performance(1.0 / 60.0)
		var feet: Dictionary = {}
		for id in ["FootLeft", "FootRight"]:
			feet[id] = actor.skeleton.get_bone_global_pose(actor._bone_index(id)).origin
		actor.set_locomotion(1.3165)
		for frame in range(8): actor.advance_performance(1.0 / 60.0)
		var start_blend = actor.locomotion_blend
		check(start_blend > 0.80, character_id + " stride becomes authoritative promptly on movement start")
		for frame in range(120): actor.advance_performance(1.0 / 60.0)
		actor.set_locomotion(0.0)
		for frame in range(12): actor.advance_performance(1.0 / 60.0)
		var stop_blend = actor.locomotion_blend
		check(stop_blend < 0.04, character_id + " stride releases within 200ms of stopping")
		var max_stop_drift := 0.0
		for id in feet:
			max_stop_drift = maxf(max_stop_drift, feet[id].distance_to(actor.skeleton.get_bone_global_pose(actor._bone_index(id)).origin))
		check(max_stop_drift < 0.025, character_id + " stop brings both actual feet back near their planted rest")
		for frame in range(60): actor.advance_performance(1.0 / 60.0)
		check(actor.skeleton.get_bone_pose_scale(actor._bone_index("EyeLeft")).is_equal_approx(Vector3.ONE), character_id + " reduced motion holds eyes fully open")
		var still_head = actor.skeleton.get_bone_pose_rotation(actor._bone_index("Head"))
		for frame in range(240): actor.advance_performance(1.0 / 60.0)
		check(still_head.angle_to(actor.skeleton.get_bone_pose_rotation(actor._bone_index("Head"))) < 0.0001, character_id + " reduced motion suppresses tilt, darts and acknowledgement")
		print("MOTION_MEASUREMENTS ", JSON.stringify({"character":character_id, "blink_interval_min_seconds":shortest, "blink_interval_max_seconds":longest, "blink_closing_scale_at_30ms":closing, "blink_opening_scale_at_110ms":opening, "eye_acquisition_radians":acquisition_eye, "head_acquisition_radians":acquisition_head, "listening_eye_range_radians":eye_max - eye_min, "listening_head_change_radians":head_max, "stride_blend_at_133ms":start_blend, "stride_blend_200ms_after_stop":stop_blend, "max_foot_rest_distance_after_stop_metres":max_stop_drift}))
		actor.queue_free()
		await process_frame
	print("Character motion polish checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
