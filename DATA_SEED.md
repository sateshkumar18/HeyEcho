# Phase 1 data — Firebase real locations (production path)

## Primary plan (what we use now)

**No paid Google Places.** Use the bundled curated seed:

```
pilot_seed.json (~150 Bengaluru restaurants + hotels)
        ↓
SeedService → Firestore businesses / contacts / config
        ↓
iOS app reads Firestore (cloud mode)
```

| Source | Role |
|--------|------|
| `HeyEcho/Data/Seed/pilot_seed.json` | Source of truth for pilot listings |
| `SeedService` | Uploads into Firebase when directory is thin |
| Firestore | **Runtime source of truth** in cloud mode |

## What you do on Mac / Console

1. Enable **Anonymous** Auth (Phase 1 OTP path)  
2. Publish `firestore.rules`  
3. `git pull` → Run app → Verify with code `123456`  
4. Firestore should show ~**150** `businesses` after seed upsert  

To force a full re-seed: delete the `businesses` collection, then relaunch once.

## Grow the directory later

- Edit `pilot_seed.json` and commit, or  
- Add / edit docs in Firebase Console  

Target from SOW: **100–200** listings for the pilot area.

## Optional later (not required)

- Google Places one-time script: `scripts/places_seed/` — needs Cloud billing  
- Skip until billing is available; current seed is enough for Phase 1 production
