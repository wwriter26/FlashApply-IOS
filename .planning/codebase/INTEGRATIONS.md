# External Integrations

**Analysis Date:** 2026-03-11

## APIs & External Services

**Backend REST API:**
- JobHarvest API — Primary app backend; all job data, swipe handling, profile, mailbox, referrals, and subscription operations
  - Base URL: `https://jobharvest-api.com` (configured via `API_DOMAIN` in `JobHarvest/Config.xcconfig`)
  - Client: `JobHarvest/Services/NetworkService.swift` (URLSession, singleton `NetworkService.shared`)
  - Auth: Bearer token (`Authorization: Bearer <idToken>`) + `X-Cognito-Identity-Id` header on all authenticated requests
  - Timeouts: 30s request / 60s resource
  - Key endpoints called by the app:
    - `POST /users/{userId}/jobs` — Fetch job card deck (`JobHarvest/ViewModels/JobCardsViewModel.swift`)
    - `POST /handleSwipe` — Record accept/reject swipe with optional manual answers
    - `POST /getUploadPresignedUrl` — Get S3 presigned URL for resume/transcript upload (`JobHarvest/Services/FileUploadService.swift`)
    - `GET /getUserResumeLink` — Get signed download URL for user's resume
    - `GET /getUserTranscriptLink` — Get signed download URL for user's transcript
    - `POST /parseResume` — Parse uploaded resume into profile data
    - `POST /removeExtraResumes` — Delete a resume from S3
    - `POST /removeExtraTranscripts` — Delete a transcript from S3
    - `POST /createCheckoutSession` — Create Stripe checkout session, returns web URL (`JobHarvest/ViewModels/SubscriptionViewModel.swift`)
    - `GET /sessionStatus` — Check Stripe checkout session result
    - `POST /cancelSubscription` — Cancel active subscription

**Company Logo Service:**
- Clearbit Logo API — Serves company logos by domain (e.g. `https://logo.clearbit.com/google.com`)
  - Client: `SwiftUI.AsyncImage` in `JobHarvest/Views/Shared/CompanyLogoView.swift`
  - Auth: None (public CDN)
  - `clearbit.com` is explicitly listed in `NSExceptionDomains` in `JobHarvest/JobHarvest/Info.plist` (HTTPS enforced)

**Payments:**
- Stripe — Subscription checkout (Plus and Pro plans)
  - Integration: Web-only checkout via `SFSafariViewController`; no in-app payment sheet, no StoreKit
  - Flow: App calls `/createCheckoutSession` → receives checkout URL → opens in `SafariView` sheet (`JobHarvest/Views/Main/Premium/PremiumView.swift`)
  - SDK key: `STRIPE_KEY` in `JobHarvest/Config.xcconfig` and accessed via `AppConfig.stripePublishableKey` in `JobHarvest/Utils/Constants.swift`
  - Plans: `plus`, `pro` with monthly, seasonal (3-month), and lifetime billing periods (`JobHarvest/Models/SubscriptionPlan.swift`)

## Data Storage

**Databases:**
- No client-side database used directly by app code
- `sqlite.swift` 0.15.3 is present as a transitive dependency of Amplify (used internally by Amplify for credential caching); not accessed directly

**File Storage:**
- AWS S3 (`dev-jobharvest-user-file-bucket`, `us-west-1`)
  - Connection: Configured in `JobHarvest/amplifyconfiguration.json` under `awsS3StoragePlugin`
  - Bucket name: also available via `BUCKET_NAME` build var in `JobHarvest/Config.xcconfig`
  - Upload pattern: App requests presigned URL from backend (`/getUploadPresignedUrl`), then `PUT`s file bytes directly to S3 presigned URL via `NetworkService.uploadFile(to:data:mimeType:)` in `JobHarvest/Services/NetworkService.swift`
  - File types: PDF resumes and PDF transcripts
  - Download pattern: App requests signed URL from backend (`/getUserResumeLink`, `/getUserTranscriptLink`), opens URL via `UIApplication.shared.open`

**Caching:**
- None client-side (no UserDefaults persistence layer, no CoreData, no explicit cache)

## Authentication & Identity

**Auth Provider:**
- AWS Cognito (via Amplify)
  - User Pool ID: `us-west-1_z834cixlP`, region `us-west-1`
  - App Client ID: `7iqq53i9msqs73cu7fmepoa1qr`
  - Identity Pool ID: `us-west-1:cbaab5f0-ad40-4adb-80d0-608883f0078e`
  - Auth flow: `USER_SRP_AUTH`
  - Configured in `JobHarvest/amplifyconfiguration.json`
  - Implementation: `JobHarvest/Services/AuthService.swift` (singleton `AuthService.shared`)

**Sign-in Methods:**
- Email + password (primary)
- Sign in with Apple (OAuth via Cognito hosted UI at `auth.dev.jobharvest.com`)
- Google Sign-In (OAuth via Cognito hosted UI at `auth.dev.jobharvest.com`)

**OAuth Redirect URIs:**
- Sign-in redirect: `jobharvest://callback`
- Sign-out redirect: `jobharvest://signout`
- Custom URL scheme `jobharvest` registered in `JobHarvest/JobHarvest/Info.plist` under `CFBundleURLSchemes`

**User Attributes:**
- `email`, `name` (standard Cognito attributes)
- `custom:firstLogin` — Boolean flag to gate onboarding quiz; set in `AuthService.swift`

**Token Usage:**
- ID token retrieved via `Amplify.Auth.fetchAuthSession()` → `getCognitoTokens().idToken` in `AuthService.getIdToken()`
- Cognito Identity ID retrieved via `getIdentityId()` for scoped S3 access
- Both sent as headers on every authenticated API request

**Session Events:**
- Amplify Hub listener in `JobHarvest/ViewModels/AuthViewModel.swift` monitors `signedIn`, `signedOut`, `sessionExpired` events to drive `AppRouter` navigation state

**Account Operations:**
- Sign up, confirm sign up (email verification code)
- Forgot password / confirm password reset
- Change password
- Update email + confirm via code
- Delete account (`Amplify.Auth.deleteUser()`)

## Monitoring & Observability

**Error Tracking:**
- None (no Sentry, Crashlytics, or similar crash reporting service detected)

**Logs:**
- Apple `os.Logger` (unified logging system)
- Subsystem: `com.flashapply.ios`
- Categories: Auth, Network, Jobs, Profile, Files, Subscription, Referral, UI
- All log calls in `JobHarvest/Utils/Logger.swift`; debug logs gated by `#if DEBUG`
- Viewable in Console.app or `log stream --predicate 'subsystem == "com.flashapply.ios"'`

## CI/CD & Deployment

**Hosting:**
- iOS App Store (production target)

**CI Pipeline:**
- None detected (no `.github/workflows/`, Fastlane, or Bitrise config present)

## Environment Configuration

**Required files before building:**
- `JobHarvest/Config.xcconfig` — must define `API_DOMAIN`, `STRIPE_KEY`, `BUCKET_NAME`
- `JobHarvest/amplifyconfiguration.json` — must contain Cognito User Pool, Identity Pool, and S3 bucket config

**Critical env vars (set in xcconfig):**
- `API_DOMAIN` — Backend base URL
- `STRIPE_KEY` — Stripe publishable key
- `BUCKET_NAME` — S3 bucket name

**Secrets location:**
- `Config.xcconfig` (not committed to git)
- `amplifyconfiguration.json` (not committed to git; contains Cognito pool IDs and app client ID)

## Webhooks & Callbacks

**Incoming:**
- None detected on the iOS client side

**Outgoing:**
- None detected; all communication is request-response via REST to `jobharvest-api.com`

**Deep Link Handling:**
- `jobharvest://callback` — Received after Cognito OAuth social sign-in (Apple, Google) to complete auth handshake
- `jobharvest://signout` — Received after Cognito OAuth sign-out

---

*Integration audit: 2026-03-11*
