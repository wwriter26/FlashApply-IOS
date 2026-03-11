# Codebase Structure

**Analysis Date:** 2026-03-11

## Directory Layout

```
FlashApply-iOS/                         # Repo root
├── JobHarvest/                         # Xcode project root
│   ├── JobHarvest.xcodeproj/           # Xcode project file (open to build)
│   ├── App/                            # App entry point and navigation root
│   │   ├── FlashApplyApp.swift         # @main, Amplify init, root EnvironmentObject
│   │   └── AppRouter.swift             # Auth-gated top-level navigation
│   ├── Models/                         # Codable data structures
│   │   ├── Job.swift                   # Job, JobFilters, FetchJobsResponse, SwipeResponse
│   │   ├── AppliedJob.swift            # AppliedJob, PipelineStage, AppliedJobsResponse
│   │   ├── User.swift                  # UserProfile, WorkHistoryEntry, EducationEntry, JobPreferences, EEOData
│   │   ├── Email.swift                 # Email model (Mailbox)
│   │   ├── Referral.swift              # Referral model (Earn tab)
│   │   └── SubscriptionPlan.swift      # SubscriptionPlan enum, checkout/session responses
│   ├── Services/                       # External I/O singletons
│   │   ├── NetworkService.swift        # URLSession wrapper, Cognito auth headers, S3 upload
│   │   ├── AuthService.swift           # Amplify.Auth wrapper (sign up/in/out, token retrieval)
│   │   └── FileUploadService.swift     # Presigned URL flow for resume/transcript upload
│   ├── ViewModels/                     # @MainActor ObservableObject classes
│   │   ├── AuthViewModel.swift         # Root auth state (isLoaded, isSignedIn, isNewUser)
│   │   ├── JobCardsViewModel.swift     # Swipe deck state, fetch, prefetch, handleSwipe
│   │   ├── AppliedJobsViewModel.swift  # My Jobs pipeline data
│   │   ├── MailboxViewModel.swift      # Inbox/email data
│   │   ├── ProfileViewModel.swift      # UserProfile fetch/update/upload
│   │   ├── ReferralViewModel.swift     # Referral code and earnings data
│   │   └── SubscriptionViewModel.swift # Checkout session, plan status, cancel
│   ├── Views/                          # SwiftUI views organized by feature
│   │   ├── Auth/                       # Pre-auth screens
│   │   │   ├── SignInView.swift
│   │   │   ├── SignUpView.swift
│   │   │   ├── EmailVerificationView.swift
│   │   │   └── ForgotPasswordView.swift
│   │   ├── Onboarding/                 # New-user profile setup wizard
│   │   │   └── PreferencesQuizView.swift
│   │   ├── Main/                       # Post-auth feature screens
│   │   │   ├── MainTabView.swift       # TabView + MoreView; instantiates all feature VMs
│   │   │   ├── Apply/                  # Swipe-to-apply tab
│   │   │   │   ├── ApplyView.swift
│   │   │   │   ├── JobCardView.swift   # Card UI + DragGesture mechanic
│   │   │   │   ├── FilterDrawerView.swift
│   │   │   │   └── ManualAnswersSheet.swift
│   │   │   ├── MyJobs/                 # Application pipeline (kanban-style)
│   │   │   │   ├── MyJobsView.swift
│   │   │   │   ├── PipelineColumnView.swift
│   │   │   │   └── JobDetailSheet.swift
│   │   │   ├── Mailbox/                # Email inbox
│   │   │   │   ├── MailboxView.swift
│   │   │   │   └── EmailDetailView.swift
│   │   │   ├── Profile/                # User profile editor
│   │   │   │   ├── ProfileView.swift
│   │   │   │   └── sections/           # One file per profile section
│   │   │   │       ├── PersonalInfoSection.swift
│   │   │   │       ├── AddressSection.swift
│   │   │   │       ├── WorkHistorySection.swift
│   │   │   │       ├── EducationSection.swift
│   │   │   │       ├── SkillsSection.swift
│   │   │   │       ├── CertificationsSection.swift
│   │   │   │       ├── LinksSection.swift
│   │   │   │       ├── ResumeSection.swift
│   │   │   │       ├── PreferencesSection.swift
│   │   │   │       ├── LocationsSection.swift
│   │   │   │       ├── AuthorizationsSection.swift
│   │   │   │       └── EEOSection.swift
│   │   │   ├── Premium/                # Subscription plans
│   │   │   │   └── PremiumView.swift
│   │   │   ├── Earn/                   # Referrals and earnings
│   │   │   │   └── EarnView.swift
│   │   │   └── Settings/              # Account settings
│   │   │       └── SettingsView.swift
│   │   └── Shared/                    # Reusable UI components
│   │       ├── CompanyLogoView.swift   # Remote logo image loader
│   │       ├── CustomButton.swift      # Styled button components
│   │       ├── ErrorView.swift         # Generic error state view
│   │       └── LoadingView.swift       # Spinner with message
│   ├── Utils/                          # Cross-cutting helpers
│   │   ├── Constants.swift             # AppConfig (build vars), Color extensions, PipelineStage display
│   │   ├── Extensions.swift            # Date, String, View, PayEstimate extensions
│   │   └── Logger.swift               # AppLogger with per-domain os.Logger instances
│   ├── JobHarvest/                     # Xcode-generated group (assets, config files)
│   │   └── Assets.xcassets/           # App icon, accent color
│   ├── JobHarvestTests/               # Unit test target
│   │   └── JobHarvestTests.swift
│   └── JobHarvestUITests/             # UI test target
│       ├── JobHarvestUITests.swift
│       └── JobHarvestUITestsLaunchTests.swift
├── Package.swift                       # SPM dependency manifest (amplify-swift, stripe-ios)
├── Package.resolved                    # SPM lockfile
├── CLAUDE.md                           # Project guidance for Claude
└── .planning/                          # GSD planning documents
    └── codebase/
```

## Directory Purposes

**`JobHarvest/App/`:**
- Purpose: App lifecycle and navigation root only — nothing else lives here
- Contains: `@main` struct, Amplify configuration call, `AppRouter` (auth gate)
- Key files: `FlashApplyApp.swift`, `AppRouter.swift`

**`JobHarvest/Models/`:**
- Purpose: Pure data structures — no business logic, no networking
- Contains: `Codable` structs/enums that mirror backend JSON shapes
- Key files: `Job.swift` (swipe deck model), `User.swift` (UserProfile — the largest model), `AppliedJob.swift` (pipeline model)

**`JobHarvest/Services/`:**
- Purpose: All external I/O — network, auth, file uploads
- Contains: Singleton service classes; ViewModels call into these directly
- Key files: `NetworkService.swift` (used by every ViewModel), `AuthService.swift`, `FileUploadService.swift`

**`JobHarvest/ViewModels/`:**
- Purpose: Business logic and API orchestration; one ViewModel per major feature area
- Contains: `@MainActor final class` types conforming to `ObservableObject`
- Key files: `AuthViewModel.swift` (root, always alive), `JobCardsViewModel.swift` (core swipe mechanic), `ProfileViewModel.swift`

**`JobHarvest/Views/Main/`:**
- Purpose: All post-authentication screens, organized by tab/feature
- Contains: Feature views and their sub-components
- Key files: `MainTabView.swift` (tab container and VM instantiation point)

**`JobHarvest/Views/Main/Profile/sections/`:**
- Purpose: Each profile section is a separate SwiftUI view to keep `ProfileView.swift` manageable
- Contains: 12 section views, each receiving `profileVM` via `@EnvironmentObject`

**`JobHarvest/Views/Shared/`:**
- Purpose: Reusable UI components with no feature-specific logic
- Contains: `CompanyLogoView`, `CustomButton`, `ErrorView`, `LoadingView`

**`JobHarvest/Utils/`:**
- Purpose: Stateless helpers — no network calls, no state
- Key files: `Constants.swift` (all brand colors live here), `Extensions.swift` (View modifier helpers `flashCardStyle()`, `primaryButtonStyle()`, `secondaryButtonStyle()`)

## Key File Locations

**Entry Points:**
- `JobHarvest/App/FlashApplyApp.swift`: `@main` struct; Amplify is configured here
- `JobHarvest/App/AppRouter.swift`: navigation gate; edit here to add new top-level routes

**Configuration:**
- `JobHarvest/Utils/Constants.swift`: brand colors and `AppConfig` build-var accessors
- `JobHarvest/JobHarvest/amplifyconfiguration.json`: AWS Cognito + S3 config (gitignored; copy from `.template`)
- `JobHarvest/Config.xcconfig`: `API_DOMAIN`, `STRIPE_KEY`, `BUCKET_NAME` (gitignored; copy from `.template`)
- `Package.swift`: SPM dependency manifest at repo root

**Core Logic:**
- `JobHarvest/Services/NetworkService.swift`: all HTTP requests pass through here
- `JobHarvest/ViewModels/JobCardsViewModel.swift`: swipe deck logic and prefetch
- `JobHarvest/ViewModels/ProfileViewModel.swift`: profile fetch, patch, and resume upload

**Networking Endpoint Map (inferred from ViewModels/Services):**
- `POST /handleNewUser` — unauthenticated; called on sign-up
- `POST /users/{userId}/jobs` — fetch swipe deck
- `POST /handleSwipe` — record swipe decision
- `GET /getAppliedJobs` — My Jobs pipeline
- `GET /users/{userId}/profile` — fetch profile
- `POST /users/{userId}/profile` — update profile
- `POST /getUploadPresignedUrl` — get S3 presigned URL
- `GET /getUserResumeLink`, `GET /getUserTranscriptLink` — download URLs
- `POST /parseResume` — AI resume parsing
- `POST /createCheckoutSession` — Stripe web checkout
- `GET /sessionStatus` — post-checkout plan confirmation
- `POST /cancelSubscription`

**Testing:**
- `JobHarvest/JobHarvestTests/JobHarvestTests.swift`: unit test target (XCTest)
- `JobHarvest/JobHarvestUITests/`: UI test target (XCUITest)

## Naming Conventions

**Files:**
- Views: `PascalCase` + `View` suffix (e.g., `SignInView.swift`, `JobCardView.swift`)
- ViewModels: `PascalCase` + `ViewModel` suffix (e.g., `JobCardsViewModel.swift`)
- Services: `PascalCase` + `Service` suffix (e.g., `NetworkService.swift`)
- Models: `PascalCase` noun matching the concept (e.g., `Job.swift`, `User.swift`)
- Utils: Descriptive noun (e.g., `Constants.swift`, `Extensions.swift`, `Logger.swift`)

**Directories:**
- Feature directories under `Views/Main/` use `PascalCase` matching the tab name (e.g., `Apply/`, `MyJobs/`, `Profile/`)
- Sub-component directories use lowercase (e.g., `sections/`)

**Swift identifiers:**
- Types: `PascalCase`
- Properties and functions: `camelCase`
- Constants on enums: `camelCase` (e.g., `AppConfig.apiDomain`, `AppLogger.network`)
- Private request body types: defined inline as `private struct` inside the ViewModel that uses them

## Where to Add New Code

**New Feature Tab:**
1. Create ViewModel: `JobHarvest/ViewModels/{Feature}ViewModel.swift` — `@MainActor final class {Feature}ViewModel: ObservableObject`
2. Create view directory: `JobHarvest/Views/Main/{Feature}/`
3. Create root view: `JobHarvest/Views/Main/{Feature}/{Feature}View.swift`
4. Instantiate VM in `MainTabView.swift` as `@StateObject` and inject via `.environmentObject()`
5. Add `TabView` entry in `MainTabView.body` or a `NavigationLink` in `MoreView`

**New API Endpoint:**
- Add the call inside the relevant ViewModel, calling `NetworkService.shared.request()`
- If the endpoint is unauthenticated, use `NetworkService.shared.unauthenticatedRequest()`
- Define request/response types as `private struct` within the ViewModel file if used only there, or in `Models/` if shared

**New Model:**
- Add to the relevant file in `JobHarvest/Models/` if it extends an existing concept
- Create a new file in `JobHarvest/Models/` if it's a distinct domain object

**New Profile Section:**
- Create `{Name}Section.swift` in `JobHarvest/Views/Main/Profile/sections/`
- Add it as a section inside `ProfileView.swift`, receiving `profileVM` via `@EnvironmentObject`

**New Shared Component:**
- Add to `JobHarvest/Views/Shared/`

**New Utility:**
- Stateless extensions → `JobHarvest/Utils/Extensions.swift`
- New constants or colors → `JobHarvest/Utils/Constants.swift`
- New log category → add a static property to `AppLogger` in `JobHarvest/Utils/Logger.swift`

## Special Directories

**`JobHarvest/JobHarvest/Assets.xcassets/`:**
- Purpose: App icon and accent color only; no image assets used in code (logos are loaded remotely via `CompanyLogoView`)
- Generated: No
- Committed: Yes

**`.build/`:**
- Purpose: SPM build artifacts
- Generated: Yes
- Committed: No (in `.gitignore`)

**`.planning/`:**
- Purpose: GSD planning documents
- Generated: By GSD commands
- Committed: Yes

---

*Structure analysis: 2026-03-11*
