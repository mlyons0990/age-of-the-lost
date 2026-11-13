#!/usr/bin/env python3
"""Static Phase17 painted masonry QA. Checks art-only GLB geometry in world metre coordinates."""
import json, unittest, struct, hashlib
from pathlib import Path
import numpy as np
import trimesh

ROOT=Path(__file__).resolve().parents[1]
ASSET=ROOT/'assets/25d/citadel/AOTL_Citadel_MasonryArt_v17.glb'
MANIFEST=ASSET.with_suffix('.json')
class CitadelV17Checks(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.data=ASSET.read_bytes();cls.meta=json.loads(MANIFEST.read_text());cls.scene=trimesh.load(ASSET,force='scene')
  cls.nodes=set(cls.scene.graph.nodes_geometry)
  n=struct.unpack_from('<I',cls.data,12)[0]
  cls.gltf=json.loads(cls.data[20:20+n])
 def mesh(self,name):
  self.assertIn(name,self.nodes)
  tf,g=self.scene.graph.get(name)
  mesh=self.scene.geometry[g].copy();mesh.apply_transform(tf);return mesh
 def test_01_integrity_and_full_mesh_inventory(self):
  self.assertEqual(self.data[:4],b'glTF')
  self.assertEqual(len(self.data),self.meta['glb_bytes'])
  self.assertEqual(hashlib.sha256(self.data).hexdigest(),self.meta['glb_sha256'])
  self.assertEqual(len(self.nodes),self.meta['nodes'])
  self.assertGreaterEqual(len(self.nodes),1000)
 def test_02_authoritative_playback_and_art_only(self):
  self.assertFalse(self.meta['has_gameplay_colliders'])
  self.assertFalse(self.meta['has_player_or_npc_state'])
  self.assertFalse(self.meta['has_cameras'])
  for name in self.nodes:
   self.assertNotIn('Collision',name)
   self.assertNotIn('Navigation',name)
  self.assertEqual(self.meta['world_space'],'X_lateral_Y_up_Z_north')
 def test_03_orig_citadel_arch_and_nine_step_geometry(self):
  for step in range(1,10):
   mesh=self.mesh('STAIR_Tread_%02d'%step)
   lo,hi=mesh.bounds
   self.assertAlmostEqual(hi[1],step*.2,places=5)
   self.assertAlmostEqual(hi[0]-lo[0],7.5,places=5)
   self.assertAlmostEqual(hi[2]-lo[2],1.,places=5)
  self.assertAlmostEqual(self.mesh('STAIR_UpperLanding').bounds[1][1],1.8,places=5)
  self.assertAlmostEqual(self.mesh('ENV_UpperStoneCourt').bounds[1][1],1.8,places=5)
  for n in range(1,33):
   m=self.mesh('GATE_GothicVoussoir_%02d'%n)
   # UV seam vertices are intentionally split in glTF. Weld by position
   # on a throwaway copy before testing actual stone shell topology.
   m.merge_vertices(merge_tex=True)
   self.assertTrue(m.is_watertight)
 def test_04_real_surface_stones_and_nonblocking_relief(self):
  paving=[n for n in self.nodes if n.startswith('PAVE_lower') or n.startswith('PAVE_upper')]
  self.assertGreaterEqual(len(paving),300)
  for n in paving:
   m=self.mesh(n)
   self.assertLessEqual(m.bounds[1][1]-m.bounds[0][1],.03)
  for n in self.nodes:
   if n.startswith('ART_Niche_'):
    self.assertGreater(abs(self.mesh(n).bounds[:,0].mean()),7.5)
 def test_05_vibrant_but_no_path_crossing_planters_or_lanterns(self):
  props=[n for n in self.nodes if n.startswith(('ART_Stone_FlowerBox_','ART_Lantern_Pole_','ART_Fountain_Rim_'))]
  self.assertGreaterEqual(len(props),16)
  for n in props:
   m=self.mesh(n)
   self.assertGreaterEqual(min(abs(m.bounds[0][0]),abs(m.bounds[1][0])),3.75)
 def test_06_seamless_paint_materials_packed_in_binary(self):
  self.assertGreaterEqual(len(self.gltf.get('images',[])),4)
  materials=self.gltf.get('materials',[])
  self.assertGreaterEqual(len(materials),12)
  textured=[m for m in materials if m.get('pbrMetallicRoughness',{}).get('baseColorTexture')]
  self.assertGreaterEqual(len(textured),4)
  for mat in textured:
   self.assertLessEqual(mat.get('pbrMetallicRoughness',{}).get('metallicFactor',1),.1)
 def test_07_source_manifest_names_and_art_metrics(self):
  self.assertEqual(self.meta['status'],'art_candidate_not_canon_not_higgsfield_export')
  stats=self.meta['stats']
  self.assertGreaterEqual(stats['gothic_detail_segments'],100)
  self.assertGreaterEqual(stats['flowering_components'],300)
  self.assertGreaterEqual(stats['textured_stone_nodes'],600)
  self.assertEqual(stats['embedded_stone_textures'],4)
  self.assertEqual(self.meta['artist_review'],'pending')
 def test_08_no_nan_and_reasonable_render_cost(self):
  faces=0
  for mesh in self.scene.geometry.values():
   self.assertTrue(np.isfinite(mesh.vertices).all())
   faces+=len(mesh.faces)
  self.assertLess(faces,85000)
  self.assertLess(ASSET.stat().st_size,8_000_000)

if __name__=='__main__': unittest.main(verbosity=2)
