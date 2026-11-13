"""Regenerate Phase23 painterly-material GLB from the committed Phase22 v10 binary.

Invoked ONLY in an isolated CI checkout:
  blender -b --factory-startup --python tools/phase23_rebuild_from_v10.py -- \
    --source assets/25d/citadel/AOTL_Citadel_Higgsfield_Optimized_v10.glb \
    --output assets/25d/citadel/AOTL_Citadel_Painterly_v13.glb \
    --blend-output /tmp/AOTL_Citadel_Ph23_Editable.blend

This is a separate derived output, never overwrites v10 or the approved
locally working Godot scene. Geometry should be preserved; only paint UV albedo.
"""
import argparse
import importlib.util
import json
from pathlib import Path
import sys
import hashlib
import bpy

def process(source:Path,output:Path,blend_output:Path|None=None) -> dict:
    source=source.resolve(strict=True)
    output=output.resolve()
    if source==output or source.is_symlink() or output.exists():
        raise ValueError("Never overwrite or edit the original approved GLB")
    if output.suffix.lower()!=".glb":
        raise ValueError("Expected .glb output")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    result=bpy.ops.import_scene.gltf(filepath=str(source))
    if "FINISHED" not in result:
        raise RuntimeError("Blender failed to import true optimized v10 GLB")
    objects=[o for o in bpy.data.objects if o.type=="MESH"]
    if len(objects)!=309:
        raise RuntimeError(f"Imported {len(objects)} meshes; need 309")
    base=Path(__file__).with_name("phase23_painterly_citadel_atlas.py")
    spec=importlib.util.spec_from_file_location("aotl_phase23_atlas",base)
    if spec is None or spec.loader is None:
        raise RuntimeError("Phase23 atlas source not loadable")
    module=importlib.util.module_from_spec(spec)
    sys.modules[spec.name]=module
    spec.loader.exec_module(module)
    paint=module.install()
    # glTF importer splits some source materials into ".001" clones for objects
    # with no TEXCOORD_0. Update every clone still pointing to the old image;
    # otherwise a false "5 embedded maps" export silently preserves v10 PNGs.
    for material_name,old_name,new_name,size,seed,kind in module.PHASE23_MAPS:
        if not old_name:
            continue
        for material in bpy.data.materials:
            if material.name!=material_name and not material.name.startswith(material_name+"."):
                continue
            if not material.use_nodes:
                continue
            for tex in (n for n in material.node_tree.nodes if n.type=="TEX_IMAGE"):
                if tex.image and tex.image.name==old_name:
                    tex.image=bpy.data.images[new_name]
    expected_images={entry["image"] for entry in paint["textures"]}
    for name in expected_images:
        if name not in bpy.data.images or not bpy.data.images[name].packed_file:
            raise RuntimeError(f"Missing packed newly painted atlas {name}")
    # Imported v10 sometimes split a material into a separate untextured .001
    # variant for UV-less meshes. Preserve that fallback rather than assigning
    # nonexistent TEXCOORD_0 and losing original color.
    leaves=[o for o in bpy.data.objects if o.type=="MESH" and
            any(slot.material and slot.material.name=="MAT_Ivy_Leaves"
                for slot in o.material_slots)]
    if len(leaves)!=52 or any(len(o.data.uv_layers)<1 for o in leaves):
        raise RuntimeError("Ivy UV source assets unexpectedly missing")
    output.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(output),export_format="GLB",export_apply=True)
    if not output.is_file():
        raise RuntimeError("GLB export failed")
    if blend_output:
        blend_output=blend_output.resolve()
        if blend_output.exists():
            raise FileExistsError("Refuse to overwrite existing editable Blender source")
        blend_output.parent.mkdir(parents=True,exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(blend_output))
    report={"schema":"aotl.citadel.phase23.rebuilt_glb.v1",
            "original_v10_bytes":source.stat().st_size,
            "output_glb":str(output),"output_bytes":output.stat().st_size,
            "output_sha256":hashlib.sha256(output.read_bytes()).hexdigest(),
            "mesh_count":len(objects),
            "new_textures":paint["textures"],
            "packed_atlas_count":len(expected_images),
            "original_game_modified":False,"real_godot_import_tested":False}
    audit=output.with_suffix(".qa.json")
    audit.write_text(json.dumps(report,indent=2),encoding="utf-8")
    return report

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--source",required=True,type=Path)
    parser.add_argument("--output",required=True,type=Path)
    parser.add_argument("--blend-output",type=Path,default=None)
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    print(json.dumps(process(args.source,args.output,args.blend_output),indent=2))
