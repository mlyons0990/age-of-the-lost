"""Blender 5.2 batch export for the *editable* Higgsfield AOTL 58-bone rig.

Run (Blender UI): open the AOTL Master Humanoid 3D Jutsu .blend, then open this
file in Blender Scripting and press Run Script. It produces a multi-action GLB
in the same folder as the .blend. Or from a shell:
  blender -b MasterHumanoid.blend --python export_master_humanoid_v07_blender52.py

Unlike the hosted 3D Jutsu quick GLB (which exported one reel), the tested
explicit export_animation_mode='ACTIONS' includes all 34 source actions,
including the eight AOTL_Dodge_* directions. No paid provider is required.
"""
import bpy, json, struct
from pathlib import Path

rig = bpy.data.objects.get('RIG_AOTL_Master_Humanoid_58')
if rig is None or rig.type != 'ARMATURE' or len(rig.data.bones) != 58:
    raise RuntimeError('Expected the 58-bone AOTL rig; no export performed')
required = {f'AOTL_Dodge_{d}' for d in ('N','NE','E','SE','S','SW','W','NW')}
missing = required - set(a.name for a in bpy.data.actions)
if missing:
    raise RuntimeError(f'Missing directional dodge actions: {sorted(missing)}')
folder = Path(bpy.data.filepath).parent if bpy.data.filepath else Path.home()
out = folder / 'AOTL_MasterHumanoid_58_V07_AllActions.glb'
bpy.ops.export_scene.gltf(
    filepath=str(out), export_format='GLB', use_selection=False,
    export_animations=True, export_animation_mode='ACTIONS',
    export_force_sampling=True, export_cameras=False, export_lights=False,
)
with out.open('rb') as src:
    src.read(12)
    n, typ = struct.unpack('<II', src.read(8))
    gltf = json.loads(src.read(n).decode('utf-8'))
names = {a.get('name') for a in gltf.get('animations', [])}
if not required.issubset(names):
    raise RuntimeError(f'Exported GLB lacks actions: {sorted(required - names)}')
print('AOTL exported',out,out.stat().st_size,'bytes; animations:',len(names))
print('Directional dodge clips:', sorted(required))
