# Roadmap: FlashApply iOS

## Overview

The entire app is already built — it is functionally blocked by a single configuration mistake. This roadmap follows the dependency graph dictated by the codebase: fix the API domain first (nothing works without it), harden auth and profile data next (everything depends on these), then verify and polish every feature against the live dev backend, then add the observability infrastructure that prevents regressions from going undetected.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Connectivity** - Fix the xcconfig domain and Amplify config so every API call reaches the correct backend
- [ ] **Phase 2: Auth and Profile Foundation** - Correct auth routing, shared ProfileViewModel, and complete onboarding quiz
- [ ] **Phase 3: Feature Polish** - Verify and polish swipe, applied jobs, payments, and error handling end-to-end
- [ ] **Phase 4: Hardening** - Add observability, memory guards, Hub token stability, and image caching

## Phase Details

### Phase 1: Connectivity
**Goal**: Every API call reaches `dev.jobharvest-api.com` and Cognito tokens are valid for that environment
**Depends on**: Nothing (first phase)
**Requirements**: CONN-01, CONN-02, CONN-03, CONN-04
**Success Criteria** (what must be TRUE):
  1. App launches and makes authenticated API requests without receiving any 403 Forbidden errors
  2. Amplify auth tokens are issued by the dev Cognito pool (not prod)
  3. A misconfigured or missing `API_DOMAIN` causes an immediate crash in DEBUG builds (no silent fallback to production)
  4. A developer setting up the project locally can follow a template file to configure their environment correctly
**Plans**: 1 plan

Plans:
- [ ] 01-01-PLAN.md — Fix API_DOMAIN, add fatalError guards, create developer onboarding templates

### Phase 2: Auth and Profile Foundation
**Goal**: Users are routed correctly on first run vs. returning run, onboarding collects all required data, and profile state is shared (not duplicated) across the app
**Depends on**: Phase 1
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, ONBD-01, ONBD-02, ONBD-03, ONBD-04, ONBD-05
**Success Criteria** (what must be TRUE):
  1. A new user who signs up is routed to the onboarding quiz — even if a network error occurs during the first-login check
  2. A returning user who signs in lands directly on the main tab view without seeing the onboarding quiz
  3. The onboarding quiz includes a functional skills/preferences step and requires valid input at each step before advancing
  4. Onboarding data (including resume upload) is saved to the backend and the user reaches the main app on completion
  5. Signing out clears all local state and returns the user to the sign-in screen; signing back in restores their session
**Plans**: TBD

### Phase 3: Feature Polish
**Goal**: Every feature tab works end-to-end against the dev backend with polished animations, friendly error messages, and no blank screens
**Depends on**: Phase 2
**Requirements**: PROF-01, PROF-02, PROF-03, PROF-04, PROF-05, PROF-06, SWIPE-01, SWIPE-02, SWIPE-03, SWIPE-04, SWIPE-05, SWIPE-06, SWIPE-07, JOBS-01, JOBS-02, JOBS-03, JOBS-04, JOBS-05, PAY-01, PAY-02, PAY-03, PAY-04, PAY-05, UX-01, UX-02, UX-03, UX-04
**Success Criteria** (what must be TRUE):
  1. A user can swipe right to apply and left to skip; both swipe gestures and tapping the buttons produce a clean card exit animation with no visual glitches
  2. A user who reaches or approaches the swipe limit sees a clear warning message — not a raw 403 error string
  3. A user can view their full profile, edit personal info and job preferences, and upload a resume; all changes save with visible success or failure feedback
  4. A user can tap Upgrade, complete Stripe checkout in Safari, return to the app, and see their plan updated immediately — without a manual refresh
  5. All loading states show a spinner or skeleton, all empty states show friendly messaging with a clear action, and all error messages are human-readable
**Plans**: TBD

### Phase 4: Hardening
**Goal**: The app has crash visibility, stable memory behavior, and no architectural anti-patterns that cause duplicate events or stale state
**Depends on**: Phase 3
**Requirements**: (no direct v1 requirement IDs — this phase delivers the quality baseline that makes v1 shippable)
**Success Criteria** (what must be TRUE):
  1. Company logo images load from cache on repeated views — no redundant network requests per render cycle
  2. Amplify Hub auth events fire exactly once per auth state change (no duplicate sign-in/sign-out events from view recreation)
  3. A crash or unhandled exception in production is reported automatically to an external dashboard (Crashlytics or Sentry)
  4. The `seenUrls` set does not grow unbounded — jobs are evicted after a configurable cap is reached
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Connectivity | 0/1 | Not started | - |
| 2. Auth and Profile Foundation | 0/TBD | Not started | - |
| 3. Feature Polish | 0/TBD | Not started | - |
| 4. Hardening | 0/TBD | Not started | - |
