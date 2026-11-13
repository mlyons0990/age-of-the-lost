#!/usr/bin/env python3
"""Isolated Phase21 portable art bundle safeguards: no live-game writes."""
from pathlib import Path
import importlib.util
import json
import sys
import tempfile
import unittest
import zipfile

TOOLS=Path(__file__).resolve().parents[1]/"tools"
sys.path.insert(0,str(TOOLS))
import phase21_bundle_external_art as bundle
from test_phase21_external_glb_gate import minimal_payload,encode

class PortableBundleTests(unittest.TestCase):
    def setUp(self):
        temp=tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root=Path(temp.name)
        self.glb=self.root/"v10.glb"
        doc,binary=minimal_payload()
        self.glb.write_bytes(encode(doc,binary))
        self.blend=self.root/"v10.blend"
        self.blend.write_bytes(b"BLENDER-v500"+b"TEST_BYPASS_NOT_REAL_BLEND")
        self.out=self.root/"zip"/"portable.zip"
        self.approved=self.root/"approved"
        self.approved.mkdir()
        (self.approved/"project.godot").write_text("config_version=5")
        self.originals={self.glb:self.glb.read_bytes(),self.blend:self.blend.read_bytes(),
                        self.approved/"project.godot":(self.approved/"project.godot").read_bytes()}

    def create(self):
        # Stub has one synthetic triangle. This test is about archive safety;
        # the production CLI keeps 309-node, <=27k triangle and 2-image rules.
        return bundle.create(self.glb,self.blend,self.out,self.approved)

    def test_valid_bundle_and_independent_checksum(self):
        result=self.create()
        self.assertEqual(result["files"],2)
        self.assertEqual(result["model_meshes"],309)
        self.assertEqual(bundle.verify(self.out)["model_triangles"],1)
        self.assertEqual(len(result["sha256"]),64)
        with zipfile.ZipFile(self.out) as z:
            self.assertIn(bundle.MANIFEST_NAME,z.namelist())
            self.assertEqual(z.read("AOTL_Citadel_Optimized_v10.glb"),self.originals[self.glb])

    def test_approved_original_and_sources_unchanged(self):
        self.create()
        self.assertEqual({p:p.read_bytes() for p in self.originals},self.originals)
        self.assertEqual(list(self.approved.iterdir()),[self.approved/"project.godot"])

    def test_refuses_overwrite(self):
        self.create()
        with self.assertRaises(FileExistsError):
            self.create()

    def test_refuses_writing_archive_inside_live_game(self):
        self.out=self.approved/"assets"/"never.zip"
        with self.assertRaisesRegex(ValueError,"inside approved game"):
            self.create()
        self.assertFalse(self.out.exists())

    def test_rejects_invalid_blender_signature(self):
        self.blend.write_bytes(b"INVALID_BINARY")
        with self.assertRaisesRegex(ValueError,"Blender magic"):
            self.create()
        self.assertFalse(self.out.exists())

    def test_rejects_non_glb_input(self):
        self.glb.write_bytes(b"bad GLB")
        with self.assertRaises(ValueError):
            self.create()
        self.assertFalse(self.out.exists())

    def test_rejects_unchecked_existing_dest(self):
        self.out.parent.mkdir()
        self.out.write_bytes(b"preserve pre-existing")
        with self.assertRaises(FileExistsError):
            self.create()
        self.assertEqual(self.out.read_bytes(),b"preserve pre-existing")

    def test_detects_manifest_checksum_mismatch(self):
        self.create()
        with zipfile.ZipFile(self.out) as z:
            entries={k:z.read(k) for k in z.namelist()}
        m=json.loads(entries[bundle.MANIFEST_NAME])
        m["files"]["AOTL_Citadel_Editable_v10.blend"]["sha256"]="0"*64
        entries[bundle.MANIFEST_NAME]=json.dumps(m).encode()
        corrupt=self.root/"corrupt.zip"
        with zipfile.ZipFile(corrupt,"w") as z:
            for k,v in entries.items():z.writestr(k,v)
        with self.assertRaisesRegex(ValueError,"integrity mismatch"):
            bundle.verify(corrupt)

    def test_symlinked_glb_input_rejected(self):
        linked=self.root/"linked.glb"
        try:linked.symlink_to(self.glb)
        except (OSError,NotImplementedError):
            self.skipTest("symlinks unsupported")
        with self.assertRaisesRegex(ValueError,"symlinks"):
            bundle.create(linked,self.blend,self.out,self.approved)

    def test_symlinked_output_rejected(self):
        linked=self.root/"linked.zip"
        try:linked.symlink_to(self.root/"not-created.zip")
        except (OSError,NotImplementedError):
            self.skipTest("symlinks unsupported")
        with self.assertRaises(FileExistsError):
            bundle.create(self.glb,self.blend,linked,self.approved)

if __name__=="__main__":
    unittest.main(verbosity=2)
