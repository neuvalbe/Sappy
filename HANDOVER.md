# Sappy — Agent Handover Document

> Read this before touching any code. It tells you everything about this project, how this developer works, and exactly where things stand.

---

## 1. How This Developer Works

- **No git operations unless explicitly commanded.** Never `git add`, `commit`, or `push` on your own.
- **No global installs.** All deps are local (`npm install`, never `npm install -g`).
- **Nothing changes visually unless asked.** If the task is backend or logic, the UI stays pixel-identical.
- **No fluff.** No "Great idea!", no apologies, no filler. Direct, professional, fast.
- **Workflow**: You edit files directly. The developer builds on the Xcode simulator to verify. You never run the simulator or suggest pulling from git — that's their job.
- **One source of truth**: The actual Swift/Firestore code is truth. Documentation reflects code, not the other way around.
- **Just chatting mode**: If they're asking a conceptual question rather than requesting a task, respond in plain text only — no files, no code blocks, no artifacts.

---

## 2. What Sappy Is

A minimalist iOS mood-tracking app with a single question: **how do you feel right now?**

- Tap `:)` for happy, `:(` for sad.
- The app shows a live global counter (how many people feel the same) with per-country breakdown.
- The brand identity is the `):)` logo — a merged sad `):` and happy `:)` face sharing colon eyes.
- Cinematic, physics-based SwiftUI animations. No navigation bars. Pure SwiftUI.

**Firebase project**: `sappy-caa9e`, region `eur3` (Europe).

---

## 3. Tech Stack

| Layer        | Technology                                                     |
| ------------ | -------------------------------------------------------------- |
| Platform     | iOS 26+, SwiftUI                                               |
| Language     | Swift 5.9+                                                     |
| Auth         | Firebase Auth — Sign In with Apple + Email/Password            |
| Database     | Cloud Firestore (real-time snapshot listeners)                 |
| Font         | Dela Gothic One (bundled TTF)                                  |
| Architecture | MVVM — `TrackingViewModel` (ObservableObject) → `TrackingView` |

---

## 4. File Map (11 Swift files — all in `Sappy/`)

| File                      | Role                                                                                                                        |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `SappyApp.swift`          | `@main` entry, custom font registration                                                                                     |
| `SappyDesignTokens.swift` | `AppState` enum (`.login`, `.tracking`), `Mood` enum, `SappyDesign` token namespace, `SquishableButtonStyle`, `flagEmoji()` |
| `ContentView.swift`       | Root state router — crossfades between `.login` and `.tracking`                                                             |
| `AuthHelper.swift`        | Centralized post-auth logic shared by `LoginView` and `SappyAuthView`                                                       |
| `LoginView.swift`         | 2-step auth: country picker → Sign In with Apple / Sappy email                                                              |
| `SappyAuthView.swift`     | Email/password auth sheet (sign-up + sign-in toggle)                                                                        |
| `SappyLegalView.swift`    | Terms of Service + Privacy Policy modal                                                                                     |
| `TrackingView.swift`      | Cinematic mood selection + feedback with real-time counter                                                                  |
| `TrackingViewModel.swift` | Firestore sync, atomic WriteBatch vote logic, sequential deleteAccount()                                                    |
| `SappySettingsView.swift` | Sign-out + account deletion (App Store 5.1.1v compliant)                                                                    |
| `SappyLogoShape.swift`    | SwiftUI `Shape` — raw SVG cubic Bézier path data for `):)` logo                                                             |

**Dead files**: `SplashView.swift` was deleted. `AppState.splash` was removed.

---

## 5. Data Architecture

```
metrics/global_counts          ← Public read, auth write (field-validated)
  total_happy: Int
  total_sad: Int
  countries: { "US": { happy: Int, sad: Int }, ... }

users/{uid}                    ← Owner read/write only
  mood: "happy" | "sad" | ""
  country: "BE"                ← ISO 3166-1 alpha-2
  updatedAt: Timestamp
```

**State stores:**

- Firebase Auth (Keychain) — auth session, survives reinstall
- `UserDefaults` — fast-launch cache only (`currentMood`, `userCountry`, `hasCompletedFirstSignUp`)
- Firestore `users/{uid}` — **source of truth** for vote state

---

## 6. Critical Architecture Decisions (don't undo these)

| Decision                                                     | Why                                                                            |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| **Atomic `WriteBatch`** for all vote/retract operations      | Without it, user doc and global counts can desync = phantom vote drift         |
| **Sequential chaining** in `deleteAccount()` and `signOut()` | Auth token must not be invalidated before Firestore write completes            |
| **`retractVote()` has a completion handler**                 | Callers (`signOut`, `deleteAccount`) chain their next step inside the callback |
| **`max(0, ...)` flooring on count display**                  | Firestore increments can transiently go negative during rapid swaps            |
| **`flagEmoji()` double-shift guard**                         | Prevents already-encoded flag emoji from being double-encoded into garbage     |
| **Vote cooldown 0.6s**                                       | Prevents rapid-tap race conditions before the first batch commits              |
| **`AuthHelper.completeAuthentication()`**                    | DRYs up identical post-auth logic in `LoginView` and `SappyAuthView`           |

---

## 7. Design Tokens (SappyDesign namespace)

- **Background (happy/light)**: Pure white `#FFFFFF`
- **Background (sad/dark)**: Pure black `#000000`
- **Text primary**: `Color(white: 0.1)` ≈ `#1A1A1A`
- **Happy subtitle**: `Color(red: 0.99, green: 0.87, blue: 0.03)` ≈ `#FDDE08` — with `shadow(radius: 8, opacity: 0.6)`
- **Sad subtitle**: `Color(red: 0.40, green: 0.55, blue: 0.78)` ≈ `#668CC7` — with `shadow(radius: 8, opacity: 0.5)`
- **Font**: Dela Gothic One (universal)
- **Button style**: `SquishableButtonStyle` — 0.96 scale on press, 0.2s ease-out

---

## 8. Firestore Security Rules

```
match /metrics/{doc} {
  allow read: if true;
  allow write: if request.auth != null
    && request.resource.data.keys().hasOnly(['total_happy', 'total_sad', 'countries'])
    && request.resource.data.total_happy is int
    && request.resource.data.total_sad is int;
}
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
// All other collections: denied
```

---

## 9. Admin Scripts (project root, require `firebase-admin` SDK)

| Script                   | Purpose                                            |
| ------------------------ | -------------------------------------------------- |
| `node read_firestore.js` | Read current `metrics/global_counts`               |
| `node seed_firestore.js` | Wipe and re-seed `global_counts` to clean state    |
| `node wipe_firestore.js` | Reset all Firestore data (metrics + all user docs) |

Credentials: use Application Default Credentials (`firebase login` / `gcloud auth`). **Never commit `serviceAccountKey.json`** — it's in `.gitignore`.

---

## 10. What Has Been Done (Chronological)

1. Built full SwiftUI app from scratch — auth, cinematic tracking screen, real-time Firestore
2. App icon pipeline via `sharp-cli` — 11% safe-zone margin baked in, all appearance slots explicitly mapped (`Contents.json`)
3. **v2.0 refactor**: Atomic `WriteBatch` for vote/retract, sequential `deleteAccount()` chain, centralized `AuthHelper`, removed `SplashView.swift` and `AppState.splash`
4. **Security**: Firestore field-validation rules on `metrics/global_counts`
5. **v2.1**: Mood-colored subtitles — brand yellow glow (happy), steel blue glow (sad)
6. **v2.2 audit fixes**: Deleted junk files, fixed `.gitignore`, chained `signOut()` after batch commit, logged `displayName` errors, removed dead `auth` block from `firebase.json`
7. All docs (`ARCHITECTURE.md`, `TECH_SPECS.md`, `README.md`) synced to actual codebase state

---

## 11. What's NOT Done Yet

| Item                                     | Priority                             | Notes                                                                           |
| ---------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------- |
| **Privacy Policy URL** (public web page) | 🔴 Required for App Store submission | GitHub Pages or Notion works                                                    |
| **Support URL**                          | 🔴 Required for App Store Connect    | Can be same page as Privacy Policy                                              |
| **App Store screenshots**                | 🔴 Required                          | 6.7" + 6.5" mandatory; 6.1" + 5.5" recommended                                  |
| **App Store Connect metadata**           | 🔴 Required                          | Description (4000 chars), subtitle (30 chars), category                         |
| **"Forgot Password?" flow**              | 🟡 Product gap                       | `Auth.auth().sendPasswordReset(withEmail:)` — one-liner                         |
| **Increment magnitude validation**       | 🔵 Security                          | Requires Cloud Function + Blaze plan. Tracked risk, not a blocker.              |
| **Android / React Native port**          | 🔵 Future                            | Backend is platform-agnostic. See `ARCHITECTURE.md` Section 9–10 for full spec. |

---

## 12. Git State

- **Repo**: `https://github.com/neuvalbe/Sappy.git`
- **Branch**: `main`
- **Latest commit**: `v2.2` audit hygiene fixes
- **Local == remote**: Always push after completing a session's changes.

---

## 13. Known Risks (Accepted Tradeoffs)

1. **No increment magnitude validation** — a malicious authenticated user could `FieldValue.increment(999999)`. Requires Cloud Function to fix. Accepted until Blaze plan.
2. **No email verification** — users can sign up with fake emails. Accepted for MVP.
3. **`DispatchQueue.main.asyncAfter` for animation timing** — fragile under main thread load. Future: migrate to `Task.sleep` with Swift Concurrency.
