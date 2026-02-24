# FlashApply iOS

Native iOS app (SwiftUI + Swift 5.9) for FlashApply (JobHarvest). Mirrors all features of the React webapp while using native iOS UX patterns.

---

## Architecture

```
iOS App (SwiftUI)
├── Auth Layer      → AWS Amplify iOS SDK (Cognito)
├── API Layer       → URLSession NetworkService (mirrors BackendConnector.js)
├── State Layer     → @StateObject ViewModels (mirrors Redux slices)
├── UI Layer        → SwiftUI views
└── Payments        → Web-only checkout via Safari (App Store compliant)
```

---

## Project Setup

### 1. Create Xcode Project

1. Open Xcode → New Project → iOS → App
2. **Product Name:** `FlashApply`
3. **Bundle ID:** `com.flashapply.ios`
4. **Interface:** SwiftUI
5. **Language:** Swift
6. **Deployment Target:** iOS 16.0
7. Copy all files from `FlashApply/` into the Xcode project

### 2. Add Swift Package Dependencies

In Xcode → File → Add Package Dependencies, add:

| Package | URL | Version |
|---------|-----|---------|
| Amplify iOS | `https://github.com/aws-amplify/amplify-swift` | 2.x |
| Stripe iOS | `https://github.com/stripe/stripe-ios` | 23.x |

Required products to add:
- `Amplify`
- `AWSCognitoAuthPlugin`
- `AWSS3StoragePlugin`
- `StripePaymentSheet` (optional — not used in App Store version)

### 3. Configure Amplify

1. Copy `amplifyconfiguration.json.template` → `amplifyconfiguration.json`
2. Fill in values from your existing Cognito setup (from webapp `.env`):
   - `YOUR_IDENTITY_POOL_ID` → `REACT_APP_IDENTITY_POOL_ID`
   - `YOUR_USER_POOL_ID` → `REACT_APP_USER_POOL_ID`
   - `YOUR_USER_POOL_CLIENT_ID` → `REACT_APP_USER_POOL_CLIENT_ID`
   - `YOUR_REGION` → `REACT_APP_REGION`
   - `YOUR_COGNITO_DOMAIN` → Cognito hosted UI domain
   - `YOUR_BUCKET_NAME` → `REACT_APP_BUCKET_NAME`
3. Add `amplifyconfiguration.json` to Xcode project (target membership: FlashApply)

### 4. Configure Build Settings

1. Copy `Config.xcconfig.template` → `Config.xcconfig`
2. Fill in `API_DOMAIN` and `STRIPE_KEY`
3. In Xcode → Project → Info → Configurations, set Config.xcconfig for Debug and Release

### 5. URL Scheme (for OAuth callbacks)

Add to `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>flashapply</string>
    </array>
  </dict>
</array>
```

### 6. App Transport Security

Add to `Info.plist` for Clearbit logo fetching:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <false/>
  <key>NSExceptionDomains</key>
  <dict>
    <key>clearbit.com</key>
    <dict>
      <key>NSExceptionAllowsInsecureHTTPLoads</key>
      <false/>
    </dict>
  </dict>
</dict>
```

---

## File Structure

```
FlashApply/
├── App/
│   ├── FlashApplyApp.swift          ← @main entry, Amplify config
│   └── AppRouter.swift              ← Auth-gated navigation root
├── Services/
│   ├── NetworkService.swift         ← URLSession API wrapper
│   ├── AuthService.swift            ← Amplify Cognito wrapper
│   └── FileUploadService.swift      ← S3 presigned URL uploads
├── Models/
│   ├── User.swift                   ← UserProfile, WorkHistory, etc.
│   ├── Job.swift                    ← Job card + filters + PayEstimate
│   ├── AppliedJob.swift             ← Pipeline stages
│   ├── Email.swift                  ← Mailbox models
│   ├── Referral.swift               ← Referral + Payout models
│   └── SubscriptionPlan.swift       ← Plan enum + Stripe responses
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── JobCardsViewModel.swift
│   ├── AppliedJobsViewModel.swift
│   ├── MailboxViewModel.swift
│   ├── ReferralViewModel.swift
│   └── SubscriptionViewModel.swift
├── Views/
│   ├── Auth/                        ← SignIn, SignUp, Verify, ForgotPW
│   ├── Onboarding/                  ← PreferencesQuizView (5-step wizard)
│   ├── Main/
│   │   ├── MainTabView.swift
│   │   ├── Apply/                   ← Swipe deck (core feature)
│   │   ├── MyJobs/                  ← 7-stage pipeline kanban
│   │   ├── Mailbox/                 ← Email list + HTML viewer
│   │   ├── Profile/                 ← 12 profile sections
│   │   ├── Premium/                 ← Plan cards + web checkout
│   │   ├── Earn/                    ← Referral rewards
│   │   └── Settings/                ← Account management
│   └── Shared/                      ← LoadingView, ErrorView, etc.
└── Utils/
    ├── Constants.swift              ← Colors, AppConfig
    ├── Extensions.swift             ← Date, String, View helpers
    └── Logger.swift                 ← os.log wrapper
```

---

## Key Design Decisions

### Payments (App Store Compliance)
Subscriptions use **web-only checkout** (Option A):
- Tap plan → `createCheckoutSession` → opens `SFSafariViewController`
- No Stripe SDK payment sheet in-app (avoids Apple IAP requirement)
- This is the standard pattern used by Notion, Linear, etc.

### Auth State Management
`AppRouter.swift` drives all navigation:
```swift
if !authVM.isLoaded   → LoadingView
if !authVM.isSignedIn → SignInView
if authVM.isNewUser   → PreferencesQuizView
else                  → MainTabView
```

Amplify Hub listener fires on `signedIn` / `signedOut` / `sessionExpired`.

### Swipe Mechanics
- `DragGesture` on `JobCardView` with 100pt threshold
- Z-stack of 3 cards with scale + offset perspective
- Spring animation for card return if threshold not met
- `UIImpactFeedbackGenerator` on accept/reject
- Prefetch next batch when deck drops to ≤ 2 cards

---

## Testing Checklist

- [ ] Auth: Sign up → verify email → onboarding quiz → Main tab
- [ ] Apply: Fetch cards → swipe right → appears in MyJobs "Applying"
- [ ] MyJobs: Tap card → move to "Interview" stage
- [ ] Mailbox: Load emails → open one → mark as kept
- [ ] Profile: Edit skills → save → reopen → verify saved
- [ ] Resume: Upload PDF → see filename in profile
- [ ] Premium: Tap plan → Safari opens checkout URL
- [ ] Referral: Copy link → contains user's referral code
- [ ] Settings: Change password → sign out → sign in with new password

---

## App Store Prep Checklist

- [ ] Sign in with Apple (required if any 3rd party auth)
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`)
- [ ] App icons (1024x1024 + all scaled sizes)
- [ ] Launch screen (teal gradient + bolt logo)
- [ ] Push notifications entitlement
- [ ] Dark mode color adaptations
- [ ] TestFlight internal testing (5+ testers)
- [ ] App Store screenshots (all device sizes)
- [ ] App Store description + keywords
