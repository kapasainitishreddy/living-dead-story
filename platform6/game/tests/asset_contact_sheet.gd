extends SceneTree
# Loads every third-party model under assets/third_party, reports load status and
# animation clips, and (when OUT is set and not headless) renders a tile per model.
var out_dir := OS.get_environment("OUT")
var files: Array = []
func _scan(p: String) -> void:
	var d := DirAccess.open(p)
	if d == null: return
	for f in d.get_files():
		if f.get_extension() in ["glb", "gltf", "fbx"]: files.append(p + "/" + f)
	for s in d.get_directories(): _scan(p + "/" + s)
func _aabb(n: Node, xf: Transform3D, acc: Array) -> void:
	if n is VisualInstance3D:
		var a: AABB = (xf * (n as Node3D).transform) * (n as VisualInstance3D).get_aabb()
		acc[0] = a if acc[0] == null else acc[0].merge(a)
	var t: Transform3D = xf * (n.transform if n is Node3D else Transform3D())
	for c in n.get_children(): _aabb(c, t, acc)
func _initialize() -> void:
	_run()
func _run() -> void:
	_scan("res://assets/third_party")
	files.sort()
	var vp := SubViewport.new(); vp.size = Vector2i(256, 256); vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.own_world_3d = true; root.add_child(vp)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.93, 0.9, 0.97); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.8,0.8,0.85); e.ambient_light_energy = 0.6
	env.environment = e; vp.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 35, 0); vp.add_child(sun)
	var cam := Camera3D.new(); vp.add_child(cam)
	var ok := 0; var bad := 0
	for f in files:
		var res = load(f)
		if res == null or not (res is PackedScene):
			print("FAIL ", f); bad += 1; continue
		var inst: Node = res.instantiate(); vp.add_child(inst)
		var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var clips := PackedStringArray()
		if ap:
			clips = ap.get_animation_list()
			var pick := ""
			for want in ["Walk", "walk", "Idle", "idle", "Swim", "Fast"]:
				for c in clips:
					if pick == "" and want in c: pick = c
			if pick == "" and clips.size() > 0: pick = clips[0]
			if pick != "": ap.play(pick); ap.seek(0.4, true)
		print("OK ", f, " clips=", clips.size(), " ", ",".join(clips.slice(0, 12)))
		ok += 1
		if out_dir != "" and DisplayServer.get_name() != "headless":
			var acc := [null]; _aabb(inst, Transform3D(), acc)
			var a: AABB = acc[0] if acc[0] != null else AABB(Vector3(-1,0,-1), Vector3(2,2,2))
			var c: Vector3 = a.get_center(); var r: float = max(a.size.length() * 0.5, 0.05)
			cam.position = c + Vector3(0.9, 0.55, 1.25).normalized() * r * 2.4; cam.look_at(c); cam.far = r * 20.0; cam.near = r * 0.01
			await process_frame; await process_frame; await process_frame
			var img := vp.get_texture().get_image()
			img.save_png(out_dir + "/" + f.trim_prefix("res://assets/third_party/").replace("/", "__").get_basename() + ".png")
		inst.queue_free(); await process_frame
	print("SUMMARY ok=", ok, " fail=", bad)
	quit()
