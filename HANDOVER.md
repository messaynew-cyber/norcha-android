# HANDOVER — Norcha Print Android

**For: whoever picks this up next. Most likely me, with no memory of writing it.**

Last updated: 2026-10-11, end of the session that fixed the grey screen, killed the
diagnostic banner, and moved the build off GitHub's slow pipe.

---

## 0. Read this first

The single most useful habit on this repo: **read the file header before changing the
file.** Every non-obvious decision is documented where it was made, in prose, with
reasoning and with the mistakes that produced it. That is unusual and it is deliberate —
it is the only reason the current me can operate without the previous me.

And the rule this codebase earned the hard way: **take numbers from the thing that
works, and measure rather than reason.** Three separate bugs on this project were caused
by deriving a value from first principles when a working reference already existed.

---

## 1. The repo, in one screen

| | |
|---|---|
| Repo | `messaynew-cyber/norcha-android` (public) |
| **Live branch** | **`pricing-real`** — this is where work happens |
| `main` | **STALE — 40+ commits behind.** Never build from it. |
| App | Flutter, Norcha Print, Bole, Addis Ababa. Offline pricer + live order API. |
| Build | GitHub Actions only. **Never on the phone** — see §2. |
| Version | read from `/VERSION`, stamped as `<version>+<run number>` |
| Download page | **https://adwaaudit.com/norcha/** (the relay) |

---

## 2. 🔴 THE BUILD CANON — do not try to compile locally

Flutter ships the Linux Dart VM as **x86_64 only**. There is no ARM64 tarball. On this
ARM64 phone `flutter --version` dies with `Exec format error`. This is not a bug and it
is not fixable. Verified the hard way on 2026-09-24.

| Role | Where |
|---|---|
| Authoring (write Dart, commit, push) | the phone |
| Compiling | GitHub Actions |
| Distribution | GitHub Release → mirrored to the relay |

**Never download the Flutter SDK onto the phone. Never try `flutter build` locally.**

---

## 3. Workflows — and the trap that keeps recurring

Three workflows: `test.yml` (fast), `luxury-build.yml` (builds the APK), `android-sample.yml`.

**The recurring trap: a branch that no workflow watches builds nothing, silently.**

That has now bitten twice:

1. `pricing-real` — the *live* branch — was in **no** trigger list. All work happened
   there and CI only ran when a human remembered to dispatch it by hand.
2. Then `fix-*` was in no list either. A fix branch was pushed, reported as "PR is
   open" (it was not), and **never tested at all.**

Both are fixed: triggers now use wildcards (`fix-*`, `fix/**`, `phase*`, `theme*`,
`feat-*`, `feat/**`) rather than enumerated names. **If you add a new branch naming
scheme, add it to all three files or it will be invisible.** An enumerated list in a
workflow is a list that rots.

---

## 4. Delivery — why the relay exists

**GitHub is unusably slow from Addis.** Measured 2026-10-11 from the phone:

| Route | Speed |
|---|---|
| github.com release download | **17 KB/s** → 53 minutes per APK |
| Cloudflare | 2.8 MB/s |
| **the relay** | **3.8 MB/s** → ~15 seconds |

The bottleneck is GitHub, **not** the connection. The phone pulled 8 MB from Cloudflare in
2.9 seconds while GitHub crawled.

### The relay

- **https://adwaaudit.com/norcha/** — a build index page, one card per APK, newest first
- Lives at `/usr/share/nginx/html/norcha/` **inside the `adwa_frontend` container**
- Works with **no nginx config** — `location /` already has `try_files $uri $uri/`, so a
  directory with an `index.html` just resolves. **Do not add a location block; you would
  be editing the Adwa Auditor's config.**
- `generate_index.py` scans the directory and writes `index.json` + a `.sha256` per build.
  The page reads that, so **it cannot lie about what is on disk.**

### Adding a build by hand (if CI mirroring is off)

```bash
cd /home/ubuntu/norcha-relay
curl -sL -o norcha-print-vX.Y.Z-bNN.apk "<release asset url>"
python3 generate_index.py
CT=$(sudo docker ps -q --filter publish=80)
sudo docker cp norcha-print-vX.Y.Z-bNN.apk $CT:/usr/share/nginx/html/norcha/
sudo docker cp index.json $CT:/usr/share/nginx/html/norcha/
```

CI now does this automatically — see §5.

---

## 5. 🔴 THE ADWA AUDITOR BOUNDARY

The Oracle VPS (`129.80.112.9`) also hosts the **Adwa Auditor**, which is **READ ONLY**.
The relay shares that container's web root. These are the rules:

- **Never edit the Auditor's `nginx.conf`.** The relay does not need to.
- **Never edit anything under `/usr/share/nginx/html/` except the `norcha/` directory.**
- **Do not touch** `adwa_frontend`'s config, `adwa_backend`, `adwa_chromadb`, or any
  other container's files.
- **Do not restart the container** without a reason. The relay was built with zero
  downtime and it should stay that way.
- Backups made during setup live at `/home/ubuntu/norcha-backup/`, and there is an
  in-container `nginx.conf.pre-norcha`. Restore with those if anything looks wrong.

**Sanity check after any relay change:**
```bash
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1/        # expect 200
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1/tobia/  # expect 200
```

### CI mirroring

`luxury-build.yml` has a **"Mirror to the relay"** step that SSHes to the VPS, pulls the
release, regenerates the index and copies it in. It needs the repo secret
**`NORCHA_RELAY_KEY`** (an SSH private key for `ubuntu@129.80.112.9`).

If that secret is absent the step **skips cleanly** — a missing secret must never fail a
build that produced a good APK. If downloads are stale, check the secret first.

---

## 6. The bugs fixed this session, and what they teach

### 6a. Amharic grey screen — `localizationsDelegates`

`MaterialApp` set `locale: Locale('am')` and listed Amharic in `supportedLocales`, but
**never provided `localizationsDelegates`** — absent from all 36 Dart files. Flutter
*accepted* the locale and *failed to resolve* it. `Localizations` fell back to
`DefaultMaterialLocalizations` (English only), `TextField` asked for its decoration, got
null, and threw `Null check operator used on a null value` inside `text_field.dart`.

**Why it looked unexplained:** the throw is entirely inside the framework, so no Norcha
frame appears in the trace. It read as a grey screen for two days.

**Why Order + Upload only:** they are the only two pages with a `TextField`.

**Why it was confused with an unrelated fix:** an earlier `ValueKey` fix addressed a
*reused Element holding a live `InputConnection`*, painting `#B6B6B6`. That fix was
correct and stays. Two bugs, same widget, same symptom.

### 6b. The diagnostic banner

Built because the Amharic fault had been guessed wrong twice. It worked — the trace that
cracked it came out of the banner. Then it came **off the screen**, because a development
instrument has no business over a shop counter's quote.

`DiagnosticHost` returns `widget.child` unless `debugMode` is true. Re-arm with
`--dart-define=NORCHA_DEBUG_BANNER=true`.

**🔴 Recording is untouched.** `Diagnostics.record`, the Flutter error hook and
`PlatformDispatcher.instance.onError` all still run. Silencing the overlay is a UI
decision and must never silence the record. Two tests guard exactly that.

### 6c. Ghost numeral doubling — `strokeWidth`

**My regression, and I got it wrong three times.**

`strokeWidth` is centred on the glyph's **contour**, so half is drawn *inside* the
letterform. The story:

| | stroke | % of glyph | |
|---|---|---|---|
| website `style.css` (`-webkit-text-stroke: 1.7px` on ~300px) | 1.7 | 0.57% | ✅ |
| app, originally | 1.6 on 240 | 0.67% | ✅ |
| **attempt 1 — `size * 0.045`** | 10.8 | **4.50%** | ❌ 8× too thick |
| **attempt 2 — fixed `1.6`, asserting it must not scale** | 1.6 | 0.67% | ✅ but for the wrong reason |
| **now — `size * 0.0065`** | 1.6 on 240 | 0.65% | ✅ ratio from the website |

Only `GhostStyle.outline` pages doubled (Quote, Order, Studio). Home and Upload are
`GhostStyle.soft` — a plain `Text` with a colour and no stroke — and were fine. **That
split was the diagnosis.**

**Attempt 3 was almost a disaster:** a comment about synthesised bold led to the conclusion
that the font was smearing a second glyph. **False.** `NotoSerifEthiopic.ttf` is a variable
font with a real `wght` axis **100→900**; `w600` is a genuine interpolated face. Caught by
reading the `fvar` table instead of trusting the comment.

Also copied the website's phone step-down: `28vw` clamped to `96–170px` → **110px** on a
393dp screen, replacing a flat `250`. A numeral sized for desktop is proportionally far
larger on a phone, and at a fixed ratio proportionally heavier — which is why the doubling
was more obvious in the app than on the web.

> **Weight warning:** pubspec declares only 400/500/600/700. Requesting a weight outside
> that set — even one inside the font's real axis — **will** synthesise, and on a stroked
> outline a synthesised copy is a *second outline*. Add the weight to `pubspec.yaml` too.

---

## 7. OPEN ITEMS

1. **`main` is stale.** 40+ commits behind `pricing-real`. Anyone landing on the repo —
   including a future me — sees a dead project. **This is the biggest remaining risk of
   confusion.** A fast-forward merge fixes it.
2. **Signing key.** Every build uses a freshly generated Android **debug** key, so
   **install-over-old always fails with a signature mismatch** and the user must uninstall
   first. Needs one persistent keystore + CI secret. **Every install instruction currently
   has to say "uninstall first", which is not shippable.**
3. **`prints` prices are placeholders.** `lib/core/pricing.dart` keeps a `prints` family
   flagged `THE PRICE IS NOT REAL` — it survives only because it is the *default selection*
   in quote and upload, so deleting it crashes both pages. **Blocked on Feven's price
   sheet.** The rest of the pricing is real, sourced from the shop's own Price List 1/2.
4. **Never visually confirmed.** Every fix this session was verified by tests, by CI, and
   by matching a measured value from working production code — **never by looking at the
   rendered app.** If the numeral doubling persists, get a screenshot of the Quote page
   watermark before touching the code again.

---

## 8. How to work on this without breaking it

1. Branch off **`pricing-real`**, not `main` and not an old branch.
2. Push. **Open the PR** — a `push` alone only triggers on wildcard-matched branches.
3. Read the CI logs before changing anything. `flutter analyze --no-fatal-infos` **still
   exits non-zero on infos**, so a stray `unused_import` fails the build.
4. **After a squash-merge, re-branch from the updated `pricing-real`.** Squash rewrites
   history; branching off the pre-merge commit guarantees a conflict and a `dirty` PR,
   and GitHub refuses to run checks on a PR it cannot merge.
5. Merge → the release step fires on its own → the relay mirrors it → the phone downloads
   it in ~15 seconds.

---

## 9. House rules this repo has settled on

- **Comment the reasoning, not the mechanics.** Say *why*, and say what you tried that
  failed. The failed attempts are the most valuable part.
- **Guards before optimisations.** The stroke is guarded, the localizations are guarded,
  the picker is guarded. An unsupported feature must render *nothing quietly*, never
  something broken.
- **A missing capability must never take down the app.** Reminders, notifications and the
  banner all fail soft.
- **Never hardcode a version.** Read it from `NORCHA_VERSION`.
- **Measure.** Three bugs here came from reasoning instead of measuring.
