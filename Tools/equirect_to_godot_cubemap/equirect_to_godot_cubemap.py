#!/usr/bin/env python3
"""
Convert an equirectangular panorama PNG to a Godot-importable cubemap PNG.

Godot expects faces in order: X+, X-, Y+, Y-, Z+, Z- (Y+ up, Z- forward).
Slice layout matches ResourceImporterLayeredTexture (row-major, top to bottom):

  2x3 (default):     1x6:          3x2:           6x1:
  +----+----+        +X+            +X+ +X- +Y+    +X+ +X- +Y+ +Y- +Z+ +Z-
  | X+ | X- |        +X-            +Y- +Z+ +Z-
  +----+----+        +Y+
  | Y+ | Y- |        +Y-
  +----+----+        +Z+
  | Z+ | Z- |        +Z-
  +----+----+

Resampling uses OpenCV INTER_LANCZOS4 (Lanczos interpolation).
"""

from __future__ import annotations

import argparse
from enum import IntEnum

import cv2
import numpy as np


class Layout(IntEnum):
    L1x6 = 0
    L2x3 = 1
    L3x2 = 2
    L6x1 = 3


def _ab_grid(face_w: int) -> tuple[np.ndarray, np.ndarray]:
    jj, ii = np.meshgrid(
        np.arange(face_w, dtype=np.float64) + 0.5,
        np.arange(face_w, dtype=np.float64) + 0.5,
    )
    u = jj / face_w
    v = ii / face_w
    a = 2.0 * u - 1.0
    b = 1.0 - 2.0 * v
    return a, b


def face_to_directions(face_index: int, face_w: int) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    a, b = _ab_grid(face_w)
    if face_index == 0:  # X+
        x, y, z = np.ones_like(a), b, -a
    elif face_index == 1:  # X-
        x, y, z = -np.ones_like(a), b, a
    elif face_index == 2:  # Y+
        x, y, z = a, np.ones_like(a), -b
    elif face_index == 3:  # Y-
        x, y, z = a, -np.ones_like(a), b
    elif face_index == 4:  # Z+
        x, y, z = a, b, np.ones_like(a)
    else:  # Z-
        x, y, z = -a, b, -np.ones_like(a)
    inv_len = 1.0 / np.sqrt(x * x + y * y + z * z)
    return x * inv_len, y * inv_len, z * inv_len


def directions_to_equirect_maps(
    x: np.ndarray,
    y: np.ndarray,
    z: np.ndarray,
    src_w: int,
    src_h: int,
) -> tuple[np.ndarray, np.ndarray]:
    phi = np.arctan2(x, z)
    theta = np.arcsin(np.clip(y, -1.0, 1.0))
    u_er = (phi / (2.0 * np.pi) + 0.5) % 1.0
    v_er = np.clip(0.5 - theta / np.pi, 0.0, 1.0)
    map_x = (u_er * (src_w - 1)).astype(np.float32)
    map_y = (v_er * (src_h - 1)).astype(np.float32)
    return map_x, map_y


def render_face(
    src: np.ndarray,
    face_index: int,
    face_w: int,
) -> np.ndarray:
    h, w = src.shape[:2]
    dx, dy, dz = face_to_directions(face_index, face_w)
    map_x, map_y = directions_to_equirect_maps(dx, dy, dz, w, h)
    return cv2.remap(
        src,
        map_x,
        map_y,
        interpolation=cv2.INTER_LANCZOS4,
        borderMode=cv2.BORDER_REPLICATE,
    )


def stitch(faces: list[np.ndarray], layout: Layout) -> np.ndarray:
    n = len(faces)
    if n != 6:
        raise ValueError("expected 6 cubemap faces")
    s = faces[0].shape[0]
    for f in faces:
        if f.shape[0] != s or f.shape[1] != s:
            raise ValueError("all faces must be square and the same size")

    if layout == Layout.L6x1:
        return np.hstack(faces)
    if layout == Layout.L1x6:
        return np.vstack(faces)
    if layout == Layout.L2x3:
        rows = [np.hstack(faces[i : i + 2]) for i in (0, 2, 4)]
        return np.vstack(rows)
    if layout == Layout.L3x2:
        rows = [np.hstack(faces[i : i + 3]) for i in (0, 3)]
        return np.vstack(rows)
    raise ValueError(f"unknown layout {layout}")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("input", help="equirectangular PNG (2:1 typical)")
    p.add_argument("output", help="output PNG for Godot Cubemap import")
    p.add_argument(
        "--face-size",
        type=int,
        default=0,
        metavar="N",
        help="output square face size in pixels (default: quarter of equirect height)",
    )
    p.add_argument(
        "--layout",
        choices=("1x6", "2x3", "3x2", "6x1"),
        default="2x3",
        help="must match Godot Import → slices/arrangement (default: 2x3)",
    )
    args = p.parse_args()

    layout = Layout({"1x6": Layout.L1x6, "2x3": Layout.L2x3, "3x2": Layout.L3x2, "6x1": Layout.L6x1}[args.layout])

    src = cv2.imread(args.input, cv2.IMREAD_UNCHANGED)
    if src is None:
        raise SystemExit(f"failed to read image: {args.input}")

    eh, ew = src.shape[:2]
    if ew < 2 or eh < 2:
        raise SystemExit("source image is too small")

    face_w = args.face_size if args.face_size > 0 else max(ew // 4, 1)

    faces = [render_face(src, i, face_w) for i in range(6)]
    out = stitch(faces, layout)

    ok = cv2.imwrite(args.output, out)
    if not ok:
        raise SystemExit(f"failed to write: {args.output}")


if __name__ == "__main__":
    main()
