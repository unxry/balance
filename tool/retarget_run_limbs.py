"""Retarget approved limb pixels with a continuous skin and frozen body."""
import json
import math
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'test/evidence/run_motion_v7/bilateral_fix'
FINAL = ROOT / 'test/goldens/run_motion_v7/final'
OUT.mkdir(parents=True, exist_ok=True)
FINAL.mkdir(parents=True, exist_ok=True)
SOURCE = FINAL / 'approved_source_native.png'
if not SOURCE.exists():
    original = ROOT / 'build/ios/iphonesimulator/Runner.app/Frameworks/App.framework/flutter_assets/assets/character/run_06.png'
    SOURCE.write_bytes(original.read_bytes())
source = Image.open(SOURCE).convert('RGBA')
W,H = source.size
yy,xx = np.indices((H,W))

def polygon(points):
    mask = Image.new('L', (W*4,H*4))
    ImageDraw.Draw(mask).polygon([(x*4,y*4) for x,y in points], fill=255)
    return np.asarray(mask.resize(source.size,Image.Resampling.LANCZOS))>127

def masked(mask):
    pixels = np.asarray(source).copy()
    pixels[~mask] = 0
    return Image.fromarray(pixels)

right_mask = polygon([(98,171),(119,171),(152,185),(174,200),(184,225),
    (201,251),(216,252),(236,246),(247,250),(247,268),(207,290),(180,295),
    (175,276),(175,262),(151,223),(125,216),(98,202),(91,188)])
left_mask = polygon([(97,192),(124,211),(124,219),(108,231),(78,241),
    (36,255),(33,264),(39,283),(34,298),(18,292),(7,279),(0,248),
    (3,229),(24,229),(44,225),(67,209),(84,207)])
left_mask &= ~right_mask
pelvis = ((xx-121)/26)**2+((yy-183)/18)**2<=1
waist = 173 + .27*np.clip(xx-99,0,60)
body_mask = (yy<waist)|pelvis|(((xx<98)|(xx>175))&(yy<195))
body = masked(body_mask)
body.save(OUT/'frozen_body.png')
masked(right_mask).save(OUT/'source_RIGHT.png')
masked(left_mask).save(OUT/'source_LEFT.png')

def complete_hidden_thigh(texture,hip,knee,radius):
    pixels=np.asarray(texture).copy()
    a,b=np.asarray(hip,float),np.asarray(knee,float)
    points=np.stack([xx,yy],axis=-1)
    v=b-a
    t=np.clip(np.sum((points-a)*v,axis=-1)/np.dot(v,v),0,1)
    distance=np.linalg.norm(points-a-t[:,:,None]*v,axis=-1)
    hidden=(distance<radius)&(pixels[:,:,3]==0)
    sy,sx=np.nonzero(pixels[:,:,3]>200)
    for y,x in zip(*np.nonzero(hidden)):
        nearest=np.argmin((sx-x)**2+(sy-y)**2)
        pixels[y,x]=pixels[sy[nearest],sx[nearest]]
    return Image.fromarray(pixels)

left_texture=complete_hidden_thigh(masked(left_mask),(117,184),(80,220),14)
right_texture=complete_hidden_thigh(masked(right_mask),(122,183),(166,213),16)

def bone_matrix(a,b,c,d):
    a,b,c,d = map(lambda p: np.asarray(p,dtype=float),(a,b,c,d))
    v,u = b-a,d-c
    sv,tu = v/np.linalg.norm(v),u/np.linalg.norm(u)
    sa = np.stack([sv,[-sv[1],sv[0]]],axis=1)
    ta = np.stack([tu,[-tu[1],tu[0]]],axis=1)
    matrix = ta@np.diag([np.linalg.norm(u)/np.linalg.norm(v),1])@sa.T
    return matrix,c-matrix@a

def deform(texture,joints,targets,arm_shape=False):
    pixels = np.asarray(texture).astype(float)/255
    pixels[:,:,:3] *= pixels[:,:,3:4]
    joint,target = np.asarray(joints,float),np.asarray(targets,float)
    matrices = [bone_matrix(joint[k],joint[k+1],target[k],target[k+1]) for k in range(len(joint)-1)]
    count=len(matrices)
    alpha = pixels[:,:,3]
    ys,xs = np.nonzero(alpha)
    xgrid = np.arange(max(0,xs.min()-8),min(W,xs.max()+9),6,dtype=float)
    ygrid = np.arange(max(0,ys.min()-8),min(H,ys.max()+9),6,dtype=float)
    sx,sy = np.meshgrid(xgrid,ygrid)
    vertices = np.stack([sx,sy],axis=-1)
    lengths = np.linalg.norm(np.diff(joint,axis=0),axis=1)
    arcs = np.r_[0,np.cumsum(lengths)]
    distances,positions = [],[]
    for k in range(count):
        v=joint[k+1]-joint[k]
        t=np.clip(np.sum((vertices-joint[k])*v,axis=-1)/np.dot(v,v),0,1)
        distances.append(np.sum((vertices-joint[k]-t[:,:,None]*v)**2,axis=-1))
        positions.append(arcs[k]+t*lengths[k])
    nearest=np.argmin(distances,axis=0)
    arc=np.choose(nearest,positions)
    weights=np.zeros((*arc.shape,count))
    weights[:,:,0]=np.clip((arcs[1]+9-arc)/18,0,1)
    if count==3:
        weights[:,:,2]=np.clip((arc-arcs[2]+8)/16,0,1)
        weights[:,:,1]=1-weights[:,:,0]-weights[:,:,2]
    else:
        weights[:,:,1]=1-weights[:,:,0]
    moved=sum((vertices@m.T+offset)*weights[:,:,k,None] for k,(m,offset) in enumerate(matrices))
    raster=np.zeros((H*2,W*2,4),float)
    for row in range(len(ygrid)-1):
        for col in range(len(xgrid)-1):
            patch=alpha[int(ygrid[row]):int(ygrid[row+1])+1,int(xgrid[col]):int(xgrid[col+1])+1]
            if not patch.any(): continue
            for corners in (((row,col),(row,col+1),(row+1,col)),((row,col+1),(row+1,col+1),(row+1,col))):
                uv=np.array([vertices[p] for p in corners])
                xy=np.array([moved[p]*2 for p in corners])
                xmin,ymin=np.maximum(np.floor(xy.min(axis=0)).astype(int),0)
                xmax,ymax=np.minimum(np.ceil(xy.max(axis=0)).astype(int),[W*2-1,H*2-1])
                if xmax<xmin or ymax<ymin: continue
                gx,gy=np.meshgrid(np.arange(xmin,xmax+1)+.5,np.arange(ymin,ymax+1)+.5)
                v0,v1=xy[1]-xy[0],xy[2]-xy[0]
                det=v0[0]*v1[1]-v0[1]*v1[0]
                if abs(det)<1e-6: continue
                dx,dy=gx-xy[0,0],gy-xy[0,1]
                b=(dx*v1[1]-dy*v1[0])/det
                c=(v0[0]*dy-v0[1]*dx)/det
                inside=(b>=-1e-6)&(c>=-1e-6)&(b+c<=1+1e-6)
                u=uv[0]+b[:,:,None]*(uv[1]-uv[0])+c[:,:,None]*(uv[2]-uv[0])
                ux,uy=np.clip(u[:,:,0],0,W-1),np.clip(u[:,:,1],0,H-1)
                ix,iy=ux.astype(int),uy.astype(int)
                fx,fy=(ux-ix)[:,:,None],(uy-iy)[:,:,None]
                jx,jy=np.minimum(ix+1,W-1),np.minimum(iy+1,H-1)
                sampled=(pixels[iy,ix]*(1-fx)*(1-fy)+pixels[iy,jx]*fx*(1-fy)
                    +pixels[jy,ix]*(1-fx)*fy+pixels[jy,jx]*fx*fy)
                patch=raster[ymin:ymax+1,xmin:xmax+1]
                patch[inside]=sampled[inside]+patch[inside]*(1-sampled[inside,3:4])
    raster=raster.reshape(H,2,W,2,4).mean(axis=(1,3))
    raster[:,:,:3]/=np.maximum(raster[:,:,3:4],1e-10)
    image=Image.fromarray(np.clip(np.rint(raster*255),0,255).astype('uint8'))
    alpha=image.getchannel('A')
    clean=alpha.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
    clean=clean.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    pixels=np.asarray(image).copy()
    sy,sx=np.nonzero(pixels[:,:,3]>100)
    for y,x in zip(*np.nonzero((np.asarray(clean)>5)&(pixels[:,:,3]<20))):
        nearest=np.argmin((sx-x)**2+(sy-y)**2)
        pixels[y,x,:3]=pixels[sy[nearest],sx[nearest],:3]
    pixels[:,:,3]=np.asarray(clean)
    if arm_shape:
        support=Image.new('L',(W*4,H*4))
        draw=ImageDraw.Draw(support)
        for k,radius in enumerate([12,13]):
            a,b=np.asarray(targets[k])*4,np.asarray(targets[k+1])*4
            draw.line([tuple(a),tuple(b)],fill=255,width=radius*8)
            for x,y in [a,b]:
                r=radius*4;draw.ellipse((x-r,y-r,x+r,y+r),fill=255)
        support=np.asarray(support.resize(source.size,Image.Resampling.LANCZOS))
        sy,sx=np.nonzero((pixels[:,:,3]>100)&(support>100))
        for y,x in zip(*np.nonzero((support>0)&(pixels[:,:,3]<100))):
            nearest=np.argmin((sx-x)**2+(sy-y)**2)
            pixels[y,x,:3]=pixels[sy[nearest],sx[nearest],:3]
        pixels[:,:,3]=support
    return Image.fromarray(pixels)

prior_reports=json.loads((OUT/'joint_trajectories.json').read_text())
lead=np.asarray(prior_reports[6]['RIGHT'][2])-prior_reports[6]['RIGHT'][0]
rear=np.asarray(prior_reports[14]['RIGHT'][2])-prior_reports[14]['RIGHT'][0]
ankle_center=(lead+rear)/2
ankle_radius=(lead-rear)/2

def chain(frame,hip):
    phase=(frame-6)*math.pi/8
    vector=ankle_center+ankle_radius*math.cos(phase)+[0,22*math.sin(phase)]
    distance=np.linalg.norm(vector)
    along=(distance**2+54**2-62**2)/(2*distance)
    bend=math.sqrt(54**2-along**2)
    knee=np.asarray(hip)+vector/distance*along+np.array([vector[1],-vector[0]])/distance*bend
    ankle=np.asarray(hip)+vector
    foot=math.radians(23.5-51.5*math.cos(phase)-20*math.sin(phase))
    toe=ankle+45*np.array([math.cos(foot),math.sin(foot)])
    return [hip,knee,ankle,toe]

def depth_mix(first,second,weight):
    a,b=np.asarray(first,dtype=float)/255,np.asarray(second,dtype=float)/255
    assert np.max(np.abs(a[:,:,3]-b[:,:,3]))<2/255
    alpha=a[:,:,3:4]*(1-weight)+b[:,:,3:4]*weight
    rgb=(a[:,:,:3]*a[:,:,3:4]*(1-weight)+b[:,:,:3]*b[:,:,3:4]*weight)/np.maximum(alpha,1e-10)
    return Image.fromarray(np.clip(np.rint(np.concatenate([rgb,alpha],axis=2)*255),0,255).astype('uint8'))

def leg_composite(left,right,frame):
    weight=np.clip(.5-.85*math.cos((frame-6)*math.pi/8),0,1)
    return depth_mix(Image.alpha_composite(left,right),Image.alpha_composite(right,left),weight)

RIGHT_JOINTS=[(122,183),(166,213),(193,268),(233,248)]
LEFT_JOINTS=[(117,184),(80,220),(30,254),(46,296)]
if '--polish-legs' in sys.argv:
    import hashlib
    anchor_hashes={f'{side}_{frame:02}.png':hashlib.sha256((OUT/f'{side}_{frame:02}.png').read_bytes()).hexdigest()
        for side in ['LEFT','RIGHT'] for frame in [6,14]}
    frames=[]; qa_frames=[]; reports=[]
    for frame in range(16):
        right=chain(frame,(122,183))
        left=chain(frame+8,(122,185))
        if frame in (6,14):
            right_image=Image.open(OUT/f'RIGHT_{frame:02}.png').convert('RGBA')
            left_image=Image.open(OUT/f'LEFT_{frame:02}.png').convert('RGBA')
            assert np.allclose(right[:3],prior_reports[frame]['RIGHT'])
            assert np.allclose(left[:3],prior_reports[frame]['LEFT'])
        else:
            right_image=deform(right_texture,RIGHT_JOINTS,right)
            left_image=deform(left_texture,LEFT_JOINTS,left)
            right_image.save(OUT/f'RIGHT_{frame:02}.png')
            left_image.save(OUT/f'LEFT_{frame:02}.png')
        image=Image.alpha_composite(leg_composite(left_image,right_image,frame),body)
        image.save(OUT/f'legs_only_{frame:02}.png')
        frames.append(image)
        qa=image.copy(); draw=ImageDraw.Draw(qa)
        for joints,color in ((left,'#ff4545'),(right,'#479aff')):
            draw.line([tuple(p) for p in joints[:3]],fill=color,width=3)
            for x,y in joints[:3]: draw.ellipse((x-3,y-3,x+3,y+3),fill=color)
        for layer,color in ((left_image,(255,69,69)),(right_image,(71,154,255))):
            a=layer.getchannel('A').point(lambda value:255 if value>64 else 0)
            edge=np.asarray(a)>np.asarray(a.filter(ImageFilter.MinFilter(3)))
            outline=np.zeros((H,W,4),dtype='uint8'); outline[edge]=[*color,255]
            qa=Image.alpha_composite(qa,Image.fromarray(outline))
        qa_frames.append(qa)
        reports.append({'frame':frame,'RIGHT':[list(map(float,p)) for p in right[:3]],
            'LEFT':[list(map(float,p)) for p in left[:3]]})
else:
    frames=[Image.open(OUT/f'legs_only_{k:02}.png').convert('RGBA') for k in range(16)]
    reports=json.loads((OUT/'joint_trajectories.json').read_text())
    qa_frames=[]
    for k,image in enumerate(frames):
        qa=image.copy(); draw=ImageDraw.Draw(qa)
        for side,color in [('LEFT','#ff4545'),('RIGHT','#479aff')]:
            joints=reports[k][side]
            draw.line([tuple(p) for p in joints],fill=color,width=3)
            layer=Image.open(OUT/f'{side}_{k:02}.png')
            a=layer.getchannel('A').point(lambda value:255 if value>64 else 0)
            edge=np.asarray(a)>np.asarray(a.filter(ImageFilter.MinFilter(3)))
            outline=np.zeros((H,W,4),dtype='uint8')
            outline[edge]=[255,69,69,255] if side=='LEFT' else [71,154,255,255]
            qa=Image.alpha_composite(qa,Image.fromarray(outline))
        qa_frames.append(qa)

def sheet(images,indices,name,columns=8,zoom=1):
    canvas=Image.new('RGB',(W*columns,(H+22)*math.ceil(len(indices)/columns)),'#181818')
    draw=ImageDraw.Draw(canvas)
    for position,index in enumerate(indices):
        x,y=position%columns*W,position//columns*(H+22)
        draw.text((x+8,y+5),f'R{index+1:02}',fill='white')
        canvas.paste(images[index],(x,y+22),images[index])
    if zoom!=1: canvas=canvas.resize((canvas.width*zoom,canvas.height*zoom))
    canvas.save(OUT/name)

sheet(frames,list(range(16)),'legs_only_16.png')
sheet(frames,list(range(8)),'RIGHT_half.png')
sheet(frames,list(range(8,16)),'LEFT_half.png')
sheet(frames,[6,14],'max_forward.png',columns=2,zoom=2)
sheet(qa_frames,list(range(16)),'identity_16.png')
if '--polish-legs' in sys.argv:
    (OUT/'joint_trajectories.json').write_text(json.dumps(reports,indent=2))
    assert all(hashlib.sha256((OUT/name).read_bytes()).hexdigest()==digest for name,digest in anchor_hashes.items())
    layers=[OUT/f'{side}_{k:02}.png' for side in ['LEFT','RIGHT'] for k in range(16)]
    (OUT/'frozen_leg_hashes.json').write_text(json.dumps({f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in layers+[OUT/'joint_trajectories.json']},indent=2))

if '--arms' in sys.argv:
    def capsule(a,b,radius):
        a,b=np.asarray(a,float),np.asarray(b,float)
        points=np.stack([xx,yy],axis=-1); v=b-a
        t=np.clip(np.sum((points-a)*v,axis=-1)/np.dot(v,v),0,1)
        return np.linalg.norm(points-a-t[:,:,None]*v,axis=-1)<radius
    near_joints=[(130,128),(90,148),(62,170)]
    far_joints=[(164,143),(180,160),(218,159)]
    near_mask=capsule(*near_joints[:2],12)|capsule(*near_joints[1:],13)
    far_mask=capsule(*far_joints[:2],12)|capsule(*far_joints[1:],13)
    torso_points=[(141,112),(165,125),(167,134),(157,158),(145,180),(144,187),
        (129,199),(99,189),(95,176),(108,152),(119,139),(124,119)]
    torso=polygon(torso_points)
    shoulder=((xx-131)/13)**2+((yy-128)/11)**2<=1
    head_mask=(yy<120)|((xx>138)&(yy<124))
    frozen_mask=body_mask & (torso|shoulder|pelvis|head_mask)
    coverage=Image.new('L',(W*4,H*4))
    draw=ImageDraw.Draw(coverage)
    draw.polygon([(x*4,y*4) for x,y in torso_points],fill=255)
    draw.ellipse((118*4,117*4,144*4,139*4),fill=255)
    draw.ellipse((95*4,165*4,147*4,201*4),fill=255)
    coverage=np.asarray(coverage.resize(source.size,Image.Resampling.LANCZOS)).copy()
    coverage[head_mask]=255
    pixels=np.asarray(source).copy()
    pixels[:,:,3]=np.minimum(pixels[:,:,3],coverage)
    pixels[~body_mask]=0
    frozen=Image.fromarray(pixels)
    frozen.save(OUT/'frozen_body_without_exposed_arms.png')
    def complete_arm(mask):
        pixels=np.asarray(masked(mask)).copy()
        sy,sx=np.nonzero((pixels[:,:,3]>200)&mask)
        for y,x in zip(*np.nonzero(mask&(pixels[:,:,3]<200))):
            nearest=np.argmin((sx-x)**2+(sy-y)**2)
            pixels[y,x]=pixels[sy[nearest],sx[nearest]]
        return Image.fromarray(pixels)
    near_texture=complete_arm(near_mask)
    far_texture=complete_arm(far_mask)
    arm_frames=[]
    arm_reports=[]
    for frame in range(16):
        swing=math.asin(.95*math.cos((frame-6)*math.pi/8))/math.asin(.95)
        arm_layers=[]
        arm_chains=[]
        for side,pivot,phase,texture,joints in (
            ('LEFT',(124,131),-swing,far_texture,far_joints),
            ('RIGHT',(130,128),swing,near_texture,near_joints)):
            upper_angle=math.radians(100+49.5*phase)
            lower_angle=math.radians(41.5+71*phase)
            upper_length=44
            lower_length=36
            elbow=np.asarray(pivot)+upper_length*np.array([math.cos(upper_angle),math.sin(upper_angle)])
            wrist=elbow+lower_length*np.array([math.cos(lower_angle),math.sin(lower_angle)])
            target=[pivot,elbow,wrist]
            arm_layers.append(deform(texture,joints,target,arm_shape=True))
            arm_chains.append({'side':side,'shoulder':list(pivot),
                'elbow':elbow.tolist(),'wrist':wrist.tolist()})
        left_leg=Image.open(OUT/f'LEFT_{frame:02}.png').convert('RGBA')
        right_leg=Image.open(OUT/f'RIGHT_{frame:02}.png').convert('RGBA')
        legs=leg_composite(left_leg,right_leg,frame)
        right_front=Image.alpha_composite(Image.alpha_composite(Image.alpha_composite(legs,arm_layers[0]),frozen),arm_layers[1])
        left_front=Image.alpha_composite(Image.alpha_composite(Image.alpha_composite(legs,arm_layers[1]),frozen),arm_layers[0])
        depth=np.clip(.5+.85*math.cos((frame-6)*math.pi/8),0,1)
        image=depth_mix(right_front,left_front,depth)
        result=np.asarray(image).copy()
        result[head_mask]=np.asarray(source)[head_mask]
        image=Image.fromarray(result)
        image.save(OUT/f'frame_{frame:02}.png')
        arm_frames.append(image)
        protected=(np.asarray(frozen)[:,:,3]==255)&(np.asarray(arm_layers[1])[:,:,3]==0)&(np.asarray(arm_layers[0])[:,:,3]==0)
        protected &= ~head_mask
        body_diff=int(np.any(result!=np.asarray(source),axis=2)[protected].sum())
        head_diff=int(np.any(result!=np.asarray(source),axis=2)[head_mask].sum())
        assert body_diff==0 and head_diff==0
        alpha=result[:,:,3]
        assert not (alpha[0].any() or alpha[-1].any() or alpha[:,0].any() or alpha[:,-1].any())
        arm_reports.append({'frame':frame,'arms':arm_chains,
            'head_pixel_diff':head_diff,'body_pixel_diff_outside_arm_overlap':body_diff})
    sheet(arm_frames,list(range(16)),'full_body_16.png')
    sheet(arm_frames,[6,7,8,9,10,11,12,13,14],'RIGHT_half.png',columns=9)
    sheet(arm_frames,[14,15,0,1,2,3,4,5,6],'LEFT_half.png',columns=9)
    sheet(arm_frames,[6,14],'max_forward.png',columns=2,zoom=2)
    sheet(arm_frames,[6,7,8,9,14,15,0,1],'cycle_seams.png',columns=4)
    arms=Image.new('RGB',(1600,132),'#181818')
    draw=ImageDraw.Draw(arms)
    for position,frame in enumerate(range(0,16,2)):
        part=arm_frames[frame].crop((30,110,230,220))
        draw.text((position*200+8,5),f'R{frame+1:02}',fill='white')
        arms.paste(part,(position*200,22),part)
    arms.resize((3200,264)).save(OUT/'arm_states.png')
    arms_pair=Image.new('RGB',(400,132),'#181818')
    draw=ImageDraw.Draw(arms_pair)
    for position,frame in enumerate([6,14]):
        part=arm_frames[frame].crop((30,110,230,220))
        draw.text((position*200+8,5),f'R{frame+1:02}',fill='white')
        arms_pair.paste(part,(position*200,22),part)
    arms_pair.resize((800,264)).save(OUT/'arms_R07_R15.png')
    final_qa=[]
    for original,qa in zip(arm_frames,qa_frames):
        pixels=np.asarray(original).copy(); overlay=np.asarray(qa)
        colored=((overlay[:,:,:3]==[255,69,69]).all(axis=2)
            |(overlay[:,:,:3]==[71,154,255]).all(axis=2))
        pixels[colored]=overlay[colored]
        final_qa.append(Image.fromarray(pixels))
    sheet(final_qa,list(range(16)),'identity_16.png')
    def path_overlay(kind,filename):
        canvas=Image.new('RGB',(512,364),'#181818')
        draw=ImageDraw.Draw(canvas)
        for column,(side,color,anchor) in enumerate([('LEFT','#ff4545',14),('RIGHT','#479aff',6)]):
            canvas.paste(arm_frames[anchor],(column*256,22),arm_frames[anchor])
            draw.text((column*256+8,5),side+' '+kind,fill=color)
            if kind=='arm':
                joints=np.asarray([[a[key] for key in ['shoulder','elbow','wrist']]
                    for row in arm_reports for a in row['arms'] if a['side']==side])
                indices=[1,2]
            else:
                joints=np.asarray([row[side] for row in reports])
                indices=[2] if kind=='ankle' else [1,2]
            for joint_index in indices:
                points=[(column*256+x,22+y) for x,y in joints[:,joint_index]]
                draw.line(points+[points[0]],fill=color,width=2 if joint_index==2 else 1)
                for frame,(x,y) in enumerate(points):
                    draw.ellipse((x-2,y-2,x+2,y+2),fill=color)
                    if joint_index==2 and frame%2==0:
                        draw.text((x+3,y-10),str(frame+1),fill=color)
        canvas.save(OUT/filename)
    path_overlay('leg','leg_joint_paths.png')
    path_overlay('ankle','ankle_paths.png')
    path_overlay('arm','arm_paths.png')
    (OUT/'arm_trajectories.json').write_text(json.dumps(arm_reports,indent=2))
    for frame in range(8):
        assert np.allclose(np.asarray(reports[frame]['RIGHT'])[:,:1],np.asarray(reports[frame+8]['LEFT'])[:,:1])
    validation={'frame_count':16,'cycle_ms':860,'head_pixel_diff':0,
        'body_pixel_diff_outside_arm_overlap':0,'bilateral_phase_offset':8,
        'RIGHT_max_forward_frame':'R7','LEFT_max_forward_frame':'R15',
        'RIGHT_ankle_forward_px':reports[6]['RIGHT'][2][0]-122,
        'LEFT_ankle_forward_px':reports[14]['LEFT'][2][0]-122,
        'source':str(SOURCE),'canvas':[W,H],
        'shoulder_swing_degrees':49.5,'elbow_flex_variation_degrees':21.5,
        'arm_lengths':[44,36]}
    legs=np.asarray([row['RIGHT'] for row in reports])
    left_legs=np.asarray([row['LEFT'] for row in reports])
    leg_error=float(np.max(np.abs((left_legs-left_legs[:,:1])-np.roll(legs-legs[:,:1],8,axis=0))))
    assert leg_error<1e-8
    jumps=np.linalg.norm(np.roll(legs,-1,axis=0)-legs,axis=2)
    frame,joint=np.unravel_index(jumps.argmax(),jumps.shape)
    validation['leg_phase_relative_error_px']=leg_error
    validation['largest_adjacent_leg_jump']={'pair':f'R{frame+1:02}→R{(frame+1)%16+1:02}',
        'joint':['hip','knee','ankle'][joint],'distance_px':float(jumps[frame,joint])}
    compact=(np.abs(legs[:,2,0]-legs[:,0,0])<30)&(np.abs(left_legs[:,2,0]-left_legs[:,0,0])<30)
    run=longest=0
    for state in np.tile(compact,2):
        run=run+1 if state else 0;longest=max(longest,run)
    validation['compact_hold_frames']=min(longest,16)
    validation['passing_frames']=[f'R{k+1:02}' for k in np.nonzero(compact)[0]]
    arm_coords={side:np.asarray([[a[key] for key in ['shoulder','elbow','wrist']]
        for row in arm_reports for a in row['arms'] if a['side']==side]) for side in ['LEFT','RIGHT']}
    relative={side:values-values[:,:1] for side,values in arm_coords.items()}
    arm_error=float(np.max(np.abs(relative['LEFT']-np.roll(relative['RIGHT'],8,axis=0))))
    assert arm_error<1e-8
    arm_jumps=np.linalg.norm(np.roll(arm_coords['RIGHT'],-1,axis=0)-arm_coords['RIGHT'],axis=2)
    frame,joint=np.unravel_index(arm_jumps.argmax(),arm_jumps.shape)
    validation['arm_phase_relative_error_px']=arm_error
    validation['frozen_arm_frames']=int(np.sum(arm_jumps[:,2]<2))
    validation['largest_adjacent_arm_jump']={'pair':f'R{frame+1:02}→R{(frame+1)%16+1:02}',
        'joint':['shoulder','elbow','wrist'][joint],'distance_px':float(arm_jumps[frame,joint])}
    assert validation['compact_hold_frames']<=2 and validation['frozen_arm_frames']<=1
    import hashlib
    locks=json.loads((OUT/'frozen_leg_hashes.json').read_text())
    changed=[name for name,digest in locks.items()
        if name not in ['LEFT_half.png','RIGHT_half.png']
        and hashlib.sha256((OUT/name).read_bytes()).hexdigest()!=digest]
    assert not changed, changed
    validation['frozen_leg_layer_changes']=changed
    (OUT/'validation.json').write_text(json.dumps(validation,indent=2))
    if '--write' in sys.argv:
        for frame,image in enumerate(arm_frames):
            image.save(ROOT/f'assets/character/run_{frame:02}.png')
            compact=image.resize((128,171),Image.Resampling.LANCZOS)
            compact.save(OUT/f'dashboard_frame_{frame:02}.png')
            compact.save(ROOT/f'assets/character/dashboard_run_{frame:02}.png')
        durations=[50,50,60,50,60,50,50,60]*2
        gif=[]
        for image in arm_frames:
            bg=Image.new('RGB',source.size,'#181818'); bg.paste(image,mask=image.getchannel('A')); gif.append(bg)
        gif[0].save(OUT/'cycle_860ms.gif',save_all=True,append_images=gif[1:],duration=durations,loop=0)
        (OUT/'native_export.json').write_text(json.dumps(validation,indent=2))
        print('Exported 16 native RUN and Dashboard frames; 860 ms loop.')
print('Saved static evidence.' if '--write' in sys.argv else 'Saved static evidence; runtime assets untouched.')
