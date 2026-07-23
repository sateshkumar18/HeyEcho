# Phase 1 data — Firebase live directory

## How it works now

```
First cloud login (empty Firestore)
        ↓
  SeedService uploads pilot_seed.json once
        ↓
Firestore businesses / contacts / config  ← source of truth
        ↓
iOS reads Firestore (pull down to refresh)
```

| Source | Role |
|--------|------|
| `pilot_seed.json` | One-time bootstrap + offline fallback |
| Firebase Console `businesses` | **Live catalog** — add restaurants/hotels anytime |
| User profile / tips / collections | Per-user in Firestore |

See **[ADD_BUSINESS.md](ADD_BUSINESS.md)** for exact fields to add a place in Console.

## Ops checklist

1. Publish `firestore.rules`  
2. Enable **Anonymous** Auth  
3. Run app → verify `123456` → first seed uploads ~150 places  
4. Add more places in Console → pull to refresh on Home  

To force re-seed from the bundle: delete Firestore `businesses`, relaunch once.
