"""R55: clip-safe elbow. Keeps R54's half-swing Elbow helper, fixes the armor clipping it introduced.

Run with Blender 5.2 (or the `bpy` 5.2 module):
  python r55_clip_safe_elbow.py -- <R54 .blend> <out R55 .blend> <out data .json> [report .json]

R54's ±24 cm linear elbow window reduced skin strain but dragged skin out through the rigid
shoulder plate (1,526 vertex-frames) and the forearm guard (3,849 vs R53's 877), seen in Godot
at Cast f23. R55:
- eases the elbow window with smoothstep, so weights change near the pivot rather than at the
  window ends (which sit 20 cm from it, where blended rotations move skin the most);
- stops the window above the elbow at the shoulder plate's lower edge (20 cm) and narrows it below (16 cm);
- scallops each forearm guard's top edge 2 cm lower on the inner-elbow side (cos² over ±90°,
  bottom edge fixed), leaving room for the inner upper arm to fold. Direction per side is
  computed from the deepest bend in the clips. The guard stays rigid on Forearm.
Helper keys, rig, other meshes and all clips are unchanged from R54.
"""
import bpy, sys, os, json, math
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import r53_arm_reweight as R53
from r53_arm_strain import arm_param, measure

UPPER, LOWER, OFFSET = 0.20, 0.16, 0.02   # window above / below the elbow, centre offset (m)
SCALLOP, SCALLOP_HALF = 0.02, math.radians(90)
BONES = R53.BONES


def ss(t):
    return t * t * (3 - 2 * t)


def weights(o, rig):
    W = R53.weights(o, rig)
    s, _, cum = arm_param(o, rig, o.name[-1])
    d = s - (cum[1] + OFFSET)
    t = ss(np.clip(np.where(d < 0, 0.5 + 0.5 * d / UPPER, 0.5 + 0.5 * d / LOWER), 0, 1))
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


def inner_direction(rig, side, clips):
    """Unit vector (armature rest space, ⟂ forearm axis) toward which the forearm swings at its deepest bend."""
    b = rig.data.bones["Forearm" + side]
    h, tail = b.head_local.copy(), b.tail_local.copy()
    best, vec = -1, None
    for a in clips:
        act = bpy.data.actions[a]; rig.animation_data.action = act
        try: rig.animation_data.action_slot = act.slots[0]
        except Exception: pass
        for f in range(int(act.frame_range[0]), int(act.frame_range[1]) + 1):
            bpy.context.scene.frame_set(f)
            pb = rig.pose.bones
            DU = pb["UpperArm" + side].matrix @ rig.data.bones["UpperArm" + side].matrix_local.inverted()
            DF = pb["Forearm" + side].matrix @ b.matrix_local.inverted()
            moved = (DU.inverted() @ DF) @ tail - tail
            if moved.length > best:
                best, vec = moved.length, moved.copy()
    ax = (tail - h).normalized()
    v = vec - ax * vec.dot(ax)
    return v.normalized(), ax, h


def scallop_guard(ob, rig, side, inner, ax, h):
    """Lower the guard's top edge toward the inner elbow (object-local coords = armature space here)."""
    if ob.matrix_world != rig.matrix_world and not ob.matrix_parent_inverse.is_identity:
        pass
    to_arm = rig.matrix_world.inverted() @ ob.matrix_world
    from_arm = to_arm.inverted()
    Q = np.array([(to_arm @ v.co)[:] for v in ob.data.vertices])
    hh, axv, inn = np.array(h[:]), np.array(ax[:]), np.array(inner[:])
    d = Q - hh; a = d @ axv; rv = d - a[:, None] * axv
    other = np.cross(axv, inn)
    dth = np.arctan2(rv @ other, rv @ inn)
    cut = SCALLOP * np.where(np.abs(dth) < SCALLOP_HALF, np.cos(dth / SCALLOP_HALF * np.pi / 2) ** 2, 0)
    a0, a1 = a.min(), a.max()
    a_new = a1 - (a1 - a) * (a1 - a0 - cut) / (a1 - a0)
    Qn = Q + (a_new - a)[:, None] * axv
    for v, q in zip(ob.data.vertices, Qn):
        v.co = from_arm @ __import__("mathutils").Vector(q.tolist())
    ob.data.update()
    return float((a_new - a).max())


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    src, out_blend, out_json = argv[:3]
    report_path = argv[3] if len(argv) > 3 else None
    bpy.ops.wm.open_mainfile(filepath=src)
    rig = [x for x in bpy.data.objects if x.type == 'ARMATURE'][0]
    report = {"upper": UPPER, "lower": LOWER, "offset": OFFSET, "ease": "smoothstep",
              "scallop_m": SCALLOP, "clips": R53.CLIPS, "frame_step": 2}
    dump = {}
    stat = lambda xs: {"mean_frame_p95_pct": round(float(np.mean([p for *_, p in xs])) * 100, 2),
                       "worst_frame_p95_pct": round(float(max(p for *_, p in xs)) * 100, 2)}
    for name in R53.ARMS:
        side = name[-1]
        o = bpy.data.objects[name]
        _, _, wb, before = measure(o, rig, R53.CLIPS, 2)
        inner, ax, h = inner_direction(rig, side, R53.CLIPS)
        guard = bpy.data.objects["V02_GEAR_ForearmGuard" + side]
        moved = scallop_guard(guard, rig, side, inner, ax, h)
        W = weights(o, rig)
        R53.apply(o, W)
        s, cum, wa, after = measure(o, rig, R53.CLIPS, 2)
        report[name] = {"r54": stat(before), "r55": stat(after),
                        "p99_worst_vertex_pct": [round(float(np.percentile(wb, 99)) * 100, 1), round(float(np.percentile(wa, 99)) * 100, 1)],
                        "inner_elbow_dir_armature": [round(x, 4) for x in inner], "guard_top_lowered_m": round(moved, 4)}
        print(name, report[name])
        dump[name] = {"bones": [b + side for b in BONES],
                      "local_positions": [[round(c, 6) for c in v.co[:]] for v in o.data.vertices],
                      "weights": [[round(float(x), 6) for x in row] for row in W]}
        dump["guard_" + side] = {"object": guard.name,
                                 "scallop": {"inner": list(inner), "axis": list(ax), "head": list(h), "depth": SCALLOP, "half": SCALLOP_HALF}}
    bpy.ops.wm.save_as_mainfile(filepath=out_blend, compress=True)
    json.dump(dump, open(out_json, "w"))
    if report_path:
        json.dump(report, open(report_path, "w"), indent=1)


if __name__ == "__main__":
    main()
