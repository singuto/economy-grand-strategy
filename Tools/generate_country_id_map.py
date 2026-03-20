#!/usr/bin/env python3
"""Generate a grayscale equirect CountryIdMap.png (R=id/255). id 0 = ocean."""
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    raise SystemExit("pip install Pillow") from None

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Data" / "CountryIdMap.png"
W, H = 512, 256


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img = Image.new("L", (W, H), 0)
    pix = img.load()
    assert pix is not None
    for y in range(H):
        v = (y + 0.5) / H
        for x in range(W):
            u = (x + 0.5) / W
            pid = 0
            if 0.15 < u < 0.42 and 0.28 < v < 0.72:
                pid = 1
            elif 0.48 < u < 0.82 and 0.22 < v < 0.58:
                pid = 2
            elif 0.38 < u < 0.62 and 0.62 < v < 0.92:
                pid = 3
            pix[x, y] = pid
    img.save(OUT, "PNG")
    print("Wrote", OUT)


if __name__ == "__main__":
    main()
