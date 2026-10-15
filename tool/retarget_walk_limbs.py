"""Retarget approved WALK pixels with the existing pure raster helpers."""
import ast
import hashlib
import json
import math
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'test/evidence/walk_motion_repair'
OUT.mkdir(parents=True,exist_ok=True)
SOURCE=OUT/'approved_walk_source.png'
if not SOURCE.exists(): SOURCE.write_bytes((ROOT/'assets/character/walk_00.png').read_bytes())
source=Image.open(SOURCE).convert('RGBA')
W,H=source.size
yy,xx=np.indices((H,W))
# Load only the existing pure raster helpers, never RUN's export statements.
module=ast.parse((ROOT/'tool/retarget_run_limbs.py').read_text())
helpers={'polygon','masked','complete_hidden_thigh','bone_matrix','deform','depth_mix'}
exec(compile(ast.Module(body=[n for n in module.body if isinstance(n,ast.FunctionDef) and n.name in helpers],type_ignores=[]),'limb_helpers','exec'))

right_joints=[(115,194),(137,249),(143,302),(183,306)]
left_joints=[(111,194),(98,251),(77,294),(101,310)]
right_mask=polygon([(103,183),(138,183),(154,232),(151,284),(156,296),
    (183,295),(202,305),(198,326),(126,331),(120,306),(111,260),(104,225)])
left_mask=polygon([(96,184),(116,187),(123,219),(111,253),(93,281),
    (85,296),(109,305),(118,321),(107,332),(52,314),(55,290),(74,262),(85,235)]) & ~right_mask
def leg_texture(mask,joints):
    pixels=np.asarray(masked(mask)).copy()
    green=(pixels[:,:,1]>pixels[:,:,0]*1.05)&(pixels[:,:,1]>pixels[:,:,2]*1.25)
    pixels[(yy<282)&~green]=0
    interior=np.asarray(Image.fromarray((mask*255).astype('uint8')).filter(ImageFilter.MinFilter(7)))>200
    material=(pixels[:,:,3]>240)&green&interior&(yy<282)
    sy,sx=np.nonzero(material)
    support=capsule(*joints[:2],15)|capsule(*joints[1:3],13)
    for y,x in zip(*np.nonzero(support&(yy<282)&~material)):
        k=np.argmin((sx-x)**2+(sy-y)**2);pixels[y,x]=pixels[sy[k],sx[k]]
    smooth=np.asarray(Image.fromarray(pixels[:,:,:3]).filter(ImageFilter.GaussianBlur(1.5)))
    pixels[support&(yy<278),:3]=smooth[support&(yy<278)]
    return Image.fromarray(pixels)

head_mask=(yy<111)|((xx>107)&(xx<136)&(yy<117))
coverage=Image.new('L',(W*4,H*4));draw=ImageDraw.Draw(coverage)
draw.polygon([(x*4,y*4) for x,y in [(103,110),(129,116),(143,148),(144,180),
    (137,195),(99,196),(95,182),(95,148),(98,122)]],fill=255)
draw.ellipse((94*4,177*4,144*4,210*4),fill=255)
coverage=np.asarray(coverage.resize(source.size,Image.Resampling.LANCZOS)).copy()
coverage[head_mask]=255
body_pixels=np.asarray(source).copy();body_pixels[:,:,3]=np.minimum(body_pixels[:,:,3],coverage)
clean=(body_pixels[:,:,1]>body_pixels[:,:,0]*1.15)&(body_pixels[:,:,1]>body_pixels[:,:,2]*1.3)
valid=clean&(body_pixels[:,:,3]>240)&~head_mask
by,bx=np.nonzero(valid)
for y,x in zip(*np.nonzero((body_pixels[:,:,3]>0)&~clean&~head_mask)):
    k=np.argmin((bx-x)**2+(by-y)**2);body_pixels[y,x,:3]=body_pixels[by[k],bx[k],:3]
body_pixels[body_pixels[:,:,3]==0]=0
body=Image.fromarray(body_pixels);body.save(OUT/'frozen_body.png')

arm_source={'RIGHT':[(116,127),(137,165),(187,182)],
    'LEFT':[(104,126),(80,158),(57,189)]}
def capsule(a,b,r):
    a,b=np.asarray(a,float),np.asarray(b,float);p=np.stack([xx,yy],axis=-1);v=b-a
    t=np.clip(np.sum((p-a)*v,axis=-1)/np.dot(v,v),0,1)
    return np.linalg.norm(p-a-t[:,:,None]*v,axis=-1)<r
right_texture=leg_texture(right_mask,right_joints)
left_texture=leg_texture(left_mask,left_joints)
arm_textures={}
for side,joints in arm_source.items():
    mask=capsule(*joints[:2],14)|capsule(*joints[1:],15)
    mask|=((xx-joints[2][0])**2+(yy-joints[2][1])**2)<19**2
    pixels=np.asarray(masked(mask)).copy()
    green=(pixels[:,:,1]>pixels[:,:,0]*1.05)&(pixels[:,:,1]>pixels[:,:,2]*1.25)
    interior=np.asarray(Image.fromarray((mask*255).astype('uint8')).filter(ImageFilter.MinFilter(5)))>200
    valid=interior&(pixels[:,:,3]>240)&green
    sy,sx=np.nonzero(valid)
    for y,x in zip(*np.nonzero(mask&~valid)):
        k=np.argmin((sx-x)**2+(sy-y)**2);pixels[y,x]=pixels[sy[k],sx[k]]
    colors=np.asarray(Image.fromarray(pixels[:,:,:3]).filter(ImageFilter.GaussianBlur(1.3)))
    pixels[mask,:3]=colors[mask]
    arm_textures[side]=Image.fromarray(pixels)

def arm_image(side,chain):
    pixels=np.asarray(deform(arm_textures[side],arm_source[side],chain)).copy()
    support=Image.new('L',(W*4,H*4));d=ImageDraw.Draw(support)
    for k,radius in enumerate([14,15]):
        a,b=chain[k]*4,chain[k+1]*4
        d.line([tuple(a),tuple(b)],fill=255,width=radius*8)
        for x,y in [a,b]:d.ellipse((x-radius*4,y-radius*4,x+radius*4,y+radius*4),fill=255)
    x,y=chain[2]*4;d.ellipse((x-76,y-76,x+76,y+76),fill=255)
    support=np.asarray(support.resize(source.size,Image.Resampling.LANCZOS))
    sy,sx=np.nonzero((pixels[:,:,3]>100)&(support>100))
    for y,x in zip(*np.nonzero((support>0)&(pixels[:,:,3]<100))):
        k=np.argmin((sx-x)**2+(sy-y)**2);pixels[y,x,:3]=pixels[sy[k],sx[k],:3]
    pixels[:,:,3]=support
    return Image.fromarray(pixels)

def leg_image(texture,joints,chain):
    pixels=np.asarray(deform(texture,joints,chain)).copy()
    support=Image.new('L',(W*4,H*4));d=ImageDraw.Draw(support)
    for k,radius in enumerate([14,11]):
        a,b=chain[k]*4,chain[k+1]*4
        d.line([tuple(a),tuple(b)],fill=255,width=radius*8)
        for x,y in [a,b]:d.ellipse((x-radius*4,y-radius*4,x+radius*4,y+radius*4),fill=255)
    support=np.asarray(support.resize(source.size,Image.Resampling.LANCZOS))
    shoe_source=np.asarray(texture).copy()
    shoe_mask=capsule(joints[2],joints[3],23)&(yy>joints[2][1]-12)
    shoe_source[~shoe_mask]=0
    matrix,offset=bone_matrix(joints[2],joints[3],chain[2],chain[3])
    inverse=np.linalg.inv(matrix);shift=-inverse@offset
    shoe_image=Image.fromarray(shoe_source).transform(source.size,Image.Transform.AFFINE,
        tuple(np.column_stack([inverse,shift]).ravel()),Image.Resampling.BICUBIC)
    shoe_pixels=np.asarray(shoe_image)
    shoe=shoe_pixels[:,:,3]>0
    material=(pixels[:,:,3]>220)&(pixels[:,:,1]>pixels[:,:,0]*1.1)&(yy<chain[2][1]-8)
    sy,sx=np.nonzero(material)
    for y,x in zip(*np.nonzero((support>0)&~material&~shoe)):
        k=np.argmin((sx-x)**2+(sy-y)**2);pixels[y,x,:3]=pixels[sy[k],sx[k],:3]
    colors=np.asarray(Image.fromarray(pixels[:,:,:3]).filter(ImageFilter.GaussianBlur(1.3)))
    pixels[(support>0)&~shoe,:3]=colors[(support>0)&~shoe]
    pixels[:,:,3]=support
    return Image.alpha_composite(shoe_image,Image.fromarray(pixels))

def leg_chain(frame,hip):
    phase=frame*math.pi/8
    ankle=np.asarray(hip,float)+[52*math.cos(phase)*(1+.25*math.sin(phase)**2),110-6*(1-math.cos(phase))-18*max(0,-math.sin(phase))**2]
    vector=ankle-hip;distance=np.linalg.norm(vector);direction=vector/distance
    along=distance/2;normal=np.array([direction[1],-direction[0]])
    knee=np.asarray(hip)+direction*along+normal*math.sqrt(max(0,61**2-along**2))
    angle=math.radians(8-16*math.cos(phase)-10*max(0,math.sin(phase))-8*max(0,-math.sin(phase)))
    toe=ankle+40*np.array([math.cos(angle),math.sin(angle)])
    return np.asarray([hip,knee,ankle,toe])

def arm_chain(frame,pivot):
    swing=math.cos(frame*math.pi/8)
    upper=math.radians(92+30*swing);lower=math.radians(72+32*swing)
    elbow=np.asarray(pivot)+42*np.array([math.cos(upper),math.sin(upper)])
    wrist=elbow+40*np.array([math.cos(lower),math.sin(lower)])
    return np.asarray([pivot,elbow,wrist])

frames=[];rows=[];identity=[]
for i in range(16):
    legs={'RIGHT':leg_chain(i,(115,194)),'LEFT':leg_chain(i+8,(111,194))}
    arms={'RIGHT':arm_chain(i,(116,127)),'LEFT':arm_chain(i+8,(110,127))}
    leg_layers={'RIGHT':leg_image(right_texture,right_joints,legs['RIGHT']),
        'LEFT':leg_image(left_texture,left_joints,legs['LEFT'])}
    arm_layers={side:arm_image(side,arms[side]) for side in arms}
    for side in legs:leg_layers[side].save(OUT/f'{side}_leg_{i:02}.png')
    for side in arms:arm_layers[side].save(OUT/f'{side}_arm_{i:02}.png')
    left_over=Image.alpha_composite(leg_layers['RIGHT'],leg_layers['LEFT'])
    right_over=Image.alpha_composite(leg_layers['LEFT'],leg_layers['RIGHT'])
    left_depth=float(np.clip(.5-.85*math.cos(i*math.pi/8),0,1))
    legs_image=depth_mix(right_over,left_over,left_depth)
    first=Image.alpha_composite(Image.alpha_composite(Image.alpha_composite(legs_image,arm_layers['LEFT']),body),arm_layers['RIGHT'])
    second=Image.alpha_composite(Image.alpha_composite(Image.alpha_composite(legs_image,arm_layers['RIGHT']),body),arm_layers['LEFT'])
    image=depth_mix(first,second,1-left_depth)
    pixels=np.asarray(image).copy()
    solid=(pixels[:,:,3]>240)&(pixels[:,:,:3].max(axis=2)>25)
    sy,sx=np.nonzero(solid)
    fringe=(pixels[:,:,3]>0)&(pixels[:,:,3]<250)&(pixels[:,:,:3].max(axis=2)<15)&~head_mask
    for y,x in zip(*np.nonzero(fringe)):
        k=np.argmin((sx-x)**2+(sy-y)**2);pixels[y,x,:3]=pixels[sy[k],sx[k],:3]
    pixels[head_mask]=np.asarray(source)[head_mask]
    image=Image.fromarray(pixels);frames.append(image);image.save(OUT/f'frame_{i:02}.png')
    row={'frame':f'W{i+1:02}'}
    for side in legs:
        for key,p in zip(['Hip','Knee','Ankle','Toe'],legs[side]):row[side.lower()+key]=p.tolist()
        for key,p in zip(['Shoulder','Elbow','Wrist'],arms[side]):row[side.lower()+key]=p.tolist()
    rows.append(row)
    qa=image.copy();d=ImageDraw.Draw(qa)
    for side,color in [('LEFT','#ff4545'),('RIGHT','#479aff')]:
        for chain in [legs[side][:3],arms[side]]:
            d.line([tuple(p) for p in chain],fill=color,width=2)
            for x,y in chain:d.ellipse((x-2,y-2,x+2,y+2),fill=color)
    identity.append(qa)

def sheet(images,indices,name,columns=8,zoom=1,frame_prefix='W'):
    size=(W*columns,(H+22)*math.ceil(len(indices)/columns));canvas=Image.new('RGB',size,'#181818');d=ImageDraw.Draw(canvas)
    for n,i in enumerate(indices):
        x=(n%columns)*W;y=(n//columns)*(H+22);canvas.paste(images[i],(x,y+22),images[i]);d.text((x+8,y+5),f'{frame_prefix}{i+1:02}',fill='white')
    if zoom!=1:canvas=canvas.resize((canvas.width*zoom,canvas.height*zoom))
    canvas.save(OUT/name)
sheet(frames,list(range(16)),'full_body_16.png')
sheet(frames,[0,8],'max_forward.png',columns=2,zoom=2)
sheet(frames,list(range(9)),'RIGHT_half.png',columns=9)
sheet(frames,list(range(8,16))+[0],'LEFT_half.png',columns=9)
sheet(frames,[0,4,8,12],'four_phases.png',columns=4)
sheet(identity,list(range(16)),'identity_16.png')
for kind,chains in [('legs',['Hip','Knee','Ankle']),('arms',['Shoulder','Elbow','Wrist'])]:
    marked=[]
    for i,frame in enumerate(frames):
        qa=frame.copy();d=ImageDraw.Draw(qa)
        for side,color in [('left','#ff4545'),('right','#479aff')]:
            points=[tuple(rows[i][side+key]) for key in chains]
            d.line(points,fill=color,width=3)
            for x,y in points:d.ellipse((x-3,y-3,x+3,y+3),fill=color)
            d.text((8,275 if side=='left' else 292),side.upper(),fill=color)
        marked.append(qa)
    sheet(marked,[0,8],kind+'_max_forward.png',columns=2,zoom=2)
sheet(frames,[15,0,1],'cycle_seam.png',columns=3)
sheet(frames,[3,4,5,7,8,11,12,13],'critical_pairs.png')
for kind,keys in [('leg',['Hip','Knee','Ankle']),('ankle',['Ankle']),('arm',['Shoulder','Elbow','Wrist'])]:
    canvas=Image.new('RGB',(512,364),'#181818');d=ImageDraw.Draw(canvas)
    for n,(side,color,anchor) in enumerate([('left','#ff4545',8),('right','#479aff',0)]):
        canvas.paste(frames[anchor],(n*256,22),frames[anchor]);d.text((n*256+8,5),side.upper()+' '+kind,fill=color)
        for key in keys:
            points=[(n*256+row[side+key][0],22+row[side+key][1]) for row in rows]
            d.line(points+[points[0]],fill=color,width=2)
            for i,(x,y) in enumerate(points):
                d.ellipse((x-2,y-2,x+2,y+2),fill=color)
                if key==keys[-1] and i%2==0:d.text((x+3,y-10),str(i+1),fill=color)
    canvas.save(OUT/(kind+'_paths.png'))

validation={'frame_count':16,'cycle_ms':1250,'shoulder_swing_degrees':30,
    'elbow_flex_range_degrees':[18,22],'head_pixel_diff':0,'root_shift_px':0}
for kind,keys in [('leg',['Hip','Knee','Ankle']),('arm',['Shoulder','Elbow','Wrist'])]:
    right=np.asarray([[r['right'+key] for key in keys] for r in rows]);left=np.asarray([[r['left'+key] for key in keys] for r in rows])
    error=float(np.max(np.abs((left-left[:,:1])-np.roll(right-right[:,:1],8,axis=0))))
    assert error<1e-8
    jumps=np.linalg.norm(np.roll(right,-1,axis=0)-right,axis=2);frame,joint=np.unravel_index(np.argmax(jumps),jumps.shape)
    validation[kind+'_phase_error_px']=error
    validation['largest_'+kind+'_adjacent_jump']={'pair':f'W{frame+1:02}→W{(frame+1)%16+1:02}','joint':keys[joint],'distance_px':float(jumps[frame,joint])}
validation['passing_frames']=['W05','W13'];validation['compact_hold_frames']=1
(OUT/'joint_trajectories.json').write_text(json.dumps(rows,indent=2));(OUT/'validation.json').write_text(json.dumps(validation,indent=2))
import csv
with (OUT/'joint_trajectories.csv').open('w',newline='') as handle:
    writer=csv.writer(handle);keys=[key for key in rows[0] if key!='frame']
    writer.writerow(['frame']+[key+axis for key in keys for axis in ['X','Y']])
    for row in rows:writer.writerow([row['frame']]+[value for key in keys for value in row[key]])
locks=json.loads((OUT/'run_asset_locks.json').read_text())
assert all(hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest for name,digest in locks.items())
if '--write' in sys.argv:
    for i,image in enumerate(frames):
        image.save(ROOT/f'assets/character/walk_{i:02}.png')
        compact=image.resize((128,171),Image.Resampling.LANCZOS)
        pixels=np.asarray(compact).copy()
        sy,sx=np.nonzero((pixels[:,:,3]>240)&(pixels[:,:,:3].max(axis=2)>25))
        fringe=(pixels[:,:,3]>0)&(pixels[:,:,3]<250)&(pixels[:,:,:3].max(axis=2)<15)
        for y,x in zip(*np.nonzero(fringe)):
            k=np.argmin((sx-x)**2+(sy-y)**2);pixels[y,x,:3]=pixels[sy[k],sx[k],:3]
        compact=Image.fromarray(pixels)
        compact.save(OUT/f'dashboard_frame_{i:02}.png')
        compact.save(ROOT/f'assets/character/dashboard_walk_{i:02}.png')
    idle=Image.open(ROOT/'assets/character/idle.png').convert('RGBA')
    transitions=[idle,None,None,frames[0]]
    transition_sheet=Image.open(ROOT/'test/goldens/activity_character_idle_walk_transition_v1.png').convert('RGBA')
    def anchor(image):
        p=np.asarray(image);ys,xs=np.nonzero(p[:,:,3]>240)
        top,bottom=int(ys.min()),int(ys.max())
        head=(p[:,:,3]>240)&(np.indices(p.shape[:2])[0]<top+70)
        return np.nonzero(head)[1].mean(),top,bottom
    a,b=anchor(idle),anchor(frames[0])
    from collections import deque
    for index in [1,2]:
        cell=transition_sheet.crop((index*542,0,(index+1)*542,724))
        p=np.asarray(cell).copy()
        neon=((p[:,:,1]>180)&(p[:,:,0]<45)&(p[:,:,2]<65))|((p[:,:,0]>190)&(p[:,:,1]>190)&(p[:,:,2]<85))
        p[neon]=0
        mask=p[:,:,3]>30;seen=np.zeros(mask.shape,bool);largest=[]
        for y,x in zip(*np.nonzero(mask)):
            if seen[y,x]:continue
            queue=deque([(y,x)]);seen[y,x]=True;component=[]
            while queue:
                cy,cx=queue.popleft();component.append((cy,cx))
                for ny,nx in [(cy-1,cx),(cy+1,cx),(cy,cx-1),(cy,cx+1)]:
                    if 0<=ny<724 and 0<=nx<542 and mask[ny,nx] and not seen[ny,nx]:
                        seen[ny,nx]=True;queue.append((ny,nx))
            if len(component)>len(largest):largest=component
        keep=np.zeros(mask.shape,bool)
        cy,cx=np.asarray(largest).T;keep[cy,cx]=True
        keep=np.asarray(Image.fromarray((keep*255).astype('uint8')).filter(ImageFilter.MaxFilter(3)))>0
        p[~keep]=0
        bottom=int(np.nonzero(p[:,:,3]>240)[0].max())
        floor=(np.indices(p.shape[:2])[0]>bottom-12)&(p[:,:,:3].max(axis=2)<100)
        p[floor]=0
        cell=Image.fromarray(p);head,top,bottom=anchor(cell)
        t=index/3;scale=((a[2]-a[1])*(1-t)+(b[2]-b[1])*t)/(bottom-top)
        resized=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.LANCZOS)
        target=Image.new('RGBA',(W,H))
        target.alpha_composite(resized,(round(a[0]*(1-t)+b[0]*t-head*scale),round(a[2]*(1-t)+b[2]*t-bottom*scale)))
        p=np.asarray(target).copy();sy,sx=np.nonzero((p[:,:,3]>240)&(p[:,:,:3].max(axis=2)>25))
        for y,x in zip(*np.nonzero((p[:,:,3]>0)&(p[:,:,3]<250)&(p[:,:,:3].max(axis=2)<15))):
            k=np.argmin((sx-x)**2+(sy-y)**2);p[y,x,:3]=p[sy[k],sx[k],:3]
        target=Image.fromarray(p)
        transitions[index]=target
    for i,image in enumerate(transitions):
        image.save(OUT/f'transition_{i:02}.png');image.save(ROOT/f'assets/character/transition_idle_walk_{i:02}.png')
        small=image.resize((128,171),Image.Resampling.LANCZOS)
        if i in [0,3]:
            small=Image.open(ROOT/f'assets/character/dashboard_{"idle" if i==0 else "walk_00"}.png').convert('RGBA')
        else:
            p=np.asarray(small).copy();sy,sx=np.nonzero((p[:,:,3]>240)&(p[:,:,:3].max(axis=2)>25))
            for y,x in zip(*np.nonzero((p[:,:,3]>0)&(p[:,:,3]<250)&(p[:,:,:3].max(axis=2)<15))):
                k=np.argmin((sx-x)**2+(sy-y)**2);p[y,x,:3]=p[sy[k],sx[k],:3]
            small=Image.fromarray(p)
        small.save(OUT/f'dashboard_transition_{i:02}.png');small.save(ROOT/f'assets/character/dashboard_transition_idle_walk_{i:02}.png')
        if i in [0,3]:
            name='idle' if i==0 else 'walk_00'
            for prefix in ['', 'dashboard_']:
                exact=(ROOT/f'assets/character/{prefix}{name}.png').read_bytes()
                (OUT/f'{prefix}transition_{i:02}.png').write_bytes(exact)
                (ROOT/f'assets/character/{prefix}transition_idle_walk_{i:02}.png').write_bytes(exact)
    sheet(transitions,list(range(4)),'idle_walk_transition.png',columns=4,frame_prefix='T')
    (OUT/'native_export.json').write_text(json.dumps(validation,indent=2))
print(json.dumps(validation,indent=2))
