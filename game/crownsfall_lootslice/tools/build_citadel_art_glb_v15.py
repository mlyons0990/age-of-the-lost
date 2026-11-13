#!/usr/bin/env python3
"""Build a reproducible, clean Godot-ready AOTL Citadel gateway GLB.

A physically aligned, independent fallback art model (NOT an export of Higgsfield
Blender revision 3).  All vertex positions are in Godot-compatible metres:
X=lateral, Y=up, Z=progress north from foot of the nine-tread staircase.

Produces an art-only GLB: no duplicate gameplay physics, navmesh, cameras, lights,
NPCs or save systems. Separate 3D collision comes from Phase 12's gated proxy.

Install: pip install trimesh numpy
Run: python tools/build_citadel_art_glb_v15.py --output assets/25d/citadel/AOTL_Citadel_ArtFallback_v15.glb
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
import numpy as np
import trimesh
from trimesh.visual.material import PBRMaterial

REVISION = 'AOTL_Citadel_ArtFallback_v15'
STEP_COUNT = 9
STEP_RUN_M = 1.0
STEP_RISE_M = 0.2
STAIR_WIDTH_M = 7.5
UPPER_Y_M = STEP_COUNT * STEP_RISE_M
HALF_CLEAR_ARCH_M = 4.05
ARCH_SPRING_M = 4.14
ARCH_APEX_M = 6.05
ARCH_PROFILE_POWER = 0.77
GATE_Z_M = 12.25
COLORS = {
    'limestone': (0.78, 0.73, 0.65, 1.0),
    'sunlit': (0.88, 0.82, 0.72, 1.0),
    'warm_shadow': (0.67, 0.63, 0.58, 1.0),
    'ivory_highlight': (0.95, 0.89, 0.79, 1.0),
    'warm_brass': (0.66, 0.50, 0.25, 1.0),
    'dark_brass': (0.29, 0.22, 0.14, 1.0),
    'royal_blue': (0.035, 0.105, 0.36, 1.0),
    'royal_azure': (0.08, 0.22, 0.45, 1.0),
    'foliage': (0.25, 0.40, 0.21, 1.0),
    'foliage_dark': (0.15, 0.27, 0.16, 1.0),
    'flower_cream': (0.96, 0.91, 0.73, 1.0),
    'flower_white': (0.99, 0.98, 0.91, 1.0),
    'wood': (0.29, 0.19, 0.11, 1.0),
}


def material(name: str, color: tuple[float, float, float, float]) -> PBRMaterial:
    return PBRMaterial(name=f'AOTL_MAT_{name}', baseColorFactor=color,
                       metallicFactor=0.45 if 'brass' in name else 0.0,
                       roughnessFactor=0.46 if 'brass' in name else 0.87,
                       doubleSided='blue' in name)


class Sculpt:
    def __init__(self):
        self.scene = trimesh.Scene(base_frame='CITADEL_Local_Root')
        self.nodes = []
        self.materials = {n: material(n, col) for n, col in COLORS.items()}

    def add(self, mesh: trimesh.Trimesh, name: str, tone: str) -> None:
        if name in self.nodes:
            raise ValueError(f'duplicate art object {name}')
        mesh.process(validate=True)
        mesh.fix_normals()
        mesh.visual = trimesh.visual.TextureVisuals(material=self.materials[tone])
        self.scene.add_geometry(mesh, geom_name=name, node_name=name)
        self.nodes.append(name)

    def box(self, name: str, center, size, tone='limestone') -> None:
        mesh = trimesh.creation.box(extents=size)
        mesh.apply_translation(center)
        self.add(mesh, name, tone)

    def ico(self, name: str, center, radius, tone, scale=(1., 1., 1.)) -> None:
        mesh = trimesh.creation.icosphere(subdivisions=1, radius=radius)
        mesh.apply_scale(np.asarray(scale, dtype=float))
        mesh.apply_translation(center)
        self.add(mesh, name, tone)

    def prism(self, name, vertices, faces, tone) -> None:
        mesh = trimesh.Trimesh(vertices=np.asarray(vertices, dtype=float),
                               faces=np.asarray(faces, dtype=int), process=False)
        if not mesh.is_watertight:
            raise ValueError(f'Nonmanifold wedge {name}')
        self.add(mesh, name, tone)

    @staticmethod
    def arch_inside(x: float) -> float:
        ratio = min(1., max(0., abs(x) / HALF_CLEAR_ARCH_M))
        return UPPER_Y_M + ARCH_SPRING_M + (ARCH_APEX_M - ARCH_SPRING_M) * (1.-ratio**ARCH_PROFILE_POWER)

    def wedge(self, name, a, b, inner, outer, zfront, zback, tone):
        vertices = [(a, inner(a), zfront), (b, inner(b), zfront),
                    (b, outer(b), zfront), (a, outer(a), zfront),
                    (a, inner(a), zback), (b, inner(b), zback),
                    (b, outer(b), zback), (a, outer(a), zback)]
        faces = [(0, 2, 1), (0, 3, 2), (4, 5, 6), (4, 6, 7),
                 (0, 1, 5), (0, 5, 4), (1, 2, 6), (1, 6, 5),
                 (2, 3, 7), (2, 7, 6), (3, 0, 4), (3, 4, 7)]
        self.prism(name, vertices, faces, tone)

    def banner(self, name: str, x: float, zfront: float,
               top: float=5.8, bottom: float=3.65):
        rows, columns = 13, 9
        vertices = []
        for j in range(rows):
            v = j/(rows-1)
            y = top-(top-bottom)*v
            for k in range(columns):
                u = k/(columns-1)
                xoff = (u-.5) * 1.5 * (1-v*.22)
                z = zfront + .08*math.sin(u*math.pi*4.+v*2.)+.07*v
                vertices.append((x+xoff, y-.11*v*math.sin(math.pi*u), z))
        faces = []
        for j in range(rows-1):
            for k in range(columns-1):
                q = j*columns+k
                faces += [(q, q+1, q+columns+1),(q, q+columns+1, q+columns)]
        mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=False)
        self.add(mesh,name,'royal_blue')
        self.box(name+'_GoldSuspensionRod', (x,top+.08,zfront), (1.72,.09,.11),'warm_brass')
        self.box(name+'_GoldEmbroideredHem', (x,bottom+.07,zfront-.015), (1.12,.05,.085),'warm_brass')
        self.box(name+'_GoldCrestStalk',(x,(top+bottom)/2,zfront-.07),(.07,.67,.045),'warm_brass')
        self.box(name+'_GoldCrestCross',(x,(top+bottom)/2+.13,zfront-.077),(.42,.06,.05),'warm_brass')

    def build(self):
        self.box('ENV_LowerStoneCourt',(0.,-.235,-5.5),(19.2,.47,11.0),'limestone')
        self.box('ENV_UpperStoneCourt',(0.,.9,17.9),(19.2,1.8,18.0),'sunlit')
        for i in range(STEP_COUNT):
            k = i+1
            h = k*STEP_RISE_M
            z = i+0.5
            self.box(f'STAIR_Tread_{k:02}',(0,h/2,z),(STAIR_WIDTH_M,h,1.0),'sunlit' if i%2==0 else 'limestone')
            # Slim, lit nosing; not dark stair bars.
            self.box(f'STAIR_SunlitNosing_{k:02}',(0,h+.015,i+.025),(7.44,.032,.045),'ivory_highlight')
            for side in [-1,1]:
                x=side*4.17
                suffix='L' if side<0 else 'R'
                self.box(f'STAIR_OuterParapet_{k:02}_{suffix}',(x,h+.32,z),(.50,.64,1.),'limestone')
                self.box(f'STAIR_GoldCoping_{k:02}_{suffix}',(x,h+.665,z),(.56,.055,1.0),'warm_brass')
        # Upper landing floor flush with the last tread; extends under the gate.
        self.box('STAIR_UpperLanding',(0,.90,11.),(STAIR_WIDTH_M,1.80,4.02),'sunlit')
        for side in [-1,1]:
            suffix='L' if side<0 else 'R'
            x=side*4.18
            self.box(f'STAIR_UpperBalustrade_{suffix}',(x,2.12,11.03),(.55,.64,4.0),'limestone')
            self.box(f'STAIR_UpperGoldCoping_{suffix}',(x,2.47,11.03),(.60,.065,4.0),'warm_brass')
        for side in [-1,1]:
            suffix='L' if side<0 else 'R'
            x = side*4.69
            self.box(f'GATE_Pier_{suffix}',(x,UPPER_Y_M+2.07,GATE_Z_M),(1.12,4.14,1.45),'limestone')
            self.box(f'GATE_PierFoot_{suffix}',(x,2.05,GATE_Z_M),(1.52,.49,1.7),'warm_shadow')
            self.box(f'GATE_PierCapital_{suffix}',(x,UPPER_Y_M+4.00,GATE_Z_M),(1.42,.21,1.66),'ivory_highlight')
            self.box(f'GATE_CapitalGoldInlay_{suffix}',(x,UPPER_Y_M+4.115,GATE_Z_M-.75),(1.40,.08,.08),'warm_brass')
            self.box(f'GATE_PierSideButtress_{suffix}',(x+side*.70,UPPER_Y_M+1.70,GATE_Z_M),(.72,3.4,1.75),'warm_shadow')
        n = 32
        for i in range(n):
            a = -HALF_CLEAR_ARCH_M+2*HALF_CLEAR_ARCH_M*i/n
            b = -HALF_CLEAR_ARCH_M+2*HALF_CLEAR_ARCH_M*(i+1)/n
            col = 'ivory_highlight' if i%8==0 else ('warm_shadow' if i%6==0 else 'limestone')
            self.wedge(f'GATE_GothicVoussoir_{i+1:02}',a,b,
                       self.arch_inside,lambda x:self.arch_inside(x)+.70,
                       GATE_Z_M-.75,GATE_Z_M+.75,col)
            self.wedge(f'GATE_FineStoneArchivolt_{i+1:02}',a,b,
                       lambda x:self.arch_inside(x)+.70,
                       lambda x:self.arch_inside(x)+.79,
                       GATE_Z_M-.84,GATE_Z_M-.65,'ivory_highlight')
        self.wedge('GATE_EngravedKeystone',-.27,.27,
                   self.arch_inside,lambda x:self.arch_inside(x)+.85,
                   GATE_Z_M-.87,GATE_Z_M-.77,'ivory_highlight')
        # Exterior stonehouse silhouettes and carving; keep path clear.
        for side in [-1,1]:
            suffix='L' if side<0 else 'R'
            x=side*8.30
            self.box(f'ENV_TerracePilaster_{suffix}',(x,4.20,17.60),(1.9,4.8,4.4),'limestone')
            self.box(f'ENV_TerraceCoping_{suffix}',(x,6.65,17.60),(2.15,.19,4.70),'warm_brass')
            self.box(f'ENV_PierWindowRecess_{suffix}',(x,4.08,15.345),(.75,1.9,.06),'royal_blue')
            self.box(f'ENV_WindowGoldMullion_{suffix}',(x,4.08,15.302),(.055,1.77,.075),'warm_brass')
            self.banner(f'DEC_RoyalBanner_{suffix}',x=side*6.1,zfront=GATE_Z_M-.78)
            for j in range(5):
                xx=side*4.69+((j-2)*.19)
                self.ico(f'GATE_CapitalFleur_{suffix}_{j}',(xx,6.03,GATE_Z_M-.87),.10,'ivory_highlight',(.78,1.35,.43))
        # Flower urns set well beyond the walkable 7.5m centre.
        for i,(x,z,ybase) in enumerate([(-6.1,-.8,0.),(6.1,-.8,0.),(-7.1,19.,1.8),(7.1,19.,1.8)]):
            self.box(f'DEC_FlowerPlanter_{i}',(x,ybase+.34,z),(1.45,.67,.85),'limestone')
            for j in range(7):
                frac = j/6.
                xoff=(frac-.5)*1.08
                zoff=.19*math.sin((j+1)*1.94)
                pos=(x+xoff,ybase+.78+.18*math.sin(j*2.2),z+zoff)
                self.ico(f'DEC_IvyBush_{i}_{j}',pos,.29,
                         'foliage' if j%2==0 else 'foliage_dark',(1.,1.22,.89))
                if j%2==0:
                    self.ico(f'DEC_WhiteBloom_{i}_{j}',
                             (pos[0],pos[1]+.19,pos[2]-.06),.08,
                             'flower_white' if j%4==0 else 'flower_cream')
        # Cast iron lantern towers — real geometry, non-gameplay.
        for i,x in enumerate([-7.15,7.15]):
            self.box(f'DEC_LampBase_{i}',(x,1.8,8.7),(.34,.36,.34),'dark_brass')
            self.box(f'DEC_LampPole_{i}',(x,3.3,8.7),(.10,2.75,.10),'dark_brass')
            self.box(f'DEC_LampHousing_{i}',(x,4.8,8.7),(.46,.67,.46),'warm_brass')
            self.box(f'DEC_LampRoof_{i}',(x,5.16,8.7),(.60,.13,.60),'dark_brass')
        return self.scene


def main() -> None:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',default='assets/25d/citadel/AOTL_Citadel_ArtFallback_v15.glb')
    parser.add_argument('--manifest',default='assets/25d/citadel/AOTL_Citadel_ArtFallback_v15.json')
    args=parser.parse_args()
    glb=Path(args.output);glb.parent.mkdir(parents=True,exist_ok=True)
    scene=Sculpt().build()
    glb.write_bytes(scene.export(file_type='glb'))
    manifest={
        'name':REVISION,'status':'reproducible_procedural_fallback_not_higgsfield_sculpt',
        'world_space':'X_lateral_Y_up_Z_north','base_origin':'bottom_of_stair_center',
        'tread_count':STEP_COUNT,'step_run_m':STEP_RUN_M,'step_rise_m':STEP_RISE_M,
        'stair_width_m':STAIR_WIDTH_M,'total_ascent_m':UPPER_Y_M,
        'arch_stones':32,'arch_aperture_m':HALF_CLEAR_ARCH_M*2,
        'gate_center_z_m':GATE_Z_M,'arch_spring_above_upper_floor_m':ARCH_SPRING_M,
        'arch_apex_above_upper_floor_m':ARCH_APEX_M,'arch_profile_power':ARCH_PROFILE_POWER,
        'nodes':len(scene.geometry),'glb_bytes':glb.stat().st_size,
        'glb_sha256':hashlib.sha256(glb.read_bytes()).hexdigest(),
        'has_gameplay_colliders':False,'has_player_or_npc_state':False,
        'artist_review':'not_approved','godot_runtime_validation':'pending',
        'source':'tools/build_citadel_art_glb_v15.py'
    }
    manifest_path=Path(args.manifest);manifest_path.parent.mkdir(parents=True,exist_ok=True)
    manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
    print('CITADEL V15 GENERATED',glb,glb.stat().st_size,'bytes',len(scene.geometry),'named meshes')
    print('sha256',manifest['glb_sha256'])

if __name__=='__main__': main()
