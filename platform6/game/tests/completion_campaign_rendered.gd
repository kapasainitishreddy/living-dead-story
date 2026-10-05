extends "res://tests/full_campaign.gd"
var directory="res://../evidence/completion/campaign"
var seen:Dictionary={}
func capture(label:String):
 for i in 3:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(directory+"/"+label+".png")
func step(action:String,value:Variant=null):
 await super.step(action,value)
 var chapter=game.model.snapshot().campaign_chapter
 if not seen.has(chapter):
  seen[chapter]=true
  await capture(chapter)
func run():
 if DisplayServer.get_name()=="headless":quit(2);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
 root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
 game=Probe.new()
 game.save_path="user://completion-native-route-"+str(Time.get_ticks_usec())+".json"
 root.add_child(game);await process_frame
 await verify_full_dispatch_route()
 await verify_controller_exploration()
 var finished=game.model.snapshot()
 check(checkpoints.complete.campaign_complete,"native rendered route completed all seven chapters")
 # Controller exploration restores a settled campaign checkpoint; re-open completion
 # before the separate bounded Journey continuation.
 game.model.restore(checkpoints.complete);game.route();game.hud.close_all()
 game.journey.path="user://completion-native-journey-"+str(Time.get_ticks_usec())+".json"
 game.dispatch("journey_enter")
 for d in game.journey.model.destinations():
  game.dispatch("journey_board",d.journey_id)
  await capture("journey-"+d.journey_id)
  check(game.journey.model.snapshot().journey_id==d.journey_id,"native board "+d.journey_id)
  game.dispatch("journey_activity");game.show_pause();game.hud.resume_pause()
  check(game.hud.modal_visible(),"native activity resumes "+d.journey_id)
  game.dispatch("journey_advance");game.dispatch("journey_advance")
  game.dispatch("journey_choose",d.choice_nodes[0].choice_id)
  game.dispatch("journey_return_train")
 check(game.journey.save(),"native Journey continuation saves locally")
 print("COMPLETION_NATIVE_ROUTE ",checks," checks; failures: ",failures,"; scripted native renderer, synthetic controller, not human acceptance")
 game.audio.shutdown();game.journey.profile_player.stop();await create_timer(.2).timeout
 game.queue_free();await process_frame;await process_frame;game=null;quit(1 if failures else 0)
