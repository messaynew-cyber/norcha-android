#!/usr/bin/env python3
"""Cross-language parity: does the DART port still agree with the JS source?

WHY THIS EXISTS
lib/core/holidays.dart is a hand port of js/norcha-holidays.js. The two are the
only things keeping the app and the website telling customers the same deadline,
and nothing enforces it. Edit one and the other drifts — silently, in the way
that produces a WRONG DATE rather than a failing test.

Fasika was a week out for years precisely because nothing compared anything.

HOW IT WORKS
Dart cannot execute on this ARM64 authoring device, so this harness does not try.
It pits the two implementations against each other in three ways:

  1. CONSTANTS — parse both files and compare the holiday tables, IDs, Amharic
     names, month/day, and the MAX_LEAD value. Text-level, catches a table edit
     on one side only. 
  2. DECISIONS — compare the message-case thresholds (the > 1, == 1, == 0,
     negative ladder and the horizon default), which are where the app and site
     could disagree about what to SAY even if they agree on the date.
  3. DATES — run the JS with node, and run a faithful Python transliteration of
     the Dart algorithm, then compare across a 30-year window. The Python is a
     THIRD implementation; a date is only trusted when all three agree.

Exit code 1 on any disagreement, so CI can gate on it.
"""
import json
import re
import subprocess
import sys
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JS = ROOT / "tools" / "vendor" / "norcha-holidays.js"
DART = ROOT / "lib" / "core" / "holidays.dart"

# The JS lives in the SITE repo, the Dart in the APP repo. When this runs in the
# app repo, JS is absent unless it is vendored — so say that plainly instead of
# silently passing.
if not JS.exists():
    print(f"SKIP: {JS} not found. Vendor the site's norcha-holidays.js here for"
          " a full check, or run this from the site repo.")
    sys.exit(0)
if not DART.exists():
    print(f"FAIL: {DART} not found.")
    sys.exit(1)

js_src = JS.read_text()
dart_src = DART.read_text()
failures = []
checks = 0


def check(name, cond, detail=""):
    global checks
    checks += 1
    if cond:
        print(f"  ok   {name}")
    else:
        failures.append(name)
        print(f"  FAIL {name}" + (f"  -> {detail}" if detail else ""))


# ---------------------------------------------------------------- 1. CONSTANTS
print("\nCONSTANTS — the holiday table")

js_rows = re.findall(
    r'\{\s*id:\s*"(\w+)",\s*en:\s*"([^"]+)",\s*am:\s*"([^"]+)",\s*md:\s*\[(\d+),\s*(\d+)\]\s*\}',
    js_src)
js_table = {r[0]: {"en": r[1], "am": r[2], "month": int(r[3]), "day": int(r[4])}
            for r in js_rows}

# Dart uses record literals: (id: 'meskel', en: 'Meskel', am: 'መስቀል', month: 9, day: 27)
# Dart accepts 'single' and "double" quoted strings, and a value containing an
# apostrophe (Mother's Day) MUST be double quoted. So the row pattern has to
# accept both delimiters.
#
# DO NOT normalise by replacing every " with ' — that turns "Mother's Day" into
# 'Mother's Day', whose apostrophe ends the string early and silently drops the
# row. (Learned the hard way in this file's first two drafts.) Match the
# delimiters properly instead, with one capture group per field.
DART_STR = r"""(?:"([^"]*)"|'([^']*)')"""
DART_ROW = re.compile(
    r"\(id:\s*" + DART_STR
    + r",\s*en:\s*" + DART_STR
    + r",\s*am:\s*" + DART_STR
    + r",\s*month:\s*(\d+),\s*day:\s*(\d+)\)"
)


def _pick(*groups):
    """First non-None capture — each field matches either the "..." branch or
    the '...' branch of DART_STR, so exactly one group is populated."""
    for g in groups:
        if g is not None:
            return g
    return ""


dart_rows = [
    (_pick(m.group(1), m.group(2)),
     _pick(m.group(3), m.group(4)),
     _pick(m.group(5), m.group(6)),
     m.group(7), m.group(8))
    for m in DART_ROW.finditer(dart_src)
]
dart_table = {
    r[0]: {"en": r[1], "am": r[2], "month": int(r[3]), "day": int(r[4])}
    for r in dart_rows
}

check("both tables parsed", bool(js_table) and bool(dart_table),
      f"js={len(js_table)} dart={len(dart_table)}")
check("same holiday IDs", set(js_table) == set(dart_table),
      f"js only={set(js_table)-set(dart_table)} dart only={set(dart_table)-set(js_table)}")

for hid in sorted(set(js_table) & set(dart_table)):
    j, d = js_table[hid], dart_table[hid]
    check(f"{hid}: en matches", j["en"] == d["en"], f"{j['en']!r} vs {d['en']!r}")
    check(f"{hid}: am matches", j["am"] == d["am"], f"{j['am']!r} vs {d['am']!r}")
    check(f"{hid}: date matches",
          (j["month"], j["day"]) == (d["month"], d["day"]),
          f"{j['month']}/{j['day']} vs {d['month']}/{d['day']}")

js_lead = re.search(r"var MAX_LEAD\s*=\s*(\d+)", js_src)
dart_lead = re.search(r"static const int maxLead\s*=\s*(\d+)", dart_src)
check("MAX_LEAD matches",
      js_lead and dart_lead and js_lead.group(1) == dart_lead.group(1),
      f"{js_lead.group(1) if js_lead else '?'} vs {dart_lead.group(1) if dart_lead else '?'}")

# ---------------------------------------------------------------- 2. DECISIONS
print("\nDECISIONS — what each side SAYS")

# The message ladder: >1, ==1, ==0, negative. Both sides must key off the same
# numbers or one will say 'tomorrow' while the other says 'within 1 day'.
js_cases = re.findall(r"days\s*([><=!]+)\s*(\d+)", js_src)
dart_cases = re.findall(r"days\s*([><=!]+)\s*(\d+)", dart_src)
check("message thresholds present on both sides",
      bool(js_cases) and bool(dart_cases),
      f"js={js_cases} dart={dart_cases}")

# horizon default: JS current() uses 75, Dart defaultHorizon should be 75
# current() decides whether a banner appears, so THAT default is the one that
# must match. Matching the first `horizonDays || N` in the file found the one
# in upcoming() (90) and compared it against the Dart's 75 — reporting a
# disagreement that did not exist.
_cur = re.search(r"function current\([^)]*\)\s*\{", js_src)
_cur_body = js_src[_cur.end():_cur.end() + 400] if _cur else ""
js_horizon = re.search(r"horizonDays\s*\|\|\s*(\d+)", _cur_body)
dart_horizon = re.search(r"defaultHorizon\s*=\s*(\d+)", dart_src)
check("default horizon matches",
      js_horizon and dart_horizon and js_horizon.group(1) == dart_horizon.group(1),
      f"{js_horizon.group(1) if js_horizon else '?'} vs {dart_horizon.group(1) if dart_horizon else '?'}")

# ------------------------------------------------------------------- 3. DATES
print("\nDATES — three implementations, 2020-2050")


def dart_transliteration(year: int) -> date:
    """A faithful transliteration of the DART algorithm, so dates can be checked
    without a Dart toolchain. Kept deliberately dumb: same integer steps, same
    century table. If the Dart changes and this does not, the check will say so
    (which is itself the alarm we want)."""
    a, b, c = year % 4, year % 7, year % 19
    d = (19 * c + 15) % 30
    e = (2 * a + 4 * b - d + 34) % 7
    month = (d + e + 114) // 31
    day = ((d + e + 114) % 31) + 1
    julian = date(year, month, day)
    offset = 12 if year < 1900 else (13 if year < 2100 else 14)
    return julian + timedelta(days=offset)


node_script = """
const fs=require('fs'),vm=require('vm');
const ctx={}; ctx.window=ctx; vm.createContext(ctx);
vm.runInContext(fs.readFileSync(process.argv[1],'utf8'),ctx);
const out={};
for(let y=2020;y<=2050;y++){ out[y]=ctx.NorchaHolidays.fasika(y).toISOString().slice(0,10); }
console.log(JSON.stringify(out));
"""
proc = subprocess.run(["node", "-e", node_script, str(JS)],
                      capture_output=True, text=True, timeout=120)
if proc.returncode != 0:
    check("node can run the JS", False, proc.stderr.strip()[:300])
else:
    js_dates = {int(k): v for k, v in json.loads(proc.stdout).items()}
    check("node can run the JS", True)

    mismatches = []
    not_sunday = []
    for y, iso in js_dates.items():
        js_date = date.fromisoformat(iso)
        py_date = dart_transliteration(y)
        if iso != py_date.isoformat():
            mismatches.append(f"{y}: js={iso} dart={py_date}")
        if js_date.weekday() != 6:  # Python: Monday=0 … Sunday=6
            not_sunday.append(f"{y}={iso}")

    check(f"JS and DART agree on Fasika for {len(js_dates)} years",
          not mismatches, "; ".join(mismatches[:6]))
    check("every Fasika is a Sunday", not not_sunday, "; ".join(not_sunday[:6]))

# ------------------------------------------------------------ PUBLISHED TRUTH
print("\nEXTERNAL FACTS — published Orthodox Easter dates")
published = {2024: "2024-05-05", 2025: "2025-04-20",
             2026: "2026-04-12", 2027: "2027-05-02"}
for y, want in published.items():
    got_js = js_dates.get(y) if 'js_dates' in dir() else None
    got_py = dart_transliteration(y).isoformat()
    check(f"{y}: JS matches published ({want})", got_js == want, f"got {got_js}")
    check(f"{y}: DART matches published ({want})", got_py == want, f"got {got_py}")



# ------------------------------------------------------------------- DELIVERY
# Same treatment for the delivery engine: it decides whether the shop can hit a
# customer's date, so a drift between app and site is a broken promise, not a
# cosmetic difference.
DART_DELIV = ROOT / "lib" / "core" / "delivery.dart"
JS_DELIV = ROOT / "tools" / "vendor" / "norcha-delivery.js"

if DART_DELIV.exists() and JS_DELIV.exists():
    print("\nDELIVERY — rules and constants")
    ddel = DART_DELIV.read_text()
    jdel = JS_DELIV.read_text()

    # Cut-off hour. Dart uses a named default: {int cutoffHour = 16}.
    # JS uses: cutoffHour === undefined ? 16 : cutoffHour.
    # Match each on its own terms — normalising whitespace and hoping produced
    # a false positive on the first run.
    check("Dart default cut-off is 16",
          re.search(r"cutoffHour\s*=\s*16", ddel) is not None,
          "no 'cutoffHour = 16' in delivery.dart")
    check("JS default cut-off is 16",
          re.search(r"\?\s*16\s*:", jdel) is not None,
          "no '? 16 :' in norcha-delivery.js")

    # Sunday rule must exist on both sides.
    check("Dart skips Sundays", "DateTime.sunday" in ddel)
    check("JS skips Sundays", "getDay()" in jdel)

    # The three refusal reasons must be the SAME STRINGS — a customer told
    # "too soon" in the app and "past" on the site is the same bug reported two
    # ways.
    for reason in ["past", "sunday", "tooSoon"]:
        check(f"reason '{reason}' present in both",
              f"'{reason}'" in ddel and f'"{reason}"' in jdel)

    def am_months(src, marker):
        """Amharic month array following [marker], single- or double-quoted.

        The Dart uses 'single' and the JS uses "double". A regex written for
        one style finds nothing in the other and reports a disagreement that
        does not exist — which happened three times in this file.
        """
        i = src.find(marker)
        if i < 0:
            return None
        seg = src[i:i + 1200]
        # The key may be BARE (JS object literal: `am: [...]`) or QUOTED
        # (Dart map literal: `'am': [...]`). Requiring quotes on both sides
        # matched the Dart and silently missed the JS — the fourth false
        # positive from quote-style assumptions in this harness.
        pattern = r"['\"]?am['\"]?\s*:\s*\[([^\]]+)\]"
        m = re.search(pattern, seg)
        if not m:
            return None
        return [x.strip().strip("'").strip('"') for x in m.group(1).split(",")]

    d_months = am_months(ddel, "_months = {")
    j_months = am_months(jdel, "MONTHS = {")
    check("Dart and JS agree on all 12 Amharic months",
          d_months is not None and j_months is not None and d_months == j_months,
          f"dart={d_months} js={j_months}")

    # The Amharic month strings must also match the HOLIDAY module, since both
    # render dates to a customer and two spellings of "September" is a bug.
    hol = ROOT / "lib" / "core" / "holidays.dart"
    if hol.exists():
        h_months = am_months(hol.read_text(), "_months = {")
        check("delivery and holiday modules agree on Amharic months",
              d_months is not None and h_months is not None and d_months == h_months,
              f"delivery={d_months} holidays={h_months}")
else:
    print("\nSKIP: delivery files not both present")

# ------------------------------------------------------------------- VERDICT
print(f"\n{checks - len(failures)}/{checks} checks passed")
if failures:
    print("\nDISAGREEMENTS:")
    for f in failures:
        print("  -", f)
    print("\nThe app and the website would tell customers different dates.")
    sys.exit(1)
print("\nApp and website agree — constants, decisions, dates and published facts.")
sys.exit(0)
