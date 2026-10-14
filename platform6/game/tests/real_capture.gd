extends SceneTree
# Rendered capture for the real-model pass (not part of run_tests.sh).
# xvfb-run godot --path . --fixed-fps 30 --script tests/real_capture.gd -- <out_dir> <mode> [frames]
# mode: shots | video
var out := "/workspace/shots/real"
var mode := "shots"
var frames := 300
var game
func _initialize(): call_deferred("run")
func _snap(name_: String):
	for i in 3: await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name_])
	print("saved ", name_)
func _place_cam(cam: Camera3D, from: Vector3, at: Vector3, fov := 45.0):
	cam.fov = fov
	cam.global_position = from
	cam.look_at(at, Vector3.UP)
	cam.make_current()
func run():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	if args.size() > 1: mode = args[1]
	if args.size() > 2: frames = int(args[2])
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1280, 720)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://real_capture.json"))
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://real_capture.json"
	root.add_child(game)
	for i in 5: await process_frame
	game.dispatch("leave_apartment")
	game.hud.close_all()
	game.resume_controls()
	game.player.set_touch_mode(true)
	game.player.position = Vector3(-2.0, 0.1, 3.0)
	game.player.pivot.rotation.y = -0.9
	var cat = game.opening_story.cat
	if cat: cat.position = Vector3(-0.5, 0, 3.6)
	var ill = game.world_container.get_child(0).get_node_or_null("IllustratedWorld")
	print("profile=", ill.profile if ill else "none", " rain=", game.world_container.get_child(0).find_children("Rain*","",true,false))
	if game.hud is CanvasItem or game.hud is CanvasLayer: game.hud.visible = false
	var cam = Camera3D.new()
	game.add_child(cam)
	for i in 40: await process_frame
	if mode == "shots":
		var p = game.player.global_position
		game.player.visual.rotation.y = 0.5
		for i in 20: await process_frame
		_place_cam(cam, p + Vector3(1.3, 1.45, 2.5), p + Vector3(0, 0.75, 0), 40)
		await _snap("01-player-closeup")
		if cat:
			cat.global_position = p + Vector3(1.5, 0, 0.8)
			for i in 90: await process_frame
			var c = cat.global_position
			var dir = -cat.global_basis.z
			dir.y = 0
			dir = dir.normalized()
			_place_cam(cam, c + dir * 1.3 + dir.cross(Vector3.UP) * 0.5 + Vector3(0, 0.55, 0), c + Vector3(0, 0.2, 0), 40)
			await _snap("02-cat")
		_place_cam(cam, Vector3(-5.2, 3.0, 11.0), Vector3(0.8, 0.6, -2.0), 58)
		await _snap("03-wide-platform")
		var w = game.world_container.get_child(0)
		var flock = w.find_child("SakuraBirdFlock", true, false)
		if flock:
			var b = flock.global_position
			_place_cam(cam, b + Vector3(-1.2, 0.6, 1.2), b + Vector3(0, 0.1, 0), 40)
			await _snap("extra-birds")
		for m in w.find_children("Mira", "", true, false):
			var q = m.global_position
			_place_cam(cam, q + Vector3(0.8, 1.3, 2.4), q + Vector3(0, 0.8, 0), 40)
			await _snap("extra-mira")
			break
	else:
		game.player.position = Vector3(-3.0, 0.1, 7.0)
		game.player.pivot.rotation.y = 0.0
		if cat: cat.position = Vector3(-1.8, 0, 8.6)
		for i in 20: await process_frame
		var focus = game.player.global_position
		for f in frames:
			var t = f / 30.0
			if t < 4.0: game.player.touch_move = Vector2(0.0, -0.42)
			elif t < 5.4: game.player.touch_move = Vector2.ZERO
			elif t < 8.4: game.player.touch_move = Vector2(0.25, 0.75)
			else: game.player.touch_move = Vector2.ZERO
			var target = game.player.global_position
			if cat: target = target.lerp(cat.global_position, 0.35)
			focus = focus.lerp(target, 0.06)
			_place_cam(cam, focus + Vector3(4.2, 2.4, 2.2), focus + Vector3(0, 0.6, 0), 50)
			await process_frame
			root.get_texture().get_image().save_png("%s/f%04d.png" % [out, f])
	game.queue_free()
	await process_frame
	quit(0)
