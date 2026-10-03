#!/usr/bin/env python3
"""Generates all figures, data, and tables of the sample paper "How Wrong Is Affine Texture Mapping?".

Run it from the root folder after changing the experiments:

    python3 scripts/sample_paper.py

It writes
- figs/teaser.svg              the teaser: renderings as embedded PNGs, labels typeset by LaTeX,
- figs/data/edge_error.csv     maximum error along an edge over the depth ratio (left plot),
- figs/data/subdivision.csv    maximum error over the number of subdivisions (right plot),
- tabs/subdivision.tex         the subdivision table,
- imgs/checkerboard.png        the texture, for the raster image test of the appendix,
and prints the numbers that the text uses.

Requires numpy, Pillow, and matplotlib (only for the viridis colormap).
"""
import base64
import io
import math
import pathlib

import numpy as np
from matplotlib import colormaps
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent

TEXELS = 256           # texture size in texels, along u and v
CHECK = 32             # size of a check in texels
NEAR = 1.0             # depth of the near edge of the floor
FAR = 4.0              # depth of the far edge, i.e., the depth ratio r = 4
FOCAL = 460.0          # focal length in pixels
WIDTH, HEIGHT = 960, 400
TOP = -72.0            # image row of the camera axis; the floor lies below it
SUBDIVISIONS = (1, 2, 4, 8, 16, 24, 32)
RATIOS = (1.25, 1.5, 2, 3, 4, 6, 8, 12, 16)
HALF_TEXEL = 0.5
BP_PER_PT = 72.0 / 72.27   # SVG and Inkscape measure in PostScript points (TeX's bp), TeX in pt


def max_error_fraction(r):
    """Maximum error of affine interpolation along an edge, as a fraction of the edge,
    for the depth ratio r of its endpoints (Eq:MaxError in the paper)."""
    r = max(r, 1.0 / r)
    return (math.sqrt(r) - 1.0) / (math.sqrt(r) + 1.0)


def floor_triangles(n, far=FAR):
    """The floor quad y = -1, x in [-1, 1], z in [NEAR, far], split into n x n cells of two
    triangles each. Texture coordinates in texels: u along x, v along z.
    Returns a list of (camera-space points (3, 3), texture coordinates (3, 2))."""
    triangles = []
    for i in range(n):
        for j in range(n):
            corners = []
            for a, b in ((i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)):
                x = -1.0 + 2.0 * a / n
                z = NEAR + (far - NEAR) * b / n
                corners.append(((x, -1.0, z), (TEXELS * a / n, TEXELS * b / n)))
            for k in ((0, 1, 2), (0, 2, 3)):
                p = np.array([corners[m][0] for m in k])
                u = np.array([corners[m][1] for m in k])
                triangles.append((p, u))
    return triangles


def rasterize(triangles, rows, width, height, samples=1):
    """Rasterizes triangles at the given image rows (y offset of the first row).
    Returns affine and perspective-correct texture coordinates per sample, shape
    (height * samples, width * samples, 2), NaN where no triangle covers the sample."""
    s = samples
    affine = np.full((height * s, width * s, 2), np.nan)
    correct = np.full((height * s, width * s, 2), np.nan)
    for p, u in triangles:
        w = p[:, 2]
        sx = WIDTH / 2 + FOCAL * p[:, 0] / w
        sy = TOP + FOCAL * (-p[:, 1]) / w - rows
        x0, x1 = int(max(0, np.floor(sx.min() * s))), int(min(width * s, np.ceil(sx.max() * s) + 1))
        y0, y1 = int(max(0, np.floor(sy.min() * s))), int(min(height * s, np.ceil(sy.max() * s) + 1))
        if x0 >= x1 or y0 >= y1:
            continue
        X, Y = np.meshgrid((np.arange(x0, x1) + 0.5) / s, (np.arange(y0, y1) + 0.5) / s)
        # Edge functions give the screen-space barycentric coordinates (Pineda).
        area = (sx[1] - sx[0]) * (sy[2] - sy[0]) - (sx[2] - sx[0]) * (sy[1] - sy[0])
        lam = np.empty((3,) + X.shape)
        for k in range(3):
            a, b = (k + 1) % 3, (k + 2) % 3
            lam[k] = ((sx[b] - sx[a]) * (Y - sy[a]) - (sy[b] - sy[a]) * (X - sx[a])) / area
        inside = np.all(lam >= -1e-12, axis=0)
        free = np.isnan(affine[y0:y1, x0:x1, 0])
        mask = inside & free
        if not mask.any():
            continue
        l = lam[:, mask]
        q = l / w[:, None]
        affine[y0:y1, x0:x1][mask] = (l.T @ u)
        correct[y0:y1, x0:x1][mask] = (q.T @ u) / q.sum(axis=0)[:, None]
    return affine, correct


def checkerboard(uv):
    """Gray level of the checkerboard at texture coordinates uv (nearest texel); white outside."""
    covered = ~np.isnan(uv[..., 0])
    t = np.floor(np.nan_to_num(uv) / CHECK)
    gray = np.where((t[..., 0] + t[..., 1]) % 2 == 0, 0.88, 0.32)
    return np.where(covered, gray, 1.0)


def render_gray(uv, samples):
    """Averages the supersamples of a checkerboard rendering to an 8-bit gray image."""
    g = checkerboard(uv).reshape(HEIGHT, samples, WIDTH, samples).mean(axis=(1, 3))
    return Image.fromarray(np.uint8(np.round(255 * g)), mode="L")


def error_texels(affine, correct):
    return np.linalg.norm(affine - correct, axis=-1)


def render_error(err, vmax):
    """Colors the error in texels with viridis on [0, vmax]; white outside the floor."""
    rgb = colormaps["viridis"](np.clip(np.nan_to_num(err) / vmax, 0, 1))[..., :3]
    rgb[np.isnan(err)] = 1.0
    return Image.fromarray(np.uint8(np.round(255 * rgb)), mode="RGB")


def png_base64(image):
    buffer = io.BytesIO()
    image.save(buffer, format="PNG", optimize=True)
    return base64.b64encode(buffer.getvalue()).decode("ascii")


def teaser_svg(images, vmax):
    """2 x 2 panels at the final size, 504 pt wide (text width of the EG layout).
    The text elements are typeset by LaTeX (\\includesvg with inkscapelatex).
    The coordinates are TeX points; the size of the page is in SVG points (bp)."""
    pw = 248.0                       # panel width in pt
    ph = pw * HEIGHT / WIDTH         # panel height in pt
    gap = 8.0
    label = 13.0                     # height of the label line below a panel
    cbar = 12.0                      # extra space below panel (d) for the colorbar ticks
    stroke = 0.4                     # frames lie inside the panels, so the drawing is 504 pt wide
    total_w = 2 * pw + gap
    total_h = 2 * (ph + label) + cbar + gap
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
           f'width="{total_w * BP_PER_PT:.4f}pt" height="{total_h * BP_PER_PT:.4f}pt" '
           f'viewBox="0 0 {total_w} {total_h:.4f}">',
           "<!-- Generated by scripts/sample_paper.py; do not edit by hand. -->"]
    stops = "".join(f'<stop offset="{t:.3f}" stop-color="#{"".join(f"{int(round(255 * c)):02x}" for c in colormaps["viridis"](t)[:3])}"/>'
                    for t in np.linspace(0, 1, 17))
    out.append(f'<defs><linearGradient id="viridis" x1="0" y1="0" x2="1" y2="0">{stops}</linearGradient></defs>')
    text = 'font-family="serif" font-size="9" fill="#000"'
    for index, (img, caption) in enumerate(images):
        col, row = index % 2, index // 2
        x = col * (pw + gap)
        y = row * (ph + label + gap)
        out.append(f'<image x="{x}" y="{y}" width="{pw}" height="{ph:.3f}" preserveAspectRatio="none" '
                   f'style="image-rendering:pixelated" xlink:href="data:image/png;base64,{png_base64(img)}"/>')
        out.append(f'<rect x="{x + stroke / 2}" y="{y + stroke / 2:.3f}" width="{pw - stroke}" height="{ph - stroke:.3f}" '
                   f'fill="none" stroke="#808080" stroke-width="{stroke}"/>')
        if caption is not None:
            out.append(f'<text x="{x + pw / 2}" y="{y + ph + 10}" text-anchor="middle" {text}>{caption}</text>')
        else:
            # Panel (d): label and colorbar with ticks.
            out.append(f'<text x="{x}" y="{y + ph + 10}" text-anchor="start" {text}>(d) Error of (a) [texels]</text>')
            bx, bw = x + 112.0, pw - 124.0
            by = y + ph + 4
            out.append(f'<rect x="{bx}" y="{by}" width="{bw}" height="5" fill="url(#viridis)" stroke="#808080" stroke-width="0.4"/>')
            for tick in range(0, int(vmax) + 1, 40):
                tx = bx + bw * tick / vmax
                out.append(f'<line x1="{tx:.2f}" y1="{by + 5}" x2="{tx:.2f}" y2="{by + 7}" stroke="#000" stroke-width="0.4"/>')
                out.append(f'<text x="{tx:.2f}" y="{by + 15}" text-anchor="middle" {text}>{tick}</text>')
    out.append("</svg>")
    return "\n".join(out)


def subdivision_table(rows):
    lines = [
        "% Generated by scripts/sample_paper.py; do not edit by hand.",
        "% Modern table: \\toprule, \\midrule, \\bottomrule, and \\cmidrule to group the error columns.",
        "\\begin{tabular}{@{}rrrrr@{}}",
        "\\toprule",
        " & & \\multicolumn{3}{c}{Max.\\ error [texels]} \\\\",
        "\\cmidrule(l){3-5}",
        "$n$ & Triangles & Predicted & Bound & Measured $\\downarrow$ \\\\",
        "\\midrule",
    ]
    for n, triangles, predicted, bound, measured in rows:
        m = f"\\num{{{measured:.3f}}}"
        if measured < HALF_TEXEL:
            m = f"\\textbf{{{m}}}"
        lines.append(f"{n} & \\num{{{triangles}}} & \\num{{{predicted:.3f}}} & \\num{{{bound:.3f}}} & {m} \\\\")
    lines += [
        "\\bottomrule",
        "\\end{tabular}",
    ]
    return "\n".join(lines) + "\n"


def main():
    diagonal = math.sqrt(2) * TEXELS          # texture length of the diagonal of the floor
    r = FAR / NEAR

    # Teaser: affine, affine with 4 x 4 cells, perspective-correct, and the error of affine.
    samples = 3
    aff1, cor1 = rasterize(floor_triangles(1), 0, WIDTH, HEIGHT, samples)
    aff4, _ = rasterize(floor_triangles(4), 0, WIDTH, HEIGHT, samples)
    err1 = error_texels(*rasterize(floor_triangles(1), 0, WIDTH, HEIGHT, 1))
    vmax = 120.0
    images = [
        (render_gray(aff1, samples), "(a) Affine"),
        (render_gray(aff4, samples), "(b) Affine, $4\\times4$ cells"),
        (render_gray(cor1, samples), "(c) Perspective-correct"),
        (render_error(err1, vmax), None),
    ]
    (ROOT / "figs").mkdir(exist_ok=True)
    (ROOT / "figs" / "teaser.svg").write_text(teaser_svg(images, vmax), encoding="utf-8")

    # The texture as a PNG file for the raster image test of the appendix.
    (ROOT / "imgs").mkdir(exist_ok=True)
    texels = np.stack(np.meshgrid(np.arange(TEXELS) + 0.5, np.arange(TEXELS) + 0.5), axis=-1)
    Image.fromarray(np.uint8(np.round(255 * checkerboard(texels))), mode="L").save(
        ROOT / "imgs" / "checkerboard.png", optimize=True)

    # Left plot: maximum error along the diagonal over the depth ratio, as a fraction of the edge.
    data = ROOT / "figs" / "data"
    data.mkdir(parents=True, exist_ok=True)
    lines = ["ratio,predicted,measured"]
    for ratio in RATIOS:
        top = TOP + FOCAL / ratio - 4
        height = int(FOCAL - FOCAL / ratio + 12)
        err = error_texels(*rasterize(floor_triangles(1, far=NEAR * ratio), top, WIDTH, height, 1))
        lines.append(f"{ratio},{max_error_fraction(ratio):.6f},{np.nanmax(err) / diagonal:.6f}")
    (data / "edge_error.csv").write_text("\n".join(lines) + "\n", encoding="utf-8")

    # Right plot and table: maximum error over the number of subdivisions n.
    rows = []
    lines = ["n,triangles,predicted,bound,measured"]
    for n in SUBDIVISIONS:
        err = error_texels(*rasterize(floor_triangles(n), 0, WIDTH, HEIGHT, 1))
        # The longest edge with the largest depth ratio is the diagonal of a cell next to the camera.
        predicted = diagonal / n * max_error_fraction(1 + (r - 1) / n)
        bound = diagonal * (r - 1) / (4 * n * n)
        measured = float(np.nanmax(err))
        rows.append((n, 2 * n * n, predicted, bound, measured))
        lines.append(f"{n},{2 * n * n},{predicted:.6f},{bound:.6f},{measured:.6f}")
    (data / "subdivision.csv").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (ROOT / "tabs").mkdir(exist_ok=True)
    (ROOT / "tabs" / "subdivision.tex").write_text(subdivision_table(rows), encoding="utf-8")

    # Supplemental material: the error inside a triangle does not exceed the error along its edges.
    # We evaluate the error at the interior points of a barycentric grid and divide its maximum
    # by the largest edge error, Eq:MaxError for each edge.
    rng = np.random.default_rng(1)
    m = 200
    i, j = np.meshgrid(np.arange(m + 1), np.arange(m + 1), indexing="ij")
    keep = (i + j < m) & (i > 0) & (j > 0)
    lam = np.stack([1 - (i[keep] + j[keep]) / m, i[keep] / m, j[keep] / m], axis=1)
    worst = 0.0
    trials = 3000
    for _ in range(trials):
        w = rng.uniform(1, 10, 3)
        u = rng.uniform(0, 1, (3, 2))
        q = lam / w
        inner = np.max(np.linalg.norm(lam @ u - (q @ u) / q.sum(axis=1, keepdims=True), axis=1))
        edges = max(np.linalg.norm(u[a] - u[b]) * max_error_fraction(w[a] / w[b])
                    for a, b in ((0, 1), (1, 2), (2, 0)))
        worst = max(worst, inner / edges)

    print(f"depth ratio r = {r}, max error fraction = {max_error_fraction(r):.6f}, "
          f"t* = {math.sqrt(r) / (1 + math.sqrt(r)):.4f}")
    print(f"diagonal = {diagonal:.2f} texels, max error n=1: predicted {rows[0][2]:.2f}, measured {rows[0][4]:.2f}")
    n_half = math.ceil(math.sqrt(diagonal * (r - 1) / (2 * HALF_TEXEL * 2)))
    print(f"pieces for half a texel from the bound: n >= sqrt(l (r-1) / 2) = {math.sqrt(diagonal * (r - 1) / 2):.2f} -> {n_half}")
    for row in rows:
        print("n={:2d} triangles={:5d} predicted={:9.3f} bound={:9.3f} measured={:9.3f}".format(*row))

    # Discussion: the floor with a larger texture, and the error of the farthest cells.
    big = math.sqrt(2) * 4096
    n_min = math.sqrt(big * (r - 1) / (4 * HALF_TEXEL))
    n_big = math.ceil(n_min)
    print(f"texture 4096 x 4096: n >= {n_min:.2f} -> {n_big} x {n_big} cells, {2 * n_big * n_big} triangles")
    n = 24
    far_ratio = FAR / (FAR - (FAR - NEAR) / n)
    print(f"n={n}: largest error of the farthest cells {diagonal / n * max_error_fraction(far_ratio):.3f} texels, "
          f"of the nearest cells {diagonal / n * max_error_fraction(1 + (r - 1) / n):.3f} texels")
    print(f"random triangles: {trials}, interior points {len(lam)}, max interior error / max edge error = {worst:.6f}")
    print("edge_error.csv:")
    print((data / "edge_error.csv").read_text())


if __name__ == "__main__":
    main()
