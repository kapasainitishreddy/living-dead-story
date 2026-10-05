extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok: failures+=1; printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func run():
 var helper=load("res://tests/return_runtime.gd").new()
 var game=load("res://main.tscn").instantiate()
 game.save_path="user://supporting-pause-"+str(Time.get_ticks_usec())+".json"
 root.add_child(game); await process_frame
 game.model.restore(helper.orchard_seed("lend")); helper.free()
 game.route(); game.dispatch("begin_return"); game.hud.close_all(); game.resume_controls()
 for i in 4: await process_frame
 var world=game.world_container.get_child(0)
 var jo=world.get_node("Jo/SupportingPerformer")
 game.show_pause()
 var elapsed=jo.elapsed
 var pose=jo.skeleton.get_bone_pose_rotation(jo._bone_index("ThighLeft"))
 await create_timer(.15).timeout
 check(jo.elapsed==elapsed,"Pause freezes supporting actor time in actual game")
 var prefs=game.model.snapshot().settings; prefs.reduced_motion=true; game.change_settings(prefs)
 check(pose.angle_to(jo.skeleton.get_bone_pose_rotation(jo._bone_index("ThighLeft")))<.00001,"Paused preferences retain every sampled seated bone")
 game.hud.resume_pause(); await process_frame; await process_frame
 check(jo.elapsed>elapsed,"Resume restarts supporting cast acting")
 var knee=jo.skeleton.get_bone_global_pose(jo._bone_index("ShinLeft")).origin
 var hip=jo.skeleton.get_bone_global_pose(jo._bone_index("ThighLeft")).origin
 check(knee.z>hip.z+.25,"Resumed preferences keep actual seated limbs")
 check(world.get_node("Jo/CrookedPaperStar").is_visible_in_tree(),"Jo keeps meaningful crooked star after deferred setup")
 game.audio.shutdown(); game.queue_free(); await process_frame; await process_frame
 print("SUPPORTING_PAUSE ",checks," checks; failures: ",failures); quit(1 if failures else 0)
