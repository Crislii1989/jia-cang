# -*- coding: utf-8 -*-
"""量截图里珊瑚色胶囊的像素包围盒（用于核对控件尺寸与 CSS 坐标）。

用法（要量的截图是一次性的，走命令行参数，不写死在文件里）:
    python tool/chipmeasure.py <截图1> [<截图2> ...]
"""
import os, sys
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

if len(sys.argv) < 2:
    sys.exit("用法: python tool/chipmeasure.py <截图1> [<截图2> ...]")

for path in sys.argv[1:]:
    chip_bbox(path, os.path.basename(path))
