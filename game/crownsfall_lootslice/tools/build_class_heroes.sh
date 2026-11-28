#!/usr/bin/env bash
# Assemble the Rogue and Cleric outfits of the one four-class hero (owner 11-27) from their Meshy models (paid,
# logged): the Knight's library clips (Idle/Walk/Run/Cast/Slash, Left_Slash, RunFast, Casual_Walk, Roll_Dodge, Dead)
# move onto each outfit's 24-bone rig, then the free Blender props (tools/make_class_props.py) are skinned rigidly
# to the hands: the Rogue's twin daggers held forward, the Cleric's mace in the right hand and sun shield strapped
# to the left forearm.
# usage: tools/build_class_heroes.sh   (run from the repo root)
set -euo pipefail
B=${BLENDER_PY:-/home/user/tools/bpyenv/bin/python}
T=game/crownsfall_lootslice/tools
K=game/crownsfall_lootslice/models/higgsfield_pilot
A=art/higgsfield_2026-11/classes
P=$A/props
CLIPS="Idle=$K/knight_pilot.glb@Idle Walk=$K/knight_pilot.glb@Walk Run=$K/knight_pilot.glb@Run Cast=$K/knight_pilot.glb@Cast
  Slash=$K/knight_pilot.glb@Slash Left_Slash=$K/clip_left_slash.glb RunFast=$K/clip_run_fast.glb
  Casual_Walk=$K/clip_casual_walk.glb Roll_Dodge=$K/clip_roll_dodge.glb Dead=$K/clip_dead.glb"
# class attack clips (paid library clips on each outfit's own rig, 2026-11-27): Rogue Double_Blade_Spin #91,
# Cleric Heavy_Hammer_Swing #128 and Double_Combo_Attack #92 (weapon + shield)
R=game/crownsfall_lootslice/models/higgsfield_rogue
C=game/crownsfall_lootslice/models/higgsfield_cleric
$B $T/merge_meshy_clips.py -- $A/rogue_rigged.glb $R/rogue_pilot.glb $A/rogue_pilot_source.blend $CLIPS \
  Blade_Spin=$R/clip_double_blade_spin.glb
$B $T/merge_meshy_clips.py -- $A/cleric_rigged.glb $C/cleric_pilot.glb $A/cleric_pilot_source.blend $CLIPS \
  Hammer_Swing=$C/clip_heavy_hammer_swing.glb Double_Combo=$C/clip_double_combo.glb
$B $T/attach_props_to_hero.py -- $A/rogue_pilot_source.blend game/crownsfall_lootslice/models/higgsfield_rogue/rogue_armed.glb $A/rogue_armed_source.blend \
  WEAPON_DaggerR=$P/rogue_dagger.glb@RightHand:aim=Idle/0/-1/-0.45 WEAPON_DaggerL=$P/rogue_dagger.glb@LeftHand:aim=Idle/0/-1/-0.45
$B $T/attach_props_to_hero.py -- $A/cleric_pilot_source.blend game/crownsfall_lootslice/models/higgsfield_cleric/cleric_armed.glb $A/cleric_armed_source.blend \
  WEAPON_Mace=$P/cleric_mace.glb@RightHand:aim=Idle/0/-0.75/0.66 SHIELD_Sun=$P/cleric_shield.glb@LeftForeArm:strap=Idle/1/-0.35/0
