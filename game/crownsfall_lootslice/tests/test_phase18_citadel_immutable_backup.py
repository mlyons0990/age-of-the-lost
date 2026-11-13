#!/usr/bin/env python3
"""Hermetic tests for Phase18 immutable project archive + SHA verification."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

SCRIPT = Path(__file__).resolve().parents[1] / "tools" / "phase18_citadel_immutable_backup.py"
spec = importlib.util.spec_from_file_location("phase18_snapshot", SCRIPT)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

class SnapshotTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.project = self.base / "approved"
        self.project.mkdir()
        (self.project / "project.godot").write_text("config_version=5\n")
        (self.project / "game").mkdir()
        (self.project / "game" / "upper_citadel.tscn").write_text("preserve this exact scene")
        (self.project / ".godot").mkdir()
        (self.project / ".godot" / "cache.bin").write_bytes(b"temporary")
        self.initial = {p.relative_to(self.project).as_posix(): p.read_bytes()
                        for p in self.project.rglob("*") if p.is_file()}
        self.target = self.base / "backups" / "approved.zip"

    def test_snapshot_verifies_and_preserves_source(self):
        result = module.create_snapshot(self.project, self.target)
        self.assertEqual(result["files"], 2)
        self.assertEqual(len(result["sha256"]), 64)
        self.assertEqual(module.verify_snapshot(self.target),
                         {"file_count": 2, "verified": True})
        self.assertEqual(self.initial, {p.relative_to(self.project).as_posix(): p.read_bytes()
                         for p in self.project.rglob("*") if p.is_file()})
        with zipfile.ZipFile(self.target) as z:
            manifest = json.loads(z.read(module.MANIFEST_NAME))
            self.assertFalse(manifest["source_is_user_approved"])
            self.assertTrue(manifest["requires_user_f5_validation"])
            self.assertNotIn(".godot/cache.bin", z.namelist())

    def test_refuses_overwrite_even_if_identical(self):
        module.create_snapshot(self.project, self.target)
        with self.assertRaises(FileExistsError):
            module.create_snapshot(self.project, self.target)

    def test_refuses_destination_inside_project(self):
        with self.assertRaises(ValueError):
            module.create_snapshot(self.project, self.project / "dump.zip")

    def test_refuses_not_a_godot_project(self):
        (self.project / "project.godot").unlink()
        with self.assertRaises(ValueError):
            module.create_snapshot(self.project, self.target)
        self.assertFalse(self.target.exists())

    def test_refuses_symlink_external_reference(self):
        secret = self.base / "external-secret.txt"
        secret.write_text("external-only text")
        try:
            (self.project / "outside.txt").symlink_to(secret)
        except (OSError, NotImplementedError):
            self.skipTest("symlinks unavailable")
        module.create_snapshot(self.project, self.target)
        with zipfile.ZipFile(self.target) as z:
            self.assertNotIn("outside.txt", z.namelist())

    def test_detects_corrupt_manifest_checksum(self):
        module.create_snapshot(self.project, self.target)
        with zipfile.ZipFile(self.target) as z:
            entries = {name: z.read(name) for name in z.namelist()}
        metadata = json.loads(entries[module.MANIFEST_NAME])
        metadata["files"][0]["sha256"] = "0" * 64
        entries[module.MANIFEST_NAME] = json.dumps(metadata).encode()
        corrupt = self.base / "corrupt.zip"
        with zipfile.ZipFile(corrupt, "w") as z:
            for name, data in entries.items():
                z.writestr(name, data)
        with self.assertRaisesRegex(ValueError, "checksum mismatch"):
            module.verify_snapshot(corrupt)

    def test_cli_verify_existing_snapshot(self):
        module.create_snapshot(self.project, self.target)
        p = subprocess.run([sys.executable, str(SCRIPT), str(self.project),
                            "--out", str(self.target), "--verify"],
                           capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertTrue(json.loads(p.stdout)["verified"])

if __name__ == "__main__":
    unittest.main(verbosity=2)
