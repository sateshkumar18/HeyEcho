# Firebase Setup — HeyEcho Phase 1

Do these steps **in order**. Console work can be done on any computer; running the iOS app needs a **Mac + Xcode**.

| Mode | When | Data |
|------|------|------|
| **Local** | No `GoogleService-Info.plist` | Device only |
| **Firebase (cloud)** | Plist added + steps below done | Auth + Firestore |

---

## Step 1 — Create the Firebase project

1. Open [Firebase Console](https://console.firebase.google.com) and sign in with Google.
2. Click **Create a project** (or **Add project**).
3. Name: `HeyEcho` (or any name you like).
4. Google Analytics: optional (Off is fine for Phase 1).
5. Click **Create project** → wait → **Continue**.

---

## Step 2 — Register the iOS app

1. On the project overview, click the **iOS** icon (or Project settings → Your apps → Add app → iOS).
2. Fill in:
   - **Apple bundle ID:** `com.heyecho.india.phase1` ← must match Xcode exactly  
   - App nickname: `HeyEcho` (optional)  
   - App Store ID: leave blank for now  
3. Click **Register app**.
4. Download **`GoogleService-Info.plist`**.
5. Click through to finish (you can skip the sample code screens).

### Put the plist in the Xcode project (on Mac)

1. Open `HeyEcho.xcodeproj` in Xcode.
2. Drag `GoogleService-Info.plist` into the **`HeyEcho`** folder in the left sidebar.
3. Check:
   - ✅ Copy items if needed  
   - ✅ Add to target: **HeyEcho**  
4. Build (**⌘B**).  
5. Run the app → **Profile** tab → Backend should show **Firebase (cloud)** (not Local).

> Do **not** commit this plist to a public GitHub repo (it is already in `.gitignore`).

---

## Step 3 — Enable Phone Authentication

1. Firebase Console → **Build** → **Authentication**.
2. Click **Get started** (if first time).
3. **Sign-in method** tab → **Phone** → **Enable** → **Save**.
4. Still under Authentication → **Sign-in method** → scroll to **Phone numbers for testing**:
   - Phone: `+91 98765 43210` (or your test number)  
   - Code: `123456`  
   - Add  

Use that number + `123456` in the app on Simulator (no real SMS).

> Real SMS to real phones usually needs the **Blaze** (pay-as-you-go) plan. Test numbers work on the free Spark plan.

---

## Step 4 — Create Firestore

1. Console → **Build** → **Firestore Database**.
2. **Create database**.
3. Start in **test mode** for the first seed (you will lock rules in Step 6).
4. Location: prefer **`asia-south1` (Mumbai)** for India.
5. **Enable**.

---

## Step 5 — Seed data (while still in test mode)

Clients cannot write `businesses` / `contacts` after production rules are published. Seed **now** (or use Debug auto-seed once before locking rules).

### A) Recommended: Debug auto-seed (easiest)

1. Keep Firestore in **test mode** for a moment.
2. Add the plist, run the app on Simulator/device.
3. Sign in with the **test phone** + OTP `123456`.
4. Finish onboarding.
5. In Console → Firestore you should see:
   - `contacts` (pilot people)  
   - `businesses` (demo listings)  
   - `users/{your-uid}`  

### B) Manual: create `config/app` (dynamic cities + ranking)

1. Firestore → **Start collection** → Collection ID: `config`
2. Document ID: `app`
3. Fields:

| Field | Type | Example value |
|-------|------|----------------|
| `foodCities` | array | `"Indiranagar, Bengaluru"`, `"Koramangala, Bengaluru"`, `"Bandra West, Mumbai"`, … |
| `gotoWeight` | number | `3` |
| `cityBoost` | number | `1` |
| `defaultFoodCity` | string | `Indiranagar, Bengaluru` |

If you skip this doc, the app still works with built-in multi-city fallbacks.

### C) Add more businesses anytime

Collection: `businesses` → documents with fields:

- `name` (string)  
- `neighborhood` (string)  
- `city` (string)  
- `categories` (array of strings)  
- `shortDescription` (string)  
- `priceLevel` (number 1–4)  
- `perfectFor` (array)  
- `recommendedByContactIds` (array of contact ids, e.g. `u1`)  
- `imageSymbol` (string, SF Symbol name e.g. `fork.knife`)  
- `address` (string)  
- `hours` (string)  

Same idea for `contacts`: `name`, `phone`, `isOnHeyEcho`, `knownFor`, `avatarHue`.

---

## Step 6 — Publish production security rules

1. Open `firestore.rules` in this repo.
2. Console → Firestore → **Rules** tab.
3. Replace everything with the file contents.
4. Click **Publish**.

After this:

- App can **read** `contacts`, `businesses`, `config`
- App can **read/write only** its own `users/{uid}` and `collections`
- App **cannot** change the business directory (you edit those in Console)

---

## Step 7 — Packages in Xcode (already in this repo)

This project already includes Firebase via Swift Package Manager. If packages fail to resolve:

1. File → **Packages** → **Resolve Package Versions**
2. Or add: `https://github.com/firebase/firebase-ios-sdk`  
   Products: **FirebaseAuth**, **FirebaseFirestore**

---

## Step 8 — Verify it works

1. Run the app (Mac + Xcode).
2. Sign up: name + test phone + OTP.
3. Allow Contacts (optional for matching).
4. Pick city → pick GoTo’s → finish.
5. In Firebase Console → Firestore:
   - `users/{uid}` exists  
   - Favoriting a place updates `favoriteBusinessIds`  
6. Profile tab shows **Firebase (cloud)**.

---

## Schema (Phase 1)

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

config/app
  foodCities, gotoWeight, cityBoost, defaultFoodCity
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Still **Local** mode | Plist missing, wrong folder, or not in target **HeyEcho** |
| OTP fails | Use Console test number; Phone provider enabled |
| Permission denied | Rules published before seed — temporarily allow writes or re-seed in Console |
| Empty businesses | Seed while in test mode, or add docs manually in Console |
| Real SMS fails | Upgrade to Blaze, or keep using test numbers |

---

## Quick checklist

- [ ] Firebase project created  
- [ ] iOS app registered with bundle `com.heyecho.india.phase1`  
- [ ] `GoogleService-Info.plist` in Xcode target  
- [ ] Phone Auth enabled + test number  
- [ ] Firestore created (`asia-south1`)  
- [ ] Seeded `contacts` + `businesses` (Debug run or Console)  
- [ ] Optional `config/app`  
- [ ] Production `firestore.rules` published  
- [ ] App Profile shows **Firebase (cloud)**  
