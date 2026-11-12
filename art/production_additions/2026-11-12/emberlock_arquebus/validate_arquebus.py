#!/usr/bin/env python3
"""Verify the AOTL Emberlock Arquebus item-art candidate without modifying assets."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
F = ROOT / "aotl_emberlock_arquebus_2x4_RGBA.png"
im = Image.open(F)
assert im.size == (256, 512), (im.size, "expected 2 x 4 cells at 128px")
assert im.mode == "RGBA", im.mode
a = im.getchannel("A")
bb = a.getbbox()
assert bb is not None, "empty alpha"
assert bb[0] > 0 and bb[1] > 0 and bb[2] < im.width and bb[3] < im.height, bb
assert a.getextrema() == (0, 255), a.getextrema()
source = Image.open(ROOT / "higgsfield_source_q94.webp")
assert source.size == (880, 1168), source.size
print("6 basic size/alpha/source checks passed; visual and Godot review still pending")
