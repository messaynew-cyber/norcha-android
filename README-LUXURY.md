# Norcha Print — Luxury rewrite

Branch: `phase2-api`. Target design: **Aurum** (see `docs/DESIGN-LUXURY.md`).

## What changed from Phase 1

| | Phase 1 | Now |
|---|---|---|
| Data | everything offline, hardcoded | **live site API** for lookup + upload; everything else still local |
| Design | flat dark editorial (accepted, safely applied) | **layered depth** — atmospheric ground, glass sheets, floating CTA |
| Tests | parity with the website's JS | parity **+ API contract + design system rules** |
| Signing | Android debug key, different per build | **documented**, and the install-over problem is named |

## The two endpoints

Full contract in `docs/API-CONTRACT.md`. Short version:

- `GET /api/order?code=&phone=` — needs **both**, returns what the studio
  received. One indistinguishable 404 for every failure case, by design.
- `POST /api/upload` (multipart) — probe `GET /api/upload` first; if it says
  503, **hide the entry point entirely**.

Base is `https://norchaprint.com`. GitHub Pages is a mirror — never call it.

## 🔴 Signing — read this before installing

Every Norcha APK built so far is signed with an **Android debug key**
(`CN=Android Debug`). Worse: they are not even the *same* debug key —
`norcha-print-sample-5.apk` and `NORCHA-phase1-final.apk` carry different
certificate fingerprints, so they were signed by different generated keys.

**Consequence:** Android refuses to install a build over one signed by a
different key. You must uninstall the old app first, or you get
`INSTALL_FAILED_UPDATE_INCOMPATIBLE` and a mystery.

**This is not fixed yet, on purpose.** A permanent release keystore has to be
generated once and then never lost — losing it means the app can never be
updated again, only replaced. That is a decision for the Architect, not a
default I should quietly pick. Options:

1. **Keep debug signing** — fine for review builds, breaks every time the
   runner's generated key changes. Current state.
2. **One committed release keystore** — stable forever, and the key is in a git
   repo. Acceptable for a shop app that is not on Play Store.
3. **Keystore in GitHub Secrets, injected at build time** — correct, and needs
   the keystore generated and uploaded once by the Architect.

Recommendation: **3**, and it only needs doing once.

## Verify locally

The phone cannot build (ARM64, x86_64-only Dart VM). What it *can* do:

```bash
flutter test        # if a Dart VM is available
```

Realistically: push, and let the runner tell you. That is the workflow.

## Build

`Luxury Build` workflow, two jobs. `verify` runs analysis + tests (fast, no
network). `apk` only runs if `verify` is green, and publishes a Release asset.
