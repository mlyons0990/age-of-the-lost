#!/usr/bin/env python3
"""AOTL R52: non-destructive Blender pose review from the actual Warrior source.

Usage:
  blender -b art/character_sources/AOTL_R51_R50_FullBody_Slash_Source.blend \\
    --python game/crownsfall_lootslice/tools/r52_blender_pose_review.py -- \\
    --output /tmp/aotl_r52_pose_review --action R50_Slash_Grounded_IKBaked_V3

Renders actual source poses. Never saves over the .blend or exports a replacement GLB.
"""
import argparse
import json
import math
import pathlib
import sys

try:
    import bpy
    from mathutils import Vector
except ImportError:
    raise SystemExit("Run from Blender's bundled Python, not ordinary Python")


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--output", required=True)
    p.add_argument("--action", default="R50_Slash_Grounded_IKBaked_V3")
    p.add_argument("--frames", default="1,5,9,12,15,19,23")
    p.add_argument("--size", type=int, default=768)
    p.add_argument("--samples", type=int, default=32)
    return p.parse_args(argv)


def find_armature(action):
    candidates = []
    for obj in bpy.data.objects:
        if obj.type != "ARMATURE":
            continue
        score = len(obj.data.bones)
        if obj.animation_data and obj.animation_data.action == action:
            score += 5000
        candidates.append((score, obj.name, obj))
    if not candidates:
        raise RuntimeError("No armature in Blender source")
    return max(candidates)[2]


def world_bounds(mesh_objects, depsgraph):
    extrema = []
    count = 0
    for obj in mesh_objects:
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        try:
            count += len(mesh.vertices)
            for corner in evaluated.bound_box:
                extrema.append(evaluated.matrix_world @ Vector(corner))
        finally:
            evaluated.to_mesh_clear()
    if not extrema:
        raise RuntimeError("No meshes found for review")
    lo = Vector([min(v[i] for v in extrema) for i in range(3)])
    hi = Vector([max(v[i] for v in extrema) for i in range(3)])
    return lo, hi, count


def bone_sample(armature):
    out = {}
    for pb in armature.pose.bones:
        name = pb.name.lower()
        if any(token in name for token in ("clavic", "shoulder", "upperarm", "upper_arm", "forearm",
                                           "spine", "chest", "pelvis", "hips", "thigh", "foot", "hand")):
            head = armature.matrix_world @ pb.head
            tail = armature.matrix_world @ pb.tail
            out[pb.name] = {
                "head_world_m": [round(float(c), 5) for c in head],
                "tail_world_m": [round(float(c), 5) for c in tail],
                "length_m": round(float((tail - head).length), 5),
            }
    return out


def setup_camera(scene, center, diagonal, azimuth_deg, elevation_deg):
    bpy.ops.object.camera_add(location=(0, 0, 0))
    camera = bpy.context.object
    camera.name = "R52_TEMP_QA_CAMERA"
    radius = max(2.5, diagonal * 1.5)
    az = math.radians(azimuth_deg)
    elev = math.radians(elevation_deg)
    camera.location = center + Vector((radius * math.sin(az) * math.cos(elev),
                                       -radius * math.cos(az) * math.cos(elev),
                                       radius * math.sin(elev)))
    direction = center - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = diagonal * 1.15
    scene.camera = camera
    return camera


def main():
    args = parse_args()
    if not 128 <= args.size <= 4096:
        raise ValueError("--size outside 128..4096")
    frames = [int(n.strip()) for n in args.frames.split(",") if n.strip()]
    if not frames:
        raise ValueError("No frames")
    action = bpy.data.actions.get(args.action)
    if action is None:
        raise RuntimeError("Action not found: %s; available: %s" %
                           (args.action, [a.name for a in bpy.data.actions]))
    rig = find_armature(action)
    if rig.animation_data is None:
        rig.animation_data_create()
    prior_action = rig.animation_data.action
    prior_frame = bpy.context.scene.frame_current
    # In Blender 5.x an action with slots may require the matching slot.
    rig.animation_data.action = action
    scene = bpy.context.scene
    meshes = [o for o in bpy.data.objects if o.type == "MESH" and
              (o.find_armature() == rig or o.parent == rig)]
    if not meshes:
        raise RuntimeError("No meshes bound to chosen armature: %s" % rig.name)
    out = pathlib.Path(args.output)
    out.mkdir(parents=True, exist_ok=True)
    report = {"action": action.name, "rig": rig.name, "bone_count": len(rig.data.bones),
              "mesh_count": len(meshes), "frames": [], "warnings": [],
              "render_provenance": "Actual Blender source mesh, evaluated armature and action frames"}
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = args.size
    scene.render.resolution_y = args.size
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = True
    if hasattr(scene, "eevee"):
        scene.eevee.taa_render_samples = args.samples
    # Action duration is evaluated in the source's own FPS; avoid changing FPS.
    try:
        for f in frames:
            scene.frame_set(f)
            bpy.context.view_layer.update()
            dg = bpy.context.evaluated_depsgraph_get()
            lo, hi, vertices = world_bounds(meshes, dg)
            center = (lo + hi) / 2
            diagonal = max((hi - lo).length, 0.5)
            sample = {"frame": f, "mesh_vertices_evaluated": vertices,
                      "bounds_min_world_m": [round(float(x), 5) for x in lo],
                      "bounds_max_world_m": [round(float(x), 5) for x in hi],
                      "selected_bones": bone_sample(rig), "renders": []}
            for label, az, elev in (("front", 0, 8), ("threequarter", 40, 12),
                                    ("side", 90, 8)):
                camera = setup_camera(scene, center, diagonal, az, elev)
                filename = "r52_%s_f%03d_%s.png" % (label, f, args.action.replace(" ", "_"))
                scene.render.filepath = str(out / filename)
                bpy.ops.render.render(write_still=True)
                sample["renders"].append(filename)
                bpy.data.objects.remove(camera, do_unlink=True)
            report["frames"].append(sample)
    finally:
        scene.frame_set(prior_frame)
        rig.animation_data.action = prior_action
    (out / "r52_pose_review.json").write_text(json.dumps(report, indent=2) + "\n")
    print("R52 pose review complete: %s" % out)


if __name__ == "__main__":
    main()
