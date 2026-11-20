# AOTL Higgsfield Credit Ledger

Rule (owner, 2026-11-20): **every paid operation needs explicit approval of that exact operation and its live quote.**
Actual costs are confirmed against the Higgsfield `transactions` log; estimates are never recorded as charges.

| Date (UTC) | Asset | Model / service | Live quote | Approval | Actual (transactions) | Job ID | Result | Status | Balance after |
|---|---|---|---:|---|---:|---|---|---|---:|
| 2026-11-20 03:46 | Knight A-pose reference | Nano Banana Pro | 2 | Art-chat handoff (pre-rule) | 2 | `10bf053c-b6e3-4973-bb39-178b2124ff8c` | Clean front A-pose of approved knight | Accepted | 2,998 |
| 2026-11-20 04:19 | Rigged textured knight (a-pose, 1.75 m, quad 30k) | Meshy 7 image-to-3D | 44 | Handoff Phase 0 budget (submitted **before** the per-job rule) | 44 | `f88409b4-84df-4e57-9c68-5b2dbf9b428c` | 24-bone rig, 48k verts, close match to reference | Accepted | 2,954 |
| 2026-11-20 04:40 | Roll_Dodge clip (#158) on the knight | 3d_rigging | 8 | Owner: "Go ahead and do the paid route" (two clips) | 8 | `186cf374-036c-4b3e-8efc-8420672269ee` | Real ground roll (hips 0.21 m), merged | Accepted | 2,946 |
| 2026-11-20 06:45 | Dead clip (#8) on the knight | 3d_rigging | 8 (re-quoted before submit) | Owner: "Approved, go ahead with the 8-credit Dead clip" | 8 | `3efdc88d-68f1-4364-b074-6e322b1950b9` | Stagger, kneel, collapse; ends hips 0.24 m / head 0.25 m; weapons attached | Accepted | 2,938 |
| 2026-11-20 06:56 | Left_Slash clip (#97) on the knight | 3d_rigging | 8 (re-quoted before submit) | Owner: "Go with the paid version so it looks perfect" | 8 | `af9142e8-ea9b-4b88-bd63-9ed38a332260` | Right-hand forward slash; real sword hits a dummy 0.65 m ahead in strict mode | Accepted | 2,930 |
| 2026-11-20 07:05 | Casual_Walk clip (#30) | 3d_rigging | 8 (re-quoted) | Owner: "Approved, get the walk and run clips" | 8 | `259cb61d-0f2d-4f8d-8799-36a38e7f864d` | 1.0 m/s stroll → new Ctrl-stroll mode | Accepted | — |
| 2026-11-20 07:05 | RunFast clip (#16) | 3d_rigging | 8 (re-quoted) | same approval | 8 | `73fe49f9-a275-44be-8089-70ffad9caf52` | Sprint for Shift-run (×0.71, natural cadence) | Accepted | 2,914 |
| 2026-11-20 07:18 | Phase 1 Mage model (4 views from the approved turnaround) | multi_image_to_3d (textured, rigged, a-pose) | 35 (re-quoted) | Owner: "Approved, go ahead with the 35-credit Mage model" | 35 | `301207b8-fb2c-4bae-a15f-c73903343278` | Close match to turnaround; 24-bone rig; knight clips transferred free | Accepted | 2,879 |
| 2026-11-20 07:41 | Mage cast: mage_soell_cast_4 (#133) on the Mage → `Cast_Sweep` / Judgment | 3d_rigging | 8 (re-quoted before submit) | Owner: "Mage spells approved" (4-clip request, 32 cr) | 8 | `94727474-ead3-4374-a01b-0379d54c3ff1` | Wide-stance staff sweep, hips drop 0.16 m, feet planted; release 0.34 | Accepted | — |
| 2026-11-20 07:41 | Mage cast: mage_soell_cast_7 (#136) → `Cast_Bolt` | 3d_rigging | 8 (re-quoted) | same approval | 8 | `935e193a-3f4b-4a19-a72d-2324a25ea73b` | Step-in one-arm cast; release 0.33 | Accepted | — |
| 2026-11-20 07:41 | Mage cast: mage_soell_cast_3 (#132) → `Cast_Lunge` / Lance | 3d_rigging | 8 (re-quoted) | same approval | 8 | `c04a78d8-125a-4cc9-add4-7a1a57a90d49` | Two-hand lunge push, held; release 0.31 | Accepted | — |
| 2026-11-20 07:41 | Mage cast: Charged_Spell_Cast (#125) → `Cast_Nova` | 3d_rigging | 8 (re-quoted) | same approval | 8 | `e05ef36d-2f30-4feb-b3ed-a02f1671fbb1` | Crouch-and-burst; release 0.69 | Accepted | 2,847 |

Totals: **153 credits spent** of the 3,000 grant (2,847 remaining, verified against `balance` + `transactions` 2026-11-20 07:42). Phase 0: 86 of 120. Phase 1: 67 of 600.
Machine-readable copy: `art/higgsfield_2026-11/LEDGER.csv`.
