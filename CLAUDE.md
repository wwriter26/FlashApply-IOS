# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FlashApply iOS is a native SwiftUI app (Swift 5.9, iOS 16.0+) that mirrors the FlashApply React webapp. The Xcode project is inside the `JobHarvest/` directory (product name: `JobHarvest`, bundle ID: `com.flashapply.ios`).

## Build & Test Commands

```bash
# Build
xcodebuild build -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'

# Run all tests
xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'

# Open in Xcode
open JobHarvest/JobHarvest.xcodeproj
```

No linting tools (SwiftLint, etc.) are configured. Dependencies are managed via Swift Package Manager (`Package.swift` at root).

## Architecture

**Pattern:** MVVM with SwiftUI
**State:** `@StateObject` ViewModels injected as `@EnvironmentObject` through the view hierarchy

### Layer Responsibilities

| Layer | Location | Role |
|-------|----------|------|
| **App/Router** | `App/AppRouter.swift` | Auth-gated navigation root — drives all top-level routing |
| **Services** | `Services/` | Networking (URLSession), Auth (Amplify Cognito), File upload (S3) |
| **Models** | `Models/` | Codable data structures shared across layers |
| **ViewModels** | `ViewModels/` | `@MainActor ObservableObject` classes; one per major feature |
| **Views** | `Views/` | SwiftUI views; organized by feature under `Views/Main/` |
| **Utils** | `Utils/` | `Constants.swift` (colors, `AppConfig`), `Extensions.swift`, `Logger.swift` |

### Auth Flow (Critical)

`AppRouter.swift` is the single source of navigation truth:
```
authVM.isLoaded == false  →  LoadingView
authVM.isSignedIn == false →  SignInView (Auth/)
authVM.isNewUser == true   →  PreferencesQuizView (Onboarding/)
else                       →  MainTabView (5 tabs)
```
Auth state changes are driven by an Amplify Hub listener for `signedIn`, `signedOut`, and `sessionExpired` events.

### Networking

`NetworkService.swift` wraps URLSession. All authenticated requests automatically attach:
- `Authorization: Bearer <token>` — from Amplify Cognito session
- `X-Identity-Id: <identityId>` — for S3-scoped access

Timeouts: 30s request / 60s resource.

### Payments (App Store Compliance)

Subscriptions use **web-only checkout**: tapping a plan calls `createCheckoutSession`, then opens the URL in `SFSafariViewController`. No in-app payment sheet — this avoids Apple IAP/StoreKit requirements (same pattern as Notion, Linear).

### Swipe Mechanic (Core Feature)

`Views/Main/Apply/` — `JobCardView` uses `DragGesture` with a 100pt threshold. Z-stack of 3 cards with scale/offset perspective. `UIImpactFeedbackGenerator` fires on accept/reject. `JobCardsViewModel` auto-prefetches the next batch when the deck drops to ≤ 2 cards.

## Key Configuration Files

- **`JobHarvest/amplifyconfiguration.json`** — AWS Cognito + S3 config (not committed; copy from `.template`)
- **`JobHarvest/Config.xcconfig`** — `API_DOMAIN`, `STRIPE_KEY`, `BUCKET_NAME` build vars (not committed; copy from `.template`)
- **`Package.swift`** — SPM dependencies: `amplify-swift` 2.x, `stripe-ios` 23.x
