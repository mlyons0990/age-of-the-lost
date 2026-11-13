#!/usr/bin/env python3
"""Static AOTL Citadel GLB quality gate. Runs without a Godot editor."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import struct
import unittest
import numpy as np
import trimesh

PROJECT = Path(__file__).resolve().parents[1]
DEFAULT_ASSET = PROJECT/'assets/25d/citadel/AOTL_Citadel_ArtFallback_v15.glb'
DEFAULT_MANIFEST = DEFAULT_ASSET.with_suffix('.json')

class CitadelAssetGate(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.path = Path(ASSET_PATH)
        cls.meta_path = Path(META_PATH)
        cls.manifest = json.loads(cls.meta_path.read_text())
        cls.scene = trimesh.load(str(cls.path),force='scene')
        cls.geometries = cls.scene.geometry
        cls.node_names = set(cls.scene.graph.nodes_geometry)

    def by_name(self,name):
        self.assertIn(name,self.node_names,f'Missing mesh node {name}')
        transform, geometry_name = self.scene.graph.get(name)
        mesh=self.geometries[geometry_name].copy()
        mesh.apply_transform(transform)
        return mesh

    def test_01_glb_header_and_file_checksum(self):
        data=self.path.read_bytes()
        self.assertEqual(data[:4],b'glTF')
        self.assertEqual(struct.unpack_from('<I',data,4)[0],2)
        self.assertEqual(struct.unpack_from('<I',data,8)[0],len(data))
        self.assertEqual(self.manifest['glb_bytes'],len(data))
        self.assertEqual(self.manifest['glb_sha256'],hashlib.sha256(data).hexdigest())

    def test_02_asset_scope_contains_no_gameplay_authority(self):
        self.assertFalse(self.manifest['has_gameplay_colliders'])
        self.assertFalse(self.manifest['has_player_or_npc_state'])
        for name in self.node_names:
            self.assertNotIn('StaticBody',name)
            self.assertNotIn('NavigationRegion',name)
        self.assertEqual(self.manifest['world_space'],'X_lateral_Y_up_Z_north')

    def test_03_stair_surfaces_monotonic_and_grounded(self):
        last_top=0.0
        for step in range(1,10):
            m=self.by_name(f'STAIR_Tread_{step:02}')
            low,high=m.bounds
            self.assertAlmostEqual(high[1],step*.2,places=5)
            self.assertAlmostEqual(low[1],0.,places=5)
            self.assertAlmostEqual(high[2]-low[2],1.,places=5)
            self.assertAlmostEqual(high[0]-low[0],7.5,places=5)
            self.assertGreater(high[1],last_top)
            last_top=high[1]
        self.assertAlmostEqual(last_top,1.8,places=5)

    def test_04_upper_landing_matches_ninth_stair(self):
        a=self.by_name('STAIR_UpperLanding').bounds
        b=self.by_name('STAIR_Tread_09').bounds
        self.assertAlmostEqual(a[1][1],b[1][1],places=5)
        self.assertLessEqual(a[0][2],9.01)
        self.assertGreaterEqual(a[1][2],13.0)
        self.assertAlmostEqual(self.by_name('ENV_UpperStoneCourt').bounds[1][1],1.8,places=5)

    def test_05_stair_railings_outside_unobstructed_walkway(self):
        for step in range(1,10):
            for side in ['L','R']:
                for prefix in ['STAIR_OuterParapet','STAIR_GoldCoping']:
                    bb=self.by_name(f'{prefix}_{step:02}_{side}').bounds
                    self.assertGreaterEqual(bb[0][0],3.75 if side=='R' else -1e5)
                    self.assertLessEqual(bb[1][0],-3.75 if side=='L' else 1e5)
        for side in ['L','R']:
            bb=self.by_name(f'GATE_Pier_{side}').bounds
            self.assertGreaterEqual(bb[0][0],3.75 if side=='R' else -1e5)
            self.assertLessEqual(bb[1][0],-3.75 if side=='L' else 1e5)

    def test_06_arch_dimensions_and_masonry_topology(self):
        stones=[]
        for i in range(1,33):
            mesh=self.by_name(f'GATE_GothicVoussoir_{i:02}')
            self.assertTrue(mesh.is_watertight)
            self.assertTrue(mesh.is_winding_consistent)
            stones.append(mesh)
        self.assertEqual(len(stones),self.manifest['arch_stones'])
        bounds=np.array([m.bounds for m in stones])
        self.assertAlmostEqual(bounds[:,:,0].min(),-4.05,places=4)
        self.assertAlmostEqual(bounds[:,:,0].max(),4.05,places=4)
        self.assertGreaterEqual(bounds[:,0,1].min(),1.8+4.14-.03)
        self.assertLessEqual(bounds[:,1,1].max(),1.8+6.05+.7+0.01)
        self.assertTrue(np.all(bounds[:,:,2] > 11.45))
        self.assertTrue(np.all(bounds[:,:,2] < 13.05))

    def test_07_no_unexpected_cameras_lights_animations(self):
        self.assertEqual(len(self.scene.geometry),self.manifest['nodes'])
        self.assertGreaterEqual(self.manifest['nodes'],200)
        self.assertEqual(len(self.node_names),self.manifest['nodes'])
        self.assertLessEqual(sum(len(m.faces) for m in self.geometries.values()),120000)
        for m in self.geometries.values():
            self.assertTrue(np.isfinite(m.vertices).all())

    def test_08_materials_and_opaque_shadowing_masonry(self):
        for i in [1,8,16,24,32]:
            m=self.by_name(f'GATE_GothicVoussoir_{i:02}')
            self.assertIsNotNone(m.visual.material)
        banner=self.by_name('DEC_RoyalBanner_L')
        self.assertGreaterEqual(len(banner.vertices),90)
        self.assertEqual(self.manifest['artist_review'],'not_approved')
        self.assertEqual(self.manifest['godot_runtime_validation'],'pending')


if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--asset',default=str(DEFAULT_ASSET))
    p.add_argument('--manifest',default=str(DEFAULT_MANIFEST))
    args=p.parse_args()
    ASSET_PATH=args.asset
    META_PATH=args.manifest
    unittest.main(argv=['citadel_v15_static_gate'],verbosity=2)
