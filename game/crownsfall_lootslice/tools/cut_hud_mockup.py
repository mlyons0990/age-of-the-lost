import cv2, numpy as np
U='/root/.claude/uploads/7d006b6b-5ba6-59a7-960e-a8220b91ea7c/'
def cut(src, crop, fg_circles, fg_rects, bg_rects, out, prob_rect):
    im=cv2.imread(U+src); x0,y0,x1,y1=crop; im=im[y0:y1,x0:x1].copy()
    h,w=im.shape[:2]
    mask=np.full((h,w),cv2.GC_BGD,np.uint8)
    px0,py0,px1,py1=[v-o for v,o in zip(prob_rect,(x0,y0,x0,y0))]
    mask[py0:py1,px0:px1]=cv2.GC_PR_FGD
    for (cx,cy,r) in fg_circles: cv2.circle(mask,(cx-x0,cy-y0),r,cv2.GC_FGD,-1)
    for (a,b,c,d) in fg_rects: mask[b-y0:d-y0,a-x0:c-x0]=cv2.GC_FGD
    for (a,b,c,d) in bg_rects: mask[max(0,b-y0):d-y0,max(0,a-x0):c-x0]=cv2.GC_BGD
    bgd=np.zeros((1,65),np.float64); fgd=np.zeros((1,65),np.float64)
    cv2.grabCut(im,mask,None,bgd,fgd,8,cv2.GC_INIT_WITH_MASK)
    m=np.where((mask==cv2.GC_FGD)|(mask==cv2.GC_PR_FGD),255,0).astype(np.uint8)
    # keep largest component, close small holes, soften edge
    n,lab,st,_=cv2.connectedComponentsWithStats(m)
    if n>1:
        k=1+np.argmax(st[1:,cv2.CC_STAT_AREA]); m=np.where(lab==k,255,0).astype(np.uint8)
    m=cv2.morphologyEx(m,cv2.MORPH_CLOSE,np.ones((7,7),np.uint8))
    m=cv2.GaussianBlur(m,(3,3),0)
    rgba=cv2.cvtColor(im,cv2.COLOR_BGR2BGRA); rgba[...,3]=m
    cv2.imwrite(out,rgba); return im
# LEFT: statue + orb + potion belt (+ start of the XP housing)
cut('901b1cb0-image.jpg',(0,95,1284,560),
    fg_circles=[(315,340,184),(112,150,26),(118,175,22)],
    fg_rects=[(505,312,1150,555),(1165,500,1284,555),(60,300,200,520),(55,195,150,300),(25,230,70,420),(85,175,140,215)],
    bg_rects=[(0,95,1284,105),(480,95,1284,290),(1160,95,1284,395),(1250,400,1284,490),(200,95,330,120)],
    out='left_cut.png', prob_rect=(0,100,1284,560))
# RIGHT: skill panel + orb + statue (+ end of the XP housing)
cut('848d332e-image.jpg',(0,170,1284,612),
    fg_circles=[(995,405,160)],
    fg_rects=[(110,375,825,605),(0,565,95,605),(1170,250,1260,520)],
    bg_rects=[(0,170,1284,180),(0,170,820,355),(0,360,90,555),(820,170,900,215),(1270,170,1284,190)],
    out='right_cut.png', prob_rect=(0,175,1284,612))
