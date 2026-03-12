# FlashApply iOS

## What This Is

A native iOS job application app (SwiftUI) that lets users swipe through curated job listings Tinder-style, auto-applies on their behalf, and lets them manage all their applications in one place. Users set up a profile once (mirroring the web app onboarding quiz) and the app handles the rest. Connected to the FlashApply AWS backend (Cognito auth, DynamoDB, S3).

## Core Value

Users should be able to swipe on jobs, get auto-applied, and track everything — with zero friction from a polished, intuitive mobile UI.

## Requirements

### Validated

- ✓ SwiftUI MVVM architecture with Cognito auth (Amplify) — existing
- ✓ Tinder-style swipe card UI for job browsing — existing (`ApplyView`, `JobCardsViewModel`)
- ✓ Applied jobs list and management — existing (`AppliedJobsViewModel`)
- ✓ Onboarding preferences quiz flow — existing (`PreferencesQuizView`)
- ✓ Profile tab with resume upload — existing (`ProfileViewModel`, `FileUploadService`)
- ✓ Mailbox/email tracking — existing (`MailboxViewModel`)
- ✓ Stripe-based subscription/payment (web checkout via SFSafariViewController) — existing
- ✓ Referral system — existing (`ReferralViewModel`)
- ✓ 5-tab navigation (Apply, My Jobs, Mailbox, Profile, More) — existing

### Active

- [ ] Fix API connectivity: change `API_DOMAIN` in `Config.xcconfig` to `https://dev.jobharvest-api.com` (root cause of all 403s)
- [ ] Verify Amplify configuration (`amplifyconfiguration.json`) points to correct Cognito user/identity pool for dev environment
- [ ] Polish onboarding walkthrough — ensure all fields from web app quiz are present and completable on mobile
- [ ] Complete profile tab — ensure all user info (personal info, skills, job preferences, work experience) is viewable and editable
- [ ] Verify payment/subscription flow works end-to-end with live Stripe + backend session
- [ ] Swipe UX polish — animations, feedback, empty states, swipe limit handling
- [ ] Applied jobs management polish — status updates, filtering, detail view
- [ ] Global UI/UX polish — loading states, error states, empty states, consistent design language
- [ ] Ensure all ViewModels handle errors gracefully with user-friendly messages (not raw error strings)

### Out of Scope

- Full backend rewrite — iOS connects to existing Express/Lambda backend
- Android app — iOS first
- Web app changes — mobile only
- Native StoreKit/IAP — Stripe web checkout is the payment path
- Real-time notifications (push) — v2

## Context

- Existing codebase at `JobHarvest/` — full SwiftUI app, mostly complete but blocked on API connectivity
- Web app runs locally against `localhost:3002` (Serverless Offline/SAM) — dev lambdas match deployed dev environment
- Two custom API domains exist: `jobharvest-api.com` (prod, not yet live) and `dev.jobharvest-api.com` (dev, active)
- iOS `Config.xcconfig` currently points to prod domain — causing all 403 Forbidden errors
- Once API is connected, most features should work; remaining work is polish and completing missing profile fields
- Auth: AWS Cognito via Amplify (AWSCognitoAuthPlugin + AWSS3StoragePlugin)
- Storage: S3 via presigned URLs for resume upload
- Payments: Stripe checkout session via SFSafariViewController

## Constraints

- **Tech Stack**: SwiftUI + Swift 5.0, iOS 16+, AWS Amplify — no changes to these
- **Backend**: Must connect to existing Express/Lambda API at `dev.jobharvest-api.com` — no backend changes in this milestone
- **Auth**: Cognito only — no new auth providers
- **Payments**: Stripe web checkout only (no native StoreKit)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use `dev.jobharvest-api.com` as API domain | Only deployed/active backend environment; prod not yet ready | — Pending |
| Keep existing 5-tab navigation structure | Already built and logical; just needs polish | — Pending |
| Polish-first approach (not rebuild) | Foundation is solid; fastest path to working app | — Pending |

---
*Last updated: 2026-03-11 after initialization*
