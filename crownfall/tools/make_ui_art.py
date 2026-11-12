"""Builds the skill-bar and HUD button art into assets/ui/ from the Higgsfield UI art.

Sources (in the repo's art/higgsfield_trial set, also copied under tools/ui_sources/):
  ui_panel_frame.png  - ornate gold-and-iron panel frame (Higgsfield GPT Image 2.6)
  orb_life_empty.png  - the life orb frame (already keyed, assets/ui)
  leather_boots.png   - painted boots (assets/items/painted)

Outputs (2x resolution; the HUD draws them at half size):
  bar_plate.png    skill bar plate, nine-sliced from the panel frame
  bar_crest.png    the shield crest that crowns the bar
  slot_socket.png  recessed square socket for an empty slot
  keycap.png       key cap for 1-4 / Q (the HUD writes the letter on it)
  mouse_l.png, mouse_r.png   mouse with the left or right button lit
  round_frame.png  small ornate ring for the potion and evade buttons (cut from the orb)
  evade_roll.png   dodge-roll icon: painted boots with a gold speed swoosh
  lock.png         padlock for a slot whose skill isn't unlocked yet
  level_gem.png    diamond plate for the level number
Needs Python 3 with Pillow and numpy. usage: python tools/make_ui_art.py (from crownfall/)
"""
import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "ui_sources")
OUT = os.path.join(HERE, "..", "assets", "ui")
SS = 4  # supersampling for hand-drawn pieces

# skill bar plate size in HUD pixels (must match hud.gd: bar_w + 80 by sz + 78)
SZ, GAP, GROUP_GAP, SLOTS = 64, 6, 26, 6
BAR_W = SLOTS * SZ + (SLOTS - 1) * GAP + GROUP_GAP
PLATE = (BAR_W + 80, SZ + 78)


def nine_slice(src, m, size, k):
    """Stretches src to size: corners (m px square in src) scaled by k, edges and centre stretched."""
    W, H = src.size
    tw, th = size
    c = round(m * k)
    out = Image.new("RGBA", size)
    def part(box, dst_box):
        p = src.crop(box)
        w, h = dst_box[2] - dst_box[0], dst_box[3] - dst_box[1]
        if w > 0 and h > 0:
            out.alpha_composite(p.resize((w, h), Image.LANCZOS), (dst_box[0], dst_box[1]))
    # plain stretches of rail chosen away from the frame's own ornaments
    ex0, ex1 = 640, 860      # plain top/bottom rail segment (x)
    ey0, ey1 = 300, 640      # plain left/right rail segment (y)
    # centre
    part((m, m, W - m, H - m), (c, c, tw - c, th - c))
    # edges
    part((ex0, 0, ex1, m), (c, 0, tw - c, c))
    part((ex0, H - m, ex1, H), (c, th - c, tw - c, th))
    part((0, ey0, m, ey1), (0, c, c, th - c))
    part((W - m, ey0, W, ey1), (tw - c, c, tw, th - c))
    # corners
    part((0, 0, m, m), (0, 0, c, c))
    part((W - m, 0, W, m), (tw - c, 0, tw, c))
    part((0, H - m, m, H), (0, th - c, c, th))
    part((W - m, H - m, W, H), (tw - c, th - c, tw, th))
    return out


def bar_plate(panel):
    tw, th = PLATE[0] * 2, PLATE[1] * 2
    plate = nine_slice(panel, 270, (tw, th), 0.24)
    # soften the hard outer edge so the plate sits on the scene
    a = Image.new("L", plate.size, 0)
    ImageDraw.Draw(a).rounded_rectangle([2, 2, tw - 3, th - 3], radius=18, fill=255)
    plate.putalpha(ImageChops.multiply(plate.getchannel("A"), a.filter(ImageFilter.GaussianBlur(2))))
    return plate


def crest(panel):
    c = panel.crop((1255, 0, 1445, 222))
    hsv = np.asarray(c.convert("HSV")).astype(float)
    v = hsv[..., 2]
    s = hsv[..., 1]
    # keep gold and red (bright or saturated), drop the dark iron behind
    alpha = np.clip((np.maximum(v - 70, 0) * 2.2 + np.maximum(s - 90, 0) * 1.2), 0, 255)
    # restrict to the shield shape
    m = Image.new("L", c.size, 0)
    ImageDraw.Draw(m).polygon([(22, 10), (95, 2), (168, 10), (162, 138), (95, 214), (28, 138)], fill=255)
    alpha = np.minimum(alpha, np.asarray(m.filter(ImageFilter.GaussianBlur(1.5))).astype(float))
    out = c.copy()
    out.putalpha(Image.fromarray(alpha.astype(np.uint8)))
    return out.resize((round(c.width * 0.62), round(c.height * 0.62)), Image.LANCZOS)


def socket():
    n = 128 * SS
    im = Image.new("RGBA", (n, n))
    d = ImageDraw.Draw(im)
    # outer bronze rim with a bevel
    for i, col in enumerate([(52, 38, 20), (150, 112, 52), (210, 170, 92), (96, 70, 34)]):
        o = i * 2 * SS
        d.rectangle([o, o, n - 1 - o, n - 1 - o], fill=col + (255,))
    # recessed dark well, lit from the top
    inner = 10 * SS
    y, x = np.mgrid[0:n - 2 * inner, 0:n - 2 * inner]
    t = y / (n - 2 * inner)
    well = np.zeros((n - 2 * inner, n - 2 * inner, 4))
    well[..., 0] = 10 + 14 * (1 - t)
    well[..., 1] = 11 + 14 * (1 - t)
    well[..., 2] = 18 + 22 * (1 - t)
    well[..., 3] = 255
    w = Image.fromarray(well.astype(np.uint8), "RGBA")
    # inner shadow along the top and left edge
    sh = Image.new("L", w.size, 0)
    ImageDraw.Draw(sh).rectangle([0, 0, w.width, 8 * SS], fill=120)
    ImageDraw.Draw(sh).rectangle([0, 0, 8 * SS, w.height], fill=120)
    sh = sh.filter(ImageFilter.GaussianBlur(6 * SS))
    w = Image.composite(Image.new("RGBA", w.size, (0, 0, 0, 255)), w, sh)
    im.alpha_composite(w, (inner, inner))
    # tiny gold corner studs
    for cx, cy in [(inner, inner), (n - inner, inner), (inner, n - inner), (n - inner, n - inner)]:
        d.ellipse([cx - 4 * SS, cy - 4 * SS, cx + 4 * SS, cy + 4 * SS], fill=(232, 196, 110, 255), outline=(70, 50, 20, 255), width=SS)
    return im.resize((128, 128), Image.LANCZOS)


def keycap():
    w, h = 48 * SS, 44 * SS
    im = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 3 * SS, w - 1, h - 1], radius=8 * SS, fill=(20, 16, 12, 255))           # base shadow
    d.rounded_rectangle([0, 0, w - 1, h - 5 * SS], radius=8 * SS, fill=(150, 116, 58, 255))        # brass rim
    d.rounded_rectangle([3 * SS, 3 * SS, w - 1 - 3 * SS, h - 8 * SS], radius=6 * SS, fill=(36, 32, 30, 255))
    # top face, lighter at the top
    face = Image.new("RGBA", (w - 10 * SS, h - 16 * SS))
    fa = np.zeros((face.height, face.width, 4))
    t = np.linspace(0, 1, face.height)[:, None]
    fa[..., 0] = 70 - 34 * t
    fa[..., 1] = 64 - 30 * t
    fa[..., 2] = 58 - 26 * t
    fa[..., 3] = 255
    face = Image.fromarray(fa.astype(np.uint8), "RGBA")
    fm = Image.new("L", face.size, 0)
    ImageDraw.Draw(fm).rounded_rectangle([0, 0, face.width - 1, face.height - 1], radius=5 * SS, fill=255)
    im.paste(face, (5 * SS, 4 * SS), fm)
    d.line([7 * SS, 6 * SS, w - 7 * SS, 6 * SS], fill=(230, 200, 140, 120), width=SS)
    return im.resize((48, 44), Image.LANCZOS)


def mouse(left):
    w, h = 40 * SS, 52 * SS
    im = Image.new("RGBA", (w, h))
    body = Image.new("L", (w, h), 0)
    ImageDraw.Draw(body).rounded_rectangle([4 * SS, 2 * SS, w - 4 * SS, h - 2 * SS], radius=16 * SS, fill=255)
    # ivory body with a soft vertical gradient
    g = np.zeros((h, w, 4))
    t = np.linspace(0, 1, h)[:, None]
    g[..., 0] = 222 - 70 * t
    g[..., 1] = 212 - 70 * t
    g[..., 2] = 190 - 66 * t
    g[..., 3] = 255
    im.paste(Image.fromarray(g.astype(np.uint8), "RGBA"), (0, 0), body)
    d = ImageDraw.Draw(im)
    # the lit button: gold, the top-left or top-right quarter
    btn = Image.new("L", (w, h), 0)
    bd = ImageDraw.Draw(btn)
    bd.rounded_rectangle([4 * SS, 2 * SS, w - 4 * SS, h - 2 * SS], radius=16 * SS, fill=255)
    bd.rectangle([0, h * 0.42, w, h], fill=0)
    if left:
        bd.rectangle([w // 2, 0, w, h], fill=0)
    else:
        bd.rectangle([0, 0, w // 2, h], fill=0)
    gold = np.zeros((h, w, 4))
    gold[..., 0] = 255 - 40 * t
    gold[..., 1] = 200 - 70 * t
    gold[..., 2] = 90 - 50 * t
    gold[..., 3] = 255
    im.paste(Image.fromarray(gold.astype(np.uint8), "RGBA"), (0, 0), btn)
    # seams and outline
    d.line([w // 2, 3 * SS, w // 2, int(h * 0.42)], fill=(40, 32, 24, 255), width=2 * SS)
    d.line([5 * SS, int(h * 0.42), w - 5 * SS, int(h * 0.42)], fill=(40, 32, 24, 255), width=2 * SS)
    d.rounded_rectangle([4 * SS, 2 * SS, w - 4 * SS, h - 2 * SS], radius=16 * SS, outline=(30, 24, 18, 255), width=2 * SS)
    # highlight
    d.arc([8 * SS, 5 * SS, w - 8 * SS, 30 * SS], 200, 250, fill=(255, 255, 255, 160), width=2 * SS)
    return im.resize((40, 52), Image.LANCZOS)


def round_frame():
    """The orb's gold ring with the globe cut out, for the small round buttons."""
    orb = Image.open(os.path.join(OUT, "orb_life_empty.png")).convert("RGBA")
    cx, cy, r = 151.0, 167.9, 93.4
    hole = Image.new("L", orb.size, 255)
    ImageDraw.Draw(hole).ellipse([cx - r + 2, cy - r + 2, cx + r - 2, cy + r - 2], fill=0)
    a = ImageChops.multiply(orb.getchannel("A"), hole.filter(ImageFilter.GaussianBlur(1)))
    ring = orb.copy()
    ring.putalpha(a)
    # crop to a square around the ring (drop the tall crest so the button stays compact)
    box = (int(cx - r - 26), int(cy - r - 26), int(cx + r + 26), int(cy + r + 26))
    return ring.crop(box)


def evade_roll():
    n = 128 * 2
    im = Image.new("RGBA", (n, n))
    # deep navy well with a warm glow
    y, x = np.mgrid[0:n, 0:n]
    d = np.hypot(x - n * 0.5, y - n * 0.56) / (n * 0.5)
    c0, c1 = np.array([60, 82, 140]), np.array([8, 12, 26])
    bg = (c0 * (1 - d[..., None]).clip(0, 1) + c1 * d[..., None].clip(0, 1))
    im = Image.fromarray(np.dstack([bg, np.full((n, n), 255)]).astype(np.uint8), "RGBA")
    dr = ImageDraw.Draw(im, "RGBA")
    # curved gold motion trails sweeping in from the left, behind the boots
    for i, (dy, wd, al) in enumerate([(-34, 9, 210), (0, 7, 170), (34, 5, 130)]):
        box = [n * 0.05, n * 0.30 + dy, n * 0.95, n * 1.10 + dy]
        dr.arc(box, 192, 238, fill=(255, 214, 120, al), width=wd)
    boots = Image.open(os.path.join(SRC, "leather_boots.png")).convert("RGBA")
    bb = boots.getchannel("A").getbbox()
    boots = boots.crop(bb)
    k = min(n * 0.8 / boots.width, n * 0.8 / boots.height)
    boots = boots.resize((round(boots.width * k), round(boots.height * k)), Image.LANCZOS).rotate(-12, expand=True, resample=Image.BICUBIC)
    # a soft gold glow under the boots
    glow = Image.new("RGBA", boots.size, (255, 200, 110, 0))
    glow.putalpha(boots.getchannel("A").filter(ImageFilter.GaussianBlur(10)).point(lambda p: int(p * 0.55)))
    pos = ((n - boots.width) // 2 + 16, (n - boots.height) // 2 + 4)
    im.alpha_composite(glow, pos)
    im.alpha_composite(boots, pos)
    # round mask
    m = Image.new("L", (n, n), 0)
    ImageDraw.Draw(m).ellipse([0, 0, n - 1, n - 1], fill=255)
    im.putalpha(m)
    return im.resize((128, 128), Image.LANCZOS)


def lock():
    n = 128 * SS
    im = Image.new("RGBA", (n, n))
    d = ImageDraw.Draw(im)
    # shackle
    d.rounded_rectangle([n * 0.3, n * 0.12, n * 0.7, n * 0.62], radius=n * 0.2, outline=(80, 74, 70, 255), width=int(n * 0.09))
    d.rounded_rectangle([n * 0.3, n * 0.12, n * 0.7, n * 0.62], radius=n * 0.2, outline=(170, 160, 150, 255), width=int(n * 0.05))
    # body with a gold gradient
    body = [int(n * 0.2), int(n * 0.42), int(n * 0.8), int(n * 0.9)]
    g = np.zeros((body[3] - body[1], body[2] - body[0], 4))
    t = np.linspace(0, 1, g.shape[0])[:, None]
    g[..., 0] = 236 - 120 * t
    g[..., 1] = 192 - 112 * t
    g[..., 2] = 104 - 76 * t
    g[..., 3] = 255
    bm = Image.new("L", (g.shape[1], g.shape[0]), 0)
    ImageDraw.Draw(bm).rounded_rectangle([0, 0, g.shape[1] - 1, g.shape[0] - 1], radius=n * 0.06, fill=255)
    im.paste(Image.fromarray(g.astype(np.uint8), "RGBA"), (body[0], body[1]), bm)
    d.rounded_rectangle(body, radius=n * 0.06, outline=(60, 40, 16, 255), width=2 * SS)
    # keyhole
    d.ellipse([n * 0.45, n * 0.56, n * 0.55, n * 0.66], fill=(30, 20, 10, 255))
    d.polygon([(n * 0.47, n * 0.63), (n * 0.53, n * 0.63), (n * 0.545, n * 0.78), (n * 0.455, n * 0.78)], fill=(30, 20, 10, 255))
    d.line([body[0] + 4 * SS, body[1] + 5 * SS, body[2] - 4 * SS, body[1] + 5 * SS], fill=(255, 240, 200, 160), width=2 * SS)
    return im.resize((128, 128), Image.LANCZOS)


def level_gem():
    n = 64 * SS
    im = Image.new("RGBA", (n, n))
    d = ImageDraw.Draw(im)
    c = n / 2
    def dia(r, col):
        d.polygon([(c, c - r), (c + r, c), (c, c + r), (c - r, c)], fill=col)
    dia(n * 0.5 - 1, (50, 36, 18, 255))
    dia(n * 0.46, (214, 172, 88, 255))
    dia(n * 0.40, (120, 86, 38, 255))
    dia(n * 0.36, (22, 18, 26, 255))
    d.line([(c - n * 0.36, c), (c, c - n * 0.36)], fill=(255, 236, 170, 140), width=2 * SS)
    return im.resize((64, 64), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    panel = Image.open(os.path.join(SRC, "ui_panel_frame.png")).convert("RGBA")
    bar_plate(panel).save(os.path.join(OUT, "bar_plate.png"))
    crest(panel).save(os.path.join(OUT, "bar_crest.png"))
    socket().save(os.path.join(OUT, "slot_socket.png"))
    keycap().save(os.path.join(OUT, "keycap.png"))
    mouse(True).save(os.path.join(OUT, "mouse_l.png"))
    mouse(False).save(os.path.join(OUT, "mouse_r.png"))
    round_frame().save(os.path.join(OUT, "round_frame.png"))
    evade_roll().save(os.path.join(OUT, "evade_roll.png"))
    lock().save(os.path.join(OUT, "lock.png"))
    level_gem().save(os.path.join(OUT, "level_gem.png"))
    print("plate", PLATE, "done")


if __name__ == "__main__":
    main()
