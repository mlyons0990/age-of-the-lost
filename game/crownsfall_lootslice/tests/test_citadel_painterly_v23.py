#!/usr/bin/env python3
"""Phase23 raw glTF material acceptance gate: no live game writes."""
import hashlib
import json
from pathlib import Path
import struct
import unittest

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets/25d/citadel/AOTL_Citadel_Higgsfield_Optimized_v10.glb"
PAINT=ROOT/"assets/25d/citadel/AOTL_Citadel_Painterly_v13.glb"
PNG=bytes([137,80,78,71,13,10,26,10])
OLD_SOURCE_SHA="91468793913600410d1665bfed0f3acdf6d733ed5f3ab13b0c8796f944329a64"

def parse_glb(path):
    raw=path.read_bytes()
    magic,version,declared=struct.unpack_from("<4sII",raw,0)
    if magic!=b"glTF" or version!=2 or declared!=len(raw):
        raise ValueError("Malformed GLB version/length")
    jsonlen,kind=struct.unpack_from("<I4s",raw,12)
    if kind!=b"JSON":raise ValueError("Missing GLB JSON chunk")
    doc=json.loads(raw[20:20+jsonlen])
    start=20+jsonlen
    binlen,kind=struct.unpack_from("<I4s",raw,start)
    if kind!=b"BIN"+bytes([0]):raise ValueError("Missing binary chunk")
    binary=raw[start+8:start+8+binlen]
    return doc,binary,raw

def embedded_pngs(doc,binary):
    result={}
    for image in doc.get("images",[]):
        view=doc["bufferViews"][image["bufferView"]]
        start=view.get("byteOffset",0);end=start+view["byteLength"]
        payload=binary[start:end]
        if not payload.startswith(PNG):raise ValueError("Nonembedded PNG atlas")
        width,height=struct.unpack_from(">II",payload,16)
        result[image.get("name","")]=(width,height,hashlib.sha256(payload).hexdigest())
    return result

class Phase23PainterlyGlb(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.doc,cls.binary,cls.raw=parse_glb(PAINT)
        cls.old_sha=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
        cls.qa=json.loads(PAINT.with_suffix(".qa.json").read_text())

    def test_original_v10_has_not_changed(self):
        self.assertEqual(self.old_sha,OLD_SOURCE_SHA)

    def test_true_glb_magic_and_version(self):
        self.assertEqual(self.doc["asset"]["version"],"2.0")
        self.assertEqual(len(self.raw),struct.unpack_from("<I",self.raw,8)[0])

    def test_mesh_count(self):
        self.assertEqual(sum("mesh" in n for n in self.doc["nodes"]),309)

    def test_original_nine_treads(self):
        names={n.get("name") for n in self.doc["nodes"]}
        self.assertTrue(all(f"STAIR_Tread_{i:02d}" in names for i in range(1,10)))

    def test_arch_stones_preserved(self):
        names={n.get("name") for n in self.doc["nodes"]}
        self.assertTrue(all(f"GATE_Gothic_Voussoir_{i:02d}" in names for i in range(1,33)))

    def test_three_embedded_material_paint_maps(self):
        images=embedded_pngs(self.doc,self.binary)
        self.assertEqual(len(images),3)
        self.assertEqual(images["AOTL_Ph23_IvoryStone_1024"][:2],(1024,1024))
        self.assertEqual(images["AOTL_Ph23_WeatheredPatina_1024"][:2],(1024,1024))
        self.assertEqual(images["AOTL_Ph23_PaintedIvy_512"][:2],(512,512))

    def test_no_external_binary_or_texture_dependency(self):
        self.assertEqual(len(self.doc["buffers"]),1)
        self.assertNotIn("uri",self.doc["buffers"][0])
        self.assertTrue(all("uri" not in image for image in self.doc["images"]))

    def test_ivy_is_texture_bound(self):
        materials=[m for m in self.doc.get("materials",[]) if m.get("name")=="MAT_Ivy_Leaves"]
        self.assertEqual(len(materials),1)
        self.assertIn("baseColorTexture",materials[0].get("pbrMetallicRoughness",{}))

    def test_all_ivy_mesh_primitives_have_uv0(self):
        ivy_materials={i for i,m in enumerate(self.doc["materials"])
                       if m.get("name")=="MAT_Ivy_Leaves"}
        count=0
        for mesh in self.doc["meshes"]:
            for p in mesh.get("primitives",[]):
                if p.get("material") in ivy_materials:
                    count+=1
                    self.assertIn("TEXCOORD_0",p["attributes"])
        self.assertGreater(count,20)

    def test_material_count_has_not_collapsed(self):
        self.assertGreaterEqual(len(self.doc.get("materials",[])),8)

    def test_qa_artifact_reports_actual_generated_pngs(self):
        self.assertEqual(len(self.qa["new_textures"]),3)
        self.assertEqual(self.qa["mesh_count"],309)
        self.assertTrue(all(len(x["png_sha256"])==64 for x in self.qa["new_textures"]))

    def test_no_gameplay_collision_node_names(self):
        bad=("StaticBody3D","CollisionShape","CharacterBody3D","NavigationRegion")
        names=[n.get("name","") for n in self.doc["nodes"]]
        self.assertFalse(any(any(p in n for p in bad) for n in names))

if __name__=="__main__":
    unittest.main(verbosity=2)
