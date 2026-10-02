# Norcha — Design Language: "Aurum"

**Status:** proposed rewrite. Supersedes the Darkroom direction.
**Target:** an app that looks like it was made by a design studio, not by a form builder.

---

## Why rewrite the design again

Darkroom was accepted ("this is much better Tobia") but it is still *good taste,
safely applied*. It has the right palette and the wrong ambition: flat panels on a
near-black ground, gold as hairlines, serif numerals. Everything sits on the same
physical plane. Nothing catches light.

The current 2026 direction — call it **volumetric glass** — fixes exactly that.
The interface is built from **layers at different depths**, each with its own
relationship to light: an atmospheric ground behind, frosted sheets in the middle,
and a small number of key elements floating above with real contact shadows and a
specular edge. Depth is not decoration; it is how the screen communicates what
matters and what is background.

**Aurum** = Darkroom's palette and typography, rebuilt on a layered, lit plane.

---

## The five laws

### 1. Depth is the hierarchy
Every surface sits at a declared Z-level with a declared blur and shadow.
No level shares lighting with another. If two things look equally close to the
glass, one of them is wrong.

| Level | Role | Blur (sigma) | Treatment |
|---|---|---|---|
| `ground` | atmospheric background | — | image + dark scrim, never text |
| `sheet` | content panels, cards | 14 | 6% white overlay + 1px top hairline |
| `raised` | selected, interactive | 22 | brighter overlay + gold hairline |
| `float` | CTA, total, nav | 30 | contact shadow + specular top edge |

### 2. Specular edge, not a border
Real glass shows a bright edge where it catches light. Every sheet gets a
**1px top gradient hairline** (white 14% → transparent) and a 1px bottom shadow
line. That single detail is most of the difference between "rounded box" and
"glass".

### 3. The ground moves, the content does not
The atmospheric layer **parallaxes at 8-14% of scroll**. Content scrolls at 100%.
This is what makes the screen feel spatial rather than flat. Cheapest possible
depth cue, and it is the one people feel without being able to name.

### 4. Gold is light, never paint
Unchanged from Darkroom and correct: gold appears as hairlines, marks, small
filled glyphs, and the foil sweep. **Never** as a large flat fill. A full-width
gold button is banned; the CTA is a dark sheet with a gold rim and gold text.

### 5. Motion is physics with an emphasis budget
M3 Expressive's actual contribution is **spring physics plus selective
overshoot**. Springs, not curves. But not everything bounces:

- **Routine** (list item, chip, tab): no overshoot. Stiffness 500 / damping 35.
- **Expressive** (quantity change, selection landing, sheet opening): overshoot.
  Stiffness 380 / damping 22.
- **Snappy** (tap feedback): stiffness 700 / damping 42, under 180ms.
- **Press response must complete under 80ms.** Slower reads as lag.
- **Emphasis budget: at most TWO expressive moments per screen.** More than two
  and nothing feels special, because everything does.

---

## Performance rules (non-negotiable, this is a phone)

Blur is the most expensive thing on this list, so it obeys hard rules:

1. **Maximum 2 live `BackdropFilter`s on screen at once.** Blur is O(area); three
   overlapping full-bleed blurs will drop frames on a mid-range device.
2. **`ImageFiltered` over `BackdropFilter`** whenever the blur applies to a single
   widget rather than to everything painted beneath it. Flutter's own docs say the
   performance difference is dramatic for complex filters — and `ImageFiltered` is
   simpler to reason about.
3. **The scrolling content must never sit under a blur.** The ground layer is a
   static image; blurs live on static chrome (app bar, bottom CTA, sheets).
4. **No blur inside a `ListView` item.** Use the cheaper `sheet` treatment
   (overlay + hairline, no filter) for repeated rows.
5. Target **60fps on the Dimensity-920 class device**, not on a flagship.

---

## Typography

Unchanged families, one addition:

- **Display serif** — Playfair Display. Numbers and headlines only. A price set
  large in a serif reads as *worth* something; the same price in sans reads as
  data entry.
- **Body sans** — Inter. Everything functional.
- **Amharic** — Noto Sans Ethiopic. Not an afterthought; most of the counter
  speaks it.
- **NEW: optical tracking on display sizes.** Large serif needs *negative* tracking
  (-1.2 at 56px, -0.6 at 38px) or it looks loose and amateur. Small caps labels
  need *positive* tracking (+2.4). This is already right in Darkroom — keep it.

**Fonts must be bundled, not fetched.** `google_fonts` fetches over HTTP at
runtime by default, which means the first launch on a shop counter with bad signal
renders in the wrong typeface — the single most visible way to look cheap. Font
files go in `assets/fonts/` and get referenced directly. Offline-first or it
doesn't ship.

---

## What is deliberately rejected

- **Dynamic color (Material You).** Pulling wallpaper colours into a luxury
  identity means the brand changes with the user's home screen. No.
- **Rive / Lottie files.** Cannot be authored from this phone, so they cannot be
  maintained from this phone. Dead on arrival.
- **A third design variation.** Two were built; one was chosen. The budget now
  goes to depth and motion quality on the chosen direction, not to a third
  opinion nobody asked for.
- **Large gold fills, glassmorphism on every surface, neon.** The failure mode of
  this entire direction is doing too much of it.

---

## The test

Show it to someone for four seconds and ask what the app is *for* and whether it
looked expensive. If either answer is unclear, the depth ladder is wrong.
