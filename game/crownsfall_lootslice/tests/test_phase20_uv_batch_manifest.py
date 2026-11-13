#!/usr/bin/env python3
"""CI provenance/consistency test for Phase20 spatial UV-safe v9 batches.
Real Blender vertex and UV checks run against v9 inside Higgsfield separately.
"""
import json
import unittest
from pathlib import Path

DATA=Path(__file__).resolve().parents[1]/"data"
class Phase20UvBatches(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.v8=json.loads((DATA/"citadel_phase20_batch_manifest.json").read_text())
        cls.v9=json.loads((DATA/"citadel_phase20_uv_batch_v09_manifest.json").read_text())

    def test_revision_progression(self):
        self.assertEqual(self.v9["schema"],"aotl.citadel.phase20.uv_batch_v9.v1")
        self.assertEqual(self.v9["base_revision"],8)
        self.assertEqual(self.v9["sculpt_revision"],9)
        self.assertEqual(self.v8["sculpt_revision"],8)

    def test_mesh_count_and_triangles(self):
        opt=self.v9["optimizations"]
        self.assertEqual(opt["original_mesh_count"],571)
        self.assertEqual(opt["phase20_v8_mesh_count"],493)
        self.assertEqual(opt["phase20_v9_mesh_count"],309)
        self.assertEqual(opt["saved_mesh_objects_total"],262)
        self.assertAlmostEqual(opt["total_reduction_pct"],100*262/571,places=2)
        self.assertEqual(opt["triangles_preserved"],8820)
        self.assertEqual(opt["packed_textures"],2)

    def test_all_phase17_source_meshes_accounted(self):
        opt=self.v9["optimizations"]
        rows=self.v9["groups"]
        self.assertEqual(len(rows),34)
        self.assertEqual(len(self.v9["remaining_singletons"]),4)
        source=[name for group in rows for name in group["source_names"]]
        self.assertEqual(len(source),218)
        self.assertEqual(len(set(source)),218)
        self.assertTrue(all(x.startswith("PH17_") for x in source))
        self.assertEqual(len(set(source)|set(self.v9["remaining_singletons"])),222)
        self.assertEqual(opt["uv_detail_source_count"],222)
        self.assertEqual(opt["uv_groups"],34)
        self.assertEqual(opt["uv_singletons"],4)

    def test_uv_face_fingerprints_are_valid(self):
        rows=self.v9["groups"]
        names=[group["name"] for group in rows]
        self.assertEqual(len(names),len(set(names)))
        for group in rows:
            self.assertTrue(group["name"].startswith("PH20_UVBatch_"))
            self.assertGreaterEqual(len(group["source_names"]),2)
            self.assertEqual(len(group["uv_face_sha256"]),64)
            self.assertTrue(all(c in "0123456789abcdef" for c in group["uv_face_sha256"]))
            self.assertGreater(group["triangles"],0)
            self.assertGreater(group["vertices"],0)
            self.assertTrue(group["material"].startswith("MAT_"))
        self.assertTrue(self.v9["optimizations"]["uv_faces_verified_exactly"])

    def test_names_provenance_and_region_partitioning(self):
        rows=self.v9["groups"]
        self.assertTrue(any("_ClimbingIvy_" in r["name"] for r in rows))
        self.assertTrue(any("_WhiteBloom_" in r["name"] for r in rows))
        self.assertTrue(any("_Arch_" in r["name"] for r in rows))
        self.assertTrue(any("_StoneRail_" in r["name"] for r in rows))
        self.assertTrue(any("_L_B" in r["name"] for r in rows))
        self.assertTrue(any("_R_B" in r["name"] for r in rows))

    def test_isolated_qa_does_not_claim_live_game(self):
        safety=self.v9["safety"]
        self.assertFalse(safety["approved_local_phase11_available"])
        self.assertTrue(safety["branch_draft"])
        self.assertFalse(safety["main_merge_allowed"])
        self.assertFalse(safety["active_game_asset_swap"])
        self.assertFalse(self.v9["proof"]["actual_godot_f5_import"]=="PASS")
        self.assertEqual(self.v9["proof"]["runtime_fps"],"NOT_MEASURED")

    def test_provider_preserves_original_binary_revisions(self):
        safety=self.v9["safety"]
        self.assertTrue(safety["glb_binary_in_higgsfield"])
        self.assertFalse(safety["glb_binary_in_github"])
        self.assertFalse(safety["glb_binary_in_drive"])

if __name__=="__main__":
    unittest.main(verbosity=2)
