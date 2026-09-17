# -*- coding: utf-8 -*-
"""Dead-code scanner: extract top-level declarations from lib/**.dart
(non-generated), count references across lib+test, flag zero-reference ones."""
import os, re, json, sys, tempfile

# 仓库根 = 本脚本所在目录的上一级（别写死绝对路径：目录改名/换机器就失效）
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# ⚠️ 输出必须写到系统临时目录，绝不能落在仓库根 ——
# 历史上就是因为把输出指向了一个「指向仓库根的联接目录」，deadcode.json 才被提交进仓库。
OUT = os.path.join(tempfile.gettempdir(), "deadcode.json")

decl_re = re.compile(
    r"^(?:@[\w.]+\s+)*"                      # skip annotations
    r"(?:abstract\s+|sealed\s+|final\s+|base\s+)*"
    r"(class|enum|mixin|extension)\s+([A-Za-z_]\w*)"
    r"|^(?:Future<[^>]*>|void|String|bool|int|double|num|List<[^>]*>|Map<[^>]*>|Widget|Color)\s+([a-z_]\w*)\s*\("
)

files = []
for dirpath, dirnames, filenames in os.walk(os.path.join(ROOT, "lib")):
    for fn in filenames:
        if fn.endswith(".dart") and not fn.endswith(".g.dart") and not fn.endswith(".freezed.dart"):
            files.append(os.path.join(dirpath, fn))

# symbol -> {"file": def file, "kind": class/enum/function, "line": n}
symbols = {}
for f in files:
    rel = os.path.relpath(f, ROOT).replace("\\", "/")
    with open(f, encoding="utf-8") as fh:
        for i, line in enumerate(fh, 1):
            s = line.strip()
            if s.startswith("//") or s.startswith("import") or s.startswith("export") or s.startswith("part "):
                continue
            m = decl_re.match(s)
            if m:
                kind = m.group(1) or "function"
                name = m.group(2) or m.group(3)
                if name and len(name) > 2:
                    symbols.setdefault(name, {"file": rel, "kind": kind, "line": i})

# read all source bodies (lib + test)
bodies = {}
for base in ("lib", "test"):
    for dirpath, _, filenames in os.walk(os.path.join(ROOT, base)):
        for fn in filenames:
            if fn.endswith(".dart"):
                p = os.path.join(dirpath, fn)
                rel = os.path.relpath(p, ROOT).replace("\\", "/")
                with open(p, encoding="utf-8") as fh:
                    bodies[rel] = fh.read()

use_re_cache = {}
results = []
for name, meta in symbols.items():
    # count references outside the defining line: occurrences of the name as a word
    pat = re.compile(r"\b" + re.escape(name) + r"\b")
    total = 0
    refs = []
    for rel, body in bodies.items():
        hits = len(pat.findall(body))
        if rel == meta["file"] and hits <= 1:
            continue  # only the declaration itself
        if hits > 0:
            total += hits
            refs.append(rel)
    if total == 0:
        results.append({"name": name, "kind": meta["kind"], "file": meta["file"], "line": meta["line"]})

results.sort(key=lambda r: (r["file"], r["line"]))
with open(OUT, "w", encoding="utf-8") as fh:
    json.dump(results, fh, ensure_ascii=False, indent=1)
print(len(results), "zero-reference symbols")
for r in results:
    print(f"{r['kind']:9s} {r['name']:40s} {r['file']}:{r['line']}")
