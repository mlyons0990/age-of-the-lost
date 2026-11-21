"""Build a large painted zone from several paintings (free, local).

A zone is one big canvas the hero walks across without loading (PoE "area" / D4 open-world region). It is assembled
from source paintings placed on the canvas (later ones blend over earlier ones with a feathered edge, so outpainted
or overlapping neighbours fuse into one scene), then cut into 2048 px tiles that the game streams in and out around
the camera. Portals ("exits") are the only places that load a different zone.

Source spec (assets/zones/src/<zone>.zone.json):
  {"name", "ppm", "hero_px_1080", "size": [W, H],
   "sources": [{"image": "res-relative path", "at": [x, y], "feather": 96}, ...],
   "occluders": [...as in build_zone_depth.py, canvas pixels...],
   "walkable", "spawn", "targets", "exits"   (canvas pixels)}
Writes assets/zones/<zone>.json (runtime) and assets/zones/<zone>/t_<col>_<row>.png + d_<col>_<row>.png.
usage: python build_zone_tiles.py <src.zone.json> [project_root]
"""
import json, os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from build_zone_depth import bake

TILE, GUTTER = 2048, 4          # gutter: neighbour pixels copied into each tile so linear filtering has no seam

def feather_mask(h, w, f, edges):
    m = np.ones((h, w), np.float32)
    if f <= 0: return m
    r = np.linspace(0, 1, f, dtype=np.float32)
    if edges.get("l"): m[:, :f] *= r[None, :]
    if edges.get("r"): m[:, -f:] *= r[::-1][None, :]
    if edges.get("t"): m[:f, :] *= r[:, None]
    if edges.get("b"): m[-f:, :] *= r[::-1][:, None]
    return m

def main():
    src = sys.argv[1]
    root = sys.argv[2] if len(sys.argv) > 2 else "."
    z = json.load(open(src))
    name = os.path.basename(src).replace(".zone.json", "")
    W, H = z["size"]
    canvas = np.zeros((H, W, 3), np.float32)
    cover = np.zeros((H, W), np.float32)
    for s in z["sources"]:
        im = np.asarray(Image.open(os.path.join(root, s["image"])).convert("RGB")).astype(np.float32)
        x, y = s["at"]
        h, w = im.shape[:2]
        x0, y0, x1, y1 = max(0, x), max(0, y), min(W, x + w), min(H, y + h)
        sub = im[y0 - y:y1 - y, x0 - x:x1 - x]
        f = int(s.get("feather", 96))
        region = cover[y0:y1, x0:x1]
        # feather only the edges that land on already-painted canvas; edges on empty canvas stay hard
        edges = {"l": x0 > 0 and region[:, 0].mean() > 0.5, "r": x1 < W and region[:, -1].mean() > 0.5,
                 "t": y0 > 0 and region[0, :].mean() > 0.5, "b": y1 < H and region[-1, :].mean() > 0.5}
        a = feather_mask(y1 - y0, x1 - x0, f, edges)
        canvas[y0:y1, x0:x1] = canvas[y0:y1, x0:x1] * (1 - a[..., None]) + sub * a[..., None]
        cover[y0:y1, x0:x1] = np.maximum(region, a)
    if (cover < 0.99).any():
        print("WARNING: %d canvas px not covered by any source" % int((cover < 0.99).sum()))
    img = np.clip(canvas, 0, 255).astype(np.uint8)
    depth = np.clip(bake(img, z.get("occluders", [])) / 4.0, 0, 255).astype(np.uint8)
    out_dir = os.path.join(root, "assets/zones", name)
    os.makedirs(out_dir, exist_ok=True)
    tiles = []
    for r, ty in enumerate(range(0, H, TILE)):
        for c, tx in enumerate(range(0, W, TILE)):
            tw, th = min(TILE, W - tx), min(TILE, H - ty)
            gx0, gy0 = max(0, tx - GUTTER), max(0, ty - GUTTER)
            gx1, gy1 = min(W, tx + tw + GUTTER), min(H, ty + th + GUTTER)
            Image.fromarray(img[gy0:gy1, gx0:gx1]).save(os.path.join(out_dir, "t_%d_%d.png" % (c, r)))
            has_depth = bool(depth[ty:ty + th, tx:tx + tw].any())
            if has_depth:
                Image.fromarray(depth[gy0:gy1, gx0:gx1], "L").save(os.path.join(out_dir, "d_%d_%d.png" % (c, r)))
            tiles.append({"image": "%s/t_%d_%d.png" % (name, c, r), "depth": ("%s/d_%d_%d.png" % (name, c, r)) if has_depth else "",
                          "rect": [tx, ty, tw, th], "img_rect": [gx0, gy0, gx1 - gx0, gy1 - gy0]})
    Image.fromarray(img).resize((max(1, W // 8), max(1, H // 8)), Image.LANCZOS).save(os.path.join(out_dir, "overview.png"))
    rt = {k: v for k, v in z.items() if k not in ("sources",)}
    rt["tiles"] = tiles
    rt["overview"] = name + "/overview.png"
    json.dump(rt, open(os.path.join(root, "assets/zones", name + ".json"), "w"), indent=1)
    print("%s: %dx%d canvas, %d tiles, %d sources" % (name, W, H, len(tiles), len(z["sources"])))

if __name__ == "__main__":
    main()
