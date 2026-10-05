extends SceneTree
# Exercise gaze and conversations through the real authored supporting rig.
const Main = preload("res://main.gd")
const Player = preload("res://player/player.gd")
const Supporting = preload("res://characters/supporting_performer.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func run():
	var game = Main.new()
	game.world_container = Node3D.new()
	root.add_child(game.world_container)
	var world = Node3D.new()
	game.world_container.add_child(world)
	game.player = Player.new()
	world.add_child(game.player)
	game.player.set_physics_process(false)
	var owner = Node3D.new()
	owner.name = "Conductor"
	world.add_child(owner)
	var actor = Supporting.new()
	actor.name = "SupportingPerformer"
	actor.stage_owner = owner
	actor.configure("conductor")
	owner.add_child(actor)
	await process_frame
	check(actor.skeleton != null, "test uses a loaded production rig")
	game.configure_characters(world, game.model.snapshot().settings)
	check(actor.gaze_target == game.player, "supporting NPC notices the nearby protagonist")
	check(game.player.visual.gaze_target == null, "NPC preferences preserve protagonist attention ownership")
	game.begin_character_conversation("conductor", null, owner)
	check(game.conversation_actor == actor, "root fallback resolves actual supporting performer")
	check(actor.conversing and actor.gaze_target == game.player, "supporting body receives listener and conversation")
	check(game.player.visual.conversing and game.player.visual.gaze_target == actor, "protagonist attends to the actual body")
	actor.advance_performance(0.3)
	check(actor.conversation_blend > 0.1, "resolved supporting conversation drives real performance")
	game.end_character_conversation()
	check(not actor.conversing and not game.player.visual.conversing, "ending dialogue retires both performances")
	game.begin_character_conversation("conductor", null, actor)
	check(game.conversation_actor == actor and actor.conversing, "direct performer fallback stays compatible")
	game.end_character_conversation()
	var marker = Node3D.new()
	world.add_child(marker)
	game.begin_character_conversation("conductor", null, marker)
	check(game.conversation_actor == marker, "ordinary marker fallback remains compatible")
	game.end_character_conversation()
	game.world_container.free()
	game.free()
	print("SUPPORTING CONVERSATION ", checks, " checks ", failures, " failures")
	quit(1 if failures else 0)
