# HANDOVER — Norcha Print Android

**For: whoever picks this up next. Most likely me, with no memory of writing it.**

---

## ⏱️ CURRENT STATE — 2026-10-11, end of session

**Where the app is:** `pricing-real` @ `0a43e67`. Live download page
**https://adwaaudit.com/norcha/** serving **`0.5.0-b56`**. Luxury Build green.

**What was solved this session:**
- ✅ **Amharic grey screen** — root cause was missing `localizationsDelegates` (§6a)
- ✅ **Diagnostic banner removed** from the screen, recording kept (§6b)
- ✅ **Relay built** at `adwaaudit.com/norcha/` — GitHub is 17 KB/s from Addis, the
  relay does 4 MB/s (§4)
- ✅ **Relay auto-publish DELETED** after it published a 9-byte `Not Found` to the
  live page and reported green while skipping (§5)

**What is NOT solved:**
- 🔴 **The ghost numerals.** Six attempts, no visible change, and the b56 result
  proves the edited code path is probably not what draws it. **§6c. Start there.**
- ⚠️ `main` is stale. ⚠️ Debug signing key. ⚠️ `prints` prices still placeholders.

**Next action, in order:**
1. Read **§6c** — the numerals. Do not adjust a stroke value.
2. Get a **screenshot of the Quote page (፪) watermark**, or answer *"what code paints
   that mark?"*. That has never been established.
3. Then everything else in §7.

---

Last updated: 2026-10-11, end of the session that fixed the grey screen, killed the
diagnostic banner, and moved the build off GitHub's slow pipe.

---

## 0. Read this first

> ### 🔴 IF YOU ARE HERE FOR THE GHOST NUMERALS — READ §6c FIRST
> Six attempts have been made and **none of them produced a visible change**. The
> evidence now says the code path being edited is **not the one drawing the artefact**.
> **Do not adjust a stroke value.** Go straight to §6c.


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

### 🔴 HOW AN APK ACTUALLY REACHES THE PHONE

**Not through CI.** The build publishes a GitHub Release; someone then copies the APK to
the relay **by hand**. See §5 — the automation was deleted on purpose, with reasons.

The phone cannot download from github.com. Measured 2026-10-11: **17 KB/s**, which is
**53 minutes for one APK**. The relay does the same file in **~15 seconds**.

### The relay

- **https://adwaaudit.com/norcha/** — a build index page, one card per APK, newest first
- Lives at `/usr/share/nginx/html/norcha/` **inside the `adwa_frontend` container**
- Works with **no nginx config** — `location /` already has `try_files $uri $uri/`, so a
  directory with an `index.html` just resolves. **Do not add a location block; you would
  be editing the Adwa Auditor's config.**
- `generate_index.py` scans the directory and writes `index.json` + a `.sha256` per build.
  The page reads that, so **it cannot lie about what is on disk.**

### Adding a build — this is the ONLY way, and it is manual

Full walkthrough with the safety checks in **§5**. Short version:

```bash
cd /home/ubuntu/norcha-relay
NAME="norcha-print-vX.Y.Z-bNN.apk"
curl -fsSL -o "$NAME" "<release asset url>"     # -f so a 404 FAILS
[ "$(stat -c %s "$NAME")" -gt 1000000 ] || exit 1   # never publish a stub
python3 generate_index.py
CT=$(sudo docker ps -q --filter publish=80)
sudo docker cp "$NAME" "$CT":/usr/share/nginx/html/norcha/
sudo docker cp "$NAME.sha256" "$CT":/usr/share/nginx/html/norcha/
sudo docker cp index.json "$CT":/usr/share/nginx/html/norcha/
```

**CI does NOT do this.** It used to try; it was removed after publishing a 9-byte
`Not Found` body to the live page and reporting green while skipping. **§5 explains why
not to bring it back.**

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

### 🔴 PUBLISHING IS MANUAL, AND THAT IS DELIBERATE

There **was** a `Mirror to the relay` CI step. It was **deleted on 2026-10-11** after
costing far more than it saved. **Do not reintroduce it** without reading this first.

It failed in three different ways, and every one was a *bad* failure:

1. **`Permission denied (publickey)` for three runs.** The cause was
   `-i <(printf '%s' "$RELAY_KEY")` — process substitution gives ssh a `/dev/fd/N`
   path, and ssh re-executes itself *before* it opens the identity file, so the
   descriptor is gone. **The symptom points at the key**, so the key was regenerated,
   reinstalled and re-sealed through PyNaCl — all wasted. The key was correct the
   whole time.
2. **It published a 9-byte file called `Not Found` to the live page.** `curl -s`
   exits 0 on a 404, so a failed download looked like success and got indexed as a
   build. **It happened twice.**
3. **It reported green while never running.** Its `if:` gate named branches
   explicitly, so on other branches the step **skipped** — and GitHub reports a
   skipped step as **SUCCESS**. Three green builds looked like the mirror working
   when it had never executed once.

> **The rule: an automation whose failure mode is a green tick is worse than a
> manual step whose failure mode is obvious.** The manual step also only runs when
> someone actually wants an APK, which is rare.

**`NORCHA_RELAY_KEY` is now unused** and can be deleted from repo secrets. The CI
pubkey is still in `/home/ubuntu/.ssh/authorized_keys` (comment `norcha-ci-relay`)
and can go too.

### Publishing a build by hand — ~20 seconds

```bash
ssh ubuntu@129.80.112.9

cd /home/ubuntu/norcha-relay
NAME="norcha-print-vX.Y.Z-bNN.apk"

# 1. fetch it (use -f, so a 404 FAILS instead of writing "Not Found")
curl -fsSL -o "$NAME" \
  "https://github.com/messaynew-cyber/norcha-android/releases/download/vX.Y.Z-bNN/norcha-luxury-NN.apk"

# 2. ALWAYS check the size before publishing. This is the check that was missing.
ls -l "$NAME"                       # must be ~55 MB
[ "$(stat -c %s "$NAME")" -gt 1000000 ] || { echo "TOO SMALL — abort"; exit 1; }

# 3. regenerate the index (refuses anything under 1 MB as of 2026-10-11)
python3 generate_index.py

# 4. copy into the live container
CT=$(sudo docker ps -q --filter publish=80)
sudo docker cp "$NAME" "$CT":/usr/share/nginx/html/norcha/
sudo docker cp "$NAME.sha256" "$CT":/usr/share/nginx/html/norcha/
sudo docker cp index.json "$CT":/usr/share/nginx/html/norcha/

# 5. VERIFY — look at the destination, never the tool's exit code
sudo docker exec "$CT" ls -la /usr/share/nginx/html/norcha/
```

Then confirm from outside: `https://adwaaudit.com/norcha/`

`generate_index.py` now has a **`MIN_APK_BYTES` floor of 1 MB** and prints
`REFUSED <name>` for anything smaller, so a truncated download or an error body can
never be indexed again.

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

### 6c. Ghost numeral doubling — 🔴 UNRESOLVED. START HERE.

**Status: OPEN. Six attempts, no visible change. The next session must NOT begin by
adjusting a stroke value.**

#### Evidence — the one fact that matters

| build | `size` | `strokeWidth` | Architect sees |
|---|---|---|---|
| b41 | `sizeFor()` ≈ **110px** | `0.0065` ratio | doubled |
| **b56** | **`250`** | **`1.6` flat** | **doubled — no change** |

**b56 was verified at commit `5d5043d`: `size: 250`, `strokeWidth: 1.6`. It shipped.**

So **doubling the numeral and changing the stroke by ~4× produced NO visible
difference.** That is decisive: **the code path being edited is not the one drawing
what the Architect sees.**

#### What has been tried (all inside `GhostNumeral` — do not repeat)

1. `size * 0.045` (4.5% of glyph) — made it **worse**
2. flat `1.6` again, on the theory it must not scale
3. `size * 0.0065` — ratio taken from `feven-prints-v2/css/style.css`
   `-webkit-text-stroke: 1.7px` on a ~300px glyph (0.57%)
4. added `sizeFor()` — `28vw` clamped 96–170, i.e. ~110px on a 393dp phone
5. restored flat `1.6` **and** flat `250`, removed `sizeFor()` entirely
6. shipped all of the above — **no visible change**

#### 🔴 WHERE TO LOOK NEXT (not stroke values)

- **There may be a SECOND numeral/watermark.** Grep the whole `lib/` for every element
  that could paint a glyph at ornament scale. Candidates not yet examined:
  `telafi` (Home and Studio pass `telafi: true`), the `stamp` element, `_Header`,
  `lib/widgets/cloth_surface.dart`, `lib/widgets/ethiopian.dart`,
  `lib/widgets/loading_mark.dart`, `lib/widgets/kinetic_number.dart`.
- **`_StrokedText` may be clipped or not painting.** It builds
  `CustomPaint(size: Size(size * 0.85, size * 0.9))` inside
  `SizedBox(height: 320)` inside a `Stack` inside a `Positioned`. **Confirm what
  actually paints.**
- **The `outline`/`soft` split is still the strongest clue** — Quote/Order/Studio
  (outline) double; Home/Upload (soft) are fine. That points at a stroke path — but
  possibly **a different stroke** from the one being edited.
- **The painter was replaced in `1738555`** because the original path-based version
  **could not compile** (`InlineSpan has no .lines`). The rendering painter today is
  the `foreground` Paint one. If something *else* also draws an outline, there are
  two stroke paths and only one has been touched.

#### 🔴 THE DISCIPLINE RULE FOR THIS BUG

**DO NOT make a seventh blind value change.** Six builds were pushed to the Architect
to test without ever confirming **which code path draws the artefact**. Get either:

- a **screenshot of the Quote page (chapter 2, ፪) watermark** — we have never actually
  looked at the doubled thing, or
- a **code answer**: which widget paints that mark

**Verify the target before tuning it.** That rule applies to every bug in this repo.

#### Salvaged from the attempts (keep these)

- `strokeWidth` is centred on the glyph's **contour**, so half is drawn *inside* the
  letterform. Around **0.57–0.67% of the glyph size** is the range the website uses
  (`1.7px` on ~300px) and the app's original (`1.6` on 240).
- The website's `@media (max-width: 640px)` clamp (`28vw`, 96–170px) is a **web**
  layout rule. Applying it to the app is what `sizeFor()` did — **reverted, and
  should stay reverted** unless measurement says otherwise.
- **Any weight outside pubspec's declared 400/500/600/700 will synthesise**, and a
  synthesised copy of a *stroked* outline is *a second outline*. The font's real
  `wght` axis is 100–900, so `w600` is genuine — but a new weight must be added to
  `pubspec.yaml` too.

---

## 7. OPEN ITEMS

1. **🔴 THE GHOST NUMERALS ARE UNRESOLVED AND ARE THE #1 ITEM.** Six attempts, no
   visible change, and b56 proved the edited code path is probably not drawing it.
   **See §6c before touching anything.** The next action is a **screenshot** or a
   **code answer to "what paints that mark"** — not another value change.
2. **`main` is stale.** 40+ commits behind `pricing-real`. Anyone landing on the repo —
   including a future me — sees a dead project. A fast-forward merge fixes it.
3. **Signing key.** Every build uses a freshly generated Android **debug** key, so
   **install-over-old always fails** with a signature mismatch and the user must
   uninstall first. Needs one persistent keystore + CI secret. **Every install
   instruction currently says "uninstall first", which is not shippable.**
4. **`prints` prices are placeholders.** `lib/core/pricing.dart` keeps a `prints` family
   flagged `THE PRICE IS NOT REAL` — it survives only because it is the *default
   selection* in quote and upload, so deleting it crashes both pages. **Blocked on
   Feven's price sheet.** The rest of the pricing is real, from the shop's own
   Price List 1/2.
5. **`Norcha Sample APK` workflow is red** on `pricing-real` pushes. It does not produce
   anything that ships (the Luxury Build is the one that matters, and it is green).
   Either fix or disable — it is noise otherwise.
6. **`NORCHA_RELAY_KEY` secret is unused** and can be deleted. Same for the
   `norcha-ci-relay` line in the VPS `authorized_keys`.

---

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
