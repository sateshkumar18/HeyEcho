# OTP / Phone Auth Setup — HeyEcho

Firebase Phone Auth works in **two modes**. For Phase 1 development, use **test numbers**.

---

## Mode A — Test OTP (recommended now)

No SMS is sent. You type a fixed code from Firebase Console. Works on Simulator + free Spark plan.

### 1. Firebase Console

1. Open [heyecho-56838](https://console.firebase.google.com/project/heyecho-56838/authentication/providers)
2. **Authentication** → **Sign-in method** → **Phone** → **Enable** → Save
3. Same page → **Phone numbers for testing** → **Add phone number**

| Field | Value |
|-------|--------|
| Phone number | `+919390217816` (or `+919876543210`) |
| Verification code | `123456` |

> Format must be E.164: `+91` + 10 digits, **no spaces** in Console (spaces in the app UI are OK — we normalize).

### 2. In the app

1. Name: anything  
2. Phone: `9390217816` or `+91 93902 17816` (must match the test entry)  
3. Tap **Send OTP**  
4. **No SMS will arrive** — that is correct  
5. Enter code: `123456`  
6. Continue onboarding  

### If Send OTP hangs / OTP field never appears

1. Confirm the number is listed under **Phone numbers for testing** exactly as `+919390217816`
2. Pull latest code (includes `AppDelegate` for Phone Auth / reCAPTCHA callbacks)
3. Rebuild the app, tap **Send OTP** again — button should show **Sending OTP…**
4. When send succeeds, the **OTP code** field appears
5. If an error shows in red under the form, fix that message (test number / network / reCAPTCHA)

On Simulator, Firebase may briefly open a reCAPTCHA browser for non-test numbers. Test numbers should skip SMS and return quickly.

---

## Mode B — Real SMS (later)

Real OTPs to real phones need:

1. **Blaze** plan (pay-as-you-go) on Firebase  
2. Prefer a **physical iPhone** (Simulator is unreliable for SMS)  
3. **APNs key** uploaded in Firebase → Project settings → Cloud Messaging (for silent push verification)  
4. Phone Auth enabled (same as above)  
5. Do **not** list that real number under “Phone numbers for testing” (test entries never send SMS)

Until Blaze + APNs are done, keep using Mode A.

---

## App status (already done in code)

- [x] Firebase Auth + Phone provider code (`AuthService`)  
- [x] `GoogleService-Info.plist` for project `heyecho-56838`  
- [x] Phone Auth URL scheme in `Info.plist`  
- [x] E.164 formatting for Indian numbers (+91)  

---

## Quick test checklist

- [ ] Phone Auth enabled in Console  
- [ ] Test number `+919390217816` + code `123456` added  
- [ ] App shows **Firebase (cloud)** on Profile  
- [ ] Sign in with that number → enter `123456` → succeeds  

That’s a complete OTP setup for Phase 1.
