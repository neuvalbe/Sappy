# Sappy — Backend V2: Cloud Functions Migration Plan

> **Status**: Pre-implementation. Gated on Apple Developer Enrollment.  
> **Trigger**: Enroll in Apple Developer Program → then execute this plan in full.  
> **Author**: Neuval Studio  
> **Last Updated**: 2026-03-31  

---

## 1. Why This Migration Exists

### The problem with today's architecture (V1)

Today, vote counting happens entirely on the client. Both iOS (`TrackingViewModel.swift`) and Web (`ProfileDrawer.tsx`) write directly to `metrics/global_counts` using `FieldValue.increment()` inside a `WriteBatch`.

This means any malicious actor who intercepts Firebase credentials can send:

```swift
batch.updateData([
    "total_happy": FieldValue.increment(Int64(99_999))
], forDocument: docRef)
```

The current `firestore.rules` field whitelist (`total_happy`, `total_sad`, `countries`) and type validation (`is int`) help, but critically they **cannot validate the magnitude of the increment**. A rule like `request.resource.data.total_happy - resource.data.total_happy <= 1` is impractical because the client sends the post-write document, not the delta — and `FieldValue.increment` on the wire bypasses field value inspection entirely.

**The Firestore rules cannot stop `increment(99999)`. Only the server can.**

### The V2 solution

Move all writes to `metrics/global_counts` behind callable Cloud Functions that:

1. Run with the Firebase Admin SDK (bypasses client security rules).
2. Validate the caller's identity server-side (`context.auth`).
3. Enforce business logic the client cannot fake:
   - One vote per UID
   - Only `+1` or `-1` increments are ever applied
   - Mood must be `"happy"` or `"sad"` — nothing else
4. Use Firestore **transactions** (not just batches) to guarantee read-then-write atomicity at the server level, eliminating any concurrency edge cases.

Lock `metrics/` to `allow write: if false` — no client can ever write to it again.

---

## 2. Current Architecture (V1) — Accurate Snapshot

### Data model

```
metrics/global_counts
  ├── total_happy: Int
  ├── total_sad: Int
  └── countries: Map
        └── {CC}: { happy: Int, sad: Int }   ← ISO 3166-1 alpha-2

users/{uid}
  ├── mood: "happy" | "sad" | ""
  ├── country: String
  └── updatedAt: Timestamp
```

### Who writes what today

| Operation | Triggered by | Code location | Writes to |
|---|---|---|---|
| Cast first vote | iOS tap | `TrackingViewModel.vote()` | `metrics/global_counts` + `users/{uid}` |
| Swap vote | iOS tap | `TrackingViewModel.vote()` | `metrics/global_counts` + `users/{uid}` |
| Retract vote (sign-out) | iOS sign-out | `TrackingViewModel.signOut()` → `retractVote()` | `metrics/global_counts` + `users/{uid}` |
| Retract vote (delete account) | iOS settings | `TrackingViewModel.deleteAccount()` → `retractVote()` | `metrics/global_counts` + `users/{uid}` |
| Retract vote (web delete) | Web profile drawer | `ProfileDrawer.handleDeleteAccount()` | `metrics/global_counts` + `users/{uid}` |
| Seed global_counts | iOS startup | `ensureGlobalDocAndListen()` | `metrics/global_counts` |

### Current `firestore.rules` (the problem in detail)

```
match /metrics/{doc} {
  allow read: if true;
  allow write: if request.auth != null
    && request.resource.data.keys().hasOnly(['total_happy', 'total_sad', 'countries'])
    && request.resource.data.total_happy is int
    && request.resource.data.total_sad is int;
}
```

**What this protects against**: Unknown fields, non-integer types.  
**What this does NOT protect against**: `increment(99999)`, a malicious client swapping other users' votes, replay attacks.

### Current Firestore startup self-heal

`ensureGlobalDocAndListen()` in iOS seeds `metrics/global_counts` with `{total_happy: 0, total_sad: 0, countries: {}}` if the doc doesn't exist. In V2, this seeding responsibility moves to a Cloud Function or is done once manually — clients never seed metrics again.

---

## 3. V2 Target Architecture

### Principle

```
Clients (iOS + Web)  →  Cloud Functions  →  Firestore
      ↕ read only                               ↑
      onSnapshot                           Admin SDK writes
```

Clients become **read-only consumers** of `metrics/global_counts`. All mutation routes through two callable functions.

### Two functions

| Function | Callable name | Purpose |
|---|---|---|
| `castVote` | `castVote` | Cast or swap a mood vote |
| `retractVote` | `retractVote` | Remove an existing vote (sign-out / account deletion) |

### Function signatures

```typescript
// castVote
Request:  { mood: "happy" | "sad" }
Response: { success: true }
Errors:   unauthenticated, invalid-argument, internal

// retractVote
Request:  {}  (no payload needed — server reads uid from context)
Response: { success: true }
Errors:   unauthenticated, not-found, internal
```

### Full data flow (V2)

```
iOS: User taps "Happy"
  │
  ▼
TrackingViewModel.vote(mood: .happy)
  │  [No longer writes to Firestore directly]
  ▼
functions.httpsCallable("castVote").call(["mood": "happy"])
  │
  ▼
Cloud Function: castVote
  │  1. Verify context.auth.uid  ─────────────────── reject if missing
  │  2. Validate mood param      ─────────────────── reject if not "happy"|"sad"
  │  3. Firestore.runTransaction():
  │       a. Read users/{uid}    → get previousMood + country
  │       b. Read users/{uid}.country (source of truth for bucketing)
  │       c. If previousMood == mood → no-op, return early
  │       d. Build atomic update to metrics/global_counts:
  │            IF swap:  total_{old} -=1, total_{new} +=1
  │                      countries.{CC}.{old} -=1, countries.{CC}.{new} +=1
  │            IF first: total_{new} +=1, countries.{CC}.{new} +=1
  │       e. Write users/{uid}.mood = newMood, updatedAt = FieldValue.serverTimestamp()
  │       f. Commit transaction
  │  4. Return { success: true }
  │
  ▼
iOS: function call resolves
  │  Update storedMood locally
  ▼
Firestore propagates → onSnapshot → iOS UI + Web UI update
```

---

## 4. Security Rules (V2 Target)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Global metrics — READ-ONLY for all clients.
    // Writes are performed exclusively by Cloud Functions via Admin SDK.
    match /metrics/{doc} {
      allow read: if true;
      allow write: if false;  // ← Admin SDK bypasses this
    }

    // Per-user vote state.
    // Users can read their own doc. Mood field is written by Cloud Functions only.
    // Only "country" and "updatedAt" can be written by the client
    // (for initial onboarding / country update).
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null
        && request.auth.uid == userId
        && request.resource.data.keys().hasOnly(['country', 'updatedAt', 'mood'])
        && !('mood' in request.resource.data.diff(resource.data).affectedKeys());
    }

    // Block everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

> **Note on the `users` write rule**: The rule above blocks clients from writing `mood` directly while still allowing them to set `country` and `updatedAt` during onboarding (which `AuthHelper.swift` does today). The `mood` field will only be writable by the Admin SDK. This is the least-breaking migration path.

---

## 5. Implementation Playbook

> Do these steps in exact order. Each step is gated on the previous one succeeding.

### Step 0 — Prerequisites

- [ ] Apple Developer Enrollment complete
- [ ] Firebase Blaze plan active (required for Cloud Functions)
- [ ] Firebase CLI installed and logged in (`firebase login`)
- [ ] Node.js 20+ installed

### Step 1 — Initialize Cloud Functions

```bash
# From Sappy project root
firebase init functions
# Select: TypeScript, ESLint yes, install deps yes
# Region: europe-west1  (closest to eur3 Firestore)
```

This creates `functions/src/index.ts` and `functions/package.json`.

### Step 2 — Implement `castVote`

```typescript
// functions/src/index.ts

import * as functions from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
const METRICS_DOC = db.collection("metrics").doc("global_counts");

export const castVote = functions.onCall(
  { region: "europe-west1" },
  async (request) => {
    // 1. Auth check
    if (!request.auth) {
      throw new functions.HttpsError("unauthenticated", "Must be signed in.");
    }

    // 2. Validate payload
    const mood = request.data.mood;
    if (mood !== "happy" && mood !== "sad") {
      throw new functions.HttpsError("invalid-argument", "mood must be 'happy' or 'sad'.");
    }

    const uid = request.auth.uid;
    const userRef = db.collection("users").doc(uid);

    // 3. Transaction: read state → compute delta → write atomically
    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      const userData = userSnap.data();

      const previousMood = userData?.mood ?? "";
      const country = userData?.country ?? "";

      // No-op: same mood locked in
      if (previousMood === mood) return;

      const metricsUpdate: Record<string, admin.firestore.FieldValue> = {
        [`total_${mood}`]: admin.firestore.FieldValue.increment(1),
      };
      if (country) {
        metricsUpdate[`countries.${country}.${mood}`] =
          admin.firestore.FieldValue.increment(1);
      }

      // If swapping, decrement old mood
      if (previousMood === "happy" || previousMood === "sad") {
        metricsUpdate[`total_${previousMood}`] =
          admin.firestore.FieldValue.increment(-1);
        if (country) {
          metricsUpdate[`countries.${country}.${previousMood}`] =
            admin.firestore.FieldValue.increment(-1);
        }
      }

      tx.update(METRICS_DOC, metricsUpdate);
      tx.set(
        userRef,
        {
          mood,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    return { success: true };
  }
);
```

### Step 3 — Implement `retractVote`

```typescript
export const retractVote = functions.onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) {
      throw new functions.HttpsError("unauthenticated", "Must be signed in.");
    }

    const uid = request.auth.uid;
    const userRef = db.collection("users").doc(uid);

    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      const userData = userSnap.data();

      const mood = userData?.mood;
      const country = userData?.country ?? "";

      // Nothing to retract
      if (mood !== "happy" && mood !== "sad") return;

      const metricsUpdate: Record<string, admin.firestore.FieldValue> = {
        [`total_${mood}`]: admin.firestore.FieldValue.increment(-1),
      };
      if (country) {
        metricsUpdate[`countries.${country}.${mood}`] =
          admin.firestore.FieldValue.increment(-1);
      }

      tx.update(METRICS_DOC, metricsUpdate);
      tx.set(
        userRef,
        {
          mood: "",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    return { success: true };
  }
);
```

### Step 4 — Update iOS `TrackingViewModel.swift`

Replace the `vote()` and `retractVote()` method bodies. The public API surface stays identical — no other files change.

```swift
// Add import at top
import FirebaseFunctions

// Replace vote() body:
func vote(mood: Mood) {
    let previousMood = currentMood
    guard previousMood != mood else { return }
    guard !isVoteCooldown else { return }
    guard Auth.auth().currentUser != nil else { return }

    isVoteCooldown = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
        self?.isVoteCooldown = false
    }

    let functions = Functions.functions(region: "europe-west1")
    functions.httpsCallable("castVote").call(["mood": mood.rawValue]) { [weak self] _, error in
        if let error {
            print("[Sappy] castVote function failed: \(error.localizedDescription)")
            return
        }
        Task { @MainActor [weak self] in
            self?.storedMood = mood.rawValue
        }
    }
}

// Replace retractVote() body:
private func retractVote(completion: (() -> Void)? = nil) {
    guard currentMood != nil else {
        completion?()
        return
    }
    guard Auth.auth().currentUser != nil else {
        completion?()
        return
    }

    let functions = Functions.functions(region: "europe-west1")
    functions.httpsCallable("retractVote").call([:]) { _, error in
        if let error {
            print("[Sappy] retractVote function failed: \(error.localizedDescription)")
        }
        completion?()
    }
}
```

`ensureGlobalDocAndListen()` stays as-is for now but the `setData` branch that seeds `global_counts` should be removed — the document will always exist once the function deploys. The `attachListener()` path is unchanged.

### Step 5 — Update Web `ProfileDrawer.tsx`

Replace the retract logic in `handleDeleteAccount` to call the function instead of a direct batch write:

```typescript
import { getFunctions, httpsCallable } from "firebase/functions";

const handleDeleteAccount = async () => {
  if (!user) return;
  setIsDeleting(true);
  setError(null);

  try {
    const fns = getFunctions(undefined, "europe-west1");
    const retractFn = httpsCallable(fns, "retractVote");

    // Step 1: Retract active vote via Cloud Function
    await retractFn({});

    // Step 2: Delete Firestore user document
    await deleteDoc(doc(db, "users", user.uid));

    // Step 3: Delete Firebase Auth account (LAST — invalidates token)
    await deleteUser(user);
  } catch (err: any) {
    setIsDeleting(false);
    if (err.code === "auth/requires-recent-login") {
      setError("For security, please sign out, sign back in, then try again.");
    } else {
      setError("Failed to delete account. Please try again.");
    }
    console.error("[Sappy] Delete account error:", err);
  }
};
```

### Step 6 — Deploy in exact order

```bash
# 1. Deploy functions first
firebase deploy --only functions

# 2. Verify in Firebase Console that both functions are live in europe-west1

# 3. Update iOS app — build and test on device

# 4. Update web app
cd web && npm run build
cd ..

# 5. Deploy hardened rules ONLY after functions confirmed working
firebase deploy --only firestore:rules

# 6. Deploy updated web hosting
firebase deploy --only hosting
```

> **Why this order?** Deploying hardened rules first would instantly break V1 clients that haven't been updated yet. Functions-first means the window where both write paths are live simultaneously is zero.

---

## 6. iOS SDK Addition Required

Add `FirebaseFunctions` to `Sappy.xcodeproj`:

- Open `Package Dependencies` in Xcode
- Firebase iOS SDK already added — just tick `FirebaseFunctions` in the target's framework list
- No new Package.resolved changes needed (it ships in the same Firebase iOS SDK bundle)

---

## 7. Bundle ID Change — Impact Assessment

The user will switch Apple IDs before or around this migration. Here is the precise impact:

| Component | Impact | Action Required |
|---|---|---|
| Cloud Functions | **None** | Functions are registered to the Firebase Project (`sappy-caa9e`), not to any bundle ID |
| Firestore rules | **None** | Rules are project-level |
| Firestore data | **None** | Documents are keyed by Firebase Auth UID |
| Firebase Auth (Sign In with Apple) | **Affected** | New bundle ID must be registered in Apple Developer Console and in Firebase Console |
| `GoogleService-Info.plist` | **Download new** | The new bundle ID needs its own iOS app entry in Firebase → new plist |
| Sign In with Apple entitlement | **Update** | Xcode entitlement must match new bundle ID |
| Web companion | **None** | Web client is independent of bundle ID |

**Bottom line**: Backend V2 (`castVote`, `retractVote`, hardened rules) is 100% bundle-ID-agnostic. You can execute the full migration now or after the bundle switch — it does not matter. Do whichever is more convenient.

---

## 8. What This Does NOT Change

| Item | Unchanged in V2 |
|---|---|
| `startSync()` startup flow | Identical — reads user doc, attaches snapshot listener |
| `onSnapshot(metrics/global_counts)` | Identical — real-time reads are not affected by write rules |
| `onSnapshot(users/{uid})` | Identical |
| `deleteAccount()` sequence | Identical call order: retract → deleteDoc → deleteUser |
| `AuthHelper.completeAuthentication()` | Identical — country write at onboarding stays client-side |
| Web read-only behavior | No change — web is already read-only except for account deletion |
| Mood data model | No schema changes required |
| `UserDefaults` caching | No change — still used for fast-launch UX |

---

## 9. Failure Modes & Mitigations

| Failure | V1 behavior | V2 behavior |
|---|---|---|
| Function cold start (rare, ~100ms) | n/a — direct Firestore write | First invocation slightly slower; subsequent calls warm |
| Network failure mid-vote | WriteBatch fails → `storedMood` unchanged (correct) | Function call fails → `storedMood` unchanged (correct) |
| User signs out before batch commits | Token valid during batch, batch succeeds | Token valid for function call duration |
| `increment(99999)` malicious payload | **Possible — rules cannot block delta magnitude** | **Impossible — server enforces ±1 only** |
| Concurrent votes from two devices | WriteBatch is client-atomic; no server-level lock | Firestore `runTransaction` provides server-level optimistic locking |
| Function throws after metrics update but before user doc update | Transaction rolls back entirely | No partial state possible |

---

## 10. Files Changed Summary

| File | Change |
|---|---|
| `functions/src/index.ts` | **NEW** — `castVote` + `retractVote` callable functions |
| `functions/package.json` | **NEW** — generated by `firebase init functions` |
| `Sappy/TrackingViewModel.swift` | Replace `vote()` + `retractVote()` bodies with function calls |
| `web/src/components/ProfileDrawer.tsx` | Replace WriteBatch retract with `httpsCallable("retractVote")` |
| `firestore.rules` | `metrics` write → `if false`; `users` write → block `mood` field from clients |
| `ARCHITECTURE.md` | Update platform diagram to show Functions layer |
| `TECH_SPECS.md` | Update vote logic pseudocode + security rules table |
| `HANDOVER.md` | Log V2 migration session |

---

## 11. Checklist (Print This Before Executing)

```
[ ] Apple Developer Enrollment active
[ ] Firebase Blaze plan confirmed
[ ] firebase init functions — TypeScript, europe-west1
[ ] Implement castVote in functions/src/index.ts
[ ] Implement retractVote in functions/src/index.ts
[ ] firebase deploy --only functions
[ ] Verify both functions live in Firebase Console > europe-west1
[ ] Update TrackingViewModel.swift — vote() + retractVote()
[ ] Add FirebaseFunctions to Xcode target frameworks
[ ] Build iOS — run on device — cast vote — verify no errors
[ ] Update ProfileDrawer.tsx — handleDeleteAccount()
[ ] cd web && npm run build — verify build succeeds
[ ] firebase deploy --only firestore:rules
[ ] firebase deploy --only hosting
[ ] Test full flow: vote → swap → sign-out → sign-in → delete account
[ ] Update ARCHITECTURE.md + TECH_SPECS.md + HANDOVER.md
```

---

## 12. New Mac Setup — Complete Onboarding Guide

> **Scenario**: You cloned this repo on a fresh Mac with a new Apple ID. You have no Firebase credentials, no Xcode signing, and no `.env.local`. This section gets you from zero to running in exact order.

---

### 12.1 What the Repo Already Contains (no action required)

The following are committed and will clone correctly with no manual steps:

| File | Status |
|---|---|
| All Swift source files (`Sappy/*.swift`) | ✅ Committed |
| All web source files (`web/src/**`) | ✅ Committed |
| `firestore.rules`, `firebase.json`, `firestore.indexes.json` | ✅ Committed |
| `web/next.config.mjs`, `package.json`, `tsconfig.json` | ✅ Committed |
| All `.md` documentation files | ✅ Committed |
| `BACKEND_V2_PLAN.md` (this file) | ✅ Committed |

### 12.2 What Is Gitignored (you must re-create manually)

These files contain secrets and are never committed. You must create them on every new machine.

| File | What it is | Where to get it |
|---|---|---|
| `Sappy/GoogleService-Info.plist` | iOS Firebase credentials | Firebase Console → `sappy-caa9e` → Project Settings → iOS app → Download |
| `web/.env.local` | Web Firebase credentials (6 keys) | Firebase Console → `sappy-caa9e` → Project Settings → Web app → Config |

---

### 12.3 Step-by-Step Setup

#### Step 1 — Install system tooling

```bash
# Install Homebrew (if not present)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js 20+
brew install node@20
node --version   # Must show 20.x.x or higher

# Install Firebase CLI
npm install -g firebase-tools
firebase --version   # Must be 13+
```

Xcode: download from the App Store with your new Apple ID. Required for iOS builds.

#### Step 2 — Clone the repo

```bash
git clone <your-repo-url> Sappy
cd Sappy
```

#### Step 3 — Firebase login

```bash
firebase login
# Opens browser — log in with the Google account that owns sappy-caa9e
```

Verify:

```bash
firebase projects:list
# sappy-caa9e must appear in the list
```

Link the project to this directory:

```bash
firebase use sappy-caa9e
```

#### Step 4 — Install web dependencies

```bash
cd web
npm install
cd ..
```

#### Step 5 — Create `web/.env.local`

```bash
touch web/.env.local
```

Open `web/.env.local` and populate all 6 values.
Source: [Firebase Console](https://console.firebase.google.com) → `sappy-caa9e` → Project Settings → Your apps → Web app → SDK setup → Config:

```env
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=sappy-caa9e
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=
```

Verify the web runs:

```bash
cd web && npm run dev
# http://localhost:3000 should show the Sappy aura or auth modal
cd ..
```

#### Step 6 — Download `GoogleService-Info.plist`

1. Go to [Firebase Console](https://console.firebase.google.com) → `sappy-caa9e` → Project Settings
2. Scroll to **Your apps** → find the iOS app with your bundle ID
3. Click **Download GoogleService-Info.plist**
4. Move it to: `Sappy/GoogleService-Info.plist`
   > The file must sit inside the `Sappy/` Swift source folder — NOT the project root.

#### Step 7 — Open in Xcode and configure signing

1. Open `Sappy.xcodeproj` in Xcode 15+
2. Xcode auto-resolves Swift Package Manager dependencies on first open — wait for it to finish
3. Select the **Sappy** target → **Signing & Capabilities**
4. Set **Team** to your new Apple Developer account
5. Set **Bundle Identifier** to the one registered in both Apple Developer Console and Firebase

#### Step 8 — Verify the iOS build

- Connect a real iPhone (Sign In with Apple requires a physical device — it does not work on simulator)
- Press **⌘R**
- App should launch, show the country picker, and complete auth

---

### 12.4 New Apple ID — Impact Assessment

| Component | Impact | Action Required |
|---|---|---|
| Firebase project (`sappy-caa9e`) | **None** | Project is Google-account-owned, not Apple-ID-owned |
| Firestore data (all collections) | **None** | Data keyed by Firebase Auth UID, not Apple ID |
| Cloud Functions (V2) | **None** | Project-level, no bundle ID dependency |
| Firestore security rules | **None** | Project-level |
| Web companion | **None** | Completely independent of iOS bundle ID |
| Email/password user accounts | **None** | Fully portable, sign-in continues to work |
| **Sign In with Apple user accounts** | **⚠️ Affected** | Apple issues a unique UID per bundle ID — see note below |
| `GoogleService-Info.plist` | **Must re-download** | New bundle ID = new iOS app entry in Firebase |
| Xcode signing team + bundle ID | **Must update** | Change in Signing & Capabilities |
| Apple Developer Console | **New registration** | Register new bundle ID, enable Sign In with Apple capability |
| Firebase Console iOS app | **New entry** | Register new bundle ID, download new plist |

> **Sign In with Apple UID note**: Apple generates a unique user identifier bound to your **bundle ID + developer team**. If both change, existing Apple-auth users who sign in again will receive a new Apple UID → new Firebase Auth UID → they appear as brand-new accounts with no vote history. Since Sappy has no live users yet, this has zero impact right now. If you have users in the future and change bundle IDs, you would need a UID migration strategy.

---

### 12.5 Connecting the New Mac to V2 Migration

Once the new Mac is set up and the app builds cleanly, you are ready to continue with the Cloud Functions migration. Run this first to confirm project linkage:

```bash
# Confirm correct project active
firebase use sappy-caa9e

# Confirm you can see current rules
firebase firestore:rules --project sappy-caa9e
```

Then proceed from **Section 5, Step 1** (Initialize Cloud Functions) of this document.

---

### 12.6 New Mac Readiness Checklist

Use this as a print-and-tick list before starting any dev work on the new machine.

```
SYSTEM TOOLING
[ ] Homebrew installed and up to date
[ ] Node.js 20+  →  node --version shows 20.x.x
[ ] Firebase CLI 13+  →  firebase --version shows 13.x.x
[ ] Xcode 15+ installed from App Store

REPO + FIREBASE
[ ] Repo cloned to local machine
[ ] firebase login — authenticated as Google account owning sappy-caa9e
[ ] firebase projects:list — sappy-caa9e is visible
[ ] firebase use sappy-caa9e — project linked in this directory

WEB SETUP
[ ] cd web && npm install — no errors
[ ] web/.env.local created with all 6 NEXT_PUBLIC_FIREBASE_* keys
[ ] npm run dev — localhost:3000 loads without console errors

iOS SETUP
[ ] GoogleService-Info.plist downloaded and placed at Sappy/GoogleService-Info.plist
[ ] Xcode opens — Swift packages resolve (progress bar completes)
[ ] Signing & Capabilities — Team set to new Apple Developer account
[ ] Bundle ID set in Xcode AND registered in Apple Developer Console
[ ] Sign In with Apple capability enabled for the new bundle ID in Apple Developer Console
[ ] Firebase Console — new iOS app entry created for this bundle ID
[ ] ⌘R — iOS app builds and runs on device without errors
[ ] Country picker screen appears on first launch
[ ] Sign-in with Apple OR email/password completes successfully
[ ] TrackingView loads with real-time Firestore data

READY FOR V2 MIGRATION
[ ] All above boxes ticked
[ ] Apple Developer Enrollment active (required for App Store + Cloud Functions billing)
[ ] Firebase Blaze plan confirmed active
[ ] Proceed to Section 5 of this document
```
