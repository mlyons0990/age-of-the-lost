"""Paint a path connector on a layout image by re-mapping a strip of an existing painted path along a new centreline
(free, local). The flagstone texture follows the curve (sampled at the same along/across position on the source path),
feathered at the sides. Used to join the real W1 painting's path exit to the master layout's path.
usage: python path_connector.py <in.png> <out.png> '<src centreline json>' '<dst centreline json>' <half_width_px>"""
import sys, json
import numpy as np, cv2
from PIL import Image

def resample(poly, n):
    p = np.array(poly, np.float64); seg = np.linalg.norm(np.diff(p, axis=0), axis=1)
    s = np.concatenate([[0], np.cumsum(seg)]); t = np.linspace(0, s[-1], n)
    return np.stack([np.interp(t, s, p[:, 0]), np.interp(t, s, p[:, 1])], 1), s[-1]

src_img = np.asarray(Image.open(sys.argv[1]).convert("RGB")).astype(np.float32)
SRC, DST, hw = json.loads(sys.argv[3]), json.loads(sys.argv[4]), float(sys.argv[5])
N = 400
P, Ls = resample(SRC, N); C, Ld = resample(DST, N)
def normals(q):
    d = np.gradient(q, axis=0); d /= np.linalg.norm(d, axis=1, keepdims=True) + 1e-9
    return np.stack([-d[:, 1], d[:, 0]], 1)
nP, nC = normals(P), normals(C)
H, W = src_img.shape[:2]
x0, y0 = int(max(0, C[:, 0].min() - hw * 2)), int(max(0, C[:, 1].min() - hw * 2))
x1, y1 = int(min(W, C[:, 0].max() + hw * 2)), int(min(H, C[:, 1].max() + hw * 2))
yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float64)
q = np.stack([xx.ravel(), yy.ravel()], 1)
# nearest centreline sample for every pixel in the box
d2 = ((q[:, None, :] - C[None, ::4, :]) ** 2).sum(-1)
k = d2.argmin(1) * 4
off = ((q - C[k]) * nC[k]).sum(1)                       # signed distance across the path
src_pt = P[k] + nP[k] * off[:, None]                    # same along/across position on the source path
mapx = src_pt[:, 0].reshape(yy.shape).astype(np.float32); mapy = src_pt[:, 1].reshape(yy.shape).astype(np.float32)
tex = cv2.remap(src_img, mapx, mapy, cv2.INTER_LINEAR, borderMode=cv2.BORDER_REFLECT)
a = np.clip((hw - np.abs(off)) / (hw * 0.35), 0, 1).reshape(yy.shape)
ends = np.clip(np.minimum(k, N - 1 - k) / 12.0, 0, 1).reshape(yy.shape)  # fade in/out at both ends
a = (a * ends)[..., None]
out = src_img.copy()
out[y0:y1, x0:x1] = src_img[y0:y1, x0:x1] * (1 - a) + tex * a
Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(sys.argv[2])
print("connector box", (x0, y0, x1, y1))
