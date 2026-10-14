extends SceneTree
# Rendered capture for the Sakura look pass (not part of run_tests.sh).
# xvfb-run godot --path . --fixed-fps 30 --script tests/sakura_look_capture.gd -- <out_dir> <shots|video|overlook>
# Framings mirror Sakura Crossing's first-person camera: FOV 46, eye 1.62 m.
var out := "/workspace/shots/sakura-look/ours"
var mode := "shots"
var game
func _initialize(): call_deferred("run")
func _snap(name_: String):
	for i in 4: await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name_])
	print("saved ", name_)
func _cam(cam: Camera3D, from: Vector3, at: Vector3, fov := 46.0):
	cam.fov = fov
	cam.near = 0.1
	cam.global_position = from
	cam.look_at(at, Vector3.UP)
	cam.make_current()
func run():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	if args.size() > 1: mode = args[1]
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1600, 900)
	var save = "user://sakura_look_capture_%d.json" % Time.get_ticks_usec()
	game = load("res://main.tscn").instantiate()
	game.save_path = save
	game.journey_save_path = save + ".journey"
	root.add_child(game)
	for i in 5: await process_frame
	game.dispatch("leave_apartment")
	if mode == "platform":
		game.dispatch("meet_stranger")
		for i in 30: await process_frame
	if mode == "overlook":
		for a in ["meet_stranger","read_board","board_train","meet_passenger","arrive_shore","reach_overlook"]:
			game.dispatch(a)
			for i in 30: await process_frame
	game.hud.close_all()
	game.resume_controls()
	game.player.set_touch_mode(true)
	if game.hud is CanvasItem or game.hud is CanvasLayer: game.hud.visible = false
	var w = game.world_container.get_child(0)
	var ill = w.get_node_or_null("IllustratedWorld")
	print("profile=", ill.profile if ill else "none")
	var cat = game.opening_story.cat if game.opening_story else null
	var cam = Camera3D.new()
	game.add_child(cam)
	if mode == "video":
		game.player.position = Vector3(-2.0, 0.1, 8.0)
		if cat: cat.position = Vector3(-0.8, 0, 9.4)
		for i in 30: await process_frame
		var focus = game.player.global_position
		for f in 300:
			var t = f / 30.0
			if t < 4.5: game.player.touch_move = Vector2(0.0, -0.45)
			elif t < 5.6: game.player.touch_move = Vector2.ZERO
			elif t < 8.6: game.player.touch_move = Vector2(0.3, 0.7)
			else: game.player.touch_move = Vector2.ZERO
			var target = game.player.global_position
			if cat: target = target.lerp(cat.global_position, 0.35)
			focus = focus.lerp(target, 0.06)
			_cam(cam, focus + Vector3(3.6, 1.9, 3.0), focus + Vector3(0, 0.7, 0), 46)
			await process_frame
			root.get_texture().get_image().save_png("%s/f%04d.png" % [out, f])
	else:
		game.player.position = Vector3(-3.2, 0.1, 2.0)
		game.player.pivot.rotation.y = 0.4
		if cat: cat.position = Vector3(-2.4, 0, 3.0)
		for i in 60: await process_frame
		var pre = mode + "-"
		_cam(cam, Vector3(-1.2, 1.62, 11.0), Vector3(-1.4, 1.45, -8.0))
		await _snap(pre + "A-street")
		_cam(cam, Vector3(-1.2, 1.62, 11.0), Vector3(1.5, 6.5, -8.0))
		await _snap(pre + "B-sky")
		if cat:
			cat.global_position = game.player.global_position + Vector3(2.6, 0, -1.6)
			cat.idle_state = "groom"; cat.pose(); cat._settle()
			cat.look_at(game.player.global_position, Vector3.UP)
			cat.set_paused(true)
			for i in 5: await process_frame
			var c = cat.global_position
			var away = c - game.player.global_position; away.y = 0; away = away.normalized()
			var front = -cat.global_basis.z; front.y = 0; front = front.normalized()
			_cam(cam, c + front * 1.9 + front.cross(Vector3.UP) * 0.8 + Vector3(0, 1.2, 0), c + Vector3(0, 0.4, 0))
			await _snap(pre + "C-cat")
		var p = game.player.global_position
		_cam(cam, p + Vector3(2.2, 1.62, 3.4), p + Vector3(0, 0.9, 0))
		await _snap(pre + "D-character")
	game.queue_free()
	await process_frame
	quit(0)
