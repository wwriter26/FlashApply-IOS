# Requirements: FlashApply iOS

**Defined:** 2026-03-11
**Core Value:** Users can swipe on jobs, get auto-applied, and track everything — with zero friction from a polished, intuitive mobile UI.

## v1 Requirements

### Connectivity

- [ ] **CONN-01**: App successfully reaches `https://dev.jobharvest-api.com` — no 403 errors from wrong API domain
- [ ] **CONN-02**: `Config.xcconfig` `API_DOMAIN` is set to `https://dev.jobharvest-api.com`
- [ ] **CONN-03**: `amplifyconfiguration.json` Cognito pool IDs match the dev environment
- [ ] **CONN-04**: Missing config keys cause a `fatalError` in DEBUG builds (no silent fallback to prod)

### Authentication

- [ ] **AUTH-01**: User can sign in with existing account and reach the main app
- [ ] **AUTH-02**: New user is correctly routed to onboarding quiz (not skipped on network error)
- [ ] **AUTH-03**: Returning user bypasses onboarding and goes directly to main tabs
- [ ] **AUTH-04**: User session persists across app restarts
- [ ] **AUTH-05**: Sign-out clears all local state and returns user to sign-in screen

### Onboarding

- [ ] **ONBD-01**: Onboarding walkthrough collects all required fields: name, phone, work authorization, job type preferences, resume upload
- [ ] **ONBD-02**: Skills/preferences step is present and functional in the quiz (currently dead state variable)
- [ ] **ONBD-03**: Onboarding data is successfully saved to backend on completion
- [ ] **ONBD-04**: Progress is preserved if user backgrounds the app mid-quiz
- [ ] **ONBD-05**: Each quiz step has clear validation — user cannot advance with invalid input

### Profile

- [ ] **PROF-01**: User can view all their profile information in the Profile tab
- [ ] **PROF-02**: User can edit personal info (name, phone, LinkedIn URL)
- [ ] **PROF-03**: User can update job preferences (job type, location, salary range, work authorization)
- [ ] **PROF-04**: User can upload or replace their resume
- [ ] **PROF-05**: Profile uses the same shared `ProfileViewModel` instance as onboarding (no redundant fetches)
- [ ] **PROF-06**: Profile changes are saved to backend with success/failure feedback to user

### Swipe / Job Cards

- [ ] **SWIPE-01**: User can swipe right to apply or left to skip a job
- [ ] **SWIPE-02**: Card exit animation completes correctly for both swipe gestures and button taps
- [ ] **SWIPE-03**: User sees a clear, friendly message when swipe limit is reached (not a raw 403 error)
- [ ] **SWIPE-04**: Progressive swipe-limit warning appears before the hard limit is hit
- [ ] **SWIPE-05**: New jobs load automatically as the deck runs low (prefetch works)
- [ ] **SWIPE-06**: Empty deck state is handled with a friendly UI (no blank screen)
- [ ] **SWIPE-07**: `isGreatFit` badge is displayed on job cards when applicable

### Applied Jobs

- [ ] **JOBS-01**: User can view all applied jobs in a pipeline/Kanban view
- [ ] **JOBS-02**: User can move a job between pipeline stages
- [ ] **JOBS-03**: Applied date is visible on each job card
- [ ] **JOBS-04**: Stage moves feel instant (optimistic update, not wait-then-refresh)
- [ ] **JOBS-05**: User can view job detail from the applied jobs list

### Payments / Subscription

- [ ] **PAY-01**: User can navigate to the subscription/upgrade screen
- [ ] **PAY-02**: Current subscription plan is correctly displayed (not always "Free")
- [ ] **PAY-03**: Stripe checkout session opens successfully in Safari
- [ ] **PAY-04**: App detects successful payment and updates subscription status after returning from Stripe
- [ ] **PAY-05**: User sees their updated plan reflected immediately after successful payment

### Error Handling & Polish

- [ ] **UX-01**: All error messages shown to users are human-readable (not raw AWS/Cognito SDK strings)
- [ ] **UX-02**: All loading states have a spinner or skeleton UI (no blank screens during fetches)
- [ ] **UX-03**: All empty states have friendly messaging and a clear action (no blank screens)
- [ ] **UX-04**: Network failure on any screen shows a retry option

## v2 Requirements

### Observability

- **OBS-01**: Crash reporting integrated (Firebase Crashlytics or Sentry)
- **OBS-02**: Analytics events tracked for key user actions (swipe, apply, subscribe)

### Testing

- **TEST-01**: Services extracted behind protocols (`NetworkServiceProtocol`) to enable unit testing
- **TEST-02**: ViewModel unit tests covering core swipe and auth flows

### Performance

- **PERF-01**: Company logo images cached to disk (SDWebImageSwiftUI replacing AsyncImage)
- **PERF-02**: Amplify Hub listener moved from View to ViewModel to prevent duplicate events

### Notifications

- **NOTF-01**: Push notifications for application status changes
- **NOTF-02**: Notification preferences in settings

## Out of Scope

| Feature | Reason |
|---------|--------|
| Backend changes | iOS connects to existing Express/Lambda API — no backend work this milestone |
| Android app | iOS-first |
| Native StoreKit / IAP | Stripe web checkout is the payment path |
| Social sign-in (Apple/Google) | Auth methods exist in code but not verified; scope to v2 |
| Real-time chat / messaging | Not part of core job-application workflow |
| Web app changes | Mobile-only milestone |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CONN-01 | Phase 1 | Pending |
| CONN-02 | Phase 1 | Pending |
| CONN-03 | Phase 1 | Pending |
| CONN-04 | Phase 1 | Pending |
| AUTH-01 | Phase 2 | Pending |
| AUTH-02 | Phase 2 | Pending |
| AUTH-03 | Phase 2 | Pending |
| AUTH-04 | Phase 2 | Pending |
| AUTH-05 | Phase 2 | Pending |
| ONBD-01 | Phase 2 | Pending |
| ONBD-02 | Phase 2 | Pending |
| ONBD-03 | Phase 2 | Pending |
| ONBD-04 | Phase 2 | Pending |
| ONBD-05 | Phase 2 | Pending |
| PROF-01 | Phase 3 | Pending |
| PROF-02 | Phase 3 | Pending |
| PROF-03 | Phase 3 | Pending |
| PROF-04 | Phase 3 | Pending |
| PROF-05 | Phase 3 | Pending |
| PROF-06 | Phase 3 | Pending |
| SWIPE-01 | Phase 3 | Pending |
| SWIPE-02 | Phase 3 | Pending |
| SWIPE-03 | Phase 3 | Pending |
| SWIPE-04 | Phase 3 | Pending |
| SWIPE-05 | Phase 3 | Pending |
| SWIPE-06 | Phase 3 | Pending |
| SWIPE-07 | Phase 3 | Pending |
| JOBS-01 | Phase 3 | Pending |
| JOBS-02 | Phase 3 | Pending |
| JOBS-03 | Phase 3 | Pending |
| JOBS-04 | Phase 3 | Pending |
| JOBS-05 | Phase 3 | Pending |
| PAY-01 | Phase 3 | Pending |
| PAY-02 | Phase 3 | Pending |
| PAY-03 | Phase 3 | Pending |
| PAY-04 | Phase 3 | Pending |
| PAY-05 | Phase 3 | Pending |
| UX-01 | Phase 3 | Pending |
| UX-02 | Phase 3 | Pending |
| UX-03 | Phase 3 | Pending |
| UX-04 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 39 total
- Mapped to phases: 39
- Unmapped: 0 ✓
- Note: Phase 4 (Hardening) delivers observability, memory, and stability work tracked as v2 requirements (OBS-01, PERF-01, PERF-02) and architectural fixes — it has no exclusive v1 requirement IDs but is required for a shippable app.

---
*Requirements defined: 2026-03-11*
*Last updated: 2026-03-11 after roadmap creation — corrected phase mapping for JOBS/PAY/UX to Phase 3*
