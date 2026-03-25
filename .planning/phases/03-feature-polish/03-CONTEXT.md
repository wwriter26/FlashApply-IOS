# Phase 3: Feature Polish - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Every feature tab works end-to-end against the dev backend with polished animations, friendly error messages, and no blank screens. This phase covers: profile viewing/editing, swipe card UX, applied jobs pipeline, Stripe payment flow, and consistent loading/error/empty state patterns across the app.

</domain>

<decisions>
## Implementation Decisions

### Swipe Animations & Feedback
- Card exit animation: Tinder-style fly-off-screen with rotation in the swipe direction. Already partially built in `JobCardView` — fix the `manualInputFields` snap-back bug (card animates off then resets to `.zero` before sheet appears).
- Haptic feedback: `UIImpactFeedbackGenerator` fires on accept/reject (already exists — verify it works cleanly).
- Button taps (accept/reject buttons) should trigger the same fly-off animation as swipe gestures — no separate animation path.

### Swipe Limit Handling
- Persistent countdown banner at the top of the screen showing "X swipes remaining" when the user approaches the limit.
- Banner appears at a threshold (e.g., 5 remaining) — not from the start.
- When limit is reached: friendly message replacing the card deck, NOT a raw 403 error. Current code catches `ServerError(403)` and sets `noSwipesLeft = true` — needs a polished UI for that state.
- Swipe limit warning should include an upgrade CTA ("Upgrade for unlimited swipes").

### Empty Deck State
- Context-aware: If filters are active, show "No more jobs match your filters — try adjusting them" with a button to open the filter drawer. If no filters, show "All caught up! Check back later for new matches" with a refresh button.

### isGreatFit Badge
- Prominent colored badge — green "Great Fit!" banner or ribbon at the top of the job card. Should be immediately noticeable, not subtle.

### Applied Jobs Pipeline
- Stage moves happen via buttons inside a detail sheet — NOT drag-and-drop between columns, NOT long-press context menu.
- Job detail view: full bottom sheet showing company, role, salary, status, and a "Move to Stage" picker/button set. Link to original job posting if URL is available.
- Applied date: Skip display for now — backend `AppliedJob` model has no `appliedDate` field. Note as a known gap, don't show placeholder text.
- Pipeline stages: Claude decides which stages to show by default vs behind a toggle (active-only vs all 7). Fix the `MyJobsView` empty state bug that only checks `applying`/`applied` columns.
- Optimistic updates for stage moves: update UI immediately, revert if API call fails.

### Payment Flow & Plan Sync
- Stripe return detection: When app returns to foreground from Safari, automatically call `checkSessionStatus` to detect if the plan changed. No deep-link or custom URL scheme needed.
- Plan loading on launch: Bridge the plan string from `ProfileViewModel.profile.plan` to `SubscriptionViewModel.currentPlan` so PremiumView shows the correct plan immediately (not always "Free").
- Post-payment UX: Show a "Verifying payment..." loading overlay on PremiumView after returning from Stripe, until the session status check completes. Show success/failure message after.
- Keep existing Stripe web checkout via `SFSafariViewController` — do not add Apple IAP/StoreKit in this phase.

### Loading States
- Use a branded logo loading animation matching the FlashApply web app — the logo animates while content loads. This replaces generic `ProgressView()` spinners for main content areas.
- Quick actions (saving profile, moving pipeline stages) can use a simpler inline indicator.

### Empty States
- Encouraging, action-oriented tone: "You haven't applied to any jobs yet — start swiping!" not "No applications found."
- Every empty state should have a clear CTA button directing the user to the relevant action.

### Claude's Discretion
- Error display style (inline banner vs alert — choose based on error severity)
- Global vs per-screen retry pattern (pick what's most maintainable)
- Human-readable error message mapping from raw AWS/network errors
- Exact threshold for swipe limit countdown banner
- Which pipeline stages show by default vs behind toggle
- Logo loading animation implementation details
- Exact layout and styling of the Great Fit badge

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Swipe & Job Cards
- `JobHarvest/Views/Main/Apply/JobCardView.swift` — Card UI, swipe gesture, fly-off animation, manualInputFields bug (lines 56-71)
- `JobHarvest/Views/Main/Apply/ApplyView.swift` — Card deck container, empty state, filter integration
- `JobHarvest/ViewModels/JobCardsViewModel.swift` — Fetch, swipe handling, prefetch, noSwipesLeft flag, seenUrls
- `JobHarvest/Views/Main/Apply/FilterDrawerView.swift` — Existing filter UI

### Applied Jobs Pipeline
- `JobHarvest/ViewModels/AppliedJobsViewModel.swift` — 7-stage arrays, fetchAppliedJobs, moveJob
- `JobHarvest/Views/Main/MyJobs/MyJobsView.swift` — Pipeline view, empty state bug (lines 27-29)
- `JobHarvest/Views/Main/MyJobs/PipelineColumnView.swift` — Column rendering
- `JobHarvest/Views/Main/MyJobs/JobDetailSheet.swift` — Existing detail sheet (needs stage-move buttons added)

### Payments & Subscription
- `JobHarvest/ViewModels/SubscriptionViewModel.swift` — Checkout session, checkSessionStatus, currentPlan always Free bug
- `JobHarvest/Views/Main/Premium/PremiumView.swift` — Upgrade screen, plan display
- `JobHarvest/Models/SubscriptionPlan.swift` — Plan definitions (prices hard-coded — known tech debt)

### Profile
- `JobHarvest/ViewModels/ProfileViewModel.swift` — Shared VM (from Phase 2), fetch/update/upload
- `JobHarvest/Views/Main/Profile/ProfileView.swift` — Profile tab root
- `JobHarvest/Views/Main/Profile/sections/` — Profile section views

### Error Handling & Patterns
- `JobHarvest/Utils/Extensions.swift` — htmlDecoded() (main thread perf issue)
- `JobHarvest/Utils/Constants.swift` — AppConfig, colors
- `JobHarvest/Utils/Logger.swift` — AppLogger categories

### Known Issues (from codebase audit)
- `.planning/codebase/CONCERNS.md` — Full list of bugs, tech debt, and fragile areas affecting this phase

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `JobCardView`: Swipe gesture with DragGesture + 100pt threshold already built — needs animation fix, not rebuild
- `AppliedJobsViewModel`: Full pipeline with 7 stages, `moveJob()` exists — needs optimistic update + UI wiring
- `SubscriptionViewModel`: `createCheckoutSession` + `checkSessionStatus` already built — needs foreground trigger and plan bridge
- `ProfileViewModel`: Shared instance from Phase 2 with fetch/update/upload — ready for profile tab polish
- `FilterDrawerView`: Job filter UI exists — can be linked from empty deck state
- `CompanyLogoView`: Logo display with AsyncImage — no caching (Phase 4 concern)
- `AppLogger`: Categorized logging across all features — use for debugging

### Established Patterns
- MVVM with `@StateObject` + `@EnvironmentObject` injection
- All API calls through `NetworkService.request<T>()` with automatic Bearer token
- Error handling via `@Published var error: String?` on each ViewModel
- `APIResponse<T>` wrapper for all backend responses

### Integration Points
- `MainTabView` — All 5 tabs rendered here; loading/error patterns must be consistent across tabs
- `AppRouter` — Foreground detection for Stripe return should be wired at app level (scenePhase or NotificationCenter)
- `ProfileViewModel.profile.plan` → `SubscriptionViewModel.currentPlan` bridge needed
- `JobCardsViewModel.noSwipesLeft` → swipe limit UI in `ApplyView`

</code_context>

<specifics>
## Specific Ideas

- "Use the logo loading animation like the web app" — branded loading experience, not generic iOS spinners
- Great Fit badge should be prominent and eye-catching — green colored banner/ribbon on the card
- Empty states should be encouraging and action-oriented, matching a job-hunting app's motivational tone
- Stage moves should feel deliberate (buttons in detail sheet) not accidental (no drag-and-drop)

</specifics>

<deferred>
## Deferred Ideas

- Apple IAP / StoreKit integration — evaluate after App Store review. If Apple requires in-app purchase for subscriptions, this becomes its own phase. Revenue impact: Apple takes 15-30%.
- `appliedDate` field on pipeline cards — requires backend schema change to `AppliedJob` model. Defer until backend team adds the field.
- Company logo disk caching (SDWebImageSwiftUI) — Phase 4 hardening concern
- `seenUrls` unbounded growth cap — Phase 4 hardening concern

</deferred>

---

*Phase: 03-feature-polish*
*Context gathered: 2026-03-24*
