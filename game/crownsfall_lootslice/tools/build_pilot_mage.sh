#!/usr/bin/env bash
# Assemble the Phase 1 Mage from its Meshy model: knight clips + the Mage's own paid cast clips (approved 2026-11-20) -> Mage, staff + tome.
# usage: tools/build_pilot_mage.sh <mage_rig.glb>   (run from the repo root)
set -euo pipefail
B=${BLENDER_PY:-/home/user/tools/bpyenv/bin/python}
T=game/crownsfall_lootslice/tools
K=game/crownsfall_lootslice/models/higgsfield_pilot
M=game/crownsfall_lootslice/models/higgsfield_mage
A=art/higgsfield_2026-11/mage
$B $T/merge_meshy_clips.py -- "$1" $M/mage_pilot.glb $A/mage_pilot_source.blend \
  Idle=$K/knight_pilot.glb@Idle Walk=$K/knight_pilot.glb@Walk Run=$K/knight_pilot.glb@Run Cast=$K/knight_pilot.glb@Cast \
  Slash=$K/knight_pilot.glb@Slash RunFast=$K/clip_run_fast.glb Casual_Walk=$K/clip_casual_walk.glb \
  Roll_Dodge=$K/clip_roll_dodge.glb Dead=$K/clip_dead.glb \
  Cast_Sweep=$M/clip_cast_sweep.glb Cast_Bolt=$M/clip_cast_bolt.glb Cast_Lunge=$M/clip_cast_lunge.glb Cast_Nova=$M/clip_cast_nova.glb
$B $T/attach_props_to_hero.py -- $A/mage_pilot_source.blend $M/mage_pilot_armed.glb $A/mage_pilot_armed_source.blend \
  MAGE_Staff=$M/mage_staff.glb@RightHand:grip=Idle,35 MAGE_Tome=$M/mage_tome.glb@LeftHand:held
