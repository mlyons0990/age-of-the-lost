#!/usr/bin/env python3
"""Hermetic safety regression tests for the non-destructive Phase18 recovery audit."""
from __future__ import annotations
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "phase18_citadel_recovery_audit.py"
spec = importlib.util.spec_from_file_location("phase18_audit", SCRIPT)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

class Phase18AuditSafetyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.project = self.base / "approved"
        self.project.mkdir()
        (self.project / "project.godot").write_text("config_version=5\n", encoding="utf-8")
        self.scenes = self.project / "scenes"
        self.scenes.mkdir()
        (self.scenes / "upper_citadel_phase11.tscn").write_text(
            "[node name=\"Citadel\" type=\"Node2D\"]\n"
            "[node name=\"Navigation\" type=\"NavigationRegion2D\" parent=\".\"]\n",
            encoding="utf-8")
        (self.project / ".godot").mkdir()
        (self.project / ".godot" / "cache").write_bytes(b"internal cache")
        (self.project / "AOTL_Citadel_MasonryArt_v17.glb").write_bytes(b"GLB TEST")
        self.original = {p.relative_to(self.project).as_posix(): p.read_bytes()
                         for p in self.project.rglob("*") if p.is_file()}

    def run_audit(self, out: Path):
        return subprocess.run([sys.executable, str(SCRIPT), str(self.project),
                               "--out", str(out)], text=True, capture_output=True)

    def test_inventory_hashes_and_candidate_flags(self):
        report = module.audit(self.project)
        self.assertFalse(report["approved_phase11_recovered"])
        self.assertFalse(report["automatic_merge_allowed"])
        self.assertFalse(report["automatic_asset_install_allowed"])
        self.assertTrue(report["phase11_possible_evidence"])
        self.assertEqual(report["file_count"], 3)
        self.assertEqual(report["known_artifacts"]["AOTL_Citadel_MasonryArt_v17.glb"],
                         ["AOTL_Citadel_MasonryArt_v17.glb"])
        self.assertEqual(len(next(x for x in report["files"] if x["path"] ==
                                  "AOTL_Citadel_MasonryArt_v17.glb")["sha256"]), 64)

    def test_output_outside_source_is_created_once_and_valid(self):
        out = self.base / "backup" / "audit.json"
        process = self.run_audit(out)
        self.assertEqual(process.returncode, 0, process.stderr)
        report = json.loads(out.read_text(encoding="utf-8"))
        self.assertEqual(report["schema"], "aotl.citadel.phase18.readonly_audit.v1")
        self.assertFalse(report["approved_phase11_recovered"])
        self.assertNotEqual(self.run_audit(out).returncode, 0)

    def test_refuses_output_inside_approved_project(self):
        self.assertNotEqual(self.run_audit(self.project / "audit.json").returncode, 0)
        self.assertFalse((self.project / "audit.json").exists())

    def test_source_files_remain_unchanged(self):
        self.assertEqual(self.run_audit(self.base / "audit.json").returncode, 0)
        after = {p.relative_to(self.project).as_posix(): p.read_bytes()
                 for p in self.project.rglob("*") if p.is_file()}
        self.assertEqual(self.original, after)

    def test_missing_source_fails_without_creating_output(self):
        out = self.base / "out.json"
        p = subprocess.run([sys.executable, str(SCRIPT),
                            str(self.base / "missing"), "--out", str(out)],
                           text=True, capture_output=True)
        self.assertNotEqual(p.returncode, 0)
        self.assertFalse(out.exists())

if __name__ == "__main__":
    unittest.main(verbosity=2)
