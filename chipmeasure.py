# -*- coding: utf-8 -*-
"""Find coral chip bbox in region, both states."""
from PIL import Image

def chip_bbox(path, label):
    img = Image.open(path).convert("RGB")
    w, h = img.size
    xs, ys = [], []
    for y in range(150, 500):
        for x in range(0, 400):
            r, g, b = img.getpixel((x, y))
            if abs(r - 0xF2) < 20 and abs(g - 0x70) < 20 and abs(b - 0x5B) < 20:
                xs.append(x)
                ys.append(y)
    if xs:
        print(f"{label}: bbox x {min(xs)}-{max(xs)} y {min(ys)}-{max(ys)}  "
              f"h={max(ys)-min(ys)+1}px css={(max(ys)-min(ys)+1)/2:.1f} "
              f"w={max(xs)-min(xs)+1}px css={(max(xs)-min(xs)+1)/2:.1f}")
    else:
        print(label, "no coral")

chip_bbox(r"C:\Users\o\shiwuji_build\.workbuddy\verify\2026-09-17\r9_collapsed.png", "collapsed")
chip_bbox(r"C:\Users\o\shiwuji_build\.workbuddy\verify\2026-09-17\r9_expanded.png", "expanded")
