import cv2, numpy as np, json
from PIL import Image
U='/root/.claude/uploads/7d006b6b-5ba6-59a7-960e-a8220b91ea7c/'
SS=4  # supersampling for anti-aliased geometric edges
def aa_circle(h,w,cx,cy,r):
    m=np.zeros((h*SS,w*SS),np.uint8); cv2.circle(m,(int(cx*SS),int(cy*SS)),int(r*SS),255,-1,cv2.LINE_AA)
    return cv2.resize(m,(w,h),interpolation=cv2.INTER_AREA).astype(np.float32)/255
def rects(h,w,rs):
    m=np.zeros((h,w),np.float32)
    for (a,b,c,d) in rs: m[b:d,a:c]=1.0
    return m
def build(cut_png, src_img, crop, outer, statue_box, panel_rects, clear_rects, out, scale, after_rgb=None):
    A=cv2.imread(cut_png,cv2.IMREAD_UNCHANGED); h,w=A.shape[:2]
    im=cv2.imread(U+src_img)[crop[1]:crop[3],crop[0]:crop[2]]
    if after_rgb is not None: im=after_rgb
    base=(A[...,3]>127).astype(np.float32)
    # statue: smooth the GrabCut outline (blur + re-threshold at 4x, then area-downsample = AA edge)
    sx0,sy0,sx1,sy1=statue_box
    st=np.zeros_like(base); st[sy0:sy1,sx0:sx1]=base[sy0:sy1,sx0:sx1]
    # statue is pale stone: drop dark / saturated-red background pixels the cut kept around its head and back
    hsv=cv2.cvtColor(im,cv2.COLOR_BGR2HSV).astype(np.float32)
    bad=(hsv[...,2]<42)|((hsv[...,1]>105)&((hsv[...,0]<10)|(hsv[...,0]>165)))
    bad=cv2.morphologyEx(bad.astype(np.uint8),cv2.MORPH_OPEN,np.ones((3,3),np.uint8)).astype(bool)
    top=np.zeros_like(bad); top[:int(h*0.72),:]=True        # keep the dark crevices of the rock base
    st[bad & top]=0
    st=cv2.morphologyEx(st,cv2.MORPH_OPEN,np.ones((5,5),np.uint8))
    n,lab,stt,_=cv2.connectedComponentsWithStats((st>0).astype(np.uint8))
    if n>1:
        keep=[i for i in range(1,n) if stt[i,cv2.CC_STAT_AREA]>2500]
        st=np.isin(lab,keep).astype(np.uint8)
    # fill interior holes (stone shading) so only the outside silhouette is trimmed
    cs,_=cv2.findContours((st>0).astype(np.uint8),cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE)
    filled=np.zeros(st.shape,np.uint8); cv2.drawContours(filled,cs,-1,1,-1)
    st=filled.astype(np.float32)
    big=cv2.resize(st,(w*SS,h*SS),interpolation=cv2.INTER_LINEAR)
    big=cv2.GaussianBlur(big,(0,0),2.2*SS)
    big=(big>0.5).astype(np.float32)
    st=cv2.resize(big,(w,h),interpolation=cv2.INTER_AREA)
    cx,cy,r=outer
    ring=aa_circle(h,w,cx,cy,r)
    pan=rects(h,w,panel_rects)
    alpha=np.maximum.reduce([st,ring,pan])
    # rock/base under the statue and ring foot keeps GrabCut, smoothed, only in the bottom band
    foot=np.zeros_like(base); foot[int(h*0.80):, :]=base[int(h*0.80):, :]
    foot=cv2.GaussianBlur(foot,(0,0),1.5); alpha=np.maximum(alpha,np.clip((foot-0.5)*2.5+0.5,0,1)*(foot>0.15))
    for (a,b,c,d) in clear_rects: alpha[b:d,a:c]=np.minimum(alpha[b:d,a:c], np.maximum(ring[b:d,a:c],st[b:d,a:c]))
    rgba=np.dstack([cv2.cvtColor(im,cv2.COLOR_BGR2RGB) if after_rgb is None else cv2.cvtColor(im,cv2.COLOR_BGR2RGB),(alpha*255).astype(np.uint8)])
    # un-premultiply fringe: pull edge colours from the interior so no background halo
    pil=Image.fromarray(rgba,'RGBA')
    tw,th=round(w*scale),round(h*scale)
    pil=pil.resize((tw,th),Image.LANCZOS)
    pil.save(out); return (w,h),(tw,th)
# left: crop (0,95)-(1284,560). Disc (302,248-95=153? ) -> careful: crop coords
L=build('left_cut.png','901b1cb0-image.jpg',(0,95,1284,560),outer=(304,250,198),
    statue_box=(0,0,215,465), panel_rects=[(500,210,1160,465),(1160,398,1284,465)],
    clear_rects=[(215,0,1284,208)], out='hud_left.png', scale=0.465)
R0=cv2.imread('hud_right.png',cv2.IMREAD_UNCHANGED)  # keeps blanked icons/letters
R=build('right_cut.png','848d332e-image.jpg',(0,170,1284,612),outer=(999,233,182),
    statue_box=(1120,0,1284,442), panel_rects=[(98,196,830,442),(0,390,98,442)],
    clear_rects=[(0,0,1120,194)], out='hud_right_v2.png', scale=0.505, after_rgb=R0[...,:3])
print(L,R)
