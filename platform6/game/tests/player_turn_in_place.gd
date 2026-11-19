extends SceneTree
# Live imported-rig regression for a player turning on planted feet.
# A wall and an orbiting camera must not generate phantom stride or turn.
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func run():
	var player = load("res://player/player.gd").new()
	root.add_child(player)
	await process_frame
	player.set_physics_process(false)
	player.visual.set_process(false)
	player.set_preferences({"sensitivity":1.0,"reduced_motion":false,"master":0.8,"effects":0.6})
	var actor = player.visual
	var origin = player.global_position
	var camera_yaw = player.pivot.rotation.y
	var heard: Array[int] = []
	player.footstep_contact.connect(func(side: int): heard.append(side))
	check(is_zero_approx(player.grounded_turn_amount(1.0,1.0,1.0/60.0,true)),"held direction without actual yaw does not lean")
	check(player.grounded_turn_amount(0.0,0.15,1.0/60.0,true)>0.9,"actual grounded right turn has a readable impulse")
	check(player.grounded_turn_amount(0.0,-0.15,1.0/60.0,true)<-0.9,"actual grounded left turn reverses the torso cue")
	check(player.grounded_turn_amount(PI-0.02,-PI+0.02,1.0/60.0,true)>0.0,"crossing heading wrap stays the short positive turn")
	check(player.grounded_turn_amount(-PI+0.02,PI-0.02,1.0/60.0,true)<0.0,"reverse heading wrap stays the short negative turn")
	check(is_zero_approx(player.grounded_turn_amount(0.0,0.2,1.0/60.0,false)),"airborne turning has no planted-foot pose")
	check(is_zero_approx(player.grounded_turn_amount(0.0,0.2,0.0,true)),"zero frame duration cannot create a turn impulse")
	actor.set_locomotion(0.0,0.9)
	for i in range(12): actor.advance_performance(1.0/60.0)
	check(actor.turn_amount>0.65 and actor.locomotion_blend<0.01,"planted player reaches additive right-turn pose without walking")
	check(float(actor.animation_tree.get("parameters/Turn/add_amount"))>0.6,"real imported AnimationTree receives the planted-turn blend")
	var chest_index = actor._bone_index("Chest")
	check(chest_index>=0 and actor.skeleton != null,"planted turn uses the real articulated chest")
	var right_chest = actor.skeleton.get_bone_pose_rotation(chest_index)
	actor.set_locomotion(0.0,-0.9)
	for i in range(18): actor.advance_performance(1.0/60.0)
	var left_chest = actor.skeleton.get_bone_pose_rotation(chest_index)
	check(actor.turn_amount < -0.65 and right_chest.angle_to(left_chest)>0.03,"left and right turns deform imported torso in opposite directions")
	check(player.global_position==origin and is_equal_approx(player.pivot.rotation.y,camera_yaw) and heard.is_empty(),"turning changes no gameplay position, camera orbit or footstep sounds")
	actor.set_locomotion(0.0,0.0)
	for i in range(32): actor.advance_performance(1.0/60.0)
	check(absf(actor.turn_amount)<0.015 and actor.locomotion_blend<0.01,"planted turn settles without lingering lean")
	actor.set_locomotion(0.0,0.9)
	for i in range(8): actor.advance_performance(1.0/60.0)
	actor.apply_preferences(true)
	check(is_zero_approx(float(actor.animation_tree.get("parameters/Turn/add_amount"))),"live reduced-motion toggle removes decorative torso turn immediately")
	actor.set_locomotion(0.0,0.9)
	actor.advance_performance(0.25)
	check(is_zero_approx(float(actor.animation_tree.get("parameters/Turn/add_amount"))),"reduced motion retains heading control but never replays torso sway")
	actor.apply_preferences(false)
	actor.set_locomotion(0.0,0.9)
	for i in range(12): actor.advance_performance(1.0/60.0)
	check(float(actor.animation_tree.get("parameters/Turn/add_amount"))>0.6,"normal mode restores grounded turn acting")
	player.set_controls_enabled(false)
	for i in range(30): actor.advance_performance(1.0/60.0)
	check(absf(actor.turn_amount)<0.015 and heard.is_empty(),"disabled exploration settles without phantom turns or contacts")
	player.queue_free()
	await process_frame
	print("Planted turn Godot checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
