# tools/ — cross-language parity

## `port_parity.py`

**The problem it solves.** `lib/core/holidays.dart` is a hand port of the
website's `js/norcha-holidays.js`. The two are the only thing keeping the app
and the site telling customers the same deadline, and nothing enforced it.

That is not hypothetical. Fasika was **a week out and landing on a Monday**
across 2025–2030, on both surfaces, because no check compared anything.

**How it works.** Dart cannot execute on this ARM64 authoring device, so the
harness does not try. It checks four things:

| Layer | What it compares |
|---|---|
| Constants | holiday IDs, English + Amharic names, month/day, MAX_LEAD |
| Decisions | the message-threshold ladder and the horizon default |
| Dates | runs the JS in node, runs a Python transliteration of the Dart, and compares Fasika across 31 years |
| External facts | published Orthodox Easter dates — the check that is a fact about the world rather than about our code |

The Python transliteration makes this a **three-implementation** check. A date
is only trusted when the JS, the transliteration, and the published calendar
all agree.

**Run it:** `python3 tools/port_parity.py`

Exit code 1 on any disagreement, so CI gates on it. It runs in the Test
workflow after the Dart tests.

## `vendor/norcha-holidays.js`

A copy of the site's holiday module.

**This is a vendored snapshot and it will go stale.** When the site's copy
changes, re-vendor it:

```sh
cp ../feven-prints-v2/js/norcha-holidays.js tools/vendor/norcha-holidays.js
python3 tools/port_parity.py
```

If the harness reports a disagreement after re-vendoring, that is the harness
working — it means the site has moved and the Dart port has not.

## Traps already hit here

Two drafts of the row-parsing regex were wrong in instructive ways. Both are
recorded at the site of the fix, but in summary:

1. **A single-quote-only pattern silently dropped `mothersday`.** Dart allows
   both `'single'` and `"double"` quoted strings, and `"Mother's Day"` *must*
   be double quoted because it contains an apostrophe. The row vanished, and it
   looked exactly like the app was missing a holiday from its table.

2. **Normalising `"` → `'` made it worse.** Then `'Mother's Day'` has an
   apostrophe that ends the string early. Replacing quote characters is not the
   same as handling quote delimiters.

3. **The horizon check read the wrong default.** `upcoming()` defaults to 90,
   `current()` to 75. Matching the first `horizonDays || N` in the file
   compared 90 against 75 and reported a disagreement that did not exist.

**The pattern in all three: the harness itself gave false readings.** A test
that cries wolf is worse than no test, because it teaches you to ignore it.
When the harness disagrees, check the harness before "fixing" the code.
