# Phase 1 — Production Completion Checklist

Use this before calling Phase 1 “done” and starting Phase 2.

## What’s now in the app (code)

- [x] Phone verification onboarding (cloud session + fixed pilot code `123456`)
- [x] Food city selection (multi-metro, remote-tunable)
- [x] **Real Contacts import** + phone match against HeyEcho directory
- [x] Up to 5 Personal GoTo’s **plus pending GoTo + share invite**
- [x] Thin-network fallback — suggest local experts when the graph is thin
- [x] “What are you a GoTo for?” tagging (shared taxonomy)
- [x] Home / Search / Browse with **trust ranking** (GoTo weight + city boost)
- [x] Production directory seed: **~150** Bengaluru restaurants + hotels (real names/addresses)
- [x] **Places API one-time seed script** (`scripts/places_seed`) — not a live in-app dependency
- [x] Business tips (free text, **no stars**) synced to Firestore `tips`
- [x] Favorites + collections (create / edit / delete / remove place)
- [x] Edit GoTo’s + known-for from Profile after onboarding
- [x] Locked Firestore rules (directory read-only for clients; tips auth’d)
- [x] Demo “Replay onboarding” **Debug-only**; backend status **Debug-only**
- [x] Production copy (no “test / Phase 1 demo / Blaze” language in Release UI)
- [x] `NSContactsUsageDescription` for App Store privacy

## Ops you must complete (cannot be done from code alone)

### 1. Pilot decisions (SOW §9) — **dynamic, not locked**

| Setting | How it works | Your action |
|---------|--------------|-------------|
| Food cities | Remote list ∪ cities in live listings | Keep adding businesses in Console |
| Trust ranking | `gotoWeight` + `cityBoost` from `config/app` | Optional edit in Firestore |
| Directory size | Firestore `businesses` / `contacts` | App upserts seed until count ≥ bundled size (~150) |

### 2. Firebase cloud

1. Project + iOS app bundle `com.heyecho.india.phase1`
2. `HeyEcho/GoogleService-Info.plist`
3. Enable **Anonymous** Auth (Phase 1 session after code verify)
4. Publish `firestore.rules` (includes `tips`)
5. Relaunch app so seed upserts restaurants + hotels if collection is thin
6. Follow `FIREBASE_SETUP.md` / `OTP_SETUP.md`

### 3. TestFlight / App Store

1. Signing Team in Xcode
2. 1024×1024 App Icon
3. Archive → TestFlight
4. App Privacy: Contacts, Phone

### 4. Pilot acceptance tests

- [ ] Verify phone → continue into city / GoTo’s
- [ ] Contacts match + pending invite share
- [ ] Local experts appear when few GoTo’s
- [ ] Home ranks trusted restaurants/hotels
- [ ] Write a tip on a business; see it after relaunch (cloud)
- [ ] Favorite + collections persist
- [ ] Release build: no Replay onboarding / backend debug strip

## Explicitly out of scope until Phase 2+

Community GoTo’s, Ask a GoTo chat, business owner portal, social OAuth, growth notifications, offers, post-visit surveys, in-app ordering.
