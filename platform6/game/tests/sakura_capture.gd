extends SceneTree
# Rendered motion capture for the Sakura animation pass (not part of run_tests.sh).
# Usage: xvfb-run godot --path . --fixed-fps 30 --script tests/sakura_capture.gd -- <out_dir> [frames]
var out := "/tmp/sakura"
var frames := 300
func _initialize(): call_deferred("run")
func run():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	if args.size() > 1: frames = int(args[1])
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1280, 720)
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://sakura_capture.json"
	root.add_child(game)
	for i in 5: await process_frame
	game.dispatch("leave_apartment")
	game.hud.close_all()
	game.resume_controls()
	game.player.set_touch_mode(true)
	game.player.position = Vector3(-2.0, 0.1, 3.0)
	game.player.pivot.rotation.y = -0.9
	if game.opening_story.cat: game.opening_story.cat.position = Vector3(-0.5, 0, 3.6)
	var cam = Camera3D.new()
	cam.fov = 50
	game.add_child(cam)
	cam.current = true
	var focus = game.player.global_position
	for i in 30: await process_frame
	for f in frames:
		var t = f / 30.0
		# Walk, pause (idle), curve, stop: exercises accel, turn, bob, breathing, follow.
		if t < 3.0: game.player.touch_move = Vector2(0.0, -1.0)
		elif t < 4.6: game.player.touch_move = Vector2.ZERO
		elif t < 7.4: game.player.touch_move = Vector2(sin(t * 0.9), -cos(t * 0.9) * 0.6).limit_length()
		else: game.player.touch_move = Vector2.ZERO
		# Side-on presentation camera, eased so the characters' own motion reads.
		var target = game.player.global_position
		if game.opening_story.cat: target = target.lerp(game.opening_story.cat.global_position, 0.3)
		focus = focus.lerp(target, 0.06)
		cam.global_position = focus + Vector3(4.6, 2.1, 3.0)
		cam.look_at(focus + Vector3(0, 0.6, 0), Vector3.UP)
		cam.make_current()
		if f == 0: print("capture camera: ", root.get_camera_3d(), " cat: ", game.opening_story.cat)
		await process_frame
		root.get_texture().get_image().save_png("%s/f%04d.png" % [out, f])
	game.queue_free()
	await process_frame
	quit(0)
