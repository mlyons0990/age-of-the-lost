"""R53: rebuild the Warrior's arm skin weights for linear-blend skinning (as Godot skins it).

Run with Blender 5.2 (or the `bpy` 5.2 module):
  python r53_arm_reweight.py -- <R52 source .blend> <out R53 .blend> <out weights .json> [report .json]

Why: the R52 audit left ~42% p95 edge strain on the right arm in Slash. The arm meshes
blended Forearm weight about 20 cm up the upper arm and spread the (never animated)
Elbow and ArmTwist bones across the whole limb, so a bent elbow sheared the biceps.

How: every vertex gets a coordinate s along the shoulder→elbow→wrist→hand chain
(nearest point on the bone polyline). Weights are smoothstep blends of s:
  shoulder cap: Clavicle ↔ UpperArm, elbow: UpperArm ↔ Forearm, wrist: Forearm ↔ Hand,
  with ArmTwist taking up to half the upper-arm share toward the elbow (it is reserved
  for future twist keys; today it moves with UpperArm). Elbow (unanimated) gets none.
The blend widths below were chosen by a grid search over every second frame of all seven
clips, minimising RMS edge strain + half the 99th-percentile worst-vertex strain (see
r53_arm_reweight_search in docs/R53_ARM_SKINNING_QA.md). Only vertex-group weights change:
topology, UVs, materials, other meshes, the rig and all actions are untouched.
"""
import bpy, sys, json, os
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from r53_arm_strain import arm_param, measure

BONES = ["Clavicle", "UpperArm", "ArmTwist", "Elbow", "Forearm", "Hand"]
# (shoulder half-width, shoulder centre, elbow half-width, elbow offset, wrist half-width, clavicle cap)
PARAMS = (0.10, -0.08, 0.16, -0.03, 0.06, 0.30)
ARMS = ["V04_SKIN_ArticulatedArmL", "V04_SKIN_ArticulatedArmR"]
CLIPS = ["R50_Slash_Grounded_IKBaked_V3", "Slash", "Idle", "Walk", "Run", "Dodge", "Cast"]


def ss(e0, e1, x):
    t = np.clip((x - e0) / max(e1 - e0, 1e-6), 0, 1)
    return t * t * (3 - 2 * t)


def weights(o, rig, params=PARAMS):
    ws, cs, we, eo, ww, cc = params
    s, _, cum = arm_param(o, rig, o.name[-1])
    elbow, wrist = cum[1], cum[2]
    W = np.zeros((len(s), 6))
    cl = (1 - ss(cs - ws, cs + ws, s)) * cc
    f = ss(elbow + eo - we, elbow + eo + we, s)
    h = ss(wrist - ww, wrist + ww, s)
    up = (1 - cl) * (1 - f)
    tw = up * 0.5 * ss(0.06, elbow * 0.75, s)
    W[:, 0] = cl; W[:, 1] = up - tw; W[:, 2] = tw; W[:, 4] = f * (1 - h); W[:, 5] = f * h
    # at most four influences (glTF JOINTS_0), renormalised
    for row in W:
        if (row > 0).sum() > 4:
            row[np.argsort(row)[:-4]] = 0
    W[W < 1e-4] = 0
    return W / W.sum(1, keepdims=True)


def apply(o, W):
    side = o.name[-1]
    for k, b in enumerate(BONES):
        g = o.vertex_groups[b + side]
        g.remove(list(range(len(o.data.vertices))))
        for v in np.nonzero(W[:, k])[0]:
            g.add([int(v)], float(W[v, k]), 'REPLACE')


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    src, out_blend, out_w = argv[:3]
    report_path = argv[3] if len(argv) > 3 else None
    bpy.ops.wm.open_mainfile(filepath=src)
    rig = [x for x in bpy.data.objects if x.type == 'ARMATURE'][0]
    report, dump = {"params": PARAMS, "clips": CLIPS, "frame_step": 2}, {}
    for name in ARMS:
        o = bpy.data.objects[name]
        _, _, _, before = measure(o, rig, CLIPS, 2)
        W = weights(o, rig)
        apply(o, W)
        _, _, _, after = measure(o, rig, CLIPS, 2)
        stat = lambda xs: {"mean_frame_p95_pct": round(float(np.mean([p for *_, p in xs])) * 100, 2),
                           "worst_frame_p95_pct": round(float(max(p for *_, p in xs)) * 100, 2),
                           "worst_frame": max(xs, key=lambda x: x[2])[:2]}
        report[name] = {"r52": stat(before), "r53": stat(after)}
        print(name, report[name])
        dump[name] = {"bones": [b + name[-1] for b in BONES],
                      "local_positions": [list(map(lambda c: round(c, 6), v.co[:])) for v in o.data.vertices],
                      "weights": [[round(float(x), 6) for x in row] for row in W]}
    bpy.ops.wm.save_as_mainfile(filepath=out_blend, compress=True)
    json.dump(dump, open(out_w, "w"))
    if report_path:
        json.dump(report, open(report_path, "w"), indent=1)


if __name__ == "__main__":
    main()
