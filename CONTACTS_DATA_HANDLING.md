# Contacts Data Handling Spec (HeyEcho India)

**Status:** Spec for implementation (pre–real-user pilot)  
**Scope:** Phone contacts, GoTo matching, pending invites, DPDP-minded retention  
**Not in scope:** Full legal counsel review (still recommended before public launch)

---

## 1. Principles

1. **Non-users did not consent.** Their name/phone must not live in HeyEcho backends “just because they were in someone’s address book.”
2. **Match on-device or via hashes** — never upload a full raw contact book to Firestore.
3. **Ask late, ask clearly** — contacts permission only on the GoTo / invite screen.
4. **Explicit invite only** — one Share tap per person; no bulk auto-SMS.
5. **Retain the minimum** — pending references expire; users can delete their account data.
6. **India-first** — DPDP Act 2023: document purpose, retention, and deletion paths.

---

## 2. Permission UX (iOS)

| Rule | Requirement |
|------|-------------|
| When to ask | Only on **Pick GoTo’s** / Edit GoTo’s — never at cold launch |
| `NSContactsUsageDescription` | Exact purpose: *“To find friends already on HeyEcho and let you invite ones who aren’t. We don’t upload your full contact list.”* |
| Denied path | App still works with directory / local experts; show Settings link |
| Re-ask | Don’t nag every session; offer Settings if previously denied |

**Implementation note:** Update `INFOPLIST_KEY_NSContactsUsageDescription` in `project.pbxproj` to the string above.

---

## 3. Matching approach (target architecture)

### 3.1 What registered users store

On successful sign-up / profile save, store on `users/{uid}` only:

| Field | Type | Notes |
|-------|------|--------|
| `phoneE164` | string | e.g. `+919390217816` — **user’s own** number only |
| `phoneHash` | string | `SHA256( phoneE164 + PEPPER )` hex — used for matching |
| `name` | string | Display name |
| `isDiscoverableByContacts` | bool | Default `true`; user can turn off later |

**Pepper:** app/config secret (or Firebase Remote Config / Cloud Function env). Same pepper on all clients that hash. Rotate = rematch all users (document rotation plan).

### 3.2 On-device match flow (no raw upload)

```
1. User grants Contacts
2. Device reads CNContactStore (name + phone only)
3. Normalize each phone → E.164 (+91 for 10-digit IN mobiles)
4. hash = SHA256(e164 + PEPPER)
5. Query backend for which hashes belong to HeyEcho users
   - Preferred: Cloud Function `matchPhoneHashes({ hashes: string[] })`
     returns [{ hash, uid, displayName, knownFor[] }] for hits only
   - Interim pilot: fetch `phoneHash` index docs (see §4) — still no non-user phones on server
6. Matched → selectable GoTo’s (uid = real Firebase uid)
7. Unmatched → invite candidates kept **only in memory / UserDefaults ephemeral**, never as Firestore contact docs
```

### 3.3 Phone normalization (India)

| Input | Output E.164 |
|-------|----------------|
| `9390217816` | `+919390217816` |
| `09390217816` | `+919390217816` |
| `919390217816` | `+919390217816` |
| `+91 93902 17816` | `+919390217816` |

- Match key for hash = full E.164 string (include `+`).  
- Reject non-mobile / too-short numbers for invite/match.  
- Re-run match every time contacts screen opens or user pulls to refresh GoTo’s (friends join over time).

### 3.4 What we stop doing

| Current | Target |
|---------|--------|
| Seed `contacts` collection with raw `phone` for demo people | OK for **synthetic pilot personas** only; label `isSynthetic: true` |
| Upload device contacts to Firestore | **Forbidden** |
| Pending GoTo id `device-{rawDigits}` with phone on user doc forever | Store **hash only** + local display name cache; expire (§6) |

---

## 4. Firestore data model

### 4.1 Collections

#### `users/{uid}` (registered people only)
```
name, phoneE164, phoneHash, knownFor, gotoIds,
pendingGotos: [ { phoneHash, addedAt, displayNameLocal? } ],  // no raw phone
favoriteBusinessIds, collectionIds, isDiscoverableByContacts,
hasCompletedOnboarding, createdAt, updatedAt
```

#### `phoneIndex/{phoneHash}` (lookup index — registered users only)
```
uid: string
displayName: string
knownFor: [string]
updatedAt: timestamp
```
- Written only when a real user registers / updates phone.  
- Deleted on account deletion.  
- **Never** create docs for non-users.

#### `contacts/{id}` (optional — pilot / editorial only)
```
name, phoneHash? or phoneE164?,
isOnHeyEcho, knownFor, avatarHue,
isSynthetic: true,          // seed personas
isLocalExpert: true/false
```
- Prefer migrating seed personas to synthetic-only; real users live in `users` + `phoneIndex`.  
- Do **not** use this collection to dump address books.

#### `inviteEvents/{id}` (rate-limit audit)
```
fromUid, targetPhoneHash, createdAt, channel: "shareSheet"
```
- Used for caps; retain 30–90 days then delete.

### 4.2 Rules sketch (add to `firestore.rules`)

```
match /phoneIndex/{hash} {
  allow read: if request.auth != null;   // or only via Cloud Function
  allow write: if request.auth != null
    && request.resource.data.uid == request.auth.uid;
}

match /inviteEvents/{id} {
  allow create: if request.auth != null
    && request.resource.data.fromUid == request.auth.uid;
  allow read: if request.auth != null
    && resource.data.fromUid == request.auth.uid;
}
```

Prefer **Cloud Function** for hash→user match so clients cannot scrape the full `phoneIndex`.

---

## 5. Retention rules

| Data | Retention |
|------|-----------|
| Device contacts in RAM | Session / until next merge only |
| Local unmatched list (invite UI) | Device only; clear on logout / 7 days idle |
| `pendingGotos[].phoneHash` on user | **90 days** or until target joins / user removes — then delete |
| `inviteEvents` | **30 days** |
| `users` + `phoneIndex` | Until account deletion |
| Synthetic `contacts` seed | Until replaced / pilot ends |
| Analytics of contact counts | Aggregate only (e.g. “matched 3”) — no raw phones |

**Cleanup job (Cloud Scheduler + Function):** daily  
- Expire `pendingGotos` older than 90 days  
- Delete `inviteEvents` older than 30 days  

---

## 6. Pending-GoTo & invite policy

### 6.1 Pending GoTo
- User taps “pending” on an unmatched contact → store `{ phoneHash, addedAt, displayNameLocal }` on **their** user doc only.  
- When target registers with same `phoneHash` → promote to real `gotoIds` (uid); remove pending entry.  
- Auto-expire after **90 days**.

### 6.2 Invite send
- **Only** via system Share sheet after explicit tap (current behavior — keep).  
- Message must not include other contacts’ data.  
- **Rate limits (per uid):**

| Cap | Limit |
|-----|-------|
| Share-sheet opens logged as invite intent | **20 / day** |
| Distinct `targetPhoneHash` invited | **20 / day** |
| Burst | **5 / 10 minutes** |

Exceed → UI: “Daily invite limit reached. Try again tomorrow.”

### 6.3 Never
- Auto-send SMS/WhatsApp to all contacts  
- Pre-check all contacts without user scrolling/selecting  
- Store invite message bodies with recipient PII in Firestore long-term  

---

## 7. Deletion & user rights (DPDP-minded)

### 7.1 In-app: Delete my account / data
Button on Profile (Phase 1.5 / pre-public):

1. Delete `users/{uid}`  
2. Delete `phoneIndex/{phoneHash}`  
3. Delete `collections` where `ownerId == uid`  
4. Delete `tips` where `authorId == uid`  
5. Remove `uid` from all `businesses.recommendedByContactIds` (batch / Function)  
6. Remove `uid` from other users’ `gotoIds` (Function — best effort)  
7. Sign out + clear UserDefaults  

### 7.2 Non-user who was “pending”
They have no account. Mitigation:
- No raw phone in cloud (hash only)  
- Pending expires in 90 days  
- Support email path: “I received an invite / want data removed” → ops deletes matching `inviteEvents` + any pending hashes if identifiable  

Document this in a short Privacy notice before real pilot.

---

## 8. Current app vs this spec (gap list)

| Area | Today | Spec target |
|------|--------|-------------|
| Permission timing | OK (GoTo step) | Keep + clearer string |
| On-device read | Yes | Keep |
| Upload full book | No | Keep forbidden |
| Match method | Raw digits vs seed `contacts` | Hash vs `phoneIndex` / Function |
| Seed `contacts` raw phones | Yes | Synthetic-only or hash |
| Pending storage | `device-{digits}` ids | `phoneHash` + expiry |
| Invite rate limit | None | 20/day + burst |
| Account deletion | None | Full wipe flow |
| Privacy copy | Minimal | Notice + retention summary |

---

## 9. Implementation phases (for builders)

### Phase P0 — before friends & family pilot (required)
1. [ ] Update usage description string  
2. [ ] Stop persisting raw unmatched device phones to any cloud collection (verify no path does)  
3. [ ] Pending GoTo: store hash + `addedAt` only; 90-day client-side drop if no Function yet  
4. [ ] Invite rate-limit in app (UserDefaults counters by day)  
5. [ ] One-page Privacy / contacts notice (markdown or Settings screen)  

### Phase P1 — proper matching
1. [ ] `PhoneNormalizer.e164Indian`  
2. [ ] SHA-256 + pepper hashing  
3. [ ] On register: write `phoneHash` + `phoneIndex` doc  
4. [ ] Match UI uses hash lookup (Function preferred)  
5. [ ] GoTo ids = real `uid`s so **Recommend place** trust graph works  

### Phase P2 — cleanup & compliance hygiene
1. [ ] Scheduled expiry for pending + inviteEvents  
2. [ ] Delete account flow  
3. [ ] Tighten rules; remove client scrape of full `phoneIndex` if exposed  
4. [ ] Legal review of Privacy notice for DPDP  

---

## 10. Pepper & security notes

- Do **not** commit production pepper in git. Use:
  - Xcode config / xcconfig (not for open source), or  
  - Cloud Function-only hashing (best: client sends E.164 over TLS to Function; Function hashes with server pepper and returns matches)  
- Server-side hash avoids pepper in the IPA (preferred for public builds).

**Preferred production match API:**
```
POST /matchContacts
body: { phonesE164: ["+91...", ...] }  // or hashes if pepper in app
auth: Firebase ID token
response: { matches: [{ phoneE164 or hash, uid, displayName, knownFor }] }
```
Function rate-limits by uid; never logs full phone lists.

---

## 11. Acceptance tests

1. Deny contacts → onboarding continues; no crash; experts still available  
2. Allow contacts → matched HeyEcho users appear; unmatched invite-only  
3. Airplane mode after cache → no accidental upload queue of raw contacts  
4. Invite 21st person same day → blocked by rate limit  
5. Pending older than 90 days → removed on refresh  
6. Delete account → `phoneIndex` gone; old GoTo links best-effort cleaned  
7. Firestore `contacts` / `users` audit: **zero** documents that are clearly “someone’s entire address book”  

---

## 12. Relation to “Recommend this place”

Trust ranking needs GoTo ids = **real user uids**.  
Hashed contact matching (this spec) is the prerequisite so friends can select **you**, and your recommendations appear under “Ranked by voices you trust.”

Build order:
1. This contacts/privacy P0–P1  
2. Then **Recommend this place** (arrayUnion uid on business)

---

## Document owners

| Topic | Owner |
|-------|--------|
| iOS matching / UI | App engineer |
| `phoneIndex` + Function + expiry jobs | Backend / Firebase |
| Privacy notice copy | Product + legal review |
| DPDP final sign-off | Legal counsel before public launch |

---

*This spec is the implementation contract. Until P0 is done, limit contact access to the development team only.*
