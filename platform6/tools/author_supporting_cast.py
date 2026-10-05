"""Original STILL HERE supporting cast; extends project-authored contour tools.

Run: blender --background --factory-startup --threads 2 --python tools/author_supporting_cast.py -- --no-render
Optional: --only ada (one export); omit --no-render for portrait evidence.
No third-party assets, downloaded meshes, paid assets, textures or stock bodies.
Hero/Mira files and the original author_characters.py are never modified.
"""
from pathlib import Path
import sys, math, json, importlib.util
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('original_character_contours',ROOT/'tools/author_characters.py')
a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)
DEST=a.DEST
CAST={
 'ada': dict(skin=(.69,.45,.31),hair=(.36,.35,.31),hair_light=(.58,.56,.49),
   coat=(.42,.255,.17),coat_light=(.58,.37,.25),pants=(.095,.115,.105),apron=(.62,.54,.36),
   iris=(.24,.16,.077),face=(1.035,.975,.982),hair_style='bun',garment='apron',
   changes=['Broader softened jaw and lowered cheek silhouette','Swept gray crown with a low asymmetric sculpted bun','Wide curved linen work apron, separate bib, straps and worn pocket','Eye creases and restrained silver hair flow'],
   role='Ada, the fair and kitchen caretaker'),
 'noor': dict(skin=(.49,.285,.18),hair=(.045,.062,.058),hair_light=(.115,.16,.125),
   coat=(.23,.34,.27),coat_light=(.34,.46,.365),pants=(.055,.095,.102),apron=(.48,.505,.355),
   iris=(.115,.23,.185),face=(.965,1.012,1.035),hair_style='bob',garment='apron',
   changes=['Narrower chin, taller face and fuller nose plane','Tucked side-parted bob with individually swept locks','Curved rounded-square glasses, bridge and temple arms','Practical shorter apron with utensil pocket and offset ties'],
   role='Noor, the paper/kitchen artist'),
 'rafi': dict(skin=(.58,.315,.18),hair=(.067,.041,.029),hair_light=(.155,.092,.045),
   coat=(.18,.29,.355),coat_light=(.285,.42,.47),pants=(.14,.145,.13),apron=(.4,.38,.26),
   iris=(.24,.145,.06),face=(1.07,1.025,.975),hair_style='crop',garment='work',
   changes=['Wider angular jaw and broader nose contour','Cropped uneven hair with five authored tousled clumps','Shaped work overshirt and two chest patch pockets','Shortened rolled sleeves with skinned exposed forearms'],
   role='Rafi, the workshop worker; generic Journey workers'),
 'conductor': dict(skin=(.65,.435,.29),hair=(.22,.24,.225),hair_light=(.47,.49,.43),
   coat=(.14,.235,.20),coat_light=(.245,.36,.29),pants=(.055,.09,.078),apron=(.38,.35,.23),
   iris=(.19,.22,.105),face=(1.045,1.035,1.005),hair_style='uniform',garment='uniform',
   changes=['Longer square lower face and quiet age creases','Neat salt-and-pepper hair and separate sculpted moustache','Original tailored conductor cap with curved visor and band','Long green uniform coat, broad lapels and brass closure'],
   role='The conductor at the return platform'),
 'jo': dict(skin=(.365,.19,.105),hair=(.024,.026,.03),hair_light=(.065,.078,.078),
   coat=(.55,.415,.255),coat_light=(.68,.535,.35),pants=(.075,.105,.135),apron=(.44,.36,.24),
   iris=(.135,.085,.04),face=(.945,.995,1.012),hair_style='coils',garment='station',
   changes=['Small tapered jaw, fuller cheek plane and wider soft nose','Short coiled crown with original interlocking raised curl paths','Fitted station waistcoat over cream work shirt','Brass station badge, inset front panels and tailored back silhouette'],
   role='Jo at the station; generic Journey keepers'),
}

BASE_FACE=[(1.35,0,-.006,.040,.054,.05),(1.37,0,-.005,.070,.08,.063),
 (1.412,0,-.002,.107,.102,.087),(1.473,0,0,.141,.121,.109),
 (1.533,0,.002,.147,.124,.12),(1.597,0,.004,.136,.119,.119),
 (1.644,0,.004,.109,.093,.09),(1.677,0,.008,.043,.039,.041)]

def surface_y(x,z):
    rings=a.refined_contours(BASE_FACE)
    for p,q in zip(rings,rings[1:]):
        if p[0]<=z<=q[0]:
            t=(z-p[0])/(q[0]-p[0]);cy=p[2]*(1-t)+q[2]*t
            rx=p[3]*(1-t)+q[3]*t;df=p[4]*(1-t)+q[4]*t
            sn=min(.995,abs(x/rx)**(1/1.03))
            return cy-df*(1-sn*sn)**(.5*1.03)
    return -.105

def set_color(mat,color):
    mat.diffuse_color=(*color,1)
    mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*color,1)

def cast_materials(slug,cfg):
    m=a.make_materials(False)
    for key in ['skin','hair','hair_light','coat','coat_light','pants','iris']:
        set_color(m[key],cfg[key])
    set_color(m['blush'],tuple(x*.85 for x in cfg['skin']))
    set_color(m['lip'],tuple(x*.45 for x in cfg['skin']))
    set_color(m['hair_dark'],tuple(x*.52 for x in cfg['hair']))
    set_color(m['coat_shadow'],tuple(x*.76 for x in cfg['coat']))
    set_color(m['cuff'],tuple(x*.85 for x in cfg['coat']))
    set_color(m['scarf'],(.84,.77,.60));set_color(m['sole'],(.135,.13,.105))
    set_color(m['shoe'],(.20,.13,.085));set_color(m['shirt'],(.75,.69,.52))
    set_color(m['seam'],tuple(x*1.12 for x in cfg['coat']))
    m['apron']=a.material(slug+' warm woven apron',cfg['apron'],.93)
    m['apron_shadow']=a.material(slug+' apron pocket and stitching',tuple(x*.81 for x in cfg['apron']),.95)
    m['frame']=a.material(slug+' brushed eyeglass metal',(.34,.32,.25),.57,.38)
    for key,mat in m.items():mat.name=slug+'_'+key
    return m

def tube(name,points,radius,mat,bone,closed=False,n=8):
    """Small authored strand/frame swept along any 3D path, with stable basis."""
    verts=[]
    for i,p in enumerate(points):
        tangent=(Vector(points[(i+1)%len(points)])-Vector(points[(i-1)%len(points)])) if closed else \
          Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        tangent.normalize();guide=Vector((0,-1,0))
        if abs(tangent.dot(guide))>.95:guide=Vector((0,0,1))
        front=(guide-tangent*guide.dot(tangent)).normalized();side=tangent.cross(front).normalized()
        r=radius[i] if isinstance(radius,list) else radius
        for j in range(n):
            ang=math.tau*j/n;verts.append(tuple(Vector(p)+r*(front*math.cos(ang)+side*math.sin(ang))))
    faces=[]
    for i in range(len(points) if closed else len(points)-1):
        k=(i+1)%len(points)
        for j in range(n):faces.append((i*n+(j+1)%n,k*n+(j+1)%n,k*n+j,i*n+j))
    if not closed:faces += [tuple(reversed(range(n))),tuple((len(points)-1)*n+j for j in range(n))]
    if callable(bone):return a.mesh(name,verts,faces,mat,weights=[bone(p) for p in verts])
    return a.mesh(name,verts,faces,mat,bone=bone)

def face_details(slug,m):
    if slug in ['ada','conductor']:
        for sign,side in [(1,'Left'),(-1,'Right')]:
            points=[(sign*x,surface_y(sign*x,z)-.0016,z) for x,z in [(.095,1.49),(.114,1.484),(.129,1.477)]]
            a.ribbon('AgeCrease'+side,points,[.0005,.0012,.0003],m['blush'],'Head')
            points=[(sign*x,surface_y(sign*x,z)-.0012,z) for x,z in [(.092,1.494),(.111,1.491),(.123,1.489)]]
            a.ribbon('SmileCrease'+side,points,[.0005,.0009,.0003],m['blush'],'Head')
    if slug=='noor':
        for sign,side in [(1,'Left'),(-1,'Right')]:
            points=[]
            for j in range(40):
                ang=math.tau*j/40;cs,sn=math.cos(ang),math.sin(ang)
                x=sign*.065+.044*math.copysign(abs(cs)**.83,cs)
                z=1.505+.026*math.copysign(abs(sn)**.8,sn)
                points.append((x,surface_y(x,z)-.013,z))
            tube('GlassesFrame'+side,points,.0025,m['frame'],'Head',closed=True)
            tube('GlassesTemple'+side,[(sign*.109,-.089,1.51),(sign*.153,-.043,1.51),
              (sign*.161,.005,1.51),(sign*.152,.025,1.495)],.0025,m['frame'],'Head')
        tube('GlassesBridge',[(-.023,-.133,1.512),(-.012,-.141,1.518),(0,-.144,1.52),
          (.012,-.141,1.518),(.023,-.133,1.512)],.0024,m['frame'],'Head')
    if slug=='conductor':
        for sign,side in [(1,'Left'),(-1,'Right')]:
            points=[(sign*.003,-.134,1.456),(sign*.015,-.137,1.451),
              (sign*.028,-.13,1.447),(sign*.044,-.116,1.45)]
            a.path_loft('Moustache'+side,points,[(.005,.004),(.008,.005),(.007,.004),(.001,.001)],m['hair'],'Head',n=16)

def reshape_face(start,cfg,slug):
    sx,sz,sy=cfg['face']
    for ob in a.CHARACTER_OBJECTS[start:]:
        if ob.type!='MESH' or ob.name=='SkinNeck':continue
        for v in ob.data.vertices:
            x,y,z=v.co/a.S
            jaw=max(0,min(1,(1.49-z)/.11))
            jawfactor=1.045 if slug in ['rafi','conductor'] else (.96 if slug in ['noor','jo'] else 1.04)
            x*=sx*(1+(jawfactor-1)*jaw)
            z=1.51+(z-1.51)*sz
            y*=sy
            if ob.name=='Nose' and slug in ['rafi','jo']:x*=1.14;y-=.0015
            v.co=(x*a.S,y*a.S,z*a.S)

def smooth_sweep(name,points,radii,mat,bone='Head'):
    rows=a.refined_contours([(p[2],p[0],p[1],r[0],r[1],r[1]) for p,r in zip(points,radii)],4)
    return a.path_loft(name,[(r[1],r[2],r[0]) for r in rows],
      [(max(.001,r[3]),max(.001,r[4])) for r in rows],mat,bone,n=16)

def hair_shell(name,cfg,m,style):
    sx,sz,sy=cfg['face'];n=56;levels=15;verts=[]
    for i in range(levels):
        u=.055+.945*i/(levels-1);r=math.sin(u*math.pi/2)
        for j in range(n):
            ang=math.tau*j/n;sn,cs=math.sin(ang),math.cos(ang);f=max(0,cs)
            if style=='bun':edge=1.522+.111*f**2+.008*sn
            elif style=='bob':edge=1.38+.247*f**2+.018*sn+.008*math.sin(ang*3)*(1-f)
            elif style=='crop':edge=1.54+.088*f**2+.009*math.sin(ang*4)
            elif style=='uniform':edge=1.52+.12*f**2-.004*sn
            else:edge=1.518+.093*f**2+.009*math.sin(ang*5)
            z=1.72-.12*(1-math.cos(u*math.pi/2))-(1.60-edge)*u**3
            hx,hf,hb=0,0,0
            nativez=1.51+(z-1.51)/sz
            for p,q in zip(BASE_FACE,BASE_FACE[1:]):
                if p[0]<=nativez<=q[0]:
                    t=(nativez-p[0])/(q[0]-p[0]);hx,hf,hb=[p[k]*(1-t)+q[k]*t for k in [3,4,5]];break
            rx=max(.166*sx*r,hx*sx+.017 if hx else 0)
            ry=max(.139*sy*r,(hf if cs>0 else hb)*sy+.015 if hx else 0)
            x=rx*sn-.007*math.sin(u*math.pi)
            y=.008-ry*cs
            if style=='coils':x+=.003*math.sin(j*2.43)*u*r;y+=.003*math.cos(j*2.43)*u*r
            verts.append((x,y,z))
    faces=[]
    for i in range(levels-1):
        for j in range(n):faces.append((i*n+j,(i+1)*n+j,(i+1)*n+(j+1)%n,i*n+(j+1)%n))
    crown=len(verts);verts.append((-.003,.008,1.72));faces += [(crown,j,(j+1)%n) for j in range(n)]
    a.mesh(name,verts,faces,m['hair'],bone='Head')

def cast_hair(slug,cfg,m):
    style=cfg['hair_style']
    names={'bun':'SweptBunHair','bob':'TuckedBobHair','crop':'CroppedWorkHair','uniform':'NeatUniformHair','coils':'CoiledStationHair'}
    hair_shell(names[style],cfg,m,style)
    if style=='bun':
        rings=[(1.515,-.009,.129,.036,.032,.044),(1.546,-.012,.143,.070,.056,.071),
          (1.589,-.015,.15,.082,.063,.085),(1.633,-.014,.144,.072,.052,.075),
          (1.665,-.011,.133,.034,.029,.037)]
        a.loft('LowWorkBun',a.refined_contours(rings,3),m['hair'],'Head',n=36,square=1.08)
        for j in range(4):
            x=-.12+j*.061
            points=[(x,-.092,1.65),(x*.9,-.121,1.633),(x*.76,-.137,1.617),(x*.63,-.134,1.604)]
            smooth_sweep('AdaSweptLock%02d'%j,points,[(.018,.008),(.02,.009),(.017,.008),(.002,.002)],m['hair'])
            a.ribbon('AdaSilverFlow%02d'%j,[(xx,yy-.009,zz+.002) for xx,yy,zz in points],[.001,.002,.002,.0005],m['hair_light'],'Head')
        for j in range(3):
            points=[(-.063+j*.06,.209,1.55),(-.069+j*.064,.231,1.585),(-.05+j*.05,.21,1.63)]
            tube('BunWovenFlow%02d'%j,points,[.001,.002,.001],m['hair_light'],'Head')
    elif style=='bob':
        smooth_sweep('NoorPartedFringe',[(-.125,-.103,1.659),(-.084,-.149,1.645),
          (-.025,-.156,1.625),(.042,-.137,1.603),(.103,-.105,1.584)],
          [(.022,.009),(.032,.011),(.028,.009),(.018,.006),(.002,.002)],m['hair'])
        for sign,side in [(1,'Left'),(-1,'Right')]:
            smooth_sweep('NoorTuckedLock'+side,[(sign*.131,-.08,1.625),(sign*.154,-.054,1.57),
              (sign*.162,.005,1.5),(sign*.147,.027,1.414),(sign*.12,.032,1.393)],
              [(.02,.009),(.028,.01),(.023,.009),(.013,.008),(.003,.002)],m['hair'])
            tube('NoorBobAccent'+side,[(sign*.154,-.041,1.567),(sign*.167,-.012,1.499),
              (sign*.153,.009,1.441)],[.001,.002,.0007],m['hair_light'],'Head')
    elif style=='crop':
        specs=[(-.128,-.093,1.666,-.073,-.125,1.628),(-.077,-.143,1.682,-.031,-.146,1.633),
          (-.018,-.155,1.684,.031,-.148,1.612),(.04,-.139,1.67,.087,-.118,1.602),(.105,-.094,1.649,.148,-.064,1.58)]
        for i,(x,y,z,xx,yy,zz) in enumerate(specs):
            smooth_sweep('RafiTousledClump%02d'%i,[(x,y,z),((x+xx)/2,y-.008,z-.025),(xx,yy,zz)],
              [(.025,.01),(.031,.012),(.002,.002)],m['hair'])
    elif style=='uniform':
        for sign,side in [(1,'Left'),(-1,'Right')]:
            smooth_sweep('UniformSideburn'+side,[(sign*.14,-.054,1.61),(sign*.149,-.061,1.557),
              (sign*.143,-.05,1.522)],[ (.016,.006),(.012,.007),(.001,.001)],m['hair'])
            tube('UniformSilverTemple'+side,[(sign*.145,-.066,1.608),(sign*.152,-.07,1.566),
              (sign*.148,-.056,1.539)],[.001,.0018,.0004],m['hair_light'],'Head')
        cap(m)
    else:
        # Coils follow the visible crown, each lifted path shaped independently.
        for i in range(13):
            angle=-1.42+2.84*i/12;cx=.14*math.sin(angle);cy=-.115*math.cos(angle)
            cz=1.632+.026*math.cos(angle);points=[]
            for j in range(13):
                ang=-.3+math.pi*1.8*j/12
                points.append((cx+.020*math.cos(ang),cy-.009*math.sin(ang),cz+.021*math.sin(ang)))
            tube('JoCoil%02d'%i,points,[.0065]*len(points),m['hair'],'Head',n=8)
            if i%3==0:tube('JoCoilAccent%02d'%i,points[2:8],[.0014]*6,m['hair_light'],'Head',n=6)

def torso(name,rings,mat):
    a.loft(name,a.refined_contours(rings,4),mat,a.torso_weight,n=44,square=.93)
    return a.refined_contours(rings,4)

def cloth_surface(rings,x,z):
    for p,q in zip(rings,rings[1:]):
        if p[0]<=z<=q[0]:
            t=(z-p[0])/(q[0]-p[0]);rx=p[3]*(1-t)+q[3]*t;cy=p[2]*(1-t)+q[2]*t;df=p[4]*(1-t)+q[4]*t
            sn=min(.999,abs(x/rx)**(1/.93));return cy-df*(1-sn*sn)**(.5*.93)
    return -.08

def cloth_patch(name,outline,rings,mat,offset=.006):
    """Subdivided solid-looking tailored panel following the torso envelope."""
    center=tuple(sum(p[k] for p in outline)/len(outline) for k in range(2));verts=[]
    verts.append((center[0],cloth_surface(rings,center[0],center[1])-offset,center[1]))
    steps=7;n=len(outline)
    for row in range(1,steps+1):
        u=row/steps
        for x,z in outline:
            xx=center[0]+(x-center[0])*u;zz=center[1]+(z-center[1])*u
            verts.append((xx,cloth_surface(rings,xx,zz)-offset-.0015*math.sin(u*math.pi),zz))
    faces=[(0,1+j,1+(j+1)%n) for j in range(n)]
    for row in range(steps-1):
        aa=1+row*n;bb=aa+n
        for j in range(n):faces.append((aa+j,bb+j,bb+(j+1)%n,aa+(j+1)%n))
    if (Vector(verts[faces[0][1]])-Vector(verts[faces[0][0]])).cross(Vector(verts[faces[0][2]])-Vector(verts[faces[0][0]])).y>0:
        faces=[tuple(reversed(f)) for f in faces]
    return a.mesh(name,verts,faces,mat,weights=[a.torso_weight(p) for p in verts])

def collar(rings,m,prefix='ShirtCollar'):
    for sign,side in [(1,'Left'),(-1,'Right')]:
        cloth_patch(prefix+side,[(sign*.052,1.286),(sign*.14,1.252),(sign*.092,1.182),
          (sign*.028,1.237)],rings,m['coat_light'])

def apron(slug,rings,m):
    # Each apron is a cut, curved original silhouette; bottom floats off the legs.
    zlo=.60 if slug=='ada' else .665;half=.203 if slug=='ada' else .175
    verts=[];faces=[];nx=20;nz=22
    for iz in range(nz):
        u=iz/(nz-1);z=zlo+(.955-zlo)*u;rx=half*(1-.18*u)
        for ix in range(nx):
            t=2*ix/(nx-1)-1;x=rx*t
            y=-.116+.026*t*t-.006*math.cos(t*math.pi*3)*(1-u)
            z2=z+.016*t*t*(1-u)
            verts.append((x,y,z2))
    for iz in range(nz-1):
        for ix in range(nx-1):
            k=iz*nx+ix;faces.append((k,k+1,k+1+nx,k+nx))
    a.mesh('WorkApron',verts,faces,m['apron'],weights=[a.torso_weight(p) for p in verts])
    cloth_patch('ApronBib',[(-.086,.942),(.086,.942),(.105,1.178),(.08,1.221),
      (-.08,1.221),(-.104,1.176)],rings,m['apron'],.009)
    for sign,side in [(1,'Left'),(-1,'Right')]:
        tube('ApronStrap'+side,[(sign*.069,-.111,1.199),(sign*.078,-.107,1.237),
          (sign*.094,-.062,1.272),(sign*.093,.044,1.272),(sign*.08,.123,1.192),
          (sign*.078,.125,1.12),(sign*.08,.127,1.04),(sign*.082,.131,.96)],
          .0085,m['apron'],a.torso_weight,n=10)
        tube('ApronWaistTie'+side,[(0,-.121,.955),(sign*.099,-.112,.966),
          (sign*.17,-.063,.96),(sign*.172,.064,.959),(sign*.083,.13,.959)],.006,m['apron_shadow'],'Spine')
    # Pocket uses apron-front surface, rather than the narrower shirt beneath.
    pz=.79 if slug=='ada' else .81;verts=[];faces=[];nx=12;nz=10
    for iz in range(nz):
        u=iz/(nz-1);z=pz+.092*u;pw=.093*(.88+.12*u)
        for ix in range(nx):
            x=pw*(2*ix/(nx-1)-1);y=-.125+.022*(x/half)**2-.003*math.sin(u*math.pi)
            verts.append((x,y,z))
    for iz in range(nz-1):
        for ix in range(nx-1):k=iz*nx+ix;faces.append((k,k+1,k+1+nx,k+nx))
    a.mesh('ApronPocket',verts,faces,m['apron_shadow'],weights=[a.torso_weight(p) for p in verts])
    tube('ApronPocketWelt',[(-.092,-.12,pz+.092),(0,-.128,pz+.092),(.092,-.12,pz+.092)],.003,m['apron'],'Spine')
    if slug=='noor':
        tube('PocketPencil',[(-.047,-.129,.884),(-.049,-.132,.967)],.004,m['brass'],'Spine')
        tube('PocketTool',[(-.020,-.13,.886),(-.023,-.13,.942)],.007,m['coat_shadow'],'Spine')


def work_garment(slug,cfg,m):
    kind=cfg['garment']
    if kind=='uniform':
        rings=[(.665,0,.013,.209,.106,.115),(.73,0,.011,.201,.113,.12),
          (.87,0,.008,.177,.112,.115),(.99,0,.007,.161,.107,.111),
          (1.11,0,.007,.18,.109,.109),(1.21,0,.006,.206,.103,.104),
          (1.26,0,.009,.22,.083,.093),(1.29,0,.014,.091,.062,.063)]
        env=torso('UniformCoat',rings,m['coat']);collar(env,m,'UniformLapel')
        cloth_patch('UniformUndershirt',[(-.043,1.284),(.043,1.284),(.038,1.177),(-.038,1.177)],env,m['shirt'],.009)
        for sign,side in [(1,'Left'),(-1,'Right')]:
            cloth_patch('UniformPocket'+side,[(sign*.061,.94),(sign*.145,.94),(sign*.137,.859),(sign*.071,.853)],env,m['coat_shadow'])
        for z in [.99,.9,.81,.73]:
            a.ellipse_patch('UniformButton%.2f'%z,(0,cloth_surface(env,0,z)-.012,z),.006,.006,m['brass'],'Spine',n=14)
        a.ellipse_patch('UniformBadge',(.127,cloth_surface(env,.127,1.158)-.01,1.158),.016,.012,m['brass'],'Chest',n=18)
    else:
        widen=1.055 if slug=='ada' else (1.015 if slug=='rafi' else .985)
        low=.78 if kind=='apron' else .83
        rings=[(low,0,.01,.17*widen,.106,.113),(.9,0,.008,.169*widen,.111,.113),
          (1.015,0,.006,.161*widen,.105,.109),(1.11,0,.005,.177*widen,.108,.109),
          (1.215,0,.005,.204*widen,.101,.105),(1.26,0,.008,.219*widen,.083,.092),
          (1.29,0,.009,.09,.061,.063)]
        name='StationShirt' if kind=='station' else ('WorkShirt' if kind=='work' else 'WorkBlouse')
        env=torso(name,rings,m['shirt'] if kind=='station' else m['coat']);collar(env,m)
        if kind=='apron':apron(slug,env,m)
        elif kind=='work':
            for sign,side in [(1,'Left'),(-1,'Right')]:
                cloth_patch('WorkPatchPocket'+side,[(sign*.041,1.158),(sign*.132,1.158),
                  (sign*.134,1.079),(sign*.087,1.061),(sign*.04,1.079)],env,m['coat_shadow'])
                a.ellipse_patch('WorkPocketFastener'+side,(sign*.087,cloth_surface(env,sign*.087,1.148)-.011,1.148),.004,.004,m['brass'],'Chest',n=12)
            for z in [.93,1.015,1.095,1.2]:
                a.ellipse_patch('WorkButton%.2f'%z,(0,cloth_surface(env,0,z)-.011,z),.004,.004,m['brass'],'Chest',n=12)
        else:
            vrings=[(.842,0,.009,.177,.114,.12),(.89,0,.008,.172,.118,.12),
              (1.01,0,.005,.167,.115,.116),(1.125,0,.006,.179,.117,.118),
              (1.22,0,.006,.202,.111,.115),(1.254,0,.009,.206,.092,.106),
              (1.276,0,.011,.094,.074,.073)]
            vestenv=torso('StationWaistcoat',vrings,m['coat'])
            # Cutaway ivory V is curved to the vest, giving an open tailored neck.
            cloth_patch('StationWaistcoatV',[(-.078,1.274),(.078,1.274),(.045,1.217),
              (0,1.157),(-.045,1.217)],vestenv,m['shirt'],.006)
            for sign,side in [(1,'Left'),(-1,'Right')]:
                cloth_patch('StationWeltPocket'+side,[(sign*.061,.995),(sign*.135,.999),
                  (sign*.132,.97),(sign*.064,.969)],vestenv,m['coat_shadow'])
            for z in [1.128,1.05,.972,.902]:
                a.ellipse_patch('StationButton%.2f'%z,(0,cloth_surface(vestenv,0,z)-.013,z),.0045,.0045,m['brass'],'Spine',n=12)
            a.ellipse_patch('StationBadge',(.104,cloth_surface(vestenv,.104,1.176)-.014,1.176),.019,.013,m['brass'],'Chest',n=18)
    return env

def cap(m):
    # Top never exceeds 1.72 native units: all cast preserve 1.7m export height.
    rings=[(1.613,0,.009,.165,.145,.133),(1.631,0,.011,.166,.147,.134),
      (1.663,0,.015,.161,.14,.135),(1.69,0,.019,.147,.122,.128),
      (1.713,0,.022,.095,.081,.083),(1.72,0,.023,.019,.016,.017)]
    a.loft('ConductorCapCrown',a.refined_contours(rings,3),m['coat'],'Head',n=48,square=.85)
    a.loft('ConductorCapBand',[(1.612,0,.009,.167,.146,.135),
      (1.636,0,.011,.169,.148,.137)],m['coat_shadow'],'Head',n=48,square=.88)
    verts=[];faces=[];n=30;rows=5
    for row in range(rows):
        u=row/(rows-1)
        for j in range(n):
            t=-1+2*j/(n-1);x=.146*t*(1+.06*u)
            y=-.108-.108*(1-t*t)**.55*u;z=1.615-.02*u+.01*t*t
            verts.append((x,y,z))
    for row in range(rows-1):
        for j in range(n-1):k=row*n+j;faces.append((k,k+1,k+1+n,k+n))
    a.mesh('ConductorCapVisor',verts,faces,m['coat_shadow'],bone='Head')
    tube('ConductorCapPiping',[(.143*(-1+2*j/20),-.149+.043*abs(-1+2*j/20)**2,1.639)
      for j in range(21)],.002,m['brass'],'Head')
    a.ellipse_patch('ConductorCapEmblem',(0,-.15,1.653),.011,.016,m['brass'],'Head',n=18)

def cast_limbs(slug,m):
    a.limbs(m,False)
    if slug!='rafi':return
    # The worker really has rolled sleeves and exposed anatomy, not cuff paint.
    for sign,side in [(1,'Left'),(-1,'Right')]:
        for name in ['JacketSleeve'+side,'Cuff'+side]:
            ob=bpy.data.objects[name];a.CHARACTER_OBJECTS.remove(ob);bpy.data.objects.remove(ob,do_unlink=True)
        shoulder=(sign*.195,0,1.245);elbow=(sign*.24,.003,1.015);wrist=(sign*.26,-.028,.79)
        points=[(sign*.164,0,1.218),(sign*.207,.002,1.194),(sign*.233,.008,1.126),elbow,(sign*.25,.001,.951)]
        radii=[(.046,.046),(.066,.06),(.054,.052),(.049,.047),(.044,.042)]
        rows=a.refined_contours([(p[2],p[0],p[1],r[0],r[1],r[1]) for p,r in zip(points,radii)],4)
        a.path_loft('RolledWorkSleeve'+side,[(r[1],r[2],r[0]) for r in rows],[(r[3],r[4]) for r in rows],m['coat'],
          lambda p:a.limb_weight(p,shoulder,wrist,elbow,('UpperArm'+side,'Forearm'+side)),n=24)
        a.path_loft('RolledCuff'+side,[(sign*.249,.001,.975),(sign*.253,-.002,.948)],
          [(.051,.047),(.048,.045)],m['coat_light'],'Forearm'+side,n=24)
        a.path_loft('ExposedWorkForearm'+side,[(sign*.25,-.001,.956),(sign*.255,-.008,.887),
          (sign*.26,-.023,.785)],[(.037,.034),(.034,.032),(.029,.028)],m['skin'],'Forearm'+side,n=24)

def clean_scene():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    a.CHARACTER_OBJECTS=[];a.RIG=None
    # Remove prior source data so repeated builds stay well below memory budgets.
    for store in [bpy.data.meshes,bpy.data.materials,bpy.data.armatures,bpy.data.actions,bpy.data.cameras,bpy.data.lights]:
        for item in list(store):
            if item.users==0 or (store==bpy.data.actions and item.use_fake_user):store.remove(item)

def build(slug):
    clean_scene();cfg=CAST[slug];out=DEST/slug;source=out/'source'
    source.mkdir(parents=True,exist_ok=True);(source/'.gdignore').write_text('')
    m=cast_materials(slug,cfg);a.make_rig(False);work_garment(slug,cfg,m);cast_limbs(slug,m)
    start=len(a.CHARACTER_OBJECTS);a.head_and_face(m,False);face_details(slug,m);reshape_face(start,cfg,slug);cast_hair(slug,cfg,m);a.animate()
    a.RIG['cast_id']=slug;a.RIG['individual_sculpt_changes']='; '.join(cfg['changes'])
    a.export_selected(out/(slug+'.glb'))
    cam=a.camera_and_lights();scene=bpy.context.scene;scene.frame_set(1)
    scene.render.threads=2;scene.cycles.samples=20
    scene.render.resolution_x=600;scene.render.resolution_y=760
    for p in a.RIG.pose.bones:p.location=(0,0,0);p.rotation_euler=(0,0,0);p.scale=(1,1,1)
    bpy.context.view_layer.update();a.aim(cam,(2.4,-5,2.1))
    bpy.ops.wm.save_as_mainfile(filepath=str(source/(slug+'.blend')))
    if '--no-render' not in sys.argv:
        scene.render.filepath=str(out/(slug+'_portrait.png'));bpy.ops.render.render(write_still=True)
    print('SUPPORTING_CAST_COMPLETE',slug,out/(slug+'.glb'),flush=True)

def manifest():
    data={'schema_version':1,'authorship':'Original sculpted supporting cast authored with project-owned contour, topology, materials, weights and animation tools',
      'source_generator':'tools/author_supporting_cast.py','base_contour_generator':'tools/author_characters.py',
      'binary_validator':'tools/test_supporting_character_assets.py','external_assets':[],
      'palette_only_variants':[],'units':'metres','height_metres':1.7,'ground_origin_y':0,
      'godot_forward_axis':'+Z','godot_up_axis':'+Y','rig':'Original 25-bone protagonist rig with unchanged names/parents',
      'animations':{'idle':{'duration_seconds':5,'loop':True},'walk':{'duration_seconds':1,'loop':True,'in_place':True}},
      'characters':{slug:{'glb':f'res://assets/characters/{slug}/{slug}.glb',
        'source':f'game/assets/characters/{slug}/source/{slug}.blend','role':cfg['role'],
        'individual_sculpt_changes':cfg['changes'],'palette':{k:cfg[k] for k in ['skin','hair','coat','pants']}}
        for slug,cfg in CAST.items()},
      'generic_cast_mapping':{'Journey worker':'rafi','Journey keeper':'jo'},
      'limits':['Simplified project-authored stylized geometry, no borrowed assets',
        'Original 25 bones; no finger bones, facial blendshapes or terrain IK',
        'Aprons are skinned cloth without cloth simulation','Target-device performance requires runtime testing']}
    (DEST/'supporting_cast_manifest.json').write_text(json.dumps(data,indent=2)+'\n')

if __name__=='__main__':
    only=sys.argv[sys.argv.index('--only')+1] if '--only' in sys.argv else None
    for slug in ([only] if only else CAST):build(slug)
    manifest()
