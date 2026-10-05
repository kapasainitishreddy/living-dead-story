extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures += 1; printerr('FAIL: '+label)
func _initialize(): call_deferred('run')
func completed_campaign(ending:String):
 var helper=load('res://tests/home_runtime.gd').new()
 var seed=helper.completed_return('lend')
 helper.free()
 var m=load('res://core/chapter_model.gd').new()
 m.restore(seed)
 for item in [['begin_home',null],['home_ticket','drawer'],['home_ritual','neither'],['home_finish',ending]]: m.apply(item[0],item[1])
 return m.snapshot()
func run():
 var game = load('res://main.tscn').instantiate()
 game.save_path = 'user://journey_runtime_campaign_'+str(Time.get_ticks_usec())+'.json'
 root.add_child(game)
 await process_frame
 check(game.get('journey') != null,'Journey runtime is integrated')
 check(game.hud.has_method('show_journey_available'),'Both campaign endings offer real Journey entry')
 game.journey.path='user://journey_runtime_'+str(Time.get_ticks_usec())+'.json'
 check(not game.journey.eligible(),'campaign cannot be skipped to Journey')
 game.dispatch('journey_enter')
 check(not game.journey.active,'early Journey entry rejected')
 if game.journey.model.destinations().size()!=10:
  check(false,'real authored ten destination pack present')
  await shutdown(game); return
 for ending in ['train','sleep']:
  var campaign=completed_campaign(ending)
  check(game.model.restore(campaign),'completed '+ending+' seed')
  game.journey.active=false
  game.journey.model=load('res://core/journey_model.gd').new()
  game.route()
  check(game.hud.footer.get_children().any(func(b): return b.text.contains('Journey Mode') and not b.disabled),'real entry available '+ending)
  game.dispatch('journey_enter')
  check(game.journey.active and game.journey.model.snapshot().mode=='train','entered carriage '+ending)
  check(game.hud.content.get_children().filter(func(b): return b is Button).size()==10,'board has ten actual controls '+ending)
  game.hud.close_all();game.resume_controls()
  var physical_board=game.world_container.get_child(0).find_child('journey_board',true,false)
  game.on_interact(physical_board)
  check(game.hud.modal_visible() and game.hud.content.get_children().filter(func(b): return b is Button).size()==10,'physical train board target opens ten destinations '+ending)

  for d in game.journey.model.destinations():
   game.dispatch('journey_board',d.journey_id)
   await process_frame
   check(game.journey.model.snapshot().journey_id==d.journey_id,'boards '+d.journey_id)
   check(game.world_container.get_child(0).get_node_or_null('Spawn')!=null,'physical destination '+d.journey_id)
   check(game.store.save_snapshot(campaign,game.save_path).ok,'fixture campaign durable')
   game.dispatch('journey_activity')
   check(is_instance_valid(game.journey.activity_view),'actual activity '+d.activity_type)
   game.show_pause()
   check(game.hud.pause_active,'pause in activity '+d.journey_id)
   game.hud.resume_pause()
   await process_frame
   check(game.hud.modal_visible() and is_instance_valid(game.journey.activity_view),'same activity survives pause '+d.journey_id)
   if d.activity_type=='arcade_paddle':
    var same=game.journey.activity_view
    same.act('launch')
    game.show_pause()
    var prefs=game.model.snapshot().settings
    prefs.reduced_motion=true
    game.change_settings(prefs)
    game.hud.resume_pause()
    check(game.journey.activity_view==same and same.reduced and not same.launched and same.state.done,'live paused reduced motion settles exact arcade widget')
    prefs.reduced_motion=false
    game.change_settings(prefs)
    campaign=game.model.snapshot()

   game.dispatch('journey_return_train')
   check(game.journey.model.snapshot().mode=='train','comfortable stop '+d.journey_id)
   game.dispatch('journey_board',d.journey_id)
   check(game.journey.model.snapshot().stage==0,'partial visit resumes authored stage '+d.journey_id)
   game.dispatch('journey_advance'); game.dispatch('journey_advance')
   var choices=d.choice_nodes
   if not choices.is_empty(): game.dispatch('journey_choose',choices[0].choice_id)
   else: game.dispatch('journey_finish')
   check(game.journey.model.snapshot().mode=='train','authored scene returns train '+d.journey_id)
   check(game.journey.model.snapshot().visits.get(d.journey_id,0)==1,'completed visit remembered '+d.journey_id)
   check(game.model.snapshot()==campaign,'campaign unchanged throughout '+d.journey_id)
   check(game.store.load_snapshot(game.save_path).data==campaign,'campaign file separate '+d.journey_id)
   check(game.journey.store.load_snapshot(game.journey.path).data==game.journey.model.snapshot(),'Journey reload exact '+d.journey_id)
  game.dispatch('journey_writing')
  game.dispatch('journey_tiny_create',{'text':'  My actual words\nunchanged  '})
  var tiny=game.journey.model.snapshot().tiny_tomorrows
  check(tiny.size()==1 and tiny[0].text=='  My actual words\nunchanged  ','private words unmodified '+ending)
  game.dispatch('journey_tiny_change',{'id':tiny[0].id,'state':'NOT ANYMORE'})
  check(game.journey.model.snapshot().tiny_tomorrows[0].state=='NOT ANYMORE','Tiny can change without penalty '+ending)
  game.dispatch('journey_echo_create',{'text':'For later, exactly.','due_local':'2030-01-01 10:00','created_local':'2026-10-03 12:00'})
  check(game.journey.model.snapshot().future_echoes.size()==1,'local Future Echo '+ending)
  var original_path=game.journey.path
  game.journey.path='/proc/platform6_journey_unwritable/save.json'
  game.request_quit()
  check(not game.quitting and not game.journey.warning.is_empty(),'failed save blocks accidental quit '+ending)
  check(game.hud.footer.get_children().any(func(b): return b.text.contains('without saving')),'failed save retains explicit comfortable exit '+ending)
  game.journey.path=original_path
  game.hud.close_all()
  game.dispatch('journey_home')
  check(not game.journey.active and game.model.snapshot()==campaign,'comfortable unchanged home '+ending)
  check(game.journey.model.snapshot().mode=='home','home resume durable '+ending)
 var recovery_path='user://journey_recovery_notice_'+str(Time.get_ticks_usec())+'.json'
 var recovered_store=game.journey.store
 var original=game.journey.model.snapshot()
 recovered_store.save_snapshot(original,recovery_path)
 recovered_store.save_snapshot(original,recovery_path)
 var broken=FileAccess.open(recovery_path,FileAccess.WRITE); broken.store_string('{broken'); broken.close()
 game.journey_save_path=recovery_path
 var checker=load('res://core/journey_runtime.gd').new()
 game.add_child(checker)
 checker.initialize(game)
 check(checker.recovery_notice.contains('Recovered backup') and checker.warning.is_empty(),'successful backup recovery is disclosed separately from unsaved state')
 checker.queue_free()
 await shutdown(game)
func shutdown(game):
 game.audio.shutdown()
 await create_timer(0.2).timeout
 game.queue_free()
 await process_frame
 await process_frame
 print('JOURNEY RUNTIME ',checks,' checks ',failures,' failures')
 quit(1 if failures else 0)
