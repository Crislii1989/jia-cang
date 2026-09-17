# -*- coding: utf-8 -*-
"""Replace app logo: user-provided square JPG -> assets/icon/jia_cang_icon_1024.png (+ web icons).

用法（源图是一次性的，所以走命令行参数，不写死在文件里）:
    python tool/relogo.py <方形 logo 原图路径>
"""
import os, sys
from PIL import Image

# 仓库根 = 本脚本所在目录的上一级（别写死绝对路径：目录改名/换机器就失效）
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON = os.path.join(ROOT, "assets", "icon", "jia_cang_icon_1024.png")
WEB = os.path.join(ROOT, "web")

if len(sys.argv) < 2:
    sys.exit("用法: python tool/relogo.py <方形 logo 原图路径>")
SRC = sys.argv[1]

img = Image.open(SRC).convert("RGB")
print("src size:", img.size)
# 方形裁到中心 1:1
w, h = img.size
side = min(w, h)
img = img.crop(((w - side) // 2, (h - side) // 2, (w + side) // 2, (h + side) // 2))

img.save(ICON, "PNG")
print("saved", ICON, img.size)

for name, size in [("icons/Icon-192.png", 192), ("icons/Icon-512.png", 512), ("favicon.png", 32)]:
    out = os.path.join(WEB, name)
    img.resize((size, size), Image.LANCZOS).save(out, "PNG")
    print("saved", out)
