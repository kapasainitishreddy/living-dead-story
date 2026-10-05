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
  await capture(d.journey_id+'_first')
  check(game.world_container.get_child(0).find_children('*','Node',true,false).size()<1000,'bounded '+d.journey_id)
  for i in 15:
   var before=Time.get_ticks_usec()
   await process_frame
   frame_samples.append((Time.get_ticks_usec()-before)/1000.0)
  game.dispatch('journey_activity')
  await capture(d.journey_id+'_activity')
  layout(d.journey_id+' activity')
  var settings=game.model.snapshot().settings
  settings.text_scale=2.0; settings.reduced_motion=true
  game.change_settings(settings)
  game.journey.show_activity()
  await capture(d.journey_id+'_2x_reduced')
  layout(d.journey_id+' 2x')
  game.show_pause(); await capture(d.journey_id+'_pause'); layout(d.journey_id+' pause')
  game.hud.resume_pause()
  check(game.hud.modal_visible(),'activity returns after pause '+d.journey_id)
  game.dispatch('journey_advance'); game.dispatch('journey_advance')
  await capture(d.journey_id+'_story_2x'); layout(d.journey_id+' final story 2x')
  check(game.hud.content.get_children().filter(func(b): return b is Button).size()==3,'three actual authored choice buttons '+d.journey_id)
  game.dispatch('journey_choose',d.choice_nodes[0].choice_id)
  game.dispatch('journey_board',d.journey_id)
  game.hud.close_all(); game.resume_controls()
  await capture(d.journey_id+'_return')
  game.dispatch('journey_return_train')
  settings.text_scale=1.0; settings.reduced_motion=false; game.change_settings(settings)
 game.hud.close_all(); game.resume_controls()
 await capture('train_evolved')
 game.dispatch('journey_writing'); await capture('private_writing_empty'); layout('writing')
 frame_samples.sort()
 var stats={'samples':frame_samples.size(),'median_ms':frame_samples[frame_samples.size()/2],'p95_ms':frame_samples[int(frame_samples.size()*0.95)],'renderer':'Godot Compatibility llvmpipe','scope':'Firefly destination only, 15 steady native frames; software-renderer observation only'}
 var f=FileAccess.open(directory+'/performance.json',FileAccess.WRITE);f.store_string(JSON.stringify(stats,'  '));f.close()
 game.audio.shutdown(); game.journey.profile_player.stop(); await create_timer(0.2).timeout
 game.queue_free();await process_frame;await process_frame;game=null
 print('JOURNEY RENDERED ',checks,' checks ',failures,' failures ',JSON.stringify(stats))
 quit(1 if failures else 0)
