extends Node
var game
var model
var store
var active := false
var warning := ''
var recovery_notice := ''
var path := 'user://still_here/journey_v1.json'
var profile_player: AudioStreamPlayer
var pack_metadata := {}
var activity_view
func initialize(owner_):
 game=owner_
 path=game.journey_save_path
 pack_metadata=JSON.parse_string(FileAccess.get_file_as_string("res://data/journey_pack.json"))
 profile_player=AudioStreamPlayer.new()
 add_child(profile_player)
 model=load('res://core/journey_model.gd').new()
 store=load('res://core/journey_store.gd').new()
 var loaded=store.load_snapshot(path)
 if loaded.ok:
  model.restore(loaded.data)
  if loaded.get("recovered",false): recovery_notice=str(loaded.error)
 elif loaded.error not in ['','missing']: warning=loaded.error
 active=loaded.ok and game.model.snapshot().get('campaign_complete',false) and model.snapshot().mode!='home'
 return self
func eligible(): return game.model.snapshot().get('campaign_complete',false)
func save() -> bool:
 var result=store.save_snapshot(model.snapshot(),path)
 warning='' if result.ok else 'Unsaved Journey progress: '+str(result.error)+'. Please keep this window open and retry.'
 game.hud.show_notice(warning)
 return result.ok
func show_save_problem():
 page('Journey changes have not been saved',warning+'\n\nYou can retry, stay here, or explicitly leave without saving only these latest Journey changes. Your campaign file remains intact.')
 game.hud.button('Retry save and leave',func():
  if save(): game.quit_to_desktop()
  else: show_save_problem()
 )
 game.hud.button('Quit without saving latest Journey changes',func(): game.quit_to_desktop())
 close_button(); focus_first()
func audio_profile():
 if not is_instance_valid(profile_player): return
 var d=selected_destination()
 var profile=d.get('music_profile',{'track':'res://assets/original/night_train.wav','gain_db':-16.0,'ambience':'Soft wheels along the rail'})
 var path_=str(profile.get('track',''))
 if path_.begins_with('res://assets/original/') and ResourceLoader.exists(path_):
  var stream=load(path_)
  if profile_player.stream!=stream:
   profile_player.stop(); profile_player.stream=stream
   if stream is AudioStreamWAV: game.audio.configure_loop(stream)
  var prefs=game.model.snapshot().settings
  var level=float(prefs.master)*float(prefs.music)
  profile_player.volume_db=linear_to_db(level)+float(profile.get('gain_db',-16.0)) if level>0 else -80.0
  if DisplayServer.get_name()!='headless' and not profile_player.playing: profile_player.play()
  game.audio.music.stop()
  game.hud.set_subtitle('['+str(profile.get('ambience','Quiet carriage'))+']')
func local_now() -> String:
 var d=Time.get_datetime_dict_from_system(false)
 return '%04d-%02d-%02d %02d:%02d'%[d.year,d.month,d.day,d.hour,d.minute]
func enter():
 if not eligible(): return
 active=true
 model.apply('return_train')
 model.apply('resolve_echoes',local_now())
 save()
 game.hud.close_all()
 game.route()
 show_board()
func selected_destination() -> Dictionary:
 var d=model.current_destination()
 if d.is_empty(): return d
 var count=int(model.snapshot().visits.get(d.journey_id,0))
 var times=d.get('available_time_states',['night'])
 var weather=d.get('weather_profile',{}).get('states',['clear'])
 d.time_state=times[count%times.size()]
 d.weather_state=weather[count%weather.size()]
 return d
func route():
 game.home_viewing=false
 game.home_cinematic=false
 for child in game.world_container.get_children():
  game.world_container.remove_child(child)
  child.queue_free()
 var snapshot=model.snapshot()
 var world=load('res://world/journey_world.gd').new().build(snapshot,game.model.snapshot(),selected_destination())
 game.world_container.add_child(world)
 game.player=load('res://player/player.gd').new()
 world.add_child(game.player)
 game.player.global_position=world.get_node('Spawn').global_position
 game.player.interact.connect(game.on_interact)
 var prefs=game.model.snapshot().settings
 game.player.set_preferences(prefs)
 game.configure_characters(world,prefs)
 game.hud.apply_settings(prefs)
 game.hud.title.text='PLATFORM 6 CONTINUES · '+('The carriage' if snapshot.mode=='train' else str(model.current_destination().get('title','Journey')))
 game.hud.set_subtitle('A bounded authored Journey. Return to the train whenever you like.')
 game.audio.apply_settings(prefs)
 var sound_locations={'rain_town':'apartment','unsent_letters_library':'paper_sky','arcade':'the_small_fair','beach_before_sunrise':'shoreline','winter_orchard':'quiet_orchard','rest_room':'still_here','failed_things_festival':'the_small_fair','sunrise_cafe':'night_kitchen','no_destination_road':'return_platform','fireflies':'overlook'}
 game.audio.crossfade_location('return_train' if snapshot.mode=='train' else str(sound_locations.get(snapshot.journey_id,'shoreline')))
 audio_profile()
 game.apply_graphics(prefs)
 world.get_node('AmbientMotion').apply_preferences(prefs.reduced_motion)
 world.apply_preferences(prefs.reduced_motion)
 game.busy=false
 game.resume_controls()
 if not warning.is_empty(): game.hud.show_notice(warning)
 elif not recovery_notice.is_empty(): game.hud.show_notice(recovery_notice)
func page(title:String,prose:String):
 game.hud.clear()
 game.hud.modal.show()
 game.player.set_controls_enabled(false)
 game.hud.text(title,28)
 game.hud.text(prose)
func close_button():
 game.hud.button('Back · Esc / B',func(): game.dispatch('dismiss'))
func body_button(label:String,callback:Callable):
 var b=Button.new()
 b.text=label; b.custom_minimum_size.y=46; b.set_meta('base_font_size',19)
 b.add_theme_font_size_override('font_size',int(19*game.model.snapshot().settings.text_scale))
 b.pressed.connect(callback); game.hud.content.add_child(b)
 return b
func focus_first():
 for child in game.hud.content.get_children():
  if child is Button: child.grab_focus(); return
 if game.hud.footer.get_child_count()>0: game.hud.footer.get_child(0).grab_focus()
func show_board():
 page('Where next?','Ten authored destinations, with changed returns and remembered details. No daily reward, deadline or required visit. The apartment is always available.')
 for destination in model.destinations():
  var id=str(destination.journey_id)
  var count=int(model.snapshot().visits.get(id,0))
  var label=str(destination.title)+(' · return '+str(count+1) if count>0 else '')
  var b=Button.new()
  b.text=label
  b.custom_minimum_size.y=46
  b.set_meta('base_font_size',19)
  b.add_theme_font_size_override('font_size',int(19*game.model.snapshot().settings.text_scale))
  b.pressed.connect(func(): dispatch('journey_board',id))
  game.hud.content.add_child(b)
 game.hud.button('Tiny Tomorrows & Future Echoes',func(): show_writing())
 game.hud.button('Return home',func(): dispatch('journey_home'))
 close_button()
 focus_first()
func show_story():
 var d=model.current_destination()
 if d.is_empty(): show_board(); return
 var s=model.snapshot()
 var visits=int(s.visits.get(d.journey_id,0))
 var entry=d.entry_variants.get('return' if visits>0 else 'first','')
 var stage=int(s.stage)
 var prose=entry+'\n\n'+str(d.story_nodes[mini(stage,2)])
 if stage==0:
  var life=pack_metadata.get('npc_lives',{}).get(str(d.npc).to_lower(),{})
  if not life.is_empty(): prose+='\n\n'+str(life.get('current_work',''))
  var memories=model.callback(game.model.snapshot())
  var catalog=model.destinations()
  var ordinal=0
  for i in catalog.size():
   if catalog[i].journey_id==d.journey_id: ordinal=i
  var keys=['camera','fair','sign','mira']
  var which=(ordinal+visits)%4
  var actual_indices=[0,1,2,4]
  var actual=actual_indices[which]
  prose+='\n\n'+str(d.get('callback_pool',{}).get(keys[which],''))
  if memories.size()>actual: prose+='\n'+str(memories[actual])
  if which==3 and memories.size()>5: prose+='\n'+str(memories[5])
  var state_id=str(s.location_states.get(d.journey_id,'as_found'))
  prose+='\n\n'+str(d.get('local_scene_states',{}).get(state_id,''))
 if stage>=2:
  for hook in d.get('tiny_tomorrow_hooks',[]): prose+='\n\nOptional invitation: '+str(hook.text)
 page(str(d.title),prose)
 if stage<2: game.hud.button('Continue this conversation',func(): dispatch('journey_advance'))
 else:
  for option in d.choice_nodes:
   body_button(str(option.label),func(): dispatch('journey_choose',option.choice_id))
  game.hud.button('Leave this moment as it is',func(): dispatch('journey_finish'))
 game.hud.button('Return to train now',func(): dispatch('journey_return_train'))
 close_button(); focus_first()
func show_activity():
 var d=model.current_destination()
 if d.is_empty(): return
 page(str(d.title)+' · '+str(d.activity_type).replace('_',' '),str(d.activity_prompt))
 activity_view=load('res://ui/journey_activity.gd').new().configure(str(d.activity_type),model.snapshot().activity,game.model.snapshot().settings.reduced_motion)
 game.hud.content.add_child(activity_view)
 activity_view.changed.connect(func(state):
  if model.apply('activity',state):
   save()
   game.world_container.get_child(0).update_activity(state)
   if state.done: game.hud.show_notice('The object holds your arrangement. You can keep looking or leave.')
 )
 var actions=[]
 match str(d.activity_type):
  'rain_routing': actions=[['Turn left gutter','0'],['Turn middle gutter','1'],['Turn right gutter','2']]
  'letter_arrangement': actions=[['Swap left pair','swap_left'],['Swap right pair','swap_right']]
  'constellation_tracing': actions=[['Trace point 1','0'],['Trace point 2','1'],['Trace point 3','2'],['Undo last connection','undo']]
  'tea_mixing': actions=[['Add / remove amber leaf','0'],['Add / remove mint','1'],['Add / remove hibiscus','2'],['Pour this blend','pour']]
  'arcade_paddle': actions=[['Paddle left','left'],['Paddle right','right'],['Launch the ball','launch'],['Watch the cabinet demonstrate','observe']]
  _: actions=[['Notice the next small detail','next']]
 for item in actions:
  var b=Button.new()
  b.text=str(item[0]); b.custom_minimum_size.y=46; b.set_meta('base_font_size',19)
  b.add_theme_font_size_override('font_size',int(19*game.model.snapshot().settings.text_scale))
  b.pressed.connect(func(): if is_instance_valid(activity_view): activity_view.act(item[1]))
  game.hud.content.add_child(b)
 game.hud.button('Continue the scene',func(): show_story())
 game.hud.button('Return to train',func(): dispatch('journey_return_train'))
 close_button(); focus_first()
func show_writing():
 page('Private words, kept here','Optional, local-only writing. Your words stay exactly as you type them. These are not tasks to earn anything. Future Echoes appear here when you return after the chosen local time; no reminders or network delivery.')
 var s=model.snapshot()
 for tiny in s.tiny_tomorrows:
  game.hud.text(str(tiny.text)+' · '+str(tiny.state),18)
  for status in ['SOMEDAY','HAPPENED','NOT ANYMORE']:
   var b=Button.new(); b.text=status; b.custom_minimum_size.y=40; b.set_meta('base_font_size',19)
   b.pressed.connect(func(): dispatch('journey_tiny_change',{'id':tiny.id,'state':status}))
   game.hud.content.add_child(b)
 for echo in s.future_echoes:
  game.hud.text('Future Echo · '+str(echo.text) if str(echo.due_local)<=local_now() else 'A Future Echo is kept for '+str(echo.due_local),18)
 var words=TextEdit.new()
 words.name='PrivateWords'
 words.placeholder_text='Your own words (optional, up to 1,000 characters)'
 words.custom_minimum_size=Vector2(620,120)
 words.add_theme_font_size_override('font_size',int(19*game.model.snapshot().settings.text_scale))
 words.set_meta('base_font_size',19)
 game.hud.content.add_child(words)
 var when=LineEdit.new()
 when.name='EchoLocalTime'
 when.set_meta('base_font_size',19)
 when.add_theme_font_size_override('font_size',int(19*game.model.snapshot().settings.text_scale))
 when.placeholder_text='Local time: YYYY-MM-DD HH:MM'
 when.text=local_now()
 game.hud.content.add_child(when)
 game.hud.button('Keep as a Tiny Tomorrow',func(): dispatch('journey_tiny_create',{'text':words.text}))
 game.hud.button('Keep as a Future Echo',func(): dispatch('journey_echo_create',{'text':words.text,'due_local':when.text,'created_local':local_now()}))
 game.hud.button('Return to destination board',func(): show_board())
 close_button(); focus_first()
func dispatch(action:String,value:Variant=null):
 if action=='journey_enter': enter(); return
 if not active or not eligible(): return
 match action:
  'journey_board':
   if value==null or (typeof(value)==TYPE_STRING and value.is_empty()): show_board(); return
   if not model.apply('board',value): return
   save(); game.hud.close_all(); game.route(); show_story()
  'journey_activity': show_activity()
  'journey_story': show_story()
  'journey_writing': show_writing()
  'journey_advance':
   if model.apply('advance'): save(); show_story()
  'journey_choose':
   if model.apply('choose',value):
    save()
    var d=model.current_destination()
    var response=''
    for option in d.choice_nodes:
     if option.choice_id==value: response=str(option.response)
    model.apply('finish'); save(); game.hud.close_all(); game.route()
    game.hud.show_notice(response if warning.is_empty() else warning)
  'journey_finish','journey_return_train':
   if model.apply('finish' if action=='journey_finish' else 'return_train'):
    save(); game.hud.close_all(); game.route()
  'journey_home':
   model.apply('home')
   if not save(): return
   active=false; profile_player.stop(); game.hud.close_all(); game.route()
  'journey_tiny_create','journey_tiny_change','journey_echo_create':
   var method={'journey_tiny_create':'tiny_create','journey_tiny_change':'tiny_change','journey_echo_create':'echo_create'}[action]
   if model.apply(method,value): save(); show_writing()
   else: game.hud.show_notice('Please use non-empty words and a real local date/time. This shelf holds up to 32 of each kind.')
