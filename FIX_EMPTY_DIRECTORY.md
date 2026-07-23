# Fix empty Home / Search / Browse (permissions)

Your screenshot error **“Missing or insufficient permissions”** means Firestore blocked the app.  
You do **not** need to add new restaurant data by hand — the app already has ~150 places in `pilot_seed.json`.

## How data is fetched (correct path)

```
pilot_seed.json  (already in the app)
        ↓
  SeedService tries to upload → Firestore
        ↓
  App reads Firestore if allowed
        ↓
  If Firestore fails → show bundled seed anyway
```

## What you must do in Firebase (2 minutes)

### 1. Publish rules
Firebase Console → **Firestore** → **Rules** → paste contents of repo file `firestore.rules` → **Publish**

### 2. Enable Anonymous Auth
Firebase Console → **Authentication** → **Sign-in method** → **Anonymous** → Enable

### 3. On Mac
```
git pull
```
Clean build (⇧⌘K) → Run (⌘R)

You should see Indiranagar restaurants on Home under **In Indiranagar**, and Hotels under Browse.

## Do you need to add new data?
**No** for Phase 1 pilot. Seed already includes dosa places, hotels, cafes, etc.

Only add more later by editing `HeyEcho/Data/Seed/pilot_seed.json` or Firestore Console — not required to fix this blank screen.
