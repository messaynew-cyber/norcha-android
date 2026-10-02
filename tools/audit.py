#!/usr/bin/env python3
"""Norcha pre-push audit - the gate before every push.

Runs in about a second, before the ~90s Flutter toolchain boots. It encodes the
mistakes that have ACTUALLY broken this build, in the order they bit:

  1. mangled regex substitutions (body -> bodySmall matched as a prefix)
  2. stale tokens pointing at classes or files that no longer exist
  3. a symbol used without importing the file that defines it
  4. c used in a scope that never resolves it (widget classes AND methods)
  5. delimiter balance + unterminated strings
  6. duplicate imports
  7. unused LOCAL imports, because flutter analyze --no-fatal-infos still fails
     on warnings, so an unused import is a build failure here

Deliberate limitations, so nobody trusts it further than it deserves:
  - it does not type-check
  - it only judges local imports for "used"; a package symbol is invisible to it
  - it cannot see widget-tree const inference, where the subtlest failure hid

When this audit and the compiler disagree, THE COMPILER IS RIGHT.
"""
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
LIB = os.path.join(ROOT, "lib")
problems = []

dart_files = []
for dp, _, fs in os.walk(LIB):
    for f in fs:
        if f.endswith(".dart"):
            dart_files.append(os.path.join(dp, f))


def strip_comments(src):
    """Blank out // and /* */ comments, respecting string literals."""
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    out = []
    for ln in src.split("\n"):
        res = ""
        i = 0
        ins = False
        q = None
        while i < len(ln):
            ch = ln[i]
            if ins:
                res += ch
                if ch == "\\":
                    if i + 1 < len(ln):
                        res += ln[i + 1]
                        i += 2
                        continue
                elif ch == q:
                    ins = False
            else:
                if ch in "'\"":
                    ins = True
                    q = ch
                    res += ch
                elif ch == "/" and i + 1 < len(ln) and ln[i + 1] == "/":
                    break
                else:
                    res += ch
            i += 1
        out.append(res)
    return "\n".join(out)


def body_of(raw):
    """The part of a file after its import block, comments and strings blanked."""
    lines = raw.split("\n")
    imps = []
    start = 0
    for i, l in enumerate(lines):
        # Tolerate `as y;`, `show A;`, `hide A;` after the path. Missing
        # them ends the import block early, and every local import after
        # an aliased one then looks unused or missing.
        m = re.match(r"^import '([^']+)'(?:\s+as\s+\w+)?(?:\s+(?:show|hide)\s+[^;]+)?\s*;", l)
        st = l.strip()
        if m:
            imps.append((m.group(1), l))
            start = i + 1
        elif st == "" or l.startswith("//") or l.startswith("/*") or l.startswith(" *") or l.startswith("*/"):
            if not imps:
                start = i + 1
        else:
            if imps:
                break
    body = strip_comments("\n".join(lines[start:]))
    # Blank string CONTENTS, but NOT interpolations: `'${Shop.wa}'` is a real
    # reference to the Shop class, while `'Quote'` is just a word that happens
    # to match a class name. Protect the ${...} spans first, blank the rest.
    # Extract interpolations FIRST (from the raw text), THEN blank all string
    # literals, THEN append the extracted expressions as a trailing block of
    # real code. Any placeholder that lives inside a literal gets swallowed by
    # the blanking regex — that is why the earlier attempts kept losing `${Shop}`.
    interps = re.findall(r"\$\{([^}]*)\}", body)
    body = re.sub(r"'[^'\n]*'", "''", body)
    body = re.sub(r'"[^"\n]*"', '""', body)
    # Interpolated expressions are real code and must count as references.
    if interps:
        body += "\n" + "\n".join(interps)
    return imps, body


# ---- 1. mangled substitutions -------------------------------------------------
MANGLED = ["body(c)Small", "title(c)Small", "display(c)Small",
           "sectionLabel(c)Small", "(c)(c)", "Small(c)Small"]
for p in dart_files:
    s = open(p).read()
    for m in MANGLED:
        if m in s:
            problems.append(f"{os.path.relpath(p, ROOT)}: mangled substitution '{m}'")

# ---- 2. stale tokens ----------------------------------------------------------
STALE = ["NorchaPalette.", "NorchaShape.", "NorchaMotion.", "netela.dart",
         "norcha_theme.dart", "motion_budget.dart", "gold_button", "gold_sheet",
         "Radius.sm", "Radius.md", "Radius.lg", "Radius.pill", "Radius.xs"]
for p in dart_files:
    s = open(p).read()
    for t in STALE:
        if t in s:
            problems.append(f"{os.path.relpath(p, ROOT)}: stale token '{t}'")

# ---- symbol index: name -> SET of files defining it ---------------------------
# A name can be legitimately defined more than once (Bi exists in both
# core/pricing.dart and services/norcha_api.dart). Any defining file satisfies.
symbols = {}
for p in dart_files:
    s = open(p).read()
    for m in re.finditer(r"^(?:class|enum|mixin|abstract class)\s+(\w+)", s, flags=re.M):
        symbols.setdefault(m.group(1), set()).add(os.path.normpath(p))

# ---- 3, 4, 6, 7 per file ------------------------------------------------------
for p in dart_files:
    raw = open(p).read()
    imps, body = body_of(raw)
    rel = os.path.relpath(p, ROOT)

    # resolve what each import points at
    resolved = set()
    for imp, _ in imps:
        if imp.startswith("package:"):
            resolved.add(os.path.normpath(os.path.join(
                ROOT, imp.replace("package:norcha_print/", "lib/"))))
        else:
            resolved.add(os.path.normpath(os.path.join(os.path.dirname(p), imp)))

    # 6. duplicate imports
    seen = set()
    for imp, _ in imps:
        if imp in seen:
            problems.append(f"{rel}: duplicate import of {imp}")
        seen.add(imp)

    # 3. every symbol used is imported from where it is defined
    declared = {m.group(1) for m in re.finditer(
        r"^(?:class|enum|mixin|abstract class)\s+(\w+)", raw, flags=re.M)}
    for sym, defps in symbols.items():
        if sym in declared or os.path.normpath(p) in defps:
            continue
        if re.search(r"\b" + re.escape(sym) + r"\b", body):
            if not any(os.path.normpath(r) in defps for r in resolved):
                where = " or ".join(sorted(os.path.relpath(d, ROOT) for d in defps))
                problems.append(f"{rel}: uses {sym}, no import of {where}")

    # 7. unused LOCAL imports (packages are invisible to this index)
    for imp, _ in imps:
        if not imp.startswith("."):
            continue
        target = os.path.normpath(os.path.join(os.path.dirname(p), imp))
        used = False
        for sym, defps in symbols.items():
            if target in defps and re.search(r"\b" + re.escape(sym) + r"\b", body):
                used = True
                break
        if not used:
            problems.append(f"{rel}: unused import '{imp}'")

    # 4. `c` used in a scope that cannot resolve it
    stripped = strip_comments(raw)
    for m in re.finditer(r"class\s+(\w+)[^{]*\{", stripped):
        start = m.end() - 1
        depth = 0
        i = start
        while i < len(stripped):
            if stripped[i] == "{":
                depth += 1
            elif stripped[i] == "}":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        block = stripped[start:i]
        # A local `c` of any kind counts — `final c = code.trim()` is a variable
        # named c, not a missing colour.
        declares_c = re.search(r"\b(?:final|var|const|NorchaColors|NorchaLang)\s+c\b", block)
        if re.search(r"\bc\.", block) and "NorchaColors.of(context)" not in block and not declares_c:
            problems.append(f"{rel}::{m.group(1)}: uses c. without resolving it")

    # 5. delimiter balance + unterminated strings
    src = strip_comments(raw)
    d = {"(": 0, "[": 0, "{": 0}
    iss = []
    ins = False
    q = None
    i = 0
    ln = 1
    while i < len(src):
        ch = src[i]
        if ch == "\n":
            if ins and q == "'":
                iss.append(ln)
            ins = False
            ln += 1
        elif ins:
            if ch == "\\":
                i += 2
                continue
            if ch == q:
                ins = False
        else:
            if ch in "'\"":
                ins = True
                q = ch
            elif ch in d:
                d[ch] += 1
            elif ch in ")]}":
                d[{")": "(", "]": "[", "}": "{"}[ch]] -= 1
        i += 1
    if not all(v == 0 for v in d.values()) or iss:
        problems.append(f"{rel}: unbalanced {d} strings={iss[:3]}")

uniq = []
for x in problems:
    if x not in uniq:
        uniq.append(x)

if uniq:
    print(f"=== {len(uniq)} PROBLEMS ===")
    for x in uniq:
        print(" ", x)
    sys.exit(1)
print("=== ALL GATES PASS ===")
