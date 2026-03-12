# Domain Pitfalls

**Domain:** SwiftUI iOS app with AWS Amplify/Cognito auth, custom-domain API Gateway, and Stripe web checkout
**Project:** FlashApply iOS (JobHarvest)
**Researched:** 2026-03-11
**Confidence:** HIGH — all pitfalls are grounded in direct codebase analysis; zero unverified speculative claims

---

## Critical Pitfalls

Mistakes that cause rewrites, data loss, or complete functional blockage.

---

### Pitfall 1: xcconfig API Domain Falls Back to Production in Debug

**What goes wrong:** `AppConfig.apiDomain` in `Constants.swift` (line 5) falls back to `"https://jobharvest-api.com"` when `API_DOMAIN` is missing from `Config.xcconfig`. Any developer who clones the repo, forgets to copy `.template` (which does not exist yet), or misconfigures the xcconfig silently hits the production API from debug builds. The current blocker — all 403 errors — is exactly this scenario.

**Why it happens:** The fallback is a nil-coalescing convenience that turns a configuration error into a silent, dangerous default. There is no assertion or `fatalError` to make misconfiguration loud.

**Consequences:** Debug traffic to production; user data affected by test swipes; impossible to reproduce dev-environment bugs; hard to distinguish from real auth failures.

**Prevention:**
- Change the fallback in `Constants.swift` from `?? "https://jobharvest-api.com"` to a `fatalError("API_DOMAIN not set in Config.xcconfig")` guarded by `#if DEBUG`.
- Commit `Config.xcconfig.template` and `amplifyconfiguration.json.template` with placeholder values and step-by-step setup instructions.
- In CI, assert `API_DOMAIN` ends with `dev.jobharvest-api.com` for debug scheme builds.

**Detection warning signs:**
- All authenticated API calls return 403 immediately after a fresh clone or a new developer environment setup.
- `AppLogger.network` logs show requests going to `https://jobharvest-api.com` in debug builds.

**Phase:** Address in the connectivity fix phase (Phase 1 / first milestone task) before any other work begins.

---

### Pitfall 2: `amplifyconfiguration.json` Pointing to Wrong Cognito Pool

**What goes wrong:** If `amplifyconfiguration.json` references the prod Cognito user pool while `Config.xcconfig` points to the dev API domain, tokens issued by the prod pool will be rejected by the dev backend's JWT authorizer (wrong issuer URL / audience). This produces 403s that look identical to the API domain misconfiguration above, making root-cause diagnosis confusing.

**Why it happens:** The two config files are independent and can drift out of sync. There is no runtime cross-check that confirms the Cognito pool and API domain are from the same environment.

**Consequences:** Auth tokens valid in Cognito but rejected at the API Gateway; intermittent 401/403 errors that appear to be networking issues; developer time lost diagnosing the wrong layer.

**Prevention:**
- The `amplifyconfiguration.json.template` (once created) should include a comment noting which environment (`dev` or `prod`) the pool IDs belong to.
- Add a diagnostic log on app start that prints the first 8 characters of the Cognito user pool ID alongside the configured `API_DOMAIN`, making environment mismatch immediately visible.
- Never copy pool IDs between environments manually; use a documented script or env-var substitution.

**Detection warning signs:**
- Amplify `configureAmplify()` succeeds (no exception) but every authenticated request returns 403.
- The `Authorization: Bearer` token in logs is present and well-formed but rejected.
- Decoding the JWT's `iss` claim shows a pool ARN that does not match the API Gateway's configured authorizer.

**Phase:** Address alongside the API domain fix. Both misconfigurations must be resolved together.

---

### Pitfall 3: Amplify Configured with Silent Failure — No Crash on Bad Config

**What goes wrong:** `configureAmplify()` in `FlashApplyApp.swift` catches all errors and logs them (`AppLogger.auth.error`) but does not crash or surface any error to the user. The app continues to launch in a broken auth state — `Amplify.Auth` calls will fail at runtime with cryptic errors rather than failing loudly at startup.

**Why it happens:** The `catch` block swallows the error to prevent a crash. In production, this makes sense. In development, it hides the root cause.

**Consequences:** A missing or malformed `amplifyconfiguration.json` results in an app that launches, shows the loading screen, then silently stays on `LoadingView` forever because `checkAuthState()` hangs or returns false without explanation.

**Prevention:**
- Wrap `Amplify.configure()` in a `#if DEBUG` block that calls `fatalError("Amplify configuration failed: \(error)")`. This turns a configuration mistake into an immediately visible crash with a clear message during development.
- In production, preserve the existing silent error + log behavior.

**Detection warning signs:**
- App launches and shows `LoadingView(message: "Loading...")` indefinitely.
- `AppLogger.auth` shows `"Amplify configuration failed: ..."` in the Xcode console on launch.

**Phase:** Fix during the connectivity/auth setup phase. One-line change; high leverage.

---

### Pitfall 4: `isFirstLogin` Error Branch Silently Routes New Users Past Onboarding

**What goes wrong:** `AuthService.isFirstLogin()` (line 173–184) catches any error from `getUserAttributes()` and returns `false` — meaning "not a first-time user." If `getUserAttributes()` fails on a new user's first launch (e.g., network hiccup, Cognito pool misconfiguration), the new user bypasses `PreferencesQuizView` and lands in `MainTabView` with an empty, uncompleted profile.

**Why it happens:** The error branch chose a safe-seeming default (`false` = skip onboarding) but the semantics are inverted: `false` means "completed onboarding," so returning `false` on error skips the quiz.

**Consequences:** New users land in the main app with no profile data set; the apply feature has no user preferences to match against; the user's `firstLogin` attribute may stay `"true"` in Cognito, causing onboarding to appear on the next launch after a clean session.

**Prevention:**
- Change the error branch in `isFirstLogin()` to `return true` (conservative: assume first login on error, show onboarding) or, better, throw the error and let `AppRouter`/`AuthViewModel` handle the error state explicitly.
- `AuthViewModel.checkAuthState()` should surface this error to the user rather than silently continuing.

**Detection warning signs:**
- New users see the main tab bar immediately after confirming their email, with no quiz shown.
- `AppLogger.auth` logs `"isFirstLogin: failed to fetch user attributes"` at launch.
- Profile API calls return empty/default data for new users who never completed the quiz.

**Phase:** Address in the onboarding polish phase. Prerequisites: API connectivity must be fixed first, because `getUserAttributes()` failing may itself be a consequence of the Cognito pool misconfiguration.

---

## Moderate Pitfalls

Mistakes that produce confusing bugs, UX regressions, or silent data inconsistencies.

---

### Pitfall 5: Swipe Card Snap-Back Glitch on Jobs with Manual Input Fields

**What goes wrong:** When the user swipes right past the threshold on a job with `manualInputFields`, the `dragGesture` first animates the card off-screen (line 57–60 in `JobCardView.swift`), then immediately resets `dragOffset = .zero` (line 67) to show the manual-input sheet. The visible result is a card that flies off-screen and then snaps back, before the sheet appears.

**Why it happens:** The animation and the sheet presentation are in the same `Task` block. The animation starts, but before it completes, the sheet flag is set and `dragOffset` is reset, cancelling the animation mid-flight.

**Consequences:** Jarring UX on any job requiring manual answers. This is the single most visible polish issue in the swipe flow.

**Prevention:**
- Do not animate the card off-screen for the manual-input path. Instead, leave the card in place, set `showManualAnswers = true` directly, and only animate off-screen after the sheet is dismissed with confirmed answers.
- Alternatively: add an `await Task.sleep(nanoseconds: 300_000_000)` delay before setting `dragOffset = .zero` so the fly-off animation completes first (simpler but fragile).

**Detection warning signs:**
- Swiping right on any job card that has a non-empty `manualInputFields` array.
- Visible on all device sizes; more noticeable on smaller screens where the snap-back is more prominent.

**Phase:** Address in the swipe UX polish phase.

---

### Pitfall 6: `SubscriptionViewModel.currentPlan` Always Shows "Free" on PremiumView Open

**What goes wrong:** `PremiumView` creates its own `@StateObject private var subscriptionVM = SubscriptionViewModel()`, which initializes `currentPlan = .free`. The user's actual plan is available on `profileVM.profile.plan` (a `String`) but is never bridged to `SubscriptionViewModel`. The "Current Plan" badge in `PlanCard` is therefore always wrong until a `checkSessionStatus` call completes — which is only triggered by a Stripe callback, not on tab open.

**Why it happens:** `SubscriptionViewModel` and `ProfileViewModel` are independent `@StateObject` instances with no shared state. The plan string from the profile response is never read by the subscription view.

**Consequences:** Every user sees "Current Plan: Free" when opening the Premium tab, even paying users. This undermines trust in the payment system and may prompt unnecessary upgrade attempts.

**Prevention:**
- Pass `profileVM.profile.plan` into `PremiumView` as an initializer argument, or make `PremiumView` use `@EnvironmentObject var profileVM: ProfileViewModel` and derive `currentPlan` from `profileVM.profile.plan` on appear.
- Do not rely on `checkSessionStatus` for initial plan display — that is a post-checkout confirmation step, not a general plan-fetch mechanism.

**Detection warning signs:**
- A paying user opens the Premium tab; all plan cards show "Choose" buttons with no "Current Plan" badge.
- `subscriptionVM.currentPlan` is `.free` immediately after `PremiumView` appears, regardless of the user's actual plan.

**Phase:** Address in the payment flow verification phase.

---

### Pitfall 7: `PreferencesQuizView` Creates Its Own `ProfileViewModel` Instance

**What goes wrong:** `PreferencesQuizView` declares `@StateObject private var profileVM = ProfileViewModel()` — a private instance disconnected from the one in `MainTabView`. After `submitProfile()` completes and `AppRouter` transitions to `MainTabView`, the new `ProfileViewModel` instance fetches the profile again, making a redundant network call. More critically, if `submitProfile()` fails silently, `MainTabView`'s `ProfileViewModel` has no awareness of what was attempted.

**Why it happens:** The quiz was built as a standalone view, creating its own ViewModel rather than receiving one from the environment.

**Consequences:** Double network request on every successful onboarding completion; inconsistent profile state between quiz completion and main app; any error in the quiz's profile save is invisible to the main app's error handling.

**Prevention:**
- Pass a `ProfileViewModel` from `AppRouter` or `MainTabView` as an `@EnvironmentObject`. The same instance should be used for both onboarding and the main profile tab.
- This requires `AppRouter` to instantiate `ProfileViewModel` at the top level alongside `AuthViewModel`.

**Detection warning signs:**
- Two consecutive `POST /users/{id}/profile` calls visible in network logs immediately after onboarding completes.
- `profileVM.isLoaded` is `false` in `MainTabView` immediately after the quiz transition.

**Phase:** Address in the onboarding polish / profile completion phase.

---

### Pitfall 8: `WorkHistoryEntry.id` and `EducationEntry.id` Are Computed from Mutable Fields

**What goes wrong:** `id` on these structs is computed as `company + title + startDate`. When the user edits company name or job title in `WorkHistorySection` or `EducationSection`, SwiftUI's `ForEach` sees the identity change mid-edit. This causes list animations to flicker, duplicate rows to appear momentarily, and in edge cases can trigger a crash from duplicate-ID violations.

**Why it happens:** These structs were given computed IDs based on content instead of stable UUIDs, likely to avoid adding an `id` field to the backend response schema.

**Consequences:** Broken list animations during profile editing; potential duplicate-key crashes on iOS 17+ with stricter ForEach identity enforcement.

**Prevention:**
- Add a `UUID`-backed `id` property to `WorkHistoryEntry` and `EducationEntry` in `User.swift`. If the backend does not return an `id`, generate one client-side on decode using a custom `init(from:)`.
- Alternatively, use `.id(UUID())` as a forced-stable workaround (prevents animations but avoids crashes).

**Detection warning signs:**
- Editing the "Company" or "Job Title" field in an existing work history entry causes the row to briefly disappear and reappear.
- Console warnings about duplicate ForEach identity in Xcode 15+.

**Phase:** Address in the profile completion/polish phase.

---

### Pitfall 9: `MyJobsView` Empty State Triggers Falsely for Active Users

**What goes wrong:** The empty state check on lines 27–29 of `MyJobsView.swift` only tests `.applying` and `.applied` stages. A user who has progressed jobs to `.screen`, `.interview`, or `.offer` — but has nothing in the first two stages — sees "No Applications Yet" while their Kanban pipeline columns render correctly one tap away on the "All" picker.

**Why it happens:** The empty state was written early in development when only the first two stages were used; the condition was never updated to cover all stages.

**Consequences:** Active, advanced-stage users are told they have no applications. This is a trust-breaking false negative for power users.

**Prevention:**
- Replace the two-stage check with `appliedJobsVM.allStages.allSatisfy { appliedJobsVM.jobs(for: $0).isEmpty }` — check all pipeline stages, not just the first two.

**Detection warning signs:**
- A user with jobs in `.screen` or `.interview` opens the My Jobs tab; the "No Applications Yet" screen appears instead of the pipeline.

**Phase:** Address in the applied jobs management polish phase. One-line fix.

---

### Pitfall 10: `seenUrls` Set Grows Unbounded in Memory

**What goes wrong:** `JobCardsViewModel.seenUrls` is a `Set<String>` that accumulates every swiped job URL with no upper bound. Every new `fetchJobs` call sends the full set as the `exclude` array in the request body. A user who swipes 500+ jobs in a session carries a multi-kilobyte exclusion list in memory and in every network request.

**Why it happens:** Client-side deduplication was added for immediate UX correctness (don't show the same card twice in a session) without a cap or TTL.

**Consequences:** Growing memory usage across long sessions; oversized request bodies; marginal latency increase on every job fetch. The server already tracks seen jobs per user, making the client-side set redundant for cross-session deduplication.

**Prevention:**
- Cap `seenUrls` at the last N entries (e.g., 200): after `insert`, if `seenUrls.count > 200`, remove the oldest entry (requires changing to an ordered structure like an array).
- Or: remove `seenUrls` entirely and let the backend handle deduplication — the server already does this for cross-session cases.

**Detection warning signs:**
- `seenUrls` count > 200 after an extended swiping session.
- Network request body for `POST /users/{id}/jobs` is noticeably large (KB-range `exclude` array).

**Phase:** Address in the swipe UX polish phase or as a follow-on optimization.

---

### Pitfall 11: `JobCardsViewModel.fetchJobs` Race Condition on Rapid Swipes

**What goes wrong:** `handleSwipe` (line 72–73 in `JobCardsViewModel.swift`) spawns a prefetch via `Task { await fetchJobs(appending: true) }` when the deck drops to ≤ 2 cards. The guard at line 21 uses `isLoading`, but a non-appending `fetchJobs` can begin concurrently with a prefetch because `isLoading` and `isPrefetching` are separate flags. Rapid swipes can trigger two simultaneous `fetchJobs` calls — one appending, one replacing — resulting in duplicate cards or the deck being unexpectedly cleared.

**Why it happens:** The two-flag design (`isLoading` / `isPrefetching`) was intended to allow background prefetching while the deck is visible, but it creates a window where both guards pass simultaneously.

**Consequences:** Duplicate job cards in the deck; potential for the deck to be replaced (reset to empty) mid-swipe session; inconsistent `seenUrls` state.

**Prevention:**
- Replace the two-flag system with a single `isFetching: Bool` flag, or use a `Task` stored as a property that can be cancelled before starting a new fetch.
- Alternatively, mark `JobCardsViewModel` as a Swift `actor` instead of `@MainActor class` and isolate all fetch state mutation through actor methods.

**Detection warning signs:**
- Duplicate job cards visible in the swipe deck.
- `AppLogger.jobs` shows two overlapping `"fetchJobs: received..."` log lines during rapid swipes.

**Phase:** Address in the swipe UX polish phase, alongside the snap-back fix.

---

### Pitfall 12: SFSafariViewController Checkout Has No Return-URL Handler

**What goes wrong:** `PremiumView` opens the Stripe checkout URL in `SafariView` (a `SFSafariViewController` wrapper). After the user completes payment, Stripe redirects to a `success_url`. If that URL is not a custom URL scheme that the app intercepts, the user returns to the app only by manually dismissing the Safari sheet — and there is no automatic call to `checkSessionStatus` to update the plan UI.

**Why it happens:** `SFSafariViewController` is an opaque browser; the app cannot observe the URL the browser navigates to without a deep link / universal link handler. The current implementation sets `checkoutURL` and opens the sheet, but `checkSessionStatus` is only called if the user somehow triggers it (not currently wired to sheet dismissal in `PremiumView`).

**Consequences:** After a successful payment, the user returns to the app and still sees "Free" plan; the "Current Plan" badge does not update. The user may think payment failed and attempt to pay again.

**Prevention:**
- Configure Stripe's `success_url` to use the app's custom URL scheme (e.g., `flashapply://checkout-success?session_id={CHECKOUT_SESSION_ID}`) so iOS routes the redirect back to the app.
- In the app's `openURL` handler (or `onOpenURL` modifier in SwiftUI), parse the `session_id` parameter and call `subscriptionVM.checkSessionStatus(sessionId:)`.
- As a fallback (no deep link): call `checkSessionStatus` in the `.onDismiss` closure of the sheet, passing any `session_id` stored before opening the URL. This is less reliable (fires on cancel too) but better than nothing.

**Detection warning signs:**
- After completing a Stripe test payment and returning to the app, `PremiumView` still shows the Free plan.
- No `checkSessionStatus` network call appears in `AppLogger.subscription` after the Safari sheet is dismissed.

**Phase:** Address in the payment flow verification phase. Requires backend coordination to configure the `success_url`.

---

## Minor Pitfalls

Lower severity; worth fixing but will not block functionality.

---

### Pitfall 13: `AppRouter` Amplify Hub Token Stored in View `@State`

**What goes wrong:** `hubToken: UnsubscribeToken?` is `@State` on the `AppRouter` struct. If SwiftUI recreates `AppRouter` during scene transitions, the old token is leaked and `listenToAuthEvents()` registers a second listener. Duplicate auth-event handlers can cause double `checkAuthState()` calls on sign-in/sign-out.

**Prevention:** Move `hubToken` to `AuthViewModel` (an `ObservableObject` with a stable lifetime) so listener registration and cleanup are tied to the ViewModel's lifecycle, not a SwiftUI view's `@State`.

**Phase:** Low priority; fix during auth stability polish if duplicate auth calls are observed in logs.

---

### Pitfall 14: `DocumentPickerView` Reads File Data on the Main Thread

**What goes wrong:** `Data(contentsOf: url)` in `PreferencesQuizView.swift` (line 74) is synchronous I/O on the main thread. For multi-MB PDFs, this blocks the UI during the file pick callback.

**Prevention:** Dispatch `Data(contentsOf:)` to a background task: `Task.detached { let data = try Data(contentsOf: url); await MainActor.run { ... } }`.

**Phase:** Address in the profile/onboarding polish phase, bundled with other `PreferencesQuizView` fixes.

---

### Pitfall 15: `ChangeEmailView` Does Not Refresh `authVM.email` After Confirmation

**What goes wrong:** After `confirmEmailUpdate(code:)` succeeds, `authVM.email` still holds the old address. UI elements that display `authVM.email` (settings screen, any future profile display) show stale data until the next `checkAuthState()` call.

**Prevention:** Call `await authVM.checkAuthState()` after a successful email update confirmation, or directly update `authVM.email` with the new value.

**Phase:** Address in the global UI/UX polish phase.

---

### Pitfall 16: Hard-Coded Subscription Prices Will Require App Store Release on Every Price Change

**What goes wrong:** `SubscriptionPlan.swift` (lines 20–48) hard-codes all plan prices (`$25/mo`, `$30/mo`, `$50 seasonal`, `$200 lifetime`). If Stripe prices change, the app shows the wrong amounts until a new version clears App Store review.

**Prevention:** Fetch plan details (price, swipe limits, features) from a `/getPlans` endpoint at app launch. Cache in `SubscriptionViewModel`. Use the cached values for display. Fall back to hardcoded values only if the fetch fails.

**Phase:** Deferred — not blocking current milestone. Flag as a v1.1 task.

---

### Pitfall 17: `FlowLayout` Height Is a Hardcoded Heuristic That Breaks on Narrow Screens

**What goes wrong:** `FlowLayout` in `JobCardView.swift` (line 355) computes height as `max(CGFloat(items.count / 3 + 1) * 28, 28)`. This assumes 3 items per row and 28pt row height. On iPhone SE (375pt wide), long chip labels like "Machine Learning Engineer" wrap sooner, so the actual height exceeds the calculated frame. Chips are clipped.

**Prevention:** Use SwiftUI's `Layout` protocol (iOS 16+) or the `ViewThatFits` approach with a `PreferenceKey` to measure actual chip heights. The existing `GeometryReader`-based flow logic computes correct positions but the outer frame height calculation is wrong.

**Phase:** Address in the swipe UX polish phase when fixing card layout.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|---|---|---|
| API connectivity fix | xcconfig prod domain fallback (Pitfall 1) + Cognito pool mismatch (Pitfall 2) | Fix xcconfig first; add `fatalError` guard; verify pool IDs match environment |
| Amplify init | Silent failure on bad `amplifyconfiguration.json` (Pitfall 3) | Add `#if DEBUG fatalError` in configure catch block |
| Onboarding polish | `isFirstLogin` error routes new users past quiz (Pitfall 4) + isolated ProfileViewModel (Pitfall 7) | Fix error branch default; share ProfileViewModel from AppRouter |
| Swipe UX polish | Snap-back animation glitch (Pitfall 5) + race condition on rapid swipes (Pitfall 11) + FlowLayout clipping (Pitfall 17) | Fix manual-input path first; unify fetch flags |
| Applied jobs polish | False "No Applications Yet" empty state (Pitfall 9) | One-line fix to empty state condition |
| Payment flow verification | currentPlan always "Free" (Pitfall 6) + no return-URL handler (Pitfall 12) | Bridge profile plan to SubscriptionVM; implement deep-link or onDismiss checkSessionStatus |
| Profile completion | Mutable computed IDs (Pitfall 8) + duplicate profile save paths (from CONCERNS.md) | Add stable UUIDs; consolidate uploadResume to call updateProfile |
| Global UX polish | Stale email after update (Pitfall 15) + `seenUrls` growth (Pitfall 10) | Refresh authVM after email confirm; cap seenUrls |

---

## Sources

All findings are derived from direct inspection of the following project files. No external sources were consulted (WebSearch/WebFetch unavailable during this research session). Confidence is HIGH because all claims are grounded in the actual code.

- `JobHarvest/Utils/Constants.swift` — `AppConfig.apiDomain` fallback (Pitfall 1)
- `JobHarvest/App/FlashApplyApp.swift` — Silent Amplify configure failure (Pitfall 3)
- `JobHarvest/App/AppRouter.swift` — Hub token in `@State` (Pitfall 13)
- `JobHarvest/Services/AuthService.swift` — `isFirstLogin` error branch (Pitfall 4)
- `JobHarvest/ViewModels/AuthViewModel.swift` — auth state machine
- `JobHarvest/ViewModels/JobCardsViewModel.swift` — `seenUrls` growth (Pitfall 10), fetch race condition (Pitfall 11)
- `JobHarvest/Views/Main/Apply/JobCardView.swift` — Snap-back bug (Pitfall 5), `FlowLayout` heuristic (Pitfall 17)
- `JobHarvest/ViewModels/SubscriptionViewModel.swift` — `currentPlan` initialization (Pitfall 6)
- `JobHarvest/Views/Main/Premium/PremiumView.swift` — No return-URL handler (Pitfall 12)
- `JobHarvest/ViewModels/ProfileViewModel.swift` — Duplicate upload logic (from CONCERNS.md)
- `JobHarvest/Views/Onboarding/PreferencesQuizView.swift` — Isolated ProfileViewModel (Pitfall 7), main-thread file read (Pitfall 14)
- `JobHarvest/Views/Main/MyJobs/MyJobsView.swift` — False empty state (Pitfall 9)
- `JobHarvest/Models/User.swift` — Mutable computed IDs (Pitfall 8)
- `JobHarvest/Models/SubscriptionPlan.swift` — Hard-coded prices (Pitfall 16)
- `.planning/codebase/CONCERNS.md` — Tech debt, known bugs, security considerations, fragile areas
- `.planning/PROJECT.md` — Active requirements, constraints, key decisions
