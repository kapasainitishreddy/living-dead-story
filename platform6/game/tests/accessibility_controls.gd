extends SceneTree
var checks:=0
var failures:=0
var game
func check(ok: bool,label:String):
 checks+=1
 if not ok: failures+=1; printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func run():
 root.size=Vector2i(1280,720); root.content_scale_size=Vector2i(1280,720)
 game=load("res://main.tscn").instantiate()
 game.save_path="user://accessibility-controls-"+str(Time.get_ticks_usec())+".json"
 root.add_child(game); await process_frame
 for scale in [1.0,2.0]:
  var prefs=game.model.snapshot().settings
  prefs.text_scale=scale; game.change_settings(prefs); game.hud.show_settings(prefs)
  for i in 3: await process_frame
  for item in game.hud.content.find_children("*","Control",true,false):
   if item is Label or item is CheckButton or item is OptionButton:
    check(item.get_theme_font_size("font_size")>=int(19*scale),"settings "+item.get_class()+" obeys "+str(scale)+"x text")
  for slider in game.hud.content.find_children("*","HSlider",true,false):
   check(slider.size.x>=220,"scaled settings retain usable slider width")
  check(game.hud.modal.get_global_rect().end.x<=1281,"settings avoid horizontal overflow at "+str(scale))
 var helper=load("res://tests/journey_runtime.gd").new()
 var campaign=helper.completed_campaign("train"); helper.free()
 campaign.settings.text_scale=2.0
 check(game.model.restore(campaign),"restore complete campaign for private Journey writing")
 game.hud.close_all(); game.route()
 game.journey.path="user://accessible-journey-"+str(Time.get_ticks_usec())+".json"
 game.dispatch("journey_enter"); game.dispatch("journey_writing")
 for i in 3: await process_frame
 var words=game.hud.content.find_child("PrivateWords",true,false)
 var when=game.hud.content.find_child("EchoLocalTime",true,false)
 check(words.get_theme_font_size("font_size")==38,"private words obey 2x preference")
 check(when.get_theme_font_size("font_size")==38,"Future Echo date is equally readable at 2x")
 var prefs=game.model.snapshot().settings; prefs.text_scale=1.0; game.change_settings(prefs)
 check(when.get_theme_font_size("font_size")==19,"date updates immediately on live text-scale change")
 game.audio.shutdown(); game.queue_free(); await process_frame; await process_frame
 print("ACCESSIBILITY_CONTROLS ",checks," checks; failures: ",failures)
 quit(1 if failures else 0)
