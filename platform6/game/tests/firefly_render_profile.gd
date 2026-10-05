extends SceneTree
var checks=0
var failures=0
var game
var directory=OS.get_environment('FIREFLY_QA_DIR') if not OS.get_environment('FIREFLY_QA_DIR').is_empty() else 'res://../evidence/firefly'
var frame_samples=[]
func check(ok,label):
 checks+=1
 if not ok: failures+=1; printerr('FAIL '+label)
func _initialize(): call_deferred('run')
func capture(name_):
 for i in 8: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(directory+'/'+name_+'.png')
func layout(label):
 var viewport=root.get_visible_rect()
 check(game.hud.modal.get_global_rect().end.y<=viewport.end.y+2,label+' modal bottom visible')
 check(game.hud.modal.get_global_rect().position.y>=-2,label+' modal top visible')
 for b in game.hud.footer.get_children():
  check(b.get_global_rect().end.y<=viewport.end.y+2,label+' comfortable footer '+b.text)
func run():
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
 game=load('res://main.tscn').instantiate()
 game.save_path='user://journey_rendered_campaign.json'
 root.add_child(game)
 await process_frame
 var helper=load('res://tests/journey_runtime.gd').new()
 game.model.restore(helper.completed_campaign('sleep'))
 helper.free()
 game.journey.path='user://journey_rendered_'+str(Time.get_ticks_usec())+'.json'
 game.journey.model=load('res://core/journey_model.gd').new()
 game.dispatch('journey_enter')
 game.hud.close_all(); game.resume_controls()
 await capture('train_first')
 for d in game.journey.model.destinations():
  if d.journey_id != "fireflies": continue
  game.dispatch('journey_board',d.journey_id)
  game.hud.close_all(); game.resume_controls()
  var world=game.world_container.get_child(0)
  world.apply_preferences(true)
  var art=world.get_node('Scenery/PaintedClearing')
  DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
  Engine.max_fps=0
  for label in ([] if OS.get_environment('FIREFLY_COMPARE_ONLY')=='1' else ['baseline_a','optimized_a','optimized_b','baseline_b']):
   var batched=label.begins_with('optimized')
   world.get_node('Scenery/FireflyOrbs/InstancedFireflies').visible=batched
   for item in world._decorative: item.node.visible=not batched
   for i in 30: await process_frame
   var times=[];var cpu=[]
   for i in 300:
    var before=Time.get_ticks_usec()
    await process_frame
    times.append((Time.get_ticks_usec()-before)/1000.0)
    cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
   times.sort();cpu.sort()
   print('PROFILE ',label,' ',JSON.stringify({'median_ms':times[150],'p95_ms':times[285],'cpu_ms':cpu[150],'draw_calls':Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),'primitives':Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}))
   await capture(label)
  # Exact pose comparisons across existing quality tiers and motion preferences.
  var settings=game.model.snapshot().settings
  settings.reduced_motion=true
  for quality in ['low','medium','high']:
   settings.graphics=quality;game.change_settings(settings)
   world.set_process(false)
   for reduced in [true,false]:
    world.apply_preferences(reduced)
    world.motion_elapsed=1.75
    world._process(0.0);art._sync_fireflies()
    for batched in [false,true]:
     world.get_node('Scenery/FireflyOrbs/InstancedFireflies').visible=batched
     for item in world._decorative: item.node.visible=not batched
     await capture('%s-%s-%s'%[quality,'rest' if reduced else 'motion','optimized' if batched else 'baseline'])
 game.audio.shutdown();game.journey.profile_player.stop();await create_timer(0.2).timeout
 game.queue_free();await process_frame;await process_frame;game=null
 quit()
