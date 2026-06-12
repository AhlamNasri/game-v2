"""
Best-effort, NON-DESTRUCTIVE skin-stripper for the dress-up assets.

Background: many `outfit_*` "fit" PNGs and ALL hair PNGs are full-doll /
full-head renders with the bald chibi body + face baked in. Because the base
body (assets/characters/body/*) already carries its own face, the correct
layered result is "garment only" / "hair only" stacked over that body.

This script removes skin-coloured pixels (head, face, neck, arms, legs) and
keeps everything else, WITHOUT changing the 1248x1248 canvas (so the renderer's
fullCanvas placement stays aligned).

It is intentionally lossy: skin-toned fabric/hair may be partially eaten and
garment edges that sat against skin may show small holes. Output goes to
asset_cleanup/cleaned/ (mirrors source tree) and review montages to
asset_cleanup/review/. Originals are never touched.

Usage:  py -3 tool/clean_assets.py
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = "assets/characters"
OUT = "asset_cleanup/cleaned"
REVIEW = "asset_cleanup/review"

# ---- which files to strip, and which base body to preview them on ----
GIRL_BODY = f"{SRC}/body/girl_light_fit.png"
BOY_BODY = f"{SRC}/body/boy_light.png"

OUTFITS = [
    "clothes/dresses/outfit_casual_hoodie",
    "clothes/dresses/outfit_cool_jacket",
    "clothes/dresses/outfit_hoodie_jeans",
    "clothes/dresses/outfit_magical_girl",
    "clothes/dresses/outfit_school_uniform",
    "clothes/dresses/outfit_sporty_tracksuit",
    "clothes/dresses/outfit_summer_dress",
    "clothes/dresses/outfit_wizard_robe",
    "clothes/dresses/boy_outfit_cool_jacket",
    "clothes/dresses/boy_outfit_hero",
    "clothes/dresses/boy_outfit_sporty",
]
HAIR = [
    "hair/girl_light_head_hair1",
    "hair/girl_light_head_hair2",
    "hair/girl_tan_head_hair1",
    "hair/girl_tan_head_hair2",
    "hair/boy_light_head_hair1",
    "hair/boy_light_head_hair2",
    "hair/boy_tan_head_hair1",
    "hair/boy_tan_head_hair2",
]


def resolve_inputs():
    """Return list of (rel_png_path, base_body_path). Includes _fit + non-_fit."""
    jobs = []
    for stem in OUTFITS:
        body = BOY_BODY if "boy_" in os.path.basename(stem) else GIRL_BODY
        for suffix in ("", "_fit"):
            p = f"{stem}{suffix}.png"
            if os.path.exists(os.path.join(SRC, p)):
                jobs.append((p, body))
    for stem in HAIR:
        body = BOY_BODY if "boy_" in stem else GIRL_BODY
        p = f"{stem}.png"
        if os.path.exists(os.path.join(SRC, p)):
            jobs.append((p, body))
    return jobs


def _hsv(rgb):
    """Vectorised RGB(0-255)->H(0-360),S(0-1),V(0-1)."""
    r, g, b = rgb[..., 0] / 255.0, rgb[..., 1] / 255.0, rgb[..., 2] / 255.0
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    df = mx - mn
    h = np.zeros_like(mx)
    nz = df > 1e-6
    # hue per dominant channel
    rmask = nz & (mx == r)
    gmask = nz & (mx == g)
    bmask = nz & (mx == b)
    h[rmask] = (60 * ((g - b) / np.where(df == 0, 1, df)))[rmask] % 360
    h[gmask] = (60 * ((b - r) / np.where(df == 0, 1, df)) + 120)[gmask]
    h[bmask] = (60 * ((r - g) / np.where(df == 0, 1, df)) + 240)[bmask]
    s = np.where(mx == 0, 0, df / np.where(mx == 0, 1, mx))
    return h, s, mx


def build_skin_palette(body_path):
    """Sample the real skin colours (incl. shadows) from a base body in Lab."""
    a = np.array(Image.open(body_path).convert("RGBA"))
    op = a[:, :, 3] > 60
    rgb = a[:, :, :3].astype(np.float32)
    h, s, v = _hsv(rgb)
    skin = op & (h > 6) & (h < 46) & (s > 0.12) & (s < 0.9) & (v > 0.35)
    px = a[:, :, :3][skin]
    if len(px) > 4000:  # subsample for speed
        idx = np.random.default_rng(0).choice(len(px), 4000, replace=False)
        px = px[idx]
    lab = np.array(Image.fromarray(px.reshape(-1, 1, 3).astype(np.uint8), "RGB")
                   .convert("LAB")).reshape(-1, 3).astype(np.float32)
    return lab


def skin_mask(a, palette_lab, dist=17.0):
    """Skin = opaque, in skin hue/sat range, and close (Lab) to the sampled
    body palette. Hue/sat gate protects white/grey garments and off-hue fabric;
    the Lab distance keeps it locked to *this* doll's actual skin tone."""
    from scipy.spatial import cKDTree

    alpha = a[:, :, 3]
    rgb = a[:, :, :3].astype(np.float32)
    h, s, v = _hsv(rgb)
    gate = (alpha > 30) & (h > 6) & (h < 46) & (s > 0.13) & (v > 0.35)

    lab = np.array(
        Image.fromarray(np.ascontiguousarray(a[:, :, :3]), "RGB").convert("LAB")
    ).astype(np.float32)

    tree = cKDTree(palette_lab)
    flat = lab[gate]
    if len(flat) == 0:
        return np.zeros(alpha.shape, dtype=bool)
    d, _ = tree.query(flat, k=1)
    near = d < dist
    out = np.zeros(alpha.shape, dtype=bool)
    out[gate] = near
    return out


_PALETTE = None


def combined_palette():
    """Both skin tones together — the outfit renders mix light + tan skin
    inconsistently, so we must match against either."""
    global _PALETTE
    if _PALETTE is None:
        bodies = [
            f"{SRC}/body/girl_light_fit.png",
            f"{SRC}/body/boy_light.png",
            f"{SRC}/body/girl_tan.png",
            f"{SRC}/body/boy_tan.png",
        ]
        _PALETTE = np.vstack([build_skin_palette(b) for b in bodies])
    return _PALETTE


def face_ellipse_mask(opaque):
    """Elliptical region covering the face on a head-only ('hair') image.

    For hair plates, hair can be the same colour as skin (golden blonde ==
    tan), so colour keying alone wipes the hair. We instead only strip skin
    *inside* the face oval, derived from the head's bounding box, so the outer
    hair ring is preserved whatever its colour."""
    rows = np.where(opaque.any(axis=1))[0]
    cols = np.where(opaque.any(axis=0))[0]
    if len(rows) == 0:
        return np.zeros(opaque.shape, dtype=bool)
    t, b = rows[0], rows[-1]
    l, r = cols[0], cols[-1]
    hh, hw = b - t, r - l
    cy = t + 0.56 * hh   # face sits just below head centre
    cx = l + 0.50 * hw
    ry = 0.40 * hh
    rx = 0.40 * hw
    yy, xx = np.mgrid[0:opaque.shape[0], 0:opaque.shape[1]]
    return (((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2) <= 1.0


def strip(path):
    im = Image.open(os.path.join(SRC, path)).convert("RGBA")
    a = np.array(im)
    alpha = a[:, :, 3]
    opaque = alpha > 30
    sm = skin_mask(a, combined_palette())
    if path.startswith("hair/"):
        sm = sm & face_ellipse_mask(opaque)

    # Connected components: drop only sizeable skin regions (head/limbs/neck);
    # keep tiny skin-coloured speckles that are likely fabric detail / noise.
    lbl, n = ndimage.label(sm)
    if n:
        sizes = ndimage.sum(np.ones_like(lbl), lbl, range(1, n + 1))
        total_op = max(int(opaque.sum()), 1)
        keep_remove = np.zeros(n + 1, dtype=bool)
        for i, s in enumerate(sizes, start=1):
            if s / total_op > 0.0015:  # >0.15% of content -> body region
                keep_remove[i] = True
        remove = keep_remove[lbl]
    else:
        remove = sm

    # Dilate the removal mask a touch to eat the anti-aliased skin fringe that
    # otherwise leaves a pale halo around the kept garment.
    remove = ndimage.binary_dilation(remove, iterations=2)

    out = a.copy()
    out[remove, 3] = 0
    cleaned = Image.fromarray(out, "RGBA")

    dst = os.path.join(OUT, path)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    cleaned.save(dst)
    removed_frac = remove.sum() / max(opaque.sum(), 1)
    return im, cleaned, sm, removed_frac


def checker(size, c=20):
    bg = Image.new("RGBA", size, (255, 255, 255, 255))
    px = bg.load()
    for yy in range(size[1]):
        for xx in range(size[0]):
            v = 215 if ((xx // c) + (yy // c)) % 2 == 0 else 165
            px[xx, yy] = (v, v, v, 255)
    return bg


def main():
    jobs = resolve_inputs()
    from PIL import ImageDraw

    body_cache = {}

    def body_for(p):
        if p not in body_cache:
            body_cache[p] = Image.open(p).convert("RGBA")
        return body_cache[p]

    CELL = 300
    rows = []
    print(f"Processing {len(jobs)} files...\n")
    print(f"{'file':46s} {'removed%':>8s}")
    for path, bodypath in jobs:
        orig, cleaned, sm, frac = strip(path)
        print(f"{path:46s} {frac*100:7.1f}")

        # review row: original | skin mask (red) | cleaned-on-checker | on body
        thumbs = []
        ck = checker((CELL, CELL))

        def fit(img):
            t = img.copy()
            t.thumbnail((CELL, CELL))
            cell = ck.copy()
            cell.alpha_composite(t, ((CELL - t.width) // 2, (CELL - t.height) // 2))
            return cell

        thumbs.append(fit(orig))

        overlay = np.array(orig).copy()
        overlay[sm] = [255, 0, 0, 255]
        thumbs.append(fit(Image.fromarray(overlay, "RGBA")))

        thumbs.append(fit(cleaned))

        comp = body_for(bodypath).copy()
        comp.alpha_composite(cleaned.resize(comp.size))
        thumbs.append(fit(comp))

        rows.append((os.path.basename(path), thumbs))

    # assemble one tall review sheet
    cols = 4
    labels = ["original", "skin mask (red=remove)", "cleaned", "cleaned OVER base body"]
    rowh = CELL + 22
    sheet = Image.new("RGBA", (cols * CELL, len(rows) * rowh + 24), (255, 255, 255, 255))
    d = ImageDraw.Draw(sheet)
    for c, lab in enumerate(labels):
        d.text((c * CELL + 4, 6), lab, fill=(0, 0, 0, 255))
    for r, (name, thumbs) in enumerate(rows):
        y = 24 + r * rowh
        for c, t in enumerate(thumbs):
            sheet.alpha_composite(t, (c * CELL, y))
        d.text((4, y + CELL + 4), name, fill=(0, 0, 0, 255))

    # split into chunks so each saved image is readable
    os.makedirs(REVIEW, exist_ok=True)
    per = 6
    for ci, start in enumerate(range(0, len(rows), per)):
        chunk = rows[start:start + per]
        h = 24 + len(chunk) * rowh
        s = Image.new("RGBA", (cols * CELL, h), (255, 255, 255, 255))
        dd = ImageDraw.Draw(s)
        for c, lab in enumerate(labels):
            dd.text((c * CELL + 4, 6), lab, fill=(0, 0, 0, 255))
        for r, (name, thumbs) in enumerate(chunk):
            y = 24 + r * rowh
            for c, t in enumerate(thumbs):
                s.alpha_composite(t, (c * CELL, y))
            dd.text((4, y + CELL + 4), name, fill=(0, 0, 0, 255))
        outp = os.path.join(REVIEW, f"review_{ci+1}.png")
        s.convert("RGB").save(outp, quality=88)
        print("wrote", outp)


def promote():
    """Copy cleaned PNGs over the real assets, backing up originals first.

    Backup -> asset_cleanup/originals_backup/ (mirrors tree). Re-runnable; the
    backup is only written the first time so it always holds the true original.
    """
    import shutil

    BACKUP = "asset_cleanup/originals_backup"
    n = 0
    for root, _, files in os.walk(OUT):
        for fn in files:
            if not fn.endswith(".png"):
                continue
            cleaned = os.path.join(root, fn)
            rel = os.path.relpath(cleaned, OUT)
            target = os.path.join(SRC, rel)
            backup = os.path.join(BACKUP, rel)
            if not os.path.exists(backup):
                os.makedirs(os.path.dirname(backup), exist_ok=True)
                shutil.copy2(target, backup)
            shutil.copy2(cleaned, target)
            n += 1
    print(f"Promoted {n} cleaned files into {SRC} (originals backed up to {BACKUP}).")


if __name__ == "__main__":
    import sys

    if "--promote" in sys.argv:
        promote()
    else:
        main()
