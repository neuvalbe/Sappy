# Sappy — Architecture & React Replication Guide

> **Purpose**: This document provides everything a co-developer needs to replicate the Sappy iOS app in React (React Native or React web) for Android users. It covers the complete state machine, every screen's behavior, animation specifications, color values, typography, and the raw SVG path data for the logo.

---

## Table of Contents
1. [App Overview](#1-app-overview)
2. [File Structure](#2-file-structure)
3. [State Machine](#3-state-machine)
4. [Design System](#4-design-system)
5. [Screen-by-Screen Specification](#5-screen-by-screen-specification)
6. [Logo & SVG Path Data](#6-logo--svg-path-data)
7. [Animation Specifications](#7-animation-specifications)
8. [Haptic Feedback Map](#8-haptic-feedback-map)
9. [Persistence & Auth](#9-persistence--auth)
10. [React Implementation Notes](#10-react-implementation-notes)

---

## 1. App Overview

**Sappy** is a minimalist mood-tracking app. The user flow is:

```
Launch → Login Screen → Mood Selection ("happy" or "sad") → Feedback Message
```

The brand identity is the `):)` logo — a sad face `):(` and happy face `(:)` merged together, sharing the colon as eyes.

---

## 2. File Structure

```
Sappy/
├── SappyApp.swift          # @main entry point
├── ContentView.swift       # Root view — state router
├── LoginView.swift         # Authentication (country + sign-in)
├── TrackingView.swift      # Mood selection + feedback response
├── SappyLogoShape.swift    # SwiftUI Shape — logo vector paths
├── SplashView.swift        # ARCHIVED — splash animation (inactive)
├── SappyLogo.svg           # Black stroke logo export (80×80)
└── SappyLogo_Red.svg       # Red gradient logo export (256×256)
```

### React Equivalent Structure
```
src/
├── App.jsx                 # Root — state router (replaces ContentView)
├── screens/
│   ├── LoginScreen.jsx     # Login flow
│   └── TrackingScreen.jsx  # Mood selection + feedback
├── components/
│   ├── SappyLogo.jsx       # SVG logo component
│   ├── SquishableButton.jsx # Press-scale button
│   └── FeedbackView.jsx    # Post-selection message
├── assets/
│   └── sappy-logo.svg      # Logo SVG file
└── styles/
    └── tokens.js           # Design tokens (colors, fonts, spacing)
```

---

## 3. State Machine

### AppState Enum
```
enum AppState {
    case splash   // Exists but bypassed (initial state is .login)
    case login    // Login screen
    case tracking // Mood selection → feedback
}
```

### State Transitions
```
┌─────────┐    auth success    ┌──────────┐
│  LOGIN   │ ─────────────────>│ TRACKING │
└─────────┘                    └──────────┘
                                     │
                               mood selected
                                     │
                                     ▼
                              ┌──────────────┐
                              │ FEEDBACK VIEW│
                              │ (inline)     │
                              └──────────────┘
```

### React Implementation
```jsx
const [appState, setAppState] = useState('login');

// In App.jsx render:
{appState === 'login' && <LoginScreen onAuth={() => setAppState('tracking')} />}
{appState === 'tracking' && <TrackingScreen />}
```

---

## 4. Design System

### Colors
| Token | Hex | Usage |
|---|---|---|
| `background` | `#FFFFFF` | All screen backgrounds |
| `text.primary` | `#1A1A1A` (`rgba(0,0,0,0.85)`) | Headlines, logo stroke |
| `text.secondary` | `rgba(0,0,0,0.5)` | Subtitles |
| `text.tertiary` | `rgba(0,0,0,0.4)` | Disclaimers, labels |
| `text.quaternary` | `rgba(0,0,0,0.3)` | Hint text, chevrons |
| `ambient.red1` | `rgba(255,51,51,0.08)` | Large background circle |
| `ambient.red2` | `rgba(128,0,0,0.06)` | Small background circle |
| `button.primary.bg` | `#1A1A1A` | Sign-in button fill |
| `button.primary.text` | `#FFFFFF` | Sign-in button text |
| `button.disabled.bg` | `rgba(0,0,0,0.2)` | Disabled continue button |
| `input.bg` | `rgba(0,0,0,0.04)` | Country picker background |
| `input.border` | `rgba(0,0,0,0.1)` | Country picker border |

### Typography
| Element | Font | Size | Weight | Style |
|---|---|---|---|---|
| App title "SAPPY" | System Rounded | 32px | Bold | kerning: 4 |
| Subtitle | System Serif | 16px | Regular | — |
| Country label | System | 18px | Semibold | — |
| Button text | System | 16-17px | Bold/Semibold | — |
| Disclaimer | System | 12px | Regular | — |
| Mood words ("happy.", "sad.") | System Serif | 48px | Light | italic, kerning: 1.5 |
| Feedback headline | System Serif | 34px | Light | kerning: 1.2 |
| Feedback body | System Serif | 18px | Regular | kerning: 0.8, lineSpacing: 6 |
| Center label | System Serif | 16px | Regular | kerning: 1.2 |

### React Typography Mapping
```js
// System Rounded → use 'SF Pro Rounded' on iOS, 'Product Sans' or 'Nunito' on Android
// System Serif → 'New York' on iOS, 'Noto Serif' or 'Merriweather' on Android
// System Default → 'SF Pro Display' on iOS, 'Roboto' on Android
```

### Corner Radius
- Buttons: `16px` (continuous/squircle on iOS → standard `borderRadius` on React)
- Input fields: `16px`

### Spacing
- Content horizontal padding: `32px`
- Bottom padding: `60px`
- Section spacing: `20px`
- Element spacing within sections: `8px`
- Button height: `56px`

---

## 5. Screen-by-Screen Specification

### 5.1 Login Screen (`LoginView.swift`)

#### Layout (top to bottom)
1. **Background**: Pure white with two animated ambient red circles
2. **Logo**: `SappyLogoShape` — 80×80, stroked in near-black, with draw-on animation
3. **Title block** (appears after logo draws on):
   - "SAPPY" — bold rounded, kerning 4
   - "Are you happy or sad?" — serif italic subtitle
4. **Spacer**
5. **Auth section** (two steps):

**Step 1 — Country Selection** (shown to first-time users):
- "Where are you joining from?" label
- Country dropdown (Menu picker) with chevron
- "Continue" button (disabled until country selected)

**Step 2 — Sign In Options** (shown after country or for returning users):
- "Sign In to Sappy" / "Continue with Sappy" button (dark, with small logo)
- "Sign in with Apple" native button (white outline style)

6. **Disclaimer text** at bottom

#### Ambient Background Animation
Two blurred circles drift continuously:
```
Circle 1: 400×400, blur: 80, color: rgba(255,51,51,0.08)
  - Animates between offset(-60,-80) ↔ offset(60,80)

Circle 2: 300×300, blur: 80, color: rgba(128,0,0,0.06)
  - Animates between offset(40,80) ↔ offset(-40,-80)

Duration: 10 seconds, easeInOut, repeats forever, autoreverses
```

#### Logo Draw-On Animation
```
- strokeEnd: 0.0 → 1.0
- Duration: 1.5s, easeOut
- After 1.2s delay: title + auth elements fade in (1.0s, easeOut)
```

#### Auth Step Transition
```
countrySelection → signinOptions
- Animation: spring(response: 0.5, dampingFraction: 0.7)
```

---

### 5.2 Tracking Screen (`TrackingView.swift`)

#### Layout
Full-screen split into two tap zones separated by a center label:

```
┌─────────────────────────┐
│                         │
│       happy.            │  ← Top half (tap zone)
│                         │
│                         │
│   How are you feeling?  │  ← Center label
│                         │
│                         │
│        sad.             │  ← Bottom half (tap zone)
│                         │
└─────────────────────────┘
```

#### Behavior
- Text fades in over 1.5s on appear
- Both mood words have a "breathing" scale animation: alternating between 0.98 and 1.02 scale, 4s cycle, forever
- "happy." breathes UP when "sad." breathes DOWN (opposite phase)
- Tapping either word triggers `.rigid` haptic and transitions to `FeedbackView`
- Transition: 0.8s easeIn opacity

#### Ambient Background
Same as Login Screen but with reactive scaling:
- **Before selection**: Same as login (400×400 & 300×300, same opacities)
- **After selection**: Circles expand (800×800 & 600×600), blur increases to 120, opacities shift to 0.02 and 0.2
- Transition: 2.0s easeInOut

---

### 5.3 Feedback View (`FeedbackView` inside `TrackingView.swift`)

#### Happy Response
- Headline: "That's wonderful."
- Body: "Keep riding the wave.\nThe world is yours today."

#### Sad Response
- Headline: "Take a deep breath."
- Body: "It is completely okay to feel this way.\nTomorrow is a new start."

#### Animations
- Headline: fade in + offset(y: 10→0), 1.0s easeOut, 0.2s delay
- Body: fade in + offset(y: 10→0), 1.0s easeOut, 1.2s delay
- Entry transition into FeedbackView: 1.5s easeIn opacity with 0.5s delay
- Exit of mood selection: opacity + scale(1.1) combined

---

## 6. Logo & SVG Path Data

### Logo Concept
The logo represents `):)` — reading left to right it's a sad face `):(`, but also a happy face `(:)`. The colon `:` serves as shared eyes.

### SVG Structure (3 parts)
The logo is composed of three independently drawable sub-paths:

1. **Left Arc** `)` — the concave left parenthesis
2. **Colon** `:` — two dots (eyes)
3. **Right Arc** `(` — the convex right parenthesis (mirrored)

### Raw SVG (80×80 viewBox, black stroke)
Use `SappyLogo.svg` in project root. This is the canonical export matching the LoginView's 80×80 rendering.

### React SVG Component
```jsx
// Import the SVG file directly or use inline SVG
import { ReactComponent as SappyLogo } from '../assets/sappy-logo.svg';

// Or render inline with the path data from SappyLogo.svg
<svg width="80" height="80" viewBox="0 0 80 80" fill="none">
  <path d="[path data from SappyLogo.svg]"
        stroke="#191919" strokeWidth="6"
        strokeLinecap="round" strokeLinejoin="round"/>
</svg>
```

### For React Native (react-native-svg)
```jsx
import Svg, { Path } from 'react-native-svg';

const SappyLogo = ({ size = 80, color = '#191919' }) => (
  <Svg width={size} height={size} viewBox="0 0 80 80" fill="none">
    <Path d="[path data from SappyLogo.svg]"
          stroke={color} strokeWidth={6}
          strokeLinecap="round" strokeLinejoin="round"/>
  </Svg>
);
```

---

## 7. Animation Specifications

### Summary Table

| Animation | Duration | Easing | Delay | Notes |
|---|---|---|---|---|
| Ambient circle drift | 10s | easeInOut | 0 | repeats forever, autoreverses |
| Logo stroke draw-on | 1.5s | easeOut | 0 | strokeEnd: 0→1 |
| Title/auth fade in | 1.0s | easeOut | 1.2s | opacity + offset(y: 20→0) |
| Auth step transition | spring | response: 0.5, damping: 0.7 | 0 | — |
| App state transition | 0.8s | easeInOut | 0 | opacity crossfade |
| Mood text fade in | 1.5s | easeIn | 0 | — |
| Mood text breathing | 4.0s | easeInOut | 0 | scale 0.98↔1.02, forever |
| Mood selection | 0.8s | easeIn | 0 | opacity transition |
| Ambient expand on select | 2.0s | easeInOut | 0 | size + blur + opacity |
| Feedback headline | 1.0s | easeOut | 0.2s | opacity + y offset |
| Feedback body | 1.0s | easeOut | 1.2s | opacity + y offset |
| Feedback view entry | 1.5s | easeIn | 0.5s | opacity |
| Button press scale | 0.2s | easeOut | 0 | scale: 1.0→0.96 |

### React Animation Library Recommendations
- **React Native**: `react-native-reanimated` for spring physics and gesture-driven animations
- **React Web**: `framer-motion` for declarative animations matching SwiftUI behavior
- **SVG draw-on**: Animate `strokeDashoffset` from path length to 0

---

## 8. Haptic Feedback Map

| Action | iOS API | Android Equivalent |
|---|---|---|
| Country selection | `UISelectionFeedbackGenerator.selectionChanged()` | `HapticFeedbackConstants.CLOCK_TICK` |
| "Continue" press | `UIImpactFeedbackGenerator(.medium)` | `HapticFeedbackConstants.CONTEXT_CLICK` |
| Auth success | `UINotificationFeedbackGenerator(.success)` | `HapticFeedbackConstants.CONFIRM` |
| Auth failure | `UINotificationFeedbackGenerator(.error)` | `HapticFeedbackConstants.REJECT` |
| Mood selection | `UIImpactFeedbackGenerator(.rigid)` | `HapticFeedbackConstants.KEYBOARD_TAP` |

### React Native Implementation
```jsx
import ReactNativeHapticFeedback from 'react-native-haptic-feedback';

// On mood selection:
ReactNativeHapticFeedback.trigger('impactHeavy');

// On auth success:
ReactNativeHapticFeedback.trigger('notificationSuccess');
```

---

## 9. Persistence & Auth

### Current State (iOS)
- **No backend**. Auth is purely front-end.
- `@AppStorage("hasCompletedFirstSignUp")` stores a boolean in `UserDefaults`.
- If `true` on launch → skip country picker, go straight to sign-in options.
- Selecting any auth method sets this to `true` and transitions to tracking.

### React Equivalent
```jsx
// AsyncStorage (React Native) or localStorage (React Web)
const hasCompletedFirstSignUp = await AsyncStorage.getItem('hasCompletedFirstSignUp');

if (hasCompletedFirstSignUp === 'true') {
  setAuthStep('signinOptions');
} else {
  setAuthStep('countrySelection');
}

// On successful auth:
await AsyncStorage.setItem('hasCompletedFirstSignUp', 'true');
```

### Country List
```js
const countries = [
  "United States", "United Kingdom", "Canada", "Australia",
  "Germany", "France", "Japan", "South Korea", "Brazil", "India"
];
```

---

## 10. React Implementation Notes

### Key Behavioral Differences to Account For

1. **SwiftUI `ZStack` → React `position: absolute`**
   - SwiftUI layers views in a ZStack. In React, use absolute positioning or `z-index` layering.

2. **SwiftUI transitions → Framer Motion `AnimatePresence`**
   - SwiftUI's `.transition(.opacity)` maps to `<AnimatePresence>` with `initial/animate/exit` props.

3. **Spring physics**
   - SwiftUI `spring(response: X, dampingFraction: Y)` → Framer Motion `transition={{ type: "spring", duration: X, bounce: 1-Y }}`

4. **`@State` → `useState`**
   - Direct 1:1 mapping. SwiftUI's `@State` is React's `useState`.

5. **`@Binding` → props + callbacks**
   - SwiftUI's `@Binding var appState` is a React prop + setter: `onAuth={() => setAppState('tracking')}`

6. **`.onAppear` → `useEffect`**
   - SwiftUI's `.onAppear { }` maps to `useEffect(() => { }, [])`.

7. **Menu picker → React Native `Picker` or custom dropdown**
   - No direct equivalent. Use `@react-native-picker/picker` or a custom modal.

8. **Sign In with Apple → `@invertase/react-native-apple-authentication`**

9. **Blur effects → `@react-native-community/blur` or CSS `backdrop-filter`**

### Minimum Dependencies (React Native)
```json
{
  "react-native-svg": "^15.x",
  "react-native-reanimated": "^3.x",
  "react-native-haptic-feedback": "^2.x",
  "@react-native-async-storage/async-storage": "^1.x",
  "@invertase/react-native-apple-authentication": "^2.x",
  "@react-native-picker/picker": "^2.x",
  "@react-native-community/blur": "^4.x"
}
```
