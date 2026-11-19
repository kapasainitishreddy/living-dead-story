extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok: failures+=1; printerr('FAIL '+label)
func _initialize(): call_deferred('run')
func run():
 var A=load('res://ui/journey_activity.gd')
 for kind in ['rain_routing','letter_arrangement','constellation_tracing','tea_mixing','arcade_paddle','observation','shelter_parade','market_rescue']:
  var a=A.new().configure(kind,{},true)
  match kind:
   'rain_routing': a.act('0'); a.act('2')
   'letter_arrangement': a.act('swap_right'); a.act('swap_left')
   'constellation_tracing': a.act('2'); check(a.state.step==0,'trace respects actual path'); a.act('0'); a.act('1'); a.act('2')
   'tea_mixing': a.act('1'); a.act('pour')
   'arcade_paddle': a.act('right'); a.act('launch')
   'shelter_parade': a.act('0'); a.act('2'); a.act('parade'); check(a.state.step==2 and a.state.selection==5,'arranged parade records actual paper route')
   'market_rescue': a.act('0'); a.act('1'); a.act('2'); check(a.state.step==2 and a.state.selection==7 and a.state.progress==3,'three optional paper-market route markers completed')
   _: a.act('next'); a.act('next'); a.act('next')
  check(a.state.done,'distinct activity completes '+kind)
  var b=A.new().configure(kind,a.state,true)
  check(b.state==a.state,'activity durable '+kind)
  var before=a.state.duplicate(true)
  match kind:
   'rain_routing': a.act('0'); check(not a.state.done,'rain stays reversible after arrangement')
   'letter_arrangement': a.act('swap_left'); check(not a.state.done,'letter swaps remain reversible')
   'constellation_tracing': a.act('undo'); check(not a.state.done and a.state.step==2,'trace undo survives completion')
   'tea_mixing': a.act('2'); check(a.state.selection!=before.selection,'tea blend remains editable')
   'shelter_parade': a.act('1'); check(not a.state.done and a.state.step==0 and a.state.selection!=before.selection,'paper gates stay reversible after completion')
   'market_rescue': a.act('1'); check(not a.state.done and a.state.progress==2 and a.state.selection!=before.selection,'paper grocery routes are reversible')
  b.free(); a.free()
 var observed=A.new().configure('shelter_parade',{},true)
 observed.act('watch')
 check(observed.state.done and observed.state.step==1 and observed.state.selection==0,'watching Jo has its own durable path without arranging gates')
 var resumed=A.new().configure('shelter_parade',observed.state,true)
 check(resumed.state==observed.state,'spectator path survives save and reopen')
 resumed.act('0')
 check(not resumed.state.done and resumed.state.step==0,'spectator can change their mind and arrange a gate')
 resumed.free(); observed.free()
 var guided=A.new().configure('market_rescue',{},true)
 guided.act('watch')
 check(guided.state.done and guided.state.step==1 and guided.state.progress==3,'watching Jo has equal access')
 guided.act('0')
 check(not guided.state.done and guided.state.step==0 and guided.state.progress==1,'watching can be followed by an ordinary route')
 guided.free()
 # Jo's three cardboard gates can be arranged by directly touching the
 # illustration; completing or watching never makes a gate irreversible.
 var shelter_tap=A.new().configure('shelter_parade',{},false)
 root.add_child(shelter_tap)
 await process_frame
 shelter_tap.set_process(false)
 var gate_events: Array = []
 shelter_tap.changed.connect(func(_state): gate_events.append(true))
 var gate_press=InputEventMouseButton.new()
 gate_press.button_index=MOUSE_BUTTON_LEFT
 gate_press.pressed=true
 for index in 3:
  gate_press.position=Vector2(120+180*index,105)
  shelter_tap._gui_input(gate_press)
  check((int(shelter_tap.state.selection)&(1<<index))!=0,'drawn shelter gate responds to press '+str(index))
 check(shelter_tap.state.selection==7 and not shelter_tap.state.done and gate_events.size()==3,'three taps arrange the paper gates without auto-finishing')
 shelter_tap.act('parade')
 check(shelter_tap.state.done and shelter_tap.state.step==2,'deliberate paper parade has its own payoff')
 gate_press.position=Vector2(120,105)
 shelter_tap._gui_input(gate_press)
 check(not shelter_tap.state.done and shelter_tap.state.selection==6,'completed route remains reversible through the illustrated gate')
 var before_empty=gate_events.size()
 gate_press.position=Vector2(30,190)
 shelter_tap._gui_input(gate_press)
 check(gate_events.size()==before_empty,'blank shelter board space never flips gates')
 shelter_tap.suspended=true
 gate_press.position=Vector2(120,105)
 shelter_tap._gui_input(gate_press)
 check(gate_events.size()==before_empty,'paused shelter panel does not alter the route')
 shelter_tap.suspended=false
 var wrong_gate=InputEventMouseButton.new()
 wrong_gate.button_index=MOUSE_BUTTON_RIGHT
 wrong_gate.pressed=true
 wrong_gate.position=Vector2(120,105)
 shelter_tap._gui_input(wrong_gate)
 check(gate_events.size()==before_empty,'secondary click cannot flip a gate')
 shelter_tap.free()
 # The on-panel cards respond to mouse and emulated finger taps. The same
 # act() path remains callable by named keyboard/controller buttons.
 var tapped=A.new().configure('market_rescue',{},false)
 root.add_child(tapped)
 await process_frame
 tapped.set_process(false)
 var taps: Array = []
 tapped.changed.connect(func(_state): taps.append(true))
 var tap=InputEventMouseButton.new()
 tap.button_index=MOUSE_BUTTON_LEFT
 tap.pressed=true
 for index in 3:
  tap.position=Vector2(115+180*index,110)
  tapped._gui_input(tap)
  check((int(tapped.state.selection) & (1<<index)) != 0,'drawn market marker responds to direct press '+str(index))
 check(tapped.state.done and tapped.state.progress==3 and taps.size()==3,'three in-panel presses complete actual market activity once each')
 tap.position=Vector2(257,203)
 tapped._gui_input(tap)
 check(taps.size()==3,'blank board area never toggles a marker')
 tapped.suspended=true
 tap.position=Vector2(115,110)
 tapped._gui_input(tap)
 check(taps.size()==3,'paused direct marker press is ignored')
 tapped.suspended=false
 tapped._gui_input(tap)
 check(not tapped.state.done and tapped.state.progress==2 and taps.size()==4,'direct marker tap reverses an already finished route')
 tapped.free()
 var arcade=A.new().configure('arcade_paddle',{'selection':8},false)
 root.add_child(arcade)
 await process_frame
 arcade.set_process(false)
 arcade.act('launch')
 check(not arcade.state.done and arcade.launched,'native-motion arcade needs actual bounce')
 arcade.suspended=true
 var still=arcade.ball
 arcade._process(0.05)
 check(arcade.ball==still,'arcade paused physical ball frozen')
 var arcade_press=InputEventMouseButton.new()
 arcade_press.button_index=MOUSE_BUTTON_LEFT
 arcade_press.pressed=true
 arcade_press.position=Vector2(80,110)
 arcade._gui_input(arcade_press)
 check(arcade.state.selection==8 and arcade.ball==still,'paused arcade press cannot re-aim or restart')
 arcade.suspended=false
 arcade_press.button_index=MOUSE_BUTTON_RIGHT
 arcade._gui_input(arcade_press)
 check(arcade.state.selection==8 and arcade.ball==still,'secondary arcade click cannot restart the ball')
 for i in 90: arcade._process(0.05)
 check(arcade.state.done and arcade.state.progress==1,'aligned paddle physically returns ball')
 arcade.state={'step':0,'selection':0,'progress':0,'done':false}
 arcade.act('launch')
 for i in 50: arcade._process(0.05)
 check(not arcade.state.done and not arcade.launched,'miss resets without score or penalty')
 for i in 15: arcade.act('left')
 check(arcade.state.selection==0,'paddle left bound')
 for i in 15: arcade.act('right')
 check(arcade.state.selection==10,'paddle right bound')
 arcade.queue_free(); await process_frame
 print('JOURNEY ACTIVITY ',checks,' checks ',failures,' failures')
 quit(1 if failures else 0)
