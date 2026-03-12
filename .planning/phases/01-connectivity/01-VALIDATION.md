---
phase: 1
slug: connectivity
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-11
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (existing) |
| **Config file** | `JobHarvest/JobHarvest.xcodeproj` |
| **Quick run command** | `xcodebuild build -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Full suite command** | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~90 seconds (build + simulator launch) |

---

## Sampling Rate

- **After every task commit:** Verify build compiles without errors
- **After every plan wave:** Run full build + verify `AppConfig.apiDomain` resolves correctly
- **Before `/gsd:verify-work`:** App must launch on simulator with no 403 errors on first authenticated call
- **Max feedback latency:** 90 seconds (build time)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | CONN-02 | build | `xcodebuild build ...` | ✅ | ⬜ pending |
| 1-01-02 | 01 | 1 | CONN-04 | build | `xcodebuild build ...` | ✅ | ⬜ pending |
| 1-01-03 | 01 | 1 | CONN-01 | manual | Launch app on simulator | ✅ | ⬜ pending |
| 1-01-04 | 01 | 1 | CONN-03 | manual | Follow template to configure env | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `JobHarvest/Config.xcconfig.template` — template for developer onboarding (CONN-03)
- [ ] `JobHarvest/amplifyconfiguration.json.template` — template for Amplify config (CONN-03)

*These are documentation/template files, not test stubs. No new test framework installation needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App makes authenticated API calls without 403 | CONN-01 | Requires live dev backend + valid Cognito session | Launch app on simulator, sign in, verify job cards load |
| Amplify tokens issued by dev Cognito pool | CONN-02 | Requires comparing token issuer URL in JWT | Sign in, decode JWT from Amplify, verify issuer matches dev pool |
| Missing API_DOMAIN causes DEBUG crash | CONN-04 | Requires removing key and launching | Remove API_DOMAIN from xcconfig, build DEBUG, verify fatalError fires |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
