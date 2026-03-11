# Technology Stack

**Analysis Date:** 2026-03-11

## Languages

**Primary:**
- Swift 5.0 - All application code (`JobHarvest/` directory)

**Secondary:**
- JSON - Configuration (`JobHarvest/amplifyconfiguration.json`, `JobHarvest/JobHarvest/Assets.xcassets/Contents.json`)

## Runtime

**Environment:**
- iOS 26.2+ (deployment target set in `JobHarvest/JobHarvest.xcodeproj/project.pbxproj`)

**App Version:**
- 1.0 (marketing), build 1 (current project version)

**Bundle ID:**
- `JWW.JobHarvest` (main app), `com.flashapply.ios` (logger subsystem)

## Package Manager

**Tool:**
- Swift Package Manager (SPM)

**Lockfile:**
- `JobHarvest/JobHarvest.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (present, version 3 format)

## Frameworks

**Core UI:**
- SwiftUI - All UI screens and components (100% SwiftUI, no UIKit views except for window presentation in `JobHarvest/Services/AuthService.swift`)
- Combine - Reactive state management in ViewModels (`@Published`, `ObservableObject`)

**Auth & Cloud:**
- amplify-swift 2.53.3 - AWS Amplify umbrella package; provides Cognito auth and S3 storage (`JobHarvest/Services/AuthService.swift`, `JobHarvest/App/FlashApplyApp.swift`)
- AWSCognitoAuthPlugin (part of amplify-swift) - Cognito user pool and identity pool auth
- AWSS3StoragePlugin (part of amplify-swift) - S3 file upload/download
- aws-sdk-swift 1.6.7 - AWS SDK underlying transport
- aws-crt-swift 0.54.2 - AWS Common Runtime for Swift
- smithy-swift 0.175.0 - AWS Smithy protocol layer

**Networking:**
- URLSession (Apple standard library) - All REST calls in `JobHarvest/Services/NetworkService.swift`
- async-http-client 1.31.0 - HTTP client (transitive, pulled by Amplify)
- swift-nio 2.95.0, swift-nio-http2 1.40.0, swift-nio-ssl 2.36.0, swift-nio-extras 1.32.1, swift-nio-transport-services 1.26.0 - NIO networking stack (transitive)

**Payments:**
- Stripe referenced via `STRIPE_KEY` in `JobHarvest/Config.xcconfig` and `AppConfig.stripePublishableKey` in `JobHarvest/Utils/Constants.swift`; checkout opens via `SFSafariViewController` (web-only, no StoreKit/IAP)

**Logging:**
- os.Logger (Apple standard library) - Structured logging with categories defined in `JobHarvest/Utils/Logger.swift`; categories: Auth, Network, Jobs, Profile, Files, Subscription, Referral, UI

**Testing:**
- XCTest (Apple standard library) - Unit tests in `JobHarvest/JobHarvestTests/`, UI tests in `JobHarvest/JobHarvestUITests/`

**Observability (transitive, pulled by Amplify):**
- opentelemetry-swift 1.17.1
- grpc-swift 1.26.1
- swift-distributed-tracing 1.4.0
- swift-log 1.10.1
- swift-metrics 2.8.0

**Utilities (transitive):**
- sqlite.swift 0.15.3 - Local SQLite (used internally by Amplify)
- swift-algorithms 1.2.1
- swift-async-algorithms 1.1.2
- swift-atomics 1.3.0
- swift-collections 1.3.0
- swift-crypto 4.2.0
- swift-protobuf 1.35.0
- swift-numerics 1.1.1
- swift-certificates 1.18.0
- swift-asn1 1.5.1
- swift-service-context 1.3.0
- swift-service-lifecycle 2.10.1
- swift-system 1.6.4
- swift-http-types 1.5.1
- swift-http-structured-headers 1.6.0
- swift-argument-parser 1.7.0

## Key Dependencies

**Critical:**
- `amplify-swift` 2.53.3 — Entire auth flow (Cognito) and file storage (S3); configured via `JobHarvest/amplifyconfiguration.json`; initialized in `JobHarvest/App/FlashApplyApp.swift`
- `URLSession` (stdlib) — All authenticated REST calls to `jobharvest-api.com` backend via `JobHarvest/Services/NetworkService.swift`

**Infrastructure:**
- `sqlite.swift` 0.15.3 — Local persistence layer used internally by Amplify (not used directly in app code)

## Configuration

**Environment:**
- Build variables sourced from `JobHarvest/Config.xcconfig` (not committed; copy from template)
- Variables injected into `Info.plist` at `JobHarvest/JobHarvest/Info.plist` via `$(API_DOMAIN)`, `$(STRIPE_KEY)`, `$(BUCKET_NAME)` expansion
- Runtime access via `AppConfig` enum in `JobHarvest/Utils/Constants.swift` using `Bundle.main.infoDictionary`
- AWS Amplify config at `JobHarvest/amplifyconfiguration.json` (not committed; copy from template)

**Key build vars:**
- `API_DOMAIN` — Base URL for the backend REST API (`https://jobharvest-api.com`)
- `STRIPE_KEY` — Stripe publishable key (currently commented out in xcconfig)
- `BUCKET_NAME` — S3 bucket name (`dev-jobharvest-user-file-bucket`)

**Build:**
- Xcode project: `JobHarvest/JobHarvest.xcodeproj`
- Scheme: `JobHarvest`
- Build command: `xcodebuild build -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'`

## Platform Requirements

**Development:**
- Xcode (iOS SDK for iOS 26.2+)
- Swift 5.0+
- `JobHarvest/Config.xcconfig` and `JobHarvest/amplifyconfiguration.json` must be present before building

**Production:**
- iOS 26.2+ device or simulator
- App Store distribution (bundle ID `JWW.JobHarvest`)
- No linting tools configured (SwiftLint, Periphery, etc.)

---

*Stack analysis: 2026-03-11*
