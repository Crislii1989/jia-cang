# -*- coding: utf-8 -*-
"""Orphan-file scanner: lib/**.dart (non-generated) never imported by lib or test."""
import os, re

# 仓库根 = 本脚本所在目录的上一级（别写死绝对路径：目录改名/换机器就失效）
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

files = []
for dirpath, dirnames, filenames in os.walk(os.path.join(ROOT, "lib")):
    for fn in filenames:
        if fn.endswith(".dart") and not fn.endswith(".g.dart") and not fn.endswith(".freezed.dart"):
            rel = os.path.relpath(os.path.join(dirpath, fn), ROOT).replace("\\", "/")
            files.append(rel)

bodies = {}
for base in ("lib", "test"):
    for dirpath, _, filenames in os.walk(os.path.join(ROOT, base)):
        for fn in filenames:
            if fn.endswith(".dart"):
                p = os.path.join(dirpath, fn)
                rel = os.path.relpath(p, ROOT).replace("\\", "/")
                with open(p, encoding="utf-8") as fh:
                    bodies[rel] = fh.read()

# 包名从 pubspec.yaml 读，避免包名一改这里就静默失效（踩过这个坑）
_PKG = re.search(
    r"^name:\s*(\S+)",
    open(os.path.join(ROOT, "pubspec.yaml"), encoding="utf-8").read(),
    re.M,
).group(1)

# import specifier -> lib-relative path mapping
def spec_to_rel(spec):
    # package:<包名>/xxx -> lib/xxx ; relative imports: resolve crudely
    prefix = f"package:{_PKG}/"
    if spec.startswith(prefix):
        return "lib/" + spec[len(prefix):]
    return None  # skip relative import resolution (rare here)

orphans = []
for target in files:
    base = os.path.basename(target)
    imported = False
    for rel, body in bodies.items():
        if rel == target:
            continue
        for m in re.finditer(r"import\s+'([^']+)';|export\s+'([^']+)';", body):
            spec = m.group(1) or m.group(2)
            t = spec_to_rel(spec)
            if t == target:
                imported = True
                break
            # relative import: match by basename heuristics
            if t is None and spec.endswith(base):
                imported = True
                break
        if imported:
            break
    if not imported:
        orphans.append(target)

for o in orphans:
    print(o)
print(len(orphans), "orphan files (never imported)")
