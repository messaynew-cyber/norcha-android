# Norcha API contract — the app talks to the live site

**Base:** `https://norchaprint.com` (Cloudflare Pages). GitHub Pages is a mirror
only — never call it.
**Reference implementation:** `feven-prints-v2/js/norcha-order.js`, `functions/api/*.js`

The app is no longer offline-only. Two endpoints, both already live and both
already used by the website. The app does not invent a third.

---

## 1. `GET /api/order?code=NOR-XXXXXX&phone=...`

The honest order lookup. Answers one question: *what did the studio actually
receive, and when.*

### Request
- `code` — must match `/^NOR-[2-9A-HJ-NP-Z]{6}$/i` (no 0/O/1/I/L, so it can be
  read down a phone line). Sent uppercased.
- `phone` — the number the customer ordered with. The server normalises it
  itself: `0911...`, `+251911...`, `251911...`, `911...` and variants with
  spaces/dashes all collapse to the same key.

### Success (200)
```json
{
  "ok": true,
  "code": "NOR-ABC123",
  "received": "2026-10-02T09:14:00.000Z",
  "files": 12,
  "bytes": 48210432,
  "stage": "received",
  "stage_note": "The studio has your photos. A person confirms sizes and price before printing.",
  "requested": { "product": "canvas", "size": "40 × 60 cm", "qty": "2", "note": "" },
  "retention_days": 30,
  "delete_after": "2026-11-01"
}
```

### Failures — and how to render them
| Status | `reason` | What the customer sees |
|---|---|---|
| 400 | — | "You need both the reference and the phone number." |
| 404 | `not-found` | "We could not find an order with that reference and phone number." |
| 429 | `rate-limited` | "Too many checks from this connection." |
| 503 | `not-configured` | "Order lookup is not switched on yet. Message us on WhatsApp." |

### 🔴 Three rules the app must not break
1. **One answer for every failure.** Unknown code, wrong phone, unreadable record
   — the server deliberately returns the *same* 404 shape for all three so the
   endpoint cannot be used to confirm an order exists. The app must not "improve"
   this by telling the user which field was wrong.
2. **Never show the photos.** The endpoint does not return them and must not be
   made to. The customer already has their photos; the studio has the files.
3. **`stage` is `"received"`, never "printed".** A human still confirms size and
   price. Copy that says "your order is ready" is a lie the shop has to answer for
   at the counter.

---

## 2. `POST /api/upload` (multipart/form-data)

Sends photos at full quality and returns an order code that ties the upload to
the WhatsApp conversation.

### Probe first — always
`GET /api/upload` returns:
```json
{ "ok": true, "configured": true, "notify": true,
  "maxFiles": 40, "maxPerFileMb": 25, "maxTotalMb": 200 }
```
`503` means the R2 bucket is not bound. **If the probe fails, hide the upload
entry point entirely.** The website's rule, and it is the right one: never show a
working upload box that cannot deliver. A customer who believes their photos are
in and finds out they are not has lost something that cannot be given back.

### Fields
| Field | Notes |
|---|---|
| `photos` | repeated. The field name is exactly `photos` (not `photos[]`) |
| `name` | ≤80 chars |
| `phone` | ≤40 chars |
| `email` | ≤120, optional |
| `note` | ≤1000 chars |
| `product` | ≤60 — family key, e.g. `canvas` |
| `size` | ≤60 — size key, e.g. `canvas-40x60` |
| `qty` | ≤10 |
| `lang` | `en` or `am` |
| `website` | **honeypot — must always be sent EMPTY.** Bots fill it. Filling it returns a fake success and stores nothing. |

### Limits (all enforced server-side, mirror them client-side for UX only)
- ≤ **40 files** per submission
- ≤ **25 MB** per file
- ≤ **200 MB** total
- ≤ **6 submissions per IP per day**
- Allowed: jpeg, png, webp, heic, heif, tiff, avif

### Success
```json
{ "ok": true, "code": "NOR-ABC123", "stored": 12, "bytes": 48210432, "notified": true }
```
**The code is the only thing the customer needs to keep.** Surface it big, make it
copyable, and offer the WhatsApp handoff in the same breath.

### Failure reasons
`not-configured` · `bad-body` · `no-files` · `too-many` · `too-big` ·
`bad-type` · `too-heavy` · `rate-limited`

Each maps to one plain sentence and a WhatsApp fallback. The photos are still on
the customer's phone when an upload fails — say that, because it is the thing they
are actually worried about.

---

## Client rules

- **Timeout: 15s on GET, 60s+ on POST.** Uploads are large and Ethiopian mobile
  data is not fast. A 15s upload timeout will fail real customers with real photos.
- **Progress is mandatory on upload.** Silent waiting reads as frozen.
- **Never block the UI on the network.** The quote, prices, tiers, holiday
  deadlines and delivery dates are all computed locally from `lib/core/*`. Only
  lookup and upload touch the network. The app must be fully useful offline, with
  network features clearly absent rather than broken.
- **Retry once on transport failure, never on 4xx.** A 400 will fail again.
