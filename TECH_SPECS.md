# Sappy

## Tech Specs & Session Log
**Last Updated**: March 25, 2026

### 1. Goal
A minimalist iOS mood-tracking app with a cinematic, physics-based experience. Users authenticate, then choose whether they're happy or sad via interactive face taps. The app responds with an empathetic message and a live global mood counter. The identity revolves around the `):)` logo — a merged sad `):(` and happy `(:)` face sharing colon eyes.

### 2. Current Architecture (v1.1)

| File | Role |
|---|---|
| `SappyApp.swift` | App entry point (`@main`), custom font registration with error logging |
| `SappyDesignTokens.swift` | Shared types (`AppState`, `Mood`), `SquishableButtonStyle`, `SappyDesign` token namespace |
| `ContentView.swift` | Root state router — crossfades between login and tracking |
| `LoginView.swift` | 2-step auth flow: country picker → Sign In (Sappy / Apple) |
| `SappyAuthView.swift` | Email/password auth sheet (sign-up + sign-in toggle) |
| `SappyLegalView.swift` | Terms of Service & Privacy Policy modal |
| `TrackingView.swift` | Cinematic mood selection: `.trim()` draw → spring split → face taps → feedback |
| `SappyLogoShape.swift` | `Shape` conformance — SVG cubic Bézier path data for `):)` logo |
| `SplashView.swift` | **Archived** — face-merge splash animation (not in active flow) |

### 3. State Flow
```
.login → (auth) → .tracking
                      ├── cinematic entrance (draw → split → breathe)
                      ├── mood select (tap face → feedback)
                      └── reset ("change my answer" → spring back)
```
Splash (`AppState.splash`) exists in enum but is bypassed; initial state is `.login`.

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
| `LegalSection` | `SappyLegalView.swift` | Titled paragraph block for legal documents |
| `LegalParagraph` | `SappyLegalView.swift` | Standalone body paragraph with legal styling |
| `SquishableButtonStyle` | `SappyDesignTokens.swift` | Tactile press-scale button style, used globally |

### 7. Status
Production-ready frontend scaffold. No backend connected. Auth is front-end only (`@AppStorage`). Global mood counts are mocked. Firebase integration is the planned next step.
