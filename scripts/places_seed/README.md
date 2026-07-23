# Places seed — one-time Google Places → pilot_seed.json
#
# Correct production pattern for HeyEcho Phase 1:
#   App reads bundled JSON → uploads to Firestore once.
#   iOS never calls Google Places at runtime.

## Why this script exists

SOW needs **100–200 real listings**. Hand-curated names work for demos;
Places API gives production-grade names, addresses, and coordinates.

| Approach | Use? |
|----------|------|
| One-time seed script (this folder) | **Yes** — pilot / directory bootstrap |
| Live Places search inside the iOS app | **No** for Phase 1 — costs grow fast |

## Cost (2026 Places API New)

- Billing **must** be enabled to use free quota.
- Prefer **Text Search Pro** fields only → ~**5,000 free calls / month**.
- This script’s field mask stays on Pro (no `rating`, `priceLevel`, `regularOpeningHours`, `editorialSummary`).
- A full Bengaluru seed is typically **~40–80 calls** (well under free Pro quota).
- Set a **budget alert** (e.g. $5–10) in Google Cloud before first run.

## Google Cloud setup (once)

1. Create / open a GCP project (can be the same as Firebase or separate).
2. Enable **Places API (New)** — not only the legacy Places API.
3. Enable **billing**.
4. Budgets & alerts → create a monthly budget + email alert.
5. Credentials → API key → restrict to **Places API (New)** (and optionally your IP).
6. Copy `.env.example` → `.env` and set `GOOGLE_PLACES_API_KEY`.

## Run

```powershell
cd c:\Users\SateshKumarReddy\Desktop\HeyEcho
copy scripts\places_seed\.env.example scripts\places_seed\.env
# edit .env with your key

python scripts\places_seed\seed_from_places.py --dry-run
python scripts\places_seed\seed_from_places.py --target 150
```

Options:

- `--target 150` — stop around this many unique places
- `--restaurants 120 --hotels 30` — soft mix
- `--max-pages 2` — pages per query (20 results/page)
- `--dry-run` — fetch + print; don’t overwrite `pilot_seed.json`

Outputs:

- Updates `HeyEcho/Data/Seed/pilot_seed.json` (contacts + config preserved)
- Writes `places_raw_cache.json` (gitignored) including `googlePlaceId` for audit

## After seeding

1. Commit `pilot_seed.json` (not `.env`, not raw cache).
2. On Mac: `git pull` → run app → sign in → `SeedService` upserts into Firestore if count is low.
3. To force re-upload: delete Firestore `businesses` collection, relaunch.

## Hard rules

- Do **not** add Places calls to Swift / Firebase Functions for Phase 1 search.
- Do **not** request Enterprise field masks “just in case”.
- Refresh the seed periodically if you keep Google-sourced fields long-term (Places caching terms).
