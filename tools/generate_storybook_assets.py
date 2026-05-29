from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "characters"
SIZE = (720, 1040)
SCALE = 2
W, H = SIZE


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.lstrip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


def canvas() -> Image.Image:
    return Image.new("RGBA", (W * SCALE, H * SCALE), (0, 0, 0, 0))


def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img = img.resize(SIZE, Image.Resampling.LANCZOS)
    img.save(path)


def draw_soft_ellipse(
    img: Image.Image,
    box: tuple[int, int, int, int],
    color: str,
    blur: int = 0,
    alpha: int = 255,
) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    scaled = tuple(v * SCALE for v in box)
    draw.ellipse(scaled, fill=rgba(color, alpha))
    if blur:
        layer = layer.filter(ImageFilter.GaussianBlur(blur * SCALE))
    img.alpha_composite(layer)


def draw_soft_round(
    img: Image.Image,
    box: tuple[int, int, int, int],
    radius: int,
    color: str,
    blur: int = 0,
    alpha: int = 255,
) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    scaled = tuple(v * SCALE for v in box)
    draw.rounded_rectangle(scaled, radius=radius * SCALE, fill=rgba(color, alpha))
    if blur:
        layer = layer.filter(ImageFilter.GaussianBlur(blur * SCALE))
    img.alpha_composite(layer)


def draw_gradient_ellipse(
    img: Image.Image,
    box: tuple[int, int, int, int],
    top: str,
    bottom: str,
    outline: str | None = None,
) -> None:
    x0, y0, x1, y1 = [v * SCALE for v in box]
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).ellipse((x0, y0, x1, y1), fill=255)
    grad = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(grad)
    h = max(1, y1 - y0)
    c1 = rgba(top)
    c2 = rgba(bottom)
    for y in range(y0, y1):
        t = (y - y0) / h
        color = tuple(round(c1[i] * (1 - t) + c2[i] * t) for i in range(4))
        draw.line((x0, y, x1, y), fill=color)
    img.alpha_composite(Image.composite(grad, Image.new("RGBA", img.size), mask))
    if outline:
        ImageDraw.Draw(img).ellipse((x0, y0, x1, y1), outline=rgba(outline, 110), width=4 * SCALE)


def draw_gradient_round(
    img: Image.Image,
    box: tuple[int, int, int, int],
    radius: int,
    top: str,
    bottom: str,
) -> None:
    x0, y0, x1, y1 = [v * SCALE for v in box]
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((x0, y0, x1, y1), radius=radius * SCALE, fill=255)
    grad = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(grad)
    h = max(1, y1 - y0)
    c1 = rgba(top)
    c2 = rgba(bottom)
    for y in range(y0, y1):
        t = (y - y0) / h
        color = tuple(round(c1[i] * (1 - t) + c2[i] * t) for i in range(4))
        draw.line((x0, y, x1, y), fill=color)
    img.alpha_composite(Image.composite(grad, Image.new("RGBA", img.size), mask))


def curve_points(cx: int, cy: int, rx: int, ry: int, start: float, end: float, count: int) -> list[tuple[int, int]]:
    return [
        (
            round((cx + math.cos(start + (end - start) * i / (count - 1)) * rx) * SCALE),
            round((cy + math.sin(start + (end - start) * i / (count - 1)) * ry) * SCALE),
        )
        for i in range(count)
    ]


def draw_body(path: Path, skin: str, gender: str) -> None:
    img = canvas()
    draw_soft_ellipse(img, (226, 900, 494, 950), "#3b2430", blur=15, alpha=45)
    draw_soft_round(img, (288, 315, 432, 400), 30, skin, alpha=255)
    draw_gradient_ellipse(img, (188, 58, 532, 402), "#ffe8d8", skin, "#9b6555")
    draw_soft_ellipse(img, (242, 258, 308, 292), "#f497a8", blur=6, alpha=135)
    draw_soft_ellipse(img, (412, 258, 478, 292), "#f497a8", blur=6, alpha=135)
    draw_gradient_round(img, (236, 386, 484, 652), 88, skin, "#e9947a")
    draw_gradient_round(img, (156, 410, 252, 676), 44, skin, "#e58b72")
    draw_gradient_round(img, (468, 410, 564, 676), 44, skin, "#e58b72")
    draw_gradient_round(img, (260, 612, 352, 900), 38, skin, "#e28670")
    draw_gradient_round(img, (368, 612, 460, 900), 38, skin, "#e28670")
    draw_gradient_ellipse(img, (218, 872, 366, 936), skin, "#dc826d", "#8f564f")
    draw_gradient_ellipse(img, (354, 872, 502, 936), skin, "#dc826d", "#8f564f")
    if gender == "boy":
        draw_soft_round(img, (304, 332, 416, 410), 28, skin)
    save(img, path)


def hair_shape(img: Image.Image, base: str, shade: str, glow: str, variant: str) -> None:
    d = ImageDraw.Draw(img)
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse((120 * SCALE, 35 * SCALE, 600 * SCALE, 760 * SCALE), fill=rgba("#2c1620", 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(8 * SCALE))
    img.alpha_composite(shadow)
    draw_gradient_ellipse(img, (142, 22, 578, 410), glow, base, "#4f2b34")

    if variant in {"long_brown", "long_blonde", "long_lavender", "soft_white"}:
        left = curve_points(188, 462, 125, 330, 2.56, 1.20, 18)
        right = curve_points(532, 462, 125, 330, 1.94, 0.58, 18)
        d.polygon(
            [
                (206 * SCALE, 168 * SCALE),
                *left,
                (238 * SCALE, 792 * SCALE),
                (254 * SCALE, 316 * SCALE),
            ],
            fill=rgba(base),
        )
        d.polygon(
            [
                (514 * SCALE, 168 * SCALE),
                *right,
                (482 * SCALE, 792 * SCALE),
                (466 * SCALE, 316 * SCALE),
            ],
            fill=rgba(base),
        )
        for offset in (0, 26, 52, 78):
            color = rgba(glow, 95 - offset // 2)
            d.arc((170 * SCALE, (120 + offset) * SCALE, 520 * SCALE, (660 + offset) * SCALE), 198, 286, fill=color, width=6 * SCALE)
            d.arc((210 * SCALE, (150 + offset) * SCALE, 594 * SCALE, (710 + offset) * SCALE), 250, 338, fill=color, width=6 * SCALE)
    elif variant in {"bob_black", "short_brown"}:
        draw_gradient_round(img, (150, 150, 570, 470), 92, glow, base)
    elif variant in {"twintails_pink", "twintails_aqua"}:
        draw_gradient_ellipse(img, (58, 258, 264, 622), glow, base, "#4f2b34")
        draw_gradient_ellipse(img, (456, 258, 662, 622), glow, base, "#4f2b34")

    face_cutout = Image.new("L", img.size, 0)
    ImageDraw.Draw(face_cutout).ellipse(
        (204 * SCALE, 138 * SCALE, 516 * SCALE, 410 * SCALE),
        fill=255,
    )
    face_cutout = face_cutout.filter(ImageFilter.GaussianBlur(2 * SCALE))
    alpha = img.getchannel("A")
    alpha.paste(0, mask=face_cutout)
    img.putalpha(alpha)

    strand_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(strand_layer)
    bang_curves = [
        [(214, 146), (264, 98), (320, 92), (348, 168)],
        [(308, 94), (348, 70), (388, 96), (382, 178)],
        [(396, 104), (448, 118), (496, 154), (474, 192)],
        [(232, 196), (310, 214), (406, 212), (490, 192)],
    ]
    for points in bang_curves:
        scaled = [(x * SCALE, y * SCALE) for x, y in points]
        sd.line(scaled, fill=rgba(shade, 185), width=13 * SCALE, joint="curve")
        sd.line(scaled, fill=rgba(glow, 135), width=5 * SCALE, joint="curve")
    strand_layer = strand_layer.filter(ImageFilter.GaussianBlur(0.35 * SCALE))
    img.alpha_composite(strand_layer)
    for x, y, w, h, a1, a2 in [
        (205, 80, 235, 190, 190, 255),
        (286, 74, 205, 205, 210, 286),
        (384, 98, 155, 190, 230, 314),
    ]:
        d.arc(
            (x * SCALE, y * SCALE, (x + w) * SCALE, (y + h) * SCALE),
            a1,
            a2,
            fill=rgba("#ffffff", 115),
            width=5 * SCALE,
        )

    if variant == "aqua_headset":
        d.arc((190 * SCALE, 25 * SCALE, 530 * SCALE, 235 * SCALE), 190, 350, fill=rgba("#2c3444"), width=17 * SCALE)
        for x in (126, 520):
            d.rounded_rectangle((x * SCALE, 200 * SCALE, (x + 82) * SCALE, 334 * SCALE), radius=28 * SCALE, fill=rgba("#2c3444"))
            d.rounded_rectangle(((x + 18) * SCALE, 222 * SCALE, (x + 58) * SCALE, 308 * SCALE), radius=18 * SCALE, fill=rgba("#ffc0d0"))

    if variant == "long_brown":
        d.ellipse((438 * SCALE, 104 * SCALE, 536 * SCALE, 174 * SCALE), fill=rgba("#f3a4bd"))
        d.ellipse((520 * SCALE, 104 * SCALE, 618 * SCALE, 174 * SCALE), fill=rgba("#f3a4bd"))
        d.ellipse((506 * SCALE, 124 * SCALE, 548 * SCALE, 166 * SCALE), fill=rgba("#e1749c"))
        d.polygon([(530 * SCALE, 160 * SCALE), (574 * SCALE, 245 * SCALE), (528 * SCALE, 224 * SCALE)], fill=rgba("#e990b2"))


def draw_hair(path: Path, base: str, shade: str, glow: str, variant: str) -> None:
    img = canvas()
    hair_shape(img, base, shade, glow, variant)
    save(img, path)


def draw_face(path: Path, eye: str, mouth: str) -> None:
    img = canvas()
    d = ImageDraw.Draw(img)
    for x in (246, 394):
        draw_gradient_ellipse(img, (x, 176, x + 98, 282), "#ffffff", "#fff2ec", "#4a2a2a")
        draw_gradient_ellipse(img, (x + 18, 190, x + 82, 268), "#7a3c20", eye, "#31120d")
        draw_soft_ellipse(img, (x + 30, 208, x + 70, 260), "#160806", alpha=250)
        draw_soft_ellipse(img, (x + 30, 196, x + 48, 214), "#ffffff", blur=1)
        draw_soft_ellipse(img, (x + 56, 230, x + 68, 242), "#ffffff", blur=1, alpha=190)
        d.arc((x * SCALE, 164 * SCALE, (x + 102) * SCALE, 214 * SCALE), 190, 346, fill=rgba("#2c1717"), width=5 * SCALE)
    draw_soft_ellipse(img, (226, 278, 302, 318), "#f38ca3", blur=8, alpha=135)
    draw_soft_ellipse(img, (418, 278, 494, 318), "#f38ca3", blur=8, alpha=135)
    draw_soft_ellipse(img, (342, 270, 378, 304), "#f09886", blur=4, alpha=145)
    if mouth == "open":
        draw_gradient_ellipse(img, (336, 326, 386, 372), "#b8454f", "#7a2532", None)
        draw_soft_ellipse(img, (346, 348, 376, 366), "#ffc0c8", blur=1)
    elif mouth == "shy":
        d.arc((330 * SCALE, 322 * SCALE, 392 * SCALE, 358 * SCALE), 24, 154, fill=rgba("#9b4c45"), width=4 * SCALE)
    else:
        d.arc((322 * SCALE, 318 * SCALE, 400 * SCALE, 366 * SCALE), 18, 162, fill=rgba("#9b4c45"), width=5 * SCALE)
    save(img, path)


def draw_dress(path: Path, top: str, skirt: str, accent: str) -> None:
    img = canvas()
    d = ImageDraw.Draw(img)
    draw_gradient_round(img, (236, 374, 484, 542), 58, "#fff5f6", top)
    skirt_points = [(248, 514), (472, 514), (616, 828), (104, 828)]
    d.polygon([(x * SCALE, y * SCALE) for x, y in skirt_points], fill=rgba(skirt))
    for i, x in enumerate((178, 260, 360, 460, 542)):
        d.line((360 * SCALE, 520 * SCALE, x * SCALE, 816 * SCALE), fill=rgba("#ffffff", 120), width=5 * SCALE)
    d.arc((148 * SCALE, 744 * SCALE, 572 * SCALE, 858 * SCALE), 0, 180, fill=rgba(accent, 220), width=14 * SCALE)
    draw_soft_ellipse(img, (328, 410, 392, 474), accent, blur=2)
    save(img, path)


def draw_shirt(path: Path, top: str, bottom: str, motif: str = "none") -> None:
    img = canvas()
    d = ImageDraw.Draw(img)
    draw_gradient_round(img, (218, 378, 502, 590), 72, top, bottom)
    draw_gradient_round(img, (130, 400, 252, 566), 50, top, bottom)
    draw_gradient_round(img, (468, 400, 590, 566), 50, top, bottom)
    if motif == "collar":
        d.polygon([(282 * SCALE, 384 * SCALE), (438 * SCALE, 384 * SCALE), (394 * SCALE, 478 * SCALE), (326 * SCALE, 478 * SCALE)], fill=rgba("#fffaf4"))
        d.polygon([(342 * SCALE, 454 * SCALE), (378 * SCALE, 454 * SCALE), (396 * SCALE, 570 * SCALE), (324 * SCALE, 570 * SCALE)], fill=rgba("#d989a6"))
    elif motif == "book":
        d.rounded_rectangle((302 * SCALE, 430 * SCALE, 420 * SCALE, 520 * SCALE), radius=10 * SCALE, fill=rgba("#a86db7"))
        d.line((360 * SCALE, 430 * SCALE, 360 * SCALE, 520 * SCALE), fill=rgba("#fff1df"), width=4 * SCALE)
    elif motif == "star":
        star = [(360, 412), (378, 448), (418, 452), (388, 478), (398, 518), (360, 496), (322, 518), (332, 478), (302, 452), (342, 448)]
        d.polygon([(x * SCALE, y * SCALE) for x, y in star], fill=rgba("#fff8cc"))
    save(img, path)


def draw_pants(path: Path, color: str, skirt: bool = False) -> None:
    img = canvas()
    d = ImageDraw.Draw(img)
    if skirt:
        d.polygon([(226 * SCALE, 540 * SCALE), (494 * SCALE, 540 * SCALE), (548 * SCALE, 696 * SCALE), (172 * SCALE, 696 * SCALE)], fill=rgba(color))
        d.arc((186 * SCALE, 642 * SCALE, 534 * SCALE, 730 * SCALE), 0, 180, fill=rgba("#ffffff", 120), width=5 * SCALE)
    else:
        draw_gradient_round(img, (250, 548, 352, 888), 40, color, "#6f89b2")
        draw_gradient_round(img, (368, 548, 470, 888), 40, color, "#6f89b2")
        draw_soft_round(img, (236, 520, 484, 598), 28, color)
    save(img, path)


def draw_shoes(path: Path, color: str, boots: bool = False) -> None:
    img = canvas()
    if boots:
        draw_gradient_round(img, (244, 790, 342, 902), 26, color, "#b18a8d")
        draw_gradient_round(img, (378, 790, 476, 902), 26, color, "#b18a8d")
    draw_gradient_ellipse(img, (204, 870, 370, 942), "#ffffff", color, "#756566")
    draw_gradient_ellipse(img, (350, 870, 516, 942), "#ffffff", color, "#756566")
    save(img, path)


def draw_accessory(path: Path, kind: str) -> None:
    img = canvas()
    d = ImageDraw.Draw(img)
    if kind == "bow":
        d.ellipse((438 * SCALE, 104 * SCALE, 536 * SCALE, 174 * SCALE), fill=rgba("#f3a4bd"))
        d.ellipse((520 * SCALE, 104 * SCALE, 618 * SCALE, 174 * SCALE), fill=rgba("#f3a4bd"))
        d.ellipse((506 * SCALE, 124 * SCALE, 548 * SCALE, 166 * SCALE), fill=rgba("#df6f99"))
        d.polygon([(530 * SCALE, 160 * SCALE), (574 * SCALE, 245 * SCALE), (528 * SCALE, 224 * SCALE)], fill=rgba("#e990b2"))
    elif kind == "glasses":
        d.ellipse((246 * SCALE, 198 * SCALE, 342 * SCALE, 270 * SCALE), outline=rgba("#6b536d"), width=8 * SCALE)
        d.ellipse((378 * SCALE, 198 * SCALE, 474 * SCALE, 270 * SCALE), outline=rgba("#6b536d"), width=8 * SCALE)
        d.line((342 * SCALE, 232 * SCALE, 378 * SCALE, 232 * SCALE), fill=rgba("#6b536d"), width=6 * SCALE)
    elif kind == "book":
        d.rounded_rectangle((230 * SCALE, 632 * SCALE, 496 * SCALE, 806 * SCALE), radius=18 * SCALE, fill=rgba("#a260ad"))
        d.polygon([(360 * SCALE, 632 * SCALE), (504 * SCALE, 598 * SCALE), (514 * SCALE, 770 * SCALE), (360 * SCALE, 806 * SCALE)], fill=rgba("#f7ecd6"))
        d.line((360 * SCALE, 632 * SCALE, 360 * SCALE, 806 * SCALE), fill=rgba("#7c456f"), width=5 * SCALE)
    elif kind == "earrings":
        for x in (218, 486):
            draw_soft_ellipse(img, (x, 300, x + 32, 332), "#fff0dc", blur=1)
            draw_soft_ellipse(img, (x + 2, 338, x + 34, 374), "#b589ff", blur=1)
    elif kind == "hat":
        draw_gradient_ellipse(img, (188, 52, 532, 170), "#ffd5e4", "#ee8ab0", "#8b5b70")
        draw_soft_ellipse(img, (288, 38, 410, 100), "#fff0f7", blur=3)
    elif kind == "crown":
        pts = [(238, 116), (292, 196), (360, 94), (428, 196), (482, 116), (468, 222), (252, 222)]
        d.polygon([(x * SCALE, y * SCALE) for x, y in pts], fill=rgba("#ffd96a"))
    elif kind == "bag":
        d.arc((436 * SCALE, 506 * SCALE, 584 * SCALE, 676 * SCALE), 190, 350, fill=rgba("#c66a8d"), width=8 * SCALE)
        d.rounded_rectangle((448 * SCALE, 610 * SCALE, 594 * SCALE, 768 * SCALE), radius=28 * SCALE, fill=rgba("#e98caf"))
        draw_soft_ellipse(img, (500, 662, 540, 702), "#fff0f5", blur=1)
    elif kind == "headphones":
        d.arc((190 * SCALE, 25 * SCALE, 530 * SCALE, 235 * SCALE), 190, 350, fill=rgba("#6d5e75"), width=18 * SCALE)
        for x in (126, 520):
            d.rounded_rectangle((x * SCALE, 200 * SCALE, (x + 82) * SCALE, 334 * SCALE), radius=28 * SCALE, fill=rgba("#6d5e75"))
            d.rounded_rectangle(((x + 18) * SCALE, 222 * SCALE, (x + 58) * SCALE, 308 * SCALE), radius=18 * SCALE, fill=rgba("#a9d8ff"))
    elif kind == "hood":
        draw_gradient_ellipse(img, (132, 64, 588, 500), "#e7b2c6", "#8c6f83", "#715566")
        draw_gradient_ellipse(img, (186, 112, 534, 440), "#f2d2df", "#c18ca3", None)
    elif kind == "splash":
        for box in [(510, 438, 556, 484), (560, 490, 590, 520), (492, 524, 520, 552)]:
            draw_soft_ellipse(img, box, "#ffc06e", blur=1)
    elif kind == "mask":
        draw_soft_round(img, (244, 190, 476, 270), 38, "#ffdce9")
        draw_soft_ellipse(img, (294, 216, 328, 236), "#ffffff")
        draw_soft_ellipse(img, (394, 216, 428, 236), "#ffffff")
    elif kind == "necklace":
        d.arc((296 * SCALE, 332 * SCALE, 424 * SCALE, 422 * SCALE), 12, 168, fill=rgba("#fff4d2"), width=8 * SCALE)
        draw_soft_ellipse(img, (342, 390, 378, 426), "#d496ff", blur=1)
    save(img, path)


def main() -> None:
    skins = {
        "light": "#ffd8c4",
        "peach": "#f3b994",
        "honey": "#c98964",
        "deep": "#91604b",
        "warm": "#d99a6c",
    }
    for name, skin in skins.items():
        draw_body(ASSETS / "body" / f"body_girl_{name}.png", skin, "girl")
        draw_body(ASSETS / "body" / f"body_boy_{name}.png", skin, "boy")

    hair_specs = {
        "hair_long_blonde": ("#5a3934", "#2f1d20", "#c8aaa4", "long_brown"),
        "hair_bob_black": ("#3b303b", "#1c151d", "#a296a8", "bob_black"),
        "hair_short_brown": ("#8b5b43", "#4a2b23", "#d5a184", "short_brown"),
        "hair_twintails_pink": ("#e57ea8", "#7f3b5e", "#ffd0de", "twintails_pink"),
        "hair_long_lavender": ("#a18ce0", "#6b5a9c", "#e7dcff", "long_lavender"),
        "hair_twintails_aqua": ("#77d5dc", "#2b7e8f", "#d8ffff", "twintails_aqua"),
        "hair_urban_pink_hood": ("#7b4957", "#3a222a", "#e5b9c4", "long_brown"),
        "hair_messy_orange": ("#e87945", "#873923", "#ffd18c", "short_brown"),
        "hair_soft_white": ("#eadbd8", "#9b8584", "#ffffff", "soft_white"),
        "hair_aqua_headset": ("#77d5dc", "#2b7e8f", "#d8ffff", "aqua_headset"),
    }
    for name, spec in hair_specs.items():
        draw_hair(ASSETS / "hair" / f"{name}.png", *spec)

    face_specs = {
        "face_smile": ("#5b2b19", "smile"),
        "face_cute": ("#6a351e", "open"),
        "face_shy": ("#6e3d2b", "shy"),
        "face_wink": ("#5b2b19", "smile"),
        "face_modern_calm": ("#6a351e", "smile"),
        "face_modern_soft": ("#7a3c28", "open"),
    }
    for name, spec in face_specs.items():
        draw_face(ASSETS / "face" / f"{name}.png", *spec)

    dresses = {
        "dress_pink": ("#ffd3e0", "#ef8caf", "#fff0f4"),
        "dress_blue": ("#d6ecff", "#8dbce9", "#fff7dc"),
        "dress_princess_mint": ("#daf7ec", "#8bd9bf", "#fff3d0"),
        "dress_shoujo_lavender": ("#eadfff", "#b9a1e7", "#ffe1ef"),
    }
    for name, spec in dresses.items():
        draw_dress(ASSETS / "clothes" / "dresses" / f"{name}.png", *spec)

    shirts = {
        "shirt_star": ("#fff0a0", "#f2b966", "star"),
        "shirt_lilac": ("#eadfff", "#b7a2e6", "book"),
        "shirt_sailor_school": ("#fffdf7", "#dbe9ff", "collar"),
        "shirt_pajama_cloud": ("#d7f3ff", "#8fd5ee", "book"),
        "hoodie_blue_pink": ("#cfeaff", "#78b9de", "book"),
        "hoodie_orange_teal": ("#ffc093", "#e98754", "collar"),
        "top_modern_black": ("#786679", "#342c3b", "none"),
    }
    for name, spec in shirts.items():
        draw_shirt(ASSETS / "clothes" / "shirts" / f"{name}.png", *spec)

    pants = {
        "pants_denim": ("#8fa9cf", False),
        "pants_mint": ("#96dec6", False),
        "skirt_school_navy": ("#4b5c8c", True),
        "shorts_pajama_pink": ("#f2a8c0", True),
    }
    for name, (color, is_skirt) in pants.items():
        draw_pants(ASSETS / "clothes" / "pants" / f"{name}.png", color, is_skirt)

    shoes = {
        "shoes_red": ("#e68ba4", False),
        "shoes_white": ("#f8f6ef", False),
        "boots_lavender": ("#b5a2df", True),
        "mary_janes_black": ("#443c45", False),
    }
    for name, (color, boots) in shoes.items():
        draw_shoes(ASSETS / "clothes" / "shoes" / f"{name}.png", color, boots)

    accessories = {
        "bow_red": "bow",
        "glasses_round": "glasses",
        "hat_beret_pink": "hat",
        "bag_heart_pink": "bag",
        "necklace_pearl": "necklace",
        "crown_gold": "crown",
        "earrings_star": "earrings",
        "sleep_mask_bunny": "mask",
        "headphones_blue": "headphones",
        "hood_blue": "hood",
        "paint_splash_orange": "splash",
    }
    for name, kind in accessories.items():
        draw_accessory(ASSETS / "clothes" / "accessories" / f"{name}.png", kind)


if __name__ == "__main__":
    main()
