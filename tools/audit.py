#!/usr/bin/env python3
"""Norcha pre-push audit. The gate before every push.

Checks, in order of how often they have actually bitten:
  1. doubled/mangled substitutions from a bad regex (body(c)Small(c))
  2. stale tokens pointing at classes or files that no longer exist
  3. every symbol USED is imported from where it is DEFINED
  4. `c.` used in a scope that never resolves it (widget classes AND plain methods)
  5. delimiter balance + unterminated strings, comments stripped first
"""
import os, re, sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
LIB = os.path.join(ROOT, "lib")
problems = []

dart_files = []
for dp, _, fs in os.walk(LIB):
    for f in fs:
        if f.endswith(".dart"):
            dart_files.append(os.path.join(dp, f))

# ---- 1. mangled substitutions -------------------------------------------------
MANGLED = ["body(c)Small", "title(c)Small", "display(c)Small",
           "sectionLabel(c)Small", "(c)(c)", "Small(c)Small"]
for p in dart_files:
    s = open(p).read()
    for m in MANGLED:
        if m in s:
            problems.append(f"{p}: mangled substitution '{m}'")

# ---- 2. stale tokens ----------------------------------------------------------
STALE = ["NorchaPalette.", "NorchaShape.", "NorchaMotion.", "netela.dart",
         "norcha_theme.dart", "motion_budget.dart", "gold_button", "gold_sheet",
         "Radius.sm", "Radius.md", "Radius.lg", "Radius.pill", "Radius.xs"]
for p in dart_files:
    s = open(p).read()
    for t in STALE:
        if t in s:
            problems.append(f"{p}: stale token '{t}'")

# ---- symbol index -------------------------------------------------------------
# symbol -> SET of files defining it. A name can be legitimately defined more
# than once (Bi exists in both core/pricing.dart and services/norcha_api.dart);
# last-write-wins would demand an import of the wrong one and report a
# non-existent problem. Any defining file satisfies the requirement.
symbols = {}
for p in dart_files:
    s = open(p).read()
    for m in re.finditer(r'^(?:class|enum|mixin|abstract class)\s+(\w+)', s, flags=re.M):
        symbols.setdefault(m.group(1), set()).add(os.path.normpath(p))

def strip_comments(src):
    out = []
    for ln in src.split("\n"):
        res = ""; i = 0; ins = False; q = None
        while i < len(ln):
            ch = ln[i]
            if ins:
                res += ch
                if ch == '\\':
                    if i + 1 < len(ln): res += ln[i + 1]; i += 2; continue
                elif ch == q: ins = False
            else:
                if ch in "'\"": ins = True; q = ch; res += ch
                elif ch == '/' and i + 1 < len(ln) and ln[i + 1] == '/': break
                else: res += ch
            i += 1
        out.append(res)
    return "\n".join(out)

# ---- 3 & 4 per file -----------------------------------------------------------
for p in dart_files:
    raw = open(p).read()
    lines = raw.split("\n")
    imps = []; body_start = 0
    for i, l in enumerate(lines):
        if l.startswith("import "):
            imps.append(l); body_start = i + 1
        elif l.startswith("//"):
            body_start = i + 1
    body = "\n".join(lines[body_start:])

    resolved = set()
    for l in imps:
        m = re.search(r"'([^']+)'", l)
        if not m: continue
        imp = m.group(1)
        if imp.startswith("package:"):
            resolved.add(os.path.normpath(os.path.join(ROOT, imp.replace("package:norcha_print/", "lib/"))))
        else:
            resolved.add(os.path.normpath(os.path.join(os.path.dirname(p), imp)))

    declared = {m.group(1) for m in re.finditer(r'^(?:class|enum|mixin|abstract class)\s+(\w+)', raw, flags=re.M)}
    for sym, defps in symbols.items():
        if sym in declared or os.path.normpath(p) in defps: continue
        if re.search(r'\b' + re.escape(sym) + r'\b', body):
            # satisfied if ANY defining file is imported
            if not any(os.path.normpath(r) in defps for r in resolved):
                where = " or ".join(sorted(os.path.relpath(d, ROOT) for d in defps))
                problems.append(f"{os.path.relpath(p, ROOT)}: uses {sym}, no import of {where}")

    # 4. `c.` in a scope that cannot resolve it
    stripped = strip_comments(raw)
    # widget classes
    for m in re.finditer(r'class\s+(\w+)[^{]*\{', stripped):
        start = m.end() - 1
        depth = 0; i = start
        while i < len(stripped):
            if stripped[i] == '{': depth += 1
            elif stripped[i] == '}':
                depth -= 1
                if depth == 0: break
            i += 1
        block = stripped[start:i]
        # A local `c` of any kind counts as resolved — `final c = code.trim()`
        # is a variable named c, not a missing colour. Only flag when the scope
        # declares no `c` at all.
        declares_c = re.search(r'\b(?:final|var|const|NorchaColors)\s+c\b', block)
        if re.search(r'\bc\.', block) and 'NorchaColors.of(context)' not in block and not declares_c:
            problems.append(f"{os.path.relpath(p, ROOT)}::{m.group(1)}: uses c. without resolving it")

# ---- 5. syntax ---------------------------------------------------------------
for p in dart_files:
    if "audit.py" in p: continue
    src = strip_comments(open(p).read())
    d = {'(': 0, '[': 0, '{': 0}; iss = []; ins = False; q = None; i = 0; ln = 1
    while i < len(src):
        ch = src[i]
        if ch == '\n':
            if ins and q == "'": iss.append(ln)
            ins = False; ln += 1
        elif ins:
            if ch == '\\': i += 2; continue
            if ch == q: ins = False
        else:
            if ch in "'\"": ins = True; q = ch
            elif ch in d: d[ch] += 1
            elif ch in ')]}': d[{')': '(', ']': '[', '}': '{'}[ch]] -= 1
        i += 1
    if not all(v == 0 for v in d.values()) or iss:
        problems.append(f"{os.path.relpath(p, ROOT)}: unbalanced {d} strings={iss[:3]}")

uniq = []
for x in problems:
    if x not in uniq: uniq.append(x)

if uniq:
    print(f"=== {len(uniq)} PROBLEMS ===")
    for x in uniq: print(" ", x)
    sys.exit(1)
print("=== ALL GATES PASS ===")
