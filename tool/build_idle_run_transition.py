"""Retarget existing clean pixels for a first step; locked gait files are read-only."""
import ast
import json
import math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT=Path(__file__).resolve().parent.parent
ASSETS=ROOT/'assets/character'
LAYERS=ROOT/'test/evidence/run_motion_v7/bilateral_fix'
OUT=ROOT/'test/evidence/idle_run_ambient'
OUT.mkdir(parents=True,exist_ok=True)
source=Image.open(ROOT/'test/goldens/run_motion_v7/final/approved_source_native.png').convert('RGBA')
W,H=source.size
yy,xx=np.indices((H,W))
# Load pure raster helpers only; never execute the RUN exporter.
module=ast.parse((ROOT/'tool/retarget_run_limbs.py').read_text())
helpers=[n for n in module.body if isinstance(n,ast.FunctionDef) and n.name in ['bone_matrix','deform']]
exec(compile(ast.Module(body=helpers,type_ignores=[]),'run_raster_helpers','exec'))

def capsule(a,b,radius):
    a,b=np.array(a,float),np.array(b,float);v=b-a;p=np.stack([xx,yy],axis=-1)
    t=np.clip(np.sum((p-a)*v,axis=-1)/np.dot(v,v),0,1)
    return np.linalg.norm(p-a-t[:,:,None]*v,axis=-1)<radius

def arm_texture(joints):
    mask=capsule(*joints[:2],12)|capsule(*joints[1:],13)
    pixels=np.asarray(source).copy();pixels[~mask]=0
    sy,sx=np.nonzero(mask&(pixels[:,:,3]>200))
    for y,x in zip(*np.nonzero(mask&(pixels[:,:,3]<200))):
        k=np.argmin((sx-x)**2+(sy-y)**2);pixels[y,x]=pixels[sy[k],sx[k]]
    return Image.fromarray(pixels)

arm_sources={'RIGHT':[(130,128),(90,148),(62,170)],'LEFT':[(164,143),(180,160),(218,159)]}
arm_textures={side:arm_texture(joints) for side,joints in arm_sources.items()}
idle=Image.open(ASSETS/'idle.png').convert('RGBA')
body_mask=Image.new('L',(W*4,H*4));d=ImageDraw.Draw(body_mask)
d.polygon([(x*4,y*4) for x,y in [(108,109),(146,109),(156,140),(155,194),(147,209),(104,209),(101,181),(103,135)]],fill=255)
mask=np.asarray(body_mask.resize((W,H),Image.Resampling.LANCZOS)).copy();mask[yy<112]=255
p=np.asarray(idle).copy();p[:,:,3]=np.minimum(p[:,:,3],mask);idle_body=Image.fromarray(p)
run_body=Image.open(LAYERS/'frozen_body_without_exposed_arms.png').convert('RGBA')

def body_pose(t):
    a,b=np.asarray(idle_body,float)/255,np.asarray(run_body,float)/255
    knots_a=np.array([0,36,104,116,201,216,342],float)
    knots_b=np.array([0,59,127,134,184,208,342],float)
    target=knots_a*(1-t)+knots_b*t;y=np.arange(H,dtype=float)
    ys=[np.interp(y,target,k).clip(0,H-1.001) for k in (knots_a,knots_b)]
    bounds=[]
    for im,sy in zip((a,b),ys):
        edges=[np.flatnonzero(row[:,3]>.15) for row in im]
        l=[v[0] if len(v) else 128 for v in edges];r=[v[-1] if len(v) else 128 for v in edges]
        bounds.append((np.interp(sy,y,l),np.interp(sy,y,r)))
    left=bounds[0][0]*(1-t)+bounds[1][0]*t;right=bounds[0][1]*(1-t)+bounds[1][1]*t
    fraction=(np.arange(W)[None,:]-left[:,None])/np.maximum(right-left,1)[:,None]
    warped=[]
    for im,sy,(l,r) in zip((a,b),ys,bounds):
        im=im.copy();im[:,:,:3]*=im[:,:,3:];x=(l[:,None]+fraction*(r-l)[:,None]).clip(0,W-1.001)
        x0=x.astype(int);y0=sy.astype(int)[:,None];dx=(x-x0)[:,:,None];dy=(sy-sy.astype(int))[:,None,None]
        pix=im[y0,x0]*(1-dx)*(1-dy)+im[y0,x0+1]*dx*(1-dy)+im[y0+1,x0]*(1-dx)*dy+im[y0+1,x0+1]*dx*dy
        pix[(fraction<0)|(fraction>1)]=0;warped.append(pix)
    pix=warped[0]*(1-t)+warped[1]*t;pix[:,:,:3]/=np.maximum(pix[:,:,3:],1/255)
    pix[:,:,3]=np.clip((pix[:,:,3]-.12)/.20,0,1)
    return Image.fromarray((pix.clip(0,1)*255).round().astype('uint8'))

legs=json.loads((LAYERS/'joint_trajectories.json').read_text())
arms=json.loads((LAYERS/'arm_trajectories.json').read_text())
idle_arms={'RIGHT':np.array([(108,124),(98,169),(100,220)],float),'LEFT':np.array([(149,128),(157,170),(162,220)],float)}
idle_legs={'RIGHT':np.array([(115,201),(110,250),(93,301),(138,301)],float),'LEFT':np.array([(144,201),(145,250),(136,301),(181,301)],float)}
weights=[0,.15,.30,.50,.70,.90,1]
strips=[];reports=[]
for frame in (0,8):
    run=Image.open(ASSETS/f'run_{frame:02}.png').convert('RGBA');frames=[]
    run_arms={a['side']:np.array([a[k] for k in ['shoulder','elbow','wrist']],float) for a in arms[frame]['arms']}
    chains={}
    for side in ['LEFT','RIGHT']:
        chain=np.array(legs[frame][side],float)
        phase=(frame+(8 if side=='LEFT' else 0)-6)*math.pi/8
        foot=math.radians(23.5-51.5*math.cos(phase)-20*math.sin(phase))
        chains[side]=np.vstack([chain,chain[-1]+45*np.array([math.cos(foot),math.sin(foot)])])
    for step,t in enumerate(weights):
        arm_targets={s:idle_arms[s]*(1-t)+run_arms[s]*t for s in idle_arms}
        leg_targets={s:idle_legs[s]*(1-t)+chains[s]*t for s in idle_legs}
        if step==0:im=idle.copy()
        elif step==6:im=run.copy()
        else:
            layers={s:deform(Image.open(LAYERS/f'{s}_{frame:02}.png').convert('RGBA'),chains[s],leg_targets[s]) for s in chains}
            arm_layers={s:deform(arm_textures[s],arm_sources[s],arm_targets[s],arm_shape=True) for s in arm_targets}
            # R01 has LEFT lead / RIGHT arm forward; R09 has the opposite identity.
            front_leg='LEFT' if frame==0 else 'RIGHT';back_leg='RIGHT' if frame==0 else 'LEFT'
            front_arm='RIGHT' if frame==0 else 'LEFT';back_arm='LEFT' if frame==0 else 'RIGHT'
            im=Image.alpha_composite(layers[back_leg],layers[front_leg])
            for layer in [arm_layers[back_arm],body_pose(t),arm_layers[front_arm]]:im=Image.alpha_composite(im,layer)
        name=f'transition_idle_run_{frame:02}_{step:02}.png';im.save(ASSETS/name)
        small=im.resize((128,171),Image.Resampling.LANCZOS)
        if step in (0,6):small=Image.open(ASSETS/('dashboard_idle.png' if step==0 else f'dashboard_run_{frame:02}.png')).convert('RGBA')
        small.save(ASSETS/('dashboard_'+name));frames.append(small)
        reports.append({'entryFrame':frame,'bridgeFrame':step,'amplitude':t,'pelvisCenter':[129*(1-t)+122*t,201*(1-t)+184*t],
            'arms':{s:{k:v.tolist() for k,v in zip(['shoulder','elbow','wrist'],arm_targets[s])} for s in arm_targets},
            'legs':{s:leg_targets[s].tolist() for s in leg_targets}})
    strips.append(frames)
for reverse,name in [(False,'idle_to_run_strip.png'),(True,'run_to_idle_strip.png')]:
    canvas=Image.new('RGB',(7*128,2*195),(253,248,233));draw=ImageDraw.Draw(canvas)
    for row,frames in enumerate(strips):
        indices=list(range(6,-1,-1)) if reverse else list(range(7))
        for column,index in enumerate(indices):
            im=frames[index];canvas.paste(im,(column*128,row*195+24),im.getchannel('A'))
            draw.text((column*128,row*195),f'R{[1,9][row]:02} bridge {index}',fill=(30,40,30))
    canvas.save(OUT/name)
pair=Image.new('RGB',(4*128,195),(253,248,233));draw=ImageDraw.Draw(pair)
for row,frame in enumerate([0,8]):
    for col,im in enumerate([strips[row][-1],Image.open(ASSETS/f'dashboard_run_{frame:02}.png')]):
        x=(row*2+col)*128;pair.paste(im,(x,24),im.getchannel('A'));draw.text((x,0),'bridge 6' if col==0 else f'production R{frame+1:02}',fill=(30,40,30))
pair.save(OUT/'bridge_production_endpoints.png')
(OUT/'transition_trajectories.json').write_text(json.dumps(reports,indent=2))
print('First-step bridges generated; production gait assets untouched.')
