extends "res://tests/completion_rendered.gd"
func frames(count:int):
 for i in count: await process_frame
func run():
 if DisplayServer.get_name()=="headless":quit(2);return
 root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
 game=load("res://main.tscn").instantiate()
 game.save_path="user://completion-clip-"+str(Time.get_ticks_usec())+".json"
 root.add_child(game);await frames(8)
 await chapter("conductor")
 var actor=game.world_container.get_child(0).get_node("SupportingPerformer")
 actor.set_conversation(true,game.player)
 view(Vector3(3.8,2.05,0),Vector3(2,1.25,-4),37);await frames(72)
 await chapter("passenger")
 var mira=game.world_container.get_child(0).get_node("Mira")
 mira.set_conversation(true,game.player)
 view(Vector3(0,2.25,2.9),Vector3(.5,1.1,-3),50);await frames(72)
 await chapter("overlook")
 view(Vector3(8,4,9),Vector3(0,1,-2),58);await frames(72)
 var helper=load("res://tests/kitchen_rendered_qa.gd").new()
 game.model.restore(helper.seed_paper());helper.free()
 game.route();game.dispatch("begin_kitchen");quiet();await frames(8)
 actor=game.world_container.get_child(0).get_node("Ada/SupportingPerformer")
 actor.set_conversation(true,game.player)
 view(Vector3(-.7,2.0,2),Vector3(-3.2,1.15,-.51),37);await frames(72)
 print("COMPLETION_CLIP_DONE 4 actual game scenes, original live rig/ambient animation")
 game.audio.shutdown();game.queue_free();await process_frame;await process_frame;game=null;quit()
