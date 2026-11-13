"""AOTL Phase23: reproducible, UV-safe painterly Citadel material atlas upgrade.

Run ONLY on an isolated editable Higgsfield v12 sculpt (309 mesh objects).
- Replaces only the Base Color maps used by the existing ivory/patina material
  nodes and adds an ivy albedo texture to UV-equipped vines.
- Preserves original packed atlas images, original geometry, nav, collision,
  characters, saves and original material references for rollback.
- Saves 1024px stone and 512px ivy RGBA PNGs; images packed in the .blend and
  embedded in glTF. No external image dependencies or internet source.
- Deterministic NumPy seeds, no expensive baked lighting.
"""
from __future__ import annotations
import bpy
import numpy as np
import hashlib
import tempfile
from pathlib import Path

PHASE23_MAPS=(
    ("MAT_AOTL_Phase17_Packed_PaintedIvory",
     "AOTL_Crownsfall_StoneIvory_v04","AOTL_Ph23_IvoryStone_1024",1024,2301,0),
    ("MAT_AOTL_Phase17_Packed_Patina",
     "AOTL_Crownsfall_StonePatina_v04","AOTL_Ph23_WeatheredPatina_1024",1024,2372,1),
    ("MAT_Ivy_Leaves",None,"AOTL_Ph23_PaintedIvy_512",512,2384,2),
)

def _periodic_noise(size:int,periods:int,rng:np.random.Generator) -> np.ndarray:
    lattice=rng.random((periods,periods),dtype=np.float32)
    axes=np.arange(size,dtype=np.float32)*np.float32(periods/size)
    indices=np.floor(axes).astype(np.int32)
    fractions=axes-indices
    smooth=fractions*fractions*(3-2*fractions)
    x0=indices%periods;x1=(indices+1)%periods
    y0=indices%periods;y1=(indices+1)%periods
    sx=smooth[None,:];sy=smooth[:,None]
    a=lattice[y0[:,None],x0[None,:]]
    b=lattice[y0[:,None],x1[None,:]]
    c=lattice[y1[:,None],x0[None,:]]
    d=lattice[y1[:,None],x1[None,:]]
    return (a*(1-sx)+b*sx)*(1-sy)+(c*(1-sx)+d*sx)*sy

def _resample_rgba(image:bpy.types.Image,size:int) -> np.ndarray:
    w,h=image.size
    source=np.empty(w*h*4,dtype=np.float32)
    image.pixels.foreach_get(source)
    source=source.reshape((h,w,4))
    x=np.linspace(0,w-1,size,dtype=np.float32)
    y=np.linspace(0,h-1,size,dtype=np.float32)
    left=np.floor(x).astype(np.int32);right=np.minimum(left+1,w-1)
    lower=np.floor(y).astype(np.int32);upper=np.minimum(lower+1,h-1)
    fx=(x-left)[None,:,None];fy=(y-lower)[:,None,None]
    top=source[lower[:,None],left[None,:],:]*(1-fx)+source[lower[:,None],right[None,:],:]*fx
    bottom=source[upper[:,None],left[None,:],:]*(1-fx)+source[upper[:,None],right[None,:],:]*fx
    return top*(1-fy)+bottom*fy

def _pixels(size:int,seed:int,kind:int,base:bpy.types.Image|None) -> np.ndarray:
    rng=np.random.default_rng(seed)
    maps=[_periodic_noise(size,p,rng) for p in (5,11,23,53,127)]
    macro=(0.47*maps[0]+0.30*maps[1]+0.15*maps[2]+0.06*maps[3]+0.02*maps[4])
    grain=(0.4*maps[2]+0.45*maps[3]+0.15*maps[4])
    yy,xx=np.meshgrid(np.arange(size,dtype=np.float32)/size,
                       np.arange(size,dtype=np.float32)/size,indexing="ij")
    # Slightly diagonal hand-brushed highlights, no harsh tile/jigsaw grid.
    sweep=np.sin((xx*20+yy*13+maps[1]*1.8)*np.float32(2*np.pi))
    sweep=(sweep*.5+.5)*(0.7*maps[2]+0.3*maps[3])
    if base is not None:
        old=_resample_rgba(base,size)
        rgb=old[:,:,:3].copy()
        if kind==0:
            rgb*=0.90+0.18*macro[:,:,None]
            rgb+=0.060*(grain[:,:,None]-0.5)
            rgb+=np.array([0.012,0.004,-0.014],dtype=np.float32)[None,None,:]
        else:
            rgb*=0.86+0.19*macro[:,:,None]
            rgb+=0.067*(grain[:,:,None]-0.5)
            rgb+=np.array([-0.015,-0.002,0.012],dtype=np.float32)[None,None,:]
            # Low-key grey/cobalt patina in recessed stone pores.
            moss=np.maximum(0.0,0.32-maps[2])[:,:,None]
            rgb=rgb*(1-0.16*moss)+np.array([0.20,0.25,0.27],dtype=np.float32)*0.16*moss
        rgb+=((sweep-0.3)*0.025)[:,:,None]
        rgba=np.concatenate([np.clip(rgb,0.06,0.97),
                              np.ones((size,size,1),dtype=np.float32)],axis=2)
    else:
        # More tonal variation across the same ivy silhouettes; no alpha holes.
        lower=np.array([0.115,0.195,0.112],dtype=np.float32)
        upper=np.array([0.35,0.47,0.23],dtype=np.float32)
        pigment=np.clip((macro-0.24)*1.9+0.18*grain,0,1)
        rgb=lower[None,None,:]*(1-pigment[:,:,None])+upper[None,None,:]*pigment[:,:,None]
        veins=0.017*np.sin(2*np.pi*(xx*33+yy*12+maps[1]))
        rgb+=veins[:,:,None]
        rgba=np.concatenate([np.clip(rgb,0.03,0.8),
                              np.ones((size,size,1),dtype=np.float32)],axis=2)
    return np.ascontiguousarray(rgba,dtype=np.float32)

def install():
    if sum(o.type=="MESH" for o in bpy.data.objects)!=309:
        raise RuntimeError("Refuse to run outside 309-mesh verified Citadel v12 sculpt")
    if bpy.data.texts.get("PH22_Temporary_GLB_Transfer_Base64"):
        raise RuntimeError("Remove temporary binary transport before material pass")
    for material,old,new,size,seed,kind in PHASE23_MAPS:
        if material not in bpy.data.materials:
            raise RuntimeError(f"Material missing: {material}")
        if new in bpy.data.images:
            raise RuntimeError(f"Phase23 image already present: {new}")
        if old and (old not in bpy.data.images or not bpy.data.images[old].packed_file):
            raise RuntimeError(f"Original packed atlas missing: {old}")
    out=[]
    with tempfile.TemporaryDirectory() as directory:
        for material_name,old_name,new_name,size,seed,kind in PHASE23_MAPS:
            source=bpy.data.images[old_name] if old_name else None
            pixels=_pixels(size,seed,kind,source)
            image=bpy.data.images.new(new_name,width=size,height=size,alpha=True)
            image.pixels.foreach_set(pixels.reshape(-1))
            image.update()
            image.file_format="PNG"
            path=Path(directory)/(new_name+".png")
            image.filepath_raw=str(path)
            image.save()
            byte_hash=hashlib.sha256(path.read_bytes()).hexdigest()
            image.pack()
            image.colorspace_settings.name="sRGB"
            material=bpy.data.materials[material_name]
            material.use_nodes=True
            existing=[n for n in material.node_tree.nodes if n.type=="TEX_IMAGE"]
            if old_name:
                if len(existing)!=1 or existing[0].image.name!=old_name:
                    raise RuntimeError(f"Original material node unexpectedly changed: {material_name}")
                tex=existing[0]
                tex.image=image
                tex.name="PH23_Painterly_Albedo"
            else:
                tex=material.node_tree.nodes.new("ShaderNodeTexImage")
                tex.name="PH23_Painterly_Albedo"
                tex.image=image
                bsdf=material.node_tree.nodes.get("Principled BSDF")
                if bsdf is None:
                    raise RuntimeError(f"Missing BSDF: {material_name}")
                material.node_tree.links.new(tex.outputs["Color"],bsdf.inputs["Base Color"])
            material["AOTL_Ph23_SourceImage"]=old_name or "native_color"
            material["AOTL_Ph23_PNG_SHA256"]=byte_hash
            out.append({"material":material_name,"image":new_name,"size":size,
                        "png_sha256":byte_hash,"packed_bytes":image.packed_file.size,
                        "source":old_name})
    return {"phase":"23","textures":out,"scene_mesh_count":309,
            "original_images_kept":all(im in bpy.data.images for im in
                ("AOTL_Crownsfall_StoneIvory_v04","AOTL_Crownsfall_StonePatina_v04")),
            "real_game_f5_verified":False,"approved_art_match":False}

if __name__=="__main__":
    print(install())
