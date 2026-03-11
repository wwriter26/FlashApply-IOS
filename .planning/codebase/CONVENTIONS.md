# Coding Conventions

**Analysis Date:** 2026-03-11

## Naming Patterns

**Files:**
- PascalCase matching the primary type defined inside: `AuthViewModel.swift`, `JobCardView.swift`, `NetworkService.swift`
- Test files use `XCTest` convention: `JobHarvestTests.swift`, `JobHarvestUITests.swift`
- Utility/extension files use descriptive PascalCase nouns: `Constants.swift`, `Extensions.swift`, `Logger.swift`

**Types (structs, classes, enums, protocols):**
- PascalCase throughout: `AuthViewModel`, `JobCardsViewModel`, `NetworkError`, `PipelineStage`, `UserProfile`
- Component naming appends role suffix: `ViewModel`, `View`, `Service`, `Router`
- Shared UI components prefixed with `Flash`: `FlashButton`, `FlashSecondaryButton`
- Icon buttons suffixed with type: `CircleIconButton`

**Functions/Methods:**
- camelCase: `fetchJobs()`, `handleSwipe()`, `checkAuthState()`, `signInWithApple()`
- Async functions that load data use `fetch` prefix: `fetchProfile()`, `fetchJobs()`, `fetchAppliedJobs()`
- Boolean-returning async functions phrased as questions: `isSignedIn()`, `isFirstLogin()`
- Sync state-mutation helpers use `handle` prefix: `handleSignOut()`, `handleSwipe()`
- Private helpers use descriptive verbs: `applyResponse()`, `removeFromAllStages()`, `appendToStage()`, `tag()`

**Variables and Properties:**
- camelCase: `isLoading`, `isLoaded`, `isSaving`, `swipesRemaining`, `seenUrls`
- State flags use `is` prefix: `isLoading`, `isLoaded`, `isSaving`, `isNewUser`, `isPrefetching`
- Published arrays named as plural nouns matching their content type: `jobs`, `applying`, `applied`, `screen`
- Private backing stores prefixed with nothing (rely on access control alone): `network`, `auth`, `session`

**Constants:**
- Centralized in `AppConfig` enum (`Utils/Constants.swift`) using static properties
- Color palette uses `flash` prefix on `Color` extension: `.flashTeal`, `.flashNavy`, `.flashDark`, `.flashOrange`

## Code Style

**Formatting:**
- No automated formatter (SwiftLint, SwiftFormat) configured — per `CLAUDE.md`
- 4-space indentation throughout
- Trailing whitespace omitted
- Braces on same line as declaration

**Linting:**
- No linting tooling configured. Conformance is manual.

**Access Control:**
- `private` used consistently on internal helpers and backing properties
- `final` applied to all class types that are not designed for subclassing: `AuthViewModel`, `NetworkService`, `AuthService`, `ProfileViewModel`
- Singletons declared `static let shared` with `private init()`

**Actor Isolation:**
- `@MainActor` applied to all ViewModel and Service classes that publish state: `AuthViewModel`, `ProfileViewModel`, `JobCardsViewModel`, `AuthService`
- `nonisolated init()` used on `@MainActor` ViewModels that need default initializers: `JobCardsViewModel`, `ProfileViewModel`, `AppliedJobsViewModel`
- Views call async ViewModel methods via `Task { await vm.method() }` inside `Button` actions

## Import Organization

**Order:**
1. `Foundation` / `SwiftUI` / `UIKit` (standard library and Apple frameworks)
2. Third-party SDKs: `Amplify`, `AWSCognitoAuthPlugin`, `AWSS3StoragePlugin`
3. `os` (for `Logger`)

No `@_exported` or module re-export patterns used. No path aliases.

## MARK Comments

MARK sections are used consistently throughout every file to divide logical blocks:

```swift
// MARK: - Fetch
// MARK: - Sign In
// MARK: - Drag Gesture
// MARK: - Card Content
// MARK: - Request Bodies
```

All MARK labels use `// MARK: -` (with dash) so Xcode generates a divider in the jump bar. Section names are title-cased nouns or verb phrases.

## Error Handling

**Strategy:**
- Services throw typed errors (`NetworkError`, `AuthError`) conforming to `LocalizedError`
- ViewModels catch errors and assign `self.error = error.localizedDescription` to a `@Published var error: String?` property
- Views display `authVM.error` / `vm.error` inline in the form as a red caption `Text`
- Critical errors that can't be recovered from fall through to UI state changes (e.g., `isSignedIn = false`)

**Typed Error Enums:**
- `NetworkError` — defined in `Services/NetworkService.swift`: `.invalidURL`, `.decodingFailed(Error)`, `.serverError(Int, String?)`, `.unauthorized`, `.noData`
- `AuthError` — defined in `Services/AuthService.swift`: `.notSignedIn`, `.sessionExpired`, `.noIdentityId`, `.confirmationRequired`, `.unknown(String)`

**Pattern:**
```swift
do {
    let result: SomeResponse = try await network.request("/endpoint", method: "POST", body: body)
    // handle success
} catch NetworkError.serverError(403, _) {
    // handle specific status
} catch {
    AppLogger.category.error("context: \(error.localizedDescription)")
    self.error = error.localizedDescription
}
```

**Optimistic Updates:**
Used in `ProfileViewModel` and `AppliedJobsViewModel`: apply state change immediately, then revert on failure with a `silentRefresh()` or by restoring a `previous` snapshot.

## Logging

**Framework:** `os.Logger` (Apple unified logging), wrapped in `AppLogger` struct at `Utils/Logger.swift`

**Categories:**
```swift
AppLogger.auth         // Authentication and session events
AppLogger.network      // HTTP request/response lifecycle
AppLogger.jobs         // Job fetch and swipe events
AppLogger.profile      // Profile load/save events
AppLogger.files        // S3 file upload events
AppLogger.subscription // Subscription events
AppLogger.referral     // Referral events
AppLogger.ui           // General UI events (default)
```

**Log Level Usage:**
- `.debug(...)` — entry points, request setup, token values (DEBUG builds only via `#if DEBUG` guard for sensitive data)
- `.info(...)` — successful outcomes: "signIn: success for \(email)", "fetchProfile: success"
- `.error(...)` — all caught errors with full `error.localizedDescription`

**Pattern:**
```swift
AppLogger.network.debug("[\(method)] \(baseURL)\(endpoint) — fetching auth tokens")
AppLogger.auth.error("signIn failed: \(error.localizedDescription)")
AppLogger.profile.info("fetchProfile: success — completion \(response.completionPercentage)%")
```

Log messages include: HTTP method in brackets, endpoint path, short description of action or outcome.

## View Structure Conventions

**Body decomposition:**
- Large `body` properties are broken into named computed `var` subviews: `headerSection`, `cardHeader`, `tabContent`, `actionButtons`, `swipeOverlay`
- Helper factory functions return `some View`: `chipRow(label:chips:color:)`, `bulletList(items:label:)`
- `@ViewBuilder` used on computed vars returning conditional content

**State ownership:**
- `@StateObject` created only at the app root (`FlashApplyApp`)
- Passed down as `@EnvironmentObject` via `.environmentObject(vm)` at the `AppRouter` level
- Local view-only state uses `@State private var`

**Async in Views:**
```swift
Button(action: { Task { await authVM.signIn(email: email, password: password) } }) { ... }
```
`Task { }` wraps all `async` ViewModel calls from synchronous button closures. `.task { }` modifier used for lifecycle-bound async calls.

## Comments

**Inline comments** used to explain non-obvious logic: swipe threshold values, optimistic update rationale, API fallback keys.

**No JSDoc/function-level documentation blocks.** Functionality is communicated through MARK sections and descriptive naming rather than doc comments.

## Module Design

**No barrel files.** Each file exposes its types directly — Swift module system handles visibility.

**Singleton services** used for shared stateless infrastructure:
- `NetworkService.shared`
- `AuthService.shared`
- `FileUploadService.shared`

**Request/response body types** defined as `private struct` within the ViewModel file that uses them (not in `Models/`). Example: `FetchJobsRequestBody` and `SwipeRequestBody` are private to `JobCardsViewModel.swift`.

---

*Convention analysis: 2026-03-11*
