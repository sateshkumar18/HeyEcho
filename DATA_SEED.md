# Phase 1 data — Firebase real locations (production path)

## Correct architecture

```
Google Places (one-time ops script)
        ↓
pilot_seed.json (bundled in app)
        ↓
SeedService → Firestore businesses / contacts / config
        ↓
iOS app reads Firestore (cloud mode)
```

| Source | Role |
|--------|------|
| `scripts/places_seed/` | **One-time** Places API (New) Text Search → regenerates seed JSON |
| `HeyEcho/Data/Seed/pilot_seed.json` | Bundled restaurants + hotels + contacts + config |
| `SeedService` | Uploads into Firebase when directory is thin |
| Firestore | **Runtime source of truth** in cloud mode |

**Do not** call Google Places from the iOS app for Phase 1 search/autocomplete.

## Places free tier (Option B — usable for seed)

As of 2026 pricing:

- Flat $200 credit is gone; each SKU has its own free monthly threshold.
- **Text Search Pro** ≈ **5,000 free calls / month** (enough for a one-time 100–200 place seed).
- Billing must still be **enabled** to use free quota.
- Set a **budget alert** before first run.
- Keep the field mask on **Pro** fields only (this repo’s script does). Enterprise fields (`rating`, `priceLevel`, hours, `editorialSummary`) burn a smaller free pool and cost more.

Full steps: `scripts/places_seed/README.md`

```powershell
copy scripts\places_seed\.env.example scripts\places_seed\.env
# set GOOGLE_PLACES_API_KEY
python scripts\places_seed\seed_from_places.py --dry-run
python scripts\places_seed\seed_from_places.py --target 150
```

## What you do on Mac / Console

1. Enable **Anonymous** Auth (Phase 1 OTP path)  
2. Publish `firestore.rules`  
3. `git pull` → Run app → Verify with code `123456`  
4. Firestore should show ~**100–150** `businesses` after seed upsert  

To force a full re-seed: delete the `businesses` collection, then relaunch once.

## Grow / refresh directory

Prefer re-running the Places script (or editing Console) over hard-coding. Target from SOW: **100–200** listings for the pilot area.
