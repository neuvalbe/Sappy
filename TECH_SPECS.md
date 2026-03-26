# Sappy

## Tech Specs & Session Log
**Last Updated**: March 26, 2026

### 1. Goal
A minimalist iOS mood-tracking app with a cinematic, physics-based experience. Users authenticate, then choose whether they're happy or sad via interactive face taps. The app responds with an empathetic message and a live global mood counter. The identity revolves around the `):)` logo — a merged sad `):(` and happy `(:)` face sharing colon eyes.

### 2. Current Architecture (v1.4)

| File | Role |
|---|---|
| `SappyApp.swift` | App entry point (`@main`), custom font registration with error logging |
| `SappyDesignTokens.swift` | Shared types (`AppState`, `Mood`), `SquishableButtonStyle`, `SappyDesign` token namespace, `flagEmoji` helper |
| `TrackingViewModel.swift` | `ObservableObject`: self-healing document seeding, Firestore snapshot listener (single source of truth), atomic `updateData` vote logic, sign-out, account deletion |
| `ContentView.swift` | Root state router — crossfades between login and tracking, passes `appState` binding |
| `LoginView.swift` | 2-step auth: country picker (ISO codes, A→Z) → Sign In with Apple (Firebase credential) / Sappy email |
| `SappyAuthView.swift` | Email/password auth sheet (sign-up + sign-in toggle) |
| `SappySettingsView.swift` | Account management: sign-out + account deletion (App Store 5.1.1(v)) |
| `SappyLegalView.swift` | Terms of Service & Privacy Policy modal |
| `TrackingView.swift` | Cinematic mood selection + feedback with real-time country capsules and settings gear overlay |
| `SappyLogoShape.swift` | `Shape` conformance — SVG cubic Bézier path data for `):)` logo |
| `SplashView.swift` | **Archived** — face-merge splash animation (not in active flow) |

### 3. State Flow
```
.login → (auth) → .tracking
                      ├── cinematic entrance (draw → split → breathe)
                      ├── mood select (tap face → feedback + country capsules)
                      ├── reset ("change my answer" → spring back)
                      └── settings → sign out → .login
                                   → delete account → .login
```
Splash (`AppState.splash`) exists in enum but is bypassed; initial state is `.login`.
If `Auth.auth().currentUser` exists on launch, `.login` is skipped entirely.

### 4. Design Tokens (SappyDesign namespace)
- **Background**: Pure white (`#FFFFFF`)
- **Text primary**: `Color(white: 0.1)` ≈ `#1A1A1A`
- **Brand gradient**: `#FF3333 → #CC0000` (selected mood faces)
- **Logo stroke**: 6pt (login), 10pt (tracking), round caps/joins
- **Typography**: Dela Gothic One universally
- **Button style**: `SquishableButtonStyle` — 0.96 scale on press, 0.2s ease-out
- **Haptics**: `.soft` (split), `.rigid` (mood select), `.medium` (reset, continue), `.success/.error` (auth)
- **Layout**: 56px buttons, 16px corners, 32px horizontal padding

### 5. Assets
| File | Description |
|---|---|
| `SappyLogo.svg` | Black stroke logo, 80×80 viewBox |
| `SappyLogo_Red.svg` | Red gradient logo, 256×256, matching splash aesthetic |
| `DelaGothicOne-Regular.ttf` | Bundled brand typeface |

### 6. Components
| Component | File | Description |
|---|---|---|
| `SappyTextField` | `SappyAuthView.swift` | Branded text/secure field with consistent input styling |
| `SappySettingsView` | `SappySettingsView.swift` | Account management: sign-out, account deletion with confirmation |
| `LegalSection` | `SappyLegalView.swift` | Titled paragraph block for legal documents |
| `LegalParagraph` | `SappyLegalView.swift` | Standalone body paragraph with legal styling |
| `SquishableButtonStyle` | `SappyDesignTokens.swift` | Tactile press-scale button style, used globally |

### 7. Status
Fully connected to Firebase backend (`sappy-caa9e`, region `eur3`). Auth: Sign In with Apple (Firebase OAuthProvider credential with nonce) + Email/Password. Firestore security rules deployed (public reads, authenticated writes). `TrackingViewModel` uses self-healing document seeding (`getDocument` → seed if missing → attach listener) with single atomic `updateData` calls for all vote operations. No optimistic updates — the snapshot listener is the single source of truth for all UI state. All counts floored at `max(0, ...)` to prevent transient negatives from stale retract operations. Country stored as ISO 3166-1 alpha-2 code via `@AppStorage("userCountry")`, displayed as capsules with country code + count in feedback. Account management (sign-out + deletion) via `SappySettingsView`. On relaunch, `ContentView` auto-skips login if `Auth.auth().currentUser` is non-nil. Android (React Native) replication guide in `ARCHITECTURE.md` Section 9.
