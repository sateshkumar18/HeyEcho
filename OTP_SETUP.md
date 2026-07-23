# OTP / Auth — Phase 1 (fixed)

## Real problem (found)

Firebase **Phone Auth** on iOS Simulator often **never returns** (reCAPTCHA / APNs).
That left the app stuck on **Sending OTP…**.

## What we do now (correct for Phase 1)

1. **Send OTP** → instant (no Firebase Phone Auth wait)
2. Enter **`123456`**
3. **Verify** → Firebase **Anonymous** sign-in (so Firestore works)
4. Continue onboarding

Real SMS Phone Auth = later (Blaze + device + APNs).

## Firebase Console checklist

1. **Firestore** created (you already did — empty is OK)
2. **Authentication → Sign-in method → Anonymous → Enable**  
   (needed so Verify can create a cloud user)
3. Publish rules from repo file `firestore.rules`  
   (Rules → Edit → paste → Publish)
4. Phone provider can stay enabled, but app no longer waits on it for Phase 1

## App test steps

1. Xcode → **Clean Build Folder** (⇧⌘K) → **Run**
2. Name + phone → **Send OTP** (OTP field appears immediately, prefilled `123456`)
3. **Verify & continue** → next onboarding step
4. After finish, check Firestore for `users/{uid}` and seeded `businesses` / `contacts`
