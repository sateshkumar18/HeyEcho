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
- Food city + up to 5 Personal GoTo’s
- Trust-ranked Home / Search / Browse
- Static → seeded cloud business profiles
- Favorites + Collections synced to Firestore
- Profile shows current backend mode

## Project layout

| Path | Role |
|------|------|
| `HeyEcho/Data/AppState.swift` | App logic + local/cloud persistence |
| `HeyEcho/Data/Firebase/` | Auth, Firestore, seed |
| `HeyEcho/Data/StaticData.swift` | Pilot seed (also uploaded to Firestore once) |
| `firestore.rules` | Security rules to paste in Console |

## Bundle ID

`com.heyecho.india.phase1` — must match the iOS app in Firebase Console.
