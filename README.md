# Norcha Print — Android

Native Flutter app for **Norcha Print**, Bole, Addis Ababa.
Live prices, Ethiopian holiday deadlines, and a quote calculator that works
with no internet at all.

The website is the reference implementation for all pricing. This app **ports**
it — it does not replace it. `test/pricing_parity_test.dart` exists to make sure
the two can never disagree.

---

## 🔴 BUILD CANON — READ THIS BEFORE TRYING TO COMPILE

**Android apps are ALWAYS compiled on GitHub Actions. NEVER on the phone.**

Why: the authoring device is ARM64 (Redmi Note 11 Pro+ 5G). Flutter/Google ship
the Linux Dart VM as **x86_64 only** — `flutter --version` dies with
`Exec format error`. There is no ARM64 Flutter tarball. This was verified the
hard way on 2026-09-24. It is not a bug and it is not fixable.

| Role | Where |
|---|---|
| Authoring (write Dart, commit, push) | the phone |
| Compiling (APK + signed AAB) | GitHub Actions |
| Distribution | GitHub Release artifact |

**Never** download the Flutter SDK onto the phone. **Never** try `flutter build`
locally. It cannot work.

---

## Layout

```
lib/
  core/
    pricing.dart      ← the source of truth: 22 prices, tiers, quote(), money()
    holidays.dart     ← Ethiopian deadline engine (Meskel, Genna, Timket, Fasika…)
    delivery.dart     ← production days, no Sundays, the 16:00 cut-off
    voucher.dart      ← offline gift vouchers
  features/
    quote/            ← the calculator UI
    deadlines/        ← the holiday strip
test/
  pricing_parity_test.dart   ← THE important test. Run it before every push.
```

## The parity rule

`js/norcha-data.js` (website) and `lib/core/pricing.dart` (app) must produce
**identical** numbers for all 22 products across every tier boundary. The test
holds the JavaScript's output as literals and fails on a one-birr drift.

This matters because "two prices for one order" already happened once on the
web — the mugs double-discount bug. In an app, nobody can hotfix it.

**If you change a price, change it in both places, then run the test.**

## Not to be "fixed"

`mugs` uses a deliberately **flat** tier ladder. Mugs already carry pack pricing
in `sizes` (1/2/4 at 350/650/1200). Adding a percentage ladder on top
double-discounts — "2 mugs" came out as 650 via the pack and 644 via the ladder.
Two prices for one order. Leave it flat.

## Status

- [x] Pricing core ported + parity tests written
- [ ] Holiday + delivery + voucher ports
- [ ] UI
- [ ] CI workflow
- [ ] ⚠️ Prices confirmed by Feven — **still outstanding, still temporary**

## Signing

Sideload-only for v1. One release keystore, used from build #1 so that build #2
installs cleanly *over* build #1. A per-build debug key would force an
uninstall/reinstall on every update and wipe app data. The keystore is backed
up off-device; losing it means the app can never be updated again.

---

## Two traps that already cost a CI run (2026-09-24)

**1. `Size` is a name Flutter already owns.**
`lib/core/pricing.dart` exports `PrintSize`, *not* `Size`. Flutter's material
library exports its own `Size`; importing both makes `Size.fromHeight(52)`
resolve to the wrong class. Nine analyse errors, one cause. Keep the `Print`
prefix.

**2. `Color.withValues()` needs Flutter 3.27+; CI pins 3.24.5.**
Use `withOpacity()` in this repo until the pinned version is raised. Using a
newer API than the pinned toolchain is not a subtle bug, it is just carelessness
with a compile error attached.

Both were caught by `flutter analyze` running **before** the build. That is why
analysis is a gate and not an afterthought.
