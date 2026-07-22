# Phase 1 — Production Completion Checklist

Use this before calling Phase 1 “done” and starting Phase 2.

## What’s now in the app (code)

- [x] Phone/OTP onboarding (Firebase or local `123456`)
- [x] Food city selection (Bengaluru pilot neighborhoods)
- [x] **Real Contacts import** + phone match against HeyEcho directory
- [x] Up to 5 Personal GoTo’s
- [x] “What are you a GoTo for?” tagging (shared taxonomy)
- [x] Home / Search / Browse with **trust ranking** (GoTo weight + city boost)
- [x] City-filtered discovery with fallback if empty
- [x] Static business profiles + favorites + collections (create / edit / delete / remove place)
- [x] Edit GoTo’s + known-for from Profile after onboarding
- [x] Locked Firestore rules (directory read-only for clients)
- [x] Client directory seeding **Debug-only**
- [x] Demo “Replay onboarding” **Debug-only**
- [x] OTP resend + empty search/browse states
- [x] `NSContactsUsageDescription` for App Store privacy

## Ops you must complete (cannot be done from code alone)

### 1. Pilot decisions (SOW §9) — **dynamic, not locked**

These are **not** fixed product decisions anymore. They load from Firestore `config/app` (+ live `businesses`), with offline fallbacks only.

| Setting | How it works | Your action |
|---------|--------------|-------------|
| Food cities | User picks any city from remote list ∪ cities found in live listings | Keep adding businesses for any city/neighborhood in Console |
| Trust ranking | `gotoWeight` + `cityBoost` from `config/app` (change anytime, no app release) | Optional: create/edit `config/app` in Firestore |
| Seed / directory size | Whatever you put in Firestore `businesses` / `contacts` | Grow from demo → 100+ whenever ready; no code change |

Example `config/app` document fields:

```
foodCities: ["Indiranagar, Bengaluru", "Koramangala, Bengaluru", …]
gotoWeight: 3
cityBoost: 1
defaultFoodCity: "Indiranagar, Bengaluru"
```

If the doc is missing, the app uses built-in multi-metro fallbacks and still works.

### 2. Firebase cloud

1. Create project + iOS app with bundle `com.heyecho.india.phase1`
2. Add `HeyEcho/GoogleService-Info.plist` (gitignored)
3. Enable Phone Auth (+ test numbers for Simulator)
4. Create Firestore (`asia-south1` recommended)
5. **Import seed** `contacts` + `businesses` via Console (client writes are denied by production rules)
6. Publish rules from `firestore.rules`
7. Follow `FIREBASE_SETUP.md`

### 3. TestFlight / App Store

1. Set **Signing & Capabilities → Team** in Xcode (`DEVELOPMENT_TEAM`)
2. Add **1024×1024 App Icon** in `Assets.xcassets/AppIcon`
3. Archive → Upload → TestFlight
4. App Privacy: Contacts (matching GoTo’s), Phone Auth

### 4. Pilot acceptance tests

- [ ] Sign up with real/test OTP on device
- [ ] Allow Contacts → matched friends appear; unmatched listed as invite later
- [ ] Select 1–5 GoTo’s → Home shows “Recommended by…”
- [ ] Search / Browse rank trusted places first; city filter works
- [ ] Favorite + collection create/edit/delete persist after relaunch
- [ ] Cloud: data visible in Firestore `users` / `collections`
- [ ] Release build: no “Replay onboarding”; directory not writable by client

## Explicitly out of scope until Phase 2+

Community GoTo’s, Ask a GoTo chat, business owner portal, social OAuth, growth notifications, offers, post-visit surveys, in-app ordering.
