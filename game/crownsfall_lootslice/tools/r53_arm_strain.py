"""Linear-blend-skinning strain of an arm mesh (armature modifier only, as Godot skins it),
binned by position along the arm, for every frame of the given actions."""
import bpy, sys, json
import numpy as np

def arm_param(o, rig, side):
    mw = o.matrix_world
    J = [rig.matrix_world @ rig.data.bones[b + side].head_local for b in ("UpperArm", "Forearm", "Hand")]
    J.append(rig.matrix_world @ rig.data.bones["Hand" + side].tail_local)
    J = np.array([j[:] for j in J]); seg = np.diff(J, axis=0); sl = np.linalg.norm(seg, axis=1)
    P = np.array([(mw @ v.co)[:] for v in o.data.vertices])
    best = np.full(len(P), 1e9); s = np.zeros(len(P)); cum = np.concatenate([[0], np.cumsum(sl)])
    for i in range(3):
        u = np.clip(((P - J[i]) @ seg[i]) / sl[i]**2, 0 if i else -0.5, 1 if i < 2 else 1.5)
        d = np.linalg.norm(P - (J[i] + u[:, None] * seg[i]), axis=1)
        m = d < best; best[m] = d[m]; s[m] = cum[i] + u[m] * sl[i]
    return s, best, cum

def measure(o, rig, actions, step):
    side = o.name[-1]
    saved = [(m, m.show_viewport) for m in o.modifiers if m.type != 'ARMATURE']
    for m, _ in saved: m.show_viewport = False
    E = np.array([e.vertices[:] for e in o.data.edges])
    s, _, cum = arm_param(o, rig, side)
    dg = bpy.context.evaluated_depsgraph_get()
    rig.data.pose_position = 'REST'; dg.update()
    ev = o.evaluated_get(dg); me = ev.to_mesh(); R = np.array([v.co[:] for v in me.vertices]); ev.to_mesh_clear()
    rig.data.pose_position = 'POSE'
    L0 = np.linalg.norm(R[E[:, 0]] - R[E[:, 1]], axis=1)
    worst = np.zeros(len(R)); allp95 = []
    for a in actions:
        act = bpy.data.actions[a]; rig.animation_data.action = act
        try: rig.animation_data.action_slot = act.slots[0]
        except Exception: pass
        f0, f1 = [int(x) for x in act.frame_range]
        for f in range(f0, f1 + 1, step):
            bpy.context.scene.frame_set(f); dg.update()
            ev = o.evaluated_get(dg); me = ev.to_mesh(); C = np.array([v.co[:] for v in me.vertices]); ev.to_mesh_clear()
            st = np.abs(np.linalg.norm(C[E[:, 0]] - C[E[:, 1]], axis=1) / np.maximum(L0, 1e-9) - 1)
            vs = np.zeros(len(R)); np.maximum.at(vs, E[:, 0], st); np.maximum.at(vs, E[:, 1], st)
            worst = np.maximum(worst, vs); allp95.append((a, f, float(np.percentile(st, 95))))
    for m, v in saved: m.show_viewport = v
    return s, cum, worst, allp95

if __name__ == "__main__":
    # usage: python r53_arm_strain.py -- file.blend ArmObject Action1,Action2 [frame step]
    argv = sys.argv[sys.argv.index("--")+1:]
    blend, obj, actions = argv[0], argv[1], argv[2].split(",")
    step = int(argv[3]) if len(argv) > 3 else 2
    bpy.ops.wm.open_mainfile(filepath=blend)
    rig = [x for x in bpy.data.objects if x.type == 'ARMATURE'][0]
    o = bpy.data.objects[obj]
    s, cum, worst, allp95 = measure(o, rig, actions, step)
    print("joints along arm (m): elbow %.3f wrist %.3f end %.3f" % (cum[1], cum[2], cum[3]))
    for lo in np.arange(-0.05, cum[3] + 0.05, 0.05):
        m = (s >= lo) & (s < lo + 0.05)
        if m.any(): print("s %.2f-%.2f n=%4d worst-frame vertex strain p95 %.1f%%" % (lo, lo + .05, m.sum(), np.percentile(worst[m], 95) * 100))
    allp95.sort(key=lambda x: -x[2])
    print("worst frames:", [(a[:12], f, round(p * 100, 1)) for a, f, p in allp95[:6]])
    print("overall: mean frame p95 %.2f%%, worst %.2f%%" % (np.mean([p for _, _, p in allp95]) * 100, allp95[0][2] * 100))
