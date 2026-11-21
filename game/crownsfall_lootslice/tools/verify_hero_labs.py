"""Run both hero HUD scenes with Godot 4.6.3, isolated from the player's settings."""
import argparse
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import uuid

HEROES = (
    "models/higgsfield_pilot/knight_pilot_armed.glb",
    "models/higgsfield_mage/mage_pilot_armed.glb",
)


def check_models(project):
    errors = []
    for name in HEROES:
        path = project / name
        if not path.is_file():
            errors.append(f"{name}: missing")
            continue
        with path.open("rb") as stream:
            header = stream.read(128)
        if header.startswith(b"version https://git-lfs.github.com/spec/v1"):
            errors.append(f"{name}: Git LFS pointer")
        elif len(header) < 12 or struct.unpack("<4sII", header[:12]) != (
            b"glTF", 2, path.stat().st_size
        ):
            errors.append(f"{name}: invalid or incomplete GLB")
    if errors:
        raise ValueError("Hero assets unavailable:\n" + "\n".join(errors) +
                         "\nFrom the repository root, run git lfs pull and retry.")


def run_engine(command, log, marker=None, timeout=240):
    with log.open("w", encoding="utf-8") as out:
        result = subprocess.run(command, stdout=out, stderr=subprocess.STDOUT, timeout=timeout)
    output = log.read_text(encoding="utf-8", errors="replace")
    if result.returncode or "SCRIPT ERROR:" in output or (marker and not re.search(marker, output)):
        raise ValueError(f"{log.stem} failed. See {log}")
    if marker:
        print(re.search(marker, output).group(0))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--godot", default="godot", help="Path to the Godot console executable")
    parser.add_argument("--logs", type=Path, default=Path.cwd() / "hero-qa-logs")
    args = parser.parse_args()
    src = args.project.resolve()
    check_models(src)
    exe = shutil.which(args.godot)
    if not exe:
        raise ValueError(f"Godot executable unavailable: {args.godot}")
    version = subprocess.check_output([exe, "--version"], text=True).strip()
    if not version.startswith("4.6.3."):
        raise ValueError(f"Expected Godot 4.6.3, found {version}")
    # QA resets bindings in user://. Override the save namespace only in a throwaway copy.
    logs = args.logs.resolve() / uuid.uuid4().hex
    logs.mkdir(parents=True)
    print(f"Godot {version}; logs: {logs}", flush=True)
    with tempfile.TemporaryDirectory(prefix="aotl-hero-") as tmp:
        project = Path(tmp) / "project"
        shutil.copytree(src, project, ignore=shutil.ignore_patterns(".godot", ".git", "__pycache__"))
        with (project / "override.cfg").open("a", encoding="utf-8") as override:
            override.write('\n[application]\nconfig/use_custom_user_dir=true\n'
                           f'config/custom_user_dir_name="AOTL_Hero_QA_{logs.name}"\n')
        common = [exe, "--path", str(project), "--log-file", str(logs / "engine.log"), "--audio-driver", "Dummy"]
        run_engine(common + ["--headless", "--editor", "--import"], logs / "import.log", timeout=900)
        run_engine(common + ["--headless", "--script", "res://tests/verify_practice_progress.gd"],
                   logs / "progression.log", r"Practice XP checks: (\d+)/\1\b")
        run_engine(common + ["--rendering-method", "gl_compatibility", "--script",
                             "res://tests/verify_arpg_hud.gd"],
                   logs / "hero-scenes.log", r"AOTL ARPG HUD RESULT [1-9]\d* checks; 0 failures")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        sys.exit(str(error))
