# Phase 3: Feature Polish - Research

**Researched:** 2026-03-24
**Domain:** SwiftUI iOS — animation fixes, subscription plan bridging, pipeline polish, loading/error/empty state patterns
**Confidence:** HIGH (all findings derived from direct codebase audit of canonical source files)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Card exit animation: Tinder-style fly-off-screen with rotation in the swipe direction. Already partially built in `JobCardView` — fix the `manualInputFields` snap-back bug (card animates off then resets to `.zero` before sheet appears).
- Haptic feedback: `UIImpactFeedbackGenerator` fires on accept/reject (already exists — verify it works cleanly).
- Button taps (accept/reject buttons) should trigger the same fly-off animation as swipe gestures — no separate animation path.
- Persistent countdown banner at the top of the screen showing "X swipes remaining" when user approaches the limit.
- Banner appears at a threshold (e.g., 5 remaining) — not from the start.
- When limit is reached: friendly message replacing the card deck, NOT a raw 403 error. `noSwipesLeft = true` — needs a polished UI for that state.
- Swipe limit warning should include an upgrade CTA ("Upgrade for unlimited swipes").
- Empty deck: context-aware — filters active = "No more jobs match your filters — try adjusting them" + open filter drawer button; no filters = "All caught up! Check back later for new matches" + refresh button.
- `isGreatFit` badge: Prominent colored badge — green "Great Fit!" banner or ribbon at the top of the job card.
- Pipeline stage moves via buttons inside a detail sheet — NOT drag-and-drop, NOT long-press context menu.
- Job detail view: full bottom sheet showing company, role, salary, status, "Move to Stage" picker/button set. Link to original job posting if URL available.
- `appliedDate`: Skip display — backend `AppliedJob` model has no `appliedDate` field. Note as known gap, don't show placeholder text.
- Pipeline stages: Claude decides which stages to show by default vs behind a toggle (active-only vs all 7). Fix the `MyJobsView` empty state bug that only checks `applying`/`applied` columns.
- Optimistic updates for stage moves: update UI immediately, revert if API call fails.
- Stripe return detection: When app returns to foreground from Safari, automatically call `checkSessionStatus`. No deep-link or custom URL scheme needed.
- Plan loading on launch: Bridge the plan string from `ProfileViewModel.profile.plan` to `SubscriptionViewModel.currentPlan` so PremiumView shows the correct plan immediately.
- Post-payment UX: "Verifying payment..." loading overlay on PremiumView after returning from Stripe, until session status check completes. Show success/failure message after.
- Keep existing Stripe web checkout via `SFSafariViewController` — do not add Apple IAP/StoreKit in this phase.
- Use branded logo loading animation matching FlashApply web app — the logo animates while content loads. Replaces generic `ProgressView()` spinners for main content areas.
- Quick actions (saving profile, moving pipeline stages) can use a simpler inline indicator.
- Empty states: encouraging, action-oriented tone. Every empty state should have a clear CTA button.

### Claude's Discretion

- Error display style (inline banner vs alert — choose based on error severity)
- Global vs per-screen retry pattern (pick what's most maintainable)
- Human-readable error message mapping from raw AWS/network errors
- Exact threshold for swipe limit countdown banner
- Which pipeline stages show by default vs behind toggle
- Logo loading animation implementation details
- Exact layout and styling of the Great Fit badge

### Deferred Ideas (OUT OF SCOPE)

- Apple IAP / StoreKit integration — evaluate after App Store review
- `appliedDate` field on pipeline cards — requires backend schema change
- Company logo disk caching (SDWebImageSwiftUI) — Phase 4 hardening concern
- `seenUrls` unbounded growth cap — Phase 4 hardening concern
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PROF-01 | User can view all their profile information in the Profile tab | `ProfileView` + section views already exist; `profileVM.fetchProfile()` is wired. Tab render confirmed working. |
| PROF-02 | User can edit personal info (name, phone, LinkedIn URL) | `PersonalInfoSection` and `LinksSection` exist with save logic. `updateProfile()` with optimistic update already implemented. |
| PROF-03 | User can update job preferences (job type, location, salary range, work authorization) | `PreferencesSection`, `LocationsSection`, `AuthorizationsSection` exist. Same save pattern. |
| PROF-04 | User can upload or replace their resume | `ResumeSection` + `ProfileViewModel.uploadResume()` exist. S3 upload path confirmed. |
| PROF-05 | Profile uses the same shared `ProfileViewModel` instance as onboarding | `FlashApplyApp` injects one `@StateObject profileVM` as `@EnvironmentObject` — all tabs share it. Confirmed. |
| PROF-06 | Profile changes are saved to backend with success/failure feedback to user | `updateProfile()` throws on failure; optimistic revert exists. UI feedback (alert/banner) needed in section views. |
| SWIPE-01 | User can swipe right to apply or left to skip a job | `DragGesture` + `handleSwipe()` fully wired. Working but animation has a known bug. |
| SWIPE-02 | Card exit animation completes correctly for both swipe gestures and button taps | Known bug: `manualInputFields` path resets `dragOffset = .zero` before sheet appears. Fix: defer reset until sheet is dismissed. |
| SWIPE-03 | User sees a clear, friendly message when swipe limit is reached (not a raw 403 error) | `noSwipesView` in `ApplyView` already exists — but needs upgrade CTA polish. 403 is already caught. |
| SWIPE-04 | Progressive swipe-limit warning appears before the hard limit is hit | Already implemented as toolbar badge at `swipesRemaining <= 5`. Needs prominence review. |
| SWIPE-05 | New jobs load automatically as the deck runs low | `handleSwipe` triggers `fetchJobs(appending: true)` when `jobs.count <= 2`. Working. |
| SWIPE-06 | Empty deck state is handled with a friendly UI (no blank screen) | `emptyView` in `ApplyView` exists but is not context-aware (filter vs no-filter). Fix needed. |
| SWIPE-07 | `isGreatFit` badge is displayed on job cards when applicable | `JobCardView` already renders `greatMatch` badge. Model has both `greatMatch` and `isGreatFit` fields — both need to be checked. |
| JOBS-01 | User can view all applied jobs in a pipeline/Kanban view | `MyJobsView` + `PipelineColumnView` exist. Empty state bug must be fixed. |
| JOBS-02 | User can move a job between pipeline stages | `JobDetailSheet.stagePicker` renders all 7 stage buttons, wired to `moveJob()`. Already complete. |
| JOBS-03 | Applied date is visible on each job card | Backend `AppliedJob` model has no `appliedDate` field. Per CONTEXT decision: skip display, note as known gap. |
| JOBS-04 | Stage moves feel instant (optimistic update, not wait-then-refresh) | `AppliedJobsViewModel.moveJob()` is already optimistic with silent-refresh revert. Working. |
| JOBS-05 | User can view job detail from the applied jobs list | `JobDetailSheet` exists and is presented on tap. Fully wired in `MyJobsView`. |
| PAY-01 | User can navigate to subscription/upgrade screen | `PremiumView` accessible via More tab `NavigationLink`. Working. |
| PAY-02 | Current subscription plan is correctly displayed (not always "Free") | Bug confirmed: `SubscriptionViewModel.currentPlan` initializes `.free` and is never synced from `profileVM.profile.plan`. Bridge needed in `PremiumView.onAppear` or `MainTabView`. |
| PAY-03 | Stripe checkout session opens successfully in Safari | `createCheckoutSession` → `checkoutURL` → `SFSafariViewController`. Working. |
| PAY-04 | App detects successful payment and updates subscription status after returning from Stripe | `checkSessionStatus(sessionId:)` exists but requires a `session_id`. Foreground detection via `scenePhase` needed. `session_id` extraction from checkout URL required. |
| PAY-05 | User sees their updated plan reflected immediately after successful payment | Flows from PAY-04. After `checkSessionStatus` succeeds, `currentPlan` updates; PremiumView re-renders. |
| UX-01 | All error messages shown to users are human-readable | Raw AWS/Cognito SDK strings propagated via `self.error = error.localizedDescription` across ViewModels. Error mapping layer needed. |
| UX-02 | All loading states have a spinner or skeleton UI (no blank screens during fetches) | `LoadingView(message:)` exists and is used in Apply/MyJobs. Profile tab has no loading state shown. Branded animation needed. |
| UX-03 | All empty states have friendly messaging and a clear action | Most empty states exist. Context-aware empty deck, `MyJobsView` empty state bug need fixes. |
| UX-04 | Network failure on any screen shows a retry option | `error` published on each VM but not consistently surfaced to user with retry buttons. Per-screen pattern recommended. |
</phase_requirements>

---

## Summary

Phase 3 is a polish phase, not a greenfield build. The codebase audit confirms that the vast majority of required features are structurally present: swipe card deck, pipeline view, profile editing, Stripe checkout, and loading/empty states all have working skeletons. The work is fixing specific bugs, bridging missing data connections, and adding consistent polish patterns.

The three most impactful issues to address are: (1) the `manualInputFields` swipe animation snap-back bug in `JobCardView`, (2) the `currentPlan` always-Free bug in `SubscriptionViewModel` (never bridged from `ProfileViewModel.profile.plan`), and (3) the `MyJobsView` empty state bug that only checks `applying`/`applied` columns. Everything else is incremental improvement to UX patterns already in place.

The foreground detection pattern for Stripe return (`scenePhase` observation in `MainTabView` or `AppRouter`) is the only non-trivial new pattern to introduce. The `checkSessionStatus` function already exists and requires a `session_id` query parameter — the implementation must extract this from the `checkoutURL` that was opened, so it needs to be stored before the Safari sheet is presented.

**Primary recommendation:** Work feature-by-feature in dependency order: animation bug fix first (SWIPE-02 unblocks SWIPE-01), then plan bridge (PAY-02 unblocks PAY-04/PAY-05), then `MyJobsView` empty state fix (JOBS-01), then add loading/error/empty state polish across all tabs.

---

## Standard Stack

### Core (already in project — no new dependencies needed)
| Component | Version | Purpose | Notes |
|-----------|---------|---------|-------|
| SwiftUI | iOS 16+ | All views | Already the project standard |
| `UIImpactFeedbackGenerator` | UIKit | Haptic on swipe | Already wired in `JobCardView` and `ApplyView.swipeJob()` |
| `SFSafariViewController` | SafariServices | Stripe checkout web flow | Already in `JobDetailSheet` and `PremiumView` |
| `EnvironmentValues.scenePhase` | SwiftUI | Foreground detection for Stripe return | Standard SwiftUI pattern, no import needed |

### No New Dependencies
Phase 3 adds no new packages. All required capabilities exist in the SwiftUI/UIKit standard library and the existing codebase.

---

## Architecture Patterns

### Existing Patterns to Follow

**MVVM with `@EnvironmentObject`:** All ViewModels are `@MainActor ObservableObject` classes injected via `@EnvironmentObject` from `FlashApplyApp`. New state goes on existing ViewModels — never create new `@StateObject` instances inside a tab view.

**Error handling convention:** Every ViewModel has `@Published var error: String?`. Error is set on failure, nil on new request start. Views observe this to show UI.

**Optimistic update pattern:** Already established in `ProfileViewModel.updateProfile()` (optimistic apply + revert on throw) and `AppliedJobsViewModel.moveJob()` (optimistic move + `silentRefresh()` on catch). All state mutations follow this pattern.

**Loading state convention:**
- `isLoading: Bool` — full-screen fetch in progress
- `isSaving: Bool` — inline save in progress (profile sections)
- `isLoaded: Bool` — first fetch has completed (gate for `.task` guard)
- Show full `LoadingView` only when `isLoading && !isLoaded`

### Pattern 1: Foreground Detection for Stripe Return (new — PAY-04)

**What:** When `SFSafariViewController` is dismissed, the app returns to foreground. Use `scenePhase` to detect `.active` transition and trigger `checkSessionStatus`.

**Where to wire:** `PremiumView` — this is the screen that opens Safari and awaits return. It already owns a `SubscriptionViewModel` instance.

**Implementation approach:**
```swift
// In PremiumView
@Environment(\.scenePhase) private var scenePhase
@State private var awaitingPaymentReturn = false
@State private var isVerifyingPayment = false

// When checkout opens:
awaitingPaymentReturn = true
showWebCheckout = true

// Detect return:
.onChange(of: scenePhase) { phase in
    guard phase == .active, awaitingPaymentReturn else { return }
    awaitingPaymentReturn = false
    isVerifyingPayment = true
    Task {
        // extract session_id from stored checkoutURL query params
        if let sessionId = extractedSessionId {
            await subscriptionVM.checkSessionStatus(sessionId: sessionId)
        }
        isVerifyingPayment = false
    }
}
```

**Session ID extraction:** `checkoutURL` from `createCheckoutSession` response is a Stripe checkout URL. The `session_id` is a query parameter on the `success_url` redirect, not on the checkout URL itself. Since no deep-link is being used, the simplest approach is: when `checkSessionStatus` is called without a `session_id` (i.e., we just check if the plan changed), the backend endpoint should support a no-arg plan lookup. **Verify with backend** — if `/sessionStatus` requires `session_id`, call `/users/{id}/profile` instead to re-fetch the plan.

**Alternative (simpler):** After returning from Stripe, re-fetch the user profile. `profileVM.profile.plan` will reflect the updated plan if payment succeeded. Bridge to `currentPlan` in the same step. This avoids the `session_id` coupling entirely.

### Pattern 2: Plan Bridge (PAY-02)

**What:** `SubscriptionViewModel.currentPlan` is always `.free` on init. `ProfileViewModel.profile.plan` (a `String?`) is the source of truth from the backend.

**Where:** `PremiumView` initializes `@StateObject private var subscriptionVM = SubscriptionViewModel()` locally. This is the right place to bridge.

```swift
// In PremiumView.onAppear or .task:
.task {
    // Bridge plan from profileVM (already fetched by ApplyView.onAppear)
    if let planString = profileVM.profile.plan,
       let plan = SubscriptionPlan(rawValue: planString) {
        subscriptionVM.currentPlan = plan
    }
}
```

`PremiumView` needs `@EnvironmentObject var profileVM: ProfileViewModel` added. `MainTabView` already injects it for the Profile tab — add it for `MoreView` as well (or pass through `NavigationLink` destination via `.environmentObject(profileVM)`).

### Pattern 3: Context-Aware Empty Deck (SWIPE-06)

**What:** `ApplyView` currently passes `currentFilters` to `fetchJobs` but the empty state doesn't distinguish filter vs no-filter.

**Approach:** Add `var hasActiveFilters: Bool` computed property on `ApplyView`:
```swift
private var hasActiveFilters: Bool {
    currentFilters != JobFilters()  // requires JobFilters: Equatable
}
```
Then show different empty state messages based on this flag. `JobFilters` needs `Equatable` conformance added.

### Pattern 4: Animation Bug Fix — manualInputFields (SWIPE-02)

**The bug (confirmed in `JobCardView.swift` lines 57–75):**
```swift
// dragGesture .onEnded:
withAnimation(.easeOut(duration: 0.35)) {
    dragOffset = CGSize(width: isAccepting ? 600 : -600, ...)
}
Task {
    if isAccepting && !(job.manualInputFields?.isEmpty ?? true) {
        pendingSwipeIsAccepting = true
        dragOffset = .zero   // ← This fires synchronously, resetting card BEFORE animation completes
        showManualAnswers = true
    }
}
```

**Fix:** Don't reset `dragOffset` to `.zero` before the sheet appears. Keep the card off-screen while the sheet is shown. Reset `dragOffset` to `.zero` only when the user cancels the sheet (dismisses without submitting). When the user submits answers, call `onSwipe` as normal — the card is already off-screen.

```swift
// dragGesture .onEnded fix:
Task {
    if isAccepting && !(job.manualInputFields?.isEmpty ?? true) {
        pendingSwipeIsAccepting = true
        // DO NOT reset dragOffset here — card stays off-screen
        showManualAnswers = true
    } else {
        await onSwipe(isAccepting, [:])
    }
}

// In .sheet(isPresented: $showManualAnswers) onDismiss:
// If user cancelled (no answers submitted), reset dragOffset:
.sheet(isPresented: $showManualAnswers, onDismiss: {
    if pendingSwipeIsAccepting {  // cancelled without submitting
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            dragOffset = .zero
        }
        pendingSwipeIsAccepting = false
    }
}) {
    ManualAnswersSheet(...) { answers in
        pendingSwipeIsAccepting = false
        Task { await onSwipe(true, answers) }
    }
}
```

### Pattern 5: isGreatFit Badge (SWIPE-07)

**Current state:** `JobCardView` already renders a `matchBadge(text: "Great Match", ...)` when `job.greatMatch == true`. The model also has `job.isGreatFit: Bool?` (separate field).

**Fix:** The CONTEXT asks for a prominent "Great Fit!" badge. Current badge is small (9pt text, capsule shape in the header corner). Make it more prominent by:
- Rendering when `job.greatMatch == true || job.isGreatFit == true`
- Using a larger, bolder style — or a ribbon/banner across the top-right corner of the card
- Distinct from the existing "High Pay" badge to avoid visual clutter

The `cardHeader` gradient strip is 56pt tall — a ribbon overlaid on the top-right of this strip reads well.

### Pattern 6: MyJobsView Empty State Bug (JOBS-01)

**The bug (confirmed at `MyJobsView.swift` line 28):** Current check:
```swift
displayedStages.allSatisfy({ appliedJobsVM.jobs(for: $0).isEmpty })
```

This is actually the correct fix — it already uses `displayedStages` (not just `applying`/`applied`). The CONCERNS.md notes the bug as checking `applying`/`applied`, but the **current code in MyJobsView line 28 uses `displayedStages.allSatisfy`**, which is correct. Verify this is working as expected. The empty state logic appears already fixed since the CONCERNS.md audit.

### Pattern 7: Error Message Humanization (UX-01)

**Problem:** `self.error = error.localizedDescription` propagates raw SDK strings (e.g., "The operation couldn't be completed. (com.amazonaws.AWSCognitoIdentityProvider error 28.)" or network timeout strings).

**Recommended approach:** Add a static `humanizeError(_:) -> String` helper in `Extensions.swift`:

```swift
// Source: project-specific, no external library needed
extension Error {
    var humanReadableDescription: String {
        let raw = localizedDescription
        // Network errors
        if raw.contains("URLError") || raw.contains("-1009") { return "No internet connection. Check your connection and try again." }
        if raw.contains("-1001") { return "The request timed out. Please try again." }
        if raw.contains("serverError(403") || raw.contains("403") { return "You've reached your daily limit. Upgrade for more swipes." }
        if raw.contains("serverError(401") || raw.contains("401") { return "Your session expired. Please sign in again." }
        if raw.contains("serverError(500") || raw.contains("500") { return "Something went wrong on our end. Please try again shortly." }
        // AWS/Cognito
        if raw.contains("AWSCognito") || raw.contains("Cognito") { return "Authentication error. Please sign out and sign in again." }
        // Default
        return "Something went wrong. Please try again."
    }
}
```

Apply at the ViewModel catch sites by replacing `error.localizedDescription` with `error.humanReadableDescription`.

### Pattern 8: Branded Loading Animation (UX-02)

**Requirement:** Replace generic `ProgressView()` with a branded logo animation for main content areas.

**Implementation approach (no external libraries):** A `BrandedLoadingView` using SwiftUI animations:

```swift
struct BrandedLoadingView: View {
    let message: String
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            // Flash logo mark — lightning bolt with pulse + scale
            Image(systemName: "bolt.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: [.flashTeal, .flashNavy],
                                   startPoint: .top, endPoint: .bottom)
                )
                .scaleEffect(isAnimating ? 1.15 : 0.95)
                .opacity(isAnimating ? 1.0 : 0.6)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear { isAnimating = true }

            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.flashTextSecondary)
        }
    }
}
```

Replace `LoadingView(message:)` calls with `BrandedLoadingView(message:)` for main content loads. The existing `LoadingView` struct can be updated in place or renamed.

**Note:** If the FlashApply web app uses a specific logo asset (SVG/PNG), use that asset with a rotation or pulse animation instead of the SF Symbol. Check `Assets.xcassets` for any logo asset.

### Pattern 9: Per-Screen Error + Retry (UX-04)

**Recommended approach:** Inline banner (not alert) for most errors. Alerts only for destructive actions.

**Error banner pattern:**
```swift
// Reusable view — add to shared Views/Shared/
struct ErrorBannerView: View {
    let message: String
    let onRetry: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.flashOrange)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.flashDark)
                .lineLimit(2)
            Spacer()
            if let retry = onRetry {
                Button("Retry", action: retry)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.flashTeal)
            }
        }
        .padding(14)
        .background(Color.flashOrange.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.flashOrange.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}
```

Place `ErrorBannerView` at the top of each tab's content when `viewModel.error != nil`. The retry closure calls the appropriate fetch method.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stripe payment detection | Custom URL scheme / deep-link handler | `scenePhase` `.active` observation | No deep-link configured, no backend coordination needed for foreground detection |
| Error humanization | Per-screen error strings | Single `Error.humanReadableDescription` extension | Centralized, consistent across all screens |
| Logo animation | Third-party Lottie/Rive | SwiftUI `withAnimation` + `repeatForever` | No new dependency needed; simple pulse is sufficient |
| Optimistic pipeline moves | Re-fetch from server after move | Existing `moveJob()` pattern | Already implemented; don't replace with a wait-then-refresh |
| Empty state logic | Complex state machine | Simple `if` checks on ViewModel `.isEmpty` flags | The state is already in published arrays |

---

## Common Pitfalls

### Pitfall 1: PremiumView Creates Its Own SubscriptionViewModel
**What goes wrong:** `PremiumView` uses `@StateObject private var subscriptionVM = SubscriptionViewModel()`. This is a local instance — when navigated to via `NavigationLink` from `MoreView`, it starts fresh with `.free` every time.
**Why it happens:** No `SubscriptionViewModel` is injected at the app level (unlike `ProfileViewModel`).
**How to avoid:** Either (a) inject `profileVM` into `PremiumView` and derive plan display directly from `profileVM.profile.plan`, or (b) add `SubscriptionViewModel` to `FlashApplyApp` as a `@StateObject` and inject it as `@EnvironmentObject`. Option (a) is simpler and avoids a new app-level VM.
**Warning signs:** PremiumView shows "Free" even for paid users on first open.

### Pitfall 2: scenePhase Fires on Every Foreground, Not Just After Stripe
**What goes wrong:** Using `scenePhase == .active` without a guard fires on every app foreground event — locking screen, incoming call, multitasking switch. This calls `checkSessionStatus` on every return, not just after Stripe.
**How to avoid:** Gate with `awaitingPaymentReturn` flag set to `true` only when `showWebCheckout = true`. Reset on `onDismiss` of the sheet and after the status check completes.
**Warning signs:** Plan flickering or unnecessary API calls when returning from other apps.

### Pitfall 3: Resetting dragOffset Cancels the Fly-Off Animation
**What goes wrong:** Setting `dragOffset = .zero` inside a `Task` block after `withAnimation` was called does not wait for the animation to finish — it fires immediately (Swift concurrency does not yield to the animation system here).
**How to avoid:** Never reset `dragOffset` while a fly-off animation is in progress. For the `manualInputFields` path, keep the card off-screen (don't reset) until either the sheet is dismissed without answers or `onSwipe` is called.

### Pitfall 4: JobFilters Needs Equatable for Context-Aware Empty Deck
**What goes wrong:** `currentFilters != JobFilters()` requires `JobFilters: Equatable`. Without this, the comparison won't compile.
**How to avoid:** Add `extension JobFilters: Equatable {}` — all properties are primitives/optionals, so synthesized conformance works.
**Warning signs:** Compile error on the empty deck context check.

### Pitfall 5: htmlDecoded() Blocks Main Thread
**What goes wrong:** `String.htmlDecoded()` creates `NSAttributedString` with HTML document type synchronously on whatever thread calls it. In `JobCardView` body, this blocks the main thread during card rendering.
**How to avoid:** Pre-decode job descriptions in `JobCardsViewModel.fetchJobs` on a background task. Store decoded string on `Job` model (add `var jobDescriptionDecoded: String?`). Phase 3 scope: if `htmlDecoded()` is only called in the card tab content (on explicit user scroll), it's lower urgency. Do not call it in the top-level card header render path.

### Pitfall 6: SubscriptionViewModel.checkSessionStatus Requires session_id
**What goes wrong:** `checkSessionStatus(sessionId:)` passes `session_id` as a query param to `/sessionStatus`. Without a deep-link return URL, the app doesn't receive the Stripe session ID after Safari redirects.
**How to avoid:** Two options:
1. Store the checkout URL when Safari opens. Parse the `session_id` query param from the URL (Stripe checkout URLs include `?session_id=cs_xxx`). Use this to call `checkSessionStatus`.
2. After returning from Stripe foreground, call `profileVM.fetchProfile()` instead — `profile.plan` will reflect the updated plan. Then bridge to `subscriptionVM.currentPlan`. This is simpler and avoids `session_id` dependency.
**Recommendation:** Use option 2 (re-fetch profile) for simplicity. The CONTEXT confirms no deep-link is needed.

---

## Code Examples

### Foreground Detection Pattern
```swift
// Source: Apple SwiftUI documentation — scenePhase environment value
// In PremiumView:
@Environment(\.scenePhase) private var scenePhase
@State private var awaitingPaymentReturn = false

.onChange(of: scenePhase) { newPhase in
    guard newPhase == .active, awaitingPaymentReturn else { return }
    awaitingPaymentReturn = false
    Task { await handlePaymentReturn() }
}

private func handlePaymentReturn() async {
    isVerifyingPayment = true
    await profileVM.fetchProfile()
    // Bridge updated plan
    if let planString = profileVM.profile.plan,
       let plan = SubscriptionPlan(rawValue: planString) {
        subscriptionVM.currentPlan = plan
        paymentResult = plan != .free ? .success : .unchanged
    }
    isVerifyingPayment = false
}
```

### Optimistic Stage Move (already correct in codebase)
```swift
// Source: JobHarvest/ViewModels/AppliedJobsViewModel.swift
func moveJob(_ job: AppliedJob, to newStage: PipelineStage) async {
    removeFromAllStages(jobUrl: job.jobUrl)   // optimistic remove
    var moved = job; moved.stage = newStage
    appendToStage(moved, stage: newStage)     // optimistic add

    do {
        let _: MessageResponse = try await network.request("/moveJobStatus", method: "POST", body: ...)
    } catch {
        await silentRefresh()  // revert from server state
    }
}
```

### Empty State With CTA (pattern for all tabs)
```swift
// Pattern for context-aware empty states
private var emptyDeckView: some View {
    VStack(spacing: 24) {
        // Icon + title + message
        ...
        if hasActiveFilters {
            Button("Adjust Filters") { showFilters = true }
                .primaryButtonStyle()
        } else {
            Button("Check Again") {
                Task { await jobCardsVM.fetchJobs(filters: currentFilters) }
            }
            .primaryButtonStyle()
        }
    }
    .padding(.horizontal, 40)
}
```

### Error Banner Integration
```swift
// Add to any tab's VStack, before main content:
if let errorMessage = viewModel.error {
    ErrorBannerView(message: errorMessage.humanReadableDescription) {
        viewModel.error = nil
        Task { await viewModel.fetchSomething() }
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `ProgressView()` generic spinner | `BrandedLoadingView` with logo pulse | Branded, consistent across tabs |
| Raw `error.localizedDescription` | `error.humanReadableDescription` via extension | Human-readable, actionable messages |
| Alert-only error display | Inline `ErrorBannerView` with retry | Non-blocking, dismissible errors |
| `dragOffset = .zero` in animation path | Defer reset until sheet dismiss | Fixes snap-back visual glitch |

---

## Open Questions

1. **session_id for checkSessionStatus**
   - What we know: `checkSessionStatus(sessionId:)` requires a session ID query param. Stripe checkout URLs include `session_id` as a query parameter on the success/cancel return URL, not on the checkout URL itself.
   - What's unclear: Does the backend's `/sessionStatus` endpoint support a plan-only lookup (no session ID), or does it require `session_id`? The current signature at line 45 uses `params: ["session_id": sessionId]`.
   - Recommendation: Implement the profile re-fetch approach (`fetchProfile()` after return) as the primary path. If the team wants to validate payment via Stripe's session status API, coordinate with backend to add a `/currentPlan` endpoint or modify `/sessionStatus` to support identity-based lookup without `session_id`.

2. **Logo asset for branded loading animation**
   - What we know: The web app has a branded logo animation. The iOS project has `Assets.xcassets`.
   - What's unclear: Is there a FlashApply logo asset in `Assets.xcassets` to use for the loading animation, or should we use the SF Symbol `bolt.fill` as a proxy?
   - Recommendation: Implementer should check `Assets.xcassets` for a logo image asset before building the loading view. If no asset exists, `bolt.fill` gradient is acceptable.

3. **PipelineStage default display**
   - What we know: `showActiveOnly = true` shows 5 stages (excluding `archived` and `failed`). The segmented picker for Active/All already exists in `MyJobsView`.
   - What's unclear: Should the default be Active (5 stages) or All (7 stages)?
   - Recommendation: Keep the current default of Active-only. Users with advanced stages will naturally discover the "All" toggle. The CONTEXT defers this to Claude's discretion.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in — no external framework installed) |
| Config file | `JobHarvest/JobHarvestTests/JobHarvestTests.swift` (currently empty) |
| Quick run command | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing JobHarvestTests` |
| Full suite command | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SWIPE-02 | `dragOffset` is NOT reset to `.zero` while `manualInputFields` sheet is open | unit | `xcodebuild test ... -only-testing JobHarvestTests/JobCardViewModelTests/testManualFieldsSwipeAnimationNoReset` | ❌ Wave 0 |
| PAY-02 | `SubscriptionViewModel.currentPlan` reflects `profileVM.profile.plan` after bridge | unit | `xcodebuild test ... -only-testing JobHarvestTests/SubscriptionViewModelTests/testPlanBridgeFromProfile` | ❌ Wave 0 |
| PAY-04 | `handlePaymentReturn()` calls `fetchProfile` when `awaitingPaymentReturn == true` and scenePhase becomes `.active` | unit | `xcodebuild test ... -only-testing JobHarvestTests/SubscriptionViewModelTests/testForegroundDetectionTriggersProfileFetch` | ❌ Wave 0 |
| UX-01 | `Error.humanReadableDescription` maps known error strings to human-readable text | unit | `xcodebuild test ... -only-testing JobHarvestTests/ExtensionsTests/testErrorHumanization` | ❌ Wave 0 |
| JOBS-01 | `MyJobsView` empty state shows "No Applications Yet" only when ALL displayed stages are empty | unit | `xcodebuild test ... -only-testing JobHarvestTests/AppliedJobsViewModelTests/testEmptyStateOnlyWhenAllStagesEmpty` | ❌ Wave 0 |
| SWIPE-06 | `hasActiveFilters` returns `true` when filters differ from `JobFilters()` default | unit | `xcodebuild test ... -only-testing JobHarvestTests/JobFiltersTests/testHasActiveFilters` | ❌ Wave 0 |

**Note on test reality:** Zero meaningful tests currently exist (confirmed in CONCERNS.md). The test infrastructure (`JobHarvestTests` target) exists but the test file contains only an empty `example()` function. These tests must be created in Wave 0 before implementation. However, given the UI-heavy nature of Phase 3, many requirements are most efficiently validated via manual device/simulator testing. The unit tests above focus on the logic-extractable behaviors: ViewModel state transitions, error mapping, and filter comparison.

### Sampling Rate
- **Per task commit:** Run the specific test target for the modified ViewModel
- **Per wave merge:** `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `JobHarvest/JobHarvestTests/SubscriptionViewModelTests.swift` — covers PAY-02, PAY-04
- [ ] `JobHarvest/JobHarvestTests/ExtensionsTests.swift` — covers UX-01 error humanization
- [ ] `JobHarvest/JobHarvestTests/JobFiltersTests.swift` — covers SWIPE-06 filter equality
- [ ] `JobHarvest/JobHarvestTests/AppliedJobsViewModelTests.swift` — covers JOBS-01 empty state logic
- [ ] `JobHarvest/JobHarvestTests/JobCardAnimationTests.swift` — covers SWIPE-02 animation bug fix

---

## Sources

### Primary (HIGH confidence — direct codebase audit)
- `JobHarvest/Views/Main/Apply/JobCardView.swift` — animation bug, badge rendering, swipe gesture
- `JobHarvest/Views/Main/Apply/ApplyView.swift` — empty states, swipe limit banner, filter integration
- `JobHarvest/ViewModels/JobCardsViewModel.swift` — prefetch, noSwipesLeft, swipesRemaining
- `JobHarvest/ViewModels/AppliedJobsViewModel.swift` — optimistic move, stage arrays, silentRefresh
- `JobHarvest/Views/Main/MyJobs/MyJobsView.swift` — empty state bug analysis
- `JobHarvest/Views/Main/MyJobs/JobDetailSheet.swift` — stagePicker implementation, detail fetch
- `JobHarvest/ViewModels/SubscriptionViewModel.swift` — currentPlan bug, checkSessionStatus signature
- `JobHarvest/Views/Main/Premium/PremiumView.swift` — local @StateObject issue, Safari flow
- `JobHarvest/ViewModels/ProfileViewModel.swift` — profile.plan field, updateProfile pattern
- `JobHarvest/Models/User.swift` — UserProfile.plan CodingKey (`membershipPlan`)
- `JobHarvest/Models/Job.swift` — greatMatch vs isGreatFit field distinction
- `JobHarvest/Models/AppliedJob.swift` — PipelineStage.isActive, backendKey
- `JobHarvest/App/FlashApplyApp.swift` — @EnvironmentObject injection scope
- `JobHarvest/App/AppRouter.swift` — scenePhase placement options
- `JobHarvest/Utils/Extensions.swift` — htmlDecoded main thread issue, existing view modifiers
- `JobHarvest/Utils/Constants.swift` — color tokens, AppConfig
- `.planning/codebase/CONCERNS.md` — full bug/tech-debt/performance audit

### Secondary (MEDIUM confidence)
- Apple SwiftUI documentation pattern: `@Environment(\.scenePhase)` for app foreground detection — standard pattern, well-established in iOS 14+

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all patterns verified against existing source files
- Architecture: HIGH — patterns derived directly from codebase audit; no assumptions
- Pitfalls: HIGH — all pitfalls confirmed by reading the actual buggy code
- Open questions: LOW — session_id handling and logo asset presence unconfirmed without backend access

**Research date:** 2026-03-24
**Valid until:** 2026-04-23 (stable codebase; no fast-moving dependencies)
