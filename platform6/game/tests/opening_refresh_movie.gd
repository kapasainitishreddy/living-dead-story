extends SceneTree
var game
var out=""
var checks=0
var failures=0
func _initialize():call_deferred("run")
func wait_frames(count):
 for i in count:await process_frame
func check(ok,label):
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+label)
func snap(id):
 await wait_frames(2)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+id+".png")
func clear():
 game.hud.close_all();game.resume_controls()
func act(action,value=null):
 game.dispatch(action,value);await wait_frames(2)
func run():
 if DisplayServer.get_name()=="headless":quit(2);return
 out=OS.get_environment("REFRESH_MEDIA_DIR")
 DirAccess.make_dir_recursive_absolute(out)
 root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
 game=load("res://main.tscn").instantiate();game.save_path="user://refresh-clip-"+str(Time.get_ticks_usec())+".json"
 root.add_child(game);await wait_frames(16)
 await snap("01-apartment");await wait_frames(48)
 await act("leave_apartment");clear();await snap("02-roof");await wait_frames(64)
 game.player.position=Vector3(0,.05,-1.5)
 game.on_interact(game.world_container.get_child(0).find_children("*","Marker3D",true,false).filter(func(n):return n.get_meta("action_id","")=="meet_stranger")[0])
 await wait_frames(16);await snap("03-umbrella-dialogue");await wait_frames(64)
 await act("dialogue","umbrella_question");await wait_frames(24)
 await act("meet_stranger");clear();game.player.position=Vector3(0,.05,-3.2)
 await snap("04-ticket");await wait_frames(48)
 await act("read_board");clear();await act("board_train");clear()
 game.player.position=Vector3(.4,.05,-1.0)
 await act("dialogue","train_window");await wait_frames(64);clear();await snap("05-window-story")
 await act("meet_passenger");clear();await act("arrive_shore");clear()
 await snap("06-shore");await wait_frames(64)
 for landmark in ["lighthouse","arch","constellation"]:
  for marker in game.world_container.get_child(0).find_children("*","Marker3D",true,false):
   if marker.get_meta("action_id","")=="inspect_landmark" and marker.get_meta("value","")==landmark:
    game.on_interact(marker);await wait_frames(2);clear();break
 game.hud.show_puzzle(game.model.snapshot())
 if is_instance_valid(game.get("opening_story")):game.opening_story.begin_preview(0)
 await snap("07-framing-before");await wait_frames(48)
 await act("preview_alignment",2)
 await snap("08-framing-whole-shore");await wait_frames(64)
 await act("align",2);clear();await act("choose_camera","lend");clear()
 await act("resolve_action","skipped");clear()
 await act("return_train");clear();game.player.position=Vector3(.4,.05,-1)
 await snap("09-breakfast-props");await wait_frames(64)
 await act("have_breakfast");clear();await act("finish")
 await snap("10-ending");await wait_frames(48)
 check(game.model.snapshot().chapter_complete,"the scripted real opening route reaches its ending")
 print("REFRESH_GAMEPLAY_MOVIE ",checks," checks; failures ",failures,"; actual rendered gameplay/audio, scripted sequence")
 game.audio.shutdown();await wait_frames(4);game.queue_free();await wait_frames(3);quit(1 if failures else 0)
