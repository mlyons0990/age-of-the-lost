#!/usr/bin/env python3
"""Hermetic regression tests for Phase18 staged-only art import."""
from __future__ import annotations
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

TOOL_DIR=Path(__file__).resolve().parents[1]/"tools"
sys.path.insert(0,str(TOOL_DIR))
import phase18_citadel_immutable_backup as snapshot
import phase18_stage_citadel_candidate as stage_tool

class StagingTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base=Path(self.temp.name)
        self.game=self.base/"live_project"
        self.game.mkdir()
        (self.game/"project.godot").write_text("config_version=5\n")
        (self.game/"approved_phase11.tscn").write_text("important approved scene")
        self.src=self.base/"phase17_candidate"
        folder=self.src/stage_tool.SOURCE_SUBDIR
        folder.mkdir(parents=True)
        self.glb=folder/stage_tool.GLB_NAME
        self.glb.write_bytes(b"test fixture only: deterministic GLB placeholder")
        self.meta=folder/stage_tool.MANIFEST_FILE
        self.meta.write_text(json.dumps({"nodes":1197,"has_gameplay_colliders":False,
            "status":"art_candidate_not_canon_not_higgsfield_export"}))
        self.sha=stage_tool.digest(self.glb)
        self.zip=self.base/"immutable.zip"
        snapshot.create_snapshot(self.game,self.zip)
        self.original=(self.game/"approved_phase11.tscn").read_bytes()

    def planning(self):
        return stage_tool.stage(self.game,self.src,self.zip,False,self.sha)

    def applying(self):
        return stage_tool.stage(self.game,self.src,self.zip,True,self.sha)

    def test_dry_run_has_zero_writes(self):
        result=self.planning()
        self.assertFalse(result["applied"])
        self.assertEqual(result["files"],2)
        self.assertFalse((self.game/stage_tool.CANDIDATE_SUBDIR).exists())
        self.assertEqual((self.game/"approved_phase11.tscn").read_bytes(),self.original)

    def test_apply_only_writes_inactive_candidate_assets(self):
        result=self.applying()
        self.assertTrue(result["applied"])
        self.assertEqual(result["status"],"STAGING_ONLY_NOT_ENABLED")
        for name in (stage_tool.GLB_NAME,stage_tool.MANIFEST_FILE):
            self.assertEqual((self.game/stage_tool.CANDIDATE_SUBDIR/name).read_bytes(),
                             (self.src/stage_tool.SOURCE_SUBDIR/name).read_bytes())
        self.assertEqual((self.game/"approved_phase11.tscn").read_bytes(),self.original)
        self.assertEqual((self.game/"project.godot").read_text(),"config_version=5\n")
        with self.assertRaises(FileExistsError):
            self.applying()  # previously staged file cannot be overwritten

    def test_rejects_wrong_glb_hash(self):
        with self.assertRaisesRegex(ValueError,"GLB checksum mismatch"):
            stage_tool.stage(self.game,self.src,self.zip,False,"0"*64)

    def test_rejects_modified_approved_scene(self):
        (self.game/"approved_phase11.tscn").write_text("modified before backup gate")
        with self.assertRaisesRegex(ValueError,"changed since backup"):
            self.planning()

    def test_rejects_added_approved_file(self):
        (self.game/"extra.gd").write_text("unexpected local source")
        with self.assertRaisesRegex(ValueError,"inventory differs"):
            self.planning()

    def test_rejects_existing_candidate_folder(self):
        (self.game/stage_tool.CANDIDATE_SUBDIR).mkdir(parents=True)
        (self.game/stage_tool.CANDIDATE_SUBDIR/stage_tool.GLB_NAME).write_bytes(b"existing")
        with self.assertRaises(FileExistsError):
            self.planning()

    def test_rejects_invalid_candidate_manifest(self):
        self.meta.write_text(json.dumps({"nodes":1197,"has_gameplay_colliders":True,
                  "status":"art_candidate_not_canon_not_higgsfield_export"}))
        with self.assertRaisesRegex(ValueError,"art-only"):
            self.planning()

    def test_rejects_modified_backup_integrity(self):
        self.zip.write_bytes(b"bad archive")
        with self.assertRaises(Exception):
            self.planning()

if __name__=="__main__":
    unittest.main(verbosity=2)
