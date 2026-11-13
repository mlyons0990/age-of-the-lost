#!/usr/bin/env python3
"""Read-only Phase 18 preflight for recovering the actual approved AOTL Citadel.

Usage:
  python tools/phase18_citadel_recovery_audit.py /path/to/approved/crownsfall_lootslice --out /path/to/recovery_audit.json

Does not modify the source project, rename files, import assets, enable meshes,
write to gameplay saves, or make any assertion that Phase 11 is recovered.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from datetime import datetime, timezone

ARTIFACT_NAMES = (
    "AOTL_Citadel_MasonryArt_v17.glb",
    "AOTL_Citadel_MasonryArt_v17.json",
    "AOTL_Citadel_ArtFallback_v15.glb",
)
BANNED_PARTS = {".git", ".godot", "__pycache__", ".venv", "node_modules"}
TEXT_EXTS = {".gd", ".tscn", ".tres", ".json", ".cfg", ".godot", ".md"}
REFERENCE_HINTS = ("citadel", "upper", "crownsfall", "navigationregion2d", "phase11")
MAX_TEXT_BYTES = 2_000_000

def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()

def audit(root: Path) -> dict:
    root = root.resolve(strict=True)
    if not root.is_dir():
        raise ValueError("Source must be a directory")
    inventory = []
    candidate_scenes = []
    matches = {name: [] for name in ARTIFACT_NAMES}
    for p in sorted(root.rglob("*")):
        if not p.is_file() or any(part in BANNED_PARTS for part in p.relative_to(root).parts):
            continue
        relative = p.relative_to(root).as_posix()
        entry = {"path": relative, "bytes": p.stat().st_size, "sha256": digest(p)}
        inventory.append(entry)
        if p.name in matches:
            matches[p.name].append(relative)
        if p.suffix.lower() in TEXT_EXTS and p.stat().st_size <= MAX_TEXT_BYTES:
            try:
                text = p.read_text(encoding="utf-8")
            except UnicodeError:
                continue
            search = (relative + "\n" + text).lower()
            found = [hint for hint in REFERENCE_HINTS if hint in search]
            if found:
                candidate_scenes.append({"path": relative, "hints": found,
                                         "has_navigation_region": "NavigationRegion2D" in text,
                                         "has_citadel_grade_call": "install_verified_citadel_grade(" in text,
                                         "has_masonry_install": "install_verified_citadel_masonry_v17(" in text})
    phase11_evidence = [x for x in candidate_scenes
                        if "phase11" in x["hints"] or
                        (x["has_navigation_region"] and "citadel" in x["hints"])]
    # Evidence is intentionally only a *candidate*: never infer actual playable approval.
    return {
        "schema": "aotl.citadel.phase18.readonly_audit.v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "source_root": str(root),
        "file_count": len(inventory),
        "files": inventory,
        "citadel_file_candidates": candidate_scenes,
        "phase11_possible_evidence": phase11_evidence,
        "known_artifacts": matches,
        "approved_phase11_recovered": False,
        "automatic_merge_allowed": False,
        "automatic_asset_install_allowed": False,
        "manual_gates": [
            "Compare candidate source against user-approved Phase11 F5 build and painted references",
            "Back up the entire genuine approved game before any import or merge",
            "Confirm actual stair entrance, exit, clear width, and authoritative NavRegion",
            "Verify F5 plaza-to-Citadel travel and F4/F8/F10 fallbacks",
            "Check physical feet, occlusion, camera, and saves at 1080p and 1440p",
        ],
    }

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("approved_project", type=Path)
    parser.add_argument("--out", type=Path, required=True,
                        help="Write audit JSON OUTSIDE the approved project tree")
    args = parser.parse_args()
    root = args.approved_project.resolve(strict=True)
    out = args.out.expanduser().resolve()
    if out == root or root in out.parents:
        parser.error("--out must be outside the source project; audit is read-only")
    if out.exists():
        parser.error("refusing to overwrite prior audit")
    result = audit(root)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"Audited {result['file_count']} files; {len(result['phase11_possible_evidence'])} potential Phase11 clues.")
    print("NOT APPROVED FOR MERGE. Review candidate evidence and validate actual F5 scene.")
    print(out)

if __name__ == "__main__":
    main()
