# Phase 1 data — Firebase real locations

## Why static existed before

Static lists were a **demo / offline fallback** so the UI worked before Firestore had data.  
Updated SOW requires a **seeded business directory (100–200 listings)** stored in the backend.

## What we do now

| Source | Role |
|--------|------|
| `HeyEcho/Data/Seed/pilot_seed.json` | Bundled **100 real Bengaluru places** + contacts + config (addresses + lat/lng) |
| `SeedService` | On first login (or if Firestore has fewer than 100 businesses), **uploads into Firebase** |
| Firestore `businesses` / `contacts` / `config/app` | **Source of truth** while the app runs in cloud mode |
| Static / bundled JSON | Used only for **local mode** (no plist) or as the seed file to upload |

Cloud mode **does not** keep showing fake static overlays after Firestore loads.

## Updated SOW notes (HeyEcho_SOW (1).pdf)

Still Phase 1: trust-ranked discovery + seeded directory.  
**New Phase 1 items in SOW v2:** tips (no stars), pending-GoTo invites, thin-network Community GoTo fallback — those are next feature work; this change completes the **real Firebase directory**.

## What you do on Mac / Console

1. Enable **Anonymous** Auth (for current Phase 1 OTP path)  
2. Publish `firestore.rules` (signed-in read/write for directory during pilot)  
3. `git pull` → Run app → Verify OTP  
4. Open Firestore → you should see ~**100** `businesses`, `contacts`, `config/app`  

To force a full re-seed: delete the `businesses` collection in Console, then relaunch the app once.

## Grow beyond 100

Edit `pilot_seed.json` (or add docs in Console) with more real places. Any city works — the app filters by the user’s food city. Target from SOW: **100–200** for the pilot area.
