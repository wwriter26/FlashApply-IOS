# Technology Stack

**Project:** FlashApply iOS
**Researched:** 2026-03-11

---

## Existing Stack (Do Not Change)

These are locked constraints from PROJECT.md. Research assumes these stay in place.

| Technology | Version | Role |
|------------|---------|------|
| Swift | 5.9 | Primary language |
| SwiftUI | iOS 16+ | 100% of UI |
| Combine | stdlib | `@Published` / `ObservableObject` reactivity |
| URLSession | stdlib | All REST calls to backend |
| amplify-swift | 2.53.3 | Cognito auth + S3 storage |
| AWSCognitoAuthPlugin | (part of Amplify) | User pool + identity pool auth |
| AWSS3StoragePlugin | (part of Amplify) | S3 file storage |
| stripe-ios | 23.x | Stripe publishable key (web checkout only) |
| os.Logger | stdlib | Structured logging |
| Swift Testing | stdlib (Xcode 16) | Unit test framework |
| XCTest | stdlib | UI test framework |
| Swift Package Manager | — | Dependency management |

---

## Recommended Additions

These are libraries and patterns that should be added to support the active milestone work. Each addition is scoped to a specific gap in the current codebase.

### Image Caching

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| SDWebImageSwiftUI | 3.1.x | Cached async image loading (company logos) | `AsyncImage` has no disk or memory cache beyond iOS's default `URLCache`. `CompanyLogoView` creates a new fetch on every view appearance and tab switch. Clearbit logos are fetched on every render of the card deck (3 simultaneous cards). `SDWebImageSwiftUI` provides a `WebImage` view that is a drop-in replacement with automatic NSCache memory caching and disk caching. It handles placeholder/failure states natively. HIGH confidence — this is the standard iOS solution for this problem. |

**What NOT to use:**
- `KingfisherSwiftUI` — Also excellent, but SDWebImage has broader Objective-C ecosystem support and SDWebImageSwiftUI's `WebImage` API is simpler for this use case. Either works; pick one.
- Custom `NSCache` wrapper — Adds maintenance burden for a solved problem.

**SPM URL:** `https://github.com/SDWebImage/SDWebImageSwiftUI`

---

### Crash Reporting & Error Tracking

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Firebase Crashlytics | via firebase-ios-sdk 11.x | Crash reports + non-fatal error tracking | The codebase has zero crash reporting (INTEGRATIONS.md confirms no Sentry/Crashlytics). All errors are swallowed into `self.error = error.localizedDescription` strings with no external visibility. Crashlytics is the iOS standard: free tier covers all needs, integrates with `os.Logger`, and surfaces crash symbolication and `NSException` traces. The alternative (Sentry) is equally capable but heavier. |

**Confidence: MEDIUM** — Firebase SDK is well-established but brings a large SPM footprint. If the team already has a Firebase project for the web app, this is a zero-cost addition. If not, Sentry iOS SDK (`sentry-cocoa`) is a lighter alternative with the same capability.

**What NOT to use:**
- `NSSetUncaughtExceptionHandler` roll-your-own — Misses `EXC_BAD_ACCESS` and signal-level crashes entirely.
- Apple's native MetricKit crash reports — Too delayed and coarse for debugging active development.

---

### Linting / Code Quality

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| SwiftLint | 0.57.x | Automated style enforcement | CONVENTIONS.md acknowledges no linting is configured and convention conformance is manual. For a polish milestone, enforcing consistent style prevents regressions. SwiftLint integrates as an Xcode build phase (SPM or Homebrew). The existing code already follows the conventions SwiftLint would enforce (4-space indent, PascalCase, access control). Adding it now means a clean initial run with few violations. |

**Confidence: HIGH** — SwiftLint is the undisputed iOS linting standard.

**What NOT to use:**
- SwiftFormat — Good, but it auto-mutates files which is risky on an existing codebase mid-milestone. SwiftLint is lint-only (warns, does not rewrite) which is safer.
- Periphery (dead code detection) — Useful later, but not relevant to a polish milestone.

**SPM URL:** `https://github.com/realm/SwiftLint`

---

## Configuration Changes Required (Not New Libraries)

These are not new dependencies but required changes to make the existing stack work correctly.

### API Domain Fix

**File:** `JobHarvest/Config.xcconfig`

**Change:** `API_DOMAIN = https://dev.jobharvest-api.com`

**Why this is the root cause of all 403s:** `AppConfig.apiDomain` falls back to `"https://jobharvest-api.com"` (the production domain) when `API_DOMAIN` is set to the production URL. The dev backend is at `dev.jobharvest-api.com`. All authenticated requests through `NetworkService` are hitting the wrong backend.

**Confidence: HIGH** — Explicitly documented in PROJECT.md as the known root cause.

---

### Amplify Configuration Verification

**File:** `JobHarvest/amplifyconfiguration.json`

**Required values to verify:**
- `userPoolId`: `us-west-1_z834cixlP`
- `appClientId`: `7iqq53i9msqs73cu7fmepoa1qr`
- `identityPoolId`: `us-west-1:cbaab5f0-ad40-4adb-80d0-608883f0078e`
- Region: `us-west-1`

These are confirmed in INTEGRATIONS.md. The file is gitignored but the values are known; verification means confirming the local file matches these IDs.

**Confidence: HIGH**

---

## Testing Infrastructure Pattern (No New Library)

The project already has Swift Testing + XCTest. The gap is architectural: `NetworkService`, `AuthService`, and `FileUploadService` are concrete singletons with `private init()` — they cannot be swapped in tests.

**Recommended pattern (no new dependency):**

Extract a `NetworkServiceProtocol` and inject via initializer, keeping `.shared` for production:

```swift
protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: String, method: String, body: (any Encodable)?) async throws -> T
}

extension NetworkService: NetworkServiceProtocol {}
```

This enables `MockNetworkService` for ViewModel unit tests without adding a mocking framework.

**What NOT to use:**
- `Mockingbird` or `Cuckoo` (code-generation mocking frameworks) — Over-engineered for this codebase size. Protocol-based handwritten mocks are sufficient and match the existing code style.
- `OHHTTPStubs` — URLSession stubbing at the HTTP layer is useful but still cannot test ViewModel error-handling paths (the ViewModel catches typed `NetworkError`, not raw HTTP responses).

**Confidence: HIGH** — Pattern is consistent with existing conventions (singleton with `.shared`, `private init()`).

---

## What NOT to Add

| Library | Why Not |
|---------|---------|
| Alamofire | URLSession is already in use and working. Alamofire adds ~2MB and a maintenance burden for zero functional gain on this codebase. |
| RxSwift / ReactiveSwift | Combine is already imported. Adding a second reactive framework would create dual-paradigm confusion with no benefit. |
| Realm / CoreData | No offline persistence requirement in scope. Adding a persistence layer mid-milestone introduces schema migration complexity for zero user-facing value. |
| StoreKit / RevenueCat | PROJECT.md explicitly rules out native IAP. Stripe web checkout is the payment path. |
| SnapKit / UIKit AutoLayout | The app is 100% SwiftUI. Mixing UIKit layout is a regression, not polish. |
| SwiftGen | Asset code generation is useful but a refactor risk mid-polish-milestone. The existing `Color` extension pattern (`.flashTeal`, `.flashNavy`) already provides type-safe color access. |
| Lottie | No animation assets exist or are planned. Adding Lottie for loading spinners is over-engineering; SwiftUI's built-in `ProgressView` and `withAnimation` cover all loading/transition needs. |
| Introspect / SwiftUIX | These UIKit-reach-through libraries are fragile across iOS versions. All needed UI patterns (sheets, cards, lists, drag gestures) are achievable in native SwiftUI on iOS 16+. |

---

## Version Pinning Notes

**amplify-swift:** Currently pinned to 2.53.3 in `Package.resolved`. Do not upgrade during this milestone — the Amplify 2.x → 3.x migration is a breaking change and is out of scope.

**aws-sdk-swift:** At 1.6.7 as a transitive dependency. Do not manually pin; let Amplify's SPM resolution manage this.

**stripe-ios:** At 23.x per CLAUDE.md. This is used only for the publishable key constant — no SDK initialization occurs in the current implementation (checkout is web-only). Pin to the current minor at `~> 23.0`.

---

## iOS Version Target Clarification

**CLAUDE.md states iOS 16.0+.** The codebase STACK.md records `iOS 26.2+` which is likely an Xcode display artifact (iOS 26 does not exist as of 2026-03-11; the latest release is iOS 18.x). The deployment target in `project.pbxproj` should be verified and corrected to `16.0` to match CLAUDE.md and the PROJECT.md constraint (`iOS 16+`).

**Confidence: HIGH** — CLAUDE.md is the authoritative developer documentation. `26.2` in the Xcode project is almost certainly a misread of the Xcode version (Xcode 16.2) being conflated with the deployment target, or a placeholder.

---

## Sources

- PROJECT.md — Constraints, active requirements, out-of-scope decisions
- .planning/codebase/STACK.md — Existing dependency inventory from source analysis
- .planning/codebase/ARCHITECTURE.md — Singleton service patterns, data flow
- .planning/codebase/CONCERNS.md — Performance bottlenecks (`CompanyLogoView`, `htmlDecoded`), fragile areas, tech debt
- .planning/codebase/INTEGRATIONS.md — Cognito pool IDs, API endpoints, Stripe integration pattern
- .planning/codebase/TESTING.md — Swift Testing framework, mocking gap, test structure
- .planning/codebase/CONVENTIONS.md — Naming patterns, actor isolation, singleton pattern
- CLAUDE.md (system context) — iOS 16+ deployment target, `stripe-ios` 23.x, build commands

**Confidence note:** All stack recommendations are based on existing codebase analysis (HIGH confidence) and established iOS ecosystem patterns (HIGH confidence). No WebSearch was available during this research session, so current library version numbers for SDWebImageSwiftUI, SwiftLint, and firebase-ios-sdk are based on training knowledge current to August 2025. Verify latest patch versions via SPM before adding.
