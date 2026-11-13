#!/usr/bin/env python3
"""Offline unit tests for the AOTL R36 GLB validation gate.

Run: python -m unittest discover -s tests -p 'test_verify_r36_glb.py'
No Godot, Blender, or third-party Python modules are required.
"""
import importlib.util
import json
import struct
import tempfile
import unittest
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1] / "tools" / "verify_r36_glb.py"
spec = importlib.util.spec_from_file_location("aotl_r36_validator", MODULE)
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


def to_glb(payload):
    encoded = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    encoded += b" " * (-len(encoded) % 4)
    length = 20 + len(encoded)
    return struct.pack("<4sII", b"glTF", 2, length) + struct.pack(
        "<II", len(encoded), 0x4E4F534A
    ) + encoded


def example_payload():
    bones = list(validator.REQUIRED_BONES)
    return {
        "asset": {"version": "2.0"},
        "nodes": [{"name": name} for name in bones],
        "skins": [{"joints": list(range(len(bones)))}],
        "meshes": [{"primitives": [{
            "attributes": {"JOINTS_0": 0, "WEIGHTS_0": 1}
        }]}],
        "animations": [{"name": "Armature|" + action} for action in validator.REQUIRED_ACTIONS],
    }


class TestGLBImportGate(unittest.TestCase):
    def inspect(self, payload):
        with tempfile.TemporaryDirectory() as folder:
            file = Path(folder) / "test.glb"
            file.write_bytes(to_glb(payload))
            document, info = validator.load_glb_json(file)
            return validator.inspect_document(document, info, None)

    def test_valid_skinned_animated_glb(self):
        report = self.inspect(example_payload())
        self.assertTrue(report["pass"], report)

    def test_missing_required_animation(self):
        payload = example_payload()
        payload["animations"] = [{"name": "Idle"}]
        report = self.inspect(payload)
        self.assertFalse(report["pass"])
        self.assertIn("Dodge", report["failure_reasons"][0])

    def test_missing_required_skin_joint(self):
        payload = example_payload()
        payload["skins"][0]["joints"].remove(1)  # Hips
        report = self.inspect(payload)
        self.assertFalse(report["pass"])
        self.assertIn("Hips", report["missing_bones"])

    def test_mesh_without_weight_attributes(self):
        payload = example_payload()
        payload["meshes"][0]["primitives"][0]["attributes"] = {}
        report = self.inspect(payload)
        self.assertFalse(report["pass"])

    def test_invalid_magic_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            file = Path(folder) / "broken.glb"
            file.write_bytes(b"Not a glTF 2.0 file")
            with self.assertRaises(ValueError):
                validator.load_glb_json(file)

    def test_tampered_declared_size_rejected(self):
        glb = bytearray(to_glb(example_payload()))
        struct.pack_into("<I", glb, 8, len(glb) + 4)
        with tempfile.TemporaryDirectory() as folder:
            file = Path(folder) / "broken.glb"
            file.write_bytes(glb)
            with self.assertRaises(ValueError):
                validator.load_glb_json(file)


if __name__ == "__main__":
    unittest.main()
