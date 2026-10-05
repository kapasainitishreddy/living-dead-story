extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _initialize(): call_deferred("run")
func run():
	var signatures: Dictionary = {}
	for choice in ["luck","joke","thanks","wave","little"]:
		var value = {"return_checkpoint":"departed","return_state":{"farewell":choice},"camera_choice":"lend","settings":{"reduced_motion":false}}
		var world = load("res://world/return_world.gd").new().build(value)
		root.add_child(world)
		await process_frame
		world.set_process(false)
		world.begin_departure(choice,"lend")
		check(world.cinematic_phase == "farewell_reply","chosen " + choice + " has a restrained live acknowledgement")
		check(not world.get_node("Train").visible,"chosen " + choice + " reply precedes train approach")
		world._process(0.65)
		var mira = world.get_node("Mira")
		var bones: Array[Quaternion] = []
		for id in ["Head","Chest","UpperArmRight","ForearmRight","Mouth"]:
			bones.append(mira.skeleton.get_bone_pose_rotation(mira._bone_index(id)))
		signatures[choice] = bones
		world._process(0.8)
		check(world.cinematic_phase == "approach" and world.get_node("Train").visible,"chosen " + choice + " always allows train to approach")
		world.finish_departure()
		check(world.snapshot.return_state.farewell == choice,"acting preserves durable " + choice)
		world.free()
	var choices = signatures.keys()
	for i in range(choices.size()):
		for j in range(i+1,choices.size()):
			var difference := 0.0
			for index in range(signatures[choices[i]].size()):
				difference += signatures[choices[i]][index].angle_to(signatures[choices[j]][index])
			check(difference > 0.02,"live acknowledgement differs for " + choices[i] + " and " + choices[j])
	print("Return farewell acting checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
