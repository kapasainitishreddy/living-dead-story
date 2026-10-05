extends Control
signal changed(state)
var kind := 'observation'
var state := {'step':0,'selection':0,'progress':0,'done':false}
var ball := Vector2(0.5,0.25)
var velocity := Vector2(0.16,0.42)
var launched := false
var suspended := false
var reduced := false
const ORDERS = [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]
func _init():
 custom_minimum_size = Vector2(620,230)
 mouse_filter = Control.MOUSE_FILTER_STOP
func configure(type_:String, saved:Dictionary, reduced_:bool):
 kind = type_
 for key in state: state[key] = saved.get(key,state[key])
 reduced = reduced_
 queue_redraw()
 return self
func apply_preferences(value: bool):
 reduced=value
 if reduced and launched: complete_arcade()
 queue_redraw()
func act(command:String):
 if suspended: return
 match kind:
  'rain_routing':
   if command in ['0','1','2']: state.selection = int(state.selection) ^ (1 << int(command))
   state.done = state.selection == 5
   state.progress = int(state.done)
  'letter_arrangement':
   var order = ORDERS[int(state.selection)%6].duplicate()
   if command == 'swap_left': var x=order[0]; order[0]=order[1]; order[1]=x
   if command == 'swap_right': var x=order[1]; order[1]=order[2]; order[2]=x
   state.selection = ORDERS.find(order)
   state.done = order == [2,0,1]
   state.progress = int(state.done)
  'constellation_tracing':
   if command == 'undo' and int(state.step)>0:
    state.step-=1
    state.selection=int(state.selection)&~(1<<int(state.step))
   if command in ['0','1','2']:
    var node = int(command)
    if node == int(state.step): state.selection = int(state.selection) | (1<<node); state.step += 1
   state.done = state.selection == 7
   state.progress = int(state.step)
  'tea_mixing':
   if command in ['0','1','2']: state.selection = int(state.selection) ^ (1<<int(command))
   if command == 'pour': state.done = true; state.progress = 1
  'arcade_paddle':
   if command == 'left': state.selection = maxi(0,int(state.selection)-1)
   if command == 'right': state.selection = mini(10,int(state.selection)+1)
   if command == 'launch':
    state.done=false
    state.progress=0
    ball=Vector2(0.5,0.25)
    velocity=Vector2(0.16,0.42)
    launched=true
    if reduced: complete_arcade()
   if command == 'observe': complete_arcade()
  _:
   state.step = mini(3,int(state.step)+1)
   state.done = state.step >= 3
   state.progress = state.step
 changed.emit(state.duplicate(true))
 queue_redraw()
func complete_arcade():
 launched=false
 state.done=true
 state.progress=1
 ball=Vector2(0.5,0.18)
 changed.emit(state.duplicate(true))
 queue_redraw()
func _process(delta):
 if kind != 'arcade_paddle' or not launched or suspended or not is_visible_in_tree(): return
 ball += velocity * minf(delta,0.05)
 if ball.x < 0.02 or ball.x > 0.98: velocity.x *= -1; ball.x=clampf(ball.x,0.02,0.98)
 if ball.y >= 0.93 and velocity.y>0:
  if absf(ball.x-float(state.selection)/10.0)<=0.16:
   velocity.y=-absf(velocity.y)
   state.progress=1
   changed.emit(state.duplicate(true))
  else:
   launched=false
   ball=Vector2(0.5,0.25)
 if ball.y<=0.1 and velocity.y<0: complete_arcade()
 queue_redraw()
func _gui_input(event):
 if kind == 'arcade_paddle' and event is InputEventMouseButton and event.pressed:
  state.selection = clampi(int(event.position.x/maxf(size.x,1)*10),0,10)
  act('launch')
func _draw():
 var width = maxf(size.x,620)
 draw_style_box(make_box(),Rect2(0,0,width,220))
 var cream=Color('eddec0')
 var amber=Color('eeba67')
 match kind:
  'rain_routing':
   draw_line(Vector2(60,30),Vector2(width-60,30),Color('718da8'),5)
   for i in 3:
    var x=100+i*200
    draw_line(Vector2(x,30),Vector2(x,95),Color('718da8'),5)
    var tilted = (int(state.selection)&(1<<i))!=0
    draw_line(Vector2(x-55,100+(-20 if tilted else 20)),Vector2(x+55,100+(20 if tilted else -20)),amber,7)
    draw_rect(Rect2(x-40,170,80,22),Color('80bda0') if ((i!=1)==tilted) else Color('66577b'))
  'letter_arrangement':
   var words=['STAMP','LETTER','ENVELOPE']
   var order=ORDERS[int(state.selection)%6]
   for i in 3:
    draw_rect(Rect2(35+i*200,45,175,130),Color('c4b393'))
    draw_string(ThemeDB.fallback_font,Vector2(50+i*200,115),words[order[i]],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color('24374e'))
  'constellation_tracing':
   var points=[Vector2(90,170),Vector2(300,45),Vector2(520,145)]
   for i in 3:
    draw_circle(points[i],13,amber if (int(state.selection)&(1<<i))!=0 else cream)
    draw_string(ThemeDB.fallback_font,points[i]+Vector2(-5,-25),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,18,cream)
    if i>0 and (int(state.selection)&(1<<i))!=0: draw_line(points[i-1],points[i],amber,3)
  'tea_mixing':
   var colors=[Color('dfa968'),Color('78a388'),Color('c26a73')]
   var mix=Color('b78351')
   for i in 3:
    draw_circle(Vector2(120+i*180,65),30,colors[i])
    if (int(state.selection)&(1<<i))!=0: mix=mix.lerp(colors[i],0.4); draw_line(Vector2(120+i*180,105),Vector2(310,165),colors[i],4)
   draw_rect(Rect2(240,145,140,55),mix)
  'arcade_paddle':
   draw_rect(Rect2(40,25,width-80,18),Color('789f8c'))
   draw_rect(Rect2(40+float(state.selection)/10*(width-150),185,70,10),amber)
   draw_circle(Vector2(40+ball.x*(width-80),45+ball.y*140),10,cream)
  _:
   for i in 3: draw_circle(Vector2(130+i*180,110),24,amber if i<int(state.step) else Color('596d80'))
func make_box():
 var box=StyleBoxFlat.new()
 box.bg_color=Color('172a3c')
 box.corner_radius_top_left=12
 box.corner_radius_top_right=12
 box.corner_radius_bottom_left=12
 box.corner_radius_bottom_right=12
 return box
