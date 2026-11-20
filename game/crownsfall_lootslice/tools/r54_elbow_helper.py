"""R54: turn the Warrior's never-keyed Elbow bone into a half-swing elbow helper.

Run with Blender 5.2 (or the `bpy` 5.2 module):
  python r54_elbow_helper.py -- <R53 .blend> <out R54 .blend> <out weights .json> [report .json]

Linear-blend skinning pinches an elbow because every vertex in the crease is an average of
two transforms ~65° apart. R54 adds a third transform halfway between them:

- Elbow (child of UpperArm, parent of Forearm, unanimated through R53) is keyed in every clip to
  half of the forearm's *swing* relative to the upper arm, pivoting on the forearm head. Twist
  about the forearm's own axis is excluded (a twisting helper shears the forearm skin).
- Forearm is re-keyed with the inverse, so its armature-space pose — and therefore hand, weapon,
  shield and every IK/socket result — is unchanged frame for frame.
- Arm skin across the elbow window uses quadratic Bernstein weights: UpperArm (1-t)², Elbow 2t(1-t),
  Forearm t², with t running across s ∈ elbow + offset ± width. Shoulder, twist and wrist blends are R53's.

Parameters came from a grid search over every second frame of all seven clips (RMS edge strain +
½·p99 worst-vertex strain), armature-only, as Godot skins it.
"""
import bpy, sys, os, json, math
import numpy as np
from mathutils import Matrix, Quaternion
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import r53_arm_reweight as R53
from r53_arm_strain import arm_param, measure

ALPHA = 0.5     # helper takes this fraction of the forearm swing
WIDTH = 0.24    # half-width (m along the arm) of the elbow blend window
OFFSET = 0.02   # window centre relative to the forearm head (m, + toward the hand)
BONES = R53.BONES


def swing_only(q, axis):
    """Swing part of q (q = swing @ twist, twist about `axis`)."""
    v = q.axis * math.sin(q.angle / 2.0)
    p = axis * v.dot(axis)
    tw = Quaternion((q.w, p.x, p.y, p.z))
    if tw.magnitude < 1e-9:
        return q.copy()
    tw.normalize()
    return q @ tw.inverted()


def helper_offset(rig, side, alpha=ALPHA):
    """Armature-space helper H for the current frame: D_elbow = D_upper @ H."""
    pb = rig.pose.bones
    D = {b: pb[b + side].matrix @ rig.data.bones[b + side].matrix_local.inverted() for b in ("UpperArm", "Forearm")}
    A = D["UpperArm"].inverted() @ D["Forearm"]
    pivot = rig.data.bones["Forearm" + side].head_local
    axis = (rig.data.bones["Hand" + side].head_local - pivot).normalized()
    qh = Quaternion().slerp(swing_only(A.to_quaternion(), axis), alpha)
    return D["UpperArm"], Matrix.Translation(pivot) @ qh.to_matrix().to_4x4() @ Matrix.Translation(-pivot)


def weights(o, rig):
    W = R53.weights(o, rig)
    s, _, cum = arm_param(o, rig, o.name[-1])
    elbow = cum[1]
    t = np.clip((s - (elbow + OFFSET - WIDTH)) / (2 * WIDTH), 0, 1)
    up, low = W[:, 1] + W[:, 2], W[:, 4] + W[:, 5]
    arm = up + low
    tw = np.where(up > 0, W[:, 2] / np.maximum(up, 1e-9), 0)
    hf = np.where(low > 0, W[:, 5] / np.maximum(low, 1e-9), 0)
    u, e, l = (1 - t) ** 2, 2 * t * (1 - t), t ** 2
    N = np.zeros_like(W)
    N[:, 0] = W[:, 0]
    N[:, 1], N[:, 2], N[:, 3] = arm * u * (1 - tw), arm * u * tw, arm * e
    N[:, 4], N[:, 5] = arm * l * (1 - hf), arm * l * hf
    for row in N:
        if (row > 0).sum() > 4:
            row[np.argsort(row)[:-4]] = 0
    N[N < 1e-4] = 0
    return N / N.sum(1, keepdims=True)


def bake_helper(rig, actions):
    """Key Elbow (helper) and Forearm (compensated) on every frame of every action."""
    for a in actions:
        act = bpy.data.actions[a]
        rig.animation_data.action = act
        try:
            rig.animation_data.action_slot = act.slots[0]
        except Exception:
            pass
        f0, f1 = [int(x) for x in act.frame_range]
        poses = {}
        for f in range(f0, f1 + 1):
            bpy.context.scene.frame_set(f)
            poses[f] = {}
            for side in "LR":
                du, H = helper_offset(rig, side)
                poses[f][side] = (du @ H @ rig.data.bones["Elbow" + side].matrix_local,
                                  rig.pose.bones["Forearm" + side].matrix.copy())
        # replace the Elbow/Forearm curves with per-frame keys
        cb = act.layers[0].strips[0].channelbag(act.slots[0])
        for fc in list(cb.fcurves):
            if any(fc.data_path == 'pose.bones["%s%s"].%s' % (b, s, p) for b in ("Elbow", "Forearm") for s in "LR" for p in ("rotation_euler", "location")):
                cb.fcurves.remove(fc)
        prev = {}
        for f in range(f0, f1 + 1):
            bpy.context.scene.frame_set(f)
            for side in "LR":
                pe, pf = poses[f][side]
                for name, target in (("Elbow" + side, pe), ("Forearm" + side, pf)):
                    pb = rig.pose.bones[name]
                    pb.matrix = target
                    bpy.context.view_layer.update()
                    if name in prev:
                        pb.rotation_euler = pb.matrix_basis.to_euler(pb.rotation_mode, prev[name])
                    prev[name] = pb.rotation_euler.copy()
                    pb.keyframe_insert("rotation_euler", frame=f)
                    pb.keyframe_insert("location", frame=f)
        for fc in cb.fcurves:
            if "Elbow" in fc.data_path or "Forearm" in fc.data_path:
                for k in fc.keyframe_points:
                    k.interpolation = 'LINEAR'


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    src, out_blend, out_w = argv[:3]
    report_path = argv[3] if len(argv) > 3 else None
    bpy.ops.wm.open_mainfile(filepath=src)
    rig = [x for x in bpy.data.objects if x.type == 'ARMATURE'][0]
    report = {"alpha": ALPHA, "width": WIDTH, "offset": OFFSET, "clips": R53.CLIPS, "frame_step": 2}
    arms = [bpy.data.objects[n] for n in R53.ARMS]
    before = {o.name: measure(o, rig, R53.CLIPS, 2) for o in arms}
    # hand pose before baking, to prove the helper never moves the hand
    hands = {}
    for a in R53.CLIPS:
        act = bpy.data.actions[a]; rig.animation_data.action = act
        try: rig.animation_data.action_slot = act.slots[0]
        except Exception: pass
        for f in range(int(act.frame_range[0]), int(act.frame_range[1]) + 1, 3):
            bpy.context.scene.frame_set(f)
            hands[(a, f)] = [rig.pose.bones["Hand" + s].matrix.copy() for s in "LR"]
    bake_helper(rig, R53.CLIPS)
    drift = 0.0
    for (a, f), mats in hands.items():
        act = bpy.data.actions[a]; rig.animation_data.action = act
        try: rig.animation_data.action_slot = act.slots[0]
        except Exception: pass
        bpy.context.scene.frame_set(f)
        for s, m in zip("LR", mats):
            n = rig.pose.bones["Hand" + s].matrix
            drift = max(drift, (n.translation - m.translation).length, max(abs(n[i][j] - m[i][j]) for i in range(3) for j in range(3)))
    report["hand_pose_max_drift"] = drift
    print("hand pose max drift after bake:", drift)
    dump = {}
    stat = lambda xs: {"mean_frame_p95_pct": round(float(np.mean([p for *_, p in xs])) * 100, 2),
                       "worst_frame_p95_pct": round(float(max(p for *_, p in xs)) * 100, 2)}
    for o in arms:
        W = weights(o, rig)
        R53.apply(o, W)
        s, cum, worst_a, after = measure(o, rig, R53.CLIPS, 2)
        _, _, worst_b, b = before[o.name]
        bands = {}
        for lo in np.arange(0.0, cum[3], 0.05):
            k = (s >= lo) & (s < lo + 0.05)
            if k.any():
                bands["%.2f" % lo] = [round(float(np.percentile(worst_b[k], 95)) * 100, 1), round(float(np.percentile(worst_a[k], 95)) * 100, 1)]
        report[o.name] = {"r53": stat(b), "r54": stat(after),
                          "p99_worst_vertex_pct": [round(float(np.percentile(worst_b, 99)) * 100, 1), round(float(np.percentile(worst_a, 99)) * 100, 1)],
                          "bands_p95_worst_frame_r53_r54": bands}
        print(o.name, report[o.name]["r53"], "->", report[o.name]["r54"], report[o.name]["p99_worst_vertex_pct"])
        dump[o.name] = {"bones": [b + o.name[-1] for b in BONES],
                        "local_positions": [[round(c, 6) for c in v.co[:]] for v in o.data.vertices],
                        "weights": [[round(float(x), 6) for x in row] for row in W]}
    bpy.ops.wm.save_as_mainfile(filepath=out_blend, compress=True)
    json.dump(dump, open(out_w, "w"))
    if report_path:
        json.dump(report, open(report_path, "w"), indent=1)


if __name__ == "__main__":
    main()
