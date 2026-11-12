# AOTL Humanoid V02 portable mesh

Higgsfield 3D Jutsu [editable project](https://higgsfield.ai/3d-jutsu/088e8199-50e8-4554-b0be-b108a6b2203a), source Blender revision **7**.

The git-tracked `AOTL_Humanoid_Master_V02.glb.gz.b64` contains the **bit-exact** compressed portable GLB because the available GitHub text writer cannot commit raw binary directly. To create the real `models/AOTL_Humanoid_Master_V02.glb`:

```sh
python game/crownsfall_lootslice/tools/restore_rig_v02.py
```

The restoration script checks SHA-256 and refuses to overwrite a different local model. **58 joints**, seven attachment sockets, a 486-frame 30-fps action reel with 16 subclips. Original source actions remain editable in the Higgsfield .blend. Godot automatically splits the reel into playable clips; see `data/humanoid_v02_reel_manifest.json`.

This is a **refined procedural animation-ready prototype**, not a final approved 2026-quality production character. No paid Higgsfield credits used. Texture baking, cloth simulation, foot IK and hand deformation need further work.
