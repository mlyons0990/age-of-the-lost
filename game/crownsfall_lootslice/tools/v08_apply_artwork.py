#!/usr/bin/env python3
"""Apply authored AOTL character artwork to the V08 rigged UV carrier.

Usage (Blender 5.2):
  blender -b AOTL_Humanoid_Master_V08.blend \
    --python tools/v08_apply_artwork.py -- \
    --body BODY_PAINT_2048.png --gear GEAR_PAINT_2048.png \
    --blend-out AOTL_Warrior_Painted.blend --glb-out AOTL_Warrior_Painted.glb

The two supplied PNGs should be *painted over the V08 BODY and GEAR UV guide
images*, respectively. The six canonical AOTL art references are color/shape
guides; an illustration is not automatically a correctly unwrapped texture.
No separate bone, mesh, socket, animation, collision or camera modifications.
"""
from __future__ import annotations
import argparse
import pathlib
import sys
import bpy

ATLAS_IMAGES = {
    "body": "V08_BODY_PaintPlaceholder_2K",
    "gear": "V08_GEAR_PaintPlaceholder_2K",
}
SHADER_IMAGE_NODE = "V08_REPLACE_WITH_YOUR_ARTWORK"
CARRIER_UV = "V08_ART"
RIG = "RIG_AOTL_Master_Humanoid_58"

def cli():
    argv = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser(description="Paint the AOTL V08 skinned humanoid")
    p.add_argument("--body", type=pathlib.Path, required=True,
                   help="PNG atlas painted over V08_BODY_UV_GUIDE_2K")
    p.add_argument("--gear", type=pathlib.Path, required=True,
                   help="PNG atlas painted over V08_GEAR_UV_GUIDE_2K")
    p.add_argument("--blend-out", type=pathlib.Path, required=True)
    p.add_argument("--glb-out", type=pathlib.Path, required=True)
    return p.parse_args(argv)

def verify():
    arm = bpy.data.objects.get(RIG)
    assert arm and arm.type == "ARMATURE", "Missing V08 armature"
    assert len(arm.data.bones) == 58, "Expected 58 compatible humanoid bones"
    assert arm.animation_data and arm.animation_data.action, "Animation reel missing"
    objects = [o for o in bpy.data.objects if o.type == "MESH" and
               o.get("AOTL_V08_ARTWORK_CARRIER") in ("body", "gear")]
    assert len(objects) == 22, "Expected 22 art-ready body/equipment meshes"
    for o in objects:
        assert len(o.vertex_groups)>0 and any(m.type == "ARMATURE" for m in o.modifiers), o.name
        assert o.data.uv_layers.get(CARRIER_UV), "Missing paint UV on " + o.name
    assert sum(o["AOTL_V08_ARTWORK_CARRIER"] == "body" for o in objects)==7
    assert sum(o["AOTL_V08_ARTWORK_CARRIER"] == "gear" for o in objects)==15
    return arm, objects

def load_art(p: pathlib.Path):
    if not p.is_file():
        raise FileNotFoundError(str(p))
    if p.suffix.lower() != ".png":
        raise ValueError("Provide an RGBA or RGB PNG painted against the exact UV guide: " + str(p))
    new = bpy.data.images.load(str(p.resolve()), check_existing=False)
    w,h = new.size[:]
    if w < 1024 or h < 1024:
        raise ValueError(f"{p.name} is {w}x{h}; at least 1024x1024 is required, 2048 preferred")
    if w != h:
        raise ValueError(f"{p.name} should use a square atlas matching the UV guide")
    new.colorspace_settings.name = "sRGB"
    new.pack()
    if new.packed_file is None:
        raise RuntimeError("Couldn't pack reference artwork in Blender source")
    return new

def main():
    args=cli()
    rig,objects=verify()
    art={"body":load_art(args.body), "gear":load_art(args.gear)}
    updated=0
    for ob in objects:
        tag=ob["AOTL_V08_ARTWORK_CARRIER"]
        for mat in ob.data.materials:
            if not mat or not mat.use_nodes:
                raise RuntimeError("Unpaintable material on "+ob.name)
            node=mat.node_tree.nodes.get(SHADER_IMAGE_NODE)
            if node is None or node.type!='TEX_IMAGE':
                raise RuntimeError("Expected V08 texture node in "+mat.name)
            node.image=art[tag]
            uv_input=node.inputs.get("Vector")
            linked=[x for x in mat.node_tree.links if x.to_socket==uv_input]
            assert linked and linked[0].from_node.type=="UVMAP" and linked[0].from_node.uv_map==CARRIER_UV
            updated+=1
    rig["AOTL_ARTWORK_SOURCE_BODY"]=args.body.name
    rig["AOTL_ARTWORK_SOURCE_GEAR"]=args.gear.name
    # The existing V06 gameplay reel remains unchanged; Godot splits 23
    # named timeline ranges from data/humanoid_v06_reel_manifest.json.
    bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.blend_out.resolve()))
    bpy.ops.export_scene.gltf(filepath=str(args.glb_out.resolve()),
                              export_format="GLB", use_selection=False,
                              export_apply=False,
                              export_animations=True,
                              export_image_format="AUTO")
    print("V08_ART_OVERLAY_OK",
          {"rig_bones":len(rig.data.bones),
           "carriers":len(objects), "assigned_slots":updated,
           "body":str(args.body), "gear":str(args.gear),
           "blend":str(args.blend_out), "glb":str(args.glb_out)})
if __name__=="__main__":
    main()
