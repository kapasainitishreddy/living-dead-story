extends SceneTree
# Regression: replacing imported local rest rotations with identity raises both
# hands above the head when reduced motion chooses the generated RestPose clip.
# Assert actual articulated bone positions, not only blend parameters.
var checks := 0
var failures := 0

func check(ok: bool, label: String):
	checks += 1
	print("REST ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func _initialize(): call_deferred("run")

func check_hands(actor, label: String, compare_rest := false):
	var rig: Skeleton3D = actor.skeleton
	var head = rig.get_bone_global_pose(rig.find_bone("Head")).origin
	for bone_name in ["HandLeft", "HandRight"]:
		var index = rig.find_bone(bone_name)
		var pose = rig.get_bone_global_pose(index).origin
		var rest = rig.get_bone_global_rest(index).origin
		print("BONE ", actor.character_id, " ", label, " ", bone_name,
			" pose=", pose, " rest=", rest, " head_y=", head.y,
			" local_pose=", rig.get_bone_pose_rotation(index),
			" local_rest=", rig.get_bone_rest(index).basis.get_rotation_quaternion())
		check(pose.y < head.y - 0.35, actor.character_id + " " + label + " " + bone_name + " rests below head")
		if compare_rest:
			check(pose.distance_to(rest) < 0.005, actor.character_id + " " + label + " " + bone_name + " preserves imported rest position")

func run():
	var controller = load("res://characters/character_performer.gd")
	for character_id in ["protagonist", "mira"]:
		var actor = controller.new()
		actor.configure(character_id)
		root.add_child(actor)
		await process_frame
		actor.set_process(false)
		actor.advance_performance(0.1)
		check_hands(actor, "authored idle")
		actor.apply_preferences(true)
		actor.advance_performance(0.0)
		check_hands(actor, "reduced rest", true)
		var thigh = actor.skeleton.find_bone("ThighLeft")
		var first = actor.skeleton.get_bone_pose_rotation(thigh)
		var maximum_change := 0.0
		actor.set_locomotion(1.2)
		for i in range(120):
			actor.advance_performance(1.0 / 60.0)
			maximum_change = maxf(maximum_change, first.angle_to(actor.skeleton.get_bone_pose_rotation(thigh)))
		check(maximum_change > 0.1, character_id + " reduced motion retains actual articulated gait")
		actor.set_locomotion(0.0)
		for i in range(120): actor.advance_performance(1.0 / 60.0)
		check_hands(actor, "walk to reduced rest", true)
		actor.apply_preferences(false)
		actor.advance_performance(0.1)
		check_hands(actor, "rest to authored idle")
		actor.queue_free()
		await process_frame
	print("Character rest pose checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
