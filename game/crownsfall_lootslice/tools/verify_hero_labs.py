"""Run both hero HUD scenes with Godot 4.6.3, isolated from the player's settings."""
import argparse
from contextlib import contextmanager
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import time
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


@contextmanager
def scratch_directory(logs):
    scratch = Path(tempfile.mkdtemp(prefix="project-", dir=logs)).resolve()
    if scratch.parent != logs:
        raise ValueError("Unexpected QA scratch path")
    try:
        yield scratch
    finally:
        # Windows may still be releasing editor metadata after a successful import.
        for attempt in range(5):
            try:
                shutil.rmtree(scratch)
                break
            except FileNotFoundError:
                if not scratch.exists():
                    break
            except OSError as error:
                if attempt == 4:
                    print(f"Scratch copy retained at {scratch}: {error}", file=sys.stderr)
                    break
            time.sleep(0.25 * (attempt + 1))


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
    def ignore_generated(directory, names):
        skipped = {name for name in names if name in {".git", ".godot", "__pycache__"}}
        skipped.update(name for name in names if Path(directory) / name == logs)
        return skipped

    with scratch_directory(logs) as tmp:
        project = Path(tmp) / "project"
        shutil.copytree(src, project, ignore=ignore_generated)
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
