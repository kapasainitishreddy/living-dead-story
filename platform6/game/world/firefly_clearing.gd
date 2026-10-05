extends Node3D
# Original authored geometry. All scenery is outside gameplay collision contracts.
var w: Node3D
var rng = RandomNumberGenerator.new()
var firefly_batch: MultiMesh
var firefly_proxies: Array[MeshInstance3D] = []
var firefly_radii: Array[float] = []
func build(world: Node3D):
 w = world
 rng.seed = 62026
 _terrain()
 _sky()
 _hills()
 _trees()
 _grass()
 _stream()
 _lamps()
 _fireflies()
func _material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
 var m = StandardMaterial3D.new()
 m.albedo_color = color
 m.roughness = 1.0
 m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_PIXEL
 m.cull_mode = BaseMaterial3D.CULL_DISABLED
 return m
func _mesh(id: String, vertices: PackedVector3Array, colors: PackedColorArray, unshaded: bool = false) -> MeshInstance3D:
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in vertices.size():
  st.set_color(colors[i]); st.add_vertex(vertices[i])
 st.generate_normals()
 var n = MeshInstance3D.new()
 n.name = id; n.mesh = st.commit()
 var mat = _material(Color.WHITE,unshaded)
 mat.vertex_color_use_as_albedo = true
 n.material_override = mat
 add_child(n)
 return n
func _tri(v: PackedVector3Array,c: PackedColorArray,a:Vector3,b:Vector3,d:Vector3,color:Color):
 v.append(a);v.append(b);v.append(d)
 c.append(color);c.append(color);c.append(color)
func _height(x:float,z:float) -> float:
 # Exactly flat in the walkable clearing; sculpted scenery outside safe bounds.
 return -0.015 if absf(x)<6.8 and absf(z)<6.8 else -0.04+0.55*sin(x*0.21)*sin(z*0.18)+0.35*cos(z*0.16)
func _terrain():
 var v=PackedVector3Array();var c=PackedColorArray()
 for zi in range(64):
  for xi in range(64):
   var x=-48.0+xi*1.5;var z=-64.0+zi*1.5
   var a=Vector3(x,_height(x,z),z);var b=Vector3(x+1.5,_height(x+1.5,z),z)
   var d=Vector3(x,_height(x,z+1.5),z+1.5);var e=Vector3(x+1.5,_height(x+1.5,z+1.5),z+1.5)
   var col=Color("344c50").lerp(Color("5b7263"),rng.randf()*0.32)
   var pool=maxf(exp(-Vector2(x+3.3,z+2.5).length_squared()*0.14),exp(-Vector2(x-3.9,z+3.0).length_squared()*0.14))
   col=col.lerp(Color("9b9270"),pool*0.60)
   if z< -9: col=col.lerp(Color("273c50"),0.45)
   _tri(v,c,a,d,b,col);_tri(v,c,b,d,e,col)
 for i in v.size():
  var x=v[i].x;var z=v[i].z
  var tint=0.20+0.13*sin(x*0.43+sin(z*0.35))+0.07*cos(z*0.67)
  var col=Color("344c50").lerp(Color("667c69"),tint)
  var pool=maxf(exp(-Vector2(x+3.3,z+2.5).length_squared()*0.14),exp(-Vector2(x-3.9,z+3.0).length_squared()*0.14))
  c[i]=col.lerp(Color("9b9270"),pool*0.65)
 _mesh("PaintedMeadow",v,c,true)
 # Smooth center ribbon and blended shoulders, continuous from foreground to stream.
 v=PackedVector3Array();c=PackedColorArray()
 for i in range(100):
  var z=18.0-i*0.42;var zz=z-0.42
  var x=sin((z+1.0)*0.31)*0.72;var xx=sin((zz+1.0)*0.31)*0.72
  for strip in range(4):
   var widths=[-1.35,-0.87,0.0,0.87,1.35]
   var a=Vector3(x+widths[strip],_height(x,z)+0.025,z)
   var b=Vector3(x+widths[strip+1],_height(x,z)+0.025,z)
   var d=Vector3(xx+widths[strip],_height(xx,zz)+0.025,zz)
   var e=Vector3(xx+widths[strip+1],_height(xx,zz)+0.025,zz)
   _tri(v,c,a,d,b,Color.WHITE);_tri(v,c,b,d,e,Color.WHITE)
 for i in v.size():
  var point=v[i];var center=sin((point.z+1)*0.31)*0.72
  var edge=clampf((absf(point.x-center)-0.85)/0.5,0,1)
  var tint=0.20+0.13*sin(point.x*0.43+sin(point.z*0.35))+0.07*cos(point.z*0.67)
  var grass=Color("344c50").lerp(Color("667c69"),tint)
  var path=Color("737d6b").lerp(Color("818a73"),0.12+0.08*sin(point.z*0.29))
  c[i]=path.lerp(grass,edge)
 _mesh("WindingFootpath",v,c,true)
func _sky():
 var env=w.get_node("JourneyEnvironment").environment
 var sky=Sky.new();var mat=ShaderMaterial.new();var shader=Shader.new()
 shader.code='''shader_type sky;
void sky(){
 float h=clamp(EYEDIR.y,0.0,1.0);
 vec3 col=mix(vec3(0.20,0.26,0.40),vec3(0.045,0.067,0.155),smoothstep(0.0,0.7,h));
 vec2 uv=vec2(atan(EYEDIR.x,EYEDIR.z),asin(EYEDIR.y));
 vec2 cell=floor(uv*180.0);vec2 local=fract(uv*180.0)-0.5;
 float hash=fract(cell.x*0.754877666+cell.y*0.569840296);
 float star=(1.0-smoothstep(0.0,0.055,length(local)))*step(0.985,hash)*smoothstep(0.05,0.25,h);
 col+=star*vec3(0.65,0.70,0.65);
 vec3 moon_dir=normalize(vec3(0.55,0.24,-1.0));
 float moon=1.0-smoothstep(0.00016,0.00025,1.0-dot(EYEDIR,moon_dir));
 float halo=exp(-max(0.0,1.0-dot(EYEDIR,moon_dir))*65.0);
 col+=vec3(0.08,0.10,0.13)*halo;
 col=mix(col,vec3(0.92,0.91,0.76),moon);
 COLOR=col;
}'''
 mat.shader=shader;sky.sky_material=mat
 env.sky=sky;env.background_mode=Environment.BG_SKY
 env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
func _hills():
 for layer in range(4):
  var v=PackedVector3Array();var c=PackedColorArray()
  var z=-50.0+layer*9.0
  var col=[Color("49566f"),Color("3a4b63"),Color("2d4357"),Color("253c48")][layer]
  for i in range(88):
   var x=-66.0+i*1.5
   var y=3.5+sin(i*0.135+layer*1.4)*2.2+sin(i*0.315+layer)*0.65+layer*0.3
   var yy=3.5+sin((i+1)*0.135+layer*1.4)*2.2+sin((i+1)*0.315+layer)*0.65+layer*0.3
   _tri(v,c,Vector3(x,-3,z),Vector3(x,y,z),Vector3(x+1.5,yy,z),col)
   _tri(v,c,Vector3(x,-3,z),Vector3(x+1.5,yy,z),Vector3(x+1.5,-3,z),col)
  _mesh("RollingRidge%d"%layer,v,c,true)
 # Distant evening train across the far slope. Silhouette first, warm punctuation.
 var bankv=PackedVector3Array();var bankc=PackedColorArray()
 for i in range(28):
  var x=-35.0+i*2.5
  _tri(bankv,bankc,Vector3(x,0,-17.5),Vector3(x,1.2,-19),Vector3(x+2.5,1.2,-19),Color("40514e"))
  _tri(bankv,bankc,Vector3(x,0,-17.5),Vector3(x+2.5,1.2,-19),Vector3(x+2.5,0,-17.5),Color("40514e"))
 _mesh("RailwayEmbankment",bankv,bankc,true)
 for z in [-18.8,-19.25]:
  w._box(self,"FarRail",Vector3(0,1.22,z),Vector3(70,0.06,0.035),Color("849298"))
 var train=w._node(self,"EveningTrain",Vector3(7,1.32,-19))
 for carriage in range(3):
  var x=carriage*3.15
  var car=w._box(train,"Carriage",Vector3(x,0.45,0),Vector3(3.0,0.92,0.7),Color("34414e"))
  car.get_child(0).material_override=_material(Color("34414e"),true)
  w._box(train,"RoundedRoof",Vector3(x,0.96,0),Vector3(3.04,0.13,0.76),Color("5b6671"))
  for wheel in [-0.95,0.95]:
   var axle=w._orb(train,"Wheel",Vector3(x+wheel,0.05,0.4),0.16,Color("243640"))
   axle.scale=Vector3(1,1,0.5);var sphere=axle.mesh as SphereMesh;sphere.radial_segments=8;sphere.rings=4
  for j in range(5):
   var window=w._box(train,"WarmWindow",Vector3(x-1.05+j*0.5,0.52,0.365),Vector3(0.32,0.35,0.012),Color("edc385"))
   window.get_child(0).material_override=_material(Color("edc385"),true)
func _trees():
 var texture=load("res://assets/foliage/moonlit_alder_crown.png")
 var quad=QuadMesh.new();quad.size=Vector2(1,1)
 var material=_material(Color("a4b5bc"),true)
 material.albedo_texture=texture
 material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
 material.alpha_scissor_threshold=0.35
 material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.mesh=quad;mm.instance_count=24*3+36
 for i in range(24):
  var x=rng.randf_range(-24,24);var z=rng.randf_range(-26,-12)
  if x>1 and x<16: x+=14
  if i<6: x=(-1 if i%2==0 else 1)*rng.randf_range(9.0,14);z=rng.randf_range(-6,7)
  var height=rng.randf_range(4.5,8.5);var radius=rng.randf_range(1.3,2.3)
  var trunk=w.factory.rounded(self,"AlderTrunk",Vector3(x,height*0.36,z),0.10,0.22,height*0.72,Color("34454b"))
  trunk.rotation.z=rng.randf_range(-0.08,0.08)
  for j in range(3):
   var center=Vector3(x,height-1.3,z)
   var basis=Basis(Vector3.UP,j*PI/3.0+sin(i)*0.22).scaled(Vector3(radius*2.9,radius*2.6,1))
   mm.set_instance_transform(i*3+j,Transform3D(basis,center))
   mm.set_instance_color(i*3+j,Color.WHITE.lerp(Color("747fa0"),clampf((-z-12.0)/42,0,0.35)))
 # Low brush conceals the existing collision perimeter with a natural edge.
 for i in range(36):
  var x=(-6.95 if i<12 else 6.95) if i<24 else -6.6+(i-24)*1.2
  var z=(-5.9+(i%12)*1.04) if i<24 else -6.92
  var height=0.65+rng.randf()*0.32
  var basis=Basis(Vector3.UP,rng.randf()*PI).scaled(Vector3(1.5,height,1))
  mm.set_instance_transform(72+i,Transform3D(basis,Vector3(x,height*0.43,z)))
  mm.set_instance_color(72+i,Color("6d8c8c"))
 var crowns=MultiMeshInstance3D.new();crowns.name="PaintedAlderCanopies";crowns.multimesh=mm;crowns.material_override=material;add_child(crowns)
 w.factory.rounded(self,"ForegroundTrunk",Vector3(-8,3.4,4),0.18,0.5,8,Color("21363a")).rotation.z=-0.12
func _grass():
 var mesh=ArrayMesh.new();var v=PackedVector3Array();var c=PackedColorArray()
 for blade in range(5):
  var a=blade*2.399;var dx=cos(a)*0.18;var dz=sin(a)*0.18
  var tip=Vector3(dx+cos(a)*0.15,0.14+blade*0.021,dz+sin(a)*0.1)
  var middle=Vector3(dx+cos(a)*0.04,0.08,dz)
  _tri(v,c,Vector3(dx-0.032,0,dz),Vector3(dx+0.032,0,dz),middle+Vector3(0.025,0,0),Color("607b69"))
  _tri(v,c,Vector3(dx-0.032,0,dz),middle+Vector3(0.025,0,0),middle-Vector3(0.025,0,0),Color("607b69"))
  _tri(v,c,middle-Vector3(0.025,0,0),middle+Vector3(0.025,0,0),tip,Color("91a58a"))
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in v.size(): st.set_color(c[i]);st.add_vertex(v[i])
 st.generate_normals();mesh=st.commit()
 var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.mesh=mesh;mm.instance_count=1500
 for i in range(mm.instance_count):
  var x=rng.randf_range(-21,21);var z=rng.randf_range(-27,9)
  if absf(x-sin((z+1)*0.31)*0.72)<1.35 and z>-16: x+=signf(x)*1.5
  if Vector2(x+2,z+2.55).length()<1.8 or Vector2(x-2.8,z+2.65).length()<1.0: x+=3.5
  var scale_=rng.randf_range(0.55,1.1)
  mm.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_),Vector3(x,_height(x,z)+0.015,z)))
  mm.set_instance_color(i,Color("89a185").lerp(Color("536e67"),rng.randf()))
 var n=MultiMeshInstance3D.new();n.name="MeadowGrasses";n.multimesh=mm
 var mat=_material(Color.WHITE,true);mat.vertex_color_use_as_albedo=true;n.material_override=mat;add_child(n)
func _stream():
 var bridge=w._node(w.scenery,"NightBridge",Vector3(0,0,-5.2))
 var stream=w._box(bridge,"Stream",Vector3(0,-0.005,0),Vector3(39,0.018,1.7),Color("3a5267"))
 stream.get_child(0).material_override=_material(Color("3a5267"),true)
 for i in range(13): w._box(bridge,"BridgePlank",Vector3(-1.25+i*0.21,0.07,0),Vector3(0.19,0.1,1.8),Color("8d8b73"))
 for i in range(17):
  var x=rng.randf_range(-15,15)
  w._box(bridge,"MoonReflection",Vector3(x,0.021,rng.randf_range(-0.7,0.7)),Vector3(rng.randf_range(0.2,1),0.006,0.025),Color("708b9a"))
func _lamps():
 for pos in [Vector3(-3.3,0,-2.5),Vector3(3.9,0,-3.0)]:
  w.factory.rounded(self,"LanternPost",pos+Vector3(0,0.95,0),0.035,0.06,1.9,Color("584f45"))
  var light_mesh=w._orb(self,"PaperLantern",pos+Vector3(0,1.88,0),0.16,Color("f4cc91"));light_mesh.scale=Vector3(0.8,1.2,0.8)
  var sphere=light_mesh.mesh as SphereMesh;sphere.radial_segments=12;sphere.rings=6
  for y in [1.67,2.09]: w.factory.rounded(self,"LanternCap",pos+Vector3(0,y,0),0.14,0.17,0.07,Color("766550"))
  for angle in range(4):
   var offset=Vector3(cos(angle*PI/2)*0.145,1.88,sin(angle*PI/2)*0.145)
   w.factory.rounded(self,"LanternRib",pos+offset,0.011,0.011,0.37,Color("8d7755"))
  light_mesh.material_override=_material(Color("f4cc91"),true)
  var light=OmniLight3D.new();light.position=pos+Vector3(0,1.75,0);light.light_color=Color("ffd89b");light.light_energy=1.45;light.omni_range=4.3;add_child(light)
func _fireflies():
 var flies=w._node(w.scenery,"FireflyOrbs")
 var sphere_mesh=SphereMesh.new()
 sphere_mesh.radius=1.0;sphere_mesh.height=2.0
 sphere_mesh.radial_segments=8;sphere_mesh.rings=4
 firefly_batch=MultiMesh.new()
 firefly_batch.transform_format=MultiMesh.TRANSFORM_3D
 firefly_batch.mesh=sphere_mesh;firefly_batch.instance_count=58
 var batch_node=MultiMeshInstance3D.new()
 batch_node.name="InstancedFireflies";batch_node.multimesh=firefly_batch
 batch_node.material_override=_material(Color("e7e8a0"),true)
 flies.add_child(batch_node)
 # World owns motion/rest positions as before; only their render submission is batched.
 process_priority=1
 for i in range(58):
  var cluster=[Vector3(-4.2,1.0,-4.1),Vector3(4.8,1.25,-4.9),Vector3(0.5,1.5,-10)][i%3]
  var pos=cluster+Vector3(rng.randf_range(-1.65,1.65),rng.randf_range(-0.5,1.2),rng.randf_range(-1.3,1.3))
  var radius=rng.randf_range(0.018,0.038)
  var fly=w._orb(flies,"Firefly",pos,radius,Color("e7e8a0"))
  var sphere = fly.mesh as SphereMesh
  sphere.radial_segments=8;sphere.rings=4
  fly.material_override=_material(Color("e7e8a0"),true)
  fly.visible=false
  firefly_proxies.append(fly);firefly_radii.append(radius)
  w._decorative.append({"node":fly,"rest":fly.position,"phase":i*0.87})
 _sync_fireflies()
func _sync_fireflies():
 for i in firefly_proxies.size():
  firefly_batch.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*firefly_radii[i]),firefly_proxies[i].position))
func _process(_delta:float):
 # Runs after journey_world, including paused/reduced-motion rest updates.
 _sync_fireflies()
