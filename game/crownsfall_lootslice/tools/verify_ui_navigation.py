#!/usr/bin/env python3
"""Static/integrity regression for the AOTL right-dock UI navigation pass.

No Godot calls are made. A passing report is NOT an engine/runtime result.
"""
from pathlib import Path
import re, sys, json, hashlib, zipfile

root=Path(__file__).resolve().parents[1]
source=root/'scripts'
hud=(source/'hud.gd').read_text()
panel=(source/'inventory_panel.gd').read_text()
systems=(source/'systems.gd').read_text()
tests=(root/'tests/inventory_ui_integration.gd').read_text()
items=[]

def check(ok:bool, name:str):
    items.append((bool(ok),name))
    print(('PASS' if ok else 'FAIL')+' '+name)

def gd_brackets(data:str):
    stack=[]; quotes=False; escaped=False; comment=False
    mapping={')':'(',']':'[','}':'{'}
    for n,c in enumerate(data):
        if c=='\n': comment=False
        if comment: continue
        if quotes:
            if escaped: escaped=False
            elif c=='\\': escaped=True
            elif c=='"': quotes=False
            continue
        if c=='#': comment=True; continue
        if c=='"': quotes=True;continue
        if c in '([{': stack.append((c,n))
        if c in ')]}':
            if not stack or stack[-1][0]!=mapping[c]: return False
            stack.pop()
    return not stack and not quotes

for name,content in [('hud.gd',hud),('inventory_panel.gd',panel),('tests/inventory_ui_integration.gd',tests)]:
    check(gd_brackets(content),name+': brackets and quoted strings are balanced')
    check(not any(l.startswith(' ') for l in content.splitlines() if l.strip() and not l.lstrip().startswith('#')),name+': indentation is tab-based')

for phrase in ['JOY_BUTTON_DPAD_LEFT','JOY_BUTTON_DPAD_RIGHT','JOY_BUTTON_DPAD_UP','JOY_BUTTON_DPAD_DOWN','JOY_BUTTON_A','JOY_BUTTON_X','JOY_BUTTON_B','JOY_BUTTON_LEFT_SHOULDER','JOY_BUTTON_RIGHT_SHOULDER','KEY_LEFT','KEY_RIGHT','KEY_UP','KEY_DOWN','KEY_ENTER','KEY_KP_ENTER','KEY_TAB']:
    check(phrase in hud,'input binding present: '+phrase)
check('func focus_step(dx: int, dy: int)' in panel,'focus step is a separate interaction method')
check('clampi(focus_cell.x + dx, 0, SYS.WIDTH - 1)' in panel and 'clampi(focus_cell.y + dy, 0, SYS.HEIGHT - 1)' in panel,'focus cell clamps to runtime backpack geometry')
check('bag.index_at(center)' in panel and 'show_bag_item(index,true)' in panel,'keyboard inspection resolves actual item under cursor')
check('ui._equip(SYS.default_slot(ui.player.inventory[index]))' in panel,'quick-equip reuses the existing validated item equip action')
check('var keyboard_was_active:' in hud and 'inventory_shell.focus_cell=selected_cell' in hud,'UI rebuild preserves keyboard cursor position')
check('ui.inventory_shell.release_keyboard_cursor()' in hud,'pointer selection releases the keyboard focus highlight')
check('SYS.derive(ui.player.level,{},ui.player.mods(),ui.player.class_id)' in panel,'stats use a true no-gear baseline, not invented comparisons')
check('str(snappedf(base_value,0.1))' in panel and 'str(snappedf(total_value,0.1))' in panel,'attributes retain half-point/decimal precision')
check('Resistances, evasion and energy shield are not implemented' in panel,'unimplemented stats are not fabricated')
check('class ResourceMeter extends Control:' in panel and 'ui.player.hp if kind=="life" else ui.player.mp' in panel,'both bars use actual player resources')
check('var new_item: Variant=plan.gear.get(old_slot)' in hud and 'Moves to backpack:' in hud,'comparison derives replaced items from actual equip plan')
check('func equip_plan' in systems or 'func plan_equip' in (source/'player.gd').read_text(),'authoritative transaction planning preserved')
check('const WIDTH := 10' in systems and 'const HEIGHT := 6' in systems,'persisted 10x6 backpack unchanged')
check('gameplay_state' not in panel,'UI does not introduce a second gameplay state owner')
check('not implemented' in tests and 'gamepad D-pad moves' in tests,'additional future Godot integration assertions are included')
check('AgeOfTheLost_Crownsfall_EncounterSlice' in (root/'project.godot').read_text(),'existing save namespace retained')
check((root/'assets/ui/inventory_backplate.jpg').exists(),'existing original stone/bronze backplate retained')
check((root/'scripts/service_panel.gd').exists() and (root/'scripts/town_actions.gd').exists(),'paired town service branch retained')
check((root/'scenes/three_d/rig_lab.tscn').exists() or any((root/'scenes').rglob('*rig*')),'F7 independent rig lab scene retained')

# Pure geometry and navigation invariants from the authored layout.
slot_text=re.search(r'const SLOTS := (\{[^\n]+\})',panel)
slot_rects={}
if slot_text:
    for name,x,y,w,h in re.findall(r'"(\w+)":Rect2\((\d+),(\d+),(\d+),(\d+)\)',slot_text.group(1)):
        slot_rects[name]=(int(x),int(y),int(w),int(h))
check(len(slot_rects)==10,'equipment paper-doll has all ten canonical slots')
check(slot_rects.get('helm',(0,0,0,0))[1]<slot_rects.get('armor',(0,0,0,0))[1],'helm slot sits above body')
check(slot_rects.get('weapon',(0,0,0,0))[0]<slot_rects.get('armor',(0,0,0,0))[0]<slot_rects.get('offhand',(0,0,0,0))[0],'hands flank the character body')
intersections=[]
for name1,r1 in slot_rects.items():
    for name2,r2 in slot_rects.items():
        if name1>=name2:continue
        x1,y1,w1,h1=r1; x2,y2,w2,h2=r2
        if min(x1+w1,x2+w2)>max(x1,x2) and min(y1+h1,y2+h2)>max(y1,y2): intersections.append((name1,name2))
check(not intersections,'equipment hit rectangles do not overlap')
for w,h in [(1280,720),(1440,810),(1920,1080),(2560,1440),(960,720)]:
    scale=min(1., (h-24)/1020, w*.45/680)
    px=w-680*scale-12
    py=(h-1020*scale)/2
    check(px>=w*.5-12 and px+680*scale<=w and py>=0 and py+1020*scale<=h,'right-side dock fits '+str(w)+'x'+str(h))

passed=sum(ok for ok,_ in items)
summary={'run_type':'STATIC_ONLY_NO_GODOT','passed':passed,'total':len(items),'failed':[name for ok,name in items if not ok]}
(root/'tests/UI_NAVIGATION_STATIC_RESULT.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
if passed!=len(items): sys.exit(1)
