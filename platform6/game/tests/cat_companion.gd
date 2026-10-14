extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func run():
	check(ResourceLoader.exists("res://world/cat_companion.gd"), "cat companion exists")
	if failures:
		quit(1)
		return
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://cat_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	check(game.hud.authored is Dictionary and game.hud.authored.dialogues.has("pet_cat"), "chapter data loads with pet dialogue")
	game.dispatch("leave_apartment")
	game.hud.close_all()
	game.resume_controls()
	var cat = game.opening_story.cat
	check(cat != null and cat.get_child_count() > 0, "roof spawns primitive cat")
	cat.set_process(false)
	game.player.position = Vector3(0, 0.1, 5)
	cat.position = Vector3(0, 0, 0)
	check(not cat.pet(), "petting is unavailable outside reach")
	cat._process(1.0)
	check(cat.position.z > 0 and cat.position.z < 3, "cat follows while leaving distance")
	cat.position = Vector3(0, 0, 3)
	for expected in ["sleep", "stretch", "groom", "sleep"]:
		check(cat.idle_state == expected, "idle cycle reaches " + expected)
		cat._process(5.0)
	game.player.position = cat.position + Vector3(0.5, 0.1, 0)
	cat._process(0.1)
	check(cat.idle_state == "react", "cat reacts to nearby player")
	var before = game.model.snapshot()
	game.player._physics_process(0.0)
	check(game.player.nearest == cat, "existing interaction selects nearby cat")
	var interaction = InputEventAction.new()
	interaction.action = "interact"
	interaction.pressed = true
	game.player._unhandled_input(interaction)
	check(cat.petted and game.hud.modal_visible(), "pet leans and opens warm dialogue")
	check(game.model.snapshot() == before, "petting changes no saved state or rewards")
	cat.apply_preferences(true)
	var pose = cat.visual.transform
	var idle_elapsed = cat.elapsed
	cat._process(10.0)
	check(cat.visual.transform == pose and cat.elapsed == idle_elapsed, "reduced motion keeps cat static without tweens")
	cat.set_paused(true)
	var resting_position = cat.position
	game.player.position = Vector3(5, 0.1, 5)
	cat._process(10.0)
	check(cat.position == resting_position, "pause freezes companion following")
	cat.set_paused(false)
	cat._process(1.0)
	check(not cat.petted and cat.idle_state in cat.IDLES, "leaving returns to idle without a pet timer")
	game.hud.close_all()
	game.resume_controls()
	game.dispatch("meet_stranger")
	check(game.opening_story.cat != null, "platform spawns cat")
	var save_path = game.save_path
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("Cat companion: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
