# Phase 4: Hardening - Research

**Researched:** 2026-03-31
**Domain:** iOS crash reporting, image caching, Amplify Hub lifecycle, bounded memory structures
**Confidence:** HIGH

## Summary

Phase 4 addresses four concrete, well-scoped problems in the existing codebase. Each maps to a specific file and a specific anti-pattern that is already visible in the code.

**Problem 1 (image caching):** `CompanyLogoView.swift` uses `AsyncImage`, which has no disk or memory caching. Every render cycle that creates a new `CompanyLogoView` triggers a fresh network request. SDWebImageSwiftUI's `WebImage` is a drop-in replacement that adds both memory and disk caching with a one-line swap.

**Problem 2 (Hub duplicate events):** `AppRouter.swift` is a SwiftUI `View`. SwiftUI can re-render the body of a View multiple times during its lifetime — each time `listenToAuthEvents()` is called from `.task`, a new Hub listener is registered on top of any previous one. The `hubToken` is `@State`, which does persist across re-renders, but `.task` re-fires any time an observed value changes, so the guard against duplicate registration relies on timing rather than an explicit uniqueness check. The correct fix is to move the Hub listener into `AuthViewModel` (an `ObservableObject`), where it is guaranteed to be registered exactly once per app lifecycle.

**Problem 3 (crash reporting):** Neither Firebase Crashlytics nor Sentry is currently in the project. Sentry is the better choice for this project: no `GoogleService-Info.plist`, no run script build phase, no `-ObjC` linker flag, no dependency on Firebase Analytics. Initialization is three lines in `FlashApplyApp.init()`.

**Problem 4 (seenUrls unbounded growth):** `JobCardsViewModel.seenUrls` is a `Set<String>` that grows indefinitely. Every job URL seen in the user's session is added and never evicted. In a long session this set grows large and the `exclude` query parameter sent to the backend becomes an extremely long comma-separated string. The fix is a simple cap: when `seenUrls.count` exceeds a configurable maximum (e.g., 500), remove the oldest entries. Because `Set` has no order, the implementation needs a companion `[String]` array acting as a FIFO queue to track insertion order for eviction.

**Primary recommendation:** Four targeted, self-contained fixes in four files. No new major framework except SDWebImageSwiftUI and Sentry.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SDWebImageSwiftUI | 3.0.0+ | Cached async image loading in SwiftUI | Maintained by SDWebImage team; both memory and disk caching out of the box; `WebImage` is a structural AsyncImage replacement |
| Sentry iOS SDK (`sentry-cocoa`) | 9.x | Crash reporting and error tracking | SPM-native, no Google dependency, no build phase script, free tier covers crash reporting, actively maintained |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SDWebImageSwiftUI | Kingfisher | Both are fine; SDWebImageSwiftUI was already named in REQUIREMENTS.md (PERF-01) — use it |
| SDWebImageSwiftUI | CachedAsyncImage | Lightweight wrapper around URLCache; acceptable but weaker caching guarantees than SDWebImage's dual-layer cache |
| Sentry | Firebase Crashlytics | Crashlytics requires `GoogleService-Info.plist`, a run-script build phase for dSYM upload, `-ObjC` linker flag, and pulls in FirebaseCore. Sentry requires none of these. For a project that does not already use Firebase, Sentry is materially simpler to integrate |

**Installation:**
```bash
# Via Xcode: File > Add Packages
# SDWebImageSwiftUI
https://github.com/SDWebImage/SDWebImageSwiftUI.git  (from: "3.0.0")

# Sentry
https://github.com/getsentry/sentry-cocoa.git  (from: "9.0.0")
```

Both packages are added through Xcode's SPM UI (not Package.swift at root, which is a documentation-only manifest — the live SPM graph is managed inside `JobHarvest.xcodeproj`).

---

## Architecture Patterns

### Pattern 1: WebImage as AsyncImage Replacement

**What:** Replace `AsyncImage(url:)` in `CompanyLogoView.swift` with `WebImage(url:)`.
**When to use:** Any view that loads a remote image that will be displayed more than once in a session.

```swift
// Source: https://github.com/SDWebImage/SDWebImageSwiftUI
import SDWebImageSwiftUI

WebImage(url: url) { image in
    image.resizable().scaledToFit()
} placeholder: {
    placeholderView
}
.frame(width: size, height: size)
.cornerRadius(size * 0.2)
```

SDWebImage maintains a shared `SDImageCache` instance that handles both in-memory (NSCache) and on-disk caching automatically. No explicit cache configuration is needed for this use case.

### Pattern 2: Hub Listener in ViewModel (not View)

**What:** Move the `Amplify.Hub.listen` call from `AppRouter` (a View) to `AuthViewModel` (an ObservableObject).

**Why it fixes the problem:** `AuthViewModel` is created once in `JobHarvestApp` as `@StateObject`. Its `init` runs exactly once. A Hub listener registered in `init` (or a dedicated `setupHubListener()` called from `init`) will fire exactly once per app session.

**Why the current code has a risk:** `AppRouter.body` can be evaluated many times. `.task` re-runs when the view is re-mounted. Although `@State private var hubToken` does persist, the window between the old `.task` completing and the new one starting leaves a gap where a second listener could briefly exist.

**The correct pattern:**

```swift
// In AuthViewModel.swift
@MainActor
final class AuthViewModel: ObservableObject {
    private var hubToken: UnsubscribeToken?

    init() {
        setupHubListener()
    }

    deinit {
        if let token = hubToken {
            Amplify.Hub.removeListener(token)
        }
    }

    private func setupHubListener() {
        hubToken = Amplify.Hub.listen(to: .auth) { [weak self] payload in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch payload.eventName {
                case HubPayload.EventName.Auth.signedIn:
                    await self.checkAuthState()
                case HubPayload.EventName.Auth.signedOut,
                     HubPayload.EventName.Auth.sessionExpired:
                    self.handleSignOut()
                default:
                    break
                }
            }
        }
    }
}
```

Then in `AppRouter`, remove `listenToAuthEvents()` and the `hubToken` `@State` property. The `.task` block becomes `await authVM.checkAuthState()` only.

**`[weak self]` is required** — `Amplify.Hub` retains the closure; without `[weak self]` the ViewModel will never be deallocated.

### Pattern 3: Sentry Initialization

**What:** Initialize the Sentry SDK as early as possible in app startup.

```swift
// In FlashApplyApp.swift
import Sentry

init() {
    configureSentry()
    configureAmplify()
}

private func configureSentry() {
    SentrySDK.start { options in
        options.dsn = AppConfig.sentryDsn  // add to Config.xcconfig + Constants.swift
        options.environment = AppConfig.isDebug ? "debug" : "production"
        options.debug = AppConfig.isDebug
        // Disable in DEBUG to avoid noise during development:
        options.enabled = !AppConfig.isDebug
    }
}
```

The DSN is a non-secret public identifier. Store it in `Config.xcconfig` as `SENTRY_DSN` and expose it through `AppConfig` in `Constants.swift`, following the same pattern as `API_DOMAIN`.

### Pattern 4: Bounded seenUrls Set

**What:** Cap `seenUrls` at a configurable maximum, evicting the oldest URLs (FIFO) when the cap is exceeded.

**Why Set alone is insufficient for eviction:** `Set<String>` has no insertion-order tracking. To evict the oldest entry you need an ordered companion structure.

```swift
// In JobCardsViewModel.swift
private static let seenUrlsCap = 500

private var seenUrls: Set<String> = []
private var seenUrlsOrder: [String] = []   // FIFO queue for eviction

private func recordSeen(_ url: String) {
    guard !seenUrls.contains(url) else { return }
    seenUrls.insert(url)
    seenUrlsOrder.append(url)
    if seenUrlsOrder.count > Self.seenUrlsCap {
        let evicted = seenUrlsOrder.removeFirst()
        seenUrls.remove(evicted)
    }
}
```

Call `recordSeen($0.jobUrl)` instead of `seenUrls.insert($0.jobUrl)` in `fetchJobs`. The `reset()` method must also clear `seenUrlsOrder`.

The cap of 500 is a reasonable default: at ~100 bytes per URL, 500 entries is ~50 KB — negligible memory. The primary benefit is keeping the `exclude` query parameter short enough for the backend to handle.

### Anti-Patterns to Avoid

- **Registering Hub listeners in a SwiftUI View body or `.task`:** View lifecycle and observer lifecycle do not align. Use a ViewModel `init` instead.
- **Using `AsyncImage` for frequently-repeated images:** It has no caching layer — same URL = same network request every time.
- **Calling `Amplify.Hub.removeListener` in `.onDisappear`:** `AppRouter` very rarely disappears; relying on this for cleanup is fragile. Proper cleanup belongs in the ViewModel's `deinit`.
- **Storing Sentry DSN in the source file:** Even though it is a public key, treat it as configuration and keep it in `Config.xcconfig` alongside other config values.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Remote image caching | Custom NSCache wrapper around URLSession | SDWebImageSwiftUI `WebImage` | SDWebImage handles memory pressure (NSCache eviction), disk cache with LRU eviction, cancellation on view disappear, retry logic, and format decoding |
| Crash capture and symbolication | Try/catch around Task bodies | Sentry SDK | Crash reporting requires a signal handler at the OS level; Swift crashes (EXC_BAD_ACCESS, stack overflow) are not catchable with do/catch |

---

## Common Pitfalls

### Pitfall 1: Hub Listener Registered Twice on First Launch

**What goes wrong:** On cold start, `AppRouter.body` is evaluated, `.task` runs `checkAuthState()` and `listenToAuthEvents()`. If any observed value changes before the task completes (e.g., `authVM.isLoaded` flips), SwiftUI may re-evaluate body and `.task` can re-fire, producing two active listeners.

**Why it happens:** SwiftUI `.task` is tied to view identity, not content identity. It cancels and restarts when the view re-mounts.

**How to avoid:** Move listener to `AuthViewModel.init()` — guaranteed single registration.

**Warning signs:** Auth state changes (sign in, sign out) cause two navigation transitions, or `checkAuthState()` is called twice in the console logs.

### Pitfall 2: `[weak self]` Omission in Hub Closure

**What goes wrong:** `Amplify.Hub` stores the listener closure strongly. Without `[weak self]`, `AuthViewModel` is retained by the Hub indefinitely — it will never be deallocated even after sign-out.

**How to avoid:** Always capture `[weak self]` in the Hub listener closure and guard-unwrap before use.

**Warning signs:** Memory usage grows over multiple sign-in/sign-out cycles.

### Pitfall 3: Sentry Enabled in DEBUG Producing Noise

**What goes wrong:** Every `AppLogger.error` call (which is not a crash) may be captured as a Sentry event if breadcrumb capture is enabled. DEBUG sessions produce many errors (simulator, misconfigured auth, etc.) that pollute the production Sentry project.

**How to avoid:** Set `options.enabled = !AppConfig.isDebug` in the Sentry configuration, or use a separate DEBUG DSN pointing to a development Sentry project.

### Pitfall 4: seenUrlsOrder Growing Past Cap Due to Duplicates

**What goes wrong:** If `recordSeen` is called with a URL already in the set, and the guard is omitted, the URL is added to `seenUrlsOrder` again while not being added to the set — causing order and set to diverge.

**How to avoid:** The `guard !seenUrls.contains(url) else { return }` early exit in `recordSeen` prevents duplicate entries in the order array.

### Pitfall 5: Firebase Crashlytics Run Script Build Phase

**What goes wrong:** Firebase Crashlytics requires a post-build run script phase and `-ObjC` linker flag. Forgetting either causes dSYMs to not upload and crashes to appear as "Error" without stack traces.

**How to avoid:** Use Sentry instead. Sentry does not require a build phase script for basic crash reporting (dSYM upload can be done via the Sentry Xcode plugin if needed, but crashes are captured without it in most cases using inline debug info).

---

## Code Examples

### Current CompanyLogoView (broken — no cache)

```swift
// Source: JobHarvest/Views/Shared/CompanyLogoView.swift
AsyncImage(url: url) { phase in
    switch phase {
    case .success(let image):
        image.resizable().scaledToFit()
    case .failure, .empty:
        placeholderView
    @unknown default:
        placeholderView
    }
}
```

### Fixed CompanyLogoView (cached)

```swift
// Source: https://github.com/SDWebImage/SDWebImageSwiftUI
import SDWebImageSwiftUI

WebImage(url: url) { image in
    image.resizable().scaledToFit()
} placeholder: {
    placeholderView
}
```

### Current listenToAuthEvents in AppRouter (fragile)

```swift
// Source: JobHarvest/App/AppRouter.swift
// Risk: registered every time .task fires; hubToken in @State is not fully safe
hubToken = Amplify.Hub.listen(to: .auth) { payload in ... }
```

### Target pattern: listener in AuthViewModel.init

```swift
// In AuthViewModel.swift
init() {
    setupHubListener()
}

private func setupHubListener() {
    hubToken = Amplify.Hub.listen(to: .auth) { [weak self] payload in
        Task { @MainActor [weak self] in
            guard let self else { return }
            // ... handle events
        }
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `AsyncImage` for remote images | `WebImage` (SDWebImageSwiftUI) | Eliminates redundant network requests on re-render |
| Hub listener in SwiftUI View | Hub listener in ObservableObject init | Exactly-once registration guaranteed by object lifecycle |
| No crash reporting | Sentry SDK | Production crashes reported automatically with symbolicated stack traces |
| Unbounded `Set<String>` for seen URLs | Capped set with FIFO eviction | Prevents memory growth and backend query string overflow |

---

## Open Questions

1. **Sentry DSN availability**
   - What we know: Sentry account must be created and a project set up to get a DSN
   - What's unclear: Whether a Sentry account already exists for this project
   - Recommendation: Create a free-tier Sentry project during implementation; DSN goes into `Config.xcconfig` (not committed to git)

2. **`Config.xcconfig` key for Sentry DSN**
   - What we know: `Config.xcconfig` already stores `API_DOMAIN`, `STRIPE_KEY`, `BUCKET_NAME`
   - What's unclear: Whether the xcconfig file uses any value escaping for URLs (Sentry DSNs contain `//`)
   - Recommendation: Use the same `$()` escaping trick established in Phase 1 for `API_DOMAIN`: `SENTRY_DSN = https://(key)@(host)/(project_id)` — or store only the numeric project ID and key separately to avoid URL escaping entirely

3. **seenUrlsCap value**
   - What we know: The backend receives `exclude` as a comma-separated query parameter; very long query strings can cause 414 Request-URI Too Long errors
   - What's unclear: The backend's maximum query string length
   - Recommendation: Default to 500. This is conservative and can be tuned by changing `seenUrlsCap` in one place.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (Xcode 16 built-in, `import Testing`) |
| Config file | None — uses default Xcode test target `JobHarvestTests` |
| Quick run command | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JobHarvestTests` |
| Full suite command | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements to Test Map

These are behavioral requirements, not v1 requirement IDs. Each success criterion maps to a verification strategy:

| Criterion | Behavior | Test Type | Automated Command | Notes |
|-----------|----------|-----------|-------------------|-------|
| SC-1: Image caching | `WebImage` used, not `AsyncImage`, in CompanyLogoView | Unit / code inspection | Build succeeds; grep for `AsyncImage` in CompanyLogoView returns no results | Functional cache behavior requires network — manual-only |
| SC-2: Hub exactly once | Hub listener registered once; sign-in/sign-out fires `checkAuthState` exactly once | Unit | `JobHarvestTests` — mock Hub, assert single call | Wave 0 gap: test does not yet exist |
| SC-3: Crash reporting | Sentry SDK initialized; test crash reported to Sentry dashboard | Manual smoke test | Run app, trigger `SentrySDK.crash()` in debug, verify event in Sentry | Cannot be automated without a running Sentry project |
| SC-4: seenUrls bounded | After inserting > 500 URLs, set size stays at 500 | Unit | `JobHarvestTests` — insert 600 URLs, assert count == 500 and oldest URL evicted | Wave 0 gap: test does not yet exist |

### Sampling Rate
- **Per task commit:** Build succeeds (`xcodebuild build`)
- **Per wave merge:** Full test suite green
- **Phase gate:** SC-3 verified manually in Sentry dashboard before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `JobHarvest/JobHarvestTests/JobHarvestTests.swift` — add unit test for seenUrls cap (SC-4)
- [ ] `JobHarvest/JobHarvestTests/JobHarvestTests.swift` — add unit test for Hub listener single-registration (SC-2, using a mock or spy)

---

## Sources

### Primary (HIGH confidence)
- [SDWebImageSwiftUI GitHub README](https://github.com/SDWebImage/SDWebImageSwiftUI) — WebImage API, SPM URL, version 3.0.0
- [Amplify Hub Swift Docs](https://docs.amplify.aws/gen1/swift/build-a-backend/utilities/hub/) — `listen(to:)`, `removeListener(_:)`, `UnsubscribeToken` API
- [Sentry iOS SPM Install Docs](https://docs.sentry.io/platforms/apple/guides/ios/install/swift-package-manager/) — package URL, `SentrySDK.start` API
- Direct code inspection of `CompanyLogoView.swift`, `AppRouter.swift`, `AuthViewModel.swift`, `JobCardsViewModel.swift`

### Secondary (MEDIUM confidence)
- [Firebase Crashlytics iOS Get Started](https://firebase.google.com/docs/crashlytics/ios/get-started) — verified Crashlytics requires run script phase and GoogleService-Info.plist (used to confirm Sentry is simpler)
- [Sentry vs Crashlytics comparison](https://uxcam.com/blog/sentry-vs-crashlytics/) — confirms Sentry requires no Firebase dependency

### Tertiary (LOW confidence)
- Various WebSearch results on duplicate Hub listeners in SwiftUI — consistent with code inspection findings but not from an official Amplify source

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — SDWebImageSwiftUI and Sentry are well-documented with verified SPM URLs; existing code confirms the problems they solve
- Architecture: HIGH — all four patterns are verified against the actual source files in this repo
- Pitfalls: HIGH for Hub/memory issues (code-verified); MEDIUM for Sentry DSN config (relies on Config.xcconfig template pattern from Phase 1)

**Research date:** 2026-03-31
**Valid until:** 2026-06-01 (Sentry 9.x and SDWebImageSwiftUI 3.x are stable; Amplify Hub API is stable in Amplify Swift 2.x)
