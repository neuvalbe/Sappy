# Sappy

## Tech Specs & Session Log
**Last Updated**: March 25, 2026

### 1. Goal
A minimalist iOS mood-tracking app. Users authenticate, then choose whether they're happy or sad. The app responds with an emotionally appropriate message. The identity revolves around the `):)` logo — a merged sad `):(` and happy `(:)` face.

### 2. Current Architecture (v1)

| File | Role |
|---|---|
| `SappyApp.swift` | App entry point (`@main`) |
| `ContentView.swift` | Root router — hosts `AppState` enum and switches views |
| `LoginView.swift` | 2-step auth: country picker → Sign In (Sappy / Apple) |
| `TrackingView.swift` | Mood selection (happy/sad) → `FeedbackView` response |
| `SappyLogoShape.swift` | `Shape` conformance — SVG path data for `:)` logo |
| `SplashView.swift` | **Archived** — face-merge animation (not in active flow) |

### 3. State Flow
```
.login → (auth) → .tracking → (mood select) → FeedbackView
```
Splash (`AppState.splash`) exists in enum but is bypassed; initial state is `.login`.

### 4. Design Tokens
- **Background**: Pure white (`#FFFFFF`)
- **Ambient glow**: Two radial circles, `rgba(255,51,51,0.08)` and `rgba(128,0,0,0.06)`, animated drift
- **Logo stroke**: `Color(white: 0.1)` ≈ `#1A1A1A`, 6pt stroke, round caps/joins
- **Typography**: System fonts — `.rounded` for headings, `.serif` for body
- **Button style**: `SquishableButtonStyle` — 0.96 scale on press, 0.2s ease-out
- **Haptics**: `UIImpactFeedbackGenerator` (.medium, .rigid), `UINotificationFeedbackGenerator` (.success, .error)

### 5. Assets
| File | Description |
|---|---|
| `SappyLogo.svg` | Black stroke logo, 80×80 viewBox |
| `SappyLogo_Red.svg` | Red gradient logo, 256×256, matching splash aesthetic |

### 6. Status
Production-ready scaffold. No backend connected. Auth is front-end only (`@AppStorage`).
