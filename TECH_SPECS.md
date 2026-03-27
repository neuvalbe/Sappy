# Sappy

## Tech Specs & Session Log
**Last Updated**: March 27, 2026 (v2.1)

### 1. Goal
A minimalist iOS mood-tracking app with a cinematic, physics-based experience. Users authenticate, then choose whether they're happy or sad via interactive face taps. The app responds with an empathetic message and a live global mood counter with per-country breakdown. The identity revolves around the `):)` logo — a merged sad `):(` and happy `(:)` face sharing colon eyes.

### 2. Current Architecture (v2.0)

| File | Role |
|---|---|
| `SappyApp.swift` | App entry point (`@main`), custom font registration with error logging |
| `SappyDesignTokens.swift` | Shared types (`AppState`, `Mood`), `SquishableButtonStyle`, `SappyDesign` token namespace, `flagEmoji` helper |
| `TrackingViewModel.swift` | `ObservableObject`: atomic `WriteBatch` vote/retract, sequential `deleteAccount()`, per-user Firestore doc sync, self-healing seeding, snapshot listener, 0.6s cooldown |
| `ContentView.swift` | Root state router — crossfades between `.login` and `.tracking`, passes `appState` binding |
| `AuthHelper.swift` | Centralized post-authentication logic: haptic, UX flag, country persist to Firestore, state transition |
| `LoginView.swift` | 2-step auth: country picker (ISO codes, A→Z) → Sign In with Apple (Firebase credential) / Sappy email |
| `SappyAuthView.swift` | Email/password auth sheet (sign-up + sign-in toggle) |
| `SappySettingsView.swift` | Account management: sign-out + account deletion (App Store 5.1.1(v)) |
| `SappyLegalView.swift` | Terms of Service & Privacy Policy modal |
| `TrackingView.swift` | Cinematic mood selection + feedback with real-time country capsules (optimistic guardrail), settings gear overlay |
| `SappyLogoShape.swift` | `Shape` conformance — SVG cubic Bézier path data for `):)` logo |

### 3. State Flow
```
.login → (auth) → .tracking
                      ├── cinematic entrance (draw → split → breathe)
                      ├── mood select (tap face → feedback + country capsules)
                      ├── reset ("change my answer" → spring back)
                      └── settings → sign out → .login
                                   → delete account → .login
```
If `Auth.auth().currentUser` exists on launch, `.login` is skipped and the app goes directly to `.tracking`.

### 4. Design Tokens (SappyDesign namespace)
- **Background**: Pure white (`#FFFFFF`)
- **Text primary**: `Color(white: 0.1)` ≈ `#1A1A1A`
- **Brand gradient**: `#FF3333 → #CC0000` (selected mood faces)
- **Logo stroke**: 6pt (login), 10pt (tracking), round caps/joins
- **Typography**: Dela Gothic One universally
- **Button style**: `SquishableButtonStyle` — 0.96 scale on press, 0.2s ease-out
- **Mood subtitle colors**: Brand yellow `#FDDE08` (happy) with warm glow, steel blue `#668CC7` (sad) with cool glow — `shadow(radius: 8)`
- **Haptics**: `.soft` (split), `.rigid` (mood select), `.medium` (reset, continue), `.success/.error` (auth)
- **Layout**: 56px buttons, 16px corners, 32px horizontal padding

### 5. Assets
| File | Description |
|---|---|
| `SappyLogo.svg` | Black stroke logo, 80×80 viewBox (project root) |
| `DelaGothicOne-Regular.ttf` | Bundled brand typeface |

### 6. Components
| Component | File | Description |
|---|---|---|
| `SappyTextField` | `SappyAuthView.swift` | Branded text/secure field with consistent input styling |
| `SappySettingsView` | `SappySettingsView.swift` | Account management: sign-out, account deletion with confirmation |
| `LegalSection` | `SappyLegalView.swift` | Titled paragraph block for legal documents |
| `LegalParagraph` | `SappyLegalView.swift` | Standalone body paragraph with legal styling |
| `SquishableButtonStyle` | `SappyDesignTokens.swift` | Tactile press-scale button style, used globally |

### 7. Data Architecture (v2.0)

**Firestore Collections:**
| Collection | Document | Purpose | Access |
|---|---|---|---|
| `metrics` | `global_counts` | Aggregated mood totals + per-country breakdown | Public read, auth write (field-validated) |
| `users` | `{uid}` | Per-user vote state (mood, country, updatedAt) | Owner read/write only |

**State Distribution:**
| Store | Contains | Lifecycle |
|---|---|---|
| Firebase Auth (Keychain) | Auth session | Survives app reinstall |
| UserDefaults | `currentMood`, `userCountry`, `hasCompletedFirstSignUp` | Cache only — Firestore is truth |
| Firestore `users/{uid}` | `mood`, `country`, `updatedAt` | Source of truth for vote state |

**Resilience (v2.0):**
- Atomic `WriteBatch` for all multi-document mutations (vote, retract, delete)
- Sequential `deleteAccount()` with chained callbacks (retract → doc delete → auth delete)
- Error logging on all Firestore write paths via `[Sappy]`-prefixed console messages
- Field-validated security rules on `metrics` (only known fields, integer types)
- Vote cooldown (0.6s) prevents rapid-tap race conditions
- `max(0, ...)` count flooring handles transient negatives
- Optimistic country guardrail in UI bridges async snapshot gap
- Self-healing document seeding if `global_counts` is missing
- Automatic migration of pre-v1.5 UserDefaults-only state to Firestore

### 8. Status
Fully connected to Firebase backend (`sappy-caa9e`, region `eur3`). Auth: Sign In with Apple (Firebase OAuthProvider credential with nonce) + Email/Password via centralized `AuthHelper`. Firestore security rules deployed with field-validated metrics and per-user document access control. `TrackingViewModel` uses atomic `WriteBatch` for all multi-document writes and sequential chaining for account deletion. Per-user Firestore documents (`users/{uid}`) provide cross-device vote deduplication. Sign-out preserves `hasCompletedFirstSignUp` and `userCountry` so returning users skip the country picker. Account deletion performs sequential retract → doc delete → auth delete → full local wipe. Android (React Native / Kotlin) replication guide in `ARCHITECTURE.md` Section 9–10.
