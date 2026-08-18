#!/usr/bin/env python3
"""Rebuild iOS AppIcon PNGs from the existing in-app Q mark.

Source: assets/images/welcome_q_glow.png
Does not invent a new logo. Does not rewrite Contents.json.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    raise SystemExit("Pillow is required: pip install pillow") from exc

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "images" / "welcome_q_glow.png"
ICONSET = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
CONTENTS = ICONSET / "Contents.json"

# Content box as a fraction of the icon edge. Leaves ~12% padding per side so
# the Q stays inside the iOS rounded-rect mask and still reads at 20pt.
CONTENT_FRACTION = 0.76
MASTER_SIZE = 1024
ALPHA_CONTENT_THRESHOLD = 8


def _pixel_size(size: str, scale: str) -> int:
    edge = float(size.split("x", 1)[0])
    factor = int(scale.rstrip("x"))
    return int(round(edge * factor))


def _content_bbox(rgba: Image.Image) -> tuple[int, int, int, int]:
    alpha = rgba.getchannel("A")
    mask = alpha.point(lambda a: 255 if a > ALPHA_CONTENT_THRESHOLD else 0)
    bbox = mask.getbbox()
    if bbox is None:
        raise SystemExit(f"No visible pixels in {SOURCE}")
    return bbox


def _optical_center(rgba: Image.Image, bbox: tuple[int, int, int, int]) -> tuple[float, float]:
    """Center of the Q's circular bowl, ignoring the tail that extends right.

    Bounding-box centering leaves the bowl left of the icon because the tail
    inflates the right edge. The inner counter of the Q is the visual center.
    """
    left, top, right, bottom = bbox
    alpha = rgba.getchannel("A")
    height = bottom - top
    xs: list[float] = []
    ys: list[float] = []
    for row in range(top + int(height * 0.32), top + int(height * 0.58)):
        solids = [
            x
            for x in range(left, right)
            if alpha.getpixel((x, row)) > ALPHA_CONTENT_THRESHOLD
        ]
        if len(solids) < 8:
            continue
        gap_start = None
        best = (0, 0, 0)  # length, start, end
        for x in range(solids[0], solids[-1] + 1):
            empty = alpha.getpixel((x, row)) <= ALPHA_CONTENT_THRESHOLD
            if empty and gap_start is None:
                gap_start = x
            elif not empty and gap_start is not None:
                length = x - gap_start
                if length > best[0]:
                    best = (length, gap_start, x - 1)
                gap_start = None
        if best[0] >= 24:
            xs.append((best[1] + best[2]) / 2)
            ys.append(float(row))
    if not xs:
        return ((left + right - 1) / 2, (top + bottom - 1) / 2)
    return (sum(xs) / len(xs), sum(ys) / len(ys))


def build_master() -> Image.Image:
    src = Image.open(SOURCE).convert("RGBA")
    black = Image.new("RGBA", src.size, (0, 0, 0, 255))
    flattened = Image.alpha_composite(black, src).convert("RGB")

    left, top, right, bottom = _content_bbox(src)
    ox, _oy = _optical_center(src, (left, top, right, bottom))
    cropped = flattened.crop((left, top, right, bottom))

    canvas = Image.new("RGB", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0))
    box = int(round(MASTER_SIZE * CONTENT_FRACTION))
    fitted = cropped.copy()
    fitted.thumbnail((box, box), Image.Resampling.LANCZOS)
    scale = fitted.width / cropped.width
    # Horizontal: center the Q bowl. Vertical: keep the glyph block centered.
    origin_x = int(round(MASTER_SIZE / 2 - (ox - left) * scale))
    origin_y = int(round((MASTER_SIZE - fitted.height) / 2))
    canvas.paste(fitted, (origin_x, origin_y))
    return canvas


def iter_targets() -> dict[str, int]:
    payload = json.loads(CONTENTS.read_text())
    targets: dict[str, int] = {}
    for entry in payload["images"]:
        filename = entry["filename"]
        pixels = _pixel_size(entry["size"], entry["scale"])
        if filename in targets and targets[filename] != pixels:
            raise SystemExit(
                f"Conflicting pixel size for {filename}: "
                f"{targets[filename]} vs {pixels}"
            )
        targets[filename] = pixels
    return targets


def main() -> int:
    if not SOURCE.is_file():
        raise SystemExit(f"Missing source asset: {SOURCE}")
    master = build_master()
    written = 0
    for filename, pixels in sorted(iter_targets().items(), key=lambda item: item[1]):
        out = ICONSET / filename
        if pixels == MASTER_SIZE:
            image = master
        else:
            image = master.resize((pixels, pixels), Image.Resampling.LANCZOS)
        rgb = image.convert("RGB")
        rgb.save(out, format="PNG", optimize=True)
        written += 1
        print(f"wrote {filename} {pixels}x{pixels} RGB")
    print(f"updated {written} AppIcon PNGs from {SOURCE.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
