extends SceneTree
# Removing shared apartment geometry, forgetting a physical choice, or moving a
# target into furniture must fail this test even when model transitions succeed.
var checks := 0
var failures := 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _initialize(): call_deferred("run")
func state(checkpoint := "arrival", ticket := "unselected", ritual := "unselected", ending := "unselected") -> Dictionary:
	return {"campaign_chapter":"still_here","home_checkpoint":checkpoint,"home":{"ticket":ticket,"ritual":ritual,"ending":ending,"completed":checkpoint == "complete"},"settings":{"reduced_motion":false}}
func action(world: Node, id: String) -> Node:
	for target in world.get_node("Interactions").get_children():
		if target.get_meta("action_id","") == id: return target
	return null
func signature(node: Node) -> Array:
	# Anonymous engine-assigned IDs differ across otherwise identical builds.
	var stable_name = node.get_class() if str(node.name).begins_with("@") else str(node.name)
	var result: Array = [node.get_class(),stable_name]
	if node is Node3D: result.append(node.transform)
	if node is MeshInstance3D:
		result.append(node.mesh.get_class())
		result.append(node.mesh.get_aabb())
		result.append(node.material_override.albedo_color)
	if node is CollisionShape3D:
		result.append(node.shape.get_class())
		if node.shape is BoxShape3D: result.append(node.shape.size)
	if node is Label3D: result.append(node.text)
	for child in node.get_children(): result.append(signature(child))
	return result
func run():
	check(ResourceLoader.exists("res://world/home_world.gd"),"home ending reuses the actual opening apartment")
	if failures:
		print("Home world scene checks: %d; failures: %d" % [checks,failures])
		quit(1)
		return
	var original = load("res://world/world_factory.gd").new().build("apartment")
	var world = load("res://world/home_world.gd").new().build(state())
	root.add_child(world)
	await process_frame
	world.set_process(false)
	for id in ["Spawn","Floor","Ceiling","Window wall","Rain window","Rug","Bed","Pillow","Table","Door","ApartmentProps","Rain","AmbientMotion","Interactions","HomeView","TicketView","WindowView","BedView","HomeTicket","TeaSteam"]:
		check(world.has_node(id),"home retains tangible original room and physical " + id)
	# Compare the actual Chapter One build, including collision and mesh assets.
	for child in original.get_children():
		if child is Node3D and (child is StaticBody3D or child.name in ["Rain window","Rug","Pillow","ApartmentProps"]):
			check(world.has_node(NodePath(str(child.name))),"original opening room node remains " + str(child.name))
			if world.has_node(NodePath(str(child.name))):
				check(signature(child) == signature(world.get_node(NodePath(str(child.name)))),"home uses exact opening transforms/assets/collision for " + str(child.name))
	check(world.get_node("Bed").position == Vector3(-4,0.6,-2),"opening bed stays at its original position")
	check(world.get_node("Table").position == Vector3(4,0.7,-3),"opening table stays at its original position")
	check(world.get_node("Rain window").position == Vector3(-5,2.5,-10.85),"opening rain window stays at its original position")
	for id in ["Mug","Chair","Crossword","Kettle","Drawer","Coat","Shoes"]:
		check(original.has_node("ApartmentProps/" + id) and world.has_node("ApartmentProps/" + id),"same ordinary " + id + " exists from Chapter One onward")
	check(action(world,"leave_apartment") == null,"home does not expose Chapter One's roof exit")
	for label in world.find_children("*","Label3D",true,false):
		check(not label.text.contains("3:17\nThe rain has softened"),"home replaces the opening time notice")
	check(not world.get_node("HomeTicket").visible,"arrival does not invent a selected ticket location")
	check(action(world,"home_state") != null and action(world,"home_ticket") != null,"arrival exposes room continuity and ticket choice")
	check(action(world,"home_ritual") == null and action(world,"home_end") == null,"arrival does not skip ticket staging")
	for ticket in ["kettle","drawer","pocket"]:
		world.apply_state(state("arrival",ticket))
		check(world.get_node("HomeTicket").visible,"saved " + ticket + " ticket exists physically")
		check(world.get_node("HomeTicket").get_meta("location","") == ticket,"saved physical ticket remembers " + ticket)
		if ticket == "pocket":
			check(world.get_node("HomeTicket").scale.x <= 0.6,"pocket ticket is folded to fit the ordinary coat pocket")
			check(world.get_node("HomeTicket").position.z < -7.59,"pocket cloth occludes the tucked part of the ticket")
		check(action(world,"home_ritual") != null,"stored ticket exposes optional ritual " + ticket)
		check(action(world,"home_end") == null,"ending waits for equally valid ritual choice")
		var ticket_position = world.get_node("HomeTicket").position
		var reopened = load("res://world/home_world.gd").new().build(state("arrival",ticket))
		check(reopened.get_node("HomeTicket").position == ticket_position,"reopen restores exact ticket placement " + ticket)
		reopened.free()
		for ritual in ["tea","window","neither"]:
			world.apply_state(state("settled",ticket,ritual))
			check(world.get_node("ApartmentProps/Mug/Tea").visible == (ritual == "tea"),"mug reflects chosen " + ritual + " without reward transform")
			check(world.get_node("WindowView").get_meta("ritual","") == ritual,"window ritual continuity is remembered")
			check(action(world,"home_end") != null,"every valid settled ritual exposes ending " + ritual)
			for ending in ["train","sleep"]:
				var saved = state("complete",ticket,ritual,ending)
				world.apply_state(saved)
				check(world.snapshot == saved,"world never mutates canonical choices " + ticket + ritual + ending)
				check(world.get_meta("ending","") == ending and not world.ending_active,"saved ending restores settled physical room " + ending)
				check(action(world,"home_state") != null and action(world,"home_end") != null,"finished apartment remains revisit-able")
				var rebuilt = load("res://world/home_world.gd").new().build(saved)
				check(signature(world.get_node("HomeTicket")) == signature(rebuilt.get_node("HomeTicket")),"canonical physical ticket survives full ending rebuild")
				check(signature(world.get_node("ApartmentProps")) == signature(rebuilt.get_node("ApartmentProps")),"canonical ordinary props survive full ending rebuild")
				rebuilt.free()
	world.apply_state(state("settled","kettle","tea"))
	check(world.has_node("WindowSitter"),"window ritual has a physically seated original protagonist")
	if world.has_node("WindowSitter"):
		world.apply_state(state("settled","kettle","window"))
		var sitter = world.get_node("WindowSitter")
		check(sitter.get_meta("character_id","") == "protagonist" and sitter.get_meta("seated",false),"window ritual uses recognizable original protagonist in a sitting posture")
		check(not sitter.visible,"exploration does not duplicate the active protagonist")
		world.set_close_view(true)
		check(sitter.visible,"fixed window ritual view shows actual seated posture")
		var hips = sitter.skeleton.global_transform * sitter.skeleton.get_bone_global_pose(sitter._bone_index("Hips")).origin
		var knee = sitter.skeleton.global_transform * sitter.skeleton.get_bone_global_pose(sitter._bone_index("ShinLeft")).origin
		check(hips.y > 0.4 and hips.y < 0.8 and absf(hips.y-knee.y) < 0.22,"seated hips rest on original chair with bent actual thighs")
		var chair_back = world.get_node("ApartmentProps/Chair/BackSlat").global_position
		check((chair_back-hips).dot(sitter.global_basis.z.normalized()) < -0.2,"ordinary chair back supports the seated torso from behind along the window-facing axis")
		var resting_thigh = sitter.skeleton.get_bone_pose_rotation(sitter._bone_index("ThighLeft"))
		for i in range(3): await process_frame
		check(not sitter.is_processing(),"world disables seated performer's manual animation advancement after tree entry")
		check(sitter.skeleton.get_bone_pose_rotation(sitter._bone_index("ThighLeft")).is_equal_approx(resting_thigh),"actual process frames preserve seated thighs")
		world.set_paused(true)
		for reduced in [true,false]:
			# Match main.configure_characters followed by world-owned preferences.
			sitter.apply_preferences(reduced)
			world.apply_preferences(reduced)
			world._process(20.0)
			await process_frame
			check(sitter.skeleton.get_bone_pose_rotation(sitter._bone_index("ThighLeft")).is_equal_approx(resting_thigh),"paused settings preserve seated pose with reduced motion " + str(reduced))
		world.set_paused(false)
		world.apply_state(state("complete","kettle","window","sleep"))
		check(not sitter.visible and world.get_node("HomeView").position == world.get_node("BedView").position,"sleep ending settles at original bed rather than leaving protagonist sitting")
		world.set_close_view(false)
		check(not sitter.visible,"leaving close view returns the single walking protagonist")
	world.apply_state(state("settled","kettle","tea"))
	var completions = [0]
	world.ending_finished.connect(func(): completions[0] += 1)
	for ending in ["train","sleep"]:
		world.begin_ending(ending)
		check(world.ending_active,"ordinary " + ending + " ending gets a quiet bounded physical hold")
		var stable = world.get_node("HomeView").transform
		world._process(0.5)
		check(world.get_node("HomeView").transform == stable,"ending composition stays fixed with no automatic camera motion")
		world.set_paused(true)
		var paused_state = world.cinematic_state()
		world._process(60.0)
		check(world.cinematic_state() == paused_state,"pause freezes the complete home presentation")
		world.set_paused(false)
		var before = completions[0]
		world.finish_ending()
		world.finish_ending()
		world._process(60.0)
		check(completions[0] == before+1 and not world.ending_active,"skip settles each ending exactly once")
	world.set_reduced_motion(true)
	check(not world.get_node("Rain").visible and not world.get_node("TeaSteam").visible,"reduced motion hides moving rain and steam")
	var before = completions[0]
	world.begin_ending("sleep")
	check(not world.ending_active and completions[0] == before+1,"reduced motion ends hold immediately with equal function")
	world.set_reduced_motion(false)
	world.begin_ending("train")
	world._process(world.ending_duration)
	check(not world.ending_active and completions[0] == before+2,"ordinary quiet ending completes once after its bounded hold")
	check(world.cinematic_camera_path() == NodePath("HomeView"),"runtime camera uses authored fixed home marker")
	original.free()
	world.free()
	print("Home world scene checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
