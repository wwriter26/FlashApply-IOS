# FlashApply iOS

## What This Is

A native iOS job application app (SwiftUI) that lets users swipe through curated job listings Tinder-style, auto-applies on their behalf, and lets them manage all their applications in one place. Users set up a profile once (mirroring the web app onboarding quiz) and the app handles the rest. Connected to the FlashApply AWS backend (Cognito auth, DynamoDB, S3).

## Core Value

Users should be able to swipe on jobs, get auto-applied, and track everything — with zero friction from a polished, intuitive mobile UI.

## Current State

**v1.0 MVP shipped 2026-04-01.** 60 Swift files, ~9,000 LOC.

The app is fully functional against the dev backend: API connectivity fixed, auth/onboarding flow complete, all 5 tabs polished (swipe cards, applied jobs pipeline, mailbox, profile, settings), Stripe web checkout integrated, error messages humanized, image caching added (SDWebImageSwiftUI), crash reporting wired (Sentry), and memory behavior bounded (seenUrls cap, Hub listener dedup).

## Requirements

### Validated

- ✓ API connectivity to dev.jobharvest-api.com with DEBUG guards — v1.0
- ✓ Cognito auth with correct dev pool IDs — v1.0
- ✓ Auth routing (new user → quiz, returning → main tabs, sign-out → sign-in) — v1.0
- ✓ 5-step onboarding quiz with skills picker, validation, resume upload — v1.0
- ✓ Profile tab: view/edit personal info, job prefs, resume upload with save feedback — v1.0
- ✓ Swipe cards: right to apply, left to skip, animations, prefetch, empty deck handling — v1.0
- ✓ Swipe limit: friendly warning/block messages, daily + enduring count tracking — v1.0
- ✓ Applied jobs pipeline with stage moves (optimistic updates), archived tab — v1.0
- ✓ Stripe web checkout via SFSafariViewController with return detection — v1.0
- ✓ Subscription plan display matching backend MembershipPlan enum — v1.0
- ✓ Human-readable error messages across all tabs (no raw SDK strings) — v1.0
- ✓ Loading spinners, empty states, error banners on all screens — v1.0
- ✓ Image caching via SDWebImageSwiftUI (no redundant network requests) — v1.0
- ✓ Sentry crash reporting (disabled in DEBUG, configurable via xcconfig) — v1.0
- ✓ Bounded seenUrls with FIFO eviction at 500 entries — v1.0
- ✓ Hub listener exactly-once registration in AuthViewModel.init — v1.0

### Active

(None — next milestone requirements TBD)

### Out of Scope

- Full backend rewrite — iOS connects to existing Express/Lambda backend
- Android app — iOS first
- Web app changes — mobile only
- Native StoreKit/IAP — Stripe web checkout is the payment path
- Real-time push notifications — v2
- Social sign-in (Apple/Google) — auth methods exist but unverified
- Offline mode — real-time is core value

## Context

- Codebase: `JobHarvest/` — 60 Swift files, SwiftUI MVVM
- Backend: `dev.jobharvest-api.com` (Express/Lambda on AWS)
- Auth: AWS Cognito via Amplify 2.x
- Storage: S3 via presigned URLs for resume upload
- Payments: Stripe checkout session via SFSafariViewController
- Crash reporting: Sentry (DSN placeholder in Config.xcconfig — needs real DSN)
- Image caching: SDWebImageSwiftUI 3.x
- Dependencies managed via Xcode SPM (not root Package.swift)

## Constraints

- **Tech Stack**: SwiftUI + Swift 5.9, iOS 16+, AWS Amplify — no changes to these
- **Backend**: Must connect to existing Express/Lambda API — no backend changes
- **Auth**: Cognito only — no new auth providers
- **Payments**: Stripe web checkout only (no native StoreKit)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use `dev.jobharvest-api.com` as API domain | Only deployed/active backend environment | ✓ Good — all API calls working |
| Keep existing 5-tab navigation structure | Already built and logical | ✓ Good — polished in place |
| Polish-first approach (not rebuild) | Foundation was solid | ✓ Good — shipped in 4 phases |
| `$()` xcconfig URL-escaping trick | Xcode strips `//` from values | ✓ Good — clean workaround |
| Crash-loudly in DEBUG for misconfig | Silent fallback caused hard-to-debug 403s | ✓ Good — catches issues immediately |
| Global `convertFromSnakeCase` decoder | camelCase keys pass through; CodingKeys take precedence | ✓ Good — no regressions |
| Sentry over Firebase Crashlytics | No GoogleService-Info.plist, no run script, no -ObjC flag | ✓ Good — simpler integration |
| App-to-web Stripe checkout | Backend uses embedded `ui_mode` returning `client_secret`, not URL | ✓ Good — opens web pricing page |
| seenUrls FIFO cap at 500 | Prevents unbounded memory + long query strings | ✓ Good — zero-dependency O(1) |
| Hub listener in AuthViewModel.init | SwiftUI View re-renders caused duplicate registrations | ✓ Good — exactly-once guarantee |

---
*Last updated: 2026-04-01 after v1.0 milestone*
