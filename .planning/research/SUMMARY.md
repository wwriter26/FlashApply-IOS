# Research Summary

**Project:** FlashApply iOS (JobHarvest)
**Synthesized:** 2026-03-11
**Research files:** STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md

---

## Executive Summary

FlashApply iOS is a nearly complete SwiftUI MVVM application built around a swipe-to-auto-apply job discovery mechanic. The architectural foundation is sound — layered cleanly from xcconfig through services, ViewModels, and SwiftUI views — and the feature surface is remarkably complete for a first-milestone codebase. The entire app is functionally blocked today by a single configuration mistake: `Config.xcconfig` points to the wrong API domain, causing every authenticated request to hit production instead of dev, returning 403 errors across the board.

The recommended approach for this milestone is sequential unblocking: fix the xcconfig domain first (one line), verify the Amplify Cognito configuration matches the same environment, then verify each feature end-to-end against the dev backend. The core architecture needs no restructuring — it is well-built. The work is configuration fixes, targeted UX polish, and hardening known fragile areas (Hub token lifecycle, payment callback flow, profile ViewModel isolation, swipe race conditions).

The primary risks are all configuration or edge-case bugs, not architectural debt. The app has no crash reporting, no linting, and no test mocking infrastructure — these are gaps that compound future debugging difficulty. Adding SDWebImageSwiftUI for image caching and crash reporting (Crashlytics or Sentry) are the only meaningful dependency additions. The guiding principle for this milestone: do not add complexity; make what exists work correctly.

---

## Key Findings

### From STACK.md

**Core technologies (locked — do not change):**

| Technology | Rationale |
|------------|-----------|
| Swift 5.9 / SwiftUI iOS 16+ | Primary language and UI framework; 100% of UI is SwiftUI |
| Combine / `@Published` | Reactive state already wired; adding any second reactive framework would create dual-paradigm confusion |
| URLSession + NetworkService | Wraps all REST calls; Amplify tokens auto-attached; no reason to add Alamofire |
| amplify-swift 2.53.3 | Pinned — do not upgrade; Amplify 3.x is a breaking migration |
| stripe-ios 23.x | Used only for publishable key constant; checkout is web-only via SFSafariViewController |

**Recommended additions:**

| Addition | Confidence | Purpose |
|----------|------------|---------|
| SDWebImageSwiftUI 3.1.x | HIGH | `CompanyLogoView` fetches on every render with no cache; `WebImage` is a drop-in `AsyncImage` replacement with memory + disk caching |
| SwiftLint 0.57.x | HIGH | No linting configured; existing code already follows what SwiftLint enforces; add as Xcode build phase |
| Firebase Crashlytics (firebase-ios-sdk 11.x) OR sentry-cocoa | MEDIUM | Zero crash visibility today; all errors swallowed into `self.error = error.localizedDescription` strings |

**Critical configuration fixes (not new libraries):**
- `Config.xcconfig`: Change `API_DOMAIN` to `https://dev.jobharvest-api.com` — this is the root cause of all 403 errors
- `amplifyconfiguration.json`: Verify `userPoolId = us-west-1_z834cixlP`, `appClientId = 7iqq53i9msqs73cu7fmepoa1qr`, region `us-west-1` — must match the same environment as `API_DOMAIN`
- `project.pbxproj`: Verify deployment target is `16.0` (not `26.2`, which is likely Xcode version bleed-through)
- Add protocol-based dependency injection (`NetworkServiceProtocol`) for testable ViewModels — no new mocking framework needed

---

### From FEATURES.md

**Must-fix blockers (without these, the app does not function):**
1. API connectivity (xcconfig domain) — unblocks all features
2. Cognito configuration — unblocks auth
3. Swipe card exit animation — core UX moment; partial implementation has visual bugs
4. Error message humanization — every error path currently surfaces raw SDK strings
5. Payment checkout callback — `checkSessionStatus` must fire on Safari sheet dismiss to validate monetization

**Should-fix (user trust):**
6. Swipe limit progressive warning at ≤3 swipes remaining (`swipesRemaining` is already published)
7. Profile section save reliability — no unsaved-changes guard on navigation
8. Stage move optimistic update in pipeline — no optimistic update means the UI feels slow
9. Skills field in onboarding (state variable exists, UI is missing)

**Nice to have (polish):**
10. `isGreatFit` badge on card (data exists in model, badge not rendered)
11. `FlowLayout` height approximation fix (clips chips on narrow screens)
12. Applied date on pipeline cards (requires backend field addition)
13. Retry buttons on key error states

**Defer to v2+ (anti-features for this milestone):**
- Native StoreKit / IAP (explicitly out of scope; web checkout is compliant and working)
- Push notifications (explicitly v2 per PROJECT.md)
- Undo last swipe (requires backend support and backend coordination)
- Multi-resume support (backend model supports one resume)
- Chat / messaging with recruiters (Mailbox tab covers recruiter response tracking)
- Calendar / interview scheduling integration (EventKit + backend webhooks; pipeline stage is sufficient)

**Feature dependency chain:**
```
Cognito Config → Auth → All authenticated features
API Domain Fix → Resume Upload → Swipe Deck
Profile Data Quality → Auto-apply accuracy
Subscription Plan → Swipe Quota + Premium Filters
```

---

### From ARCHITECTURE.md

**Layer stack (bottom to top):**
```
AWS Cognito / S3 / API Gateway
  → Amplify SDK (AWSCognitoAuthPlugin, AWSS3StoragePlugin)
  → Services: AuthService, NetworkService, FileUploadService
  → ViewModels: AuthVM, JobCardsVM, ProfileVM, AppliedJobsVM, MailboxVM, SubscriptionVM, ReferralVM
  → Views: AppRouter → MainTabView → 5 tab subtrees
```

**Key patterns to follow:**
- Build-time config via xcconfig → Info.plist → `AppConfig` enum (pattern fully in place; just needs correct values)
- `AuthViewModel` as root `@EnvironmentObject` — single source of truth for auth state, never deallocated during session
- Feature ViewModels as `@StateObject` in `MainTabView` — survive tab switches, destroyed on sign-out
- Optimistic update with revert (`ProfileViewModel.updateProfile` already demonstrates this; extend to pipeline stage moves)

**Anti-patterns to fix:**
- Hub listener `UnsubscribeToken` stored in `@State` on `AppRouter` — should move to `AuthViewModel` to prevent duplicate listeners on view recreation
- `PreferencesQuizView` creates its own `ProfileViewModel` instance — causes double network fetch on onboarding completion; the shared instance should come from `AppRouter`
- `AppConfig.apiDomain` falls back silently to production — replace nil-coalescing fallback with `#if DEBUG fatalError(...)` guard

**Component build order (dependencies):**
1. `Config.xcconfig` (no dependencies; unblocks everything)
2. `amplifyconfiguration.json` verification (no code dependencies; unblocks Cognito)
3. `AppConfig` DEBUG guard (feeds `NetworkService.baseURL`)
4. `NetworkService` error classification (all ViewModels depend on this)
5. `AuthService` + `AuthViewModel` (AppRouter depends on these)
6. `ProfileViewModel` + `UserProfile` model (onboarding and profile tab)
7. Feature ViewModels (all depend on NetworkService pointing at correct domain)
8. Views (pure presentational polish; no new structural dependencies)

---

### From PITFALLS.md

**Top 5 pitfalls with prevention strategies:**

| Pitfall | Severity | Prevention |
|---------|----------|------------|
| xcconfig `API_DOMAIN` falls back to production in debug | CRITICAL | Fix xcconfig value; add `#if DEBUG fatalError` guard in `AppConfig`; commit `.template` files |
| `amplifyconfiguration.json` pointing to wrong Cognito pool | CRITICAL | Verify pool IDs match API environment; add startup diagnostic log showing first 8 chars of pool ID alongside `API_DOMAIN` |
| Amplify `configure()` swallows errors silently — app hangs on `LoadingView` | CRITICAL | Wrap `Amplify.configure()` catch in `#if DEBUG fatalError(...)` |
| `isFirstLogin()` error branch returns `false` — new users bypass onboarding | CRITICAL | Change error branch default to `return true` (conservative: show onboarding on error) |
| `SubscriptionViewModel.currentPlan` always initializes to `.free` | HIGH | Bridge `profileVM.profile.plan` to `PremiumView` on appear; do not rely on `checkSessionStatus` for initial plan display |

**Additional pitfalls requiring phase-specific attention:**

| Phase | Pitfall |
|-------|---------|
| Swipe UX | Card snap-back animation glitch on manual-input jobs (Pitfall 5); fetch race condition on rapid swipes (Pitfall 11) |
| Applied jobs | False "No Applications Yet" for users with advanced-stage jobs (Pitfall 9) — one-line fix |
| Profile | Mutable computed IDs on `WorkHistoryEntry`/`EducationEntry` cause ForEach flicker/crashes (Pitfall 8) |
| Payment | No return-URL handler on Stripe Safari checkout — plan never updates after payment (Pitfall 12) |
| Global polish | `seenUrls` set grows unbounded in memory (Pitfall 10); stale `authVM.email` after email change (Pitfall 15) |

---

## Implications for Roadmap

The research converges clearly on a 4-phase structure. The ordering is not a preference — it is dictated by the dependency graph: nothing works until Phase 1 is complete.

### Suggested Phase Structure

**Phase 1: Connectivity Unblock (Configuration Layer)**
- Rationale: 100% of authenticated features are blocked by one xcconfig value. This phase has no ViewModel or View changes — it is pure configuration. It must come first.
- Delivers: A working dev environment where API calls reach the correct backend and Cognito auth tokens are valid
- Features from FEATURES.md: Unblocks all features
- Pitfalls to address: Pitfalls 1, 2, 3 (xcconfig domain, Cognito pool mismatch, silent Amplify failure)
- Tasks: Fix `Config.xcconfig` `API_DOMAIN`, verify `amplifyconfiguration.json` pool IDs, add `#if DEBUG fatalError` in `AppConfig`, add template files with setup instructions, add Release xcconfig variant
- Research flag: NONE NEEDED — all patterns are well-documented and implementation paths are specific

**Phase 2: Auth and Profile Foundation**
- Rationale: Auth state correctness and profile data completeness underpin every other feature. Onboarding must route correctly, and profile data must be shared (not duplicated) across the onboarding-to-main-app transition.
- Delivers: Correct first-run onboarding flow, shared `ProfileViewModel` instance, reliable profile saves, stable `WorkHistoryEntry`/`EducationEntry` identifiers
- Features from FEATURES.md: Profile completeness, onboarding quiz, auth flows
- Pitfalls to address: Pitfalls 4, 7, 8, 14 (`isFirstLogin` error branch, isolated `ProfileViewModel`, mutable computed IDs, main-thread file read)
- Research flag: NONE NEEDED — all fixes are specific code changes identified in research

**Phase 3: Feature Verification and UX Polish**
- Rationale: With connectivity and auth solid, each feature tab can be verified end-to-end against the dev backend. UX polish (animations, error messages, loading states) belongs here because it requires a working backend to test against.
- Delivers: Correct swipe animations, humanized error messages, working payment callback, accurate pipeline state, functional mailbox and referral tabs
- Features from FEATURES.md: All "Must Fix" and "Should Fix" items — swipe card exit animation, progressive swipe limit warning, payment callback, stage move optimistic update, `isGreatFit` badge, skills onboarding field
- Pitfalls to address: Pitfalls 5, 6, 9, 11, 12 (swipe snap-back, currentPlan initialization, false empty state, fetch race condition, Stripe return URL)
- Research flag: Phase 3 payment integration (Stripe `success_url` deep-link wiring) likely benefits from `/gsd:research-phase` — the URL scheme configuration and backend coordination are not fully specified in existing research

**Phase 4: Hardening and Observability**
- Rationale: The app ships without crash reporting or test coverage. This phase adds the infrastructure that prevents regressions and surfaces production issues.
- Delivers: SDWebImageSwiftUI for logo caching, Crashlytics or Sentry crash reporting, SwiftLint integration, `NetworkServiceProtocol` for testable ViewModels, Hub token moved to `AuthViewModel`, `seenUrls` cap
- Features from FEATURES.md: "Nice to have" items — `FlowLayout` fix, stale email refresh, `seenUrls` memory cap
- Pitfalls to address: Pitfalls 10, 13, 15 (`seenUrls` unbounded growth, Hub token in `@State`, stale email after update)
- Research flag: NONE NEEDED — all patterns are standard iOS/SwiftUI and fully specified in STACK.md

---

## Confidence Assessment

| Area | Confidence | Basis |
|------|------------|-------|
| Stack | HIGH | All recommendations derived from direct codebase analysis; existing dependencies inventoried from live source |
| Features | HIGH (existing) / MEDIUM (UX norms) | Feature inventory is from direct code inspection; UX pattern expectations derived from category knowledge of comparable apps |
| Architecture | HIGH | Direct file-by-file analysis; architectural patterns identified from production code, not speculation |
| Pitfalls | HIGH | Every pitfall cites a specific file and line number; all are verified bugs, not hypothetical risks |

**Overall: HIGH** — this is an unusually high-confidence research result because all four researcher agents worked primarily from direct codebase analysis, not domain speculation or external documentation.

### Gaps to Address

1. **`amplifyconfiguration.json` values are known but the file is not committed** — the pool IDs are documented in INTEGRATIONS.md but the file must be created locally before any testing can begin. This is a developer environment setup step, not a code change.

2. **Stripe `success_url` configuration** — the backend must be configured to redirect to the app's custom URL scheme after payment. The iOS-side `onOpenURL` handler pattern is clear, but the backend coordination (what URL scheme, what query parameters) is not fully specified. This gap should be surfaced to the backend team during Phase 3 planning.

3. **`appliedDate` on pipeline cards** — `AppliedJob` model has no `appliedDate` field. Adding date-applied display requires a backend schema change; this should be flagged as a backend dependency, not a purely iOS task.

4. **Library version numbers** — STACK.md research had no live WebSearch access. SDWebImageSwiftUI, SwiftLint, and firebase-ios-sdk version numbers are based on training knowledge current to August 2025. Verify latest patch versions in SPM before adding.

5. **`isGreatFit` badge rendering** — the data exists in the `Job` model but the badge is not rendered in `cardHeader`. This is a confirmed gap but its visual design (how it renders alongside `greatMatch` and `isHighPaying` badges) is not specified and may require a design decision.

---

## Sources

Aggregated from all four research files. All sources are from direct codebase analysis except where noted.

**Primary (direct codebase analysis — HIGH confidence):**
- `JobHarvest/Config.xcconfig`
- `JobHarvest/Utils/Constants.swift`
- `JobHarvest/Services/NetworkService.swift`, `AuthService.swift`, `FileUploadService.swift`
- `JobHarvest/ViewModels/` (all ViewModel files)
- `JobHarvest/Views/` (all View files)
- `JobHarvest/Models/User.swift`, `SubscriptionPlan.swift`, `Job.swift`
- `JobHarvest/App/FlashApplyApp.swift`, `AppRouter.swift`
- `.planning/PROJECT.md`, `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/CONCERNS.md`, `.planning/codebase/INTEGRATIONS.md`, `.planning/codebase/TESTING.md`, `.planning/codebase/CONVENTIONS.md`
- `CLAUDE.md`

**Secondary (established patterns — HIGH confidence):**
- Apple xcconfig / Info.plist build settings system
- Amplify Hub event handling (amplify-swift 2.x)
- SwiftUI `@EnvironmentObject` / `@StateObject` lifecycle semantics
- iOS 16+ `Layout` protocol for flow layouts

**Tertiary (category knowledge — MEDIUM confidence):**
- Swipe-based job app UX norms (Jobr, Handshake, LinkedIn mobile, Indeed mobile)
- Mobile onboarding completion patterns
- Kanban-style mobile tracking UIs
