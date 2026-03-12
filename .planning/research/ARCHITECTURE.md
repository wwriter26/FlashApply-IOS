# Architecture Patterns

**Domain:** SwiftUI MVVM mobile app with AWS Amplify backend integration
**Researched:** 2026-03-11
**Confidence:** HIGH — based on direct codebase analysis, no speculation required

---

## Current Architecture (As-Built)

The app is fully constructed as a layered MVVM application. The architecture is sound for this type of client. The issues blocking the app are entirely in configuration, not structure — a one-line xcconfig change will unblock the majority of features. Architectural work in this milestone is about hardening an already-working skeleton, not rebuilding it.

### Layer Stack (bottom to top)

```
[AWS Cognito / S3 / API Gateway]
        |
[Amplify SDK (AWSCognitoAuthPlugin, AWSS3StoragePlugin)]
        |
[Services: AuthService, NetworkService, FileUploadService]
        |
[ViewModels: AuthVM, JobCardsVM, ProfileVM, AppliedJobsVM, MailboxVM, SubscriptionVM, ReferralVM]
        |
[Views: AppRouter → MainTabView → 5 tab subtrees]
        |
[User]
```

### Component Boundaries

| Component | Responsibility | Communicates With | Notes |
|-----------|---------------|-------------------|-------|
| `FlashApplyApp` | App entry, Amplify init, root `@StateObject` creation | `AppRouter` | Amplify configure must complete before any auth or storage calls |
| `AppRouter` | Auth-gated top-level navigation; Amplify Hub listener | `AuthViewModel` (via `@EnvironmentObject`) | Hub token stored in `@State` — fragile; should move to `AuthViewModel` |
| `AuthViewModel` | Global auth state (`isSignedIn`, `isNewUser`, `email`, `userId`) | `AuthService`, `AppRouter` | Root `@EnvironmentObject`; never deallocated during session |
| `MainTabView` | Instantiates all feature ViewModels; injects them as `@EnvironmentObject` | All feature ViewModels | All feature VMs are created here and live for the session lifetime |
| `NetworkService` | All HTTP to the backend API; auto-attaches Cognito headers | `AuthService` (for tokens), all ViewModels | Singleton; `baseURL` reads from `AppConfig.apiDomain` (derived from xcconfig) |
| `AuthService` | Thin Amplify.Auth wrapper; token retrieval | `Amplify.Auth`, `NetworkService` | Singleton; token refresh is transparent via Amplify |
| `FileUploadService` | Presigned URL orchestration for S3 uploads | `NetworkService`, `ProfileViewModel` | Does NOT use `AWSS3StoragePlugin` — uses NetworkService + presigned PUT |
| `AppConfig` | Build-time config reader (`API_DOMAIN`, `STRIPE_KEY`, `BUCKET_NAME`) | `NetworkService`, `FileUploadService` | Reads from `Bundle.main.infoDictionary` which is populated via xcconfig → Info.plist |
| Feature ViewModels | Business logic + API calls for each tab | `NetworkService`, `Models` | One per tab; scoped to session lifetime via `MainTabView` |
| Views | Pure UI; no service calls | Feature ViewModels via `@EnvironmentObject` | Auth/, Onboarding/, Main/ (tabs), Shared/ (components) |
| Models | Codable structs | Foundation only | `Job`, `AppliedJob`, `User`, `UserProfile`, `Email`, `Referral`, `SubscriptionPlan` |

---

## Configuration Architecture: The Root Problem

### How `API_DOMAIN` flows from xcconfig to URLRequest

```
Config.xcconfig
  └─ API_DOMAIN = https://$()/jobharvest-api.com     ← BUG: wrong value
       |
  Info.plist (via $(API_DOMAIN) substitution in build settings)
       |
  Bundle.main.infoDictionary["API_DOMAIN"]
       |
  AppConfig.apiDomain (Constants.swift:5)
       |
  NetworkService.baseURL (computed property)
       |
  Every URLRequest constructed by NetworkService
```

The fix is in one place: `Config.xcconfig` line 8. Change `https://$()/jobharvest-api.com` to `https://dev.jobharvest-api.com`. Every API call in the entire app will immediately route to the correct backend.

**Secondary risk:** `AppConfig.apiDomain` falls back to `"https://jobharvest-api.com"` (production) if the xcconfig key is missing. This means a fresh clone without a properly configured `Config.xcconfig` silently hits production. The safe fix is to make missing config a `fatalError` in DEBUG builds.

### Amplify Configuration Flow

```
amplifyconfiguration.json (not committed)
  └─ Auth.Default.authenticationFlowType: USER_SRP_AUTH
  └─ Auth.Default.OAuth (hosted UI domain: auth.dev.jobharvest.com)
  └─ CognitoUserPool: UserPoolId, AppClientId, region
  └─ CognitoIdentityPool: IdentityPoolId, region
  └─ S3TransferUtility: bucket, region
       |
  FlashApplyApp.init() → Amplify.configure() → reads above file
       |
  AWSCognitoAuthPlugin → handles all Cognito token flows
  AWSS3StoragePlugin   → configured but likely unused (uploads go via presigned URL)
```

**Key constraint:** `amplifyconfiguration.json` must match the Cognito pools for the same environment as `API_DOMAIN`. Using dev API with prod Cognito pools (or vice versa) will cause auth rejections from the backend Lambda authorizer even after fixing the domain.

### Environment Configuration Pattern (Recommended)

The current single-file xcconfig approach works but has no environment separation. The recommended pattern for this codebase is:

**Two xcconfig files per build configuration:**

```
Config.xcconfig           ← Dev (Debug scheme, current file)
Config.Release.xcconfig   ← Prod (Release scheme)
```

In Xcode Project Settings → Build Configurations:
- `Debug` → references `Config.xcconfig` (API_DOMAIN = dev.jobharvest-api.com)
- `Release` → references `Config.Release.xcconfig` (API_DOMAIN = jobharvest-api.com)

This means no code changes are needed when building for prod — the scheme determines the target. The `#if DEBUG` guards already in `NetworkService` and `AuthService` align naturally with this split.

**Companion: separate amplifyconfiguration files per environment:**

```
amplifyconfiguration.dev.json   ← dev Cognito pools (us-west-1_z834cixlP)
amplifyconfiguration.prod.json  ← prod Cognito pools (different pools)
amplifyconfiguration.json       ← symlinked or copied by build phase script
```

A Run Script build phase can copy the correct file based on `$CONFIGURATION` (Debug vs Release) before Amplify reads it at runtime.

---

## Data Flow: Authenticated API Request

```
View event (e.g., onAppear, button tap)
  └─ ViewModel async method call
       └─ NetworkService.request(_:method:body:)
            ├─ AuthService.getIdToken()
            │    └─ Amplify.Auth.fetchAuthSession() → CognitoTokens.idToken
            ├─ AuthService.getIdentityId()
            │    └─ Amplify.Auth.fetchAuthSession() → identityId
            └─ URLSession.data(for: request)
                 └─ HTTP response
                      ├─ 200–299 → JSONDecoder → T → ViewModel @Published update → SwiftUI re-render
                      ├─ 401/403 → NetworkError.unauthorized → ViewModel.error = message → View alert
                      └─ other → NetworkError.serverError → ViewModel.error = message → View alert
```

Token refresh is transparent: Amplify's `fetchAuthSession()` refreshes the token using the refresh token if the ID token is expired. The app never handles token expiry explicitly.

## Data Flow: Auth State Machine

```
App Launch
  └─ FlashApplyApp.body → AppRouter rendered
       └─ AppRouter.task → authVM.checkAuthState()
            └─ AuthService.isSignedIn() → Amplify.Auth.fetchAuthSession()
                 ├─ isSignedIn=false → SignInView
                 └─ isSignedIn=true
                      └─ AuthService.isFirstLogin() → getUserAttributes()["custom:firstLogin"]
                           ├─ true → PreferencesQuizView
                           └─ false → MainTabView

Runtime Events (Amplify Hub)
  └─ AppRouter.listenToAuthEvents()
       ├─ signedIn → authVM.checkAuthState() (re-run above)
       ├─ signedOut → authVM.handleSignOut() → zeroes all state → AppRouter shows SignInView
       └─ sessionExpired → same as signedOut
```

## Data Flow: Profile Completeness Check

Profile completeness is currently implicit — there is no computed `isComplete` property or validation gate. The completeness problem manifests as:

```
PreferencesQuizView (onboarding)
  └─ Creates its own @StateObject ProfileViewModel (isolated)
       └─ submitProfile() → POST /users/{userId}/profile
            └─ authVM.setFirstLoginComplete() → updates custom:firstLogin
                 └─ AppRouter detects signedIn event → checkAuthState → MainTabView

MainTabView
  └─ Creates NEW ProfileViewModel (no knowledge of onboarding data)
       └─ loadProfile() → GET /users/{userId}/profile  (redundant fetch)
```

The profile data model (`UserProfile`) has these completeness-relevant fields:
- Identity: `firstName`, `lastName`, `email`, `phone`, `location`
- Job preferences: `desiredRoles`, `desiredLocations`, `jobType`, `salaryMin`
- Skills: `skills[]`
- Work history: `workHistory[]` (`WorkHistoryEntry`)
- Education: `education[]` (`EducationEntry`)
- Files: `resumeFileName`, `transcriptFileName`
- Account: `plan` (subscription tier)

There is no field validation layer — validation is done inline per-view with extensions like `String.isValidEmail`.

---

## Patterns to Follow

### Pattern 1: Build-Time Configuration via xcconfig

**What:** All environment-specific values (API domain, bucket name, keys) live in xcconfig files, not in code. They are read once at startup via `AppConfig` (an enum with static computed properties reading `Bundle.main.infoDictionary`).

**When:** Any value that differs between dev and prod, or that must not be committed to source control.

**Why it works for this codebase:** The pattern is already fully implemented — `AppConfig`, the Info.plist entries, and the xcconfig plumbing are all in place. The only work is correcting the value in `Config.xcconfig` and adding a release variant.

```swift
// AppConfig reads a key that was set by xcconfig → Info.plist substitution
static let apiDomain = Bundle.main.infoDictionary?["API_DOMAIN"] as? String ?? "https://fallback.com"

// In Config.xcconfig:
API_DOMAIN = https://dev.jobharvest-api.com
```

### Pattern 2: EnvironmentObject for Cross-Cutting State

**What:** `AuthViewModel` is instantiated once at the `WindowGroup` level and passed down via `.environmentObject()`. It is the single source of truth for auth state.

**When:** Any state that multiple unrelated subtrees need (auth, user identity, theming).

**Why:** Feature ViewModels do not own auth — they receive tokens on demand via `AuthService`. This prevents cross-ViewModel dependencies.

### Pattern 3: Optimistic Update with Revert

**What:** `ProfileViewModel.updateProfile` saves the current profile locally, then fires the API call. On failure, it restores the pre-save state.

**When:** Any write operation where the user expects immediate feedback.

```swift
let previous = profile
profile = updated  // optimistic
do {
    try await network.request(...)
} catch {
    profile = previous  // revert
    self.error = error.localizedDescription
}
```

### Pattern 4: Feature-Scoped ViewModel Lifetime

**What:** All feature ViewModels (`JobCardsViewModel`, `ProfileViewModel`, etc.) are `@StateObject` in `MainTabView`, not in individual tab views. They persist for the entire authenticated session and are destroyed when `MainTabView` is unmounted (on sign-out).

**When:** Any ViewModel that must survive tab switches.

**Why:** State is not lost when the user switches tabs. `AppliedJobsViewModel` loaded data remains available when the user returns to My Jobs.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Hub Listener Token in View State

**What:** `AppRouter` stores the Amplify Hub unsubscribe token in `@State private var hubToken`.

**Why bad:** SwiftUI may recreate `AppRouter` during scene transitions. If this happens, the old token leaks and two Hub listeners fire for every auth event. This would cause double state transitions — a sign-out would call `handleSignOut()` twice.

**Instead:** Move `hubToken` storage into `AuthViewModel`, which has a guaranteed stable lifetime as a root `@StateObject`. The auth event subscription should live inside the ViewModel, not the View.

### Anti-Pattern 2: Isolated ViewModel in Onboarding

**What:** `PreferencesQuizView` creates `@StateObject private var profileVM = ProfileViewModel()` instead of receiving the shared instance via `@EnvironmentObject`.

**Why bad:** After onboarding completes and `MainTabView` mounts, `MainTabView` creates its own fresh `ProfileViewModel` that does a redundant network fetch. The profile data from onboarding is discarded.

**Instead:** Pass the `ProfileViewModel` instance down from `AppRouter` (which could create it as `@StateObject` alongside `AuthViewModel`) so the same instance transitions from onboarding to the main session.

### Anti-Pattern 3: Production Fallback in Config

**What:** `AppConfig.apiDomain` falls back to `"https://jobharvest-api.com"` (production) if `API_DOMAIN` is missing.

**Why bad:** A developer running a fresh clone without configuring `Config.xcconfig` silently hits the production API from a debug build. This can corrupt production data or trigger real Stripe charges.

**Instead:**
```swift
// In DEBUG, refuse to run with a missing or fallback domain
static let apiDomain: String = {
    #if DEBUG
    guard let domain = Bundle.main.infoDictionary?["API_DOMAIN"] as? String,
          !domain.isEmpty else {
        fatalError("API_DOMAIN not set in Config.xcconfig. Copy Config.xcconfig.template and configure it.")
    }
    return domain
    #else
    return Bundle.main.infoDictionary?["API_DOMAIN"] as? String ?? "https://jobharvest-api.com"
    #endif
}()
```

### Anti-Pattern 4: Treating 401 and 403 as the Same Error

**What:** `NetworkService.execute` handles both 401 and 403 with `throw NetworkError.unauthorized` and logs them identically.

**Why bad:** For this backend, a 403 from `/users/{userId}/jobs` means "swipes exhausted" and is correctly caught by `JobCardsViewModel`. But a 403 from other endpoints (like the current API domain misconfiguration) also triggers `NetworkError.unauthorized`, surfacing a misleading "Session expired" message to users when the real problem is a wrong endpoint domain.

**Instead:** Distinguish 403 at the ViewModel layer for endpoints where it has domain-specific meaning. The current `JobCardsViewModel` handling of 403 is correct — extend this pattern.

---

## Component Build Order (Dependency Graph)

This is the natural sequence for touching components in this milestone, given dependencies:

```
1. Config.xcconfig (no dependencies)
   └─ Unblocks everything

2. amplifyconfiguration.json verification (no code dependencies)
   └─ Unblocks Cognito auth and S3

3. AppConfig (Utils/Constants.swift)
   └─ Feeds NetworkService.baseURL
   └─ Should add DEBUG fatalError guard here

4. NetworkService (Services/)
   └─ All ViewModels depend on this working correctly

5. AuthService + AuthViewModel (Services/ + ViewModels/)
   └─ AppRouter depends on AuthViewModel
   └─ NetworkService depends on AuthService for tokens

6. ProfileViewModel + UserProfile model
   └─ Onboarding and Profile tab both depend on this
   └─ Profile completeness work happens here

7. Feature ViewModels (JobCardsVM, AppliedJobsVM, MailboxVM, SubscriptionVM, ReferralVM)
   └─ All depend on NetworkService being pointed at the correct domain
   └─ Most "just work" once API domain is fixed

8. Views (all tabs)
   └─ Polish, error states, empty states, loading states
   └─ No new structural dependencies — purely presentational improvements
```

---

## Scalability Considerations

| Concern | Current State | At this Milestone | Future Concern |
|---------|---------------|------------------|----------------|
| API domain switching | Single xcconfig, wrong value | Fix value + add Release variant | Multi-region: add `REGION` to xcconfig |
| Amplify config | Single JSON, not committed | Verify pools, add template files | Separate dev/prod JSON files per environment |
| Auth token refresh | Transparent via Amplify | No changes needed | Token rotation issues surface at scale via Amplify Hub `sessionExpired` events |
| Profile data size | Full object sent on every update | Document the limitation | Implement PATCH endpoint to send only changed fields |
| Job card deck | seenUrls grows indefinitely in memory | Not blocking now | Cap at ~200 entries or move deduplication entirely to server |
| ViewModel lifetime | Session-scoped via MainTabView | Correct pattern | Add `onSignOut` cleanup hooks if ViewModels accumulate background tasks |

---

## Suggested Build Order for Roadmap Phases

Based on the dependency graph and blocking nature of the API domain issue:

**Phase 1 — Unblock connectivity (config layer)**
Address `Config.xcconfig`, verify `amplifyconfiguration.json`, add template files, add DEBUG fatalError guard in `AppConfig`. No ViewModel or View changes. This is a pure configuration phase that unblocks every other phase.

**Phase 2 — Complete profile data model**
The `UserProfile` model and `ProfileViewModel` need to be verified against what the backend actually stores. Profile completeness (all onboarding fields present, editable in the Profile tab) must be confirmed end-to-end. The isolated-ViewModel issue in `PreferencesQuizView` should be resolved here.

**Phase 3 — Feature verification and polish**
With connectivity restored and profile data solid, verify each feature tab (swipe, applied jobs, mailbox, subscription, referrals) works against the dev backend. Polish UX: loading states, error states, empty states, consistent design language.

**Phase 4 — Hardening**
Address known fragile areas (Hub token in `@State`, `seenUrls` memory growth, `SubscriptionViewModel.currentPlan` initialization) and fill the most critical test coverage gaps (auth state machine, swipe VM, NetworkService error paths).

---

## Sources

- Direct codebase analysis: `JobHarvest/Config.xcconfig`, `JobHarvest/Utils/Constants.swift`, `JobHarvest/Services/NetworkService.swift`, `JobHarvest/Services/AuthService.swift`
- `.planning/codebase/ARCHITECTURE.md` — existing architecture documentation (HIGH confidence, written from live code)
- `.planning/codebase/CONCERNS.md` — fragile areas, known bugs, security concerns (HIGH confidence, written from live code)
- `.planning/codebase/INTEGRATIONS.md` — external service integration details (HIGH confidence, written from live code)
- `.planning/PROJECT.md` — milestone requirements and constraints
- Xcode xcconfig + Info.plist substitution: standard iOS build system pattern (HIGH confidence, stable Apple API)
- Amplify Hub event handling: documented in amplify-swift 2.x (HIGH confidence, patterns validated in Amplify SDK source at `.build/index-build/checkouts/amplify-swift/`)
