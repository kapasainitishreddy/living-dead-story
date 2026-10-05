extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _initialize(): call_deferred("run")
func state(checkpoint := "arrival", camera_choice := "lend") -> Dictionary:
	return {"campaign_chapter":"the_return","return_checkpoint":checkpoint,"return_state":{"farewell":"unselected","completed":checkpoint == "complete"},"camera_choice":camera_choice,"settings":{"reduced_motion":false}}
func action(world: Node, id: String) -> Node:
	for target in world.get_node("Interactions").get_children():
		if target.get_meta("action_id","") == id: return target
	return null
func run():
	check(ResourceLoader.exists("res://world/return_world.gd"),"return has its own original station world")
	if failures: quit(1); return
	var world = load("res://world/return_world.gd").new().build(state())
	root.add_child(world)
	await process_frame
	world.set_process(false)
	for id in ["Spawn","AmbientMotion","Interactions","ReturnCamera","StationArt","PlatformFloor","StationBench","Indicator","Indicator/Destination","Train","Train/Doors/Left","Train/Doors/Right","Train/BoardingStep","Mira","ToolRoll","CameraLeftBehind","Conductor","Jo","JoBench","Jo/YellowUmbrella","Jo/YellowUmbrella/Canopy","Jo/CrookedPaperStar","PlatformClock","RailBed","Roof"]:
		check(world.has_node(id),"tangible return station has " + id)
	check(world.get_node("Jo").get_meta("seated",false),"Jo is visibly seated as the optional encounter describes")
	check(world.get_node("PlatformFloor") is StaticBody3D,"platform floor has real support")
	check(world.get_node("Mira").get_meta("character_id","") == "mira","departure uses original production Mira rig")
	check(world.get_node("Mira").skeleton != null,"departure actor has live imported skeleton")
	check(world.get_node("ReturnCamera") is Marker3D and world.get_node("ReturnCamera").has_meta("look_at"),"main receives stable cinematic camera marker and focal target")
	var front = world.get_node("Train/NearFrontWall")
	var rear = world.get_node("Train/NearRearWall")
	check(front.position.z+front.get_child(0).mesh.get_aabb().size.z/2 <= -4.78,"train front wall leaves physical boarding doorway open")
	check(rear.position.z-rear.get_child(0).mesh.get_aabb().size.z/2 >= -3.22,"train rear wall leaves physical boarding doorway open")
	check(world.cinematic_camera_path() == NodePath("ReturnCamera"),"main camera API names actual camera marker")
	check(not world.get_node("Train").visible,"arrival leaves train outside the station")
	check(action(world,"return_arrival") != null,"arrival starts farewell when player chooses")
	check(action(world,"return_conductor") == null and action(world,"return_jo") == null,"post-departure contacts wait until departure")
	world.apply_snapshot(state("farewell"))
	check(action(world,"return_farewell") != null,"restored farewell remains freely reachable")
	world.apply_snapshot(state("departed"))
	check(not world.get_node("Mira").visible and not world.get_node("Train").visible,"saved departed restores absence without replay")
	check(world.cinematic_phase == "settled" and not world.departure_active,"saved departed has no replay wait")
	check(action(world,"return_finish") != null,"settled station offers authored continuation")
	check(action(world,"return_conductor") != null and action(world,"return_jo") != null,"station people remain after Mira leaves")
	world.apply_snapshot(state("complete"))
	check(action(world,"return_exit") != null,"completed chapter has tangible exit target")
	check(world.snapshot.return_state.farewell == "unselected","world does not invent saved story choices")
	world.free()
	print("Return world scene checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
