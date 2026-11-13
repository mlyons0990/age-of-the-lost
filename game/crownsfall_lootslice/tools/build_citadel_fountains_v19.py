"""Phase19 Higgsfield Citadel v6 sculpt source: twin terrace fountains.

Run in Blender 5.2 against previously verified editable revision 5 only.
This is an add-on visual-scene script, not a live Godot game edit.
Built from original mesh objects; no collision, nav, save, or rig owners.
"""
import bpy
import math

EXPECTED_PREPASS_MESHES=481
PREFIX="PH19_Fountain_"

def build():
    meshes=[o for o in bpy.data.objects if o.type=="MESH"]
    if len(meshes)!=EXPECTED_PREPASS_MESHES:
        raise RuntimeError("Requires original verified 481-mesh v5 sculpt")
    if any(o.name.startswith(PREFIX) for o in bpy.data.objects):
        raise RuntimeError("Refusing duplicate fountain installation")
    for i in range(1,10):
        if bpy.data.objects.get(f"STAIR_Tread_{i:02}") is None:
            raise RuntimeError("Original nine-tread route is incomplete")
    stone=bpy.data.materials["MAT_Sunlit_Pale_Stone"]
    brass=bpy.data.materials["MAT_Brushed_Royal_Brass"]
    patina=bpy.data.materials["MAT_AOTL_Phase17_Packed_Patina"]
    flowers=bpy.data.materials["MAT_White_Pink_Flowers"]
    water=bpy.data.materials.get("MAT_Phase19_FountainWater")
    if water is None:
        water=bpy.data.materials.new("MAT_Phase19_FountainWater")
        water.diffuse_color=(0.28,0.62,0.77,0.62)
        water.use_nodes=True
        bsdf=water.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value=(0.20,0.56,0.73,1.0)
        bsdf.inputs["Roughness"].default_value=0.16
        bsdf.inputs["Alpha"].default_value=0.64
        water.surface_render_method="DITHERED"
    created=[]
    def obj(name,vertices,faces,mat):
        mesh=bpy.data.meshes.new(name+"_Mesh")
        mesh.from_pydata(vertices,[],faces)
        mesh.update()
        mesh.materials.append(mat)
        item=bpy.data.objects.new(name,mesh)
        bpy.context.scene.collection.objects.link(item)
        item["AOTL_visual_only"]=True
        item["AOTL_collision"]=False
        created.append(item.name)
        return item
    def block(name,center,dims,mat):
        x,y,z=center;dx,dy,dz=dims
        vertices=[(x+u*dx/2,y+w*dy/2,z+t*dz/2) for u,w,t in
           [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
            (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
        faces=[(0,3,2,1),(4,5,6,7),(0,1,5,4),
               (1,2,6,5),(2,3,7,6),(3,0,4,7)]
        return obj(name,vertices,faces,mat)
    def basin(name,x,y,z,mat,radius=0.56):
        vertices=[];faces=[]
        for j in range(5):
            frac=j/4
            yy=y-0.25+frac*0.50
            for i in range(13):
                theta=math.pi*i/12
                xx=x+radius*math.cos(theta)
                zz=z+0.20*(math.sin(theta)**2)+0.07*abs(2*frac-1)
                vertices.append((xx,yy,zz))
        for j in range(4):
            for i in range(12):
                a=j*13+i
                faces.append((a,a+1,a+14,a+13))
        return obj(name,vertices,faces,mat)
    def stream(name,x,y,z):
        vertices=[];faces=[]
        for i in range(19):
            t=i/18
            xx=x+0.018*math.sin(t*math.pi*5)
            yy=y+0.38*t
            zz=z+0.18*(1-t)-t*t
            width=0.035*(1-0.5*t)
            vertices.extend([(xx-width,yy,zz),(xx+width,yy,zz)])
        for i in range(18):
            a=2*i
            faces.append((a,a+1,a+3,a+2))
        return obj(name,vertices,faces,water)
    def fleur(name,x,y,z):
        vertices=[(x,y,z)]
        for j in range(16):
            angle=j*math.pi/8
            radius=0.17 if j%2==0 else 0.08
            vertices.append((x+radius*math.cos(angle),
                             y-0.009,z+radius*math.sin(angle)))
        return obj(name,vertices,
                   [(0,j,j+1 if j<16 else 1) for j in range(1,17)],
                   flowers)
    for sign,side in [(-1,"L"),(1,"R")]:
        x=sign*7.10;y=3.60;floor=1.80
        block(f"{PREFIX}{side}_BackRelief",(x,y+0.29,floor+1.02),(1.48,.16,1.92),stone)
        block(f"{PREFIX}{side}_StonePlinth",(x,y,floor+.16),(1.63,.76,.32),stone)
        block(f"{PREFIX}{side}_BasinLip",(x,y-.13,floor+.55),(1.58,.73,.11),stone)
        basin(f"{PREFIX}{side}_ConcaveBasin",x,y-.13,floor+.52,patina)
        for sub in [-1,1]:
            block(f"{PREFIX}{side}_FlutedPier_{'L' if sub<0 else 'R'}",
                  (x+sub*.64,y+.18,floor+1.13),(.16,.19,1.66),stone)
        block(f"{PREFIX}{side}_Cornice",(x,y+.15,floor+2.04),(1.69,.28,.15),stone)
        block(f"{PREFIX}{side}_Spout",(x,y-.025,floor+1.52),(.21,.32,.14),brass)
        block(f"{PREFIX}{side}_BlueMosaic",(x,y+.192,floor+1.10),(.78,.015,.79),patina)
        stream(f"{PREFIX}{side}_WaterStream",x,y-.12,floor+1.34)
        for k,offset in enumerate([-.31,0,.31]):
            fleur(f"{PREFIX}{side}_CarvedFleur_{k:02}",
                  x+offset,y+.15,floor+1.79)
    if len(created)!=26:
        raise RuntimeError(f"Expected 26 generated fountain details, got {len(created)}")
    return {"mesh_count":len([o for o in bpy.data.objects if o.type=="MESH"]),
            "fountain_details":len(created),"names":created}

if __name__=="__main__":
    print(build())
