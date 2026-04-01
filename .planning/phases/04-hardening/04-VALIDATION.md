---
phase: 4
slug: hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-31
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (Xcode 16 built-in, `import Testing`) |
| **Config file** | None — uses default Xcode test target `JobHarvestTests` |
| **Quick run command** | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JobHarvestTests` |
| **Full suite command** | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Build succeeds (`xcodebuild build`)
- **After every plan wave:** Full test suite green
- **Before `/gsd:verify-work`:** Full suite must be green; SC-3 verified manually in Sentry dashboard
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | SC-1 Image caching | code inspection | `grep -L 'AsyncImage' JobHarvest/Views/Shared/CompanyLogoView.swift` | ✅ | ⬜ pending |
| 04-01-02 | 01 | 1 | SC-2 Hub once | unit | `xcodebuild test -only-testing:JobHarvestTests` | ❌ W0 | ⬜ pending |
| 04-01-03 | 01 | 1 | SC-3 Crash reporting | manual | Trigger test crash, verify Sentry dashboard | N/A | ⬜ pending |
| 04-01-04 | 01 | 1 | SC-4 seenUrls bounded | unit | `xcodebuild test -only-testing:JobHarvestTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `JobHarvestTests/SeenUrlsTests.swift` — unit test for seenUrls cap (SC-4): insert 600 URLs, assert count == 500 and oldest URL evicted
- [ ] `JobHarvestTests/HubListenerTests.swift` — unit test for Hub listener single-registration (SC-2, using mock/spy)

*Wave 0 tests must be created before or alongside the implementation tasks.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sentry crash reporting | SC-3 | Requires running Sentry project and dashboard access | 1. Build and run app. 2. Trigger `SentrySDK.crash()` in debug. 3. Verify event appears in Sentry dashboard. |
| Image cache hit on repeated views | SC-1 (functional) | Network caching behavior requires real network | 1. Open job cards with company logos. 2. Scroll away and back. 3. Verify no new network requests in Charles/Proxyman. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
