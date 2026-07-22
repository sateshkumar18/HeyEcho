# Firebase Setup — HeyEcho Phase 1 (Dynamic)

This app supports two modes:

| Mode | When | Data |
|------|------|------|
| **Local** | No `GoogleService-Info.plist` | Device only (`UserDefaults` + seed) |
| **Firebase (cloud)** | Plist added + Console configured | Auth + Firestore |

Follow these steps to go **production-dynamic**.

---

## 1. Create a Firebase project

1. Open [Firebase Console](https://console.firebase.google.com)
2. **Add project** → name it `HeyEcho` (or similar)
3. Disable Google Analytics if you want (optional)

## 2. Add an iOS app

1. Project settings → **Add app** → iOS  
2. Bundle ID must match Xcode:

   `com.heyecho.india.phase1`

3. Download **`GoogleService-Info.plist`**
4. Drag it into the Xcode project under the `HeyEcho` folder  
   - ✅ Copy items if needed  
   - ✅ Target: **HeyEcho**

5. Rebuild (**⌘B**). Profile → Backend should show **Firebase (cloud)**.

## 3. Enable Phone Authentication

1. Console → **Build → Authentication → Sign-in method**
2. Enable **Phone**
3. For Simulator testing, add a **Phone test number**:
   - Example: `+91 98765 43210`
   - Code: `123456`
4. Use that number + code in the app (no real SMS needed)

> Real SMS usually needs the **Blaze** (pay-as-you-go) plan. Test numbers work on Spark.

## 4. Create Firestore

1. Console → **Build → Firestore Database**
2. **Create database** → start in **test mode** (dev only), pick a region (e.g. `asia-south1`)
3. After first successful login + onboarding, the app auto-seeds:
   - `contacts` (10 pilot people)
   - `businesses` (10 Indiranagar listings)
4. User data lands in:
   - `users/{uid}`
   - `collections/{id}` (with `ownerId`)

## 5. Security rules (before real users)

Replace test-mode rules with the contents of `firestore.rules` in this repo, then **Publish**.

## 6. Add Firebase packages in Xcode (if missing)

1. File → **Add Package Dependencies…**
2. URL: `https://github.com/firebase/firebase-ios-sdk`
3. Add products:
   - `FirebaseAuth`
   - `FirebaseFirestore`
4. Attach to target **HeyEcho**

## 7. Verify data in Console

1. Sign up in the app (name + test phone + OTP)
2. Finish onboarding
3. Console → **Firestore** → open `users`, `businesses`, `contacts`
4. Toggle a favorite → refresh the user document → see `favoriteBusinessIds` update

---

## Collections schema (Phase 1)

```
users/{uid}
  name, phone, foodCity, knownFor, gotoIds,
  favoriteBusinessIds, collectionIds, hasCompletedOnboarding

contacts/{id}
  name, phone, isOnHeyEcho, knownFor, avatarHue

businesses/{id}
  name, neighborhood, city, categories, shortDescription,
  priceLevel, perfectFor, recommendedByContactIds,
  imageSymbol, address, hours

collections/{id}
  ownerId, title, ownerName, businessIds, note
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Still “Local” mode | Plist not in target membership |
| OTP fails | Use Console test number; check Phone provider enabled |
| Empty businesses | Kill app & relaunch after Auth works; seed runs when `businesses` is empty |
| Permission denied | Publish `firestore.rules` or temporarily use test mode |
