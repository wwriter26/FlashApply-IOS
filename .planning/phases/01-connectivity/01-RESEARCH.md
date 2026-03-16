# Phase 1: Connectivity - Research

**Researched:** 2026-03-11
**Domain:** iOS build configuration (xcconfig / Info.plist), AWS Amplify Cognito setup, Swift `#if DEBUG` guards
**Confidence:** HIGH

---

## Summary

Phase 1 is a pure configuration-and-hardening phase. Every file that needs to change has been directly inspected and the exact edits required are known. There is no library research, no architectural redesign, and no new dependencies. The entire phase reduces to four concrete tasks:

1. Fix `API_DOMAIN` in `Config.xcconfig` — one value, one line.
2. Verify `amplifyconfiguration.json` pool IDs match the same dev environment as `API_DOMAIN` (they do today; the file must be committed or a template created so a new developer can reproduce it).
3. Replace the silent nil-coalescing fallback in `AppConfig` with a `#if DEBUG fatalError` so a misconfigured environment crashes immediately rather than silently connecting to production.
4. Add a `fatalError` guard around `Amplify.configure()` in `FlashApplyApp` so a broken `amplifyconfiguration.json` produces an immediate crash rather than an infinite `LoadingView`.

All four changes are isolated and non-breaking. No other layers (ViewModels, Views, Models, Services) require modification.

**Primary recommendation:** Fix `Config.xcconfig` first (one-line change), then add the two `fatalError` guards, then create template files. Commit each step separately so the git history is legible.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CONN-01 | App successfully reaches `https://dev.jobharvest-api.com` — no 403 errors from wrong API domain | Fix `API_DOMAIN` in `Config.xcconfig`; `NetworkService` reads `AppConfig.apiDomain` which reads this value at runtime |
| CONN-02 | `Config.xcconfig` `API_DOMAIN` is set to `https://dev.jobharvest-api.com` | Direct one-line edit confirmed by direct file inspection |
| CONN-03 | `amplifyconfiguration.json` Cognito pool IDs match the dev environment | File is present and already contains dev pool IDs (`us-west-1_z834cixlP`, `7iqq53i9msqs73cu7fmepoa1qr`); a template must be created so new developers can reproduce it |
| CONN-04 | Missing config keys cause a `fatalError` in DEBUG builds (no silent fallback to prod) | `AppConfig.apiDomain` currently uses `?? "https://jobharvest-api.com"` nil-coalescing — replace with `#if DEBUG fatalError`; same pattern needed in `configureAmplify()` catch block |
</phase_requirements>

---

## Standard Stack

No new libraries are added in this phase. All tools are already present.

### Core (already in project)
| Component | Version | Purpose | Location |
|-----------|---------|---------|----------|
| `Config.xcconfig` | n/a | Build-time key/value vars injected into `Info.plist` | `JobHarvest/Config.xcconfig` |
| `Info.plist` | n/a | Carries `$(API_DOMAIN)`, `$(STRIPE_KEY)`, `$(BUCKET_NAME)` expansion at build time | `JobHarvest/JobHarvest/Info.plist` |
| `AppConfig` enum | n/a | Runtime typed access to `Bundle.main.infoDictionary` values | `JobHarvest/Utils/Constants.swift` |
| `amplify-swift` | 2.53.3 | Cognito auth and S3 storage; configured from `amplifyconfiguration.json` | `Package.resolved` |
| `FlashApplyApp.configureAmplify()` | n/a | Adds Cognito + S3 plugins and calls `Amplify.configure()` | `JobHarvest/App/FlashApplyApp.swift` |

### Alternatives Considered
None. This phase uses only existing platform mechanisms.

---

## Architecture Patterns

### xcconfig → Info.plist → AppConfig (existing, working)

The pipeline is already correctly wired end-to-end:

```
Config.xcconfig
  API_DOMAIN = https://$()/dev.jobharvest-api.com   ← must add "dev."

    ↓ Xcode build system expands $(API_DOMAIN)

Info.plist
  <key>API_DOMAIN</key>
  <string>$(API_DOMAIN)</string>

    ↓ Bundle.main.infoDictionary at runtime

AppConfig.apiDomain
  Bundle.main.infoDictionary?["API_DOMAIN"] as? String

    ↓ consumed by

NetworkService.shared  →  all REST calls
```

**Important:** The xcconfig value uses `https://$()/dev.jobharvest-api.com`, not `https://dev.jobharvest-api.com`. This is an Xcode xcconfig quirk: `$()` is an empty variable expansion used to escape the double-slash in URLs. The current file already uses this pattern for the prod domain. The dev domain must follow the identical pattern.

Current line (wrong):
```
API_DOMAIN = https://$()/jobharvest-api.com
```

Correct line:
```
API_DOMAIN = https://$()/dev.jobharvest-api.com
```

### fatalError Guard Pattern (CONN-04)

**What:** Replace silent fallback with a build-time-conditional crash so misconfigured builds fail loudly at launch rather than silently targeting production.

**Pattern 1 — AppConfig (Constants.swift):**
```swift
// BEFORE (silent fallback to prod):
static let apiDomain = Bundle.main.infoDictionary?["API_DOMAIN"] as? String ?? "https://jobharvest-api.com"

// AFTER (crash in DEBUG if key is missing or empty):
static let apiDomain: String = {
    guard let value = Bundle.main.infoDictionary?["API_DOMAIN"] as? String, !value.isEmpty else {
        #if DEBUG
        fatalError("API_DOMAIN is missing or empty in Config.xcconfig / Info.plist. Copy Config.xcconfig.template to Config.xcconfig and set API_DOMAIN.")
        #else
        return "https://jobharvest-api.com"  // safe fallback only in Release
        #endif
    }
    return value
}()
```

**Pattern 2 — Amplify configure (FlashApplyApp.swift):**
```swift
// BEFORE (silent log on failure, app hangs on LoadingView):
} catch {
    AppLogger.auth.error("Amplify configuration failed: \(error)")
}

// AFTER (crash in DEBUG on misconfigured amplifyconfiguration.json):
} catch {
    AppLogger.auth.error("Amplify configuration failed: \(error)")
    #if DEBUG
    fatalError("Amplify.configure() failed — check amplifyconfiguration.json. Error: \(error)")
    #endif
}
```

### Template File Pattern

**What:** Committed files ending in `.template` that document what a developer must create locally. These are the gitignored files' documented equivalents.

**Template locations:**
- `JobHarvest/Config.xcconfig.template` — documents required keys with placeholder values
- `JobHarvest/amplifyconfiguration.json.template` — documents required JSON structure with placeholder values

**Note:** The `.gitignore` currently does NOT list `Config.xcconfig` or `amplifyconfiguration.json` as ignored. Both files are present in the working tree. Before adding template files, verify whether these files should actually be gitignored (they contain non-secret AWS pool IDs and a plain domain name — they are not high-sensitivity credentials). The gitignore and CLAUDE.md say they are "not committed; copy from template" but the files ARE present on disk. The planner should create the templates regardless as documentation for onboarding, but should not blindly gitignore files that are already tracked without confirming intent.

### Anti-Patterns to Avoid
- **Do not change `NetworkService.swift` baseURL construction.** It correctly reads `AppConfig.apiDomain`. Fix the source (`Config.xcconfig`), not the consumer.
- **Do not add a separate "dev/prod" environment enum or scheme.** The task description says there is one active backend (dev). Adding environment switching is premature.
- **Do not modify `project.pbxproj` to change the deployment target.** The `IPHONEOS_DEPLOYMENT_TARGET = 26.2` is noted as possibly being Xcode version bleed-through, but this is out of scope for Phase 1 — changing it risks breaking the build.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Build-time config injection | Custom env-file parsing, custom plist writing | xcconfig → Info.plist → Bundle.main.infoDictionary (already in place) |
| Crash-on-misconfiguration | Runtime URL validation, custom config checker | `#if DEBUG fatalError(...)` in `AppConfig` and `configureAmplify()` |
| Developer onboarding docs | README sections that go stale | `.template` files committed alongside the gitignored files they document |

**Key insight:** The xcconfig/Info.plist/Bundle pipeline is the canonical Apple-blessed approach for injecting build-time configuration. It is already 100% wired in this project. The only problem is wrong values.

---

## Common Pitfalls

### Pitfall 1: Double-slash URL escaping in xcconfig
**What goes wrong:** Writing `API_DOMAIN = https://dev.jobharvest-api.com` in an xcconfig file produces `https:` at runtime — Xcode interprets `//` as a comment.
**Why it happens:** xcconfig files use `//` for comments; the build system strips everything after `//`.
**How to avoid:** Use the `$()` empty variable trick: `API_DOMAIN = https://$()/dev.jobharvest-api.com`. The current file already does this correctly for the prod domain.
**Verification:** After changing the value, build and log `AppConfig.apiDomain` at startup to confirm the full URL reads back correctly.

### Pitfall 2: amplifyconfiguration.json is already present and correct
**What goes wrong:** Treating the Amplify config as a gap when it is actually already populated with the correct dev values.
**Why it happens:** Prior research and STATE.md note it as "not committed" but the file exists on disk and contains dev pool IDs.
**What is true today:**
- `CognitoUserPool.Default.PoolId` = `us-west-1_z834cixlP` (dev)
- `CognitoUserPool.Default.AppClientId` = `7iqq53i9msqs73cu7fmepoa1qr` (dev)
- `CredentialsProvider.CognitoIdentity.Default.PoolId` = `us-west-1:cbaab5f0-ad40-4adb-80d0-608883f0078e` (dev)
- `storage.awsS3StoragePlugin.bucket` = `dev-jobharvest-user-file-bucket` (dev)
**Recommendation:** The file is correct. The only action needed is to create a `.template` version for developer onboarding.

### Pitfall 3: Config.xcconfig is not gitignored yet
**What goes wrong:** Adding a `.template` file and instructions to "gitignore and copy" when the actual file is already tracked by git.
**Why it happens:** CLAUDE.md and research docs say the file is "not committed; copy from template" — this is aspirational, not current reality.
**Current reality:** `.gitignore` does not contain `Config.xcconfig` or `amplifyconfiguration.json`. Both files exist on disk.
**Recommendation:** The planner should confirm the intended gitignore behavior with the team. If the files contain no secrets (the xcconfig only has a domain name, and the Cognito pool IDs in amplifyconfiguration.json are not high-sensitivity), there is no strong reason to gitignore them. Creating templates is still valuable documentation regardless.

### Pitfall 4: AppConfig fatalError must not fire in Release
**What goes wrong:** Adding `fatalError` unconditionally causes production app store submissions to crash if `API_DOMAIN` is missing.
**How to avoid:** Always wrap the `fatalError` in `#if DEBUG ... #else [safe fallback] #endif`. The Release build can safely fall back to the prod domain because app store builds will have the correct xcconfig.

### Pitfall 5: Amplify configure() error swallowing causes infinite LoadingView
**What goes wrong:** If `amplifyconfiguration.json` is malformed or missing, `configureAmplify()` catches the error, logs it, and returns normally. `authVM.checkAuthState()` then hangs because Amplify plugins are not initialized.
**Symptom:** App launches to a `LoadingView` spinner that never resolves.
**How to avoid:** Add `#if DEBUG fatalError(...)` in the catch block so configuration failures crash immediately with a clear message in development.

---

## Code Examples

### CONN-02: Correct Config.xcconfig
```
// Config.xcconfig
// Source: direct file inspection + Apple xcconfig URL-escaping convention

API_DOMAIN = https://$()/dev.jobharvest-api.com

//STRIPE_KEY = pk_test_YOUR_STRIPE_KEY

BUCKET_NAME = dev-jobharvest-user-file-bucket
```

### CONN-04: AppConfig with DEBUG fatalError (Constants.swift)
```swift
// Source: existing Constants.swift + #if DEBUG guard pattern (Apple platform standard)

enum AppConfig {
    static let apiDomain: String = {
        guard let value = Bundle.main.infoDictionary?["API_DOMAIN"] as? String,
              !value.isEmpty else {
            #if DEBUG
            fatalError("API_DOMAIN is missing or empty. Copy Config.xcconfig.template to Config.xcconfig and set API_DOMAIN.")
            #else
            return "https://jobharvest-api.com"
            #endif
        }
        return value
    }()

    static let stripePublishableKey = Bundle.main.infoDictionary?["STRIPE_KEY"] as? String ?? ""
    static let bucketName = Bundle.main.infoDictionary?["BUCKET_NAME"] as? String ?? ""
}
```

### CONN-04: Amplify configure guard (FlashApplyApp.swift)
```swift
// Source: existing FlashApplyApp.swift + #if DEBUG guard pattern

private func configureAmplify() {
    do {
        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        try Amplify.add(plugin: AWSS3StoragePlugin())
        try Amplify.configure()
        AppLogger.auth.info("Amplify configured successfully")
    } catch {
        AppLogger.auth.error("Amplify configuration failed: \(error)")
        #if DEBUG
        fatalError("Amplify.configure() failed — verify amplifyconfiguration.json exists and is valid. Error: \(error)")
        #endif
    }
}
```

### Config.xcconfig.template
```
// Config.xcconfig.template
// Copy this file to Config.xcconfig (gitignored) and fill in your values.

// Backend API domain — use dev for local development
API_DOMAIN = https://$()/dev.jobharvest-api.com

// Stripe publishable key — get from Stripe dashboard (test key for dev)
//STRIPE_KEY = pk_test_YOUR_STRIPE_KEY_HERE

// S3 bucket name — dev bucket for local development
BUCKET_NAME = dev-jobharvest-user-file-bucket
```

---

## State of the Art

| Old Approach | Current Approach | Relevance |
|--------------|------------------|-----------|
| Hardcoded base URLs in source | xcconfig → Info.plist → Bundle | Already in use; just needs correct value |
| Silent nil fallback for missing keys | `#if DEBUG fatalError` | CONN-04 upgrade |
| No developer setup docs | `.template` files | To be added |

---

## Open Questions

1. **Should Config.xcconfig and amplifyconfiguration.json be gitignored?**
   - What we know: Both files are present on disk and not currently in `.gitignore`. CLAUDE.md describes them as "not committed; copy from template."
   - What's unclear: Whether the files were intentionally left unignored (they contain non-secret values) or whether the gitignore was an oversight.
   - Recommendation: The planner should add a task to add these to `.gitignore` if the intent is for them to be developer-local. If they will remain committed (simpler), the template files are still useful as onboarding documentation but the gitignore step is skipped. Either decision is valid — the planner should make a call rather than leaving it ambiguous.

2. **Is the deployment target (`IPHONEOS_DEPLOYMENT_TARGET = 26.2`) intentional?**
   - What we know: STACK.md and ARCHITECTURE.md note it may be Xcode version bleed-through; CLAUDE.md says the project targets iOS 16+.
   - What's unclear: Whether changing this value to `16.0` would cause any build issues.
   - Recommendation: Treat as out of scope for Phase 1. Log for Phase 4 hardening.

---

## Validation Architecture

> No automated test framework is configured for this project (no `pytest.ini`, no `jest.config`, no `XCTest` test targets with meaningful tests). Validation for Phase 1 is manual + build-time verification.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (present in project but no phase-relevant unit tests exist) |
| Config file | `JobHarvest/JobHarvest.xcodeproj` (scheme: JobHarvest) |
| Quick run command | `xcodebuild build -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Full suite command | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CONN-01 | App makes authenticated requests without 403 errors | manual smoke | Run app in simulator; attempt sign-in and observe network logs in Console.app | N/A |
| CONN-02 | `API_DOMAIN` resolves to `https://dev.jobharvest-api.com` at runtime | build verification | Add `AppLogger.network.info("API_DOMAIN: \(AppConfig.apiDomain)")` in `configureAmplify()` — visible in Console.app on launch | N/A (log only) |
| CONN-03 | Cognito pool IDs match dev | manual verification | Read `amplifyconfiguration.json` pool IDs and cross-check against known dev values documented in INTEGRATIONS.md | N/A |
| CONN-04 | Missing `API_DOMAIN` causes `fatalError` in DEBUG | build verification | Remove `API_DOMAIN` from xcconfig, build in DEBUG — should crash at launch with descriptive message | ❌ Wave 0 — add test or document manual step |

### Sampling Rate
- **Per task commit:** `xcodebuild build ...` (confirms no compilation errors)
- **Per wave merge:** `xcodebuild build ...` + manual simulator smoke test confirming `AppLogger` logs show dev domain
- **Phase gate:** Clean build + `AppConfig.apiDomain` logs `https://dev.jobharvest-api.com` in Console.app before `/gsd:verify-work`

### Wave 0 Gaps
- No automated tests exist for configuration validation — this is acceptable for Phase 1 since all changes are single-value or single-guard additions. Manual verification via `AppLogger` log output is sufficient.

---

## Sources

### Primary (HIGH confidence — direct codebase inspection)
- `JobHarvest/Config.xcconfig` — confirmed current value is `https://$()/jobharvest-api.com` (missing `dev.`)
- `JobHarvest/Utils/Constants.swift` — confirmed `AppConfig.apiDomain` uses `?? "https://jobharvest-api.com"` silent fallback
- `JobHarvest/App/FlashApplyApp.swift` — confirmed `configureAmplify()` swallows errors silently
- `JobHarvest/amplifyconfiguration.json` — confirmed dev pool IDs (`us-west-1_z834cixlP`, `7iqq53i9msqs73cu7fmepoa1qr`, identity pool `us-west-1:cbaab5f0-ad40-4adb-80d0-608883f0078e`)
- `JobHarvest/JobHarvest/Info.plist` — confirmed `$(API_DOMAIN)` expansion wiring
- `JobHarvest/JobHarvest.xcodeproj/project.pbxproj` — confirmed `baseConfigurationReference` wires `Config.xcconfig` to both Debug and Release build configurations
- `.gitignore` — confirmed `Config.xcconfig` and `amplifyconfiguration.json` are NOT currently gitignored
- `.planning/codebase/INTEGRATIONS.md` — confirmed dev Cognito pool IDs and S3 bucket
- `.planning/research/SUMMARY.md` — cross-referenced pitfalls list

### Secondary (HIGH confidence — established Apple platform patterns)
- Apple xcconfig URL-escaping (`$()` trick) — well-known convention, verified against current file usage
- `#if DEBUG fatalError(...)` guard — standard Swift/iOS pattern for configuration validation in development builds
- `Bundle.main.infoDictionary` key lookup — standard Info.plist runtime access pattern

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; all existing components inspected directly
- Architecture: HIGH — all file paths, exact code, and exact values confirmed by direct file reads
- Pitfalls: HIGH — every pitfall cites a specific file and verified code pattern

**Research date:** 2026-03-11
**Valid until:** 2026-06-11 (stable platform conventions; xcconfig/Info.plist pipeline unchanged for many Xcode versions)
