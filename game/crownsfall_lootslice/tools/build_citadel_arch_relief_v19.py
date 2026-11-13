"""Phase19 Higgsfield Citadel v7 — carved Gothic arch rib and shadow-cut relief.

Run with Blender 5.2 on exact revision 6 of the editable Citadel scene.
Raises only 64 noncollision ornamental meshes. Does not modify the 32 original
arch voussoirs, gameplay, stairs, navigation or saved data.
"""
import bpy

def build():
    if len([o for o in bpy.data.objects if o.type=="MESH"])!=507:
        raise RuntimeError("Requires the exact 507-mesh Higgsfield v6 base")
    if any(o.name.startswith("PH19_Arch_") for o in bpy.data.objects):
        raise RuntimeError("Refusing duplicate arch relief")
    ivory=bpy.data.materials["MAT_AOTL_Phase17_Packed_PaintedIvory"]
    patina=bpy.data.materials["MAT_AOTL_Phase17_Packed_Patina"]
    bases=[bpy.data.objects.get(f"GATE_Gothic_Voussoir_{i:02}") for i in range(1,33)]
    if any(o is None for o in bases):
        raise RuntimeError("Expected all 32 Gothic arch source stones")
    created=[]
    def visual(name,verts,faces,mat):
        mesh=bpy.data.meshes.new(name+"_Mesh")
        mesh.from_pydata(verts,[],faces)
        mesh.update()
        mesh.materials.append(mat)
        obj=bpy.data.objects.new(name,mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj["AOTL_visual_only"]=True
        obj["AOTL_collision"]=False
        created.append(name)
    for i,base in enumerate(bases,1):
        points=[base.matrix_world @ vertex.co for vertex in base.data.vertices]
        xmin=min(v.x for v in points); xmax=max(v.x for v in points)
        zmin=min(v.z for v in points); zmax=max(v.z for v in points)
        ymin=min(v.y for v in points)
        x=(xmin+xmax)*0.5;z=(zmin+zmax)*0.5
        y=ymin-0.028
        dx=min((xmax-xmin)*0.31,0.070)
        dz=min((zmax-zmin)*0.22,0.16)
        vertices=[(x,y-0.024,z),(x,y,z+dz),(x+dx,y,z),
                  (x,y,z-dz),(x-dx,y,z)]
        visual(f"PH19_Arch_LancetRelief_{i:02}",vertices,
               [(0,1,2),(0,2,3),(0,3,4),(0,4,1)],ivory)
        ygroove=ymin-0.018
        bottom=z-dz*1.55
        width=0.008;height=0.09
        vertices=[(x-width,ygroove,bottom-height),
                  (x+width,ygroove,bottom-height),
                  (x+width,ygroove,bottom+height),
                  (x-width,ygroove,bottom+height)]
        visual(f"PH19_Arch_ShadowCut_{i:02}",vertices,[(0,1,2,3)],patina)
    assert len(created)==64
    return {"added_arch_details":len(created),
            "scene_mesh_count":len([o for o in bpy.data.objects if o.type=="MESH"])}
if __name__=="__main__":
    print(build())
