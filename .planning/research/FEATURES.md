# Feature Landscape

**Domain:** Swipe-based mobile job application (iOS, auto-apply, Tinder-style)
**Researched:** 2026-03-11
**Confidence:** HIGH for existing-codebase analysis; MEDIUM for domain/UX patterns (derived from category knowledge of Jobr, Tinder Jobs, Handshake, LinkedIn mobile, Hinge, and related swipe-first products)

---

## What Already Exists (Codebase Inventory)

Before mapping table stakes vs. differentiators, here is what the codebase already implements — this is the baseline everything else is measured against.

| Feature | Location | Status |
|---------|----------|--------|
| Swipe card deck (Z-stack, DragGesture, 100pt threshold) | `JobCardView`, `ApplyView` | Built — needs polish |
| Accept/Reject overlays (green APPLY / red SKIP) | `JobCardView.swipeOverlay` | Built — functional |
| Haptic feedback on swipe | `ApplyView.swipeJob` | Built |
| Action buttons (tap-to-swipe X / checkmark) | `JobCardView.actionButtons` | Built |
| Card prefetch when deck drops to ≤ 2 | `JobCardsViewModel` | Built |
| Swipe limit / daily quota with `noSwipesLeft` state | `ApplyView`, `JobCardsViewModel` | Built |
| Swipes-remaining counter in nav bar | `ApplyView` toolbar | Built |
| Filter drawer (industry, type, salary, recency, company) | `FilterDrawerView` | Built |
| Premium filter gating (salary/recency locked for free users) | `FilterDrawerView` | Built |
| Manual answers sheet for jobs needing extra fields | `ManualAnswersSheet` | Built |
| Job card tabs: Description / Requirements / Benefits | `JobCardView.tabContent` | Built |
| Match badges (Great Match, High Pay) | `JobCardView.cardHeader` | Built |
| Empty deck state with Refresh | `ApplyView.emptyView` | Built |
| No-resume gate with deep link to Resume section | `ApplyView.noResumeView` | Built |
| Upgrade upsell when swipes exhausted | `ApplyView.noSwipesView` | Built |
| Pipeline board (horizontal Kanban: Applying→Applied→Screen→Interview→Offer→Archived→Failed) | `MyJobsView`, `PipelineColumnView` | Built |
| Active/All toggle on pipeline | `MyJobsView` | Built |
| Job detail sheet (Overview/Requirements/Company tabs, stage mover, Safari link) | `JobDetailSheet` | Built |
| Lazy-load job details on sheet open | `AppliedJobsViewModel.fetchJobDetails` | Built |
| Email tracking (Mailbox tab with filter tabs, unread count, keep/unkeep, infinite scroll) | `MailboxView`, `EmailDetailView` | Built |
| Profile completion percentage bar | `ProfileView`, `UserProfile.completionPercentage` | Built |
| Profile sections: Personal, Address, Work Auth, Work History, Education, Skills, Certifications, Links, Resume, Preferences, Locations, EEO | `ProfileView` + section files | Built (sections exist; field completeness needs verification) |
| Resume upload (PDF, S3 presigned URL) | `ResumeSection`, `FileUploadService` | Built |
| Onboarding quiz (5 steps: Resume → Name → Contact → Work Auth → Preferences) | `PreferencesQuizView` | Built |
| Cognito auth (email/password, Apple Sign-In, Google Sign-In, Forgot Password) | `SignInView`, `SignUpView`, `AuthViewModel` | Built |
| Premium/subscription screen (Plus/Pro, Monthly/Seasonal/Lifetime, web checkout) | `PremiumView` | Built |
| Referral / Earn tab (link sharing, stats, payout request) | `EarnView` | Built |
| Settings (change email, change password, cancel subscription, delete account, sign out) | `SettingsView` | Built |

---

## Table Stakes

Features users of a swipe-based job app expect. Missing or broken = users abandon.

### Swipe UX

| Feature | Why Expected | Complexity | Current State | Notes |
|---------|--------------|------------|---------------|-------|
| Cards fly off screen with physics-consistent animation on swipe completion | Every swipe app does this; without it the interaction feels broken | Low | Partial — `easeOut(duration: 0.3)` to ±600pt offset exists but card does not actually leave the view hierarchy with a smooth curve; no spring physics on exit | Polish: add spring curve, ensure card is removed from deck after exit animation completes |
| Visual directional indicator fades in proportional to drag distance | Standard affordance — users need to know what a swipe will do before they commit | Low | Built — `swipeOverlay` uses opacity ramp from 20–100pt drag | Working; verify the opacity curve feels responsive |
| Snap-back spring animation when swipe is abandoned | Cards must feel physical, not digital | Low | Built — `.spring()` on `dragOffset = .zero` | Working |
| Button tap triggers same fly-off as physical swipe | Buttons are fallback for users who don't discover swipe | Low | Built — `dragOffset = CGSize(width: ±600, height: 0)` | Working |
| Stack depth visible behind top card (scale + offset perspective) | Conveys "there are more" without distracting | Low | Built — 3 cards, `scaleEffect` and `stackOffset` | Working |
| Swipe limit communicated clearly before user hits the wall | Surprise limits cause frustration; transparency builds trust | Low | Partial — counter shows "N swipes left" in nav bar leading position, but no progressive warning (e.g., "3 left") | Polish: add warning state at ≤3 swipes remaining |
| Empty deck state with actionable next step | Dead end = app feels broken | Low | Built — Refresh button, advice to adjust filters | Working |
| Resume gate with clear path to fix | Without resume the app cannot function; user must know how to unblock | Low | Built — `noResumeView` with NavigationLink to `ResumeSection` | Working; verify NavigationLink resolves correctly in the nav stack |

### Job Card Content

| Feature | Why Expected | Complexity | Current State | Notes |
|---------|--------------|------------|---------------|-------|
| Company name, title, location visible above the fold without scrolling | Decision-relevant info must be instant | Low | Built — `cardHeader` shows logo, title, company, location, type, pay | Working |
| Salary/pay estimate displayed prominently | Pay is a primary filter — hiding it creates distrust | Low | Built — orange `payEstimate.formattedString` in header | Working; depends on data quality from backend |
| Job type badge (Full-time, Contract, etc.) | Quick scan filter | Low | Built — teal chip in header | Working |
| Tab navigation between Description / Requirements / Benefits on the card | Users want detail before swiping right | Low | Built — segmented picker tabs | Working; scrollable content inside 280pt max height — verify it doesn't clip |
| Skills tags displayed as chips | Visual scanning; users match against own skills | Low | Built — `FlowLayout` chips on Description tab | Working; `FlowLayout` has a known height calculation approximation — verify on varied chip counts |

### Applied Jobs Management

| Feature | Why Expected | Complexity | Current State | Notes |
|---------|--------------|------------|---------------|-------|
| All applications visible in one place | Core promise of the app | Low | Built — `MyJobsView` pipeline board | Working once API connected |
| Stage progression (applied → screen → interview → offer) | Users track where they are in each process | Low | Built — `PipelineStage` enum, `moveJob` API call, stage chips in `JobDetailSheet` | Working; verify `moveJob` API call succeeds end-to-end |
| Detail view per application with original job description | Users need to prep for interviews | Medium | Built — `JobDetailSheet` with lazy-loaded details | Working; depends on `fetchJobDetails` API |
| Direct link to original job posting | Users need to reference the posting | Low | Built — Safari button in `JobDetailSheet` toolbar | Working |
| Empty state for pipeline | Users who just signed up see a clean prompt | Low | Built — `emptyState` in `MyJobsView` | Working |
| Active / archived split | Active pipeline should not be cluttered by dead ends | Low | Built — Active/All segmented picker | Working |

### Profile / Onboarding

| Feature | Why Expected | Complexity | Current State | Notes |
|---------|--------------|------------|---------------|-------|
| First-run onboarding that collects minimum viable profile before swiping starts | Without data, auto-apply cannot work | Medium | Built — 5-step `PreferencesQuizView` | Steps: Resume, Name, Contact, Work Auth, Preferences. Missing: location/address and salary preference during onboarding (captured later in Profile). Acceptable gap. |
| Skip option with clear consequence warning | Forcing completion causes drop-off | Low | Built — "Skip for Now" with confirmation dialog explaining resume requirement | Working |
| Profile completeness indicator | Motivates users to complete data that improves auto-apply quality | Low | Built — `completionPercentage` progress bar in `ProfileView` | The 10-field score covers resume, name, email, phone, work auth, skills, work history, education, preferences, city — verify all 10 are reachable/editable from Profile sections |
| Edit-in-place for all profile fields | Users need to update data over time | Medium | Built — separate section views for each profile area | Completeness of each section needs verification (field coverage, save success) |
| Resume upload (PDF) | The entire auto-apply value prop depends on this | Medium | Built — document picker + S3 presigned upload | Working once API connected; verify PDF-only restriction is enforced correctly |
| Work authorization field | Required for application compliance | Low | Built — `AuthorizationsSection`, onboarding step 4 | Working |

### Authentication

| Feature | Why Expected | Complexity | Current State | Notes |
|---------|--------------|------------|---------------|-------|
| Email/password sign-in | Baseline | Low | Built | Working once Cognito pointed at dev pool |
| Sign up with email | Baseline | Low | Built — `SignUpView` | Needs Cognito connectivity |
| Forgot password / reset | User expectation | Low | Built — `ForgotPasswordView` | Working once Cognito connected |
| Apple Sign-In | App Store requirement for apps offering third-party login; users expect it | Low | Built — `authVM.signInWithApple()` | Verify actual Amplify/Cognito federated identity wiring |
| Sign out | Baseline | Low | Built — with confirmation dialog | Working |
| Session persistence (stay signed in across app restarts) | Users expect this | Low | Handled by Amplify token refresh | Working |

### Subscription / Payment

| Feature | Why Expected | Complexity | Current State | Notes |
|---------|--------------|------------|---------------|-------|
| Clear pricing displayed before purchase | Users won't buy blind | Low | Built — `PlanCard` with price, swipe count, feature list | Working |
| Current plan indicated | Users need to know what they have | Low | Built — "Current Plan" badge, `isCurrent` | Depends on `subscriptionVM.currentPlan` loading correctly after checkout callback |
| Upgrade upsell from natural friction points (swipe limit, premium filter lock) | In-context upsells convert better than standalone | Low | Built — `noSwipesView` NavigationLink to `PremiumView`, filter lock rows with Upgrade link | Working |
| Subscription cancellation | App Store requirement; user expectation | Low | Built — `SettingsView` cancel flow with confirmation | Working |

---

## Differentiators

Features that set this product apart from generic job boards. Not universally expected, but create loyalty and word-of-mouth when done well.

| Feature | Value Proposition | Complexity | Current State | Notes |
|---------|-------------------|------------|---------------|-------|
| Auto-apply on swipe right | Core differentiator — the entire product | High | Backend-handled; swipe triggers `POST /handleSwipe` | iOS's job is to send the right data and show clear confirmation; verify `SwipeResponse.success` is surfaced to user with positive feedback |
| Match badges (Great Match, High Pay, isGreatFit) | Reduces decision fatigue — users trust curated signals | Low | Built — `greatMatch`, `isHighPaying` badges in card header | Differentiated; make sure `isGreatFit` is also surfaced — it exists in `Job` model but is not currently rendered |
| Manual questions sheet for jobs needing extra fields | Handles edge cases gracefully instead of silently failing or skipping | Medium | Built — `ManualAnswersSheet` with full field type support (text, select, textarea, boolean) | Well-implemented; verify required-field validation works end-to-end |
| Pipeline Kanban board (not just a list) | Active application tracking is rare in mobile job apps; most just log "applied" | Medium | Built — horizontal scrolling Kanban with 7 stages | Genuine differentiator; main polish gap is no date-applied or time-in-stage visibility on pipeline cards |
| Email tracking inbox (Mailbox tab) | Consolidates recruiter responses without leaving the app | High | Built — `MailboxView` with filter tabs, keep/unkeep, infinite scroll | Strong differentiator; depends on backend email ingestion pipeline |
| Referral / Earn cashback program | Unusual in this category; creates organic growth loop | Medium | Built — `EarnView` with link sharing, stats, payout request | Differentiator; verify payout API works end-to-end |
| Subscription plans with daily swipe quotas | Freemium model creates natural upgrade moments tied to real usage | Low | Built — free/plus/pro tiers with `swipesRemaining` | Well-integrated into UX |
| Premium filter gating (salary floor, recency) | Premium filters are a clear, tangible value add | Low | Built — salary and recency sliders locked for free users | Clean implementation |
| Profile completion score | Gamification that directly improves product quality (better profiles = better auto-apply) | Low | Built — `completionPercentage` with progress bar | Differentiated; currently 10-point scoring — consider whether the weighting reflects actual impact on auto-apply success |
| Company data on the card (benefits, size, HQ, revenue, rating) | Most swipe-job apps show minimal company context | Low | Built — Benefits tab on card, full company tab in detail sheet | Genuine differentiator when data is available |

---

## Anti-Features

Features to explicitly NOT build in this milestone. Each has a rationale.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Native StoreKit / IAP | Apple takes 30%; explicitly out of scope per PROJECT.md; web checkout (Stripe via SFSafariViewController) is already implemented and working | Continue using web checkout — it works, it's compliant (same pattern as Notion, Linear), and it avoids StoreKit complexity entirely |
| Push notifications (in-milestone) | Explicitly out of scope ("v2") per PROJECT.md; adding a notification system mid-polish sprint would balloon scope | Redirect to system Settings for notification preferences (already implemented in `SettingsView`) |
| Android app | iOS first, explicitly out of scope | Invest in iOS quality |
| In-app resume parsing / ATS optimization suggestions | Adds AI/ML complexity with no backend support defined; distraction from core polish | Let the backend handle application logic; iOS just uploads the file |
| Social feed / "who else applied" | Privacy concern; adds social graph complexity; no backend support | Out of scope for this product category entirely |
| Job recommendations via ML (on-device) | Core ML requires significant training data pipeline; wrong layer for this — belongs in backend | Backend already returns `greatMatch` / `isGreatFit` signals; consume those |
| Multi-resume support | Profile model supports one resume (`resumeFileName`); adding multi-resume requires backend and model changes | Single resume is the right MVP constraint |
| Chat / messaging with recruiters | Adds real-time infrastructure (WebSockets/APNs); out of scope | Email tracking (Mailbox) already handles recruiter responses |
| Calendar integration (interview scheduling) | Complex; requires EventKit + backend webhook integration | Pipeline stage "interview" is sufficient for this milestone; deeper integration is v2 |
| Undo last swipe | Common in Tinder-style apps but adds complexity: must reverse the `POST /handleSwipe` API call and reinsert the card at top of deck; backend must support it | If added, gate it behind premium tier to limit API cost |

---

## Feature Dependencies

```
Resume Upload → Swipe Deck (blocked by noResumeView gate)
Cognito Connectivity → All authenticated features (jobs, profile, mailbox, payments)
API Connectivity (dev.jobharvest-api.com) → Resume Upload, Swipe Deck, Profile, Mailbox, Applied Jobs, Payments
Profile Data Quality → Auto-apply accuracy (more complete profile = better applications)
Subscription Plan → Swipe quota (swipesRemaining), Premium filters (salary, recency)
Manual Answers Sheet → Jobs with manualInputFields (edge case, but load-bearing for correctness)
Job Detail Lazy Load → JobDetailSheet content (fetchJobDetails called on sheet open)
```

---

## What Is Incomplete or Needs Polish (Gap Analysis)

This section captures features that exist structurally but have polish gaps that matter for user experience.

### Swipe UX Polish Gaps

| Gap | Impact | Notes |
|-----|--------|-------|
| No animation on the card disappearing after button tap (only drag-initiated swipe has the fly-off) | Medium — button taps feel unresponsive | The accept button sets `dragOffset` but only when `manualInputFields` is empty; verify the animation path is actually reached |
| No progressive swipe-limit warning (e.g., "3 swipes left" state change) | Medium — users hit the wall with no warning | `swipesRemaining` is already published; add a threshold state |
| `FlowLayout` height is approximated (`items.count / 3 + 1 * 28`) | Low — can clip chips on cards with many skills | Replace with proper `Layout` protocol implementation (iOS 16+) |
| No undo / "I accidentally swiped left" recovery | Low | Out of scope this milestone unless backend supports it |
| Card content scroll within fixed 280pt frame | Medium — long descriptions get clipped without scrollable affordance | Verify ScrollView inside card works without interfering with the outer DragGesture |
| `isGreatFit` badge not rendered | Low — data is available in model, badge is missing from card | Trivial add; aligns with `greatMatch` and `isHighPaying` existing badges |

### Applied Jobs / Pipeline Polish Gaps

| Gap | Impact | Notes |
|-----|--------|-------|
| No application date on `PipelineJobCard` | Medium — users cannot see how long something has been in a stage | `AppliedJob` model has no `appliedDate` field — requires backend support |
| No sorting or filtering within pipeline columns | Low — acceptable at this scale | Skip for this milestone |
| Stage move has no optimistic update (UI doesn't change until API responds) | Medium — feels slow | Verify `moveJob` flow; add optimistic update if missing in `AppliedJobsViewModel` |
| `JobDetailSheet` company tab shows "No company info available" when `companyData` is nil | Low — acceptable fallback exists | Acceptable; backend data quality issue |

### Profile Polish Gaps

| Gap | Impact | Notes |
|-----|--------|-------|
| `completionPercentage` scoring does not weight resume most heavily (1/10 = 10%) | Medium — resume is required to use the app; its importance should be visually communicated separately from the score | Consider displaying "Resume required" separately before showing the % score |
| Onboarding quiz does not collect preferred salary or preferred locations | Low — captured later in Profile sections | Acceptable; these are lower-urgency fields |
| Each profile section must save independently; no global "unsaved changes" guard | Medium — user can lose edits by navigating away | Verify each section view has proper `.task` / `.onDisappear` save behavior |
| `skills` field on onboarding quiz step 5 is present in state (`@State private var skills: [String]`) but no UI exists for it on that step | Low-Medium — data is never collected during onboarding | Either add a skills input to step 5 or remove the dead state variable |

### Payment / Subscription Polish Gaps

| Gap | Impact | Notes |
|-----|--------|-------|
| After Safari web checkout closes, `checkSessionStatus` must be called to update `currentPlan` — success confirmation depends on this flow working end-to-end | High | Verify the Safari sheet dismiss callback triggers `checkSessionStatus` correctly in `PremiumView` |
| No "you're already on this plan" protection if user taps a plan they currently have | Low — `isCurrent` disables the CTA button on `PlanCard` | Built; working |

### Error / Loading State Polish Gaps

| Gap | Impact | Notes |
|-----|--------|-------|
| Raw error strings from `error.localizedDescription` are shown in `.alert` and inline `Text` views | High — Cognito/network errors produce unhelpful technical strings | All ViewModels catch to `self.error = error.localizedDescription`; needs user-friendly mapping |
| No retry affordance on most error states | Medium — user sees error but has no clear action | Add retry buttons on key failure paths (job fetch, profile load, mailbox load) |
| `LoadingView` is used for initial load but no skeleton/placeholder for subsequent refreshes | Low | Pull-to-refresh covers this adequately |

---

## MVP Recommendation for This Milestone

The foundation is solid. The polish sprint should prioritize in this order:

**Must Fix (blockers):**
1. API connectivity (`Config.xcconfig` domain correction) — unblocks everything
2. Cognito configuration verification — unblocks auth
3. Swipe card exit animation correctness — core UX moment
4. Error message humanization — every error path shows raw SDK strings currently
5. Payment checkout → session status callback — validates the core monetization flow

**Should Fix (user trust):**
6. Swipe limit progressive warning (≤3 swipes)
7. Profile section save reliability (no silent data loss on navigation)
8. Stage move optimistic update in pipeline
9. Skills field in onboarding (state exists, UI missing)

**Nice to Have (polish):**
10. `isGreatFit` badge on card
11. `FlowLayout` height approximation fix
12. Applied-date on pipeline cards (requires backend field)
13. Retry buttons on error states

---

## Sources

- Direct codebase inspection of all Swift files (HIGH confidence — no external verification needed for "what exists")
- Category knowledge: Tinder-for-jobs UX patterns (Jobr, Handshake, LinkedIn mobile swipe gestures, Indeed mobile), mobile onboarding research, Kanban-style mobile tracking UIs (MEDIUM confidence — well-established patterns, not verified against 2026 documentation)
- Apple HIG for iOS 16+ interaction patterns — swipe gesture norms, `DragGesture` threshold conventions (MEDIUM confidence)
- PROJECT.md and ARCHITECTURE.md (provided, current as of 2026-03-11)
