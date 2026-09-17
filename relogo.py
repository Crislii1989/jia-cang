# -*- coding: utf-8 -*-
"""Replace app logo: user-provided JPG -> assets/icon/jia_cang_icon_1024.png (+ web icons)."""
from PIL import Image

SRC = r"C:\Users\o\WorkBuddy\2026-09-17-14-13-03\tidy-logo_assets\5ff021c5-miora_text_to_image-1789626065990-0-b48f48be7e20.jpg"
ICON = r"D:\工作文件\敲代码\家中有数\shiwuji\assets\icon\jia_cang_icon_1024.png"
WEB = r"D:\工作文件\敲代码\家中有数\shiwuji\web"

img = Image.open(SRC).convert("RGB")
print("src size:", img.size)
# 方形裁到中心 1:1
w, h = img.size
side = min(w, h)
img = img.crop(((w - side) // 2, (h - side) // 2, (w + side) // 2, (h + side) // 2))

img.save(ICON, "PNG")
print("saved", ICON, img.size)

for name, size in [("icons/Icon-192.png", 192), ("icons/Icon-512.png", 512), ("favicon.png", 32)]:
    out = f"{WEB}\\{name}"
    img.resize((size, size), Image.LANCZOS).save(out, "PNG")
    print("saved", out)
