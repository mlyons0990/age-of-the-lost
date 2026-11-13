#!/usr/bin/env python3
"""Make a verified, immutable ZIP snapshot before attempting AOTL Citadel art integration.

Creates a fresh archive OUTSIDE the source project; never changes the approved
Godot tree, saves, source scenes or art. Run explicitly on the user's current
F5-approved project, NOT on the stale Phase08 engineering branch.

Usage:
 python tools/phase18_citadel_immutable_backup.py "C:/AOTL/Crownsfall" --out "D:/AOTL_Backups/Crownsfall_approved_snapshot.zip"
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile
import zipfile

PRUNE = {".godot", ".git", ".venv", "__pycache__", "node_modules"}
MANIFEST_NAME = "_AOTL_PHASE18_BACKUP_MANIFEST.json"
ZIP_DATE = (2026, 1, 1, 0, 0, 0)

def sha256_bytes(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()

def source_files(root: Path):
    for base, directories, names in os.walk(root, topdown=True, followlinks=False):
        directories[:] = sorted(x for x in directories
                                if x not in PRUNE and not (Path(base)/x).is_symlink())
        for name in sorted(names):
            p = Path(base) / name
            if p.is_symlink() or not p.is_file():
                continue
            rel = p.relative_to(root).as_posix()
            if rel == MANIFEST_NAME:
                # Include any genuine file, but ensure our reserved archive manifest
                # does not overwrite an existing project entry.
                raise ValueError("Source already contains reserved manifest name")
            if ".." in Path(rel).parts or rel.startswith("/"):
                raise ValueError("unsafe archive entry")
            yield rel, p

def zip_info(name: str) -> zipfile.ZipInfo:
    i = zipfile.ZipInfo(name, ZIP_DATE)
    i.compress_type = zipfile.ZIP_DEFLATED
    i.external_attr = 0o100644 << 16
    return i

def create_snapshot(root: Path, output: Path) -> dict:
    root = root.expanduser().resolve(strict=True)
    output = output.expanduser().resolve()
    if not root.is_dir():
        raise ValueError("Source is not a directory")
    if output == root or root in output.parents:
        raise ValueError("Backup must be outside source")
    if output.exists():
        raise FileExistsError(f"Refusing overwrite: {output}")
    if not (root / "project.godot").is_file():
        raise ValueError("No project.godot found; refuse to label as a Godot backup")
    output.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=".aotl_phase18_",suffix=".zip.tmp",dir=output.parent)
    os.close(fd)
    entries = []
    try:
        with zipfile.ZipFile(tmp, "w", compression=zipfile.ZIP_DEFLATED,
                             compresslevel=6, allowZip64=True) as archive:
            for relative, path in source_files(root):
                before = path.stat()
                # Small or large files streamed via ZipFile.open, not buffered in RAM.
                sha = hashlib.sha256()
                size = 0
                with path.open("rb") as src, archive.open(zip_info(relative), "w") as dst:
                    while block := src.read(1024 * 1024):
                        dst.write(block)
                        sha.update(block)
                        size += len(block)
                after = path.stat()
                if before.st_size != size or after.st_size != size or before.st_mtime_ns != after.st_mtime_ns:
                    raise RuntimeError(f"Source file changed during snapshot: {relative}")
                entries.append({"path": relative, "bytes": size, "sha256": sha.hexdigest()})
            manifest = {"schema": "aotl.citadel.phase18.immutable_snapshot.v1",
                        "source_is_user_approved": False,
                        "requires_user_f5_validation": True,
                        "source_dir_name": root.name, "files": entries,
                        "excluded_cache_directories": sorted(PRUNE)}
            archive.writestr(zip_info(MANIFEST_NAME),
                             json.dumps(manifest, indent=2, sort_keys=True).encode("utf-8"))
        verify_snapshot(Path(tmp))
        # Exclusive creation refuses a race with another process creating output.
        with output.open("xb") as dest, open(tmp, "rb") as src:
            while block := src.read(1024 * 1024):
                dest.write(block)
        verify_snapshot(output)
        return {"archive": str(output), "files": len(entries),
                "size_bytes": output.stat().st_size,
                "sha256": sha256_file(output)}
    except Exception:
        if output.exists():
            # Cleanup only the new file created by this function; never replace
            # a pre-existing archive (handled by output.open('xb')).
            if 'dest' in locals():
                output.unlink()
        raise
    finally:
        Path(tmp).unlink(missing_ok=True)

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for b in iter(lambda: f.read(1024 * 1024), b""):
            h.update(b)
    return h.hexdigest()

def verify_snapshot(path: Path) -> dict:
    with zipfile.ZipFile(path, "r") as archive:
        if archive.testzip() is not None:
            raise ValueError("ZIP CRC failure")
        manifest = json.loads(archive.read(MANIFEST_NAME))
        expected = manifest["files"]
        archive_names = [item.filename for item in archive.infolist()]
        if len(archive_names) != len(set(archive_names)):
            raise ValueError("Duplicate ZIP entry")
        if set(archive_names) != {item["path"] for item in expected} | {MANIFEST_NAME}:
            raise ValueError("Archive manifest entries do not match archive files")
        for item in expected:
            name = item["path"]
            if Path(name).is_absolute() or ".." in Path(name).parts:
                raise ValueError("Archive path traversal")
            h = hashlib.sha256()
            total = 0
            with archive.open(name) as stream:
                while b := stream.read(1024 * 1024):
                    h.update(b)
                    total += len(b)
            if total != item["bytes"] or h.hexdigest() != item["sha256"]:
                raise ValueError(f"Archive checksum mismatch: {name}")
        return {"file_count": len(expected), "verified": True}

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("approved_project", type=Path)
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--verify", action="store_true", help="Verify --out instead of making it")
    args = p.parse_args()
    result = verify_snapshot(args.out) if args.verify else create_snapshot(args.approved_project, args.out)
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
