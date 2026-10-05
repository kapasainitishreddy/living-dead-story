"""Original Platform Six character sculptures, rigs and animation.

Run: blender --background --factory-startup --python tools/author_characters.py
All contours, topology, materials and motion in this file are authored for this
project. No stock body, mesh primitive, downloaded model, texture or font is used.
Blender: metres, Z up, -Y forward. glTF: metres, Y up, +Z forward.
"""
from pathlib import Path
import math, json
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'game/assets/characters'
S = 1.7 / 1.72
TAU = math.tau
CHARACTER_OBJECTS = []
RIG = None

def v3(p): return Vector(p) * S

def material(name, color, rough=.7, metallic=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bs = m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (*color, 1)
    bs.inputs['Roughness'].default_value = rough
    bs.inputs['Metallic'].default_value = metallic
    return m

def mesh(name, verts, faces, mat, bone=None, weights=None, smooth=True):
    me = bpy.data.meshes.new(name + '_Topology')
    me.from_pydata([v3(p) for p in verts], [], faces)
    me.materials.append(mat)
    me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    for poly in me.polygons: poly.use_smooth = smooth
    if bone or weights:
        if weights is None: weights = [{bone: 1.0} for _ in verts]
        for bn in {k for row in weights for k in row}:
            vg = ob.vertex_groups.new(name=bn)
            for i, row in enumerate(weights):
                if row.get(bn, 0) > 0: vg.add([i], row[bn], 'REPLACE')
        mod = ob.modifiers.new('Anatomical skin', 'ARMATURE')
        mod.object = RIG
        ob.parent = RIG
    CHARACTER_OBJECTS.append(ob)
    return ob

def refined_contours(rings, steps=6):
    """Centripetal-looking cubic garment stations with exact original endpoints."""
    result=[]
    for i in range(len(rings)-1):
        p0,p1,p2,p3=[rings[max(0,min(len(rings)-1,k))] for k in [i-1,i,i+1,i+2]]
        for j in range(steps):
            t=j/steps
            row=[]
            for k in range(6):
                if k==0: value=p1[k]*(1-t)+p2[k]*t
                else: value=.5*((2*p1[k])+(-p0[k]+p2[k])*t+(2*p0[k]-5*p1[k]+4*p2[k]-p3[k])*t*t+(-p0[k]+3*p1[k]-3*p2[k]+p3[k])*t*t*t)
                row.append(value)
            result.append(tuple(row))
    return result+[rings[-1]]

def loft(name, rings, mat, weight, n=20, square=.85, cap=True):
    """Authored horizontal garment/head contours; rings=z,x,y,width,front,back."""
    verts = []
    for z,cx,cy,rx,df,db in rings:
        for j in range(n):
            a = TAU*j/n
            sn, cs = math.sin(a), math.cos(a)
            x = cx + rx*math.copysign(abs(sn)**square, sn)
            y = cy - (df if cs >= 0 else db)*math.copysign(abs(cs)**square, cs)
            verts.append((x,y,z))
    faces = []
    for i in range(len(rings)-1):
        for j in range(n):
            faces.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
    if cap:
        faces += [tuple(reversed(range(n))),tuple((len(rings)-1)*n+j for j in range(n))]
    weights = [weight(p) if callable(weight) else {weight:1} for p in verts]
    return mesh(name,verts,faces,mat,weights=weights)

def path_loft(name, points, radii, mat, weight, n=12, cap=True):
    """Sculpted varying cross-sections along a garment/anatomical centreline."""
    verts=[]
    for i,p in enumerate(points):
        tangent=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(i-1,0)])
        tangent.normalize()
        front=Vector((0,-1,0))
        front=(front-tangent*front.dot(tangent)).normalized()
        cross=tangent.cross(front).normalized()
        rw,rd=radii[i]
        for j in range(n):
            a=TAU*j/n
            q=Vector(p)+cross*(rw*math.cos(a))+front*(rd*math.sin(a))
            verts.append(tuple(q))
    faces=[]
    for i in range(len(points)-1):
        for j in range(n): faces.append((i*n+j,(i+1)*n+j,(i+1)*n+(j+1)%n,i*n+(j+1)%n))
    if cap: faces += [tuple(range(n)),tuple(reversed([(len(points)-1)*n+j for j in range(n)]))]
    return mesh(name,verts,faces,mat,weights=[weight(p) if callable(weight) else {weight:1} for p in verts])

def panel(name, front, thickness, mat, bone, bevel=0):
    """Solid cut-and-fold clothing, hair or equipment panel with original outline."""
    # Outline must be planar or near-planar; front/back constitute a solid mesh.
    verts=front+[(x,y+thickness,z) for x,y,z in front]
    n=len(front)
    faces=[tuple(range(n)),tuple(reversed(range(n,2*n)))]
    faces += [(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
    ob=mesh(name,verts,faces,mat,bone=bone,smooth=False)
    if bevel:
        mod=ob.modifiers.new('Soft tailored edge','BEVEL');mod.width=bevel*S;mod.segments=2
        # Evaluated on export; preserves source outline and editability.
    return ob

def ribbon(name, points, widths, mat, bone, depth=.0025):
    # Thin convex ribbon facing -Y. Curves have bespoke endpoints/control stations.
    verts=[]
    for i,p in enumerate(points):
        t=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        t.y=0
        if t.length<.0001:t=Vector((1,0,0))
        side=Vector((-t.z,0,t.x)).normalized()
        q=Vector(p)
        verts.extend([tuple(q-side*widths[i]/2),tuple(q+side*widths[i]/2)])
    faces=[(2*i,2*i+1,2*i+3,2*i+2) for i in range(len(points)-1)]
    return mesh(name,verts,faces,mat,bone=bone)

def ellipse_patch(name, center, rx, rz, mat, bone, n=18, bulge=.002, outline=None):
    cx,cy,cz=center
    verts=[(cx,cy-bulge,cz)]
    for j in range(n):
        a=TAU*j/n
        if outline:
            px,pz=outline[j]
            verts.append((cx+px,cy,cz+pz))
        else: verts.append((cx+rx*math.cos(a),cy,cz+rz*math.sin(a)))
    faces=[(0,j+1,(j+1)%n+1) for j in range(n)]
    return mesh(name,verts,faces,mat,bone=bone)

def torso_weight(p):
    z=p[2]
    if z<.87:return {'Hips':1}
    if z<1.06:
        t=(z-.87)/.19;return {'Hips':1-t,'Spine':t}
    t=min(1,max(0,(z-1.06)/.18));return {'Spine':1-t,'Chest':t}

def limb_weight(p,a,b,joint,bones):
    # Smooth skin through a deliberately shaped elbow or knee band.
    d=Vector(p)-Vector(joint)
    axis=(Vector(b)-Vector(a)).normalized()
    t=max(0,min(1,.5+d.dot(axis)/.085))
    return {bones[0]:1-t,bones[1]:t}

def make_rig(mira=False):
    global RIG
    arm=bpy.data.armatures.new('OriginalCharacterRig')
    RIG=bpy.data.objects.new('Rig',arm);bpy.context.collection.objects.link(RIG)
    CHARACTER_OBJECTS.append(RIG)
    bpy.context.view_layer.objects.active=RIG;RIG.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    specs=[
      ('Root',(0,0,0),(0,0,.15),None),
      ('Hips',(0,0,.79),(0,0,.91),'Root'),
      ('Spine',(0,0,.91),(0,0,1.08),'Hips'),
      ('Chest',(0,0,1.08),(0,0,1.26),'Spine'),
      ('Neck',(0,0,1.26),(0,0,1.365),'Chest'),
      ('Head',(0,0,1.365),(0,0,1.64),'Neck'),
      ('EyeLeft',(.065,-.122,1.505),(.065,-.122,1.535),'Head'),
      ('EyeRight',(-.065,-.122,1.505),(-.065,-.122,1.535),'Head'),
      ('BrowLeft',(.065,-.122,1.562),(.065,-.122,1.59),'Head'),
      ('BrowRight',(-.065,-.122,1.562),(-.065,-.122,1.59),'Head'),
      ('Mouth',(0,-.12,1.42),(0,-.12,1.445),'Head'),
    ]
    for sign,suffix in [(1,'Left'),(-1,'Right')]:
        carry=mira and suffix=='Right'
        elbow_y=-.09 if carry else .003
        wrist_y=-.175 if carry else -.028
        elbow_z=1.028 if carry else 1.015
        wrist_z=.827 if carry else .790
        specs += [
          ('Shoulder'+suffix,(sign*.055,0,1.24),(sign*.195,0,1.245),'Chest'),
          ('UpperArm'+suffix,(sign*.195,0,1.245),(sign*.24,elbow_y,elbow_z),'Shoulder'+suffix),
          ('Forearm'+suffix,(sign*.24,elbow_y,elbow_z),(sign*.26,wrist_y,wrist_z),'UpperArm'+suffix),
          ('Hand'+suffix,(sign*.26,wrist_y,wrist_z),(sign*.265,wrist_y-.004,wrist_z-.1),'Forearm'+suffix),
          ('Thigh'+suffix,(sign*.095,0,.81),(sign*.115,-.008,.46),'Hips'),
          ('Shin'+suffix,(sign*.115,-.008,.46),(sign*.13,.005,.115),'Thigh'+suffix),
          ('Foot'+suffix,(sign*.13,.005,.115),(sign*.13,-.14,.069),'Shin'+suffix)]
    for name,head,tail,parent in specs:
        b=arm.edit_bones.new(name);b.head=v3(head);b.tail=v3(tail)
        if parent:b.parent=arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT');RIG.select_set(False)
    RIG.show_in_front=True
    RIG['character_height_metres']=1.7
    RIG['forward_axis']='Blender -Y; Godot/glTF +Z'
    RIG['walk_reference_velocity_mps']=1.332*S
    RIG['walk_cycle_seconds']=1.0
    RIG['authorship']='Original contours, topology, materials and motion authored for Platform Six'

def head_and_face(m, mira):
    rings=[(1.35,0,-.006,.040,.054,.05),(1.37,0,-.005,.070,.08,.063),
      (1.412,0,-.002,.107,.102,.087),(1.473,0,0,.141,.121,.109),
      (1.533,0,.002,.147,.124,.12),(1.597,0,.004,.136,.119,.119),
      (1.644,0,.004,.109,.093,.09),(1.677,0,.008,.043,.039,.041)]
    rings=refined_contours(rings)
    loft('SculptedFace',rings,m['skin'],'Head',n=64,square=1.03)
    # A tapered nape/jaw connection, hidden inside collar and chin at its ends.
    # Distributed weighting avoids a rigid cylindrical plug under head turns.
    neckrings=[(1.263,0,.009,.064,.046,.053),(1.285,0,.008,.052,.042,.048),
      (1.312,0,.009,.043,.036,.041),(1.34,0,.009,.039,.035,.041),
      (1.365,0,.008,.041,.04,.043),(1.383,0,.007,.042,.041,.044)]
    def neck_weight(p):
        z=p[2]
        if z<1.30:
            t=max(0,min(1,(z-1.263)/.037));return {'Chest':1-t,'Neck':t}
        t=max(0,min(1,(z-1.345)/.038));return {'Neck':1-t,'Head':t}
    loft('SkinNeck',refined_contours(neckrings,4),m['skin'],neck_weight,n=32)
    for sign,suffix in [(1,'Left'),(-1,'Right')]:
        # Ears are shaped cuffs of anatomy rather than stock spheres.
        path_loft('Ear'+suffix,[(sign*.138,.001,1.51),(sign*.157,.002,1.502),
          (sign*.164,.004,1.478),(sign*.158,.005,1.457),(sign*.145,.005,1.452)],
          [(.008,.012),(.017,.016),(.019,.018),(.014,.014),(.006,.009)],m['skin'],'Head',n=12)
        ellipse_patch('EarInner'+suffix,(sign*.159,-.012,1.48),.008,.017,m['blush'],'Head',n=12)
        cx=sign*.065; cy=-.122;cz=1.505;bone='Eye'+suffix
        # Eight-station almond outline. Each component moves with an eye bone.
        shape=[(-.033,0),(-.023,.014),(-.006,.019),(.014,.016),(.031,.001),(.02,-.013),(0,-.016),(-.021,-.011)]
        shape=[(x*1.14,z*1.0) for x,z in shape]
        outline=[]
        for i in range(len(shape)):
            p0,p1,p2,p3=[shape[k%len(shape)] for k in [i-1,i,i+1,i+2]]
            for j in range(6):
                t=j/6
                outline.append(tuple(.5*(2*p1[k]+(-p0[k]+p2[k])*t+(2*p0[k]-5*p1[k]+4*p2[k]-p3[k])*t*t+(-p0[k]+3*p1[k]-3*p2[k]+p3[k])*t*t*t) for k in [0,1]))
        ellipse_patch('FaceEye'+suffix,(cx,cy,cz),0,0,m['ivory'],bone,n=len(outline),outline=outline,bulge=.005)
        ellipse_patch('FaceIris'+suffix,(cx,-.129,cz+.001),.0175,.0165,m['iris'],bone,n=20,bulge=.001)
        ellipse_patch('FacePupil'+suffix,(cx,-.131,cz+.001),.008,.0105,m['ink'],bone,n=16,bulge=.001)
        ellipse_patch('FaceGlint'+suffix,(cx-.004,-.133,cz+.008),.003,.0035,m['ivory'],bone,n=8)
        # The lid shares the *same* curved contour as the white. The former
        # unscaled five-point line cut through the enlarged almond eye.
        upper=outline[:25]
        ribbon('FaceLid'+suffix,[(cx+x,-.127,cz+z) for x,z in upper],
          [.0012+.0025*math.sin(math.pi*i/(len(upper)-1)) for i in range(len(upper))],
          m['hair_dark'],bone)
        arch=1 if mira else -1
        ribbon('FaceBrow'+suffix,[(cx-.034,-.123,1.553),(cx-.018,-.127,1.562+arch*.002),
          (cx+.002,-.128,1.564),(cx+.022,-.123,1.56),(cx+.032,-.119,1.553)],
          [.001,.006,.007,.005,.001],m['hair_dark'],'Brow'+suffix)
        # Subtle cheeks occupy actual face surface, with warm color rather than red spheres.
        ellipse_patch('Cheek'+suffix,(sign*.098,-.105,1.454),.018,.009,m['blush'],'Head',n=16,bulge=.001)
    # Rounded, shallow original nose: a flowing bridge with soft tip, no wedge.
    path_loft('Nose',[(0,-.119,1.495),(0,-.126,1.487),(0,-.136,1.478),
      (0,-.135,1.474),(0,-.129,1.47)],
      [(.0051,.004),(.0068,.006),(.0089,.009),(.00935,.008),(.0051,.004)],
      m['skin'],'Head',n=48)
    # Readable closed neutral smile; mouth bone can animate conversational expression.
    ribbon('FaceMouth',[(-.034,-.109,1.426),(-.021,-.119,1.419),(0,-.122,1.416),
      (.021,-.119,1.419),(.034,-.109,1.426)],[.001,.003,.0035,.003,.001],m['lip'],'Mouth')
    ribbon('LowerLip',[(-.018,-.12,1.41),(0,-.123,1.408),(.018,-.12,1.41)],
      [.001,.002,.001],m['blush'],'Mouth')
    # Embed every face drawing in the sculpted surface. Flat disks would float
    # over the outer cheek when seen three-quarter and produce wall-eyed gaze.
    def surface_y(x,z):
        for a,b in zip(rings,rings[1:]):
            if a[0]<=z<=b[0]:
                t=(z-a[0])/(b[0]-a[0])
                cy=a[2]*(1-t)+b[2]*t;rx=a[3]*(1-t)+b[3]*t;df=a[4]*(1-t)+b[4]*t
                sn=min(.999,abs(x/rx)**(1/1.03))
                return cy-df*(1-sn*sn)**(.5*1.03)
        return -.11
    offsets={'FaceEye':.003,'FaceIris':.005,'FacePupil':.0065,'FaceGlint':.008,
      'FaceLid':.004,'FaceBrow':.003,'Cheek':.0015,'FaceMouth':.0025,'LowerLip':.002}
    for ob in CHARACTER_OBJECTS:
        if ob.type!='MESH':continue
        match=next((o for prefix,o in offsets.items() if ob.name.startswith(prefix)),None)
        if match is None:continue
        for vertex in ob.data.vertices:
            x,y,z=vertex.co/S
            vertex.co.y=(surface_y(x,z)-match)*S

def hair(m,mira):
    # Designed cap with a varying hem: bob at the sides/back, open brow in front.
    n=64;levels=18;verts=[]
    top=1.72
    for i in range(levels):
        u=.055+.945*i/(levels-1)
        radius=math.sin(u*math.pi/2)
        for j in range(n):
            a=TAU*j/n;sn=math.sin(a);cs=math.cos(a)
            front=max(0,cs)
            if mira: edge=1.352+.255*(front**1.5)+.011*sn+.010*math.sin(a*3)*(1-front)
            else: edge=1.432+.182*(front**2)-.012*sn
            z=top-.12*(1-math.cos(u*math.pi/2))-(1.60-edge)*(u**3)
            # Use the actual facial contour as the inner envelope. A spherical
            # cap alone would cut into the temple and expose an accidental bald
            # stripe where its crown radius narrows faster than the head.
            envelope=[(1.35,.040,.054,.05),(1.37,.070,.08,.063),
              (1.412,.107,.102,.087),(1.473,.141,.121,.109),
              (1.533,.147,.124,.12),(1.597,.136,.119,.119),
              (1.644,.109,.093,.09),(1.677,.043,.039,.041)]
            hx,hf,hb=0,0,0
            for a0,a1 in zip(envelope,envelope[1:]):
                if a0[0]<=z<=a1[0]:
                    t=(z-a0[0])/(a1[0]-a0[0])
                    hx,hf,hb=[a0[k]*(1-t)+a1[k]*t for k in [1,2,3]]
                    break
            rx=max(.163*radius,hx+.024 if hx else 0)
            ry=max((.137 if cs>0 else .13)*radius,(hf if cs>0 else hb)+.019 if hx else 0)
            x=rx*sn
            y=.006-ry*cs
            # An off-centre crown ridge and back-plane prevent a generic spherical cap.
            x+=(-.008 if mira else -.015)*math.sin(u*math.pi)
            if not mira:z+=.006*sn*math.sin(u*math.pi)*(u**2)
            verts.append((x,y,z))
    faces=[]
    for i in range(levels-1):
        for j in range(n):faces.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
    crown=len(verts);verts.append((0,.006,1.72))
    faces.extend((crown,(j+1)%n,j) for j in range(n))
    mesh('BobHair' if mira else 'SweptHair',verts,[tuple(reversed(f)) for f in faces],m['hair'],'Head')
    # Solid coiffed locks following bespoke contours, with no primitive additions.
    if mira:
        locks=[
          [(-.139,-.096,1.633),(-.094,-.137,1.629),(-.022,-.144,1.6),(.031,-.142,1.558),(.004,-.14,1.59),(-.074,-.141,1.612),(-.14,-.107,1.604)],
          [(-.146,-.087,1.614),(-.124,-.111,1.594),(-.123,-.12,1.516),(-.131,-.105,1.426),(-.15,-.067,1.379),(-.164,-.051,1.486)],
          [(.12,-.108,1.601),(.144,-.083,1.61),(.16,-.033,1.448),(.142,-.069,1.365),(.128,-.1,1.428),(.126,-.111,1.529)]]
    else:
        locks=[
          [(-.139,-.103,1.639),(-.086,-.141,1.655),(-.019,-.151,1.642),(.047,-.15,1.608),(.1,-.12,1.562),(.058,-.144,1.582),(-.031,-.155,1.613),(-.119,-.126,1.61)],
          [(-.139,-.082,1.624),(-.102,-.124,1.617),(-.072,-.137,1.582),(-.112,-.12,1.551),(-.129,-.092,1.508),(-.154,-.056,1.583)],
          [(.107,-.102,1.647),(.148,-.067,1.621),(.157,-.021,1.528),(.136,-.042,1.478),(.126,-.087,1.547),(.118,-.12,1.589)]]
    # Replace flat outlined locks with continuously curved sculpted sweeps.
    if mira:
        sweep_specs=[
          ([(-.128,-.092,1.653),(-.103,-.132,1.641),(-.055,-.155,1.618),
            (.005,-.156,1.616),(.058,-.144,1.59)],
            [(.022,.013),(.03,.015),(.027,.013),(.018,.009),(.002,.002)]),
          ([(-.14,-.076,1.626),(-.143,-.105,1.588),(-.14,-.119,1.516),
            (-.134,-.088,1.43),(-.153,-.061,1.384)],
            [(.027,.012),(.025,.014),(.018,.012),(.012,.01),(.002,.003)]),
          ([(.135,-.091,1.627),(.15,-.091,1.57),(.154,-.06,1.488),(.15,-.069,1.405)],
            [(.023,.014),(.025,.014),(.015,.012),(.002,.003)])]
    else:
        sweep_specs=[
          ([(-.123,-.095,1.662),(-.083,-.145,1.656),(-.026,-.167,1.637),
            (.033,-.165,1.606),(.075,-.148,1.573),(.1,-.117,1.553)],
            [(.023,.014),(.041,.016),(.034,.015),(.027,.011),(.017,.009),(.002,.002)]),
          ([(-.146,-.077,1.63),(-.126,-.122,1.61),(-.11,-.142,1.586),
            (-.116,-.13,1.551),(-.138,-.088,1.508)],
            [(.02,.012),(.025,.013),(.023,.012),(.016,.01),(.002,.002)]),
          ([(.113,-.092,1.652),(.14,-.101,1.618),(.15,-.077,1.571),(.137,-.071,1.491)],
            [(.023,.013),(.028,.014),(.025,.012),(.002,.002)])]
    for i,(points,radii) in enumerate(sweep_specs):
        stations=[(p[2],p[0],p[1],r[0],r[1],r[1]) for p,r in zip(points,radii)]
        refined=refined_contours(stations,5)
        path_loft('HairFlow%02d'%i,[(r[1],r[2],r[0]) for r in refined],
          [(max(.001,r[3]),max(.001,r[4]*.58)) for r in refined],m['hair'],'Head',n=24)
    # One broad directional fringe accent supports the lock silhouette from
    # gameplay distance. Original control points, not a borrowed hairstyle.
    fringe=[(-.114,-.143,1.647),(-.069,-.167,1.637),(-.025,-.17,1.628),
      (.019,-.169,1.61),(.05,-.15,1.588)] if mira else [
      (-.099,-.158,1.651),(-.056,-.18,1.64),(-.011,-.181,1.621),(.034,-.171,1.597)]
    ribbon('HairFringeAccent',fringe,[.0012]+[.003]*(len(fringe)-2)+[.001],m['hair_light'],'Head')
    # Quiet warm strand highlights add directional rhythm instead of texture noise.
    if mira:
        strands=[([(-.145,-.081,1.602),(-.145,-.103,1.526),(-.147,-.084,1.441),(-.145,-.07,1.397)], [.002,.004,.003,.001]),
          ([(.146,-.08,1.588),(.151,-.083,1.511),(.145,-.084,1.439),(.139,-.075,1.387)],[.002,.003,.003,.001])]
    else:
        strands=[([(-.124,-.123,1.642),(-.064,-.153,1.636),(-.006,-.157,1.615),(.047,-.149,1.588)], [.001,.004,.003,.001]),
          ([(-.132,-.097,1.612),(-.122,-.122,1.587),(-.118,-.118,1.56)], [.001,.003,.001])]
    for i,(points,widths) in enumerate(strands):ribbon('HairAccent%02d'%i,points,widths,m['hair_light'],'Head')

def shoe(name, sign, m, mira):
    cx=sign*.13
    # Footprint is a rounded toe, tapered waist and squared heel, not a box.
    outline=[(-.043,-.184),(-.059,-.157),(-.064,-.107),(-.059,-.019),(-.048,.065),
      (-.033,.081),(.033,.081),(.048,.065),(.059,-.019),(.064,-.107),(.059,-.157),(.043,-.184)]
    rings=[]
    verts=[]
    for z,scale,shift in [(.003,1,0),(.047,1,0),(.06,.95,0),(.116,.85,.016),(.14,.63,.026)]:
        for x,y in outline:
            # Toe top is lower than heel, following a usable footwear last.
            zz=z-(.031 if z>.10 and y<-.11 else 0)
            verts.append((cx+x*scale,y*scale+shift,zz))
    n=len(outline);faces=[]
    for k in range(4):
        for j in range(n):faces.append((k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j))
    faces+=[tuple(reversed(range(n))),tuple(4*n+j for j in range(n))]
    ob=mesh(name,verts,faces,m['shoe'],'Foot'+('Left' if sign>0 else 'Right'))
    # Separate continuous custom sole, with visible ivory foxing.
    soleverts=[(cx+x,y,z) for z in [0,.045] for x,y in outline]
    solefaces=[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
    mesh(name+'Sole',soleverts,solefaces,m['sole'],'Foot'+('Left' if sign>0 else 'Right'))
    if not mira:
        for k in range(3):
            panel(name+'Lace%d'%k,[(cx-.026,-.101+k*.022,.118+k*.006),
              (cx+.026,-.101+k*.022,.118+k*.006),(cx+.025,-.107+k*.022,.117+k*.006),
              (cx-.025,-.107+k*.022,.117+k*.006)],.001,m['ivory'],'Foot'+('Left' if sign>0 else 'Right'))
    else:
        panel(name+'BootVamp',[(cx-.038,-.114,.106),(cx+.038,-.114,.106),
          (cx+.045,-.025,.157),(cx-.045,-.025,.157)],.004,m['shoe'],'Foot'+('Left' if sign>0 else 'Right'))

def limbs(m,mira):
    for sign,suffix in [(1,'Left'),(-1,'Right')]:
        hip=(sign*.095,0,.81);knee=(sign*.115,-.008,.46);ankle=(sign*.13,.005,.115)
        points=[(sign*.092,0,.86),(sign*.099,-.001,.765),(sign*.11,-.007,.63),
          knee,(sign*.124,.012,.333),(sign*.131,.015,.209),ankle]
        radii=[(.075,.067),(.073,.066),(.068,.064),(.061,.063),(.061,.066),(.044,.048),(.038,.039)] if mira else [(.088,.074),(.083,.071),(.071,.066),(.061,.063),(.061,.066),(.044,.048),(.038,.039)]
        path_loft('TailoredTrouser'+suffix,points,radii,m['pants'],
          lambda p:limb_weight(p,hip,ankle,knee,('Thigh'+suffix,'Shin'+suffix)),n=16)
        # A narrow trouser side seam responds to actual knee weighting.
        pts=[(sign*.171,-.005,.74),(sign*.179,-.002,.58),(sign*.177,.003,.43),(sign*.179,.008,.29),(sign*.17,.009,.16)]
        ob=ribbon('TrouserSeam'+suffix,pts,[.0018]*5,m['seam'],'Shin'+suffix)
        # Reweight long seam so it follows both joints cleanly.
        ob.vertex_groups.clear()
        for bn in ['Thigh'+suffix,'Shin'+suffix]:ob.vertex_groups.new(name=bn)
        for i,vert in enumerate(ob.data.vertices):
            w=limb_weight(tuple(vert.co/S),hip,ankle,knee,('Thigh'+suffix,'Shin'+suffix))
            for bn,value in w.items():
                if value:ob.vertex_groups[bn].add([i],value,'REPLACE')
        shoe('Boot'+suffix if mira else 'Sneaker'+suffix,sign,m,mira)
        carry=mira and suffix=='Right'
        elbow_y=-.09 if carry else .003
        wrist_y=-.175 if carry else -.028
        elbow_z=1.028 if carry else 1.015
        wrist_z=.827 if carry else .790
        shoulder=(sign*.195,0,1.245); elbow=(sign*.24,elbow_y,elbow_z); wrist=(sign*.26,wrist_y,wrist_z)
        # Root cap lies fully inside the torso's armhole envelope, including
        # the animated forward/back swing. A closed buried cap avoids an open
        # black gap when the sleeve changes orientation in station lighting.
        sleevepts=[(sign*.164,0,1.218),(sign*.207,.002,1.194),(sign*.232,-.038 if carry else .009,1.126),elbow,
          (sign*.253,-.133 if carry else .001,.969 if carry else .961),(sign*.258,wrist_y+.006,wrist_z+.046),(sign*.26,wrist_y,wrist_z+.010)]
        # Deltoid fullness, a narrower elbow, and a tapered forearm produce a
        # tailored silhouette. Extra longitudinal rings support joint bending.
        radii=[(.046,.046),(.065,.06),(.053,.052),(.044,.046),(.048,.045),(.039,.037),(.036,.034)]
        stations=refined_contours([(p[2],p[0],p[1],r[0],r[1],r[1]) for p,r in zip(sleevepts,radii)],4)
        path_loft('CoatSleeve'+suffix if mira else 'JacketSleeve'+suffix,
          [(r[1],r[2],r[0]) for r in stations],[(r[3],r[4]) for r in stations],m['coat'],
          lambda p:limb_weight(p,shoulder,wrist,elbow,('UpperArm'+suffix,'Forearm'+suffix)),n=24,cap=True)
        path_loft('Cuff'+suffix,[(sign*.258,wrist_y+.002,wrist_z+.035),(sign*.262,wrist_y,wrist_z+.004)],
          [(.04,.038),(.037,.034)],m['cuff'],'Forearm'+suffix,n=24)
        # Designed palm and finger taper, thumb exits from the anatomical inside edge.
        handpts=[(sign*.351,-.018,.819),(sign*.354,-.022,.798),(sign*.359,-.024,.774),
          (sign*.361,-.023,.749)]
        path_loft('SkinHand'+suffix,handpts,[(.023,.021),(.027,.023),(.03,.021),(.027,.017)],m['skin'],'Hand'+suffix,n=16)
        path_loft('SculptedThumb'+suffix,[(sign*.332,-.025,.79),(sign*.32,-.034,.777),
          (sign*.311,-.032,.76),(sign*.312,-.023,.748)],
          [(.012,.012),(.011,.01),(.009,.009),(.004,.005)],m['skin'],'Hand'+suffix,n=12)
        for k,(label,x,length) in enumerate([('Index',.339,.05),('Middle',.353,.055),
          ('Ring',.367,.051),('Little',.38,.04)]):
            path_loft('SculptedFinger'+suffix+label,[(sign*x,-.024,.754),
              (sign*(x+.001),-.027,.742),(sign*(x+.002),-.028,.754-length*.63),
              (sign*(x+.001),-.02,.754-length)],
              [(.0075,.01),(.007,.0085),(.0065,.007),(.0035,.0045)],m['skin'],'Hand'+suffix,n=10)
            ribbon('FingerCrease'+suffix+label,[(sign*(x-.004),-.035,.731),
              (sign*(x+.003),-.035,.731)], [.0007,.0007],m['blush'],'Hand'+suffix)
        for ob in CHARACTER_OBJECTS:
            if not ob.name.startswith(('SkinHand'+suffix,'SculptedThumb'+suffix,
              'SculptedFinger'+suffix,'FingerCrease'+suffix)):continue
            for vertex in ob.data.vertices:
                vertex.co.x-=sign*.09*S
                vertex.co.y-=(.157 if carry else .01)*S
                vertex.co.z+=(wrist_z-.817)*S
                if ob.name.startswith(('SculptedFinger','FingerCrease')):
                    curl=max(0,min(1,(.746+wrist_z-.817-vertex.co.z/S)/.045))
                    vertex.co.y-=.016*S*curl*curl
                    vertex.co.z+=.006*S*curl*curl

def garments(m,mira):
    # Torso silhouettes intentionally differ: cropped jacket and split-hem coat.
    if mira:
        rings=[(.72,0,.011,.203,.1,.11),(.76,0,.01,.2,.106,.115),(.85,0,.009,.175,.111,.116),
          (.96,0,.006,.157,.107,.108),(1.08,0,.004,.166,.106,.11),
          (1.19,0,.003,.19,.102,.105),(1.254,0,.005,.206,.082,.092),
          (1.29,0,.01,.096,.065,.063)]
    else:
        rings=[(.854,0,.008,.157,.105,.109),(.88,0,.008,.164,.109,.113),
          (.97,0,.007,.161,.11,.114),(1.08,0,.005,.174,.11,.112),
          (1.19,0,.004,.199,.107,.107),(1.255,0,.006,.214,.086,.09),
          (1.289,0,.008,.091,.06,.062)]
    loft('TerracottaCoat' if mira else 'MidnightJacket',refined_contours(rings,4),m['coat'],torso_weight,n=48,square=.9)
    if mira:
        panel('TealUnderlayer',[(-.061,-.08,1.282),(.061,-.08,1.282),(.066,-.103,1.239),
          (.038,-.111,1.177),(-.038,-.111,1.177),(-.066,-.103,1.239)],.005,m['shirt'],'Chest',bevel=.003)
        panel('CoatLapelLeft',[(.071,-.085,1.284),(.143,-.097,1.247),(.111,-.119,1.174),
          (.068,-.126,1.105),(.028,-.117,1.165)],.009,m['coat_light'],'Chest',bevel=.004)
        panel('CoatLapelRight',[(-.071,-.085,1.284),(-.148,-.098,1.25),(-.103,-.124,1.145),
          (-.068,-.128,1.096),(-.023,-.119,1.169)],.009,m['coat_light'],'Chest',bevel=.004)
        # Split hem edge and contrasting lining, shaped rather than block add-ons.
        panel('CoatFrontLeft',[(.008,-.123,1.04),(.109,-.116,1.062),(.164,-.11,.85),
          (.196,-.105,.738),(.052,-.118,.724),(.022,-.12,.79)],.004,m['coat_light'],'Spine',bevel=.002)
        panel('CoatFrontRight',[(-.008,-.123,1.04),(-.109,-.116,1.062),(-.164,-.11,.85),
          (-.196,-.105,.738),(-.052,-.118,.724),(-.022,-.12,.79)],.004,m['coat'],'Spine',bevel=.002)
        for sign,suffix in [(1,'Left'),(-1,'Right')]:
            panel('CoatPocket'+suffix,[(sign*.074,-.121,.932),(sign*.151,-.109,.953),
              (sign*.148,-.112,.89),(sign*.091,-.121,.877)],.006,m['coat_shadow'],'Spine',bevel=.003)
            ribbon('PocketWelt'+suffix,[(sign*.074,-.125,.932),(sign*.151,-.113,.953)],
              [.006,.006],m['coat_light'],'Spine')
        for z in [.993,.899,.815]:ellipse_patch('CoatButton%.3f'%z,(-.015,-.13,z),.006,.006,m['brass'],'Spine',n=12)
    else:
        panel('JacketZip',[(-.004,-.12,1.215),(.005,-.12,1.215),(.005,-.118,.878),(-.004,-.118,.878)],.003,m['seam'],'Chest')
        panel('JacketCollarLeft',[(.063,-.075,1.289),(.149,-.097,1.253),(.107,-.118,1.176),(.028,-.121,1.23)],.008,m['coat_light'],'Chest',bevel=.003)
        panel('JacketCollarRight',[(-.063,-.075,1.289),(-.149,-.097,1.253),(-.107,-.118,1.176),(-.028,-.121,1.23)],.008,m['coat_light'],'Chest',bevel=.003)
        for sign,suffix in [(1,'Left'),(-1,'Right')]:
            panel('JacketPocket'+suffix,[(sign*.069,-.119,1.149),(sign*.139,-.11,1.151),
              (sign*.134,-.118,1.082),(sign*.077,-.127,1.079)],.008,m['coat_shadow'],'Chest',bevel=.002)
            ribbon('JacketPocketStitch'+suffix,[(sign*.075,-.131,1.082),(sign*.13,-.122,1.085)],
              [.0017,.0017],m['seam'],'Chest')
            ellipse_patch('PocketSnap'+suffix,(sign*.105,-.127,1.133),.004,.004,m['brass'],'Chest',n=10)
        loft('JacketHem',[(.86,0,.008,.161,.107,.111),(.889,0,.008,.166,.111,.114)],m['cuff'],torso_weight,n=24,square=.65)
        # Cream wrap has an irregular collar ridge and actual sewn drape.
        loft('ScarfWrap',[(1.272,0,-.007,.07,.067,.062),(1.286,0,-.007,.081,.076,.068),
          (1.312,0,-.006,.076,.071,.065),(1.332,0,-.004,.062,.058,.054)],m['scarf'],'Neck',n=24,square=.72)
        panel('ScarfTail',[(-.015,-.096,1.3),(.045,-.101,1.303),(.047,-.13,1.224),
          (.022,-.137,1.12),(-.024,-.13,1.107),(-.032,-.128,1.146),(-.012,-.121,1.232)],
          .011,m['scarf'],'Chest',bevel=.003)
        ribbon('ScarfFold',[(.009,-.144,1.284),(.016,-.143,1.238),(.007,-.146,1.19),(-.007,-.143,1.129)],
          [.002,.004,.003,.001],m['scarf_shadow'],'Chest')
        for x in [-.02,-.011,-.002,.007,.016]:
            ribbon('ScarfFringe%.3f'%x,[(x,-.136,1.112),(x-.002,-.135,1.094)],
              [.002,.001],m['scarf'],'Chest')

    # Tailored collar panels follow the actual coat surface with a gentle rolled
    # edge, instead of floating flat triangles. Radial subdivisions remain fully
    # editable and use the same Hips/Spine/Chest weights as the cloth beneath.
    envelope=refined_contours(rings,4)
    def cloth_y(x,z):
        for aa,bb in zip(envelope,envelope[1:]):
            if aa[0]<=z<=bb[0]:
                t=(z-aa[0])/(bb[0]-aa[0]);cy=aa[2]*(1-t)+bb[2]*t
                rx=aa[3]*(1-t)+bb[3]*t;df=aa[4]*(1-t)+bb[4]*t
                sn=min(.995,abs(x/rx)**(1/.9))
                return cy-df*(1-sn*sn)**.45
        return -.083
    for name in (['CoatLapelLeft','CoatLapelRight','TealUnderlayer'] if mira else ['JacketCollarLeft','JacketCollarRight']):
        old=bpy.data.objects[name]
        count=len(old.data.vertices)//2
        outline=[tuple(v.co/S) for v in list(old.data.vertices)[:count]]
        mat=old.data.materials[0]
        if 'Lapel' in name:
            outline=[(x,y,1.284-(1.284-z)*.82) for x,y,z in outline]
        center=tuple(sum(p[k] for p in outline)/len(outline) for k in range(3))
        verts=[(center[0],cloth_y(center[0],center[2])-.006,center[2])]
        faces=[];n=len(outline);steps=7
        for row in range(1,steps+1):
            u=row/steps
            for x,y,z in outline:
                xx=center[0]+(x-center[0])*u;zz=center[2]+(z-center[2])*u
                yy=cloth_y(xx,zz)-.006-.003*math.sin(math.pi*u)
                verts.append((xx,yy,zz))
        for j in range(n):faces.append((0,1+j,1+(j+1)%n))
        for row in range(steps-1):
            aa=1+row*n;bb=aa+n
            for j in range(n):faces.append((aa+j,bb+j,bb+(j+1)%n,aa+(j+1)%n))
        # Front polygons need normals towards Blender -Y.
        if (Vector(verts[faces[0][1]])-Vector(verts[faces[0][0]])).cross(
          Vector(verts[faces[0][2]])-Vector(verts[faces[0][0]])).y>0:
            faces=[tuple(reversed(f)) for f in faces]
        CHARACTER_OBJECTS.remove(old);bpy.data.objects.remove(old,do_unlink=True)
        mesh(name,verts,faces,mat,weights=[torso_weight(p) for p in verts])

    if mira:
        envelope=refined_contours(rings,4)
        for sign,suffix in [(1,'Left'),(-1,'Right')]:
            old=bpy.data.objects.get('CoatFront'+suffix)
            CHARACTER_OBJECTS.remove(old);bpy.data.objects.remove(old,do_unlink=True)
            verts=[];faces=[];nz=16;nx=12
            for iz in range(nz):
                z=.738+(.99-.738)*iz/(nz-1)
                a,b=next((a,b) for a,b in zip(envelope,envelope[1:]) if a[0]<=z<=b[0])
                t=(z-a[0])/(b[0]-a[0]);rx=a[3]*(1-t)+b[3]*t;cy=a[2]*(1-t)+b[2]*t;df=a[4]*(1-t)+b[4]*t
                for ix in range(nx):
                    x=sign*(.014+(rx*.86-.014)*ix/(nx-1));sn=abs(x/rx)**(1/.9)
                    y=cy-df*(1-sn*sn)**(.45)-.0025
                    verts.append((x,y,z))
            for iz in range(nz-1):
                for ix in range(nx-1):
                    a=iz*nx+ix;faces.append((a,a+1,a+1+nx,a+nx) if sign>0 else (a+nx,a+1+nx,a+1,a))
            mesh('CoatFront'+suffix,verts,faces,m['coat'],weights=[torso_weight(p) for p in verts])
        for sign,suffix in [(1,'Left'),(-1,'Right')]:
            for name in ['CoatPocket'+suffix,'PocketWelt'+suffix]:
                old=bpy.data.objects.get(name);CHARACTER_OBJECTS.remove(old);bpy.data.objects.remove(old,do_unlink=True)
            verts=[];faces=[];nz=8;nx=8
            for iz in range(nz):
                u=iz/(nz-1);z=.887+.056*u
                a,b=next((a,b) for a,b in zip(envelope,envelope[1:]) if a[0]<=z<=b[0])
                t=(z-a[0])/(b[0]-a[0]);rx=a[3]*(1-t)+b[3]*t;cy=a[2]*(1-t)+b[2]*t;df=a[4]*(1-t)+b[4]*t
                width=.030*(.82+.18*math.sin(u*math.pi))
                for ix in range(nx):
                    x=sign*(.092+width*(2*ix/(nx-1)-1));sn=abs(x/rx)**(1/.9)
                    y=cy-df*(1-sn*sn)**(.45)-.0038
                    verts.append((x,y,z))
            for iz in range(nz-1):
                for ix in range(nx-1):
                    a=iz*nx+ix;faces.append((a,a+1,a+1+nx,a+nx) if sign>0 else (a+nx,a+1+nx,a+1,a))
            mesh('CoatPocket'+suffix,verts,faces,m['coat_shadow'],weights=[torso_weight(p) for p in verts])
        for ob in CHARACTER_OBJECTS:
            if not ob.name.startswith(('CoatButton',)):continue
            for vertex in ob.data.vertices:
                x,y,z=vertex.co/S
                for a,b in zip(envelope,envelope[1:]):
                    if a[0]<=z<=b[0]:
                        t=(z-a[0])/(b[0]-a[0]);cx=a[1]*(1-t)+b[1]*t;cy=a[2]*(1-t)+b[2]*t
                        rx=a[3]*(1-t)+b[3]*t;df=a[4]*(1-t)+b[4]*t
                        sn=min(.995,abs((x-cx)/rx)**(1/.9))
                        surface=cy-df*(1-sn*sn)**(.5*.9)
                        vertex.co.y=(surface-.008)*S
                        break
            ob.vertex_groups.clear()
            for bn in ['Hips','Spine','Chest']:ob.vertex_groups.new(name=bn)
            for i,vertex in enumerate(ob.data.vertices):
                for bn,value in torso_weight(tuple(vertex.co/S)).items():
                    if value:ob.vertex_groups[bn].add([i],value,'REPLACE')

def make_materials(mira):
    return {
      'skin': material('Warm sculpted skin',(.59,.32,.22) if mira else (.73,.46,.31),.84),
      'blush':material('Cheek and crease warm rose',(.59,.29,.217) if mira else (.73,.405,.305),.85),
      'lip':material('Soft mouth line',(.25,.105,.079) if mira else (.36,.17,.125),.85),
      'ivory':material('Eye ivory',(.92,.9,.8),.43),
      'iris':material('Teal iris' if mira else 'Amber iris',(.055,.2,.18) if mira else (.24,.125,.048),.36),
      'ink':material('Pupil',(.011,.018,.024),.45),
      'hair':material('Midnight bob' if mira else 'Chestnut swept hair',(.045,.043,.063) if mira else (.235,.087,.04),.73),
      'hair_dark':material('Hair and brow dark',(.027,.024,.039) if mira else (.12,.037,.018),.82),
      'hair_light':material('Hair contour accent',(.115,.092,.121) if mira else (.355,.15,.07),.72),
      'coat':material('Mira terracotta wool' if mira else 'Protagonist midnight blue',(.48,.185,.11) if mira else (.035,.085,.15),.83),
      'coat_light':material('Fold highlight',(.61,.255,.154) if mira else (.067,.14,.223),.82),
      'coat_shadow':material('Pocket cloth',(.355,.115,.068) if mira else (.022,.06,.115),.86),
      'shirt':material('Mira deep teal underlayer',(.035,.225,.218),.77),
      'pants':material('Tailored dark denim',(.035,.062,.078) if mira else (.052,.075,.101),.87),
      'seam':material('Warm subtle seams',(.22,.15,.12) if mira else (.22,.29,.32),.88),
      'cuff':material('Soft cuff fabric',(.285,.103,.068) if mira else (.125,.196,.239),.84),
      'shoe':material('Worn leather boot' if mira else 'Ochre canvas sneaker',(.14,.067,.048) if mira else (.4,.245,.113),.84),
      'sole':material('Rubber sole',(.07,.065,.061) if mira else (.68,.645,.52),.91),
      'brass':material('Small brass fastener',(.49,.315,.116),.42,.65),
      'scarf':material('Cream scarf',(.84,.748,.528),.93),
      'scarf_shadow':material('Cream scarf fold',(.65,.54,.343),.92),
    }

def animate():
    rig=RIG
    rig.animation_data_create()
    for name,length in [('idle',120),('walk',24)]:
        action=bpy.data.actions.new(name)
        action.use_fake_user=True
        rig.animation_data.action=action
        for frame in range(1,length+2,4 if name=='idle' else 2):
            phase=(frame-1)/length*TAU
            for p in rig.pose.bones:
                p.rotation_mode='XYZ';p.rotation_euler=(0,0,0);p.location=(0,0,0);p.scale=(1,1,1)
            if name=='idle':
                rig.pose.bones['Hips'].location.y=.0025*S*math.sin(phase)
                rig.pose.bones['Hips'].rotation_euler.z=.008*math.sin(phase)
                rig.pose.bones['Spine'].rotation_euler.z=-.010*math.sin(phase)
                rig.pose.bones['Chest'].rotation_euler.x=.009*math.sin(phase)
                rig.pose.bones['Chest'].rotation_euler.y=.014*math.sin(phase+.6)
                rig.pose.bones['Head'].rotation_euler.z=.007*math.sin(phase*.999)
                for sign,suffix in [(1,'Left'),(-1,'Right')]:
                    rig.pose.bones['UpperArm'+suffix].rotation_euler.x=sign*.011*math.sin(phase+.4)
                    rig.pose.bones['Shoulder'+suffix].rotation_euler.z=sign*.006*math.sin(phase+.4)
                    rig.pose.bones['Forearm'+suffix].rotation_euler.x=-.085+.016*math.sin(phase+sign*.7)
                    rig.pose.bones['Hand'+suffix].rotation_euler.x=.03+.01*math.sin(phase+sign*.4)
            else:
                # Grounded one-second walk. During stance the foot travels in
                # a linear 0.666 m track over 0.5 seconds; reference 1.332 m/s.
                # Hip lowering cancels leg shortening so the stance ankle stays
                # at its rest floor height. Recovery knee bends only in swing.
                stance_phase=phase % math.pi
                stance_theta=math.asin((-.333+.666*stance_phase/math.pi)/.695)
                rig.pose.bones['Hips'].location.y=-.695*S*(1-math.cos(stance_theta))
                rig.pose.bones['Chest'].rotation_euler.y=-.035*math.sin(phase)
                for sign,suffix in [(1,'Left'),(-1,'Right')]:
                    p=(phase+(0 if sign==1 else math.pi)) % TAU
                    if p<=math.pi:
                        thigh=math.asin((-.333+.666*p/math.pi)/.695);knee=0
                    else:
                        thigh=.5*math.cos(p-math.pi);knee=.78*math.sin(p-math.pi)
                    rig.pose.bones['Thigh'+suffix].rotation_euler.x=thigh
                    rig.pose.bones['Shin'+suffix].rotation_euler.x=knee
                    rig.pose.bones['Foot'+suffix].rotation_euler.x=-thigh-knee
                    rig.pose.bones['UpperArm'+suffix].rotation_euler.x=-.72*thigh
                    rig.pose.bones['Forearm'+suffix].rotation_euler.x=-.10-.04*math.sin(p)
            for p in rig.pose.bones:
                if p.name in ('Root','EyeLeft','EyeRight','BrowLeft','BrowRight','Mouth'):continue
                p.keyframe_insert(data_path='rotation_euler',frame=frame,group=p.name)
                if p.name=='Hips':p.keyframe_insert(data_path='location',frame=frame,group=p.name)
        # Explicit endpoint closes the seamless loop, including a 32-frame walk.
        for p in rig.pose.bones:
            p.rotation_euler=(0,0,0);p.location=(0,0,0)
        for fc in action.fcurves:
            if fc.keyframe_points:
                value=fc.evaluate(1)
                fc.keyframe_points.insert(length+1,value,options={'FAST'})
                for kp in fc.keyframe_points:kp.interpolation='BEZIER'
        rig.animation_data.action=None
        track=rig.animation_data.nla_tracks.new();track.name=name
        strip=track.strips.new(name,0,action);strip.name=name
        strip.action_frame_start=1;strip.action_frame_end=length+1
        strip.blend_type='REPLACE';strip.extrapolation='NOTHING'
        track.mute=True
    for p in rig.pose.bones:
        p.rotation_euler=(0,0,0);p.location=(0,0,0);p.scale=(1,1,1)

def camera_and_lights():
    scene=bpy.context.scene
    # CPU path tracer is predictable on the cloud's headless software renderer.
    scene.render.engine='CYCLES'
    scene.cycles.samples=40
    # This Blender build omits OpenImageDenoise; unsupported denoising aborts
    # image writing. Explicitly disabled, using a clean 40-sample CPU render.
    scene.cycles.use_denoising=False
    scene.render.threads_mode='FIXED';scene.render.threads=4
    scene.render.resolution_x=720;scene.render.resolution_y=880
    scene.render.resolution_percentage=100
    scene.world.color=(.13,.13,.13)
    world=scene.world;world.use_nodes=True
    world.node_tree.nodes['Background'].inputs['Color'].default_value=(.115,.14,.19,1)
    world.node_tree.nodes['Background'].inputs['Strength'].default_value=.4
    scene.view_settings.view_transform='AgX'
    scene.render.image_settings.file_format='PNG'
    # Authored stage outline; not included in the character export.
    ground=material('Studio ground',(.115,.15,.19),.95)
    mesh('RenderGround',[(-200,-200,-.006),(200,-200,-.006),(200,200,-.006),(-200,200,-.006)],[(0,1,2,3)],ground)
    def area(name,loc,power,size,color):
        data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;data.color=color
        ob=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(ob);ob.location=loc
        ob.rotation_euler=(Vector((0,0,.9))-ob.location).to_track_quat('-Z','Y').to_euler()
    area('Warm key',(-3,-4,5),400,4,(1,.83,.69))
    area('Cool fill',(3,-2,2.8),220,3,(.67,.79,1))
    area('Rim',(.4,3,4),450,3,(1,.74,.47))
    data=bpy.data.cameras.new('PortraitCamera');cam=bpy.data.objects.new('PortraitCamera',data)
    bpy.context.collection.objects.link(cam);scene.camera=cam
    cam.data.type='ORTHO';cam.data.ortho_scale=1.96
    return cam

def aim(cam,pos,target=(0,0,.855)):
    cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()

def export_selected(path,animated=True):
    bpy.ops.object.select_all(action='DESELECT')
    for ob in CHARACTER_OBJECTS:
        if ob.name=='RenderGround':continue
        ob.select_set(True)
    if RIG:bpy.context.view_layer.objects.active=RIG
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
      export_yup=True,export_animations=animated,export_animation_mode='NLA_TRACKS',
      export_nla_strips=True,export_apply=False,export_texcoords=False,
      export_normals=True,export_materials='EXPORT',export_cameras=False,export_lights=False,
      export_skins=True,export_all_influences=False,export_def_bones=True)

def build_character(slug):
    global CHARACTER_OBJECTS,RIG
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    CHARACTER_OBJECTS=[];RIG=None
    mira=slug=='mira';out=DEST/slug;out.mkdir(parents=True,exist_ok=True)
    source=out/'source';source.mkdir(exist_ok=True);(source/'.gdignore').write_text('')
    m=make_materials(mira);make_rig(mira);garments(m,mira);limbs(m,mira);head_and_face(m,mira);hair(m,mira);animate()
    # Only source modeling assets and rig are selected for glTF export.
    export_selected(out/(slug+'.glb'))
    cam=camera_and_lights();bpy.context.scene.frame_set(1)
    # The glTF exporter samples the final NLA strip and leaves that pose in
    # Blender even after restoring mute flags. Explicitly reset the editable
    # source to the intended neutral A pose; exported animation is unchanged.
    for p in RIG.pose.bones:
        p.location=(0,0,0);p.rotation_euler=(0,0,0);p.scale=(1,1,1)
    bpy.context.view_layer.update()
    aim(cam,(2.5,-5,2.6))
    # Save editable source before expensive rendering; portraits can be rebuilt.
    bpy.ops.wm.save_as_mainfile(filepath=str(source/(slug+'.blend')))
    if '--no-render' in __import__('sys').argv:
        return
    # Mute NLA preview tracks so rest posture is the source portrait.
    aim(cam,(2.5,-5,2.6))
    bpy.context.scene.render.filepath=str(out/(slug+'_portrait.png'));bpy.ops.render.render(write_still=True)
    aim(cam,(0,-5,1.75));bpy.context.scene.render.filepath=str(out/(slug+'_front.png'));bpy.ops.render.render(write_still=True)
    aim(cam,(2.5,5,2.1));bpy.context.scene.render.filepath=str(out/(slug+'_back.png'));bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(source/(slug+'.blend')))
    mesh_objects=[ob for ob in CHARACTER_OBJECTS if ob.type=='MESH' and ob.name!='RenderGround']
    print('CHARACTER_COMPLETE',json.dumps({'name':slug,'path':str(out/(slug+'.glb')),
      'mesh_objects':len(mesh_objects),'vertices':sum(len(o.data.vertices) for o in mesh_objects),
      'polygons':sum(len(o.data.polygons) for o in mesh_objects),'bones':list(RIG.data.bones.keys()),
      'animations':['idle','walk']}))

def build_camera():
    global CHARACTER_OBJECTS,RIG,S
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    CHARACTER_OBJECTS=[];RIG=None;S=1.0
    out=DEST/'mira';source=out/'source'
    cream=material('Camera warm cream polymer',(.69,.647,.495),.72)
    teal=material('Camera teal leatherette',(.035,.19,.18),.86)
    dark=material('Camera charcoal bezel',(.026,.036,.043),.46)
    glass=material('Camera blue optical glass',(.025,.115,.16),.16,.3)
    metal=material('Camera metal trim',(.41,.42,.38),.36,.75)
    flash=material('Flash diffuser',(.87,.875,.76),.32)
    # Grip-centred origin on the right side; body width .15 m.
    cx=.042
    outline=[(-.071,-.037),(-.062,-.044),(.06,-.044),(.076,-.027),(.077,.028),
      (.067,.043),(-.061,.043),(-.074,.03)] # x,z custom chamfered casing
    verts=[(x+cx,y,z) for y in [-.027,.025] for x,z in outline]
    n=len(outline);faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
    ob=mesh('CameraShell',verts,faces,cream,smooth=False)
    bevel=ob.modifiers.new('Moulded casing radius','BEVEL');bevel.width=.006;bevel.segments=3
    panel('CameraLeatherGrip',[(-.02,-.034,-.033),(.019,-.034,-.033),(.019,-.034,.032),(-.02,-.034,.032)],.004,teal,None,bevel=.004)
    panel('CameraFaceInset',[(.024,-.033,-.033),(.108,-.033,-.033),(.111,-.033,.031),(.024,-.033,.031)],.003,teal,None,bevel=.003)
    # Lens is an authored revolved machined profile with tapered shoulder/ridge.
    lc=.066;profile=[(-.034,.025),(-.04,.028),(-.045,.028),(-.049,.024),(-.056,.024),(-.059,.02)]
    verts=[]
    for y,r in profile:
        for j in range(32):
            a=TAU*j/32;verts.append((lc+r*math.cos(a),y,-.006+r*math.sin(a)))
    faces=[]
    for k in range(len(profile)-1):
        for j in range(32):faces.append((k*32+j,k*32+(j+1)%32,(k+1)*32+(j+1)%32,(k+1)*32+j))
    mesh('CameraLensHousing',verts,faces,dark)
    ellipse_patch('CameraLensGlass',(lc,-.0598,-.006),.018,.018,glass,None,n=32,bulge=-.001)
    ellipse_patch('CameraLensReflection',(lc-.006,-.0605,.001),.004,.002,flash,None,n=12)
    panel('CameraFlash',[(.018,-.036,.022),(.048,-.036,.022),(.048,-.036,.034),(.018,-.036,.034)],.001,flash,None,bevel=.001)
    panel('CameraViewfinder',[(.088,-.035,.021),(.105,-.035,.021),(.105,-.035,.033),(.088,-.035,.033)],.001,dark,None,bevel=.001)
    panel('CameraFinderGlass',[(.091,-.037,.024),(.102,-.037,.024),(.102,-.037,.03),(.091,-.037,.03)],.001,glass,None)
    # Top shutter is a shaped bevel panel rather than a floating sphere.
    ob=mesh('CameraShutter',[(-.012,-.01,.043),(.014,-.01,.043),(.016,.008,.043),(-.014,.008,.043),
      (-.012,-.01,.048),(.014,-.01,.048),(.016,.008,.048),(-.014,.008,.048)],
      [(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)],metal,smooth=False)
    bevel=ob.modifiers.new('Shutter radius','BEVEL');bevel.width=.003;bevel.segments=2
    panel('CameraBackDisplay',[(.017,.03,-.025),(.1,.03,-.025),(.1,.03,.026),(.017,.03,.026)],-.002,dark,None,bevel=.002)
    export_selected(out/'camera.glb',animated=False)
    cam=camera_and_lights();cam.data.ortho_scale=.23;aim(cam,(.28,-.4,.24),(.045,0,0))
    bpy.context.scene.render.resolution_x=1000;bpy.context.scene.render.resolution_y=760
    bpy.ops.wm.save_as_mainfile(filepath=str(source/'camera.blend'))
    if '--no-render' not in __import__('sys').argv:
        bpy.context.scene.render.filepath=str(out/'camera_portrait.png');bpy.ops.render.render(write_still=True)
    print('CAMERA_COMPLETE',out/'camera.glb')

if __name__=='__main__':
    for slug in ['protagonist','mira']:build_character(slug)
    build_camera()
