#!/usr/bin/env python3
"""Phase 17 | isolated, painterly-detail Crownsfall Citadel art-only GLB.

Extends the independently checked Phase15 GLB geometry; adds richer three-dimensional
Gothic carvings, laid masonry pavers, flowering vines, daylight glass and independent
texture variation. No collision, input, 2D nav, NPC/game state, or save changes.
The approved Phase11 painted game remains default. This is still an ART CANDIDATE.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
import random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import trimesh
from trimesh.visual.material import PBRMaterial
from trimesh.visual.texture import TextureVisuals
from build_citadel_art_glb_v15 import Sculpt as BaseSculpt, UPPER_Y_M

REV = "AOTL_Citadel_MasonryArt_v17"
SEED = 171113
COVERAGE_THRESHOLD = 200
TEX_SIZE = 512


def create_stone_texture(seed: int, tint: tuple[int, int, int]):
    """Deterministic aged stone color with multiscale, painterly brush-grain.

    Output is an embedded albedo/roughness-friendly tile rather than a dependency
    on external AI art or an untraceable texture from a browser screenshot.
    """
    rng = np.random.default_rng(seed)
    base = np.zeros((TEX_SIZE, TEX_SIZE), dtype=np.float32)
    for sz, weight in [(9, .42), (25, .26), (70, .21), (256, .11)]:
        sample = rng.random((sz, sz))
        small = Image.fromarray(np.uint8(sample * 255), mode="L")
        large = small.resize((TEX_SIZE, TEX_SIZE), Image.Resampling.BICUBIC)
        base += (np.asarray(large, dtype=np.float32)/255. - .5) * weight
    # Warm limestone instead of flat plastic, with readable hand-painted shading.
    grain = rng.normal(0, 1.5, (TEX_SIZE,TEX_SIZE))
    rgb = np.clip(np.array(tint)[None,None,:] + base[...,None]*70 + grain[...,None], 0,255).astype(np.uint8)
    img = Image.fromarray(rgb, 'RGB')
    paint = ImageDraw.Draw(img, 'RGBA')
    for i in range(360):
        x = int(rng.integers(0,TEX_SIZE))
        y = int(rng.integers(0,TEX_SIZE))
        ex = x+int(rng.integers(2,48))
        ey = y+int(rng.integers(-2,4))
        paint.line((x,y,ex,ey), fill=(100,78,60,int(rng.integers(5,17))), width=int(rng.integers(1,3)))
    # Sparse diagonal edge scratches; not black high-contrast stone outlines.
    for i in range(22):
        x = int(rng.integers(0,TEX_SIZE)); y=int(rng.integers(0,TEX_SIZE))
        paint.line((x,y,x+int(rng.integers(9,50)),y-int(rng.integers(0,8))), fill=(60,55,51,22),width=1)
    return img


class SculptV17(BaseSculpt):
    def __init__(self):
        super().__init__()
        self.rng = random.Random(SEED)
        self.terrace_stones = 0
        self.florals = 0
        self.gothic_details = 0
        self.water_tiles = 0
        self.tex_images = {
            'limestone': create_stone_texture(SEED+1,(213,201,178)),
            'sunlit': create_stone_texture(SEED+2,(226,215,195)),
            'warm_shadow':create_stone_texture(SEED+3,(185,170,152)),
            'ivory_highlight':create_stone_texture(SEED+4,(237,225,203)),
        }
        self.tex_materials = {
            k:PBRMaterial(name='AOTL_Painted_%s_v17'%k,
                          baseColorFactor=[255,255,255,255],
                          baseColorTexture=im,
                          metallicFactor=0.0,roughnessFactor=.91,
                          doubleSided=False)
            for k,im in self.tex_images.items()
        }
        from build_citadel_art_glb_v15 import COLORS
        COLORS.update({
            'gold_glass':(.97,.74,.32,1.0),
            'aqua':(.19,.55,.68,1.0),
            'deep_water':(.08,.24,.35,1.0),
            'blue_window':(.07,.20,.44,1.0),
            'carved_shadow':(.46,.43,.39,1.0),
            'copper':(.39,.29,.19,1.0),
            'stone_vein':(.83,.79,.72,1.0),
            'blossom_gold':(.95,.81,.30,1.0),
        })
        for k,col in COLORS.items():
            if k not in self.materials:
                self.materials[k]=PBRMaterial(name='AOTL_MAT_'+k,
                    baseColorFactor=col, metallicFactor=.38 if k=='copper' else 0,
                    roughnessFactor=.60 if k=='copper' else .84,
                    doubleSided=False)

    def paving(self):
        # Millimetre-thin overlays on original walkable planes. No gameplay collision.
        # Each tile has slightly randomized dimensions / warm hue while retaining a
        # predictable canonical center corridor, never covering the graded risers.
        for floor_name, y, za, zb in [('lower',0.,-10.7,-.20),('upper',1.8,9.0,26.65)]:
            for iz in range(int(math.ceil((zb-za)/1.22))):
                zc=za+iz*1.22+.61
                for ix in range(15):
                    # Cut ashlar stone in offset courses with close fine joints.
                    stagger=.45 if iz%2 else 0.0
                    xc = -8.6 + (ix+.50)*1.17 + stagger
                    if abs(xc)>9.3 or zc>zb+.15:continue
                    # Do not overlay +Z9..13 where raised landing owns the surface.
                    if floor_name=='upper' and zc<13.05 and abs(xc)<3.79:continue
                    tilt_y = (self.rng.random()-.5)*.005
                    top=y+.008+tilt_y
                    self.box('PAVE_%s_%02d_%02d'%(floor_name,iz,ix),
                        (xc,top-.006,zc),
                        (1.10,.012,1.14),
                        'sunlit' if (ix+iz)%3 else 'limestone')
                    self.terrace_stones+=1
        # Nine tread nosing strips remain thin/light; use inset ivy-stone motif.
        for step in range(1,10):
            y=step*.2+.008
            z=step-0.05
            for ix in range(-3,4):
                self.box('PAVE_Stair_Accent_%02d_%d'%(step,ix),
                    (ix*.95,y,z),(.60,.012,.065),'stone_vein')

    def arch_niches(self):
        # Additional real Gothic shallow niches on two exterior facades;
        # all structural framing sits beyond the 7.5m central stair clearance.
        for side in [-1,1]:
            direction='L' if side<0 else 'R'
            xcenter=side*8.1
            for j,z in enumerate([14.55,18.15,21.75]):
                # An actual relief recess, two narrow jambs and segmented roof.
                self.box('ART_Niche_IndigoBacking_%s_%d'%(direction,j),
                    (xcenter,4.30,z),(.83,1.95,.09),'blue_window')
                for s in [-1,1]:
                    self.box('ART_Niche_Column_%s_%d_%d'%(direction,j,s),
                       (xcenter+s*.54,4.28,z-.06),(.18,2.2,.26),'ivory_highlight')
                for segment in range(12):
                    a = -0.63 + segment*1.26/12.0
                    b = -0.63 + (segment+1)*1.26/12.0
                    def arc(q): return 5.30+.70*(1-(abs(q)/.63)**.77)
                    # Cross-section arch stones, mouth faces the near camera.
                    self.wedge('ART_Niche_GothicRib_%s_%d_%02d'%(direction,j,segment),
                        xcenter+a,xcenter+b,
                        lambda xx, origin=xcenter:arc(xx-origin),
                        lambda xx,origin=xcenter:arc(xx-origin)+.21,
                        z-.32,z-.04,'ivory_highlight')
                    self.gothic_details+=1
                self.box('ART_Niche_Gold_Mullion_%s_%d'%(direction,j),
                    (xcenter,4.30,z-.12),(.05,1.75,.08),'warm_brass')
                self.box('ART_Niche_Sill_%s_%d'%(direction,j),
                    (xcenter,3.27,z-.18),(1.43,.13,.46),'ivory_highlight')
            # Finials and sculpted capital blocks supporting the arch.
            for t in range(8):
                z=14.0+t*1.43
                x=side*9.18
                self.box('ART_Balustrade_Shaft_%s_%02d'%(direction,t),
                    (x,2.4,z),(.18,1.03,.18),'limestone')
                self.ico('ART_Balustrade_Finial_%s_%02d'%(direction,t),
                    (x,2.96,z),.17,'ivory_highlight',(1,.88,1))
                self.gothic_details+=2

    def flora_and_lighting(self):
        # Dense but finite bloom/bush grouping, along planted edges only.
        planting=[(-7.75,9.9,1.8),(7.75,9.9,1.8),
                  (-8.0,15.9,1.8),(8.0,15.9,1.8),
                  (-8.05,23.1,1.8),(8.05,23.1,1.8),
                  (-8.0,-4.3,0.0),(8.0,-4.3,0.0)]
        for idx,(x,z,y0) in enumerate(planting):
            self.box('ART_Stone_FlowerBox_%02d'%idx,(x,y0+.27,z),(.9,.53,1.2),'limestone')
            for branch in range(11):
                dx=self.rng.uniform(-.33,.33);dz=self.rng.uniform(-.48,.48)
                h=self.rng.uniform(.68,1.32)
                xx=x+dx;zz=z+dz
                self.ico('ART_IvyCanopy_%02d_%02d'%(idx,branch),
                    (xx,y0+h,zz),.29,'foliage' if branch%3 else 'foliage_dark',
                    (1.16,1.16,.88))
                if branch%2==0:
                    for petal in range(5):
                        a=petal*math.tau/5.
                        self.ico('ART_WhiteDaisy_%02d_%02d_%d'%(idx,branch,petal),
                          (xx+.09*math.cos(a),y0+h+.18,zz+.09*math.sin(a)),
                          .055,'flower_white' if petal%2 else 'flower_cream',
                          (1,.65,1))
                        self.florals+=1
                    self.ico('ART_DaisyGoldCenter_%02d_%02d'%(idx,branch),
                        (xx,y0+h+.20,zz),.05,'blossom_gold')
                self.florals+=1
        # Individually shaped bronze lanterns with restrained gold glass.
        for side in [-1,1]:
            for j,z in enumerate([14.1,21.6]):
                x=side*7.1
                nm='%s_%d'%('L' if side<0 else 'R',j)
                self.box('ART_Lantern_Plinth_'+nm,(x,2.0,z),(.40,.40,.40),'dark_brass')
                self.box('ART_Lantern_Pole_'+nm,(x,3.45,z),(.10,2.55,.10),'dark_brass')
                self.ico('ART_Lantern_AmberGlass_'+nm,(x,4.80,z),.35,'gold_glass',(.70,1.25,.7))
                self.box('ART_Lantern_Roof_'+nm,(x,5.25,z),(.61,.12,.61),'copper')
                self.ico('ART_Lantern_Crown_'+nm,(x,5.38,z),.13,'warm_brass',(1,1.5,1))
                for rx in [-1,1]:
                    self.box('ART_Lantern_CornerFrame_'+nm+('_L' if rx<0 else '_R'),
                        (x+rx*.24,4.78,z-.24),(.04,.65,.04),'warm_brass')
        # Compact side-water basins, out of the connected gameplay lane.
        for side in [-1,1]:
            suffix='L' if side<0 else 'R'
            for j,z in enumerate([13.7,19.4]):
                x=side*10.45
                self.box('ART_Fountain_Rim_%s_%d'%(suffix,j),
                    (x,1.82,z),(.98,.22,2.1),'limestone')
                self.box('ART_Fountain_Water_%s_%d'%(suffix,j),
                    (x,1.938,z),(.80,.018,1.9),'aqua')
                for ripple in range(5):
                    self.ico('ART_Fountain_SoftRipple_%s_%d_%d'%(suffix,j,ripple),
                        (x+self.rng.uniform(-.29,.29),1.952,z+self.rng.uniform(-.85,.85)),
                        .075,'stone_vein',(.9,.09,.5))
                    self.water_tiles+=1

    @staticmethod
    def _triplanar_uv(mesh:trimesh.Trimesh, density:float=0.7):
        # Unmerge shared vertices so each face may choose its own UV plane.
        mesh.unmerge_vertices()
        uv=np.zeros((len(mesh.vertices),2),dtype=float)
        normals=mesh.face_normals
        for fi,face in enumerate(mesh.faces):
            n=np.abs(normals[fi]);axis=int(np.argmax(n))
            xyz=mesh.vertices[face]
            if axis==1: uv[face]=xyz[:,[0,2]]*density
            elif axis==0: uv[face]=xyz[:,[2,1]]*density
            else:uv[face]=xyz[:,[0,1]]*density
        return uv

    def texture_existing_stone(self):
        updated=0
        for name in sorted(self.scene.graph.nodes_geometry):
            transform,key=self.scene.graph.get(name)
            mesh=self.scene.geometry[key]
            mat=getattr(mesh.visual,'material',None)
            old_name=getattr(mat,'name','')
            tone=old_name.replace('AOTL_MAT_','')
            if tone not in self.tex_materials:continue
            uv=self._triplanar_uv(mesh)
            mesh.visual=TextureVisuals(uv=uv,material=self.tex_materials[tone])
            updated+=1
        return updated

    def build(self):
        super().build()
        self.paving()
        self.arch_niches()
        self.flora_and_lighting()
        textured_count=self.texture_existing_stone()
        self.stats={
          'paving_stones':self.terrace_stones,
          'gothic_detail_segments':self.gothic_details,
          'flowering_components':self.florals,
          'water_highlights':self.water_tiles,
          'textured_stone_nodes':textured_count,
          'embedded_stone_textures':len(self.tex_images),
        }
        return self.scene


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--output',default='assets/25d/citadel/AOTL_Citadel_MasonryArt_v17.glb')
    p.add_argument('--manifest',default='assets/25d/citadel/AOTL_Citadel_MasonryArt_v17.json')
    p.add_argument('--textures',default='assets/25d/citadel/texture_source_v17')
    args=p.parse_args()
    art=SculptV17()
    scene=art.build()
    dst=Path(args.output);dst.parent.mkdir(parents=True,exist_ok=True)
    blob=scene.export(file_type='glb')
    dst.write_bytes(blob)
    texture_folder=Path(args.textures);texture_folder.mkdir(parents=True,exist_ok=True)
    for key,img in art.tex_images.items():img.save(texture_folder/f'AOTL_Stone_{key}_v17.png',optimize=True)
    meta={
        'name':REV,'status':'art_candidate_not_canon_not_higgsfield_export',
        'source':'tools/build_citadel_art_v17.py','derived_from':'Phase15 verified GLB art generator',
        'world_space':'X_lateral_Y_up_Z_north','base_origin':'bottom_of_stair_center',
        'nodes':len(scene.graph.nodes_geometry),'tread_count':9,
        'step_run_m':1.0,'step_rise_m':.2,'stair_width_m':7.5,
        'total_ascent_m':1.8,'arch_stones':32,'arch_aperture_m':8.1,
        'gate_center_z_m':12.25,'has_gameplay_colliders':False,
        'has_player_or_npc_state':False,'has_cameras':False,
        'artist_review':'pending','godot_runtime_validation':'pending',
        'glb_bytes':len(blob),'glb_sha256':hashlib.sha256(blob).hexdigest(),
        'texture_atlas_seed':SEED,'stats':art.stats,
        'warnings':['No full current Phase11 source synchronized',
                    'No final knight IK/occlusion or artist sign-off'],
    }
    mdst=Path(args.manifest);mdst.parent.mkdir(parents=True,exist_ok=True)
    mdst.write_text(json.dumps(meta,indent=2)+'\n')
    print('PHASE17 GENERATED',dst,len(blob),'bytes',len(scene.graph.nodes_geometry),'mesh nodes')
    print('sha256',meta['glb_sha256'],'details',art.stats)

if __name__=='__main__':main()
