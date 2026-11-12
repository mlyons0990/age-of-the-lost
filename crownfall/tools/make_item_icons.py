"""Paints the inventory item icons into assets/items/<slot>.png.

One icon per item type, sized to the item's inventory footprint (a sword is
1x3 cells, a chest 2x3 and so on). Drawn at 4x and scaled down for smooth
edges, with metal gradients, dark outlines and highlights in the game's
palette: steel, gold trim, royal blue cloth and leather.

These stand in until painted portraits replace them: drop a PNG with the same
name and aspect into assets/items/ and the game uses it.
Needs Python 3 with Pillow. usage: python make_item_icons.py <output folder>
"""
import sys, os, math
from PIL import Image, ImageDraw, ImageFilter, ImageChops

CELL = 96          # output pixels per inventory cell
SS = 4             # supersampling factor
OUTLINE = (24, 20, 28, 255)

STEEL = [(232, 236, 244), (168, 176, 192), (98, 104, 122)]
DARK_STEEL = [(170, 176, 190), (110, 116, 132), (60, 64, 78)]
GOLD = [(255, 236, 160), (226, 176, 72), (140, 92, 30)]
BLUE = [(120, 156, 255), (46, 74, 190), (18, 28, 92)]
LEATHER = [(170, 112, 70), (118, 72, 42), (66, 38, 22)]
GEM_BLUE = [(200, 230, 255), (70, 140, 255), (20, 40, 140)]
GEM_RED = [(255, 200, 200), (220, 40, 60), (100, 10, 24)]


def canvas(cols, rows):
    return Image.new("RGBA", (cols * CELL * SS, rows * CELL * SS), (0, 0, 0, 0))


def S(v):
    """Scale a design coordinate (0..1 of the image) to supersampled pixels."""
    return v


def pts(img, coords):
    w, h = img.size
    return [(x * w, y * h) for x, y in coords]


def gradient(size, stops, angle=90):
    """Linear gradient image through three colour stops; angle 90 = top to bottom."""
    w, h = size
    g = Image.new("RGBA", size)
    px = g.load()
    a = math.radians(angle)
    dx, dy = math.cos(a), math.sin(a)
    span = abs(dx) * w + abs(dy) * h
    ox = 0 if dx >= 0 else w
    oy = 0 if dy >= 0 else h
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            t = ((x - ox) * dx + (y - oy) * dy) / span
            t = min(1.0, max(0.0, t))
            if t < 0.5:
                c0, c1, k = stops[0], stops[1], t / 0.5
            else:
                c0, c1, k = stops[1], stops[2], (t - 0.5) / 0.5
            c = tuple(int(c0[i] + (c1[i] - c0[i]) * k) for i in range(3)) + (255,)
            px[x, y] = c
            if x + 1 < w:
                px[x + 1, y] = c
            if y + 1 < h:
                px[x, y + 1] = c
                if x + 1 < w:
                    px[x + 1, y + 1] = c
    return g


def fill(img, shape, stops, angle=90, outline=True, width=0.012, ellipse=False):
    """Fills a polygon (list of 0..1 points) or ellipse box with a gradient and a dark outline."""
    w, h = img.size
    mask = Image.new("L", img.size, 0)
    md = ImageDraw.Draw(mask)
    if ellipse:
        box = [shape[0] * w, shape[1] * h, shape[2] * w, shape[3] * h]
        md.ellipse(box, fill=255)
    else:
        md.polygon(pts(img, shape), fill=255)
    img.paste(gradient(img.size, stops, angle), (0, 0), mask)
    if outline:
        lw = max(2, int(width * min(w, h) * 1.0))
        d = ImageDraw.Draw(img)
        if ellipse:
            d.ellipse(box, outline=OUTLINE, width=lw)
        else:
            p = pts(img, shape)
            d.line(p + [p[0]], fill=OUTLINE, width=lw, joint="curve")


def line(img, a, b, col, width):
    w, h = img.size
    ImageDraw.Draw(img).line([(a[0] * w, a[1] * h), (b[0] * w, b[1] * h)], fill=col, width=max(1, int(width * min(w, h))))


def gem(img, cx, cy, r, stops):
    w, h = img.size
    rx = r * min(w, h) / w
    ry = r * min(w, h) / h
    fill(img, (cx - rx, cy - ry, cx + rx, cy + ry), stops, 135, ellipse=True, width=0.01)
    hx, hy = cx - rx * 0.35, cy - ry * 0.35
    ImageDraw.Draw(img).ellipse([(hx - rx * 0.28) * w, (hy - ry * 0.28) * h, (hx + rx * 0.28) * w, (hy + ry * 0.28) * h], fill=(255, 255, 255, 200))


def finish(img, name, folder):
    # soft drop shadow, then scale down
    alpha = img.split()[3]
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow.putalpha(alpha.filter(ImageFilter.GaussianBlur(10)).point(lambda v: int(v * 0.55)))
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(shadow, (8, 12))
    out.alpha_composite(img)
    out = out.resize((img.size[0] // SS, img.size[1] // SS), Image.LANCZOS)
    out.save(os.path.join(folder, name + ".png"))


# ------------------------------------------------------------------ icons
def sword(folder):
    img = canvas(1, 3)
    # blade with a fuller
    fill(img, [(0.42, 0.06), (0.5, 0.015), (0.58, 0.06), (0.58, 0.66), (0.42, 0.66)], STEEL, 0)
    line(img, (0.5, 0.07), (0.5, 0.64), (120, 128, 148, 255), 0.03)
    line(img, (0.455, 0.08), (0.455, 0.64), (255, 255, 255, 150), 0.02)
    # crossguard
    fill(img, [(0.12, 0.655), (0.88, 0.655), (0.92, 0.69), (0.88, 0.725), (0.12, 0.725), (0.08, 0.69)], GOLD, 90)
    gem(img, 0.5, 0.69, 0.07, GEM_BLUE)
    # grip and pommel
    fill(img, [(0.43, 0.725), (0.57, 0.725), (0.57, 0.9), (0.43, 0.9)], LEATHER, 0)
    for k in range(5):
        y = 0.74 + k * 0.032
        line(img, (0.43, y), (0.57, y + 0.012), (60, 34, 20, 255), 0.02)
    fill(img, (0.36, 0.89, 0.64, 0.97), GOLD, 135, ellipse=True)
    gem(img, 0.5, 0.93, 0.05, GEM_BLUE)
    finish(img, "weapon", folder)


def shield(folder):
    img = canvas(2, 2)
    outer = [(0.14, 0.1), (0.86, 0.1), (0.86, 0.48), (0.5, 0.94), (0.14, 0.48)]
    fill(img, outer, GOLD, 135, width=0.014)
    inner = [(0.2, 0.15), (0.8, 0.15), (0.8, 0.46), (0.5, 0.86), (0.2, 0.46)]
    fill(img, inner, BLUE, 120, outline=False)
    # gold crest: a cross with a sun
    fill(img, [(0.46, 0.2), (0.54, 0.2), (0.54, 0.74), (0.46, 0.74)], GOLD, 0, width=0.008)
    fill(img, [(0.27, 0.38), (0.73, 0.38), (0.73, 0.46), (0.27, 0.46)], GOLD, 90, width=0.008)
    gem(img, 0.5, 0.42, 0.075, GEM_BLUE)
    line(img, (0.22, 0.17), (0.4, 0.17), (255, 255, 255, 120), 0.012)
    finish(img, "offhand", folder)


def helm(folder):
    img = canvas(2, 2)
    # plume
    fill(img, [(0.46, 0.06), (0.6, 0.02), (0.76, 0.1), (0.66, 0.26), (0.52, 0.24)], BLUE, 45, width=0.01)
    # dome
    dome = [(0.2, 0.86), (0.18, 0.5)]
    for i in range(13):
        a = math.pi + math.pi * i / 12
        dome.append((0.5 + math.cos(a) * 0.32, 0.5 + math.sin(a) * 0.32))
    dome += [(0.82, 0.5), (0.8, 0.86)]
    fill(img, dome, STEEL, 20, width=0.014)
    # T visor
    fill(img, [(0.3, 0.48), (0.7, 0.48), (0.7, 0.55), (0.55, 0.55), (0.55, 0.82), (0.45, 0.82), (0.45, 0.55), (0.3, 0.55)], [(30, 30, 40), (12, 12, 18), (4, 4, 8)], 90, width=0.008)
    # gold brow band and crest ridge
    fill(img, [(0.2, 0.4), (0.8, 0.4), (0.8, 0.45), (0.2, 0.45)], GOLD, 90, width=0.008)
    line(img, (0.5, 0.2), (0.5, 0.4), (226, 176, 72, 255), 0.03)
    line(img, (0.3, 0.26), (0.36, 0.22), (255, 255, 255, 170), 0.014)
    finish(img, "helm", folder)


def armor(folder):
    img = canvas(2, 3)
    # blue tabard skirt
    fill(img, [(0.22, 0.6), (0.78, 0.6), (0.86, 0.95), (0.62, 0.92), (0.5, 0.97), (0.38, 0.92), (0.14, 0.95)], BLUE, 90, width=0.01)
    line(img, (0.5, 0.62), (0.5, 0.94), (226, 176, 72, 255), 0.02)
    # breastplate
    plate = [(0.12, 0.12), (0.34, 0.06), (0.5, 0.12), (0.66, 0.06), (0.88, 0.12), (0.84, 0.32), (0.76, 0.62), (0.24, 0.62), (0.16, 0.32)]
    fill(img, plate, STEEL, 0, width=0.012)
    # pauldrons
    fill(img, (0.02, 0.06, 0.32, 0.24), DARK_STEEL, 120, ellipse=True)
    fill(img, (0.68, 0.06, 0.98, 0.24), DARK_STEEL, 60, ellipse=True)
    # gold trim and ridge
    line(img, (0.5, 0.13), (0.5, 0.6), (140, 146, 164, 255), 0.02)
    line(img, (0.24, 0.6), (0.76, 0.6), (226, 176, 72, 255), 0.028)
    line(img, (0.3, 0.1), (0.5, 0.15), (226, 176, 72, 255), 0.018)
    line(img, (0.7, 0.1), (0.5, 0.15), (226, 176, 72, 255), 0.018)
    gem(img, 0.5, 0.32, 0.06, GEM_BLUE)
    line(img, (0.27, 0.2), (0.3, 0.5), (255, 255, 255, 120), 0.014)
    finish(img, "armor", folder)


def gloves(folder):
    img = canvas(2, 2)
    # cuff
    fill(img, [(0.22, 0.62), (0.78, 0.62), (0.82, 0.9), (0.18, 0.9)], LEATHER, 90, width=0.012)
    line(img, (0.2, 0.68), (0.8, 0.68), (226, 176, 72, 255), 0.025)
    # back of hand plate
    fill(img, [(0.24, 0.36), (0.76, 0.36), (0.78, 0.64), (0.22, 0.64)], STEEL, 20, width=0.012)
    # finger plates
    for i, x in enumerate([0.26, 0.39, 0.52, 0.65]):
        top = 0.12 + (0.04 if i in (0, 3) else 0.0)
        fill(img, [(x, top), (x + 0.1, top), (x + 0.1, 0.37), (x, 0.37)], STEEL, 0, width=0.01)
        line(img, (x, top + 0.09), (x + 0.1, top + 0.09), (98, 104, 122, 255), 0.012)
    # thumb
    fill(img, [(0.06, 0.4), (0.22, 0.38), (0.24, 0.56), (0.12, 0.56)], DARK_STEEL, 0, width=0.01)
    gem(img, 0.5, 0.5, 0.05, GEM_BLUE)
    finish(img, "gloves", folder)


def belt(folder):
    img = canvas(2, 1)
    fill(img, [(0.04, 0.36), (0.96, 0.36), (0.96, 0.66), (0.04, 0.66)], LEATHER, 90, width=0.02)
    for x in (0.14, 0.3, 0.7, 0.86):
        gem(img, x, 0.51, 0.045, [(255, 236, 160), (210, 160, 60), (120, 80, 24)])
    # buckle
    fill(img, [(0.4, 0.2), (0.6, 0.2), (0.6, 0.82), (0.4, 0.82)], GOLD, 135, width=0.022)
    fill(img, [(0.45, 0.34), (0.55, 0.34), (0.55, 0.68), (0.45, 0.68)], LEATHER, 90, width=0.012)
    line(img, (0.5, 0.36), (0.5, 0.66), (200, 200, 210, 255), 0.03)
    finish(img, "belt", folder)


def boots(folder):
    img = canvas(2, 2)
    # greave
    fill(img, [(0.3, 0.08), (0.62, 0.08), (0.64, 0.62), (0.28, 0.62)], STEEL, 0, width=0.012)
    line(img, (0.46, 0.1), (0.46, 0.6), (98, 104, 122, 255), 0.016)
    fill(img, (0.3, 0.42, 0.62, 0.58), GOLD, 135, ellipse=True)
    # foot
    fill(img, [(0.26, 0.6), (0.64, 0.6), (0.9, 0.76), (0.92, 0.9), (0.24, 0.9)], DARK_STEEL, 20, width=0.012)
    line(img, (0.24, 0.86), (0.92, 0.86), (66, 38, 22, 255), 0.04)
    line(img, (0.35, 0.14), (0.36, 0.4), (255, 255, 255, 140), 0.014)
    finish(img, "boots", folder)


def ring(folder):
    img = canvas(1, 1)
    w, h = img.size
    d = ImageDraw.Draw(img)
    fill(img, (0.18, 0.3, 0.82, 0.92), GOLD, 135, ellipse=True, width=0.03)
    # hollow centre
    d.ellipse([0.32 * w, 0.44 * h, 0.68 * w, 0.8 * h], fill=(0, 0, 0, 0), outline=OUTLINE, width=int(0.03 * w))
    # setting and gem
    fill(img, [(0.36, 0.3), (0.64, 0.3), (0.58, 0.14), (0.42, 0.14)], GOLD, 90, width=0.02)
    gem(img, 0.5, 0.2, 0.13, GEM_BLUE)
    finish(img, "ring", folder)


def amulet(folder):
    img = canvas(1, 1)
    line(img, (0.18, 0.06), (0.44, 0.46), (226, 176, 72, 255), 0.035)
    line(img, (0.82, 0.06), (0.56, 0.46), (226, 176, 72, 255), 0.035)
    fill(img, [(0.5, 0.36), (0.74, 0.62), (0.5, 0.94), (0.26, 0.62)], GOLD, 135, width=0.022)
    gem(img, 0.5, 0.64, 0.14, GEM_RED)
    finish(img, "amulet", folder)


def build(folder):
    os.makedirs(folder, exist_ok=True)
    for f in (sword, shield, helm, armor, gloves, belt, boots, ring, amulet):
        f(folder)


if __name__ == "__main__":
    build(sys.argv[1] if len(sys.argv) > 1 else "assets/items")
    print("done")
