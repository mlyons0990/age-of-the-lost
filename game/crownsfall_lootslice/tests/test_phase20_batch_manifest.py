#!/usr/bin/env python3
"""Hermetic Phase20 geometry optimization provenance checks.

This is a manifest-integrity preflight, NOT a substitute for exact Blender QA,
Godot F5 navigation or pixel A/B testing against a live gameplay scene.
"""
import json
from pathlib import Path
import unittest

MANIFEST=Path(__file__).resolve().parents[1]/"data"/"citadel_phase20_batch_manifest.json"
class Phase20BatchManifestTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.report=json.loads(MANIFEST.read_text(encoding="utf-8"))

    def test_revision_and_artifact_lineage(self):
        self.assertEqual(self.report["schema"],"aotl.citadel.phase20.batching.v1")
        self.assertEqual(self.report["source_revision"],7)
        self.assertEqual(self.report["sculpt_revision"],8)
        self.assertFalse(self.report["actual_local_godot_f5_test"])
        self.assertFalse(self.report["canonical_art_approved"])
        self.assertFalse(self.report["merge_into_main_allowed"])

    def test_exact_scene_and_object_counts(self):
        g=self.report["geometry"]
        self.assertEqual(g["original_scene_mesh_objects"],571)
        self.assertEqual(g["decorative_source_mesh_objects"],90)
        self.assertEqual(g["new_optimized_batch_objects"],12)
        self.assertEqual(g["optimized_scene_mesh_objects"],493)
        self.assertEqual(g["object_count_reduction"],78)
        self.assertEqual(571-90+12,493)
        self.assertAlmostEqual(100*78/571,g["object_reduction_percent"],places=2)

    def test_no_triangle_changes_claim(self):
        g=self.report["geometry"]
        self.assertEqual(g["total_triangles_before"],8820)
        self.assertEqual(g["total_triangles_after"],8820)
        self.assertEqual(g["original_stair_treads"],9)
        self.assertEqual(g["original_gothic_stones"],32)
        self.assertEqual(g["phase18_rosettes"],18)
        self.assertEqual(g["packed_images"],2)
        self.assertEqual(g["unused_external_images"],0)
        self.assertTrue(g["all_ornamental_worldspace_vertices_sha_verified"])

    def test_batch_ids_and_sha_are_unique(self):
        groups=self.report["groups"]
        self.assertEqual(len(groups),12)
        self.assertEqual(len({g["name"] for g in groups}),12)
        self.assertEqual(sum(g["source_meshes"] for g in groups),90)
        self.assertEqual(sum(g["triangles"] for g in groups),744)
        self.assertEqual(sum(g["vertices"] for g in groups),724)
        for g in groups:
            self.assertTrue(g["name"].startswith("PH20_Batched_"))
            self.assertTrue(g["vertex_sha256"])
            self.assertEqual(len(g["vertex_sha256"]),64)
            self.assertTrue(all(ch in "0123456789abcdef" for ch in g["vertex_sha256"]))
            self.assertGreater(g["vertices"],0)
            self.assertGreater(g["triangles"],0)

    def test_fountain_and_arch_batches_are_separated(self):
        groups=self.report["groups"]
        arch=[g for g in groups if "_Arch_" in g["name"]]
        left=[g for g in groups if "_Fountain_L_" in g["name"]]
        right=[g for g in groups if "_Fountain_R_" in g["name"]]
        self.assertEqual((len(arch),len(left),len(right)),(2,5,5))
        self.assertEqual(sum(x["source_meshes"] for x in arch),64)
        self.assertEqual(sum(x["source_meshes"] for x in left),13)
        self.assertEqual(sum(x["source_meshes"] for x in right),13)

    def test_pixels_at_fixed_camera_show_no_significant_change(self):
        pixels=self.report["render_validation"]
        self.assertEqual(pixels["resolution"],[640,360])
        self.assertEqual(pixels["pixels_compared"],640*360)
        self.assertEqual(pixels["pixels_with_rgb_delta_gt_0_02"],0)
        self.assertEqual(pixels["pixels_with_rgb_delta_gt_0_005"],198)
        self.assertLess(pixels["maximum_rgb_channel_delta"],0.02)

    def test_binary_and_live_game_are_explicitly_unverified(self):
        self.assertTrue(self.report["glb_retained_at_provider"])
        self.assertTrue(self.report["blend_retained_at_provider"])
        self.assertFalse(self.report["external_glb_bin_uploaded_to_github"])
        self.assertFalse(self.report["external_glb_bin_uploaded_to_google"])
        self.assertFalse(self.report["actual_local_godot_f5_test"])
        self.assertIn("not actual runtime",self.report["performance_claim"])
if __name__=="__main__":
    unittest.main(verbosity=2)
