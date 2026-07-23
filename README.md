# HeyEcho (India) — Phase 1

Trust-based local food discovery iOS app. Phase 1 supports **local mode** and **Firebase cloud mode**.

## Open in Xcode

1. Install **Xcode** (full app).
2. Open:

```
/Users/eorigami/Projects/HeyEcho/HeyEcho.xcodeproj
```

3. Let Swift packages resolve (Firebase Auth + Firestore).
4. Select an **iPhone simulator** → **⌘R**.

## Backend modes

| Mode | Condition | Behavior |
|------|-----------|----------|
| Local | No `GoogleService-Info.plist` | Device storage + seed data; OTP `123456` |
| Firebase | Plist added + Console setup | Real Auth + Firestore; data visible in Console |

**Go live:** follow [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md).

## Phase 1 features

- Phone/OTP onboarding (Firebase Auth when cloud)
- Food city + up to 5 Personal GoTo’s (matched from **device contacts**)
- Trust-ranked Home / Search / Browse (GoTo weight + city boost)
- Static → seeded cloud business profiles
- Favorites + Collections (create / edit / delete) synced to Firestore
- Profile: edit GoTo’s and known-for tags; shows current backend mode

**Production checklist:** [`PHASE1_PRODUCTION.md`](PHASE1_PRODUCTION.md)  
**Directory seed:** [`DATA_SEED.md`](DATA_SEED.md) · **Add places in Console:** [`ADD_BUSINESS.md`](ADD_BUSINESS.md)  
**Contacts / privacy (DPDP-minded):** [`CONTACTS_DATA_HANDLING.md`](CONTACTS_DATA_HANDLING.md)  
**Go live:** follow [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md).

## Trust ranking (Phase 1) — dynamic

Weights load from Firestore `config/app` (`gotoWeight`, `cityBoost`). Defaults if missing:

| Signal | Default weight |
|--------|----------------|
| Personal GoTo recommends the place | +3 each |
| Business matches selected food city | +1 |
| Tie-break | Name A→Z |

Food cities and business listings are also dynamic (remote config + Firestore directory). Results prefer the user’s selected city when matches exist.

## Project layout

| Path | Role |
|------|------|
| `HeyEcho/Data/AppState.swift` | App logic + local/cloud persistence |
| `HeyEcho/Data/Firebase/` | Auth, Firestore, seed |
| `HeyEcho/Data/StaticData.swift` | Pilot seed (also uploaded to Firestore once) |
| `firestore.rules` | Security rules to paste in Console |

## Bundle ID

`com.heyecho.india.phase1` — must match the iOS app in Firebase Console.
