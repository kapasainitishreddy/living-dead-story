extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok: failures+=1; printerr('FAIL '+label)
func _initialize(): call_deferred('run')
func run():
 var A=load('res://ui/journey_activity.gd')
 for kind in ['rain_routing','letter_arrangement','constellation_tracing','tea_mixing','arcade_paddle','observation']:
  var a=A.new().configure(kind,{},true)
  match kind:
   'rain_routing': a.act('0'); a.act('2')
   'letter_arrangement': a.act('swap_right'); a.act('swap_left')
   'constellation_tracing': a.act('2'); check(a.state.step==0,'trace respects actual path'); a.act('0'); a.act('1'); a.act('2')
   'tea_mixing': a.act('1'); a.act('pour')
   'arcade_paddle': a.act('right'); a.act('launch')
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
  b.free(); a.free()
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
 arcade.suspended=false
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
