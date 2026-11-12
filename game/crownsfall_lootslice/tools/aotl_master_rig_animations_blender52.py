"""AOTL master humanoid animation foundation — Blender 5.2 / Higgsfield 3D Jutsu.

Run against the free procedural source in Higgsfield project:
https://higgsfield.ai/3d-jutsu/088e8199-50e8-4554-b0be-b108a6b2203a

Creates distinct, editable, named Blender Slotted Actions for the 58-bone
humanoid rig. No credits / network / paid assets needed. This file intentionally
does not write over the working Godot proxy or an existing .blend file.
Procedural motion is an INITIAL BASELINE, not polished mocap or shipped combat.
"""
import bpy
import math

RIG_NAME = "RIG_AOTL_Master_Humanoid_58"
rig = bpy.data.objects[RIG_NAME]
assert rig.type == "ARMATURE"
assert len(rig.data.bones) == 58, "Bone contract changed; inspect before animating"
D = math.radians

# Rotation values in degrees: animation authoring table stays human-readable.
# Frame lengths at 30fps; every clip starts and ends at neutral rest as appropriate.
ANIMS = {
 "Idle": {
   "frames": 48, "loop": True,
   "keys": [
    (1, {"SpineA":(0,0,0), "Chest":(0,0,0), "UpperArmL":(0,0,0), "UpperArmR":(0,0,0)}),
    (13, {"SpineA":(2,0,0), "Chest":(-1,0,1), "UpperArmL":(-2,0,0), "UpperArmR":(-2,0,0)}),
    (25, {"SpineA":(3,0,0), "Chest":(-2,0,-1), "UpperArmL":(-3,0,0), "UpperArmR":(-3,0,0)}),
    (37, {"SpineA":(1,0,0), "Chest":(-1,0,0)}),
    (48, {}),
   ]},
 "Walk": {
   "frames": 25, "loop": True,
   "keys": [
    (1, {"ThighL":(30,0,0), "ThighR":(-30,0,0), "UpperArmL":(-15,0,0), "UpperArmR":(15,0,0), "SpineA":(3,0,0)}),
    (7, {"ThighL":(0,0,0), "ThighR":(0,0,0), "KneeL":(18,0,0), "UpperArmL":(0,0,0), "UpperArmR":(0,0,0)}),
    (13, {"ThighL":(-30,0,0), "ThighR":(30,0,0), "UpperArmL":(15,0,0), "UpperArmR":(-15,0,0), "SpineA":(3,0,0)}),
    (19, {"ThighL":(0,0,0), "ThighR":(0,0,0), "KneeR":(18,0,0)}),
    (25, {"ThighL":(30,0,0), "ThighR":(-30,0,0), "UpperArmL":(-15,0,0), "UpperArmR":(15,0,0), "SpineA":(3,0,0)}),
   ]},
 "Run": {
   "frames": 19, "loop": True,
   "keys": [
    (1, {"ThighL":(48,0,0), "ThighR":(-45,0,0), "KneeR":(35,0,0), "UpperArmL":(-34,0,0), "UpperArmR":(34,0,0), "SpineA":(11,0,0)}),
    (5, {"ThighL":(0,0,0), "ThighR":(0,0,0), "KneeL":(35,0,0), "SpineA":(12,0,0)}),
    (10, {"ThighL":(-45,0,0), "ThighR":(48,0,0), "KneeL":(35,0,0), "UpperArmL":(34,0,0), "UpperArmR":(-34,0,0), "SpineA":(11,0,0)}),
    (15, {"ThighL":(0,0,0), "ThighR":(0,0,0), "KneeR":(35,0,0), "SpineA":(12,0,0)}),
    (19, {"ThighL":(48,0,0), "ThighR":(-45,0,0), "KneeR":(35,0,0), "UpperArmL":(-34,0,0), "UpperArmR":(34,0,0), "SpineA":(11,0,0)}),
   ]},
 "Slash": {
   "frames": 23, "loop": False,
   "keys": [
    (1, {}),
    (5, {"Chest":(0,0,-30), "SpineB":(0,0,-15), "UpperArmR":(-45,-12,24), "ForearmR":(65,0,0), "UpperArmL":(-15,0,0)}),
    (10, {"Chest":(0,0,32), "SpineB":(0,0,16), "UpperArmR":(57,0,-65), "ForearmR":(10,0,0), "HandR":(0,0,25)}),
    (15, {"Chest":(0,0,14), "UpperArmR":(15,0,-25)}),
    (23, {}),
   ]},
 "HeavySlash": {
   "frames": 34, "loop": False,
   "keys": [
    (1, {}),
    (9, {"Hips":(0,0,-15), "Chest":(0,0,-42), "UpperArmR":(-75,0,35), "ForearmR":(70,0,0), "ThighR":(-15,0,0)}),
    (18, {"Hips":(0,0,18), "Chest":(0,0,46), "UpperArmR":(92,0,-85), "ForearmR":(0,0,0), "ThighL":(15,0,0)}),
    (25, {"Chest":(0,0,12), "UpperArmR":(20,0,-18)}),
    (34, {}),
   ]},
 "Thrust": {
   "frames": 25, "loop": False,
   "keys": [
    (1, {}),
    (6, {"ThighL":(25,0,0), "ThighR":(-12,0,0), "Chest":(0,0,-12), "UpperArmR":(-45,0,20), "ForearmR":(60,0,0)}),
    (12, {"ThighL":(36,0,0), "Chest":(10,0,8), "UpperArmR":(70,0,2), "ForearmR":(-16,0,0), "HandR":(0,0,8)}),
    (19, {"ThighL":(20,0,0), "Chest":(3,0,0), "UpperArmR":(15,0,0)}),
    (25, {}),
   ]},
 "Dodge": {
   "frames": 24, "loop": False,
   "keys": [
    (1, {}),
    (4, {"Hips":(18,0,0), "SpineA":(12,0,0), "KneeL":(40,0,0), "KneeR":(40,0,0), "UpperArmL":(-55,0,0), "UpperArmR":(-55,0,0)}),
    (8, {"Hips":(105,0,0), "KneeL":(80,0,0), "KneeR":(80,0,0), "UpperArmL":(-95,0,0), "UpperArmR":(-95,0,0)}),
    (12, {"Hips":(200,0,0), "KneeL":(85,0,0), "KneeR":(85,0,0), "UpperArmL":(-90,0,0), "UpperArmR":(-90,0,0)}),
    (17, {"Hips":(315,0,0), "KneeL":(40,0,0), "KneeR":(40,0,0), "UpperArmL":(-48,0,0), "UpperArmR":(-48,0,0)}),
    (21, {"Hips":(360,0,0), "KneeL":(12,0,0), "KneeR":(12,0,0)}),
    (24, {"Hips":(360,0,0)}),
   ],
   "vertical": [(1,0), (4,-.13), (8,-.18), (12,-.10), (17,-.09), (21,0), (24,0)],
 },
 "Cast": {
   "frames": 42, "loop": False,
   "keys": [
    (1, {}),
    (10, {"Chest":(-8,0,0), "UpperArmL":(-65,-25,-12), "UpperArmR":(-65,25,12), "ForearmL":(-55,0,0), "ForearmR":(-55,0,0)}),
    (23, {"Chest":(-12,0,0), "UpperArmL":(-86,-28,-14), "UpperArmR":(-86,28,14), "ForearmL":(-67,0,0), "ForearmR":(-67,0,0), "Head":(-10,0,0)}),
    (32, {"Chest":(8,0,0), "UpperArmL":(-42,-14,-8), "UpperArmR":(-42,14,8)}),
    (42, {}),
   ]},
 "CastRelease": {
   "frames": 21, "loop": False,
   "keys": [
    (1, {"Chest":(-10,0,0), "UpperArmL":(-65,0,0), "UpperArmR":(-65,0,0), "ForearmL":(-50,0,0), "ForearmR":(-50,0,0)}),
    (6, {"Chest":(14,0,0), "UpperArmL":(-95,0,0), "UpperArmR":(-95,0,0), "ForearmL":(-13,0,0), "ForearmR":(-13,0,0)}),
    (13, {"Chest":(6,0,0), "UpperArmL":(-40,0,0), "UpperArmR":(-40,0,0)}),
    (21, {}),
   ]},
 "HitReact": {
   "frames": 17, "loop": False,
   "keys": [
    (1, {}),
    (5, {"SpineB":(-22,0,8), "Chest":(-14,0,15), "Head":(13,0,0), "UpperArmL":(35,0,0), "UpperArmR":(35,0,0)}),
    (11, {"SpineB":(-7,0,3), "Chest":(-5,0,4)}),
    (17, {}),
   ]},
}
rig.animation_data_create()
anim=rig.animation_data
created=[]
for clip_name,spec in ANIMS.items():
  action_name="AOTL_"+clip_name
  prior=bpy.data.actions.get(action_name)
  if prior: bpy.data.actions.remove(prior)
  action=bpy.data.actions.new(name=action_name)
  action.use_fake_user=True
  slot=action.slots.new(id_type='OBJECT',name=rig.name)
  strip=action.layers.new("Motion").strips.new(type='KEYFRAME')
  bag=strip.channelbag(slot,ensure=True)
  used=sorted({bn for _,pose in spec['keys'] for bn in pose.keys()})
  if 'vertical' in spec: used.append('Hips')
  # New actions are independent; make zero/rest tracks for every involved bone
  # at each authored timing sample to prevent unintended carry-over.
  for bn in used:
    assert bn in rig.pose.bones, bn
    rig.pose.bones[bn].rotation_mode='XYZ'
    path=f'pose.bones["{bn}"].rotation_euler'
    for axis in range(3):
      fc=bag.fcurves.new(data_path=path,index=axis,group_name=bn)
      for f,pose in spec['keys']:
        xyz=pose.get(bn,(0,0,0))
        kp=fc.keyframe_points.insert(float(f),D(xyz[axis]),options={'FAST'})
        kp.interpolation='BEZIER' if clip_name in ('Idle','Cast','HitReact') else 'LINEAR'
      fc.update()
  if 'vertical' in spec:
    for axis in range(3):
      fc=bag.fcurves.new(data_path='pose.bones["Hips"].location',index=axis,group_name='Hips')
      for f,z in spec['vertical']:
        kp=fc.keyframe_points.insert(float(f),z if axis==2 else 0,options={'FAST'})
        kp.interpolation='BEZIER'
      fc.update()
  action["AOTL_ClipFrames"]=int(spec['frames'])
  action["AOTL_Loop"]=bool(spec['loop'])
  created.append((action_name,len(used),spec['frames']))
# The active action is the calm editable rest/idle. Distinct actions exist as saved
# datablocks; the future retarget/export pass should verify each clip in Godot.
anim.action=bpy.data.actions['AOTL_Idle']
anim.action_slot=anim.action.slots[0]
rig["AOTL_Animation_Clips"]=",".join(ANIMS)
rig["AOTL_Animation_Status"]="Authored procedural keyframes; physics, contact, IK and Godot import not yet QA-validated"
bpy.context.scene.frame_set(1)
result={'created_actions':created,'active':anim.action.name,'bone_count':len(rig.data.bones)}
