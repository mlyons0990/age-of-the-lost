#!/usr/bin/env python3
"""Hermetic tamper checks for Phase21 GLB parser, no Blender dependency."""
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest

SRC=Path(__file__).resolve().parents[1]/"tools"/"phase21_external_glb_gate.py"
spec=importlib.util.spec_from_file_location("phase21_glb_gate",SRC)
gate=importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(gate)

def pack_chunk(payload: bytes, kind: bytes) -> bytes:
    fill=b" " if kind==b"JSON" else b"\x00"
    payload=payload+fill*((-len(payload))%4)
    return struct.pack("<I4s",len(payload),kind)+payload

def minimal_payload():
    landmarks=[f"STAIR_Tread_{i:02d}" for i in range(1,10)]
    landmarks.extend(f"GATE_Gothic_Voussoir_{i:02d}" for i in range(1,33))
    names=landmarks+[f"PH21_Decorative_{i:03d}" for i in range(309-len(landmarks))]
    binary=b"\x00"*36+bytes([137,80,78,71,13,10,26,10])*2
    doc={"asset":{"version":"2.0"},
         "buffers":[{"byteLength":len(binary)}],
         "bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":36},
                        {"buffer":0,"byteOffset":36,"byteLength":8},
                        {"buffer":0,"byteOffset":44,"byteLength":8}],
         "accessors":[{"bufferView":0,"componentType":5126,"count":3,
                       "type":"VEC3"}],
         "materials":[{"name":"original_test_mat"}],
         "images":[{"bufferView":1,"mimeType":"image/png"},
                   {"bufferView":2,"mimeType":"image/png"}],
         "meshes":[{"primitives":[{"attributes":{"POSITION":0},"mode":4,
                                   "material":0}]}],
         "nodes":[{"name":name,"mesh":0} for name in names],
         "textures":[{"source":0},{"source":1}]}
    return doc,binary

def encode(doc,binary):
    parts=[pack_chunk(json.dumps(doc).encode(),b"JSON"),
           pack_chunk(binary,b"BIN\x00")]
    total=12+sum(len(x) for x in parts)
    return struct.pack("<4sII",b"glTF",2,total)+b"".join(parts)

class ExternalGlbGateTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path=Path(self.tmp.name)/"model.glb"
        self.doc,self.bin=minimal_payload()
    def write(self):
        self.path.write_bytes(encode(self.doc,self.bin))
    def gate(self):
        self.write()
        return gate.inspect_glb(self.path,mesh_nodes=309,max_triangles=1,min_images=2)

    def test_valid_minimal_embedded_asset(self):
        result=self.gate()
        self.assertEqual(result["status"],"PASS")
        self.assertEqual(result["mesh_nodes"],309)
        self.assertEqual(result["actual_exported_triangles"],1)
        self.assertEqual(result["embedded_images"],2)
        self.assertFalse(result["real_godot_import_verified"])

    def test_missing_tread_rejected(self):
        self.doc["nodes"][0]["name"]="MISSING_TREAD"
        with self.assertRaisesRegex(gate.GlbRejected,"landmarks"):
            self.gate()

    def test_missing_arch_stone_rejected(self):
        self.doc["nodes"][9]["name"]="RENAMED"
        with self.assertRaisesRegex(gate.GlbRejected,"landmarks"):
            self.gate()

    def test_more_than_allowed_triangles_rejected(self):
        self.doc["accessors"][0]["count"]=6
        with self.assertRaisesRegex(gate.GlbRejected,"exceed"):
            self.gate()

    def test_broken_external_image_rejected(self):
        self.doc["images"][0]={"uri":"https://tracker.example/art.png"}
        with self.assertRaisesRegex(gate.GlbRejected,"external URI"):
            self.gate()

    def test_external_binary_buffer_rejected(self):
        self.doc["buffers"][0]["uri"]="../evil.bin"
        with self.assertRaisesRegex(gate.GlbRejected,"embedded BIN"):
            self.gate()

    def test_too_short_accessor_view_rejected(self):
        self.doc["bufferViews"][0]["byteLength"]=12
        with self.assertRaisesRegex(gate.GlbRejected,"exceeds its declared bufferView"):
            self.gate()

    def test_invalid_component_alignment_rejected(self):
        self.doc["accessors"][0]["byteOffset"]=1
        with self.assertRaisesRegex(gate.GlbRejected,"alignment"):
            self.gate()

    def test_collision_extras_rejected(self):
        self.doc["nodes"][100]["extras"]={"AOTL_collision":True}
        with self.assertRaisesRegex(gate.GlbRejected,"collision authority"):
            self.gate()

    def test_invalid_embedded_image_signature_rejected(self):
        self.bin=b"\\x00"*36+b"bad-image-dat" + bytes([137,80,78,71,13,10,26,10])
        self.doc["buffers"][0]["byteLength"]=len(self.bin)
        with self.assertRaisesRegex(gate.GlbRejected,"PNG signature"):
            self.gate()

    def test_node_with_collision_name_rejected(self):
        self.doc["nodes"][100]["name"]="StaticBody3D_Injector"
        with self.assertRaisesRegex(gate.GlbRejected,"collision"):
            self.gate()

    def test_duplicate_mesh_node_name_rejected(self):
        self.doc["nodes"][100]["name"]=self.doc["nodes"][101]["name"]
        with self.assertRaisesRegex(gate.GlbRejected,"Duplicate"):
            self.gate()

    def test_invalid_material_reference_rejected(self):
        self.doc["meshes"][0]["primitives"][0]["material"]=99
        with self.assertRaisesRegex(gate.GlbRejected,"material"):
            self.gate()

    def test_invalid_accessor_view_rejected(self):
        self.doc["accessors"][0]["bufferView"]=99
        with self.assertRaisesRegex(gate.GlbRejected,"buffer view"):
            self.gate()

    def test_out_of_bounds_image_buffer_view_rejected(self):
        self.doc["bufferViews"][1]["byteOffset"]=200
        with self.assertRaisesRegex(gate.GlbRejected,"escapes"):
            self.gate()

    def test_truncated_header_rejected(self):
        self.path.write_bytes(b"glTF")
        with self.assertRaisesRegex(gate.GlbRejected,"too short"):
            gate.inspect_glb(self.path)

    def test_wrong_glb_sha256_rejected(self):
        self.write()
        with self.assertRaisesRegex(gate.GlbRejected,"SHA-256"):
            gate.inspect_glb(self.path,expected_sha256="0"*64)

    def test_null_geometry_rejected(self):
        self.doc["meshes"][0]["primitives"][0].pop("attributes")
        with self.assertRaisesRegex(gate.GlbRejected,"POSITION"):
            self.gate()

    def test_sparse_accessor_rejected(self):
        self.doc["accessors"][0]["sparse"]={"count":1}
        with self.assertRaisesRegex(gate.GlbRejected,"Sparse"):
            self.gate()

    def test_symlinked_asset_rejected(self):
        self.write()
        link=Path(self.tmp.name)/"linked.glb"
        try:
            link.symlink_to(self.path)
        except (OSError,NotImplementedError):
            self.skipTest("symlinks unsupported")
        with self.assertRaisesRegex(gate.GlbRejected,"symlinked"):
            gate.inspect_glb(link)

if __name__=="__main__":
    unittest.main(verbosity=2)
