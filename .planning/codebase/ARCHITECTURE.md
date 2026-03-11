# Architecture

**Analysis Date:** 2026-03-11

## Pattern Overview

**Overall:** MVVM (Model-View-ViewModel) with SwiftUI

**Key Characteristics:**
- ViewModels are `@MainActor final class` conforming to `ObservableObject`, one per major feature
- `AuthViewModel` is the single root `@StateObject`, injected as `@EnvironmentObject` at the `WindowGroup` level and threaded down
- Feature-scoped ViewModels (`JobCardsViewModel`, `ProfileViewModel`, etc.) are instantiated as `@StateObject` in `MainTabView` and injected via `.environmentObject()` into their respective tab subtrees
- All networking is async/await; no Combine publishers are used for data fetching (Combine is imported but unused in practice)
- Services are singletons (`NetworkService.shared`, `AuthService.shared`, `FileUploadService.shared`) accessed directly by ViewModels — there is no dependency injection container

## Layers

**App/Router:**
- Purpose: App entry point and auth-gated navigation root
- Location: `JobHarvest/App/`
- Contains: `FlashApplyApp.swift` (configures Amplify, creates root `AuthViewModel`), `AppRouter.swift` (conditional view switcher)
- Depends on: `AuthViewModel`, `AuthService` (via Amplify)
- Used by: SwiftUI `WindowGroup`

**Services:**
- Purpose: External I/O — networking, authentication, file uploads
- Location: `JobHarvest/Services/`
- Contains: `NetworkService.swift`, `AuthService.swift`, `FileUploadService.swift`
- Depends on: Amplify SDK (auth/storage), URLSession, `AppConfig` (build var constants)
- Used by: ViewModels

**Models:**
- Purpose: Codable data structures shared across layers
- Location: `JobHarvest/Models/`
- Contains: `Job.swift`, `AppliedJob.swift`, `User.swift`, `Email.swift`, `Referral.swift`, `SubscriptionPlan.swift`
- Depends on: Foundation only
- Used by: ViewModels, Views

**ViewModels:**
- Purpose: Business logic, state, and API orchestration for each feature
- Location: `JobHarvest/ViewModels/`
- Contains: `AuthViewModel.swift`, `JobCardsViewModel.swift`, `ProfileViewModel.swift`, `AppliedJobsViewModel.swift`, `MailboxViewModel.swift`, `ReferralViewModel.swift`, `SubscriptionViewModel.swift`
- Depends on: Services, Models
- Used by: Views (via `@EnvironmentObject` or `@StateObject`)

**Views:**
- Purpose: SwiftUI UI layer; purely presentational — no direct service calls
- Location: `JobHarvest/Views/`
- Contains: Auth/, Onboarding/, Main/ (feature tabs), Shared/ (reusable components)
- Depends on: ViewModels (via `@EnvironmentObject`), Models
- Used by: `AppRouter`, `MainTabView`

**Utils:**
- Purpose: Cross-cutting helpers used by any layer
- Location: `JobHarvest/Utils/`
- Contains: `Constants.swift` (colors via `Color` extension, `AppConfig` build vars), `Extensions.swift` (Date, String, View modifiers, `PayEstimate`), `Logger.swift` (`AppLogger` with per-category `os.Logger` instances)
- Depends on: Nothing (no imports beyond Foundation/SwiftUI)
- Used by: All layers

## Data Flow

**App Launch / Auth Check:**

1. `FlashApplyApp.init()` calls `configureAmplify()`, adding `AWSCognitoAuthPlugin` and `AWSS3StoragePlugin`
2. `JobHarvestApp.body` creates `AuthViewModel` as `@StateObject` and passes it to `AppRouter` as `@EnvironmentObject`
3. `AppRouter.task` calls `authVM.checkAuthState()` which calls `AuthService.shared.isSignedIn()` → `Amplify.Auth.fetchAuthSession()`
4. `AppRouter` reads `authVM.isLoaded`, `authVM.isSignedIn`, `authVM.isNewUser` to select which view to render

**Auth Event Routing:**

1. `AppRouter.listenToAuthEvents()` subscribes to `Amplify.Hub` on the `.auth` channel
2. On `signedIn` event → calls `authVM.checkAuthState()` again to refresh state
3. On `signedOut` or `sessionExpired` → calls `authVM.handleSignOut()` which zeros out auth state
4. Auth state changes propagate reactively to `AppRouter` via `@Published` properties on `AuthViewModel`

**Authenticated API Request:**

1. ViewModel calls `NetworkService.shared.request(endpoint, method:, body:)`
2. `NetworkService` calls `AuthService.shared.getIdToken()` and `getIdentityId()` to fetch live Cognito tokens
3. Request is sent via URLSession with `Authorization: Bearer <token>` and `X-Cognito-Identity-Id: <identityId>` headers
4. JSON response is decoded into the expected `Decodable` type and returned
5. ViewModel updates its `@Published` state; SwiftUI re-renders dependent views

**Swipe / Job Card Flow:**

1. `ApplyView` renders a Z-stack of up to 3 `JobCardView` cards from `jobCardsVM.jobs`
2. User drags card past 100pt threshold — `JobCardView.dragGesture` fires `onSwipe(isAccepting:, answers:)` callback
3. `JobCardsViewModel.handleSwipe()` removes the card from the deck optimistically, then calls `POST /handleSwipe`
4. If deck drops to ≤ 2 cards and not already prefetching, a background `Task` calls `fetchJobs(appending: true)`
5. `SwipeResponse` returns `swipesRemaining`; a 403 response sets `noSwipesLeft = true`

**Resume Upload Flow:**

1. `ProfileViewModel.uploadResume(data:fileName:)` calls `FileUploadService.shared.uploadResume()`
2. `FileUploadService` calls `POST /getUploadPresignedUrl` to obtain a presigned S3 URL
3. File data is PUT directly to S3 via the presigned URL using `NetworkService.uploadFile()`
4. On success, the S3 key is written back to `profile.resumeFileName` and the profile is patched via `POST /users/{userId}/profile`

**Payments / Subscription:**

1. `SubscriptionViewModel.createCheckoutSession(plan:)` calls `POST /createCheckoutSession` and stores the returned URL
2. `PremiumView` opens the URL in `SFSafariViewController` — no native payment sheet
3. On Safari callback, `checkSessionStatus(sessionId:)` calls `GET /sessionStatus?session_id=...` and updates `currentPlan`

**State Management:**
- Global auth state lives in `AuthViewModel` (root `@EnvironmentObject`, never deallocated)
- Feature state is scoped to ViewModels instantiated in `MainTabView`; they persist for the session lifetime but are destroyed on sign-out (because `MainTabView` is unmounted by `AppRouter`)
- No local persistence (no CoreData, no UserDefaults caching of API responses)

## Key Abstractions

**NetworkService:**
- Purpose: Single URLSession wrapper that auto-attaches Cognito auth headers to every request
- Location: `JobHarvest/Services/NetworkService.swift`
- Pattern: Singleton; generic async throws methods `request<T: Decodable>`, `unauthenticatedRequest<T>`, `requestWithParams<T>`, plus `uploadFile(to:data:mimeType:)` for presigned S3 uploads

**AuthService:**
- Purpose: Thin wrapper around `Amplify.Auth` — translates Amplify results into app-level `AuthError` types
- Location: `JobHarvest/Services/AuthService.swift`
- Pattern: Singleton; `@MainActor` to allow safe `@Published` usage; provides token retrieval methods consumed by `NetworkService`

**AppRouter:**
- Purpose: Single source of navigation truth — maps auth state to top-level view
- Location: `JobHarvest/App/AppRouter.swift`
- Pattern: Pure SwiftUI `View` with a `Group` containing conditional branches; also owns the Amplify Hub subscription lifecycle

**AppLogger:**
- Purpose: Structured logging with named categories for filtering in Console.app
- Location: `JobHarvest/Utils/Logger.swift`
- Pattern: Static struct with one `os.Logger` per domain (Auth, Network, Jobs, Profile, Files, Subscription, Referral, UI)

**AppConfig:**
- Purpose: Typed access to build-time configuration injected via `Config.xcconfig`
- Location: `JobHarvest/Utils/Constants.swift`
- Pattern: Enum with static computed properties reading from `Bundle.main.infoDictionary`; keys: `API_DOMAIN`, `STRIPE_KEY`, `BUCKET_NAME`

## Entry Points

**App Entry:**
- Location: `JobHarvest/App/FlashApplyApp.swift`
- Triggers: iOS app launch
- Responsibilities: Configures Amplify plugins, creates root `AuthViewModel`, renders `AppRouter`

**Navigation Root:**
- Location: `JobHarvest/App/AppRouter.swift`
- Triggers: `authVM` state changes
- Responsibilities: Renders `LoadingView` | `SignInView` | `PreferencesQuizView` | `MainTabView` based on auth state; manages Amplify Hub listener lifecycle

**Main Tab Container:**
- Location: `JobHarvest/Views/Main/MainTabView.swift`
- Triggers: User is authenticated and not new
- Responsibilities: Instantiates all feature ViewModels as `@StateObject`, injects them as `@EnvironmentObject` into 5 tabs (Apply, My Jobs, Mailbox, Profile, More)

## Error Handling

**Strategy:** Async throws with typed error enums; ViewModels catch errors and surface them as `@Published var error: String?` strings for Views to display

**Patterns:**
- `NetworkError` enum: `invalidURL`, `decodingFailed(Error)`, `serverError(Int, String?)`, `unauthorized`, `noData`
- `AuthError` enum: `notSignedIn`, `sessionExpired`, `noIdentityId`, `confirmationRequired`, `unknown(String)`
- ViewModels catch all thrown errors in `do/catch` blocks and assign `self.error = error.localizedDescription`
- Optimistic updates (e.g., `ProfileViewModel.updateProfile`) revert to previous state on failure
- 403 from `/users/{userId}/jobs` is caught specifically by `JobCardsViewModel` to set `noSwipesLeft = true` rather than showing a generic error

## Cross-Cutting Concerns

**Logging:** `AppLogger` struct in `JobHarvest/Utils/Logger.swift`; category-named `os.Logger` instances. Debug logs are wrapped in `#if DEBUG` guards at the call site in some cases; `AppLogger.network` logs every request method, URL, and status code.

**Validation:** Inline in Views (e.g., `String.isValidEmail` extension, `canAdvance` computed property in `PreferencesQuizView`). No dedicated validation layer.

**Authentication:** Handled at the service layer — `NetworkService` fetches fresh tokens before every authenticated request via `AuthService.getIdToken()`. Token refresh is handled transparently by Amplify.

---

*Architecture analysis: 2026-03-11*
